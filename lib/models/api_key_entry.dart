class ApiKeyEntry {
  String id;
  String label;
  String key;
  DateTime addedAt;

  ApiKeyEntry({
    required this.id,
    required this.label,
    required this.key,
    DateTime? addedAt,
  }) : addedAt = addedAt ?? DateTime.now();

  /// Masked view for display, e.g. nvapi-••••••3kP1
  String get masked {
    if (key.length <= 10) return key;
    final start = key.substring(0, 6);
    final end   = key.substring(key.length - 4);
    return '$start••••••$end';
  }

  Map<String, dynamic> toJson() => {
    'id': id, 'label': label, 'key': key,
    'addedAt': addedAt.toIso8601String(),
  };

  factory ApiKeyEntry.fromJson(Map<String, dynamic> j) => ApiKeyEntry(
    id: j['id'], label: j['label'], key: j['key'],
    addedAt: DateTime.tryParse(j['addedAt'] ?? '') ?? DateTime.now(),
  );
}
