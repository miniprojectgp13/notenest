class ChatMessage {
  ChatMessage({
    required this.sender,
    required this.content,
    required this.sentAt,
    this.isMine = false,
    this.attachmentName,
    this.attachmentRef,
    this.attachmentType,
  });

  String sender;
  String content;
  DateTime sentAt;
  bool isMine;
  String? attachmentName;
  String? attachmentRef;
  String? attachmentType;
}

class GroupMember {
  GroupMember({required this.name, required this.uniqueId});

  String name;
  String uniqueId;
}

class GroupAttachment {
  GroupAttachment({
    required this.id,
    required this.fileName,
    required this.fileRef,
    required this.fileType,
    required this.sentBy,
    required this.sentAt,
  });

  String id;
  String fileName;
  String fileRef;
  String fileType;
  String sentBy;
  DateTime sentAt;
}

class GroupItem {
  GroupItem({
    required this.id,
    required this.name,
    required this.members,
    required this.messages,
    required this.attachments,
    this.photoPath,
  });

  final String id;
  String name;
  String? photoPath;
  List<GroupMember> members;
  List<ChatMessage> messages;
  List<GroupAttachment> attachments;
}
