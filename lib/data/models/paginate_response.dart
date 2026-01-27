class PaginateResponse<T> {
  final int count;
  final String? next;
  final String? previous;
  final List<T> results;

  PaginateResponse({
    required this.count,
    required this.next,
    required this.previous,
    required this.results,
  });

  factory PaginateResponse.fromJson(
    Map<String, dynamic> json,
    T Function(Map<String, dynamic>) fromJsonT,
  ) {
    return PaginateResponse<T>(
      count: json['count'] as int,
      next: json['next'] as String?,
      previous: json['previous'] as String?,
      results: (json['results'] as List<dynamic>)
          .map((item) => fromJsonT(item as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson(Map<String, dynamic> Function(T) toJsonT) {
    return {
      'count': count,
      'next': next,
      'previous': previous,
      'results': results.map((item) => toJsonT(item)).toList(),
    };
  }

  bool get hasNextPage => next != null;
  bool get hasPreviousPage => previous != null;
}
