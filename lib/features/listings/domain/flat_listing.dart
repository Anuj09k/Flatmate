import 'package:equatable/equatable.dart';
import '../../../core/services/image_check_service.dart';

class FlatListing extends Equatable {
  final String userId;
  final String city;
  final String locality;
  final double latitude;
  final double longitude;
  final int rent;
  final int deposit;
  final String furnishing;
  final String roomType;
  final String bathroomType;
  final List<String> amenities;
  final String rentSplit;
  final bool maidShare;
  final String utilitiesSplit;
  final DateTime availableFrom;
  final int minStayMonths;
  final int noticePeriodDays;
  final Map<String, String> houseRules;
  final List<ImageCheckInput> interiorPhotos;
  final List<ImageCheckInput> exteriorPhotos;
  final List<ImageCheckInput> extraPhotos;
  final bool photosVerified;
  final bool isPublished;

  const FlatListing({
    required this.userId,
    this.city = 'Mumbai',
    required this.locality,
    required this.latitude,
    required this.longitude,
    required this.rent,
    required this.deposit,
    this.furnishing = 'furnished',
    this.roomType = 'private_room',
    this.bathroomType = 'attached',
    this.amenities = const [],
    this.rentSplit = 'equal',
    this.maidShare = true,
    this.utilitiesSplit = 'equal',
    required this.availableFrom,
    this.minStayMonths = 6,
    this.noticePeriodDays = 30,
    this.houseRules = const {},
    this.interiorPhotos = const [],
    this.exteriorPhotos = const [],
    this.extraPhotos = const [],
    this.photosVerified = false,
    this.isPublished = false,
  });

  FlatListing copyWith({
    bool? photosVerified,
    bool? isPublished,
    List<ImageCheckInput>? interiorPhotos,
    List<ImageCheckInput>? exteriorPhotos,
  }) {
    return FlatListing(
      userId: userId,
      city: city,
      locality: locality,
      latitude: latitude,
      longitude: longitude,
      rent: rent,
      deposit: deposit,
      furnishing: furnishing,
      roomType: roomType,
      bathroomType: bathroomType,
      amenities: amenities,
      rentSplit: rentSplit,
      maidShare: maidShare,
      utilitiesSplit: utilitiesSplit,
      availableFrom: availableFrom,
      minStayMonths: minStayMonths,
      noticePeriodDays: noticePeriodDays,
      houseRules: houseRules,
      interiorPhotos: interiorPhotos ?? this.interiorPhotos,
      exteriorPhotos: exteriorPhotos ?? this.exteriorPhotos,
      extraPhotos: extraPhotos,
      photosVerified: photosVerified ?? this.photosVerified,
      isPublished: isPublished ?? this.isPublished,
    );
  }

  @override
  List<Object?> get props => [
        userId,
        city,
        locality,
        latitude,
        longitude,
        rent,
        deposit,
        furnishing,
        roomType,
        bathroomType,
        amenities,
        rentSplit,
        maidShare,
        utilitiesSplit,
        availableFrom,
        minStayMonths,
        noticePeriodDays,
        houseRules,
        interiorPhotos,
        exteriorPhotos,
        extraPhotos,
        photosVerified,
        isPublished,
      ];
}
