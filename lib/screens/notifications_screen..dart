import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

//Modele notifications
enum NotifType { redZone, enRoute, DejaLivre }

NotifType _typeFromString(String s) {
  switch (s) {
    case 'red_zone':
      return NotifType.redZone;
    case 'en_route':
      return NotifType.enRoute;
    case 'deja_livre':
    default:
      return NotifType.DejaLivre;
  }
}

class AppNotification {
  final String id;
  final String title;
  final String body;
  final String time;
  final NotifType type;
  final bool unread;

  AppNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.time,
    required this.type,
    required this.unread,
  });

  factory AppNotification.fromFirestore(String id, Map<String, dynamic> data) {
    final typeStr = data['type'] ?? '';
    final type = typeStr == 'red_zone'
        ? NotifType.redZone
        : typeStr == 'en_route'
        ? NotifType.enRoute
        : NotifType.DejaLivre;
    return AppNotification(
      id: id,
      title: data['title'] ?? '',
      body: data['body'] ?? '',
      time: data['time'] ?? '',
      type: type,
      unread: data['unread'] ?? false,
    );
  }
}

//Screen
class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  static const Color bg = Color(0xFFFAFAF8);
  static const Color darkText = Color(0xFF1A1A1A);
  static const Color greySub = Color(0xFF888888);
  static const Color primaryOrange = Color(0xFFE8501A);
  NotifType? _filter;

  String? get _uid => FirebaseAuth.instance.currentUser?.uid;

  Stream<QuerySnapshot<Map<String, dynamic>>> get _stream {
    final uid = _uid;
    if (uid == null) {
      return const Stream.empty();
    }
    return FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('notifications')
        .orderBy('timestamp', descending: true)
        .snapshots();
  }


  @override
  void initState() {
    super.initState();
    _initFCM();
  }

  Future<void> _initFCM() async {
    final uid = _uid;
    if (uid == null) return;
    final messaging = FirebaseMessaging.instance;

    // 1 — Request permission (iOS + Android 13+)
    final settings = await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    if (settings.authorizationStatus == AuthorizationStatus.denied) return;

    // 2 — Save token to Firestore
    final token = await messaging.getToken();
    if (token != null) {
      await FirebaseFirestore.instance.collection('users').doc(uid).set({
        'fcmToken': token,
      }, SetOptions(merge: true));
    }

    // Refresh token when it rotates
    messaging.onTokenRefresh.listen((newToken) {
      if (_uid == null) return;
      FirebaseFirestore.instance.collection('users').doc(_uid).set({
        'fcmToken': newToken,
      }, SetOptions(merge: true));
    });

    // 3 — Foreground message → show SnackBar
    // (Firestore doc is already written by Cloud Function, stream auto-updates)
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      final notif = message.notification;
      if (notif == null || !mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: darkText,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          content: Row(
            children: [
              const Icon(
                Icons.notifications_rounded,
                color: primaryOrange,
                size: 18,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      notif.title ?? '',
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        fontSize: 13,
                      ),
                    ),
                    Text(
                      notif.body ?? '',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    });
  }

  Future<void> _markRead(String id) async {
    final uid = _uid;
    if (uid == null) return;
    await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('notifications')
        .doc(id)
        .update({'unread': false});
  }

  Future<void> _markAllRead() async {
    final uid = _uid;
    if (uid == null) return;
    final batch = FirebaseFirestore.instance.batch();
    final snap = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('notifications')
        .where('unread', isEqualTo: true)
        .get();
    for (final doc in snap.docs) {
      batch.update(doc.reference, {'unread': false});
    }
    await batch.commit();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: Column(
          children: [
            _buildTopBar(),
            _buildFilterRow(),
            Expanded(
              child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: _stream,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(
                        color: primaryOrange,
                        strokeWidth: 2,
                      ),
                    );
                  }
                  if (snapshot.hasError) {
                    return Center(
                      child: Text(
                        'Erreur : ${snapshot.error}',
                        style: const TextStyle(color: greySub),
                      ),
                    );
                  }

                  var notifs = (snapshot.data?.docs ?? [])
                      .map((d) => AppNotification.fromFirestore(d.id, d.data()))
                      .toList();

                  if (_filter != null) {
                    notifs = notifs.where((n) => n.type == _filter).toList();
                  }

                  if (notifs.isEmpty) return _buildEmpty();

                  return ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                    itemCount: notifs.length,
                    itemBuilder: (_, i) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _buildNotifCard(notifs[i]),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Top Bar ────────────────────────────────────────────────────────────
  Widget _buildTopBar() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFF0F0F0),
                border: Border.all(color: Colors.black12, width: 0.5),
              ),
              child: const Icon(
                Icons.arrow_back_ios_new_rounded,
                size: 14,
                color: darkText,
              ),
            ),
          ),
          const Expanded(
            child: Center(
              child: Text(
                'Notifications',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: darkText,
                ),
              ),
            ),
          ),
          TextButton(
            onPressed: _markAllRead,
            style: TextButton.styleFrom(
              padding: EdgeInsets.zero,
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: const Text(
              'Tout marquer lu',
              style: TextStyle(
                color: primaryOrange,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Filter Row ─────────────────────────────────────────────────────────
  Widget _buildFilterRow() {
    final filters = <String, NotifType?>{
      'Tout': null,
      'Zone rouge': NotifType.redZone,
      'En route': NotifType.enRoute,
      'Déjà livré': NotifType.DejaLivre,
    };

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: filters.entries.map((entry) {
            final selected = _filter == entry.value;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: GestureDetector(
                onTap: () => setState(() => _filter = entry.value),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: selected ? primaryOrange : const Color(0xFFF0F0F0),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    entry.key,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: selected ? Colors.white : greySub,
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  // ── Notif Card ─────────────────────────────────────────────────────────
  Widget _buildNotifCard(AppNotification n) {
    final accent = _accent(n.type);
    final iconBg = accent.withOpacity(0.10);
    final icon = _icon(n.type);

    return GestureDetector(
      onTap: () => _markRead(n.id),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: n.unread ? accent : Colors.black12,
            width: n.unread ? 1.2 : 0.5,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: accent, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    n.title,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: n.unread ? FontWeight.w700 : FontWeight.w600,
                      color: darkText,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    n.body,
                    style: const TextStyle(
                      fontSize: 12,
                      color: greySub,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    n.time,
                    style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFFAAAAAA),
                    ),
                  ),
                ],
              ),
            ),
            if (n.unread)
              Padding(
                padding: const EdgeInsets.only(top: 4, left: 8),
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: accent,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ── Empty State ─────────────────────────────────────────────────────────
  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: const Color(0xFFFFF0E8),
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFFF5C4B3), width: 0.5),
            ),
            child: const Icon(
              Icons.notifications_off_outlined,
              size: 26,
              color: primaryOrange,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Aucune notification',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: darkText,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Vous serez notifié ici des mises à jour.',
            style: TextStyle(fontSize: 12, color: greySub),
          ),
        ],
      ),
    );
  }

  // ── Helpers ────────────────────────────────────────────────────────────
  Color _accent(NotifType t) {
    switch (t) {
      case NotifType.redZone:
        return const Color(0xFFE24B4A);
      case NotifType.enRoute:
        return primaryOrange;
      case NotifType.DejaLivre:
        return const Color(0xFF3B6D11);
    }
  }

  IconData _icon(NotifType t) {
    switch (t) {
      case NotifType.redZone:
        return Icons.block_rounded;
      case NotifType.enRoute:
        return Icons.local_shipping_outlined;
      case NotifType.DejaLivre:
        return Icons.check_circle_outline_rounded;
    }
  }
}
