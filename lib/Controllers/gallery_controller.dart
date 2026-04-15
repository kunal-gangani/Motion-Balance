import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../Models/recorded_video.dart';
import '../Services/gallery_service.dart';

final galleryServiceProvider = Provider<GalleryService>((ref) {
  return GalleryService();
});

final galleryProvider =
    StateNotifierProvider<GalleryNotifier, AsyncValue<List<RecordedVideo>>>(
  (ref) => GalleryNotifier(
    ref.read(galleryServiceProvider),
  ),
);

class GalleryNotifier
    extends StateNotifier<AsyncValue<List<RecordedVideo>>> {
  final GalleryService _galleryService;

  GalleryNotifier(this._galleryService)
      : super(const AsyncLoading()) {
    loadVideos();
  }

  Future<void> loadVideos() async {
    try {
      final videos = await _galleryService.getAllVideos();

      state = AsyncData(videos);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  Future<void> refreshGallery() async {
    await loadVideos();
  }

  Future<void> deleteVideo(String path) async {
    await _galleryService.deleteVideo(path);
    await loadVideos();
  }
}