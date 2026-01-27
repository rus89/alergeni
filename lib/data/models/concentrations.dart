class Concentrations {
  final int id;
  final int allergenId;
  final int value;
  final int pollenId;

  Concentrations({
    required this.id,
    required this.allergenId,
    required this.value,
    required this.pollenId,
  });

  factory Concentrations.fromJson(Map<String, dynamic> json) {
    return Concentrations(
      id: json['id'],
      allergenId: json['allergen'],
      value: json['value'],
      pollenId: json['pollen'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'allergen': allergenId,
      'value': value,
      'pollen': pollenId,
    };
  }
}
