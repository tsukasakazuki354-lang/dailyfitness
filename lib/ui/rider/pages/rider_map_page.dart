import 'package:flutter/material.dart';

class RiderMapPage extends StatelessWidget {
  const RiderMapPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Delivery Map'), automaticallyImplyLeading: false),
      body: Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            width: 120, height: 120,
            decoration: BoxDecoration(color: const Color(0xFFE8F1FF), shape: BoxShape.circle),
            child: const Icon(Icons.map, size: 56, color: Color(0xFF0F2850)),
          ),
          const SizedBox(height: 24),
          const Text('Delivery Map', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              'Live map tracking will be available in a future update. You will be able to see delivery routes and customer locations here.',
              style: TextStyle(color: Colors.black54, fontSize: 14),
              textAlign: TextAlign.center,
            ),
          ),
        ]),
      ),
    );
  }
}
