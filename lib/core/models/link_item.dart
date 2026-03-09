class UrlSubFolder {
  UrlSubFolder({required this.id, required this.name});

  final String id;
  String name;
}

class UrlFolder {
  UrlFolder({required this.id, required this.name, required this.subFolders});

  final String id;
  String name;
  final List<UrlSubFolder> subFolders;
}

class SavedUrlItem {
  SavedUrlItem({
    required this.id,
    required this.url,
    required this.folderId,
    this.subFolderId,
    required this.content,
    required this.createdAt,
  });

  final String id;
  String url;
  String folderId;
  String? subFolderId;
  String content;
  DateTime createdAt;
}
