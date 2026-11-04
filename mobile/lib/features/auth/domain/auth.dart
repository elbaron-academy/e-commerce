class User {
  const User({required this.id, required this.phone, required this.name, required this.email, required this.language});

  factory User.fromJson(Map<String, dynamic> json) => User(
    id: json['id'] as int,
    phone: json['phone'] as String,
    name: (json['name'] as String?) ?? '',
    email: (json['email'] as String?) ?? '',
    language: (json['language'] as String?) ?? 'ar',
  );

  final int id;
  final String phone;
  final String name;
  final String email;
  final String language;

  Map<String, dynamic> toJson() => {'id': id, 'phone': phone, 'name': name, 'email': email, 'language': language};
}

abstract interface class AuthRepository {
  User? get cachedUser;
  bool get hasSession;

  /// Sends the login code by SMS. Returns how many seconds until a new code can be requested.
  Future<int> sendCode(String phone);

  /// Checks the code, stores the tokens and returns the customer.
  Future<({User user, bool isNew})> verifyCode(String phone, String code);

  Future<User> me();
  Future<User> updateProfile({String? name, String? email, String? language});
  Future<void> logout();
}
