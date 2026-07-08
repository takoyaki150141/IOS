import 'package:hive_flutter/hive_flutter.dart';
import '../models/tracked_item.dart';

class StorageService {
  static const _boxName = 'tracked_items';
  late Box<TrackedItem> _box;

  static final StorageService instance = StorageService._internal();
  StorageService._internal();

  Future<void> init() async {
    await Hive.initFlutter();
  
    Hive.registerAdapter(TrackedItemAdapter());
    Hive.registerAdapter(PriceRecordAdapter());
    Hive.registerAdapter(TrackedTypeAdapter());
  
    // 一度だけ実行
    await Hive.deleteBoxFromDisk(_boxName);
  
    _box = await Hive.openBox<TrackedItem>(_boxName);
  }

  List<TrackedItem> getAll() => _box.values.toList()
    ..sort((a, b) => b.addedAt.compareTo(a.addedAt));

  List<TrackedItem> getByType(TrackedType type) =>
      getAll().where((e) => e.type == type).toList();

  bool exists(String id) => _box.containsKey(id);

  Future<void> save(TrackedItem item) async {
    await _box.put(item.id, item);
  }

  Future<void> delete(String id) async {
    await _box.delete(id);
  }

  TrackedItem? get(String id) => _box.get(id);
}
