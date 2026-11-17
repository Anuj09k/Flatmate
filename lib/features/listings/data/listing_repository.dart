import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/config/app_config.dart';
import '../../../core/services/image_check_service.dart';
import '../domain/flat_listing.dart';

class ListingRepository {
  final AppConfig config;
  final ImageCheckService imageChecker;
  final Map<String, FlatListing> _listings = {};

  ListingRepository({required this.config, required this.imageChecker});

  /// Enforces Section 6 Flat Photo Rules for Listers:
  /// - At least 2 interior photos, not duplicates of each other (checked via pHash)
  /// - At least 1 exterior photo of the building/entrance
  /// - Fake photo check against other users' listings
  /// - Location EXIF check against listed area
  Future<FlatListing> verifyAndPublishListing({
    required FlatListing draft,
    List<ImageCheckInput> otherUsersPhotos = const [],
  }) async {
    if (draft.interiorPhotos.length < config.minListerInteriorPhotos) {
      throw StateError(
        'INSUFFICIENT_INTERIOR_PHOTOS: Listers must add at least ${config.minListerInteriorPhotos} interior photos.',
      );
    }

    if (draft.exteriorPhotos.length < config.minListerExteriorPhotos) {
      throw StateError(
        'INSUFFICIENT_EXTERIOR_PHOTOS: Listers must add at least ${config.minListerExteriorPhotos} exterior building/entrance photo.',
      );
    }

    final verifiedPhotos = <ImageCheckInput>[];
    final allCandidatePhotos = [
      ...draft.interiorPhotos,
      ...draft.exteriorPhotos,
      ...draft.extraPhotos,
    ];

    var sentToManualReview = false;

    for (final photo in allCandidatePhotos) {
      final result = await imageChecker.checkPhoto(
        candidate: photo,
        existingUserPhotos: verifiedPhotos,
        otherListingsPhotos: otherUsersPhotos,
        listedAreaLat: draft.latitude,
        listedAreaLng: draft.longitude,
      );

      if (result.outcome == ImageModerationOutcome.rejectedDuplicate ||
          result.outcome == ImageModerationOutcome.rejectedUnsafe) {
        throw StateError('FLAT_PHOTO_REJECTED: ${result.message}');
      }

      if (result.outcome == ImageModerationOutcome.flaggedCrossUserDuplicate ||
          result.outcome == ImageModerationOutcome.flaggedLocationMismatch) {
        sentToManualReview = true;
      }

      verifiedPhotos.add(photo);
    }

    final updated = draft.copyWith(
      photosVerified: !sentToManualReview,
      isPublished: !sentToManualReview,
    );
    _listings[updated.userId] = updated;
    return updated;
  }
}

final listingRepositoryProvider = Provider<ListingRepository>((ref) {
  return ListingRepository(
    config: ref.watch(appConfigProvider),
    imageChecker: ref.watch(imageCheckServiceProvider),
  );
});
