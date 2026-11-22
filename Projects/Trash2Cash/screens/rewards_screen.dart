class Reward {
  final int id;
  final String image;
  final String name;
  final int quantity;
  final int pointsRequired;
  final String addedDate;

  Reward({
    required this.id,
    required this.image,
    required this.name,
    required this.quantity,
    required this.pointsRequired,
    required this.addedDate,
  });

  factory Reward.fromJson(Map<String, dynamic> json) {
    return Reward(
      id: json['id'] is int ? json['id'] : int.tryParse('${json['id']}') ?? 0,
      image: (json['image'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      quantity: json['quantity'] is int
          ? json['quantity']
          : int.tryParse('${json['quantity']}') ?? 0,
      pointsRequired: json['pointsrequired'] is int
          ? json['pointsrequired']
          : int.tryParse('${json['pointsrequired']}') ?? 0,
      addedDate: (json['added_date'] ?? '').toString(),
    );
  }
}