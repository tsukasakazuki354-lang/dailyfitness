import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:daily_fitness/providers/session_provider.dart';
import 'package:daily_fitness/services/firestore_service.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class SellerReviewsPage extends StatelessWidget {
  const SellerReviewsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = Provider.of<SessionProvider>(context).currentUser?.uid;
    return Scaffold(
      appBar: AppBar(title: const Text('Product Reviews'), automaticallyImplyLeading: false),
      body: _buildReviewsList(context, uid ?? ''),
    );
  }

  Widget _buildReviewsList(BuildContext context, String sellerId) {
    // First get seller's products, then get reviews for those products
    return StreamBuilder<QuerySnapshot>(
      stream: FirestoreService.products().where('sellerId', isEqualTo: sellerId).snapshots(),
      builder: (context, productSnapshot) {
        if (productSnapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
        final productIds = (productSnapshot.data?.docs ?? []).map((d) => (d.data() as Map<String, dynamic>)['productId'] as String).toList();
        if (productIds.isEmpty) {
          return const Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(Icons.reviews_outlined, size: 64, color: Colors.black26),
            SizedBox(height: 16),
            Text('No reviews yet', style: TextStyle(fontSize: 16, color: Colors.black54)),
            SizedBox(height: 8),
            Text('Reviews will appear once customers review your products.', style: TextStyle(color: Colors.black38), textAlign: TextAlign.center),
          ]));
        }
        return StreamBuilder<QuerySnapshot>(
          stream: FirestoreService.reviews().snapshots(),
          builder: (context, reviewSnapshot) {
            if (reviewSnapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
            final allReviews = (reviewSnapshot.data?.docs ?? []).where((doc) {
              final data = doc.data() as Map<String, dynamic>;
              return productIds.contains(data['productId']);
            }).toList();
            if (allReviews.isEmpty) {
              return const Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.reviews_outlined, size: 64, color: Colors.black26),
                SizedBox(height: 16),
                Text('No reviews yet', style: TextStyle(fontSize: 16, color: Colors.black54)),
              ]));
            }
            return ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: allReviews.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final data = allReviews[index].data() as Map<String, dynamic>;
                return _SellerReviewCard(data: data);
              },
            );
          },
        );
      },
    );
  }
}

class _SellerReviewCard extends StatelessWidget {
  final Map<String, dynamic> data;
  const _SellerReviewCard({required this.data});

  String _formatDate(dynamic timestamp) {
    if (timestamp == null) return '';
    final date = (timestamp as Timestamp).toDate();
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    final hour = date.hour > 12 ? date.hour - 12 : (date.hour == 0 ? 12 : date.hour);
    final amPm = date.hour >= 12 ? 'PM' : 'AM';
    return '${months[date.month - 1]} ${date.day}, ${date.year} at $hour:${date.minute.toString().padLeft(2, '0')} $amPm';
  }

  @override
  Widget build(BuildContext context) {
    final rating = data['rating'] ?? 5;
    final comment = data['comment'] ?? '';
    final userName = data['userName'] ?? 'Anonymous';
    final sellerReply = data['sellerReply'] ?? '';
    final reviewId = data['reviewId'] ?? '';
    final dateStr = _formatDate(data['createdAt']);

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            CircleAvatar(radius: 18, backgroundColor: const Color(0xFFE8F1FF), child: Text(userName.isNotEmpty ? userName[0].toUpperCase() : '?', style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0F2850)))),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(userName, style: const TextStyle(fontWeight: FontWeight.w600)),
              if (dateStr.isNotEmpty) Text(dateStr, style: const TextStyle(color: Colors.black45, fontSize: 11)),
              Row(children: List.generate(5, (i) => Icon(i < (rating as int) ? Icons.star : Icons.star_border, size: 16, color: Colors.amber))),
            ])),
          ]),
          const SizedBox(height: 12),
          Text(comment, style: const TextStyle(color: Colors.black87, height: 1.4)),
          if (sellerReply.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: const Color(0xFFF0F5FF), borderRadius: BorderRadius.circular(10)),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('Your Reply', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12, color: Color(0xFF0F2850))),
                const SizedBox(height: 4),
                Text(sellerReply, style: const TextStyle(fontSize: 13, color: Colors.black54)),
              ]),
            ),
          ],
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: () => _showReplyDialog(context, reviewId, sellerReply),
              icon: Icon(sellerReply.isEmpty ? Icons.reply : Icons.edit, size: 16),
              label: Text(sellerReply.isEmpty ? 'Reply' : 'Edit Reply', style: const TextStyle(fontSize: 12)),
            ),
          ),
        ]),
      ),
    );
  }

  void _showReplyDialog(BuildContext context, String reviewId, String existingReply) {
    final controller = TextEditingController(text: existingReply);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(existingReply.isEmpty ? 'Reply to Review' : 'Edit Reply'),
        content: TextField(controller: controller, maxLines: 3, decoration: const InputDecoration(hintText: 'Write your reply...', border: OutlineInputBorder())),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              if (controller.text.trim().isEmpty) return;
              await FirestoreService.reviews().doc(reviewId).update({'sellerReply': controller.text.trim()});
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text('Save Reply'),
          ),
        ],
      ),
    );
  }
}
