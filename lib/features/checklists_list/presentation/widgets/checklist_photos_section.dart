import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../bloc/order_bloc.dart';
import '../../../../bloc/order_event.dart';
import '../../../../models/order.dart';
import '../../../../models/checklist_config.dart';
import '../../../../utils/app_design.dart';

/// Секция фотофиксации в чек-листе
class ChecklistPhotosSection extends StatelessWidget {
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
                  onPressed: onTakePhoto,
                  icon: const Icon(Icons.camera_alt, size: 18),
                  label: const Text('Добавить фото'),
                  style: AppDesign.accentButtonStyle,
                ),
              ],
            ),
            const SizedBox(height: AppDesign.spacing12),
            BlocBuilder<OrderBloc, OrderState>(
              builder: (context, state) {
                if (state is OrderLoaded) {
                  final order = state.orders.firstWhere(
                    (o) => o.id == orderId,
                    orElse: () => Order(
                      id: orderId,
                      clientName: '',
                      address: '',
                      date: DateTime.now(),
                      workType: WorkType.windows,
                      createdAt: DateTime.now(),
                      updatedAt: DateTime.now(),
                    ),
                  );
                  if (order.photos.isEmpty) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(AppDesign.spacing24),
                        child: Text(
                          'Нет фото. Нажмите кнопку выше.',
                          style: AppDesign.captionStyle,
                        ),
                      ),
                    );
                  }

                  return GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          crossAxisSpacing: AppDesign.spacing8,
                          mainAxisSpacing: AppDesign.spacing8,
                        ),
                    itemCount: order.photos.length,
                    itemBuilder: (context, index) {
                      final photo = order.photos[index];
                      return _PhotoThumbnail(
                        photo: photo,
                        onTap: onViewPhoto,
                        onDelete: onDeletePhoto,
                      );
                    },
                  );
                }
                return const SizedBox.shrink();
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

  const _PhotoThumbnail({
    required this.photo,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onTap(photo),
      child: Stack(
        fit: StackFit.expand,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(AppDesign.radiusListItem),
            child: Image.file(
              File(photo.annotatedPath ?? photo.filePath),
              fit: BoxFit.cover,
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
                onPressed: () => onDelete(photo),
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
