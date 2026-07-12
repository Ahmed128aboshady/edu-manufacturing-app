class AppUser {
  final int id;
  final String name;
  final String email;
  final String? phone;
  final String? street;
  final String? city;
  final int partnerId;

  const AppUser({
    required this.id,
    required this.name,
    required this.email,
    this.phone,
    this.street,
    this.city,
    required this.partnerId,
  });

  factory AppUser.fromJson(Map<String, dynamic> json, {int? partnerId}) {
    return AppUser(
      id: json['uid'] as int? ?? 0,
      name: json['name'] as String? ?? 'User',
      email: json['username'] as String? ?? '',
      partnerId: partnerId ?? json['partner_id'] as int? ?? 0,
    );
  }

  factory AppUser.fromPartner(Map<String, dynamic> json) {
    return AppUser(
      id: 0,
      name: json['name'] as String? ?? 'User',
      email: json['email'] as String? ?? '',
      phone: json['phone'] as String?,
      street: json['street'] as String?,
      city: json['city'] as String?,
      partnerId: json['id'] as int,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'email': email,
    'phone': phone,
    'street': street,
    'city': city,
    'partnerId': partnerId,
  };

  AppUser copyWith({String? phone, String? street, String? city}) => AppUser(
    id: id,
    name: name,
    email: email,
    phone: phone ?? this.phone,
    street: street ?? this.street,
    city: city ?? this.city,
    partnerId: partnerId,
  );
}
