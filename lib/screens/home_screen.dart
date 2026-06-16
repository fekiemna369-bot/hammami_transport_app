import 'package:flutter/material.dart';
import '../services/firestore_service.dart';
import '../models/colis.dart';
import 'tracking_screen.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final TextEditingController _searchControlller = TextEditingController();
  final FirestoreService _firestoreService = FirestoreService();


  String state = 'idle';
  String errorMessage = '';

  @override
  void dispose() {
    _searchControlller.dispose();
    super.dispose();
  }

  Future<void> _search() async {
    final num = _searchControlller.text.trim();
    if (num.isEmpty) return;

    setState(() {
      state = 'loading';
      errorMessage = '';
    });
    try {
      final colis = await _firestoreService.getColisByNum(num);
      if (colis == null) {
        setState(() {
          state = 'error';
          errorMessage = '"$num" n\'existe pas dans notre système.';
        });
      } else {
        setState(() {
          state = 'idle';
        });
        if (mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => TrackingScreen(colis: colis),
            ),
          );
        }
      }
    } catch (e) {
      setState(() {
        state = 'error';
        errorMessage = 'Une erreur est survenue lors de la recherche.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2EDE8),
      body: Column(
        children: [
          _buildToBar(),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _buildSearchBar(),
                  const SizedBox(height: 12),
                  if (state == 'loading') _buildLoading(),
                  if (state == 'error') _buildError(),
                  if (state == 'idle') _buildHeroImage(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToBar() {
    return Container(
      color: const Color(0xFFE8501A),
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 12,
        left: 20,
        right: 20,
        bottom: 14,
      ),
      child: Row(
        children: [
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Hammami Transport',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                'Suivi de colis',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const Spacer(),
          const CircleAvatar(
            radius: 17,
            backgroundColor: Colors.white24,
            child: Icon(Icons.person_outline, color: Colors.white, size: 18),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black12, width: 0.5),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Numéro de suivi',
            style: TextStyle(
              fontSize: 12,
              color: Color(0xFF888888),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchControlller,
                  onSubmitted: (_) => _search(),
                  style: const TextStyle(fontSize: 14),
                  decoration: InputDecoration(
                    hintText: "ex: HT-T6712",
                    hintStyle: const TextStyle(color: Color(0xFFAAAAAA)),
                    filled: true,
                    fillColor: const Color(0xFFF5F5F5),
                    contentPadding: const EdgeInsets.symmetric(
                      vertical: 12,
                      horizontal: 14,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                height: 46,
                child: ElevatedButton.icon(
                  onPressed: _search,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFE8501A),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                  ),
                  icon: const Icon(Icons.search, size: 18),
                  label: const Text(
                    'Chercher',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── État : chargement
  Widget _buildLoading() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black12, width: 0.5),
      ),
      padding: const EdgeInsets.all(32),
      child: const Column(
        children: [
          CircularProgressIndicator(color: Color(0xFFE8501A), strokeWidth: 3),
          SizedBox(height: 16),
          Text(
            'Recherche en cours ...',
            style: TextStyle(color: Color(0xFF888888), fontSize: 14),
          ),
        ],
      ),
    );
  }

  // ── État : erreur
  Widget _buildError() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFFFF0F0),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFFCCCC), width: 0.5),
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.error_outline, color: Colors.red, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Colis introuvable,',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFFA32D2D),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  errorMessage,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFFA32D2D),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Image héro du camion (état idle)
  Widget _buildHeroImage() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Image.asset(
        'Images/truck_hero.jpg',
        width: double.infinity,
        height: 380,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Container(
          width: double.infinity,
          height: 380,
          decoration: BoxDecoration(
            color: const Color(0xFFEFE9E2),
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Center(
            child: Icon(
              Icons.local_shipping_outlined,
              size: 64,
              color: Color(0xFFCCCCCC),
            ),
          ),
        ),
      ),
    );
  }
}