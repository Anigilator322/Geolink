import 'package:flutter/material.dart';

class BaseSheet extends StatelessWidget {
  final String title;
  final VoidCallback onClose;
  final Widget body;
  final Widget? leading;
  final List<Widget> actions;
  final Widget? bottomButton;

  const BaseSheet({
    super.key,
    required this.title,
    required this.onClose,
    required this.body,
    this.leading,
    this.actions = const [],
    this.bottomButton,
  });

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
          _buildHeader(),
          Expanded(child: body),
          if (bottomButton != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 40),
              child: Center(child: bottomButton),
            ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Stack(
        alignment: Alignment.center,
        children: [
          if (leading != null)
            Align(alignment: Alignment.centerLeft, child: leading),
          Text(
            title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                ...actions,
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.black, size: 24),
                  onPressed: onClose,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}