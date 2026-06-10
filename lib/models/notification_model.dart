class NotificationModel {
  final String id;
  final String toUserId;
  final String title;
  final String body;
  final String type;
  final bool isRead;
  final DateTime createdAt;

  NotificationModel({
    required this.id,
    required this.toUserId,
    required this.title,
    required this.body,
    this.type = 'bill',
    this.isRead = false,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'toUserId': toUserId,
    'title': title,
    'body': body,
    'type': type,
    'isRead': isRead,
    'createdAt': createdAt.toIso8601String(),
  };

  factory NotificationModel.fromMap(Map<String, dynamic> map) =>
      NotificationModel(
        id: map['id'] ?? '',
        toUserId: map['toUserId'] ?? '',
        title: map['title'] ?? '',
        body: map['body'] ?? '',
        type: map['type'] ?? 'bill',
        isRead: map['isRead'] ?? false,
        createdAt: DateTime.parse(map['createdAt']),
      );
}