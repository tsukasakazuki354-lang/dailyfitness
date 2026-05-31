import 'package:flutter/material.dart';

class RiderComplaintsPage extends StatelessWidget {
  const RiderComplaintsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Complaints & Feedback'), automaticallyImplyLeading: false),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showComplaintDialog(context),
        icon: const Icon(Icons.add),
        label: const Text('New Complaint'),
      ),
      body: const Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.feedback_outlined, size: 64, color: Colors.black26),
          SizedBox(height: 16),
          Text('No complaints filed', style: TextStyle(fontSize: 16, color: Colors.black54)),
          SizedBox(height: 8),
          Text('Tap + to submit a new complaint or feedback.', style: TextStyle(color: Colors.black38)),
        ]),
      ),
    );
  }

  void _showComplaintDialog(BuildContext context) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Submit Complaint'),
        content: TextField(controller: controller, maxLines: 4, decoration: const InputDecoration(hintText: 'Describe your issue...', border: OutlineInputBorder())),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Complaint submitted. We will review it shortly.')));
            },
            child: const Text('Submit'),
          ),
        ],
      ),
    );
  }
}
