import 'package:json_annotation/json_annotation.dart';

part 'user.g.dart';

@JsonSerializable()
class User {
  final String id;
  final String name;
  final String email;
  final String role;
  final String? token;
  final DateTime? passwordChangedAt;

  User({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.token,
    this.passwordChangedAt,
  });

  factory User.fromJson(Map<String, dynamic> json) => _$UserFromJson(json);

  Map<String, dynamic> toJson() => _$UserToJson(this);

  User copyWith({
    String? id,
    String? name,
    String? email,
    String? role,
    String? token,
    DateTime? passwordChangedAt,
  }) {
    return User(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      role: role ?? this.role,
      token: token ?? this.token,
      passwordChangedAt: passwordChangedAt ?? this.passwordChangedAt,
    );
  }
}
