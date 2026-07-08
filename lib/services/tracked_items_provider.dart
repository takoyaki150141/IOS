import 'package:flutter/foundation.dart';
import '../models/tracked_item.dart';
import 'booth_parser.dart';
import 'storage_service.dart';

class TrackedItemsProvider extends ChangeNotifier {
  final _storage = StorageService.instance;
  List<TrackedItem> _items = [];
  bool _isRefreshing = false;
  String? _lastError;

  List<TrackedItem> get items => _items;
  bool get isRefreshing => _isRefreshing;
  String? get lastError => _lastError;

  void load() {
    _items = _storage.getAll();
    notifyListeners();
  }

  /// URLを解析して新規登録する
  Future<void> addByUrl(String url) async {
    final type = BoothParser.detectType(url);
    if (type == null) {
      throw Exception('BoothのURLとして認識できませんでした');
    }

    if (type == TrackedType.item) {
      final id = BoothParser.extractItemId(url);
      if (id == null) throw Exception('アイテムIDを取得できませんでした');
      if (_storage.exists('item_$id')) throw Exception('既に登録済みです');

      final info = await BoothParser.fetchItemInfo(url);
      final item = TrackedItem(
        id: 'item_$id',
        url: url,
        type: TrackedType.item,
        title: info['title'],
        shopName: info['shopName'],
        imageUrl: info['imageUrl'],
        price: info['price'],
        isAvailable: info['isAvailable'] ?? true,
        lastCheckedAt: DateTime.now(),
      );
      if (item.price != null) {
        item.priceHistory.add(PriceRecord(checkedAt: DateTime.now(), price: item.price!));
      }
      await _storage.save(item);
    } else {
      final shopId = BoothParser.extractShopId(url);
      if (shopId == null) throw Exception('ショップIDを取得できませんでした');
      if (_storage.exists('shop_$shopId')) throw Exception('既に登録済みです');

      final itemIds = await BoothParser.fetchShopItemIds(url);
      final item = TrackedItem(
        id: 'shop_$shopId',
        url: url,
        type: TrackedType.shop,
        title: shopId,
        shopName: shopId,
        knownChildItemIds: itemIds,
        lastCheckedAt: DateTime.now(),
      );
      await _storage.save(item);
    }
    load();
  }

  Future<void> remove(TrackedItem item) async {
    await _storage.delete(item.id);
    load();
  }

  /// クールダウンを尊重しつつ、対象アイテムを再チェックする。
  /// Boothへのアクセスは登録済みURLのみ・1回のGETのみに限定する。
  Future<void> refreshOne(TrackedItem item, {bool force = false}) async {
    if (!force && !item.canCheckNow()) return;

    try {
      if (item.type == TrackedType.item) {
        final info = await BoothParser.fetchItemInfo(item.url);
        item.title = info['title'] ?? item.title;
        item.imageUrl = info['imageUrl'] ?? item.imageUrl;
        item.shopName = info['shopName'] ?? item.shopName;
        item.isAvailable = info['isAvailable'] ?? item.isAvailable;
        final newPrice = info['price'] as int?;
        if (newPrice != null && newPrice != item.price) {
          item.priceHistory.add(PriceRecord(checkedAt: DateTime.now(), price: newPrice));
          item.price = newPrice;
        }
      } else {
        final ids = await BoothParser.fetchShopItemIds(item.url);
        final newIds = ids.where((id) => !item.knownChildItemIds.contains(id)).toList();
        if (newIds.isNotEmpty) {
          item.newItemIdsSinceLastView = [...item.newItemIdsSinceLastView, ...newIds];
          item.knownChildItemIds = ids;
        }
      }
      item.lastCheckedAt = DateTime.now();
      await _storage.save(item);
    } catch (e) {
      _lastError = '${item.title}: $e';
    }
  }

  /// 登録済み全件をクールダウンを尊重して順にチェック（並列にせず負荷を抑える）
  Future<void> refreshAll({bool force = false}) async {
    _isRefreshing = true;
    _lastError = null;
    notifyListeners();

    for (final item in List<TrackedItem>.from(_items)) {
      await refreshOne(item, force: force);
      // 連続アクセスを避けるための小さな間隔
      await Future.delayed(const Duration(milliseconds: 800));
    }

    _isRefreshing = false;
    load();
  }

  Future<void> clearNewBadge(TrackedItem item) async {
    item.newItemIdsSinceLastView = [];
    await _storage.save(item);
    load();
  }
}
