import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/database/app_database.dart';
import '../../../core/theme/app_theme.dart';

class ItemsScreen extends ConsumerStatefulWidget {
  const ItemsScreen({super.key});

  @override
  ConsumerState<ItemsScreen> createState() => _ItemsScreenState();
}

class _ItemsScreenState extends ConsumerState<ItemsScreen> {
  @override
  Widget build(BuildContext context) {
    final db = context.read<AppDatabase>();
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Items'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () => showSearch(context: context, delegate: _ItemSearch(db)),
          ),
        ],
      ),
      body: FutureBuilder(
        future: db.getAllItems(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No items found. Add your first item!', style: TextStyle(color: Colors.grey)));
          }
          
          final items = snapshot.data!;
          
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index];
              final isLowStock = item.stock <= item.lowStockThreshold;
              
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: isLowStock ? AppTheme.dangerColor : AppTheme.successColor,
                    child: Text('${item.stock}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                  title: Text(item.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: Text('${item.category ?? 'General'} • SKU: ${item.sku ?? 'N/A'}'),
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text('₹${item.salePrice}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.primaryColor)),
                      if (isLowStock) const Text('Low Stock', style: TextStyle(color: AppTheme.dangerColor, fontSize: 12)),
                    ],
                  ),
                  onTap: () => _showDetails(context, item),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Add item feature - Coming soon')),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
  
  void _showDetails(BuildContext context, Item item) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(item.name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            _buildDetailRow('Purchase Price', '₹${item.purchasePrice}'),
            _buildDetailRow('Sale Price', '₹${item.salePrice}'),
            _buildDetailRow('GST', '${item.gstPercent}%'),
            _buildDetailRow('Stock', '${item.stock} ${item.unit}'),
            _buildDetailRow('Supplier', item.supplier ?? 'N/A'),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.edit),
                label: const Text('Edit Item'),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _ItemSearch extends SearchDelegate {
  final AppDatabase db;
  
  _ItemSearch(this.db);
  
  @override
  List<Widget> buildActions(BuildContext context) {
    return [IconButton(icon: const Icon(Icons.clear), onPressed: () => query = '')];
  }
  
  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => close(context, null));
  }
  
  @override
  Widget buildResults(BuildContext context) => buildSuggestions(context);
  
  @override
  Widget buildSuggestions(BuildContext context) {
    return FutureBuilder(
      future: db.getAllItems(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        
        final items = snapshot.data!;
        final results = items.where((i) => i.name.toLowerCase().contains(query.toLowerCase())).toList();
        
        return ListView.builder(
          itemCount: results.length,
          itemBuilder: (context, index) {
            final item = results[index];
            return ListTile(
              title: Text(item.name),
              subtitle: Text('₹${item.salePrice}'),
              onTap: () => close(context, item),
            );
          },
        );
      },
    );
  }
}