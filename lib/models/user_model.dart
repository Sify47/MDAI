// lib/models/user_model.dart

class User {
  final int id;
  final String name;
  final String email;
  final String? phone;
  final DateTime birthDate;
  final String gender;
  final String? token;
  final String? refreshToken;

  User({
    required this.id,
    required this.name,
    required this.email,
    this.phone,
    required this.birthDate,
    required this.gender,
    this.token,
    this.refreshToken,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'],
      birthDate: DateTime.parse(
        json['birth_date'] ?? DateTime.now().toIso8601String(),
      ),
      gender: json['gender'] ?? 'ذكر',
      token: json['token'] ?? json['access_token'],
      refreshToken: json['refresh_token'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'birth_date': birthDate.toIso8601String(),
      'gender': gender,
      'token': token,
      'refresh_token': refreshToken,
    };
  }
}
