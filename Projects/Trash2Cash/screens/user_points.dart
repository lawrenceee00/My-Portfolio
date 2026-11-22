class UserPoints {
  final double total;
  final double weekly;

  const UserPoints({required this.total, required this.weekly});

  static double _toDouble(dynamic v) =>
      v is num ? v.toDouble() : double.tryParse('${v ?? ''}') ?? 0.0;

  factory UserPoints.fromJson(Map<String, dynamic> json) {
    return UserPoints(
      total: _toDouble(json['total']),
      weekly: _toDouble(json['weekly']),
    );
  }
}