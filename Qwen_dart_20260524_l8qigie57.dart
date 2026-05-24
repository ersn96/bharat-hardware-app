import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

part 'app_database.g.dart';

class Items extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().withLength(min: 1, max: 200)();
  TextColumn get sku => text().withLength(min: 1, max: 50).nullable()();
  TextColumn get category => text().withLength(min: 1, max: 100).nullable()();
  RealColumn get purchasePrice => real()();
  RealColumn get salePrice => real()();
  RealColumn get gstPercent => real().withDefault(const Constant(18.0))();
  IntColumn get stock => integer().withDefault(const Constant(0))();
  IntColumn get lowStockThreshold => integer().withDefault(const Constant(10))();
  TextColumn get supplier => text().nullable()();
  TextColumn get unit => text().withDefault(const Constant('pcs'))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

class Bills extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get billNumber => text().withLength(min: 1, max: 50)();
  TextColumn get customerName => text().withLength(min: 1, max: 200)();
  TextColumn get customerMobile => text().nullable()();
  RealColumn get subtotal => real()();
  RealColumn get gstAmount => real().withDefault(const Constant(0.0))();
  RealColumn get discount => real().withDefault(const Constant(0.0))();
  RealColumn get total => real()();
  TextColumn get paymentMode => text()();
  DateTimeColumn get date => dateTime()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

class BillItems extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get billId => integer().references(Bills, #id)();
  IntColumn get itemId => integer()();
  TextColumn get itemName => text()();
  RealColumn get quantity => real()();
  RealColumn get rate => real()();
  RealColumn get gstPercent => real()();
  RealColumn get amount => real()();
}

@DriftDatabase(tables: [Items, Bills, BillItems])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());
  
  static QueryExecutor _openConnection() {
    return LazyDatabase(() async {
      final dbFolder = await getApplicationDocumentsDirectory();
      final file = File(p.join(dbFolder.path, 'bharat_hardware.sqlite'));
      return NativeDatabase.createInBackground(file);
    });
  }
  
  @override
  int get schemaVersion => 1;
  
  Future<List<Item>> getAllItems() => select(items).get();
  
  Future<List<Item>> getLowStockItems() {
    return (select(items)..where((t) => t.stock.isSmallerOrEqualValue(t.lowStockThreshold))).get();
  }
  
  Future<int> insertItem(ItemsCompanion item) => into(items).insert(item);
  
  Future<bool> updateItem(int id, ItemsCompanion item) {
    return (update(items)..where((t) => t.id.equals(id))).write(item);
  }
  
  Future<List<Bill>> getAllBills() {
    return select(bills).orderBy([(t) => OrderingTerm.desc(t.date)]).get();
  }
  
  Future<List<Bill>> getTodayBills() {
    final today = DateTime.now();
    final start = DateTime(today.year, today.month, today.day);
    final end = start.add(const Duration(days: 1));
    return (select(bills)..where((t) => t.date.isBetweenValues(start, end))).get();
  }
  
  Future<int> insertBill(BillsCompanion bill, List<BillItemsCompanion> items) {
    return transaction(() async {
      final billId = await into(bills).insert(bill);
      for (final item in items) {
        await into(billItems).insert(item.copyWith(billId: Value(billId)));
      }
      return billId;
    });
  }
  
  Future<Map<String, dynamic>> getTodayStats() async {
    final today = DateTime.now();
    final start = DateTime(today.year, today.month, today.day);
    final end = start.add(const Duration(days: 1));
    
    final bills = await (select(bills)..where((t) => t.date.isBetweenValues(start, end))).get();
    final allItems = await select(items).get();
    
    double sale = bills.fold(0.0, (sum, b) => sum + b.total);
    double stockVal = allItems.fold(0.0, (sum, i) => sum + (i.purchasePrice * i.stock));
    
    return {
      'todaySale': sale,
      'stockValue': stockVal,
      'billsCount': bills.length,
      'totalItems': allItems.length,
    };
  }
}