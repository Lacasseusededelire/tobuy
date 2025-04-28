class Suggestion {
  final String name;
  final String reason;
  final double estimatedPrice;

  Suggestion({
    required this.name,
    required this.reason,
    required this.estimatedPrice,
  });

  factory Suggestion.fromJson(Map<String, dynamic> json) {
    return Suggestion(
      name: json['name'] as String? ?? 'Inconnu',
      reason: json['reason'] as String? ?? 'Aucune raison',
      estimatedPrice: (json['estimated_price'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'reason': reason,
      'estimated_price': estimatedPrice,
    };
  }

  factory Suggestion.fromMap(Map<String, dynamic> map) {
    return Suggestion(
      name: map['name'] as String,
      reason: map['reason'] as String,
      estimatedPrice: (map['estimated_price'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return toJson();
  }

  @override
  String toString() {
    return 'Suggestion(name: $name, reason: $reason, estimatedPrice: $estimatedPrice)';
  }
}