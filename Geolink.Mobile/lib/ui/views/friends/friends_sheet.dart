import 'dart:async';

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
    unawaited(widget.viewModel.load());
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

  Widget _buildBody() {
    if (widget.viewModel.isLoading &&
        widget.viewModel.myFriends.isEmpty &&
        widget.viewModel.incomingRequests.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    final error = widget.viewModel.errorMessage;
    if (error != null &&
        error.isNotEmpty &&
        widget.viewModel.myFriends.isEmpty &&
        widget.viewModel.incomingRequests.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                error,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.red),
              ),
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: () => unawaited(widget.viewModel.load(force: true)),
              child: const Text('Повторить'),
            ),
          ],
        ),
      );
    }

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
              title: Text(friend.displayName),
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
        child: Text(
          'Нет входящих запросов',
          style: TextStyle(color: AppColors.textGrey),
        ),
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
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(
                      Icons.check_outlined,
                      color: AppColors.primary,
                      size: 28,
                    ),
                    onPressed: () => unawaited(_acceptRequest(request)),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.red, size: 28),
                    onPressed: () =>
                        widget.viewModel.dismissIncomingRequest(request),
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
              color: Colors.black.withValues(alpha: 0.15),
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
                onSubmitted: (_) => unawaited(_sendFriendRequestFromInput()),
                decoration: InputDecoration(
                  hintText: 'Введите имя пользователя',
                  prefixIcon: const Icon(
                    Icons.search,
                    color: AppColors.primary,
                  ),
                  suffixIcon: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (widget.viewModel.isSendingRequest)
                        const Padding(
                          padding: EdgeInsets.only(right: 8),
                          child: SizedBox(
                            height: 16,
                            width: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        )
                      else
                        IconButton(
                          icon: const Icon(Icons.send, size: 20),
                          onPressed: () =>
                              unawaited(_sendFriendRequestFromInput()),
                        ),
                      IconButton(
                        icon: const Icon(Icons.clear, size: 20),
                        onPressed: () {
                          _searchController.clear();
                          widget.viewModel.stopSearch();
                        },
                      ),
                    ],
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
              ConstrainedBox(
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
                        _searchController.text = user.displayName;
                        _searchController
                            .selection = TextSelection.fromPosition(
                          TextPosition(offset: _searchController.text.length),
                        );
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

  Future<void> _sendFriendRequestFromInput() async {
    final message = await widget.viewModel.sendFriendRequestByUsername(
      _searchController.text,
    );

    if (!mounted) {
      return;
    }

    if (message == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Запрос отправлен')));
      _searchController.clear();
      widget.viewModel.stopSearch();
      return;
    }

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _acceptRequest(FriendListItem request) async {
    final message = await widget.viewModel.acceptFriendRequest(request);
    if (!mounted || message == null) {
      return;
    }

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}
