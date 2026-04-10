import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../bloc/order_bloc.dart';
import '../../../../bloc/order_event.dart';
import '../../../../database/database_helper.dart';
import '../../../../models/order.dart';
import '../../../../models/checklist_config.dart';
import '../../../../utils/app_design.dart';
import '../../../../services/app_logger.dart';

/// Секция фотофиксации в чек-листе
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
      decoration: AppDesign.cardDecoration,
      child: Padding(
        padding: const EdgeInsets.all(AppDesign.spacing16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Фотофиксация', style: AppDesign.subtitleStyle),
                ElevatedButton.icon(
                  onPressed: widget.onTakePhoto,
                  icon: const Icon(Icons.camera_alt, size: 18),
                  label: const Text('Добавить фото'),
                  style: AppDesign.accentButtonStyle,
                ),
              ],
            ),
            const SizedBox(height: AppDesign.spacing12),
            if (_isLoading)
              const Center(child: CircularProgressIndicator())
            else if (_photos.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(AppDesign.spacing24),
                  child: Text(
                    'Нет фото. Нажмите кнопку выше.',
                    style: AppDesign.captionStyle,
                  ),
                ),
              )
            else
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: AppDesign.spacing8,
                  mainAxisSpacing: AppDesign.spacing8,
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
            borderRadius: BorderRadius.circular(AppDesign.radiusListItem),
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
              decoration: BoxDecoration(
                color: AppDesign.statusCancelled.withOpacity(0.9),
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: const Icon(Icons.delete, color: Colors.white, size: 18),
                onPressed: () async {
                  onDelete(photo);
                  // Ждём завершения удаления в OrderBloc
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
