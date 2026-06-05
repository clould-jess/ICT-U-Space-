class Hall {
  final String id;
  final String name;
  final int capacity;
  final String features;
  final String buildingBlock;

  Hall({
    required this.id,
    required this.name,
    required this.capacity,
    required this.features,
    required this.buildingBlock,
  });

  factory Hall.fromJson(Map<String, dynamic> json) {
    return Hall(
      id: json['id'],
      name: json['name'],
      capacity: json['capacity'],
      features: json['features'],
      buildingBlock: json['building_block'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'capacity': capacity,
      'features': features,
      'building_block': buildingBlock,
    };
  }
}
