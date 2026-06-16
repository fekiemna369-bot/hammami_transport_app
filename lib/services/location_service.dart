import 'dart:convert';
import 'package:http/http.dart' as http;

// ── Models ───────────────────────────────────────────────────────────────────

class Vehicle {
  final int idDevice;
  final int idVehicule;
  final String matricule;
  final String mark;

  Vehicle({
    required this.idDevice,
    required this.idVehicule,
    required this.matricule,
    required this.mark,
  });

  factory Vehicle.fromJson(Map<String, dynamic> j) => Vehicle(
        idDevice: j['idDevice'] as int,
        idVehicule: j['idVehicule'] as int,
        matricule: j['matricule'] as String? ?? '',
        mark: j['mark'] as String? ?? '',
      );
}

class RealTimeRecord {
  final int idRealTimeRecord;
  final double lat;
  final double lng;
  final double speed;
  final double fuel;
  final double rpm;
  final double fuelRate;
  final int recordTime;

  RealTimeRecord({
    required this.idRealTimeRecord,
    required this.lat,
    required this.lng,
    required this.speed,
    required this.fuel,
    required this.rpm,
    required this.fuelRate,
    required this.recordTime,
  });

  factory RealTimeRecord.fromJson(Map<String, dynamic> j) {
    final coord = j['coordinate'] as Map<String, dynamic>? ?? {};
    return RealTimeRecord(
      idRealTimeRecord: j['idRealTimeRecord'] as int? ?? 0,
      lat: (coord['lat'] as num?)?.toDouble() ?? 0.0,
      lng: (coord['lng'] as num?)?.toDouble() ?? 0.0,
      speed: (j['speed'] as num?)?.toDouble() ?? 0.0,
      fuel: (j['fuel'] as num?)?.toDouble() ?? 0.0,
      rpm: (j['rpm'] as num?)?.toDouble() ?? 0.0,
      fuelRate: (j['fuel_rate'] as num?)?.toDouble() ?? 0.0,
      recordTime: j['recordTime'] as int? ?? 0,
    );
  }
}

// ── GPS Service ──────────────────────────────────────────────────────────────

class GpsService {
  static const String _base = 'https://fleet.tn/ws_rimtrack_all';

  String? _token;

  // ── 1. Authenticate and cache token ───────────────────────────────────
  Future<void> login({
    required String username,
    required String password,
  }) async {
    final res = await http.post(
      Uri.parse('$_base/signin'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'username': username, 'password': password}),
    );

    if (res.statusCode != 200) {
      throw Exception('Auth failed — ${res.statusCode}: ${res.body}');
    }

    final data = jsonDecode(res.body) as Map<String, dynamic>;
    // The API returns the token inside the response body or as a header.
    // Adjust the key below if needed (e.g. 'token', 'accessToken', 'jwt').
    final token = data['token'] as String? ??
        data['accessToken'] as String? ??
        data['jwt'] as String?;

    if (token == null) {
      throw Exception('Token not found in response: ${res.body}');
    }

    _token = token;
  }

  // ── 2. Fetch vehicle list ──────────────────────────────────────────────
  Future<List<Vehicle>> fetchVehicles({String keyword = ''}) async {
    _assertAuthenticated();

    final res = await http.get(
      Uri.parse('$_base/groupes/details?keyword=$keyword'),
      headers: _headers,
    );

    _assertOk(res, 'fetchVehicles');

    final groups = jsonDecode(res.body) as List<dynamic>;
    final vehicles = <Vehicle>[];

    for (final group in groups) {
      final list =
          (group as Map<String, dynamic>)['vehicules'] as List<dynamic>?;
      if (list != null) {
        vehicles.addAll(list
            .map((v) => Vehicle.fromJson(v as Map<String, dynamic>))
            .toList());
      }
    }

    return vehicles;
  }

  // ── 3. Fetch real-time records for ALL vehicles ────────────────────────
  Future<List<RealTimeRecord>> fetchRealTimeAll() async {
    _assertAuthenticated();

    final res = await http.get(
      Uri.parse('$_base/realTimeRecords'),
      headers: _headers,
    );

    _assertOk(res, 'fetchRealTimeAll');

    final list = jsonDecode(res.body) as List<dynamic>;
    return list
        .map((e) => RealTimeRecord.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  // ── 4. Fetch real-time for ONE vehicle by idDevice ─────────────────────
  // Use this to get live position of the truck assigned to a colis.
  Future<RealTimeRecord?> fetchRealTimeForDevice(int? idDevice) async {
    if (idDevice == null) return null;
    final all = await fetchRealTimeAll();
    // The API returns all vehicles; filter by idDevice == idRealTimeRecord
    // (adjust matching field based on actual API payload if needed)
    try {
      return all.firstWhere((r) => r.idRealTimeRecord == idDevice);
    } catch (_) {
      return null; // device not found in real-time feed
    }
  }

  // ── Helpers ────────────────────────────────────────────────────────────
  Map<String, String> get _headers => {
        'Authorization': 'Bearer $_token',
        'Content-Type': 'application/json',
      };

  void _assertAuthenticated() {
    if (_token == null) {
      throw Exception(
          'GpsService: not authenticated. Call login() first.');
    }
  }

  void _assertOk(http.Response res, String caller) {
    if (res.statusCode != 200) {
      throw Exception(
          '$caller failed — ${res.statusCode}: ${res.body}');
    }
  }
}