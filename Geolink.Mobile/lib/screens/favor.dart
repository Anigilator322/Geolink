import 'package:flutter/material.dart';

class FavorSheet extends StatefulWidget {
  final VoidCallback onClose;
  const FavorSheet({super.key, required this.onClose});

  @override
  State<FavorSheet> createState() => _FavorSheetState();
}

class _FavorSheetState extends State<FavorSheet> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final Color activeColor = const Color(0xFF6750A3); 

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
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Stack(
              alignment: Alignment.center,
              children: [
                const Text(
                  'Избранные мероприятия',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
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

          Stack(
            alignment: Alignment.bottomCenter,
            children: [
              const Divider(height: 1, thickness: 1, color: Color(0xFFE0E0E0)),
              TabBar(
                controller: _tabController,
                labelColor: activeColor,
                unselectedLabelColor: Colors.grey,
                indicatorColor: activeColor,
                indicatorWeight: 4,
                indicatorSize: TabBarIndicatorSize.label,
                indicator: UnderlineTabIndicator(
                  borderSide: BorderSide(width: 4, color: activeColor),
                  insets: const EdgeInsets.symmetric(horizontal: 20),
                ),
                tabs: const [
                  Tab(text: 'Мои'),
                  Tab(text: 'Приглашения'),
                ],
              ),
            ],
          ),

          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildMyTab(),
                _buildInvitationsTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMyTab() {
    return Column(
      children: [
        _buildHeader(col2: 'Начало', col3: 'Дата'),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            children: const [],
          ),
        ),
      ],
    );
  }

  Widget _buildInvitationsTab() {
    return Column(
      children: [
        _buildHeader(col2: 'Дата', col3: 'Подтверждение'), 
        Expanded(
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            children: const [],
          ),
        ),
      ],
    );
  }

  Widget _buildHeader({required String col2, required String col3}) {
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
            child: Text(col2, style: const TextStyle(fontSize: 16), textAlign: TextAlign.center),
          ),
          SizedBox(
            width: 140, 
            child: Padding(
              padding: const EdgeInsets.only(right: 10),
              child: Text(col3, style: const TextStyle(fontSize: 15), textAlign: TextAlign.right),
            ),
          ),
        ],
      ),
    );
  }
}
