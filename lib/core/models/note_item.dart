class NoteItem {
  NoteItem({
    required this.id,
    required this.name,
    required this.subject,
    required this.year,
    required this.type,
    required this.keywords,
    required this.createdAt,
    this.folderId,
    this.localPath,
  });

  final String id;
  String name;
  String subject;
  String year;
  String type;
  String keywords;
  DateTime createdAt;
  String? folderId;
  String? localPath;
}

class NoteFolder {
  NoteFolder({required this.id, required this.name, required this.createdAt});

  final String id;
  String name;
  DateTime createdAt;
}
