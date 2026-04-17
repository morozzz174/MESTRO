import 'dart:io';

import 'package:flutter/material.dart';
import '../../../../database/database_helper.dart';
import '../../../../models/order.dart';
import '../../../../services/app_logger.dart';

class ChecklistPhotosSection extends StatefulWidget {
  final String orderId;
  final VoidCallback onTakePhoto;
  final ValueChanged<PhotoAnnotation> onViewPhoto;
  final ValueChanged<PhotoAnnotation> onDeletePhoto;

  const ChecklistPhotosSection({
    super.key,
    required this.orderId,
    required this.onTakePhoto,
    required this.onViewPhoto,
    required this.onDeletePhoto,
  });

  @override
  State<ChecklistPhotosSection> createState() => ChecklistPhotosSectionState();
}

class ChecklistPhotosSectionState extends State<ChecklistPhotosSection> {
  List<PhotoAnnotation> _photos = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    loadPhotos();
  }

  Future<void> loadPhotos() async {
    try {
      final db = DatabaseHelper();
      final photos = await db.getPhotosForOrder(widget.orderId);
      AppLogger.info(
        'ChecklistPhotos',
        'Загружено ${photos.length} фото для заявки ${widget.orderId}',
      );
      if (mounted) {
        setState(() {
          _photos = photos;
          _isLoading = false;
        });
      }
    } catch (e, st) {
      AppLogger.error('ChecklistPhotos', 'Ошибка загрузки фото', e, st);
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Фотофиксация',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                ElevatedButton.icon(
                  onPressed: widget.onTakePhoto,
                  icon: const Icon(Icons.camera_alt, size: 18),
                  label: const Text('Добавить фото'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.secondary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (_isLoading)
              const Center(child: CircularProgressIndicator())
            else if (_photos.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    'Нет фото. Нажмите кнопку выше.',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              )
            else
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                ),
                itemCount: _photos.length,
                itemBuilder: (context, index) {
                  final photo = _photos[index];
                  return _PhotoThumbnail(
                    photo: photo,
                    onTap: widget.onViewPhoto,
                    onDelete: widget.onDeletePhoto,
                    onDeleteSuccess: loadPhotos,
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}

class _PhotoThumbnail extends StatelessWidget {
  final PhotoAnnotation photo;
  final ValueChanged<PhotoAnnotation> onTap;
  final ValueChanged<PhotoAnnotation> onDelete;
  final VoidCallback onDeleteSuccess;

  const _PhotoThumbnail({
    required this.photo,
    required this.onTap,
    required this.onDelete,
    required this.onDeleteSuccess,
  });

  @override
  Widget build(BuildContext context) {
    final path = photo.annotatedPath ?? photo.filePath;
    final file = File(path);

    return GestureDetector(
      onTap: () => onTap(photo),
      child: Stack(
        fit: StackFit.expand,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: file.existsSync()
                ? Image.file(file, fit: BoxFit.cover)
                : Container(
                    color: Colors.grey.shade300,
                    child: const Icon(Icons.broken_image, color: Colors.grey),
                  ),
          ),
          Positioned(
            top: 4,
            right: 4,
            child: Container(
              decoration: const BoxDecoration(
                color: Color(0xFFE53935),
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: const Icon(Icons.delete, color: Colors.white, size: 18),
                onPressed: () async {
                  onDelete(photo);
                  await Future.delayed(const Duration(milliseconds: 500));
                  onDeleteSuccess();
                },
                constraints: const BoxConstraints(),
                padding: const EdgeInsets.all(4),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
