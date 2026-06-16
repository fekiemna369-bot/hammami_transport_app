import 'package:cloud_firestore/cloud_firestore.dart';

class AppUser {
  final String uid;
  final String email;
  final String nom;
  final String prenom;
  final String photoUrl;
  final String telephone;

  //Wallet
  final double solde;
  final double soldeMinimum;
  final double limiteTransaction;

  //Agent IA
  final bool isBlocked;
  final String? blockedReason;
  final DateTime? blockedAt;

  //FCM
  final String? fcmToken;

  //Card
  final String cardNumber;

  final DateTime createdAt;

  const AppUser({
    required this.uid,
    required this.email,
    required this.nom,
    required this.prenom,
    required this.telephone,
    this.photoUrl = '',
    this.solde = 0.0,
    this.soldeMinimum = 100.0,
    this.limiteTransaction = -20.0,
    this.isBlocked = false,
    this.blockedReason,
    this.blockedAt,
    this.fcmToken,
    this.cardNumber = '0000',
    required this.createdAt,
  });
  //Depuis Firestore
  factory AppUser.fromFirestore(String uid, Map<String, dynamic> d) {
    return AppUser(
      uid: uid,
      email: d['email'] ?? '',
      nom: d['nom'] ?? '',
      prenom: d['prenom'] ?? '',
      telephone: d['telephone'] ?? '',
      photoUrl: d['photoUrl'] ?? '',
      solde: (d['solde'] ?? 0.0).toDouble(),
      soldeMinimum: (d['soldeMinimum'] ?? 100.0).toDouble(),
        limiteTransaction: (d['limiteTransaction'] ?? -20.0).toDouble(),
      isBlocked: d['isBlocked'] ?? false,
      blockedReason: d['blockedReason'],
      blockedAt: d['blockedAt'] != null
          ? (d['blockedAt'] as Timestamp).toDate()
          : null,
      fcmToken: d['fcmToken'],
      cardNumber: d['cardNumber'] ?? '0000',
      createdAt: d['createdAt'] != null
          ? (d['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  //vers Firestore (création du compte)
  Map<String, dynamic> toFirestore() {
    return {
      'email': email,
      'nom': nom,
      'prenom': prenom,
      'telephone': telephone,
      'photoUrl': photoUrl,
      'solde': solde,
      'soldeMinimum': soldeMinimum,
      'limiteTransaction': limiteTransaction,
      'isBlocked': isBlocked,
      'blockedAt': blockedAt != null ? Timestamp.fromDate(blockedAt!) : null,
      'fcmToken': fcmToken,
      'cardNumber': cardNumber,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }

  // ── Copie avec champs modifiés
  AppUser copyWith({
    String? nom,
    String? prenom,
    String? telephone,
    String? photoUrl,
    double? solde,
    bool? isBlocked,
    String? blockedReason,
    DateTime? blockedAt,
    String? fcmToken,
  }) {
    return AppUser(
      uid: uid,
      email: email,
      nom: nom ?? this.nom,
      prenom: prenom ?? this.prenom,
      telephone: telephone ?? this.telephone,
      photoUrl: photoUrl ?? this.photoUrl,
      solde: solde ?? this.solde,
      soldeMinimum: soldeMinimum,
      limiteTransaction: limiteTransaction,
      isBlocked: isBlocked ?? this.isBlocked,
      blockedReason: blockedReason ?? this.blockedReason,
      blockedAt: blockedAt ?? this.blockedAt,
      fcmToken: fcmToken ?? this.fcmToken,
      cardNumber: cardNumber,
      createdAt: createdAt,
    );
  }

  // ── Nom complet
  String get fullName => '$prenom $nom';

  // ── Initiales pour l'avatar
  String get initials {
    final p = prenom.isNotEmpty ? prenom[0].toUpperCase() : '';
    final n = nom.isNotEmpty ? nom[0].toUpperCase() : '';
    return '$p$n';
  }
}
