import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/base_sheet.dart';
import '../../view_models/events/events_view_model.dart';

class EventsSheet extends StatelessWidget {
  final VoidCallback onClose;
  final EventsViewModel viewModel;
  final void Function(EventItem event) onEventTap;

  const EventsSheet({
    super.key,
    required this.onClose,
    required this.viewModel,
    required this.onEventTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: viewModel,
      builder: (context, _) => BaseSheet(
        title: viewModel.isAddingEvent ? 'Новое мероприятие' : 'Список мероприятий',
        onClose: onClose,
        leading: viewModel.isAddingEvent
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: viewModel.cancelAddEvent,
              )
            : null,
        body: viewModel.isAddingEvent ? _buildAddEventForm() : _buildEventsList(),
        bottomButton: _buildBottomButton(),
      ),
    );
  }

  Widget _buildEventsList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: GestureDetector(
            onTap: () {},
            child: const Text(
              'Показать на карте',
              style: TextStyle(
                color: AppColors.primary,
                fontSize: 14,
                decoration: TextDecoration.underline,
              ),
            ),
          ),
        ),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 20, vertical: 5),
          child: Row(
            children: [
              SizedBox(width: 10),
              Expanded(child: Text('Название', style: TextStyle(fontSize: 16))),
              SizedBox(
                width: 70,
                child: Text('Начало', style: TextStyle(fontSize: 16), textAlign: TextAlign.center),
              ),
              SizedBox(
                width: 90,
                child: Padding(
                  padding: EdgeInsets.only(right: 10),
                  child: Text('Дата', style: TextStyle(fontSize: 16), textAlign: TextAlign.right),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: viewModel.events.length,
            itemBuilder: (context, index) {
              final event = viewModel.events[index];
              return Column(
                children: [
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(event.name),
                    subtitle: Text('${event.date}  ${event.time}'),
                    onTap: () {
                      onClose();
                      onEventTap(event);
                    },
                  ),
                  const Divider(height: 1, thickness: 0.5),
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildAddEventForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 10),
          const Text('Адрес', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          _buildTextField('г.Томск Ленина 67'),
          GestureDetector(
            onTap: () {},
            child: const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Text(
                'Указать на карте',
                style: TextStyle(
                  color: AppColors.primary,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Text('Название', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          _buildTextField('Выступление группы'),
          const SizedBox(height: 24),
          TextFormField(
            decoration: const InputDecoration(
              labelText: 'Дата',
              hintText: 'mm/dd/yyyy',
              floatingLabelBehavior: FloatingLabelBehavior.always,
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 24),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Начало', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    _buildTextField('20:00'),
                  ],
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                child: Text('-', style: TextStyle(fontSize: 24, color: Colors.black26)),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Конец', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    _buildTextField('22:00'),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          const Text('Статус:', style: TextStyle(fontWeight: FontWeight.bold)),
          Row(
            children: [
              _StatusCheckbox(
                label: 'Частное',
                value: !viewModel.isPublic,
                onChanged: (_) => viewModel.setPublic(false),
              ),
              const SizedBox(width: 20),
              _StatusCheckbox(
                label: 'Публичное',
                value: viewModel.isPublic,
                onChanged: (_) => viewModel.setPublic(true),
              ),
            ],
          ),
          const SizedBox(height: 24),
          const Text('Описание:', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          TextFormField(
            maxLines: 5,
            maxLength: 500,
            decoration: const InputDecoration(
              hintText: 'Описание',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildTextField(String hint) {
    return TextFormField(
      decoration: InputDecoration(
        hintText: hint,
        border: const OutlineInputBorder(),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      ),
    );
  }

  Widget _buildBottomButton() {
    return SizedBox(
      width: 250,
      height: 45,
      child: ElevatedButton(
        onPressed: viewModel.isAddingEvent ? viewModel.saveEvent : viewModel.showAddEvent,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        ),
        child: Text(
          viewModel.isAddingEvent ? 'Сохранить' : 'Добавить мероприятие',
          style: const TextStyle(color: Colors.white, fontSize: 14),
        ),
      ),
    );
  }
}

class _StatusCheckbox extends StatelessWidget {
  final String label;
  final bool value;
  final ValueChanged<bool?> onChanged;

  const _StatusCheckbox({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Checkbox(value: value, activeColor: AppColors.primary, onChanged: onChanged),
        Text(label),
      ],
    );
  }
}