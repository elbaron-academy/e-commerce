import 'package:dio/dio.dart';

import '../../../core/network/api_client.dart';
import '../domain/chat.dart';

class SupportRepositoryImpl implements SupportRepository {
  SupportRepositoryImpl(this._api);

  final ApiClient _api;

  @override
  Future<ChatSnapshot> chat({int? after, int? before}) async {
    final data = await _api.get<Map<String, dynamic>>('/support/chat/', query: {'after': ?after, 'before': ?before});
    return chatSnapshotFromJson(data);
  }

  @override
  Future<ChatMessage> send({required String body, ChatPhoto? photo, int? orderId}) async {
    final Object data = photo == null
        ? {'body': body, 'order': orderId}
        : FormData.fromMap({
            'body': body,
            'order': ?orderId?.toString(),
            'image': MultipartFile.fromBytes(
              photo.bytes,
              filename: photo.name,
              contentType: DioMediaType.parse(photo.mimeType),
            ),
          });
    return chatMessageFromJson(await _api.post<Map<String, dynamic>>('/support/chat/messages/', data: data));
  }

  @override
  Future<int> markRead(int messageId) async {
    final data = await _api.post<Map<String, dynamic>>('/support/chat/read/', data: {'message_id': messageId});
    return data['unread'] as int;
  }

  @override
  Future<int> unread() async => (await _api.get<Map<String, dynamic>>('/support/chat/unread/'))['unread'] as int;
}

ChatSnapshot chatSnapshotFromJson(Map<String, dynamic> json) {
  final conversation = json['conversation'] as Map<String, dynamic>?;
  return ChatSnapshot(
    conversation: conversation == null
        ? null
        : ChatConversation(
            id: conversation['id'] as int,
            isOpen: conversation['status'] == 'open',
            staffLastRead: conversation['staff_last_read'] as int? ?? 0,
            customerLastRead: conversation['customer_last_read'] as int? ?? 0,
          ),
    messages: [for (final m in json['messages'] as List) chatMessageFromJson(m as Map<String, dynamic>)],
    hasOlder: json['has_older'] as bool? ?? false,
    unread: json['unread'] as int? ?? 0,
  );
}

ChatMessage chatMessageFromJson(Map<String, dynamic> json) {
  final image = json['image'] as Map<String, dynamic>?;
  final order = json['order'] as Map<String, dynamic>?;
  return ChatMessage(
    id: json['id'] as int,
    conversation: json['conversation'] as int,
    isEvent: json['kind'] == 'event',
    event: json['event'] as String? ?? '',
    sender: json['sender'] == 'staff' ? ChatSender.staff : ChatSender.customer,
    senderName: json['sender_name'] as String? ?? '',
    body: json['body'] as String? ?? '',
    image: image == null
        ? null
        : ChatImage(url: image['url'] as String, width: image['width'] as int?, height: image['height'] as int?),
    order: order == null ? null : ChatOrderRef(id: order['id'] as int, number: order['number'] as String? ?? ''),
    createdAt: DateTime.parse(json['created_at'] as String).toLocal(),
  );
}
