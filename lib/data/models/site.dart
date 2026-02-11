class Site {
  final int locationId;
  final String? date;
  final int allergenId;
  final String? allergenName;
  final int allergenicityIndex;
  final int level;
  final int trend;
  final int week;

  Site({
    required this.locationId,
    this.date,
    required this.allergenId,
    this.allergenName,
    required this.allergenicityIndex,
    required this.level,
    required this.trend,
    required this.week,
  });

  factory Site.fromJson(Map<String, dynamic> json) {
    return Site(
      locationId: json['location'],
      date: json['date'],
      allergenId: json['allergen'],
      allergenName: json['allergen_name'],
      allergenicityIndex: json['allergenicity'],
      level: json['level'],
      trend: json['trend'],
      week: json['week'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'location': locationId,
      'date': date,
      'allergen': allergenId,
      'allergen_name': allergenName,
      'allergenicity': allergenicityIndex,
      'level': level,
      'trend': trend,
      'week': week,
    };
  }
}
