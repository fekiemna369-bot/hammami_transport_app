import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class WalletScreen extends StatefulWidget {
  const WalletScreen({super.key});

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {
  // ── Palette ─────────────────────────────────────────────────────────────
  static const Color bg            = Color(0xFFFAFAF8);
  static const Color darkText      = Color(0xFF1A1A1A);
  static const Color greySub       = Color(0xFF888888);
  static const Color primaryOrange = Color(0xFFE8501A);
  static const Color greenAmount   = Color(0xFF1A7A2E);
  static const Color greenBg       = Color(0xFFEAF3DE);
  static const Color redAmount     = Color(0xFFA32D2D);
  static const Color redBg         = Color(0xFFFCEBEB);

  // ── Tab ─────────────────────────────────────────────────────────────────
  int _selectedTab = 0; // 0 = Compte normal, 1 = Zone rouge

  String? get _uid => FirebaseAuth.instance.currentUser?.uid;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: Column(
          children: [
            _buildTopBar(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildBalanceCard(),
                    const SizedBox(height: 16),
                    _buildTabs(),
                    const SizedBox(height: 24),
                    _buildTransactionsHeader(),
                    const SizedBox(height: 10),
                    _buildTransactionsList(),
                    const SizedBox(height: 28),
                    _buildPayButton(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  // ── Top Bar ────────────────────────────────────────────────────────────
  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
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
              child: const Icon(Icons.arrow_back_ios_new_rounded,
                  size: 14, color: darkText),
            ),
          ),
          const Expanded(
            child: Center(
              child: Text(
                'Mon Wallet',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: darkText,
                ),
              ),
            ),
          ),
          GestureDetector(
            onTap: () {
              // navigate to historique complet
            },
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.black12, width: 0.5),
              ),
              child: const Row(
                children: [
                  Icon(Icons.history_rounded, size: 14, color: greySub),
                  SizedBox(width: 4),
                  Text(
                    'Historique',
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: greySub),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Balance Card ────────────────────────────────────────────────────────
  Widget _buildBalanceCard() {
    final uid = _uid;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [primaryOrange, Color(0xFFFF7A45)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: primaryOrange.withOpacity(0.28),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Solde disponible',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 6),

          // Live balance
          uid == null
              ? const _BalanceDisplay(value: '0.000 TND')
              : StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                  stream: FirebaseFirestore.instance
                      .collection('users')
                      .doc(uid)
                      .snapshots(),
                  builder: (context, snap) {
                    final data = snap.data?.data();
                    final balance =
                        (data?['walletBalance'] as num?)?.toDouble() ?? 0.0;
                    return _BalanceDisplay(
                      value:
                          '${balance.toStringAsFixed(3)} TND',
                    );
                  },
                ),

          const SizedBox(height: 8),

          // Card number (masked)
          uid == null
              ? const SizedBox.shrink()
              : StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                  stream: FirebaseFirestore.instance
                      .collection('users')
                      .doc(uid)
                      .snapshots(),
                  builder: (context, snap) {
                    final data = snap.data?.data();
                    final card = data?['cardNumber'] as String? ?? '****';
                    return Text(
                      'Carte N° **** **** $card',
                      style: const TextStyle(
                        color: Colors.white60,
                        fontSize: 11,
                      ),
                    );
                  },
                ),

          const SizedBox(height: 6),
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: Color(0xFF66FF88),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              const Text(
                'Compte actif',
                style: TextStyle(color: Colors.white70, fontSize: 11),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Tabs ────────────────────────────────────────────────────────────────
  Widget _buildTabs() {
    final tabs = ['Compte normal', 'Zone rouge'];
    return Container(
      height: 42,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFEEEEEE),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: List.generate(tabs.length, (i) {
          final selected = _selectedTab == i;
          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _selectedTab = i),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                decoration: BoxDecoration(
                  color: selected ? Colors.white : Colors.transparent,
                  borderRadius: BorderRadius.circular(9),
                  boxShadow: selected
                      ? [
                          const BoxShadow(
                            color: Color(0x14000000),
                            blurRadius: 6,
                            offset: Offset(0, 2),
                          )
                        ]
                      : [],
                ),
                alignment: Alignment.center,
                child: Text(
                  tabs[i],
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: selected ? darkText : greySub,
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  // ── Transactions Header ─────────────────────────────────────────────────
  Widget _buildTransactionsHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          'Transactions récentes',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: darkText,
          ),
        ),
        GestureDetector(
          onTap: () {
            // navigate to full transaction history
          },
          child: const Text(
            'Voir tout',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: primaryOrange,
            ),
          ),
        ),
      ],
    );
  }

  // ── Transactions List (Firestore) ───────────────────────────────────────
  Widget _buildTransactionsList() {
    final uid = _uid;
    if (uid == null) {
      return _emptyState('Connectez-vous pour voir vos transactions.');
    }

    // Filter by account type
    final accountType =
        _selectedTab == 0 ? 'normal' : 'zone_rouge';

    final stream = FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('transactions')
        .where('accountType', isEqualTo: accountType)
        .orderBy('date', descending: true)
        .limit(10)
        .snapshots();

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: stream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Center(
              child: CircularProgressIndicator(
                  color: primaryOrange, strokeWidth: 2),
            ),
          );
        }

        if (snapshot.hasError) {
          return _emptyState('Erreur de chargement.');
        }

        final docs = snapshot.data?.docs ?? [];
        if (docs.isEmpty) {
          return _emptyState('Aucune transaction pour ce compte.');
        }

        return Column(
          children: docs.map((doc) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _TransactionCard(data: doc.data()),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _emptyState(String msg) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.black12, width: 0.5),
      ),
      child: Center(
        child: Text(
          msg,
          textAlign: TextAlign.center,
          style: const TextStyle(color: greySub, fontSize: 12),
        ),
      ),
    );
  }

  // ── Payer Button (centered, single action) ──────────────────────────────
  Widget _buildPayButton() {
    return Center(
      child: SizedBox(
        width: 200,
        height: 52,
        child: ElevatedButton.icon(
          onPressed: () {
            // navigate to payment flow
          },
          icon: const Icon(Icons.payment_rounded, size: 18),
          label: const Text(
            'Payer',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: primaryOrange,
            foregroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
        ),
      ),
    );
  }

  // ── Bottom Nav ─────────────────────────────────────────────────────────
  Widget _buildBottomNav() {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
              color: Color(0x12000000),
              blurRadius: 16,
              offset: Offset(0, -4)),
        ],
      ),
      child: BottomNavigationBar(
        currentIndex: 2,
        onTap: (_) {},
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        selectedItemColor: primaryOrange,
        unselectedItemColor: const Color(0xFFAAAAAA),
        selectedFontSize: 11,
        unselectedFontSize: 11,
        elevation: 0,
        items: const [
          BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home_rounded),
              label: 'Accueil'),
          BottomNavigationBarItem(
              icon: Icon(Icons.map_outlined),
              activeIcon: Icon(Icons.map_rounded),
              label: 'Carte'),
          BottomNavigationBarItem(
              icon: Icon(Icons.account_balance_wallet_outlined),
              activeIcon: Icon(Icons.account_balance_wallet_rounded),
              label: 'Wallet'),
          BottomNavigationBarItem(
              icon: Icon(Icons.notifications_outlined),
              activeIcon: Icon(Icons.notifications_rounded),
              label: 'Alertes'),
          BottomNavigationBarItem(
              icon: Icon(Icons.person_outline_rounded),
              activeIcon: Icon(Icons.person_rounded),
              label: 'Profil'),
        ],
      ),
    );
  }
}

