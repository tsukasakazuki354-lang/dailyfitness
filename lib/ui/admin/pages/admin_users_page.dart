import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:daily_fitness/services/firestore_service.dart';
import 'package:flutter/material.dart';

class AdminUsersPage extends StatefulWidget {
  const AdminUsersPage({super.key});

  @override
  State<AdminUsersPage> createState() => _AdminUsersPageState();
}

class _AdminUsersPageState extends State<AdminUsersPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _search = '';
  final _tabs = const ['All', 'Pending', 'Approved', 'Declined', 'Suspended'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Users'),
        automaticallyImplyLeading: false,
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
          tabs: _tabs.map((t) => Tab(text: t)).toList(),
        ),
      ),
      body: Column(children: [
        // Search bar
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: TextField(
            onChanged: (v) => setState(() => _search = v.toLowerCase()),
            decoration: InputDecoration(
              hintText: 'Search by name, email, or role...',
              prefixIcon: const Icon(Icons.search),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
              suffixIcon: _search.isNotEmpty ? IconButton(icon: const Icon(Icons.clear), onPressed: () => setState(() => _search = '')) : null,
            ),
          ),
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: _tabs.map((tab) => _UserList(statusFilter: tab == 'All' ? '' : tab.toLowerCase(), search: _search)).toList(),
          ),
        ),
      ]),
    );
  }
}

class _UserList extends StatelessWidget {
  final String statusFilter;
  final String search;
  const _UserList({required this.statusFilter, required this.search});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirestoreService.users().snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
        var users = (snapshot.data?.docs ?? []).map((d) => {'id': d.id, ...d.data() as Map<String, dynamic>}).toList();

        // Filter by status
        if (statusFilter.isNotEmpty) {
          users = users.where((u) => (u['status'] ?? 'active') == statusFilter).toList();
        }

        // Filter by search
        if (search.isNotEmpty) {
          users = users.where((u) {
            final name = '${u['firstName'] ?? ''} ${u['lastName'] ?? ''}'.toLowerCase();
            final email = (u['email'] ?? '').toString().toLowerCase();
            final role = (u['role'] ?? '').toString().toLowerCase();
            return name.contains(search) || email.contains(search) || role.contains(search);
          }).toList();
        }

        if (users.isEmpty) {
          return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.people_outline, size: 56, color: Colors.black26),
            const SizedBox(height: 12),
            Text(statusFilter.isEmpty ? 'No users found' : 'No $statusFilter users', style: const TextStyle(color: Colors.black54)),
          ]));
        }

        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: users.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (context, index) => _UserCard(user: users[index]),
        );
      },
    );
  }
}

class _UserCard extends StatelessWidget {
  final Map<String, dynamic> user;
  const _UserCard({required this.user});

  @override
  Widget build(BuildContext context) {
    final name = '${user['firstName'] ?? ''} ${user['lastName'] ?? ''}'.trim();
    final role = user['role'] ?? 'buyer';
    final email = user['email'] ?? '';
    final status = user['status'] ?? 'active';
    final uid = user['uid'] ?? user['id'] ?? '';

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            CircleAvatar(
              radius: 22,
              backgroundColor: _roleColor(role).withOpacity(0.1),
              child: Icon(_roleIcon(role), color: _roleColor(role), size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(name.isNotEmpty ? name : 'No Name', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
              Text(email, style: const TextStyle(color: Colors.black54, fontSize: 12)),
            ])),
            _StatusBadge(status: status),
          ]),
          const SizedBox(height: 12),
          Row(children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(color: _roleColor(role).withOpacity(0.08), borderRadius: BorderRadius.circular(8)),
              child: Text(role.toUpperCase(), style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: _roleColor(role))),
            ),
            const Spacer(),
            // Action buttons based on status
            if (status == 'pending') ...[
              _ActionButton(label: 'Approve', color: Colors.green, icon: Icons.check, onTap: () => _updateStatus(context, uid, 'active')),
              const SizedBox(width: 8),
              _ActionButton(label: 'Decline', color: Colors.red, icon: Icons.close, onTap: () => _updateStatus(context, uid, 'declined')),
            ] else if (status == 'active' || status == 'approved') ...[
              _ActionButton(label: 'Suspend', color: Colors.orange, icon: Icons.block, onTap: () => _updateStatus(context, uid, 'suspended')),
            ] else if (status == 'suspended' || status == 'declined') ...[
              _ActionButton(label: 'Approve', color: Colors.green, icon: Icons.check, onTap: () => _updateStatus(context, uid, 'active')),
            ],
          ]),
        ]),
      ),
    );
  }

  Color _roleColor(String role) {
    switch (role) { case 'seller': return Colors.orange; case 'rider': return Colors.blue; case 'admin': return Colors.purple; default: return Colors.green; }
  }

  IconData _roleIcon(String role) {
    switch (role) { case 'seller': return Icons.store; case 'rider': return Icons.delivery_dining; case 'admin': return Icons.admin_panel_settings; default: return Icons.person; }
  }

  void _updateStatus(BuildContext context, String uid, String newStatus) async {
    try {
      await FirestoreService.users().doc(uid).update({'status': newStatus, 'updatedAt': Timestamp.now()});
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('User status updated to $newStatus')));
    } catch (e) {
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }
}

class _StatusBadge extends StatelessWidget {
  final String status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    Color color;
    switch (status) {
      case 'active': case 'approved': color = Colors.green; break;
      case 'pending': color = Colors.orange; break;
      case 'declined': color = Colors.red; break;
      case 'suspended': color = Colors.grey; break;
      default: color = Colors.grey;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
      child: Text(status.toUpperCase(), style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: color)),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final Color color;
  final IconData icon;
  final VoidCallback onTap;
  const _ActionButton({required this.label, required this.color, required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: color)),
        ]),
      ),
    );
  }
}
