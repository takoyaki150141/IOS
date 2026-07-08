import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/tracked_item.dart';
import '../services/tracked_items_provider.dart';
import '../services/booth_parser.dart';
import '../widgets/item_card.dart';
import '../widgets/booth_webview_tab.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0; // 0: Booth, 1: アイテム, 2: ショップ
  final _boothTabKey = GlobalKey<BoothWebViewTabState>();
  bool _canRegisterCurrentPage = false;

  static const _titles = ['Booth', 'アイテム', 'ショップ'];

  @override
  void initState() {
    super.initState();
    context.read<TrackedItemsProvider>().load();
  }

  void _onBoothUrlChanged(String url) {
    final type = BoothParser.detectType(url);
    final registerable = type != null && url != boothHomeUrl;
    if (registerable != _canRegisterCurrentPage) {
      setState(() => _canRegisterCurrentPage = registerable);
    }
  }

  /// 一覧からアイテム/ショップをタップした際、Boothタブへ切り替えてそのURLを開く
  void _openInBoothTab(String url) {
    setState(() => _currentIndex = 0);
    // タブ切り替え直後にWebView側の初期化が済んでいない場合があるため次フレームで実行
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _boothTabKey.currentState?.loadUrl(url);
    });
  }

  Future<void> _registerCurrentPage() async {
    final url = _boothTabKey.currentState?.currentUrl;
    if (url == null) return;
    final provider = context.read<TrackedItemsProvider>();
    try {
      await provider.addByUrl(url);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('登録しました')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TrackedItemsProvider>();
    final all = provider.items;
    final items = all.where((e) => e.type == TrackedType.item).toList();
    final shops = all.where((e) => e.type == TrackedType.shop).toList();
    final isBoothTab = _currentIndex == 0;

    return Scaffold(
      appBar: AppBar(
        title: Text(isBoothTab ? 'Booth' : 'BoothWatch — ${_titles[_currentIndex]}'),
        actions: [
          if (isBoothTab) ...[
            IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => _boothTabKey.currentState?.goBack()),
            IconButton(icon: const Icon(Icons.refresh), onPressed: () => _boothTabKey.currentState?.reload()),
          ] else
            IconButton(
              icon: provider.isRefreshing
                  ? const SizedBox(
                      width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.refresh),
              onPressed: provider.isRefreshing ? null : () => provider.refreshAll(),
            ),
        ],
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: [
          BoothWebViewTab(key: _boothTabKey, onUrlChanged: _onBoothUrlChanged),
          _ItemList(items: items, onTap: (item) => _openInBoothTab(item.url)),
          _ItemList(items: shops, onTap: (item) => _openInBoothTab(item.url)),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (i) => setState(() => _currentIndex = i),
        destinations: [
          const NavigationDestination(icon: Icon(Icons.public), label: 'Booth'),
          NavigationDestination(icon: const Icon(Icons.inventory_2_outlined), label: 'アイテム(${items.length})'),
          NavigationDestination(icon: const Icon(Icons.storefront_outlined), label: 'ショップ(${shops.length})'),
        ],
      ),
      floatingActionButton: isBoothTab
          ? (_canRegisterCurrentPage
              ? FloatingActionButton.extended(
                  onPressed: _registerCurrentPage,
                  icon: const Icon(Icons.add),
                  label: const Text('このページを登録'),
                )
              : null)
          : null,
    );
  }
}

class _ItemList extends StatelessWidget {
  final List<TrackedItem> items;
  final ValueChanged<TrackedItem> onTap;
  const _ItemList({required this.items, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final provider = context.read<TrackedItemsProvider>();

    if (items.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'まだ何も登録されていません。\n'
            'Boothタブでページを開いて「このページを登録」から追加してください。',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey),
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => provider.refreshAll(force: true),
      child: ListView.builder(
        itemCount: items.length,
        itemBuilder: (context, index) {
          final item = items[index];
          return ItemCard(
            item: item,
            onTap: () => onTap(item),
            onDelete: () => _confirmDelete(context, provider, item),
          );
        },
      ),
    );
  }

  void _confirmDelete(BuildContext context, TrackedItemsProvider provider, TrackedItem item) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('削除しますか？'),
        content: Text(item.title),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('キャンセル')),
          TextButton(
            onPressed: () {
              provider.remove(item);
              Navigator.pop(ctx);
            },
            child: const Text('削除', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
