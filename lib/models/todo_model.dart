class Todo {
  final String id;
  final String task;
  final bool isDone;
  final bool isStarred;
  final int position;
  final String frequency; // 'once', 'daily', or 'weekly'
  final int? repeatDay;

  Todo({
    required this.id, 
    required this.task, 
    this.isDone = false, 
    this.isStarred = false,
    this.position = 0,
    this.frequency = 'once',
    this.repeatDay,
  });

  // Convert Firestore document to Todo object
  factory Todo.fromFirestore(Map<String, dynamic> data, String id) {
    return Todo(
      id: id,
      task: data['task'] ?? '',
      isDone: data['isDone'] ?? false,
      isStarred: data['isStarred'] ?? false,
      position: data['position'] ?? 0,
      frequency: data['frequency'] ?? 'once',
      repeatDay: data['repeatDay'],
    );
  }

  // Convert Todo object to Firestore Map
  Map<String, dynamic> toMap() => {
    'task': task,
    'isDone': isDone,
    'isStarred': isStarred,
    'position': position,
    'frequency': frequency,
    'repeatDay': repeatDay,
  };
}
