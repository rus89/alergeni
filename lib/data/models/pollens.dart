class Pollens {
  final int id;
  final int locationId;
  final DateTime date;
  final List<int> concentrationIds;

  Pollens({
    required this.id,
    required this.locationId,
    required this.date,
    required this.concentrationIds,
  });

  factory Pollens.fromJson(Map<String, dynamic> json) {
    return Pollens(
      id: json['id'],
      locationId: json['location'],
      date: DateTime.parse(json['date']),
      concentrationIds: List<int>.from(json['concentrations']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'location': locationId,
      'date': date.toIso8601String().split('T')[0],
      'concentrations': concentrationIds,
    };
  }
}
