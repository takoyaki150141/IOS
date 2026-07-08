import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as html_parser;
import 'package:html/dom.dart';

import '../models/tracked_item.dart';

class BoothParseException implements Exception {
  final String message;
  BoothParseException(this.message);
  @override
  String toString() => 'BoothParseException: $message';
}

/// Boothのページを最小限のリクエストで取得・解析するサービス。
/// 公式APIが存在しないため、OGPタグ(meta property="og:*")を優先的に読む。
/// og:*はページの主要構造が変わっても比較的安定しているため、
/// 本文セレクタへの依存を減らし負荷・壊れやすさの両方を抑える狙い。
class BoothParser {
  static final _itemUrlPattern = RegExp(r'/items/(\d+)');
  static final _priceDigitPattern = RegExp(r'[\d,]+');

  static const _headers = {
    // 一般的なブラウザUAを装う（過度なブロックを避けるため）。
    'User-Agent':
        'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/125.0 Safari/537.36',
    'Accept-Language': 'ja,en;q=0.8',
  };

  /// アイテムURLかショップURLかを判定
  static TrackedType? detectType(String url) {
    final uri = Uri.tryParse(url);
    if (uri == null) return null;
    if (!uri.host.contains('booth.pm')) return null;

    if (_itemUrlPattern.hasMatch(uri.path)) {
      return TrackedType.item;
    }
    // ショップURL: https://xxxx.booth.pm/ or /items 一覧
    if (uri.host.endsWith('.booth.pm')) {
      return TrackedType.shop;
    }
    return null;
  }

  static String? extractItemId(String url) {
    final match = _itemUrlPattern.firstMatch(url);
    return match?.group(1);
  }

  static String? extractShopId(String url) {
    final uri = Uri.tryParse(url);
    if (uri == null) return null;
    // サブドメイン部分をショップIDとして使う
    final host = uri.host;
    if (host.endsWith('.booth.pm')) {
      return host.replaceAll('.booth.pm', '');
    }
    return null;
  }

  /// アイテムページを取得してTrackedItemを構築（新規登録・更新チェック両用）
  static Future<Map<String, dynamic>> fetchItemInfo(String url) async {
    final res = await http.get(Uri.parse(url), headers: _headers);
    if (res.statusCode != 200) {
      throw BoothParseException('HTTP ${res.statusCode}: 取得に失敗しました');
    }
    final doc = html_parser.parse(utf8.decode(res.bodyBytes, allowMalformed: true));

    final title = _metaContent(doc, 'og:title') ?? doc.querySelector('title')?.text.trim() ?? '不明な商品';
    final image = _metaContent(doc, 'og:image');
    final shopName = _extractShopNameFromTitle(title) ?? _metaContent(doc, 'og:site_name');

    // 価格取得: itemprop="price" のmetaタグを最優先。無ければ本文中の¥表記を拾う。
    int? price = _extractPriceFromMeta(doc);
    price ??= _extractPriceFromText(doc);

    // 販売終了・非公開の簡易判定（本文に特定文言が含まれるか）
    final bodyText = doc.body?.text ?? '';
    final isAvailable = !bodyText.contains('無効な商品') && !bodyText.contains('ページが見つかりません');

    return {
      'title': title,
      'imageUrl': image,
      'shopName': shopName,
      'price': price,
      'isAvailable': isAvailable,
    };
  }

  /// ショップの商品一覧ページを取得し、掲載中のアイテムID一覧を返す
  static Future<List<String>> fetchShopItemIds(String shopUrl) async {
    final uri = Uri.parse(shopUrl);
    final listUrl = uri.path.contains('/items') ? shopUrl : '${shopUrl.replaceAll(RegExp(r"/$"), '')}/items';

    final res = await http.get(Uri.parse(listUrl), headers: _headers);
    if (res.statusCode != 200) {
      throw BoothParseException('HTTP ${res.statusCode}: ショップページの取得に失敗しました');
    }
    final doc = html_parser.parse(utf8.decode(res.bodyBytes, allowMalformed: true));

    final ids = <String>{};
    for (final a in doc.querySelectorAll('a[href]')) {
      final href = a.attributes['href'] ?? '';
      final match = _itemUrlPattern.firstMatch(href);
      if (match != null) ids.add(match.group(1)!);
    }
    return ids.toList();
  }

  static String? _metaContent(Document doc, String property) {
    final el = doc.querySelector('meta[property="$property"]') ?? doc.querySelector('meta[name="$property"]');
    return el?.attributes['content'];
  }

  static int? _extractPriceFromMeta(Document doc) {
    final el = doc.querySelector('meta[itemprop="price"]') ?? doc.querySelector('[itemprop="price"]');
    final content = el?.attributes['content'] ?? el?.text;
    if (content == null) return null;
    final match = _priceDigitPattern.firstMatch(content.replaceAll(',', ''));
    return match != null ? int.tryParse(match.group(0)!.replaceAll(',', '')) : null;
  }

  static int? _extractPriceFromText(Document doc) {
    // 「¥1,000」のようなテキストを本文から拾うフォールバック
    final priceEl = doc.querySelectorAll('*').firstWhere(
          (e) => e.text.trim().startsWith('¥') && e.children.isEmpty,
          orElse: () => Element.tag('span'),
        );
    final text = priceEl.text.trim();
    if (!text.startsWith('¥')) return null;
    final match = _priceDigitPattern.firstMatch(text);
    if (match == null) return null;
    return int.tryParse(match.group(0)!.replaceAll(',', ''));
  }

  static String? _extractShopNameFromTitle(String title) {
    // Boothのタイトルは "商品名 - ショップ名 - BOOTH" 形式が多い
    final parts = title.split(' - ');
    if (parts.length >= 2) return parts[parts.length - 2];
    return null;
  }
}
