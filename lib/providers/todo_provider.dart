import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/todo_model.dart';

final firestoreProvider = Provider((ref) => FirebaseFirestore.instance);

// This provider streams data from Firestore in real-time
final todoStreamProvider = StreamProvider<List<Todo>>((ref) {
  final user = FirebaseAuth.instance.currentUser;
  return ref.read(firestoreProvider)
      .collection('users')
      .doc(user?.uid)
      .collection('todos')
      .orderBy('position')
      .snapshots()
      .map((snapshot) => snapshot.docs
          .map((doc) => Todo.fromFirestore(doc.data(), doc.id))
          .toList());
});

// This handles the actions (Add, Toggle, Delete)
final todoActionProvider = Provider((ref) => TodoActionNotifier(ref));

class TodoActionNotifier {
  final Ref ref;
  TodoActionNotifier(this.ref);

  CollectionReference get _collection => ref.read(firestoreProvider)
      .collection('users')
      .doc(FirebaseAuth.instance.currentUser?.uid)
      .collection('todos');

  Future<void> addTask(
    String task, 
    int position, 
    {String frequency = 'once', int? repeatDay}
  ) async {
    await _collection.add({
      'task': task,
      'isDone': false,
      'isStarred': false,
      'position': position,
      'frequency': frequency,
      'repeatDay': repeatDay,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> updatePositions(List<Todo> reorderedList) async {
    final batch = ref.read(firestoreProvider).batch();
    for (int i = 0; i < reorderedList.length; i++) {
      batch.update(_collection.doc(reorderedList[i].id), {'position': i});
    }
    await batch.commit();
  }

  Future<void> toggleDone(Todo todo) async {
    await _collection.doc(todo.id).update({'isDone': !todo.isDone});
  }

  Future<void> toggleStar(Todo todo) async {
    await _collection.doc(todo.id).update({'isStarred': !todo.isStarred});
  }

  Future<void> deleteTodo(String id) async {
    await _collection.doc(id).delete();
  }

  Future<void> deleteAllCompleted() async {
    final query = await _collection.where('isDone', isEqualTo: true).get();
    final batch = ref.read(firestoreProvider).batch();
    
    for (var doc in query.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
  }

}
