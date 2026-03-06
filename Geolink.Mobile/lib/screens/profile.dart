import 'package:flutter/material.dart';

class ProfileSheet extends StatefulWidget {
  final VoidCallback onClose;
  const ProfileSheet({super.key, required this.onClose});

  @override
  State<ProfileSheet> createState() => _ProfileSheetState();
}

class _ProfileSheetState extends State<ProfileSheet> {
  bool _isEditing = false; 

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
                if (_isEditing)
                  Align(
                    alignment: Alignment.centerLeft,
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back),
                      onPressed: () => setState(() => _isEditing = false),
                    ),
                  ),
                
                const Text(
                  'Профиль',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),

                Align(
                  alignment: Alignment.centerRight,
                  child: Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (!_isEditing) 
                          IconButton(
                            icon: const Icon(Icons.edit, color: Colors.grey, size: 22),
                            onPressed: () => setState(() => _isEditing = true),
                          ),
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.black, size: 22),
                          onPressed: widget.onClose,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Center(
            child: Column(
              children: [
                Container(
                  width: 140,
                  height: 140,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.grey[300],
                  ),
                  child: const Icon(Icons.person, size: 60, color: Colors.grey),
                ),
                if (_isEditing) 
                  TextButton(
                    onPressed: () {},
                    child: const Text(
                      'Загрузить новое фото',
                      style: TextStyle(
                        color: Color(0xFF2E7D32),
                        fontSize: 14,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: _isEditing 
              ? TextFormField(
                  initialValue: 'Тимофеев Игнат',
                  enabled: false, 
                  decoration: const InputDecoration(
                    labelText: 'Имя пользователя',
                    border: OutlineInputBorder(),
                  ),
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Имя пользователя:', style: TextStyle(fontSize: 16)),
                    Text('Тимофеев Игнат', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w500)),
                  ],
                ),
          ),
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: _isEditing
              ? TextFormField(
                  initialValue: 'Информация о пользователе...',
                  enabled: false, 
                  maxLines: 4,
                  maxLength: 500, 
                  decoration: const InputDecoration(
                    labelText: 'О себе',
                    alignLabelWithHint: true,
                    border: OutlineInputBorder(),
                  ),
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('О себе:', style: TextStyle(fontSize: 16)),
                    const SizedBox(height: 4),
                    const Text(
                      'Информация о пользователе, подробное описание профиля.',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
          ),

          const Spacer(),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
            child: _isEditing
                ? Center(
                    child: SizedBox(
                      width: double.infinity, 
                      height: 50,
                      child: ElevatedButton(
                        onPressed: () {
                          setState(() => _isEditing = false);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2E7D32), 
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12), 
                          ),
                          elevation: 0,
                        ),
                        child: const Text(
                          'Сохранить',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.normal, 
                          ),
                        ),
                      ),
                    ),
                  )
                : GestureDetector(
                    onTap: widget.onClose,
                    behavior: HitTestBehavior.opaque,
                    child: const Text(
                      'Выйти из профиля',
                      style: TextStyle(
                        color: Colors.red,
                        fontSize: 16,
                        decoration: TextDecoration.underline,
                        decorationColor: Colors.red,
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
