import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// All private data lives under users/{uid}. uid comes from the signed-in user.
class UserRepo {
  final User user;
  UserRepo(this.user);

  String get uid => user.uid;
  final _db = FirebaseFirestore.instance;

  DocumentReference<Map<String, dynamic>> get _userDoc =>
      _db.collection('users').doc(uid);
  DocumentReference<Map<String, dynamic>> get _answersDoc =>
      _userDoc.collection('onboarding').doc('answers');

  Future<void> ensureProfile() async {
    final snap = await _userDoc.get();
    if (!snap.exists) {
      await _userDoc.set({
        'uid': uid,
        'displayName': (user.displayName ?? '').trim().isEmpty
            ? 'विद्यार्थी'
            : user.displayName!.trim(),
        'email': user.email ?? '',
        'language': 'hi',
        'selectedGoals': <String>[],
        'createdAt': FieldValue.serverTimestamp(),
      });
    }
  }

  Stream<Map<String, dynamic>> profile() =>
      _userDoc.snapshots().map((s) => s.data() ?? {});

  Stream<Map<String, dynamic>> answers() =>
      _answersDoc.snapshots().map((s) => s.data() ?? {});

  Future<Map<String, dynamic>> loadAnswers() async =>
      (await _answersDoc.get()).data() ?? {};

  Future<void> saveAnswer(String id, dynamic value) => _answersDoc
      .set({id: value}, SetOptions(merge: true))
      .timeout(const Duration(seconds: 10));

  CollectionReference<Map<String, dynamic>> get _progressCol =>
      _userDoc.collection('syllabus_progress');

  Stream<Map<String, dynamic>> progress(String trackId) =>
      _progressCol.doc(trackId).snapshots().map((s) => s.data() ?? {});

  Future<void> setTopicDone(String trackId, String key, bool done) => _progressCol
      .doc(trackId)
      .set({key: done ? true : FieldValue.delete()}, SetOptions(merge: true))
      .timeout(const Duration(seconds: 10));

  Future<void> updateProfile(Map<String, dynamic> data) => _userDoc
      // Add/repair the immutable owner UID when an older profile is first edited.
      // Merge preserves existing legacy fields and does not replace the document.
      .set({...data, 'uid': uid}, SetOptions(merge: true))
      .timeout(const Duration(seconds: 10));
}

String friendlyAuthError(Object e) {
  if (e is FirebaseAuthException) {
    switch (e.code) {
      case 'invalid-email':
        return 'ईमेल सही नहीं है।';
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        return 'ईमेल या पासवर्ड गलत है।';
      case 'email-already-in-use':
        return 'इस ईमेल से खाता पहले से बना है। लॉगिन करें।';
      case 'weak-password':
        return 'पासवर्ड कमज़ोर है। कम से कम 8 अक्षर रखें।';
      case 'network-request-failed':
        return 'इंटरनेट नहीं चल रहा। जाँचकर दोबारा कोशिश करें।';
      case 'too-many-requests':
        return 'बहुत ज़्यादा कोशिशें हुईं। थोड़ी देर बाद फिर करें।';
      case 'user-disabled':
        return 'यह खाता बंद है।';
    }
  }
  return 'कुछ गड़बड़ हो गई। दोबारा कोशिश करें।';
}
