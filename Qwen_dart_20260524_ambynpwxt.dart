import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../data/database/app_database.dart';

class NewSaleScreen extends ConsumerStatefulWidget {
  const NewSaleScreen({super.key});

  @override
  ConsumerState<NewSaleScreen> createState() => _NewSaleScreenState();
}

class _NewSaleScreenState extends ConsumerState<NewSaleScreen> {
  final _customerCtrl = TextEditingController(text: 'Walk-in Customer');
  final _mobileCtrl = TextEditingController();
  final _discountCtrl = TextEditingController(text: '0');
  List<_CartItem> _cart = [];
  PaymentMode _mode = PaymentMode.cash;
  bool _gstOn = true;

  @override
  void dispose() {
    _customerCtrl.dispose();
    _mobileCtrl.dispose();
    _discountCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final db = context.read<AppDatabase>();
    final allItems = db.getAllItems();
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('New Sale'),
        actions: [
          IconButton(
            icon: const Icon(Icons.qr_code_scanner),
            onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Barcode scanner - Coming soon')),
            ),
          ),
        ],
      ),
      body: FutureBuilder(
        future: allItems,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          
          final items = snapshot.data!;
          
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    TextField(
                      controller: _customerCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Customer Name',
                        prefixIcon: Icon(Icons.person),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _mobileCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Mobile Number',
                        prefixIcon: Icon(Icons.phone),
                      ),
                      keyboardType: TextInputType.phone,
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Autocomplete<Item>(
                  optionsBuilder: (value) {
                    if (value.text.isEmpty) return const Iterable<Item>.empty();
                    return items.where((i) => 
                      i.name.toLowerCase().contains(value.text.toLowerCase())
                    );
                  },
                  displayStringForOption: (item) => '${item.name} - ₹${item.salePrice}',
                  fieldViewBuilder: (context, ctrl, focus, onSub) {
                    return TextField(
                      controller: ctrl,
                      focusNode: focus,
                      decoration: const InputDecoration(
                        labelText: 'Search Item',
                        prefixIcon: Icon(Icons.search),
                      ),
                    );
                  },
                  onSelected: (item) {
                    setState(() => _cart.add(_CartItem(item: item, qty: 1)));
                    FocusScope.of(context).unfocus();
                  },
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: _cart.isEmpty
                    ? const Center(child: Text('Search & add items', style: TextStyle(color: Colors.grey)))
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: _cart.length,
                        itemBuilder: (context, index) {
                          final ci = _cart[index];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            child: ListTile(
                              title: Text(ci.item.name),
                              subtitle: Text('₹${ci.item.salePrice} x ${ci.qty}'),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text('₹${ci.total.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold)),
                                  IconButton(
                                    icon: const Icon(Icons.delete, color: Colors.red),
                                    onPressed: () => setState(() => _cart.removeAt(index)),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 8)],
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Subtotal:', style: TextStyle(fontSize: 16)),
                        Text('₹${_subtotal.toStringAsFixed(2)}', style: const TextStyle(fontSize: 16)),
                      ],
                    ),
                    if (_gstOn)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('GST (18%):', style: TextStyle(fontSize: 16)),
                          Text('₹${_gst.toStringAsFixed(2)}', style: const TextStyle(fontSize: 16)),
                        ],
                      ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Discount:', style: TextStyle(fontSize: 16)),
                        SizedBox(
                          width: 100,
                          child: TextField(
                            controller: _discountCtrl,
                            decoration: const InputDecoration(suffixText: '₹'),
                            keyboardType: TextInputType.number,
                            onChanged: (_) => setState(() {}),
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('TOTAL:', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                        Text('₹${_total.toStringAsFixed(2)}', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppTheme.successColor)),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        _payBtn('Cash', PaymentMode.cash, Icons.money),
                        const SizedBox(width: 8),
                        _payBtn('UPI', PaymentMode.upi, Icons.phone_android),
                        const SizedBox(width: 8),
                        _payBtn('Credit', PaymentMode.credit, Icons.credit_card),
                      ],
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton.icon(
                        onPressed: _cart.isEmpty ? null : () => _save(db),
                        icon: const Icon(Icons.save),
                        label: const Text('SAVE BILL', style: TextStyle(fontSize: 18)),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _payBtn(String label, PaymentMode mode, IconData icon) {
    final isSelected = _mode == mode;
    return Expanded(
      child: ElevatedButton(
        onPressed: () => setState(() => _mode = mode),
        style: ElevatedButton.styleFrom(
          backgroundColor: isSelected ? AppTheme.primaryColor : Colors.grey[200],
          foregroundColor: isSelected ? Colors.white : Colors.black87,
        ),
        child: Column(
          children: [
            Icon(icon),
            Text(label),
          ],
        ),
      ),
    );
  }

  double get _subtotal => _cart.fold(0.0, (sum, c) => sum + c.total);
  double get _gst => _gstOn ? _subtotal * 0.18 : 0;
  double get _discount => double.tryParse(_discountCtrl.text) ?? 0;
  double get _total => _subtotal + _gst - _discount;

  Future<void> _save(AppDatabase db) async {
    final billNumber = 'BH-${DateTime.now().millisecondsSinceEpoch}';
    
    final billCompanion = BillsCompanion(
      billNumber: Value(billNumber),
      customerName: Value(_customerCtrl.text),
      customerMobile: Value(_mobileCtrl.text.isEmpty ? null : _mobileCtrl.text),
      subtotal: Value(_subtotal),
      gstAmount: Value(_gst),
      discount: Value(_discount),
      total: Value(_total),
      paymentMode: Value(_mode.name),
      date: Value(DateTime.now()),
    );
    
    final itemsCompanions = _cart.map((c) => BillItemsCompanion(
      itemId: Value(c.item.id),
      itemName: Value(c.item.name),
      quantity: Value(c.qty.toDouble()),
      rate: Value(c.item.salePrice),
      gstPercent: Value(c.item.gstPercent),
      amount: Value(c.total),
    )).toList();
    
    try {
      await db.insertBill(billCompanion, itemsCompanions);
      
      for (var c in _cart) {
        await db.updateItem(c.item.id, ItemsCompanion(
          stock: Value(c.item.stock - c.qty),
        ));
      }
      
      _showSavedDialog(billNumber);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  void _showSavedDialog(String billNumber) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Bill Saved!'),
        content: Text('Bill #$billNumber saved successfully.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          ElevatedButton(
            onPressed: () => _print(billNumber),
            child: const Text('Print'),
          ),
          ElevatedButton(
            onPressed: () => _share(billNumber),
            child: const Text('WhatsApp'),
          ),
        ],
      ),
    );
  }

  Future<void> _print(String billNumber) async {
    final doc = pw.Document();
    
    doc.addPage(
      pw.Page(
        build: (pw.Context context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.center,
          children: [
            pw.Text('BHARAT HARDWARE', style: pw.TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            pw.Text('Electrical & Tools'),
            pw.Text('Nandura, Dist Buldhana - 443402'),
            pw.Text('Mobile: 7768082083'),
            pw.Divider(),
            pw.Text('Bill #: $billNumber'),
            pw.Text('Date: ${DateTime.now().toString().split(' ')[0]}'),
            pw.Divider(),
            pw.Table.fromTextArray(
              headers: ['Item', 'Qty', 'Rate', 'Amount'],
              data: _cart.map((c) => [
                c.item.name,
                c.qty.toString(),
                '₹${c.item.salePrice}',
                '₹${c.total.toStringAsFixed(2)}',
              ]).toList(),
            ),
            pw.Divider(),
            pw.Align(
              alignment: pw.Alignment.centerRight,
              child: pw.Text('Total: ₹${_total.toStringAsFixed(2)}', style: pw.TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ),
            pw.Spacer(),
            pw.Text('Thank you for your business!', style: pw.TextStyle(fontStyle: pw.FontStyle.italic)),
          ],
        ),
      ),
    );
    
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => doc.save(),
    );
  }

  Future<void> _share(String billNumber) async {
    final message = 'Hi! Your bill #$billNumber from Bharat Hardware is ₹${_total.toStringAsFixed(2)}. Thank you!';
    final url = 'https://wa.me/?text=${Uri.encodeComponent(message)}';
    
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    }
  }
}

class _CartItem {
  Item item;
  int qty;
  
  _CartItem({required this.item, required this.qty});
  
  double get total => item.salePrice * qty;
}

enum PaymentMode { cash, upi, credit }