import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/base_sheet.dart';
import '../../view_models/friends/friends_view_model.dart';

class FriendsSheet extends StatefulWidget {
  final VoidCallback onClose;
  final FriendsViewModel viewModel;

  const FriendsSheet({
    super.key,
    required this.onClose,
    required this.viewModel,
  });

  @override
  State<FriendsSheet> createState() => _FriendsSheetState();
}

class _FriendsSheetState extends State<FriendsSheet>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }
   
  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.viewModel,
      builder: (context, _) => Stack(
        children: [
          BaseSheet(
            title: 'Друзья',
            onClose: widget.onClose,
            actions: [
              IconButton(
                icon: const Icon(Icons.search),
                onPressed: widget.viewModel.startSearch,
              ),
            ],
            body: _buildBody(),
          ),
          if (widget.viewModel.isSearching) _buildSearchOverlay(),
        ],
      ),
    );
  }
  Widget _buildMyFriendsList() {
  final friends = widget.viewModel.myFriends;
  if (friends.isEmpty) {
    return const Center(
      child: Text('Нет друзей', style: TextStyle(color: AppColors.textGrey)),
    );
  }
  return ListView.builder(
    padding: const EdgeInsets.symmetric(horizontal: 20),
    itemCount: friends.length,
    itemBuilder: (context, index) {
      final friend = friends[index];
      return Column(
        children: [
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: CircleAvatar(
              backgroundColor: Colors.grey[300],
              child: const Icon(Icons.person, color: Colors.grey),
            ),
            title: Text(friend.displayName), // ← только имя, без bio
          ),
          const Divider(height: 1, thickness: 0.5),
        ],
      );
    },
  );
}

Widget _buildRequestsList() {
  final requests = widget.viewModel.incomingRequests;
  if (requests.isEmpty) {
    return const Center(
      child: Text('Нет запросов', style: TextStyle(color: AppColors.textGrey)),
    );
  }
  return ListView.builder(
    padding: const EdgeInsets.symmetric(horizontal: 20),
    itemCount: requests.length,
    itemBuilder: (context, index) {
      final request = requests[index];
      return Column(
        children: [
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: CircleAvatar(
              backgroundColor: Colors.grey[300],
              child: const Icon(Icons.person, color: Colors.grey),
            ),
            title: Text(request.displayName),
            // Иконки максимально справа
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.check_outlined,
                      color: AppColors.primary, size: 28),
                  onPressed: () {},
                ),
                IconButton(
                  icon: const Icon(Icons.close,
                      color: Colors.red, size: 28),
                  onPressed: () {},
                ),
              ],
            ),
          ),
          const Divider(height: 1, thickness: 0.5),
        ],
      );
    },
  );
}
  // ── Body ───────────────────────────────────────────────────────────────────

  Widget _buildBody() {
    return Column(
      children: [
        _buildTabBar(),
        Expanded(
          child: TabBarView(
              controller: _tabController,
              children: [
                _buildMyFriendsList(),
                _buildRequestsList(),
                const Center(child: Text('Приглашения')), 
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
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textGrey,
          indicator: const UnderlineTabIndicator(
            borderSide: BorderSide(width: 4, color: AppColors.primary),
            insets: EdgeInsets.symmetric(horizontal: 20),
          ),
          tabs: const [
            Tab(text: 'Мои друзья'),
            Tab(text: 'Запросы'),
            Tab(text: 'Приглашения'),
          ],
        ),
      ],
    );
  }

  // ── Search overlay ─────────────────────────────────────────────────────────

  Widget _buildSearchOverlay() {
    return Positioned(
      top: 60,
      left: 15,
      right: 15,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 20,
              spreadRadius: 5,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(8),
              child: TextField(
                controller: _searchController,
                autofocus: true,
                onChanged: widget.viewModel.onSearch,
                decoration: InputDecoration(
                  hintText: 'Поиск...',
                  prefixIcon: const Icon(Icons.search, color: AppColors.primary),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.clear, size: 20),
                    onPressed: () {
                      _searchController.clear();
                      widget.viewModel.stopSearch();
                    },
                  ),
                  filled: true,
                  fillColor: AppColors.inputBackground,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ),
            if (widget.viewModel.searchResults.isNotEmpty)
              Container(
                constraints: const BoxConstraints(maxHeight: 200),
                child: ListView.builder(
                  padding: EdgeInsets.zero,
                  shrinkWrap: true,
                  itemCount: widget.viewModel.searchResults.length,
                 itemBuilder: (context, index) {
                    final user = widget.viewModel.searchResults[index]; 
                    return ListTile(
                      title: Text(user.displayName),
                      subtitle: user.bio.isNotEmpty ? Text(user.bio) : null,
                      onTap: () {
                        _searchController.clear();
                        widget.viewModel.stopSearch();
                      },
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}
