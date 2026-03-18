import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/base_sheet.dart';
import '../../view_models/profile/profile_view_model.dart';
import '../../../data/services/local/secure_storage_service.dart';

class ProfileSheet extends StatefulWidget {
  final VoidCallback onClose;
  final ProfileViewModel viewModel;

  const ProfileSheet({
    super.key,
    required this.onClose,
    required this.viewModel,
  });

  @override
  State<ProfileSheet> createState() => _ProfileSheetState();
}

class _ProfileSheetState extends State<ProfileSheet> {
  late final TextEditingController _usernameController;
  late final TextEditingController _bioController;

  @override
  void initState() {
    super.initState();
    _usernameController = TextEditingController(text: widget.viewModel.username);
    _bioController = TextEditingController(text: widget.viewModel.bio);
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.viewModel,
      builder: (context, _) {
        if (!widget.viewModel.isEditing) {
          _usernameController.text = widget.viewModel.username;
          _bioController.text = widget.viewModel.bio;
        }
        return BaseSheet(
          title: 'Профиль',
          onClose: widget.onClose,
          leading: widget.viewModel.isEditing
              ? IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: widget.viewModel.cancelEditing,
                )
              : null,
          actions: [
            if (!widget.viewModel.isEditing)
              IconButton(
                icon: const Icon(Icons.edit, color: AppColors.iconGrey, size: 22),
                onPressed: widget.viewModel.startEditing,
              ),
          ],
          body: _buildBody(),
          bottomButton: _buildBottomButton(),
        );
      },
    );
  }

  Widget _buildBody() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 10),
          _buildAvatar(),
          const SizedBox(height: 20),
          _buildNameField(),
          const SizedBox(height: 20),
          _buildBioField(),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildAvatar() {
    return Center(
      child: Column(
        children: [
          Container(
            width: 140,
            height: 140,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.grey[300],
            ),
            child: widget.viewModel.avatarUrl != null
                ? ClipOval(
                    child: Image.network(
                      widget.viewModel.avatarUrl!,
                      fit: BoxFit.cover,
                    ),
                  )
                : const Icon(Icons.person, size: 60, color: Colors.grey),
          ),
          if (widget.viewModel.isEditing)
            TextButton(
              onPressed: () {},
              child: const Text(
                'Загрузить новое фото',
                style: TextStyle(
                  color: AppColors.primary,
                  fontSize: 14,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildNameField() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: widget.viewModel.isEditing
          ? TextFormField(
              controller: _usernameController,
              decoration: const InputDecoration(
                labelText: 'Имя пользователя',
                border: OutlineInputBorder(),
              ),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Имя пользователя:', style: TextStyle(fontSize: 16)),
                Text(
                  widget.viewModel.username,
                  style: const TextStyle(
                      fontSize: 22, fontWeight: FontWeight.w500),
                ),
              ],
            ),
    );
  }

  Widget _buildBioField() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: widget.viewModel.isEditing
          ? TextFormField(
              controller: _bioController,
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
                Text(
                  widget.viewModel.bio,
                  style: const TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w500),
                ),
              ],
            ),
    );
  }

  Widget? _buildBottomButton() {
    if (widget.viewModel.isEditing) {
      return SizedBox(
        width: double.infinity,
        height: 50,
        child: ElevatedButton(
        onPressed: widget.viewModel.isSaving ? null : () async {
                final ok = await widget.viewModel.saveProfile(
                  newUsername: _usernameController.text,
                  newBio: _bioController.text,
                );

                if (!mounted) return;

                if (!ok && widget.viewModel.error != null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(widget.viewModel.error!)),
                  );
                }
                },
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: widget.viewModel.isSaving
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Text(
                  'Сохранить',
                  style: TextStyle(color: Colors.white, fontSize: 14),
                ),
        ),
      );
    }

    return GestureDetector(
      onTap: () async {
        await SecureStorageService().clear();
        if (!mounted) return;
        Navigator.pushNamedAndRemoveUntil(context, '/email', (route) => false);
      },
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
    );
  }
}