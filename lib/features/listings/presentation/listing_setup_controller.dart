import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/image_check_service.dart';
import '../data/listing_repository.dart';
import '../domain/flat_listing.dart';

class ListingSetupState {
  final FlatListing draft;
  final String? error;
  final bool isSaving;

  const ListingSetupState({
    required this.draft,
    this.error,
    this.isSaving = false,
  });

  ListingSetupState copyWith({
    FlatListing? draft,
    String? error,
    bool? isSaving,
  }) {
    return ListingSetupState(
      draft: draft ?? this.draft,
      error: error,
      isSaving: isSaving ?? this.isSaving,
    );
  }
}

class ListingSetupController extends StateNotifier<ListingSetupState> {
  final ListingRepository _repo;

  ListingSetupController(this._repo)
      : super(
          ListingSetupState(
            draft: FlatListing(
              userId: 'lister_1',
              locality: 'Andheri West',
              latitude: 19.1363,
              longitude: 72.8277,
              rent: 28000,
              deposit: 75000,
              availableFrom: DateTime(2026, 12, 1),
            ),
          ),
        );

  void addInteriorPhoto(ImageCheckInput photo) {
    state = state.copyWith(
      draft: state.draft.copyWith(
        interiorPhotos: [...state.draft.interiorPhotos, photo],
      ),
      error: null,
    );
  }

  void addExteriorPhoto(ImageCheckInput photo) {
    state = state.copyWith(
      draft: state.draft.copyWith(
        exteriorPhotos: [...state.draft.exteriorPhotos, photo],
      ),
      error: null,
    );
  }

  Future<bool> publishListing() async {
    state = state.copyWith(isSaving: true, error: null);
    try {
      final saved = await _repo.verifyAndPublishListing(draft: state.draft);
      state = state.copyWith(draft: saved, isSaving: false);
      return saved.photosVerified;
    } catch (e) {
      state = state.copyWith(isSaving: false, error: e.toString());
      return false;
    }
  }
}

final listingSetupControllerProvider =
    StateNotifierProvider<ListingSetupController, ListingSetupState>((ref) {
  return ListingSetupController(ref.watch(listingRepositoryProvider));
});
