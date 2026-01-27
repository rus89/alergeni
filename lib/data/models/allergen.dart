class Allergen {
  final int id;
  final String name;
  final String localizedName;
  final int marginTop;
  final int marginBottom;
  final int type;
  final int allergenicityIndex;
  final String allergenicityDisplay;

  Allergen({
    required this.id,
    required this.name,
    required this.localizedName,
    required this.marginTop,
    required this.marginBottom,
    required this.type,
    required this.allergenicityIndex,
    required this.allergenicityDisplay,
  });

  factory Allergen.fromJson(Map<String, dynamic> json) {
    return Allergen(
      id: json['id'],
      name: json['name'],
      localizedName: json['localized_name'],
      marginTop: json['margine_top'],
      marginBottom: json['margine_bottom'],
      type: json['type'],
      allergenicityIndex: json['allergenicity'],
      allergenicityDisplay: json['allergenicity_display'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'localized_name': localizedName,
      'margine_top': marginTop,
      'margine_bottom': marginBottom,
      'type': type,
      'allergenicity': allergenicityIndex,
      'allergenicity_display': allergenicityDisplay,
    };
  }
}
