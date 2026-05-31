import 'dart:typed_data';
import 'package:firebase_storage/firebase_storage.dart';

class StorageService {
  static final FirebaseStorage _storage = FirebaseStorage.instance;

  static Future<String> uploadFile({required String path, required Uint8List bytes}) async {
    final ref = _storage.ref().child(path);
    final uploadTask = ref.putData(bytes);
    final snapshot = await uploadTask;
    return snapshot.ref.getDownloadURL();
  }
}
