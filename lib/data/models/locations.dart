class Locations {
  final int id;
  final String name;
  final String latitude;
  final String longitude;
  final String description;

  Locations({
    required this.id,
    required this.name,
    required this.latitude,
    required this.longitude,
    required this.description,
  });

  factory Locations.fromJson(Map<String, dynamic> json) {
    return Locations(
      id: json['id'],
      name: json['name'],
      latitude: json['latitude'],
      longitude: json['longitude'],
      description: json['description'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'latitude': latitude,
      'longitude': longitude,
      'description': description,
    };
  }
}
