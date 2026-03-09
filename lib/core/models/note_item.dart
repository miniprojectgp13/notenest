class NoteItem {
  NoteItem({
    required this.id,
    required this.name,
    required this.subject,
    required this.year,
    required this.type,
    required this.keywords,
    required this.createdAt,
    this.localPath,
  });

  final String id;
  String name;
  String subject;
  String year;
  String type;
  String keywords;
  DateTime createdAt;
  String? localPath;
}
