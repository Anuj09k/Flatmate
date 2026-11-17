import 'package:flutter_test/flutter_test.dart';
import 'package:flatmate_app/core/config/app_config.dart';
import 'package:flatmate_app/core/services/image_check_service.dart';
import 'package:flatmate_app/core/utils/contact_blocker.dart';
import 'package:flatmate_app/features/auth/data/auth_repository.dart';
import 'package:flatmate_app/features/auth/domain/app_user.dart';
import 'package:flatmate_app/features/listings/data/listing_repository.dart';
import 'package:flatmate_app/features/listings/domain/flat_listing.dart';
import 'package:flatmate_app/features/profile/data/profile_repository.dart';
import 'package:flatmate_app/features/profile/domain/user_profile.dart';

void main() {
  const config = AppConfig();
  const imageChecker = MockImageCheckService(config);

  group('Phase 1 — Auth, Age Gate & 15-Day Timer', () {
    test('Rejects sign-up under minimum age (18) and initializes 15-day verification window', () async {
      final authRepo = InMemoryAuthRepository(config);
      final now = DateTime.utc(2026, 11, 12);

      expect(
        () => authRepo.verifyOtpAndSignUp(
          phone: '+919820011111',
          otp: '123456',
          dateOfBirth: DateTime.utc(2009, 11, 13),
          gender: 'man',
          nowOverride: now,
        ),
        throwsStateError,
      );

      final user = await authRepo.verifyOtpAndSignUp(
        phone: '+919820022222',
        otp: '123456',
        dateOfBirth: DateTime.utc(1999, 5, 10),
        gender: 'woman',
        nowOverride: now,
      );
      expect(user.status, AccountStatus.limited);
      expect(user.verificationDeadline.difference(now).inDays, config.verificationWindowDays);
    });
  });

  group('Phase 1 — Profile Photos, Prompts & Contact Blocker', () {
    const validPrompts = [
      PromptAnswer(promptId: 'daily_1', answer: 'Morning runs and filter coffee.', position: 0),
      PromptAnswer(promptId: 'living_1', answer: 'Clean kitchen after cooking.', position: 1),
      PromptAnswer(promptId: 'about_1', answer: 'Reading sci-fi on the balcony.', position: 2),
    ];

    const validPhotos = [
      ImageCheckInput(id: 'p1', url: 'https://example.com/1.jpg', perceptualHash: 0x0000000000000001),
      ImageCheckInput(id: 'p2', url: 'https://example.com/2.jpg', perceptualHash: 0xFFFFFFFFFFFFFFFF),
    ];

    test('Rejects group photo as first photo and all-sunglasses photos', () async {
      final profileRepo = ProfileRepository(config: config, imageChecker: imageChecker);

      expect(
        () => profileRepo.saveAndValidateProfile(
          profile: const UserProfile(
            userId: 'u1',
            name: 'Aarav',
            bio: 'Product designer',
            occupation: 'Designer',
            collegeOrCompany: 'Razorpay',
            languages: ['English'],
            profilePhotos: [
              ImageCheckInput(
                id: 'p1',
                url: 'u1',
                perceptualHash: 0x1,
                isGroupPhoto: true,
              ),
              ImageCheckInput(id: 'p2', url: 'u2', perceptualHash: 0xFFFFFFFFFFFFFFFF),
            ],
            promptAnswers: validPrompts,
          ),
          role: UserRole.seeker,
          listerFlatPhotosVerified: false,
        ),
        throwsStateError,
      );

      expect(
        () => profileRepo.saveAndValidateProfile(
          profile: const UserProfile(
            userId: 'u1',
            name: 'Aarav',
            bio: 'Product designer',
            occupation: 'Designer',
            collegeOrCompany: 'Razorpay',
            languages: ['English'],
            profilePhotos: [
              ImageCheckInput(id: 'p1', url: 'u1', perceptualHash: 0x1, hasSunglasses: true),
              ImageCheckInput(
                id: 'p2',
                url: 'u2',
                perceptualHash: 0xFFFFFFFFFFFFFFFF,
                hasSunglasses: true,
              ),
            ],
            promptAnswers: validPrompts,
          ),
          role: UserRole.seeker,
          listerFlatPhotosVerified: false,
        ),
        throwsStateError,
      );
    });

    test('Blocks phone numbers (spaced & spelled out) and social handles in bio/prompts', () {
      expect(ContactBlocker.containsContactDetails('Call me at 98200 12345'), isTrue);
      expect(
        ContactBlocker.containsContactDetails('reach me nine eight two zero zero one two three'),
        isTrue,
      );
      expect(ContactBlocker.containsContactDetails('DM me on insta @rahul_99'), isTrue);
      expect(ContactBlocker.containsContactDetails('Love cooking pasta and watching F1'), isFalse);
    });

    test('Lister cannot complete profile unless flat photos are verified', () async {
      final profileRepo = ProfileRepository(config: config, imageChecker: imageChecker);

      expect(
        () => profileRepo.saveAndValidateProfile(
          profile: const UserProfile(
            userId: 'lister_1',
            name: 'Riya',
            bio: 'Architect',
            occupation: 'Architect',
            collegeOrCompany: 'Studio',
            languages: ['English'],
            profilePhotos: validPhotos,
            promptAnswers: validPrompts,
          ),
          role: UserRole.lister,
          listerFlatPhotosVerified: false,
        ),
        throwsStateError,
      );
    });
  });

  group('Phase 1 — Lister Flat Photo Rules (2 non-duplicate interior + 1 exterior)', () {
    test('Enforces 2 distinct interior photos + 1 exterior photo and checks EXIF location', () async {
      final listingRepo = ListingRepository(config: config, imageChecker: imageChecker);
      final baseListing = FlatListing(
        userId: 'lister_1',
        locality: 'Andheri West',
        latitude: 19.1363,
        longitude: 72.8277,
        rent: 28000,
        deposit: 75000,
        availableFrom: DateTime.utc(2026, 12, 1),
      );

      expect(
        () => listingRepo.verifyAndPublishListing(
          draft: baseListing.copyWith(
            interiorPhotos: const [
              ImageCheckInput(id: 'int1', url: 'i1', perceptualHash: 0x0000000000000000),
            ],
            exteriorPhotos: const [
              ImageCheckInput(id: 'ext1', url: 'e1', perceptualHash: 0x0F0F0F0F0F0F0F0F),
            ],
          ),
        ),
        throwsStateError,
      );

      expect(
        () => listingRepo.verifyAndPublishListing(
          draft: baseListing.copyWith(
            interiorPhotos: const [
              ImageCheckInput(id: 'int1', url: 'i1', perceptualHash: 0x0000000000000000),
              ImageCheckInput(id: 'int2_dup', url: 'i2', perceptualHash: 0x0000000000000001),
            ],
            exteriorPhotos: const [
              ImageCheckInput(id: 'ext1', url: 'e1', perceptualHash: 0x0F0F0F0F0F0F0F0F),
            ],
          ),
        ),
        throwsStateError,
      );

      final published = await listingRepo.verifyAndPublishListing(
        draft: baseListing.copyWith(
          interiorPhotos: const [
            ImageCheckInput(
              id: 'int1',
              url: 'i1',
              perceptualHash: 0x0000000000000000,
              exifLat: 19.1363,
              exifLng: 72.8277,
            ),
            ImageCheckInput(
              id: 'int2',
              url: 'i2',
              perceptualHash: 0xFFFFFFFFFFFFFFFF,
              exifLat: 19.1365,
              exifLng: 72.8280,
            ),
          ],
          exteriorPhotos: const [
            ImageCheckInput(
              id: 'ext1',
              url: 'e1',
              perceptualHash: 0x0F0F0F0F0F0F0F0F,
              exifLat: 19.1363,
              exifLng: 72.8277,
            ),
          ],
        ),
      );
      expect(published.photosVerified, isTrue);
      expect(published.isPublished, isTrue);

      final mismatched = await listingRepo.verifyAndPublishListing(
        draft: baseListing.copyWith(
          interiorPhotos: const [
            ImageCheckInput(
              id: 'int1',
              url: 'i1',
              perceptualHash: 0x0000000000000000,
              exifLat: 18.9220,
              exifLng: 72.8347,
            ),
            ImageCheckInput(
              id: 'int2',
              url: 'i2',
              perceptualHash: 0xFFFFFFFFFFFFFFFF,
              exifLat: 19.1365,
              exifLng: 72.8280,
            ),
          ],
          exteriorPhotos: const [
            ImageCheckInput(
              id: 'ext1',
              url: 'e1',
              perceptualHash: 0x0F0F0F0F0F0F0F0F,
              exifLat: 19.1363,
              exifLng: 72.8277,
            ),
          ],
        ),
      );
      expect(mismatched.photosVerified, isFalse);
      expect(mismatched.isPublished, isFalse);
    });
  });
}
