import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/colis.dart';
import '../services/location_service.dart';   

class TrackingScreen extends StatefulWidget {
  final Colis colis;
  const TrackingScreen({super.key, required this.colis});

  @override
  State<TrackingScreen> createState() => _TrackingScreenState();
}

class _TrackingScreenState extends State<TrackingScreen> {
  // ── Palette ────────────────────────────────────────────────────────────
  static const Color orange    = Color(0xFFE8501A);
  static const Color darkText  = Color(0xFF1A1A1A);
  static const Color greySub   = Color(0xFF888888);
  static const Color greenDark = Color(0xFF27500A);
  static const Color greenMid  = Color(0xFF3B6D11);
  static const Color greenBg   = Color(0xFFEAF3DE);
  static const Color greenBord = Color(0xFFC0DD97);
  static const Color redBg     = Color(0xFFFCEBEB);
  static const Color redText   = Color(0xFFA32D2D);

  // ── Scroll / map key ───────────────────────────────────────────────────
  final ScrollController _scrollController = ScrollController();
  final GlobalKey         _mapKey          = GlobalKey();
  final MapController     _mapController   = MapController();

  // ── Pickup state ───────────────────────────────────────────────────────
  bool _pickupRequested    = false;
  bool _isRequestingPickup = false;

  // ── GPS state ──────────────────────────────────────────────────────────
  final GpsService _gps = GpsService();

  bool            _mapVisible   = false;
  bool            _gpsLoading   = false;
  String?         _gpsError;
  RealTimeRecord? _liveRecord;       // latest position from API
  Timer?          _refreshTimer;    // polls every 15 s when map is open

  String get _statut         => widget.colis.statut;
  bool   get _isAtAgence     => _statut == 'arrive_agence' || _statut == 'retrait_demande';
  bool   get _pickupAlreadyDone => _statut == 'retrait_demande';

  @override
  void initState() {
    super.initState();
    _pickupRequested = _pickupAlreadyDone;
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  // ── GPS: authenticate → fetch ──────────────────────────────────────────
  // Credentials come from your secure config / environment.
  // Replace the values below with your real GPS account credentials.
  static const String _gpsUsername = 'hammami';         // ← replace
  static const String _gpsPassword = 'hammami*gps24';  // ← replace

  Future<void> _loadLivePosition() async {
    final idDevice = widget.colis.idDevice;
    if (idDevice == null) {
      setState(() {
        _gpsError = 'Aucun traceur GPS associé à ce colis.';
      });
      return;
    }

    setState(() { _gpsLoading = true; _gpsError = null; });

    try {
      // 1 — Login (only if not already authenticated)
      await _gps.login(username: _gpsUsername, password: _gpsPassword);

      // 2 — Fetch real-time records and find the truck for this colis
      //     widget.colis.idDevice is the device ID linked to the shipment.
      //     Add an `idDevice` field to your Colis model if not already there.
      final record = await _gps.fetchRealTimeForDevice(idDevice);

      if (!mounted) return;
      if (record == null) {
        setState(() => _gpsError = 'Véhicule introuvable dans le flux temps réel.');
      } else {
        setState(() => _liveRecord = record);
        _mapController.move(LatLng(record.lat, record.lng), 13);
      }
    } catch (e) {
      if (mounted) setState(() => _gpsError = e.toString());
    } finally {
      if (mounted) setState(() => _gpsLoading = false);
    }
  }

  // ── Start/stop auto-refresh every 15 s ────────────────────────────────
  void _startRefresh() {
    _refreshTimer?.cancel();
    _refreshTimer = Timer.periodic(const Duration(seconds: 15), (_) {
      if (_mapVisible && mounted) _loadLivePosition();
    });
  }

  void _stopRefresh() {
    _refreshTimer?.cancel();
    _refreshTimer = null;
  }

  // ── Track button handler ───────────────────────────────────────────────
  Future<void> _onTrackPressed() async {
    if (!_mapVisible) {
      // Open map
      setState(() => _mapVisible = true);
      await _loadLivePosition();
      _startRefresh();

      // Scroll to map after build
      await Future.delayed(const Duration(milliseconds: 80));
      final ctx = _mapKey.currentContext;
      if (ctx != null && mounted) {
        await Scrollable.ensureVisible(
          ctx,
          duration: const Duration(milliseconds: 450),
          curve: Curves.easeInOut,
          alignment: 0.1,
        );
      }
    } else {
      // Refresh position
      await _loadLivePosition();
    }
  }

  // ── Pickup request ─────────────────────────────────────────────────────
  Future<void> _requestPickup() async {
    final confirm = await _showConfirmDialog();
    if (!confirm) return;
    setState(() => _isRequestingPickup = true);
    try {
      await FirebaseFirestore.instance
          .collection('colis')
          .where('numero', isEqualTo: widget.colis.numero)
          .limit(1)
          .get()
          .then((snap) {
        if (snap.docs.isNotEmpty) {
          return snap.docs.first.reference.update({
            'statut': 'retrait_demande',
            'pickupRequestedAt': FieldValue.serverTimestamp(),
            'pickupRequestedBy': FirebaseAuth.instance.currentUser?.uid,
          });
        }
      });
      if (mounted) setState(() => _pickupRequested = true);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Erreur lors de la demande. Réessaie.'),
            backgroundColor: Color(0xFFE24B4A),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isRequestingPickup = false);
    }
  }

