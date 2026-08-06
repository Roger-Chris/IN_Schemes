import 'dart:collection';

/// Immutable wrapper around raw catalog JSON entities.
/// Preserves complete un-flattened raw structure while providing typed accessors
/// and multilingual localization fallback helper methods.
class MssEntity {
  final String id;
  final String entityType;
  final String code;
  final String status;
  final Map<String, dynamic> raw;

  MssEntity._({
    required this.id,
    required this.entityType,
    required this.code,
    required this.status,
    required this.raw,
  });

  factory MssEntity.fromJson(Map<String, dynamic> json) {
    final identity = json['identity'] as Map<String, dynamic>? ?? {};
    final id = (identity['id'] ?? json['entityId'] ?? '') as String;
    final entityType = (identity['entityType'] ?? json['entityType'] ?? '') as String;
    final code = (identity['code'] ?? '') as String;
    final status = (identity['status'] ?? json['status'] ?? 'unknown') as String;

    return MssEntity._(
      id: id,
      entityType: entityType,
      code: code,
      status: status,
      raw: UnmodifiableMapView(json),
    );
  }

  /// Multilingual name resolution. Fallback order:
  /// localization[preferredLang]['name'] -> localization['ta']['name'] -> localization['en']['name'] -> identity['name']
  String getLocalizedName([String preferredLang = 'en']) {
    final loc = raw['localization'] as Map<String, dynamic>?;
    if (loc != null) {
      final preferred = loc[preferredLang] as Map<String, dynamic>?;
      if (preferred != null && (preferred['name'] as String?)?.isNotEmpty == true) {
        return preferred['name'] as String;
      }
      final ta = loc['ta'] as Map<String, dynamic>?;
      if (ta != null && (ta['name'] as String?)?.isNotEmpty == true) {
        return ta['name'] as String;
      }
      final en = loc['en'] as Map<String, dynamic>?;
      if (en != null && (en['name'] as String?)?.isNotEmpty == true) {
        return en['name'] as String;
      }
    }
    final identity = raw['identity'] as Map<String, dynamic>?;
    if (identity != null && (identity['name'] as String?)?.isNotEmpty == true) {
      return identity['name'] as String;
    }
    return '';
  }

  /// Multilingual attribute resolution for any field (e.g. 'summary', 'overview', 'description', 'benefits').
  String getLocalizedAttribute(String key, [String preferredLang = 'en']) {
    final loc = raw['localization'] as Map<String, dynamic>?;
    if (loc != null) {
      final preferred = loc[preferredLang] as Map<String, dynamic>?;
      if (preferred != null && (preferred[key] as String?)?.isNotEmpty == true) {
        return preferred[key] as String;
      }
      final ta = loc['ta'] as Map<String, dynamic>?;
      if (ta != null && (ta[key] as String?)?.isNotEmpty == true) {
        return ta[key] as String;
      }
      final en = loc['en'] as Map<String, dynamic>?;
      if (en != null && (en[key] as String?)?.isNotEmpty == true) {
        return en[key] as String;
      }
    }
    return '';
  }

  /// Accessors for nested entity sections
  Map<String, dynamic> get content =>
      (raw['content'] as Map<String, dynamic>?) ?? const {};

  Map<String, dynamic> get identity =>
      (raw['identity'] as Map<String, dynamic>?) ?? const {};

  Map<String, dynamic> get relationships =>
      (raw['relationships'] as Map<String, dynamic>?) ?? const {};

  Map<String, dynamic> get search =>
      (raw['search'] as Map<String, dynamic>?) ?? const {};

  Map<String, dynamic> get metadata =>
      (raw['metadata'] as Map<String, dynamic>?) ?? const {};

  List<Map<String, dynamic>> get references {
    final refs = relationships['references'] as List?;
    if (refs == null) return const [];
    return refs
        .whereType<Map<String, dynamic>>()
        .toList(growable: false);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MssEntity && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'MssEntity(id: $id, type: $entityType, code: $code, status: $status)';
}
