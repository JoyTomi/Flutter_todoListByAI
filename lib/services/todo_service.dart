import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/todo.dart';

class TodoService {
  final DatabaseReference _database = FirebaseDatabase.instance.ref();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String get _userId => _auth.currentUser?.uid ?? '';

  Stream<List<Todo>> getTodos() {
    return _database
        .child('todos')
        .orderByChild('userId')
        .equalTo(_userId)
        .onValue
        .map((event) {
      final data = event.snapshot.value as Map<dynamic, dynamic>?;
      if (data == null) return [];
      
      return data.entries.map((entry) {
        final todoData = Map<String, dynamic>.from(entry.value as Map);
        todoData['id'] = entry.key;
        return Todo.fromJson(todoData);
      }).toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    });
  }

  Future<void> addTodo(String title) async {
    final todoRef = _database.child('todos').push();
    final todo = Todo(
      id: todoRef.key!,
      title: title,
      userId: _userId,
      createdAt: DateTime.now(),
    );
    await todoRef.set(todo.toJson());
  }

  Future<void> updateTodo(Todo todo) async {
    await _database.child('todos/${todo.id}').update(todo.toJson());
  }

  Future<void> updateTodoTitle(String id, String newTitle) async {
    await _database.child('todos/$id').update({'title': newTitle});
  }

  Future<void> deleteTodo(String id) async {
    await _database.child('todos/$id').remove();
  }

  Future<void> toggleTodoStatus(Todo todo) async {
    final updatedTodo = todo.copyWith(isCompleted: !todo.isCompleted);
    await updateTodo(updatedTodo);
  }
} 