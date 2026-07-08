import 'package:hive/hive.dart';

part 'tracked_item.g.dart';

/// 価格履歴の1レコード
@HiveType(typeId: 1)
class PriceRecord extends HiveObject {
  @HiveField(0)
  final DateTime checkedAt;

  @HiveField(1)
  final int price;

  PriceRecord({required this.checkedAt, required this.price});
}

/// 追跡対象の種類
@HiveType(typeId: 2)
enum TrackedType {
  @HiveField(0)
  item, // 個別アイテムページ
  @HiveField(1)
  shop, // ショップページ（新着検知用）
}

/// 追跡対象（アイテム or ショップ）
@HiveType(typeId: 0)
class TrackedItem extends HiveObject {
  @HiveField(0)
  final String id; // BoothのアイテムID or ショップID

  @HiveField(1)
  final String url;

  @HiveField(2)
  TrackedType type;

  @HiveField(3)
  String title;

  @HiveField(4)
  String? shopName;

  @HiveField(5)
  String? imageUrl;

  @HiveField(6)
  int? price; // ショップの場合はnull

  @HiveField(7)
  bool isAvailable;

  @HiveField(8)
  final DateTime addedAt;

  @HiveField(9)
  DateTime? lastCheckedAt;

  @HiveField(10)
  List<PriceRecord> priceHistory;

  @HiveField(11)
  List<String> knownChildItemIds; // ショップ追跡時: 既知のアイテムID一覧（新着検知用）

  @HiveField(12)
  List<String> newItemIdsSinceLastView; // ショップ追跡時: 前回確認後に見つかった新着ID

  TrackedItem({
    required this.id,
    required this.url,
    required this.type,
    required this.title,
    this.shopName,
    this.imageUrl,
    this.price,
    this.isAvailable = true,
    DateTime? addedAt,
    this.lastCheckedAt,
    List<PriceRecord>? priceHistory,
    List<String>? knownChildItemIds,
    List<String>? newItemIdsSinceLastView,
  })  : addedAt = addedAt ?? DateTime.now(),
        priceHistory = priceHistory ?? [],
        knownChildItemIds = knownChildItemIds ?? [],
        newItemIdsSinceLastView = newItemIdsSinceLastView ?? [];

  /// 前回チェックからのクールダウン時間が経過しているか
  bool canCheckNow({Duration cooldown = const Duration(minutes: 30)}) {
    if (lastCheckedAt == null) return true;
    return DateTime.now().difference(lastCheckedAt!) >= cooldown;
  }
}
