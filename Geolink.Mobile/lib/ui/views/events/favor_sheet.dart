import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/base_sheet.dart';
import '../../view_models/events/favor_view_model.dart';

class FavorSheet extends StatefulWidget {
  final VoidCallback onClose;
  final FavorViewModel viewModel;

  const FavorSheet({
    super.key,
    required this.onClose,
    required this.viewModel,
  });

  @override
  State<FavorSheet> createState() => _FavorSheetState();
}

class _FavorSheetState extends State<FavorSheet>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.viewModel,
      builder: (context, _) => BaseSheet(
        title: 'Избранные мероприятия',
        onClose: widget.onClose,
        body: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    return Column(
      children: [
        _buildTabBar(),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildMyEventsTab(),
              _buildInvitationsTab(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTabBar() {
    return Stack(
      alignment: Alignment.bottomCenter,
      children: [
        const Divider(height: 1, thickness: 1, color: AppColors.divider),
        TabBar(
          controller: _tabController,
          labelColor: AppColors.accent,
          unselectedLabelColor: AppColors.textGrey,
          indicator: const UnderlineTabIndicator(
            borderSide: BorderSide(width: 4, color: AppColors.accent),
            insets: EdgeInsets.symmetric(horizontal: 20),
          ),
          tabs: const [
            Tab(text: 'Мои'),
            Tab(text: 'Приглашения'),
          ],
        ),
      ],
    );
  }

  Widget _buildMyEventsTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildColumnHeader(col2: 'Начало', col3: 'Дата'),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: widget.viewModel.myEvents.length,
            itemBuilder: (context, index) {
              final item = widget.viewModel.myEvents[index];
              return Column(
                children: [
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(item.name),
                    trailing: Text('${item.time}  ${item.date}'),
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

  Widget _buildInvitationsTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildColumnHeader(col2: 'Дата', col3: 'Подтверждение'),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: widget.viewModel.invitations.length,
            itemBuilder: (context, index) {
              final item = widget.viewModel.invitations[index];
              return Column(
                children: [
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(item.name),
                    subtitle: Text(item.date),
                    trailing: item.accepted
                        ? const Icon(Icons.check_circle, color: AppColors.primary)
                        : const Icon(Icons.pending, color: AppColors.textGrey),
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

  Widget _buildColumnHeader({required String col2, required String col3}) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 15, 20, 5),
      child: Row(
        children: [
          const SizedBox(width: 10),
          const Expanded(
            child: Text('Название', style: TextStyle(fontSize: 16)),
          ),
          SizedBox(
            width: 80,
            child: Text(
              col2,
              style: const TextStyle(fontSize: 16),
              textAlign: TextAlign.center,
            ),
          ),
          SizedBox(
            width: 140,
            child: Padding(
              padding: const EdgeInsets.only(right: 10),
              child: Text(
                col3,
                style: const TextStyle(fontSize: 15),
                textAlign: TextAlign.right,
              ),
            ),
          ),
        ],
      ),
    );
  }
}