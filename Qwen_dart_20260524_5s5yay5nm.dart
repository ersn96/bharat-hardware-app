import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:responsive_framework/responsive_framework.dart';
import '../../../data/database/app_database.dart';
import '../../../core/theme/app_theme.dart';
import '../../billing/screens/new_sale_screen.dart';
import '../../items/screens/items_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final db = context.read<AppDatabase>();
    final isDesktop = ResponsiveWrapper.of(context).isLargerThan(DESKTOP);
    
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Bharat Hardware', style: TextStyle(fontSize: 18)),
            Text('Er. Shaikh Naeem', style: TextStyle(fontSize: 12, color: Colors.white70)),
          ],
        ),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: () => setState(() {})),
        ],
      ),
      body: FutureBuilder(
        future: db.getTodayStats(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          
          final stats = snapshot.data as Map<String, dynamic>? ?? {};
          
          return RefreshIndicator(
            onRefresh: () async => setState(() {}),
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _buildSummaryCards(stats, isDesktop),
                const SizedBox(height: 24),
                _buildQuickActions(isDesktop),
                const SizedBox(height: 24),
                _buildLowStockAlert(db),
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const NewSaleScreen())),
        icon: const Icon(Icons.add_shopping_cart),
        label: const Text('New Sale'),
      ),
      bottomNavigationBar: isDesktop ? null : BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() => _selectedIndex = index);
          if (index == 1) {
            Navigator.push(context, MaterialPageRoute(builder: (_) => const ItemsScreen()));
          } else if (index == 2) {
            Navigator.push(context, MaterialPageRoute(builder: (_) => const NewSaleScreen()));
          }
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.inventory), label: 'Items'),
          BottomNavigationBarItem(icon: Icon(Icons.receipt), label: 'Billing'),
        ],
      ),
    );
  }
  
  Widget _buildSummaryCards(Map<String, dynamic> stats, bool isDesktop) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: isDesktop ? 4 : 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.5,
      children: [
        _summaryCard('${stats['todaySale']?.toStringAsFixed(0) ?? '0'}', 'Today Sale', AppTheme.successColor, Icons.trending_up),
        _summaryCard('₹${stats['stockValue']?.toStringAsFixed(0) ?? '0'}', 'Stock Value', AppTheme.primaryColor, Icons.inventory_2),
        _summaryCard('${stats['billsCount'] ?? 0}', 'Bills Today', AppTheme.warningColor, Icons.receipt_long),
        if (isDesktop) _summaryCard('${stats['totalItems'] ?? 0}', 'Total Items', AppTheme.dangerColor, Icons.shopping_basket),
      ],
    );
  }
  
  Widget _summaryCard(String value, String label, Color color, IconData icon) {
    return Card(
      color: color,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 28),
            const SizedBox(height: 8),
            Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
            Text(label, style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.9))),
          ],
        ),
      ),
    );
  }
  
  Widget _buildQuickActions(bool isDesktop) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Quick Actions', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: isDesktop ? 4 : 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.2,
          children: [
            _quickActionTile('New Sale', Icons.point_of_sale, AppTheme.successColor, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const NewSaleScreen()))),
            _quickActionTile('Add Item', Icons.add_box, AppTheme.primaryColor, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ItemsScreen()))),
            _quickActionTile('View Items', Icons.inventory, AppTheme.warningColor, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ItemsScreen()))),
            _quickActionTile('Reports', Icons.bar_chart, AppTheme.dangerColor, () {}),
          ],
        ),
      ],
    );
  }
  
  Widget _quickActionTile(String title, IconData icon, Color color, VoidCallback onTap) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 32, color: color),
              const SizedBox(height: 8),
              Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildLowStockAlert(AppDatabase db) {
    return FutureBuilder(
      future: db.getLowStockItems(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const SizedBox.shrink();
        }
        
        final items = snapshot.data!;
        
        return Card(
          color: AppTheme.warningColor.withOpacity(0.1),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.warning, color: AppTheme.warningColor),
                    const SizedBox(width: 8),
                    const Text('Low Stock Alert', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 12),
                ...items.take(3).map((item) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Text('• ${item.name} - ${item.stock} left', style: const TextStyle(fontSize: 14)),
                )),
              ],
            ),
          ),
        );
      },
    );
  }
}