  Future<bool> _showConfirmDialog() async {
    return await showModalBottomSheet<bool>(
          context: context,
          backgroundColor: Colors.white,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          builder: (_) => Padding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Confirmer le retrait',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: darkText)),
                const SizedBox(height: 6),
                const Text(
                  'En confirmant, vous déclarez vouloir récupérer votre colis à l\'agence. '
                  'Présentez-vous avec votre pièce d\'identité.',
                  style: TextStyle(fontSize: 13, color: greySub, height: 1.5),
                ),
                const SizedBox(height: 24),
                Row(children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context, false),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFFDDDDDD)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(vertical: 13),
                      ),
                      child: const Text('Annuler', style: TextStyle(color: darkText)),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context, true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF639922),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        elevation: 0,
                      ),
                      child: const Text('Confirmer', style: TextStyle(fontWeight: FontWeight.w600)),
                    ),
                  ),
                ]),
              ],
            ),
          ),
        ) ??
        false;
  }

  // ── Build ──────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAF8),
      body: SafeArea(
        child: SingleChildScrollView(
          controller: _scrollController,
          child: Column(
            children: [
              _buildTopBar(),
              _buildHero(),
              _buildColisCard(),
              _buildOrderSummary(),
              if (_isAtAgence) _buildPickupCard(),
              if (_pickupRequested) _buildSuccessBanner(),
              if (_mapVisible) _buildMapCard(),
              _buildTrackButton(),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  // ── Top Bar ────────────────────────────────────────────────────────────
  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Row(
        children: [
          GestureDetector(
            onTap: () {
              _stopRefresh();
              Navigator.pop(context);
            },
            child: Container(
              width: 34, height: 34,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFF0F0F0),
                border: Border.all(color: Colors.black12, width: 0.5),
              ),
              child: const Icon(Icons.arrow_back_ios_new_rounded, size: 14, color: darkText),
            ),
          ),
          const Expanded(
            child: Text('Order Status',
                textAlign: TextAlign.center,
                style: TextStyle(color: darkText, fontSize: 15, fontWeight: FontWeight.w600)),
          ),
          const SizedBox(width: 34),
        ],
      ),
    );
  }

  // ── Hero ───────────────────────────────────────────────────────────────
  Widget _buildHero() {
    final atAgence = _isAtAgence;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Column(
        children: [
          Container(
            width: 72, height: 72,
            decoration: BoxDecoration(
              color: atAgence ? greenBg : const Color(0xFFFFF0E8),
              shape: BoxShape.circle,
              border: Border.all(color: atAgence ? greenBord : const Color(0xFFF5C4B3), width: 0.5),
            ),
            child: Icon(
              atAgence ? Icons.store_outlined : Icons.local_shipping_outlined,
              size: 34,
              color: atAgence ? greenMid : orange,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            atAgence ? 'Colis arrivé en agence' : 'Your package is on the way',
            style: const TextStyle(color: darkText, fontSize: 18, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 4),
          Text(
            atAgence
                ? 'Votre colis vous attend. Venez le récupérer.'
                : 'Estimated delivery: ${widget.colis.dateLivraison}',
            style: const TextStyle(fontSize: 13, color: greySub),
          ),
        ],
      ),
    );
  }

  // ── Colis Card ─────────────────────────────────────────────────────────
  Widget _buildColisCard() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(width: 0.5, color: Colors.black12),
          borderRadius: BorderRadius.circular(16),
        ),
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              width: 42, height: 42,
              decoration: BoxDecoration(
                color: const Color(0xFFFFF0E8),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.inventory_2_outlined, size: 20, color: orange),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(widget.colis.numero,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: darkText)),
                const SizedBox(height: 2),
                const Text('Hammami Transport',
                    style: TextStyle(color: orange, fontSize: 12, fontWeight: FontWeight.w600)),
              ]),
            ),
            Text('${widget.colis.montantCR.toStringAsFixed(3)} TND',
                style: const TextStyle(color: orange, fontSize: 15, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }

  // ── Order Summary ──────────────────────────────────────────────────────
  Widget _buildOrderSummary() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: Colors.black12, width: 0.5),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(14, 12, 14, 8),
            child: Text('Order Summary',
                style: TextStyle(color: darkText, fontSize: 13, fontWeight: FontWeight.w600)),
          ),
          const Divider(height: 0.5, thickness: 0.5, color: Color(0xFFF0F0F0)),
          _fieldRow('Date expédition', widget.colis.dateExpedition),
          _fieldRow('Expéditeur',      widget.colis.expediteur),
          _fieldRow('Tél expéditeur',  widget.colis.telExpediteur),
          _fieldRow('Destinataire',    widget.colis.destinataire),
          _fieldRow('Tél destinataire',widget.colis.telDestinataire),
          _fieldRow('Destination',     widget.colis.ville),
          _fieldRow('Montant CR',      '${widget.colis.montantCR.toStringAsFixed(3)} TND'),
          _fieldRow('Type',            widget.colis.type),
          _fieldRow('Libellé',         widget.colis.libelle, last: true),
        ]),
      ),
    );
  }

  Widget _fieldRow(String label, String value, {bool last = false, Color? valueColor}) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 14),
      decoration: BoxDecoration(
        border: last ? null : const Border(bottom: BorderSide(color: Color(0xFFF5F5F5), width: 0.5)),
      ),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(label, style: const TextStyle(color: orange, fontSize: 13)),
        const SizedBox(width: 12),
        Flexible(
          child: Text(value,
              textAlign: TextAlign.right,
              style: TextStyle(color: valueColor ?? darkText, fontSize: 13, fontWeight: FontWeight.w500)),
        ),
      ]),
    );
  }

  // ── Pickup Card ────────────────────────────────────────────────────────
  Widget _buildPickupCard() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFF639922), width: 2),
        ),
        clipBehavior: Clip.hardEdge,
        child: Column(children: [
          Container(
            width: double.infinity,
            color: greenBg,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
            child: Row(children: const [
              Icon(Icons.store_outlined, color: greenMid, size: 18),
              SizedBox(width: 8),
              Text('Colis disponible en agence',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: greenDark)),
            ]),
          ),
          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(14),
            child: Column(children: [
              _pickupInfoRow(
                icon: Icons.location_on_outlined,
                title: 'Agence Hammami — Sfax Centre',
                sub: 'Av. Habib Bourguiba, Sfax 3000\nOuvert : Lun–Sam, 08h00–18h00',
              ),
              const SizedBox(height: 10),
              _pickupInfoRow(
                icon: Icons.access_time_outlined,
                title: 'Disponible jusqu\'au 18/06/2025',
                sub: 'Au-delà, le colis sera retourné à l\'expéditeur.',
              ),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                height: 46,
                child: ElevatedButton.icon(
                  onPressed: _pickupRequested || _isRequestingPickup ? null : _requestPickup,
                  icon: _isRequestingPickup
                      ? const SizedBox(width: 18, height: 18,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Icon(Icons.move_to_inbox_outlined, size: 18),
                  label: Text(
                    _pickupRequested ? 'Demande envoyée' : 'Je viens récupérer mon colis',
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _pickupRequested
                        ? const Color(0xFF3B6D11).withOpacity(0.6)
                        : const Color(0xFF639922),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                ),
              ),
            ]),
          ),
        ]),
      ),
    );
  }

  Widget _pickupInfoRow({required IconData icon, required String title, required String sub}) {
    return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Container(
        width: 34, height: 34,
        decoration: BoxDecoration(color: greenBg, borderRadius: BorderRadius.circular(10)),
        child: Icon(icon, color: greenMid, size: 17),
      ),
      const SizedBox(width: 10),
      Expanded(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: darkText)),
          const SizedBox(height: 2),
          Text(sub, style: const TextStyle(fontSize: 12, color: greySub, height: 1.4)),
        ]),
      ),
    ]);
  }

  // ── Success Banner ─────────────────────────────────────────────────────
  Widget _buildSuccessBanner() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
      child: Container(
        decoration: BoxDecoration(
          color: greenBg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: greenBord, width: 0.5),
        ),
        padding: const EdgeInsets.all(14),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Icon(Icons.check_circle_outline_rounded, color: greenMid, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: const [
              Text('Demande envoyée à l\'agence',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: greenDark)),
              SizedBox(height: 3),
              Text('L\'agence prépare votre colis. Présentez-vous avec votre pièce d\'identité.',
                  style: TextStyle(fontSize: 12, color: greenMid, height: 1.4)),
            ]),
          ),
        ]),
      ),
    );
  }

  // ── Map Card (live GPS from API) ───────────────────────────────────────
  Widget _buildMapCard() {
    // Use live coords if available, fallback to static Firestore coords
    final lat = _liveRecord?.lat ?? widget.colis.latitude;
    final lng = _liveRecord?.lng ?? widget.colis.longitude;

    return Padding(
      key: _mapKey,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.black12, width: 0.5),
        ),
        clipBehavior: Clip.hardEdge,
        child: Column(children: [
          // ── Map header ──────────────────────────────────────────────
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Row(children: [
              const Icon(Icons.location_on_outlined, color: orange, size: 18),
              const SizedBox(width: 8),
              Text(
                _isAtAgence ? 'Adresse de l\'agence' : 'Localisation du camion',
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: darkText),
              ),
              const Spacer(),
              // Live badge OR loading indicator
              if (_gpsLoading)
                const SizedBox(width: 16, height: 16,
                    child: CircularProgressIndicator(color: orange, strokeWidth: 2))
              else if (_liveRecord != null && !_isAtAgence)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: redBg,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Container(width: 7, height: 7,
                        decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFFE24B4A))),
                    const SizedBox(width: 5),
                    const Text('Live', style: TextStyle(fontSize: 11, color: redText)),
                  ]),
                ),
            ]),
          ),

          // ── GPS error ────────────────────────────────────────────────
          if (_gpsError != null)
            Container(
              width: double.infinity,
              color: redBg,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              child: Text(_gpsError!,
                  style: const TextStyle(fontSize: 12, color: redText)),
            ),

          // ── Live info bar (speed / fuel) ─────────────────────────────
          if (_liveRecord != null && !_isAtAgence)
            Container(
              color: const Color(0xFFFAFAF8),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              child: Row(children: [
                _infoChip(Icons.speed_rounded,
                    '${_liveRecord!.speed.toStringAsFixed(0)} km/h'),
                const SizedBox(width: 12),
                _infoChip(Icons.local_gas_station_outlined,
                    '${_liveRecord!.fuel.toStringAsFixed(0)} L'),
              ]),
            ),

          const Divider(height: 0.5, thickness: 0.5, color: Color(0xFFF0F0F0)),

          // ── Map ──────────────────────────────────────────────────────
          SizedBox(
            height: 220,
            child: FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: LatLng(lat, lng),
                initialZoom: 13,
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.hammami_transport_app',
                ),
                MarkerLayer(markers: [
                  Marker(
                    point: LatLng(lat, lng),
                    width: 40, height: 40,
                    child: Container(
                      decoration: BoxDecoration(
                        color: _isAtAgence ? const Color(0xFF639922) : orange,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        _isAtAgence ? Icons.store_outlined : Icons.local_shipping_outlined,
                        color: Colors.white, size: 20,
                      ),
                    ),
                  ),
                ]),
              ],
            ),
          ),
        ]),
      ),
    );
  }

  Widget _infoChip(IconData icon, String label) {
    return Row(children: [
      Icon(icon, size: 14, color: greySub),
      const SizedBox(width: 4),
      Text(label, style: const TextStyle(fontSize: 12, color: greySub, fontWeight: FontWeight.w500)),
    ]);
  }

  // ── Track Button ───────────────────────────────────────────────────────
  Widget _buildTrackButton() {
    final atAgence = _isAtAgence;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: SizedBox(
        width: double.infinity,
        height: 52,
        child: ElevatedButton.icon(
          onPressed: _gpsLoading ? null : _onTrackPressed,
          icon: _gpsLoading
              ? const SizedBox(width: 18, height: 18,
                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
              : Icon(
                  atAgence
                      ? Icons.map_outlined
                      : (_mapVisible ? Icons.refresh_rounded : Icons.map_outlined),
                  size: 20),
          label: Text(
            atAgence
                ? 'Voir l\'adresse de l\'agence'
                : (_mapVisible ? 'Rafraîchir la position' : 'Track order'),
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: atAgence ? greenBg : orange,
            foregroundColor: atAgence ? greenDark : Colors.white,
            disabledBackgroundColor: orange.withOpacity(0.5),
            shape: const StadiumBorder(),
            elevation: 0,
          ),
        ),
      ),
    );
  }
}