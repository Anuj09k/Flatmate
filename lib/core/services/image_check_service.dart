import 'dart:math' as math;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../config/app_config.dart';

class ImageCheckInput {
  final String id;
  final String url;
  final int perceptualHash; // 64-bit dHash
  final double? exifLat;
  final double? exifLng;
  final bool isGroupPhoto;
  final bool hasSunglasses;
  final bool containsUnsafeContent;

  const ImageCheckInput({
    required this.id,
    required this.url,
    required this.perceptualHash,
    this.exifLat,
    this.exifLng,
    this.isGroupPhoto = false,
    this.hasSunglasses = false,
    this.containsUnsafeContent = false,
  });
}

enum ImageModerationOutcome {
  approved,
  rejectedDuplicate,
  rejectedUnsafe,
  flaggedCrossUserDuplicate,
  flaggedLocationMismatch,
}

class ImageCheckResult {
  final ImageModerationOutcome outcome;
  final String? message;

  const ImageCheckResult({required this.outcome, this.message});
  bool get isApproved => outcome == ImageModerationOutcome.approved;
}

/// Small interface for perceptual hashing, duplicate checks, EXIF location checks,
/// and content moderation (Section 5 & Section 6).
abstract class ImageCheckService {
  int hammingDistance64(int hashA, int hashB);

  Future<ImageCheckResult> checkPhoto({
    required ImageCheckInput candidate,
    required List<ImageCheckInput> existingUserPhotos,
    List<ImageCheckInput> otherListingsPhotos = const [],
    double? listedAreaLat,
    double? listedAreaLng,
  });
}

class MockImageCheckService implements ImageCheckService {
  final AppConfig config;
  const MockImageCheckService(this.config);

  @override
  int hammingDistance64(int hashA, int hashB) {
    var xor = hashA ^ hashB;
    var count = 0;
    for (var i = 0; i < 64; i++) {
      if ((xor & 1) == 1) count++;
      xor = xor >> 1;
    }
    return count;
  }

  double _haversineKm(double lat1, double lon1, double lat2, double lon2) {
    const earthRadiusKm = 6371.0;
    final dLat = _degToRad(lat2 - lat1);
    final dLon = _degToRad(lon2 - lon1);
    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_degToRad(lat1)) *
            math.cos(_degToRad(lat2)) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return earthRadiusKm * c;
  }

  double _degToRad(double deg) => deg * (math.pi / 180.0);

  @override
  Future<ImageCheckResult> checkPhoto({
    required ImageCheckInput candidate,
    required List<ImageCheckInput> existingUserPhotos,
    List<ImageCheckInput> otherListingsPhotos = const [],
    double? listedAreaLat,
    double? listedAreaLng,
  }) async {
    if (candidate.containsUnsafeContent) {
      return const ImageCheckResult(
        outcome: ImageModerationOutcome.rejectedUnsafe,
        message: 'Photo rejected by safety moderation check.',
      );
    }

    // 1. Check same-user duplicate via perceptual hash
    for (final existing in existingUserPhotos) {
      if (existing.id != candidate.id &&
          hammingDistance64(existing.perceptualHash, candidate.perceptualHash) <=
              config.pHashDuplicateThreshold) {
        return const ImageCheckResult(
          outcome: ImageModerationOutcome.rejectedDuplicate,
          message: 'Duplicate or near-identical photo rejected. Please upload a different room or angle.',
        );
      }
    }

    // 2. Check cross-user / stolen listing photo
    for (final other in otherListingsPhotos) {
      if (hammingDistance64(other.perceptualHash, candidate.perceptualHash) <=
          config.pHashDuplicateThreshold) {
        return const ImageCheckResult(
          outcome: ImageModerationOutcome.flaggedCrossUserDuplicate,
          message: 'Photo matches an existing listing and has been queued for manual review.',
        );
      }
    }

    // 3. Check EXIF GPS coordinates against listed locality (Section 6)
    if (candidate.exifLat != null &&
        candidate.exifLng != null &&
        listedAreaLat != null &&
        listedAreaLng != null) {
      final distanceKm = _haversineKm(
        candidate.exifLat!,
        candidate.exifLng!,
        listedAreaLat,
        listedAreaLng,
      );
      if (distanceKm > config.maxPhotoLocationMismatchKm) {
        return ImageCheckResult(
          outcome: ImageModerationOutcome.flaggedLocationMismatch,
          message:
              'Photo location is ${distanceKm.toStringAsFixed(1)} km from the listed locality. Sent to manual review.',
        );
      }
    }

    return const ImageCheckResult(outcome: ImageModerationOutcome.approved);
  }
}

final imageCheckServiceProvider = Provider<ImageCheckService>((ref) {
  final config = ref.watch(appConfigProvider);
  return MockImageCheckService(config);
});
