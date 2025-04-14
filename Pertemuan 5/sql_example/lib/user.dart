class User{
  final int? id;
  final String username;
  final String email;

  User({this.id, required this.username, required this.email});

  Map<String, dynamic> toMap() {
    return {'id': id, 'username': username, 'email': email};
  }

  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      id: map['id'],
      username: map['username'],
      email: map['email'],
    );
  }
}