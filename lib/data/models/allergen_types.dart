class AllergenTypes {
  final int id;
  final String name;

  AllergenTypes({required this.id, required this.name});

  factory AllergenTypes.fromJson(Map<String, dynamic> json) {
    return AllergenTypes(id: json['id'], name: json['name']);
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'name': name};
  }
}
