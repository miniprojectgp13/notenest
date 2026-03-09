enum TaskStatus { notCompleted, inProgress, completed }

class TodoTask {
  TodoTask({
    required this.id,
    required this.title,
    required this.subject,
    required this.type,
    required this.dateTime,
    this.status = TaskStatus.notCompleted,
  });

  final String id;
  String title;
  String subject;
  String type;
  DateTime dateTime;
  TaskStatus status;
}
