// lib/models/colis.dart

class Colis {
  final String id;          
  final String numero;       
  final String dateExpedition;
  final String expediteur;
  final String telExpediteur;
  final String destinataire;
  final String telDestinataire;
  final String ville;        
  final String type;         
  final double montantCR;   
  final String libelle;      
  final String payePar;      
  final double montantPaye;
  final String dateLivraison;
  final bool crSortie;       
  final String statut;       
  final double latitude;
  final double longitude;
  final String clientUid; 
  final int? idDevice; 

  const Colis({
    required this.id,
    required this.numero,
    required this.dateExpedition,
    required this.expediteur,
    required this.telExpediteur,
    required this.destinataire,
    required this.telDestinataire,
    required this.ville,
    required this.type,
    required this.montantCR,
    required this.libelle,
    required this.payePar,
    required this.montantPaye,
    required this.dateLivraison,
    required this.crSortie,
    required this.statut,
    required this.latitude,
    required this.longitude,
    required this.clientUid,
    this.idDevice,
  });

  // ── Depuis Firestore
  factory Colis.fromFirestore(String id, Map<String, dynamic> d) {
    return Colis(
      id:               id,
      numero:           d['numero']           ?? '',
      dateExpedition:   d['dateExpedition']   ?? '',
      expediteur:       d['expediteur']       ?? '',
      telExpediteur:    d['telExpediteur']    ?? '',
      destinataire:     d['destinataire']     ?? '',
      telDestinataire:  d['telDestinataire']  ?? '',
      ville:            d['ville']            ?? '',
      type:             d['type']             ?? 'Standard',
      montantCR:        (d['montantCR']       ?? 0).toDouble(),
      libelle:          d['libelle']          ?? '',
      payePar:          d['payePar']          ?? '',
      montantPaye:      (d['montantPaye']     ?? 0).toDouble(),
      dateLivraison:    d['dateLivraison']    ?? '—',
      crSortie:         d['crSortie']         ?? false,
      statut:           d['statut']           ?? 'en_transit',
      latitude:         (d['latitude']        ?? 0).toDouble(),
      longitude:        (d['longitude']       ?? 0).toDouble(),
      clientUid:        d['clientUid']        ?? '',
      idDevice:         d['idDevice'] != null ? (d['idDevice'] as num).toInt() : null,
    );
  }

  // ── Vers Firestore (pour écrire/mettre à jour)
  Map<String, dynamic> toFirestore() {
    return {
      'numero':          numero,
      'dateExpedition':  dateExpedition,
      'expediteur':      expediteur,
      'telExpediteur':   telExpediteur,
      'destinataire':    destinataire,
      'telDestinataire': telDestinataire,
      'ville':           ville,
      'type':            type,
      'montantCR':       montantCR,
      'libelle':         libelle,
      'payePar':         payePar,
      'montantPaye':     montantPaye,
      'dateLivraison':   dateLivraison,
      'crSortie':        crSortie,
      'statut':          statut,
      'latitude':        latitude,
      'longitude':       longitude,
      'clientUid':       clientUid,
      'idDevice':        idDevice,
    };
  }

  // ── Copie avec champs modifiés (utile pour mise à jour statut)
  Colis copyWith({
    String? statut,
    bool? crSortie,
    String? dateLivraison,
    double? latitude,
    double? longitude,
    int? idDevice,
  }) {
    return Colis(
      id:               id,
      numero:           numero,
      dateExpedition:   dateExpedition,
      expediteur:       expediteur,
      telExpediteur:    telExpediteur,
      destinataire:     destinataire,
      telDestinataire:  telDestinataire,
      ville:            ville,
      type:             type,
      montantCR:        montantCR,
      libelle:          libelle,
      payePar:          payePar,
      montantPaye:      montantPaye,
      dateLivraison:    dateLivraison ?? this.dateLivraison,
      crSortie:         crSortie     ?? this.crSortie,
      statut:           statut       ?? this.statut,
      latitude:         latitude     ?? this.latitude,
      longitude:        longitude    ?? this.longitude,
      clientUid:        clientUid,
      idDevice:         idDevice     ?? this.idDevice,
    );
  }
}