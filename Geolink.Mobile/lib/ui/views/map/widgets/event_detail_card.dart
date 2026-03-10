import 'package:flutter/material.dart';
import '../../../../ui/core/theme/app_colors.dart';
import '../../../core/widgets/base_sheet.dart';
import '../../../../ui/view_models/events/events_view_model.dart';

class EventDetailCard extends StatelessWidget {
  final EventItem event;
  final VoidCallback onClose;
  final VoidCallback onShowOnMap;

  const EventDetailCard({
    super.key,
    required this.event,
    required this.onClose,
    required this.onShowOnMap,
  });

  @override
  Widget build(BuildContext context) {
    return BaseSheet(
      title: event.name,
      onClose: onClose,
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            _InfoRow(label: 'Дата:', value: event.date),
            const SizedBox(height: 8),
            _InfoRow(label: 'Время:', value: event.time),
            const SizedBox(height: 20),
            const Text(
              'Описание:',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 6),
            if (event.description.isNotEmpty)
              Text(
                event.description,
                style: const TextStyle(fontSize: 16, height: 1.5),
              ),
            const SizedBox(height: 20),
            if (event.authorName.isNotEmpty)
              Row(
                children: [
                  const Text(
                    'Автор: ',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                  ),
                  Text(
                    event.authorName,
                    style: const TextStyle(fontSize: 16, color: AppColors.primary),
                  ),
                ],
              ),
            const SizedBox(height: 16),
            GestureDetector(
              onTap: onShowOnMap,
              child: const Text(
                'Показать на карте',
                style: TextStyle(
                  fontSize: 16,
                  color: AppColors.primary,
                  decoration: TextDecoration.underline,
                  decorationColor: AppColors.primary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return RichText(
      text: TextSpan(
        style: const TextStyle(fontSize: 16, color: Colors.black),
        children: [
          TextSpan(text: '$label ', style: const TextStyle(fontWeight: FontWeight.w500)),
          TextSpan(text: value),
        ],
      ),
    );
  }
}



