import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:daily_fitness/services/firestore_service.dart';
import 'package:flutter/material.dart';

class AdminTestimonialsPage extends StatelessWidget {
  const AdminTestimonialsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Testimonials'), automaticallyImplyLeading: false, actions: [
        IconButton(icon: const Icon(Icons.add), onPressed: () => _addTestimonial(context)),
      ]),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirestoreService.testimonials().snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
          final docs = snapshot.data?.docs ?? [];
          if (docs.isEmpty) {
            return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
              const Icon(Icons.rate_review_outlined, size: 64, color: Colors.black26),
              const SizedBox(height: 16),
              const Text('No testimonials yet', style: TextStyle(fontSize: 16, color: Colors.black54)),
              const SizedBox(height: 12),
              ElevatedButton.icon(onPressed: () => _addTestimonial(context), icon: const Icon(Icons.add), label: const Text('Add Testimonial')),
            ]));
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final data = docs[index].data() as Map<String, dynamic>;
              final docId = docs[index].id;
              return _TestimonialCard(data: data, docId: docId);
            },
          );
        },
      ),
    );
  }

  void _addTestimonial(BuildContext context) {
    final nameCtrl = TextEditingController();
    final messageCtrl = TextEditingController();
    final roleCtrl = TextEditingController(text: 'Buyer');
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Add Testimonial'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Customer Name')),
          const SizedBox(height: 12),
          TextField(controller: roleCtrl, decoration: const InputDecoration(labelText: 'Role (Buyer/Seller/Rider)')),
          const SizedBox(height: 12),
          TextField(controller: messageCtrl, maxLines: 3, decoration: const InputDecoration(labelText: 'Testimonial Message')),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(onPressed: () async {
            if (nameCtrl.text.trim().isEmpty || messageCtrl.text.trim().isEmpty) return;
            await FirestoreService.testimonials().add({
              'name': nameCtrl.text.trim(),
              'role': roleCtrl.text.trim(),
              'message': messageCtrl.text.trim(),
              'featured': true,
              'createdAt': Timestamp.now(),
            });
            if (ctx.mounted) Navigator.pop(ctx);
          }, child: const Text('Add')),
        ],
      ),
    );
  }
}

class _TestimonialCard extends StatelessWidget {
  final Map<String, dynamic> data;
  final String docId;
  const _TestimonialCard({required this.data, required this.docId});

  @override
  Widget build(BuildContext context) {
    final name = data['name'] ?? 'Anonymous';
    final role = data['role'] ?? '';
    final message = data['message'] ?? '';
    final featured = data['featured'] ?? false;

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            CircleAvatar(radius: 20, backgroundColor: const Color(0xFFE8F1FF), child: Text(name.isNotEmpty ? name[0].toUpperCase() : '?', style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0F2850)))),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(name, style: const TextStyle(fontWeight: FontWeight.w600)),
              Text(role, style: const TextStyle(color: Colors.black54, fontSize: 12)),
            ])),
            if (featured) const Icon(Icons.star, color: Colors.amber, size: 20),
            PopupMenuButton<String>(
              onSelected: (action) => _handleAction(context, action),
              itemBuilder: (_) => [
                PopupMenuItem(value: 'feature', child: Text(featured ? 'Unfeature' : 'Feature')),
                const PopupMenuItem(value: 'delete', child: Text('Delete', style: TextStyle(color: Colors.red))),
              ],
            ),
          ]),
          const SizedBox(height: 12),
          Text('"$message"', style: const TextStyle(fontStyle: FontStyle.italic, color: Colors.black87, height: 1.5)),
        ]),
      ),
    );
  }

  void _handleAction(BuildContext context, String action) async {
    if (action == 'feature') {
      final current = data['featured'] ?? false;
      await FirestoreService.testimonials().doc(docId).update({'featured': !current});
    } else if (action == 'delete') {
      await FirestoreService.testimonials().doc(docId).delete();
    }
  }
}
