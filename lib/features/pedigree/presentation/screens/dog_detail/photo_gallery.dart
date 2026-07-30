import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../../core/services/file_storage_service.dart';
import '../../../../../core/widgets/delete_confirm_dialog.dart';
import '../../../domain/entities/dog.dart';
import '../../providers/pedigree_providers.dart';

class PhotoGallery extends ConsumerWidget {
  final Dog dog;

  const PhotoGallery({super.key, required this.dog});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final galleryAsync = ref.watch(dogGalleryProvider(dog.id));
    final imagePicker = ImagePicker();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Photo Gallery',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              TextButton.icon(
                onPressed: () async {
                  final picked = await imagePicker.pickImage(source: ImageSource.gallery);
                  if (picked != null) {
                    final repo = ref.read(pedigreeRepositoryProvider);
                    await repo.addDogPhoto(dog.id, picked.path);
                  }
                },
                icon: const Icon(Icons.add_a_photo, size: 18),
                label: const Text('Add'),
              ),
            ],
          ),
        ),
        galleryAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('Error loading gallery: $e'),
                const SizedBox(height: 16),
              ],
            ),
          ),
          data: (photos) {
            if (photos.isEmpty) {
              return const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.0),
                child: Text('No photos yet. Add some to build a gallery!',
                    style: TextStyle(color: Colors.grey)),
              );
            }
            return SizedBox(
              height: 120,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                itemCount: photos.length,
                itemBuilder: (context, index) {
                  final photo = photos[index];
                  return Stack(
                    children: [
                      Container(
                        width: 120,
                        margin: const EdgeInsets.only(right: 8.0),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.file(
                            File(photo.photoPath),
                            fit: BoxFit.cover,
                            cacheWidth: 400,
                            errorBuilder: (context, error, stackTrace) => Container(
                              color: Colors.grey.shade200,
                              child: const Icon(Icons.broken_image, color: Colors.grey),
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        top: 4,
                        right: 12,
                        child: GestureDetector(
                          onTap: () => _deletePhoto(context, ref, photo.id, dog.id, photo.photoPath),
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: Colors.black54,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.close, size: 14, color: Colors.white),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            );
          },
        ),
      ],
    );
  }

  Future<void> _deletePhoto(
      BuildContext context, WidgetRef ref, int photoId, int dogId, String path) async {
    final confirmed = await showDeleteConfirmDialog(
      context,
      title: 'Delete Photo',
      message: 'Remove this photo from the gallery?',
    );

    if (confirmed && context.mounted) {
      try {
        final repo = ref.read(pedigreeRepositoryProvider);
        await FileStorageService.deleteFile(path);
        await repo.deleteDogPhoto(photoId);
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error deleting photo: $e')),
          );
        }
      }
    }
  }
}
