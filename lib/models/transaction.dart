// lib/models/transaction.dart
import 'package:cloud_firestore/cloud_firestore.dart';

enum TransactionType { recharge, livraison, paiement, bloque }

class Transaction {
  final String id;
  final String libelle;
  final String date;
  final double montant;
  final TransactionType type;
  final String? colisId;       // référence au colis lié (si livraison)
  final Timestamp? timestamp;  // pour le tri Firestore

  Transaction({
    required this.id,
    required this.libelle,
    required this.date,
    required this.montant,
    required this.type,
    this.colisId,
    this.timestamp,
  });

  // ── Depuis Firestore
  factory Transaction.fromFirestore(Map<String, dynamic> d, {String id = ''}) {
    final typeStr = d['type'] ?? '';
    final type = typeStr == 'recharge'
        ? TransactionType.recharge
        : typeStr == 'livraison'
            ? TransactionType.livraison
            : typeStr == 'paiement'
                ? TransactionType.paiement
                : TransactionType.bloque;

    return Transaction(
      id:        id,
      libelle:   d['libelle']   ?? '',
      date:      d['date']      ?? '',
      montant:   (d['montant']  ?? 0).toDouble(),
      type:      type,
      colisId:   d['colisId'],
      timestamp: d['timestamp'] as Timestamp?,
    );
  }

  // ── Vers Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'libelle':   libelle,
      'date':      date,
      'montant':   montant,
      'type':      type.name,   // "recharge" | "livraison" | "paiement" | "bloque"
      'colisId':   colisId,
      'timestamp': FieldValue.serverTimestamp(),
    };
  }

  // ── Helpers pour l'UI
  bool get isCredit  => type == TransactionType.recharge;
  bool get isDebit   => type == TransactionType.livraison ||
                        type == TransactionType.paiement;
  bool get isBlocked => type == TransactionType.bloque;

  String get amountLabel {
    if (isBlocked)  return 'Refusé';
    if (isCredit)   return '(+${montant.toStringAsFixed(3)})';
    return '(-${montant.toStringAsFixed(3)})';
  }
}