import 'dart:typed_data';

/// Support chat with the Rocket team. The customer sees one continuous chat;
/// the server groups it into conversations that staff can close.

class ChatImage {
  const ChatImage({required this.url, this.width, this.height});

  final String url;
  final int? width;
  final int? height;

  double? get aspectRatio => (width != null && height != null && height! > 0) ? width! / height! : null;
}

class ChatOrderRef {
  const ChatOrderRef({required this.id, required this.number});

  final int id;
  final String number;
}

enum ChatSender { customer, staff }

class ChatMessage {
  const ChatMessage({
    required this.id,
    required this.conversation,
    required this.isEvent,
    required this.event,
    required this.sender,
    required this.senderName,
    required this.body,
    required this.image,
    required this.order,
    required this.createdAt,
  });

  final int id;
  final int conversation;

  /// A line in the chat such as "this conversation has ended", not a message.
  final bool isEvent;
  final String event;
  final ChatSender sender;
  final String senderName;
  final String body;
  final ChatImage? image;
  final ChatOrderRef? order;
  final DateTime createdAt;

  bool get fromStaff => sender == ChatSender.staff;
}

class ChatConversation {
  const ChatConversation({
    required this.id,
    required this.isOpen,
    required this.staffLastRead,
    required this.customerLastRead,
  });

  final int id;
  final bool isOpen;

  /// Last message id the support team has seen (for ✓✓).
  final int staffLastRead;
  final int customerLastRead;

  ChatConversation copyWith({int? customerLastRead}) => ChatConversation(
    id: id,
    isOpen: isOpen,
    staffLastRead: staffLastRead,
    customerLastRead: customerLastRead ?? this.customerLastRead,
  );
}

/// One answer of GET /support/chat/.
class ChatSnapshot {
  const ChatSnapshot({
    required this.conversation,
    required this.messages,
    required this.hasOlder,
    required this.unread,
  });

  final ChatConversation? conversation;

  /// Oldest first.
  final List<ChatMessage> messages;
  final bool hasOlder;
  final int unread;
}

/// A photo picked on the phone, ready to upload.
class ChatPhoto {
  const ChatPhoto({required this.bytes, required this.name, this.mimeType = 'image/jpeg'});

  final Uint8List bytes;
  final String name;
  final String mimeType;
}

abstract interface class SupportRepository {
  /// The latest messages, only newer ones ([after]) or older ones ([before]).
  Future<ChatSnapshot> chat({int? after, int? before});

  Future<ChatMessage> send({required String body, ChatPhoto? photo, int? orderId});

  /// Marks the support team's messages as read. Returns the unread count left.
  Future<int> markRead(int messageId);

  Future<int> unread();
}
