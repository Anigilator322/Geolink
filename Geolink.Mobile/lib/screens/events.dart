import 'package:flutter/material.dart';

class EventsSheet extends StatefulWidget {
  final VoidCallback onClose;
  const EventsSheet({super.key, required this.onClose});

  @override
  State<EventsSheet> createState() => _EventsSheetState();
}

class _EventsSheetState extends State<EventsSheet> {
  bool _isAddingEvent = false; 
  bool _isPublic = true; 

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Stack(
              alignment: Alignment.center,
              children: [
                if (_isAddingEvent)
                  Align(
                    alignment: Alignment.centerLeft,
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back),
                      onPressed: () => setState(() => _isAddingEvent = false),
                    ),
                  ),
                Text(
                  _isAddingEvent ? 'Новое мероприятие' : 'Список мероприятий',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: IconButton(
                    icon: const Icon(Icons.close, color: Colors.black, size: 24),
                    onPressed: widget.onClose,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: _isAddingEvent ? _buildAddEventForm() : _buildEventsList(),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 40),
            child: Center(
              child: SizedBox(
                width: 250,
                height: 45,
                child: ElevatedButton(
                  onPressed: () {
                    setState(() {
                      if (_isAddingEvent) {
                        _isAddingEvent = false; 
                      } else {
                        _isAddingEvent = true; 
                      }
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2E7D32),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  ),
                  child: Text(
                    _isAddingEvent ? 'Сохранить' : 'Добавить мероприятие',
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                  ),
                ),
              ),
            ),
          ),
        ],
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
                color: Color(0xFF2E7D32),
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
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            children: [
              _buildEventItem('Выступление группы', '20:00', '18.02.2026'),
              _buildEventItem('Мастер-класс по Flutter', '12:00', '20.02.2026'),
              _buildEventItem('Встреча сообщества', '18:30', '22.02.2026'),
            ],
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
                style: TextStyle(color: Color(0xFF2E7D32), decoration: TextDecoration.underline),
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
                    const Text('Начало', style: TextStyle(fontWeight: FontWeight.bold), textAlign: TextAlign.center),
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
              _buildCheckbox('Частное', !_isPublic),
              const SizedBox(width: 20),
              _buildCheckbox('Публичное', _isPublic),
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

  Widget _buildCheckbox(String label, bool value) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Checkbox(
          value: value,
          activeColor: const Color(0xFF2E7D32),
          onChanged: (v) => setState(() => _isPublic = (label == 'Публичное')),
        ),
        Text(label),
      ],
    );
  }

  Widget _buildEventItem(String name, String time, String date) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 15),
          child: Row(
            children: [
              Expanded(child: Text(name, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500))),
              SizedBox(width: 80, child: Text(time, style: const TextStyle(fontSize: 14), textAlign: TextAlign.center)),
              SizedBox(width: 80, child: Text(date, style: const TextStyle(fontSize: 14), textAlign: TextAlign.right)),
            ],
          ),
        ),
        const Divider(height: 1, thickness: 0.5, color: Colors.black45),
      ],
    );
  }
}