// ── Balance display widget ──────────────────────────────────────────────────
class _BalanceDisplay extends StatelessWidget {
  final String value;
  const _BalanceDisplay({required this.value});

  @override
  Widget build(BuildContext context) {
    return Text(
      value,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 28,
        fontWeight: FontWeight.w800,
        letterSpacing: 0.5,
      ),
    );
  }
}

// ── Transaction Card ────────────────────────────────────────────────────────
/// Firestore document fields expected:
///   type       : 'recharge' | 'livraison'
///   label      : String  (e.g. "Recharge wallet" | "Livraison HT-T67124680")
///   amount     : num     (positive = credit, negative = debit)
///   date       : Timestamp
///   accountType: 'normal' | 'zone_rouge'
class _TransactionCard extends StatelessWidget {
  final Map<String, dynamic> data;
  const _TransactionCard({required this.data});

  static const Color darkText    = Color(0xFF1A1A1A);
  static const Color greySub     = Color(0xFF888888);
  static const Color greenAmount = Color(0xFF1A7A2E);
  static const Color greenBg     = Color(0xFFEAF3DE);
  static const Color redAmount   = Color(0xFFA32D2D);
  static const Color redBg       = Color(0xFFFCEBEB);

  @override
  Widget build(BuildContext context) {
    final type     = data['type'] as String? ?? 'recharge';
    final label    = data['label'] as String? ?? '—';
    final amount   = (data['amount'] as num?)?.toDouble() ?? 0.0;
    final isCredit = amount >= 0;

    final createdAt = data['date'];
    String dateStr = '';
    if (createdAt is Timestamp) {
      final d = createdAt.toDate();
      dateStr =
          '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}, '
          '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
    }

    final iconBg    = isCredit ? greenBg : redBg;
    final iconColor = isCredit ? greenAmount : redAmount;
    final iconData  = type == 'recharge'
        ? Icons.account_balance_wallet_outlined
        : Icons.local_shipping_outlined;
    final amountStr =
        '(${isCredit ? '+' : ''}${amount.toStringAsFixed(3)})';
    final amountColor = isCredit ? greenAmount : redAmount;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border(
          left: BorderSide(color: isCredit ? greenAmount : redAmount, width: 3),
        ),
      ),
      child: Row(
        children: [
          // Icon
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(iconData, color: iconColor, size: 18),
          ),
          const SizedBox(width: 12),

          // Label + date
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: darkText,
                  ),
                ),
                if (dateStr.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(dateStr,
                      style: const TextStyle(
                          fontSize: 11, color: greySub)),
                ],
              ],
            ),
          ),

          // Amount
          Text(
            amountStr,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: amountColor,
            ),
          ),
        ],
      ),
    );
  }
}