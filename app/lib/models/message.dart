class ChatMessage {
  final String id;
  final String visitorId;
  final String senderType; // visitor, member
  final String senderName;
  final String? senderId;
  final String content;
  final DateTime sentAt;

  ChatMessage({
    required this.id,
    required this.visitorId,
    required this.senderType,
    required this.senderName,
    this.senderId,
    required this.content,
    required this.sentAt,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id'] ?? json['messageId'] ?? '',
      visitorId: json['visitorId'] ?? json['visitor_id'] ?? '',
      senderType: json['senderType'] ?? json['sender_type'] ?? '',
      senderName: json['senderName'] ?? json['sender_name'] ?? '',
      senderId: json['senderId'] ?? json['sender_id'],
      content: json['content'] ?? json['text'] ?? '',
      sentAt: json['sentAt'] != null
          ? DateTime.parse(json['sentAt'])
          : (json['sent_at'] != null
              ? DateTime.parse(json['sent_at'])
              : DateTime.now()),
    );
  }

  bool get isFromVisitor => senderType == 'visitor';
  bool get isFromMember => senderType == 'member';
}
