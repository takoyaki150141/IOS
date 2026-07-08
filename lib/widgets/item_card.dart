import 'package:flutter/material.dart';
import '../models/tracked_item.dart';

class ItemCard extends StatelessWidget {
  final TrackedItem item;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const ItemCard({
    super.key,
    required this.item,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final hasNew = item.newItemIdsSinceLastView.isNotEmpty;
    final priceChanged = item.priceHistory.length >= 2 &&
        item.priceHistory.last.price != item.priceHistory[item.priceHistory.length - 2].price;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: item.imageUrl != null
                    ? Image.network(item.imageUrl!, width: 72, height: 72, fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _placeholder())
                    : _placeholder(),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item.title, maxLines: 2, overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                    if (item.shopName != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(item.shopName!, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                      ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        if (item.type == TrackedType.item && item.price != null)
                          Text('¥${_formatPrice(item.price!)}',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: priceChanged ? Colors.redAccent : null,
                              )),
                        if (!item.isAvailable)
                          const Padding(
                            padding: EdgeInsets.only(left: 8),
                            child: Text('販売終了', style: TextStyle(color: Colors.grey, fontSize: 12)),
                          ),
                        if (hasNew)
                          Padding(
                            padding: const EdgeInsets.only(left: 8),
                            child: Chip(
                              label: Text('新着 ${item.newItemIdsSinceLastView.length}'),
                              backgroundColor: Colors.orange.shade100,
                              labelStyle: const TextStyle(fontSize: 11),
                              padding: EdgeInsets.zero,
                              visualDensity: VisualDensity.compact,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    icon: const Icon(Icons.delete_outline, size: 20),
                    onPressed: onDelete,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _placeholder() => Container(
        width: 72,
        height: 72,
        color: Colors.grey[200],
        child: const Icon(Icons.image_not_supported_outlined, color: Colors.grey),
      );

  String _formatPrice(int price) {
    return price.toString().replaceAllMapped(
        RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (m) => '${m[1]},');
  }
}
