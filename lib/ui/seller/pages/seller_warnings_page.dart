import 'package:flutter/material.dart';

class SellerWarningsPage extends StatelessWidget {
  const SellerWarningsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Warnings & Violations'), automaticallyImplyLeading: false),
      body: const Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.verified_user_outlined, size: 64, color: Colors.green),
          SizedBox(height: 16),
          Text('No warnings', style: TextStyle(fontSize: 16, color: Colors.black54)),
          SizedBox(height: 8),
          Text('Your account is in good standing. Keep it up!', style: TextStyle(color: Colors.black38), textAlign: TextAlign.center),
        ]),
      ),
    );
  }
}
