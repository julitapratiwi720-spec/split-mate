class UserModel {
  final String uid;
  final String email;
  final String name;
  final String? fcmToken;

  UserModel({
    required this.uid,
    required this.email,
    required this.name,
    this.fcmToken,
  });

  Map<String, dynamic> toMap() => {
    'uid': uid,
    'email': email,
    'name': name,
    'fcmToken': fcmToken ?? '',
  };

  factory UserModel.fromMap(Map<String, dynamic> map) => UserModel(
    uid: map['uid'] ?? '',
    email: map['email'] ?? '',
    name: map['name'] ?? '',
    fcmToken: map['fcmToken'],
  );
}