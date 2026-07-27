class AppNotificationModel {
  const AppNotificationModel({
    required this.id,
    required this.type,
    required this.channel,
    required this.title,
    required this.body,
    required this.data,
    required this.isRead,
    required this.createdAt,
    required this.readAt,
  });

  final int id;
  final String type;
  final String channel;
  final String title;
  final String body;
  final String data;
  final bool isRead;
  final DateTime createdAt;
  final DateTime? readAt;

  factory AppNotificationModel.fromJson(Map<String, dynamic> j) {
    final created = DateTime.tryParse('${j['created_at'] ?? ''}');
    final read = DateTime.tryParse('${j['read_at'] ?? ''}');

    return AppNotificationModel(
      id: (j['id'] as num?)?.toInt() ?? 0,
      type: (j['type'] ?? '').toString(),
      channel: (j['channel'] ?? '').toString(),
      title: (j['title'] ?? '').toString(),
      body: (j['body'] ?? '').toString(),
      data: (j['data'] ?? '').toString(),
      isRead: j['is_read'] == true,
      createdAt: created ?? DateTime.fromMillisecondsSinceEpoch(0),
      readAt: read,
    );
  }
  AppNotificationModel copyWith({bool? isRead, DateTime? readAt}) {
    return AppNotificationModel(
      id: id,
      type: type,
      channel: channel,
      title: title,
      body: body,
      data: data,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt,
      readAt: readAt ?? this.readAt,
    );
  }
}
