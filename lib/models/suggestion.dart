// Ce modèle est utilisé par l'IA (Membre 3) mais défini ici car partagé

class Suggestion {
  final String name; // Nom de l'aliment suggéré
  final String reason; // Pourquoi il est suggéré
  final double estimatedPrice; // Prix estimé (optionnel)

  Suggestion({
    required this.name,
    required this.reason,
    this.estimatedPrice = 0.0, // Prix par défaut à 0 si non fourni
  });

  // Factory constructor pour créer depuis une Map (ex: réponse JSON de l'API Gemini)
  factory Suggestion.fromJson(Map<String, dynamic> json) {
    return Suggestion(
      name: json['name'] as String? ?? 'Inconnu',
      reason: json['reason'] as String? ?? 'Aucune raison',
      estimatedPrice: (json['estimated_price'] as num?)?.toDouble() ?? 0.0,
    );
  }

  // Méthode pour convertir en Map (moins utile ici, mais pour la complétude)
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'reason': reason,
      'estimated_price': estimatedPrice,
    };
  }

  // Méthode toString pour faciliter le débogage
  @override
  String toString() {
    return 'Suggestion(name: $name, reason: $reason, estimatedPrice: $estimatedPrice)';
  }
}
