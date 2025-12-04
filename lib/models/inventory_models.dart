class InventoryItem {
  String? id;
  String name;
  String category;
  double quantity; 
  String unit;
  double price;
  String currency;
  DateTime expiryDate;
  String location;
  double latitude;
  double longitude;

  InventoryItem({
    required this.id,
    required this.name,
    required this.category,
    required this.quantity,
    required this.unit,
    required this.price,
    required this.currency,
    required this.expiryDate,
    required this.location,
    required this.latitude,
    required this.longitude,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'category': category,
      'quantity': quantity, 
      'unit': unit,
      'price': price,
      'currency': currency,
      'expiryDate': expiryDate.toIso8601String(),
      'location': location,
      'latitude': latitude,
      'longitude': longitude,
    };
  }

  factory InventoryItem.fromMap(Map<String, dynamic> map) {
    return InventoryItem(
      id: map['id'] as String?,
      name: map['name'] as String,
      category: map['category'] as String,
      quantity: (map['quantity'] is int) 
          ? (map['quantity'] as int).toDouble() 
          : (map['quantity'] as double),
      unit: map['unit'] as String,
      price: (map['price'] is int) 
          ? (map['price'] as int).toDouble() 
          : (map['price'] as double),
      currency: map['currency'] as String,
      expiryDate: DateTime.parse(map['expiryDate'] as String),
      location: map['location'] as String,
      latitude: map['latitude'] as double,
      longitude: map['longitude'] as double,
    );
  }
}