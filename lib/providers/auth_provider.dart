import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final authRepositoryProvider = Provider((ref) => FirebaseAuth.instance);

final authStateProvider = StreamProvider((ref) {
  return ref.watch(authRepositoryProvider).authStateChanges();
});
