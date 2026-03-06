import 'package:flutter/material.dart';

class FriendsSheet extends StatefulWidget {
  final VoidCallback onClose;
  const FriendsSheet({super.key, required this.onClose});

  @override
  State<FriendsSheet> createState() => _FriendsSheetState();
}

class _FriendsSheetState extends State<FriendsSheet> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();

  final List<String> _allUsers = ['Анастасия', 'Анатолий', 'Анита', 'Антон', 'Борис', 'Виктор'];
  List<String> _searchResults = [];

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

  void _onSearch(String query) {
    setState(() {
      _searchResults = query.isEmpty 
          ? [] 
          : _allUsers.where((u) => u.toLowerCase().startsWith(query.toLowerCase())).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(topLeft: Radius.circular(20), topRight: Radius.circular(20)),
      ),
      child: Stack(
        children: [
          Column(
            children: [
              _buildHeader(),
              _buildTabBar(),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: const [
                    Center(child: Text('Список друзей')),
                    Center(child: Text('Запросы')),
                    Center(child: Text('Приглашения')),
                  ],
                ),
              ),
            ],
          ),
          if (_isSearching)
            Positioned(
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
                      padding: const EdgeInsets.all(8.0),
                      child: TextField(
                        controller: _searchController,
                        autofocus: true,
                        onChanged: _onSearch,
                        decoration: InputDecoration(
                          hintText: 'Поиск...',
                          prefixIcon: const Icon(Icons.search, color: Color(0xFF2E7D32)),
                          suffixIcon: IconButton(
                            icon: const Icon(Icons.clear, size: 20),
                            onPressed: () => setState(() {
                              _isSearching = false;
                              _searchController.clear();
                              _searchResults = [];
                            }),
                          ),
                          filled: true,
                          fillColor: const Color(0xFFF5F5F5),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                    ),
                    if (_searchResults.isNotEmpty)
                      Container(
                        constraints: const BoxConstraints(maxHeight: 200),
                        child: ListView.builder(
                          padding: EdgeInsets.zero,
                          shrinkWrap: true,
                          itemCount: _searchResults.length,
                          itemBuilder: (context, index) => ListTile(
                            title: Text(_searchResults[index]),
                            onTap: () {
                              setState(() {
                                _isSearching = false;
                                _searchController.clear();
                              });
                            },
                          ),
                        ),
                      ),
                  ],
                ),
              ),
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
          const Text('Друзья', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500)),
          Align(
            alignment: Alignment.centerRight,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.search),
                  onPressed: () => setState(() => _isSearching = true),
                ),
                IconButton(icon: const Icon(Icons.close), onPressed: widget.onClose),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Stack(
      alignment: Alignment.bottomCenter,
      children: [
        const Divider(height: 1, thickness: 1, color: Color(0xFFE0E0E0)),
        TabBar(
          controller: _tabController,
          labelColor: const Color(0xFF2E7D32),
          unselectedLabelColor: Colors.grey,
          indicator: const UnderlineTabIndicator(
            borderSide: BorderSide(width: 4, color: Color(0xFF2E7D32)),
            insets: EdgeInsets.symmetric(horizontal: 20),
          ),
          tabs: const [Tab(text: 'Мои друзья'), Tab(text: 'Запросы'), Tab(text: 'Приглашения')],
        ),
      ],
    );
  }
}
