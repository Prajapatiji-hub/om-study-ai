import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'study_memory_validator.dart';

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
    // Create the profile and required-onboarding marker atomically. If either
    // write fails, neither is committed, so a new account cannot bypass setup
    // because the profile write succeeded but the marker write failed.
    await _db.runTransaction((transaction) async {
      final snap = await transaction.get(_userDoc);
      if (snap.exists) return;

      transaction.set(_userDoc, {
        'uid': uid,
        'displayName': (user.displayName ?? '').trim().isEmpty
            ? 'विद्यार्थी'
            : user.displayName!.trim(),
        'email': user.email ?? '',
        'language': 'hi',
        'selectedGoals': <String>[],
        'createdAt': FieldValue.serverTimestamp(),
      });
      // Existing profiles are deliberately left untouched.
      transaction.set(_answersDoc, {
        '_setupRequired': true,
        '_setupCreatedAt': FieldValue.serverTimestamp(),
      });
    }).timeout(const Duration(seconds: 15));
  }

  Future<void> completeRequiredSetup() async {
    await _answersDoc.set({
      '_setupRequired': false,
      '_setupCompletedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true)).timeout(const Duration(seconds: 10));
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

  DocumentReference<Map<String, dynamic>> get _studyPlanDoc =>
      _userDoc.collection('study_plan').doc('current');

  Stream<Map<String, dynamic>> studyPlan() =>
      _studyPlanDoc.snapshots().map((s) => s.data() ?? {});

  Future<void> addStudyTask(String title) async {
    final snap = await _studyPlanDoc.get();
    final data = snap.data() ?? <String, dynamic>{};
    final raw = data['tasks'];
    final tasks = raw is List
        ? raw.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList()
        : <Map<String, dynamic>>[];
    if (tasks.length >= 100) {
      throw StateError('एक प्लान में अधिकतम 100 काम रख सकते हैं।');
    }
    tasks.add({
      'id': DateTime.now().microsecondsSinceEpoch.toString(),
      'title': title,
      'done': false,
    });
    await _studyPlanDoc.set({
      'dailyMinutes': data['dailyMinutes'] is int ? data['dailyMinutes'] : 120,
      'tasks': tasks,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true)).timeout(const Duration(seconds: 10));
  }

  Future<void> setStudyTarget(int minutes) async {
    if (![30, 60, 90, 120, 180, 240].contains(minutes)) {
      throw ArgumentError('अमान्य दैनिक लक्ष्य');
    }
    await _studyPlanDoc.set({
      'dailyMinutes': minutes,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true)).timeout(const Duration(seconds: 10));
  }

  Future<void> toggleStudyTask(String id, bool done) async {
    final snap = await _studyPlanDoc.get();
    final data = snap.data() ?? <String, dynamic>{};
    final raw = data['tasks'];
    final tasks = raw is List
        ? raw.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList()
        : <Map<String, dynamic>>[];
    final index = tasks.indexWhere((task) => task['id'] == id);
    if (index < 0) return;
    tasks[index]['done'] = done;
    await _studyPlanDoc.set({
      'tasks': tasks,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true)).timeout(const Duration(seconds: 10));
  }

  Future<void> deleteStudyTask(String id) async {
    final snap = await _studyPlanDoc.get();
    final data = snap.data() ?? <String, dynamic>{};
    final raw = data['tasks'];
    final tasks = raw is List
        ? raw.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList()
        : <Map<String, dynamic>>[];
    tasks.removeWhere((task) => task['id'] == id);
    await _studyPlanDoc.set({
      'tasks': tasks,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true)).timeout(const Duration(seconds: 10));
  }

  CollectionReference<Map<String, dynamic>> get _notesCol =>
      _userDoc.collection('notes');

  Stream<QuerySnapshot<Map<String, dynamic>>> notes() =>
      _notesCol.orderBy('updatedAt', descending: true).snapshots();

  Future<void> addNote({required String title, required String body}) async {
    final cleanTitle = title.trim();
    final cleanBody = body.trim();
    if (cleanTitle.isEmpty || cleanTitle.length > 100) {
      throw ArgumentError('शीर्षक 1 से 100 अक्षरों के बीच रखें।');
    }
    if (cleanBody.isEmpty || cleanBody.length > 20000) {
      throw ArgumentError('नोट 1 से 20,000 अक्षरों के बीच रखें।');
    }
    await _notesCol.add({
      'title': cleanTitle,
      'body': cleanBody,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    }).timeout(const Duration(seconds: 15));
  }

  Future<void> updateNote({
    required String noteId,
    required String title,
    required String body,
  }) async {
    final cleanTitle = title.trim();
    final cleanBody = body.trim();
    if (cleanTitle.isEmpty || cleanTitle.length > 100) {
      throw ArgumentError('शीर्षक 1 से 100 अक्षरों के बीच रखें।');
    }
    if (cleanBody.isEmpty || cleanBody.length > 20000) {
      throw ArgumentError('नोट 1 से 20,000 अक्षरों के बीच रखें।');
    }
    await _notesCol.doc(noteId).update({
      'title': cleanTitle,
      'body': cleanBody,
      'updatedAt': FieldValue.serverTimestamp(),
    }).timeout(const Duration(seconds: 15));
  }

  Future<void> deleteNote(String noteId) =>
      _notesCol.doc(noteId).delete().timeout(const Duration(seconds: 15));


  DocumentReference<Map<String, dynamic>> get _studyMemoryDoc =>
      _userDoc.collection('ai_study_memory').doc('profile');

  Future<Map<String, dynamic>> loadStudyMemory() async =>
      (await _studyMemoryDoc.get()).data() ?? {};

  Future<void> saveStudyMemory({
    required String summary,
    required List<String> strengths,
    required List<String> weakTopics,
    required String preferredStyle,
  }) async {
    final data = sanitizeStudyMemory(
      summary: summary,
      strengths: strengths,
      weakTopics: weakTopics,
      preferredStyle: preferredStyle,
    );
    await _studyMemoryDoc.set({
      ...data,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true)).timeout(const Duration(seconds: 12));
  }

  CollectionReference<Map<String, dynamic>> get _quizAttemptsCol =>
      _userDoc.collection('quiz_attempts');

  Future<void> saveQuizAttempt({
    required String quizId,
    required int score,
    required int total,
    required List<Map<String, dynamic>> responses,
  }) async {
    if (quizId.isEmpty || quizId.length > 80) {
      throw ArgumentError('टेस्ट की पहचान सही नहीं है।');
    }
    if (total < 1 || total > 100 || score < 0 || score > total ||
        responses.length != total) {
      throw ArgumentError('टेस्ट का परिणाम सही नहीं है।');
    }
    for (final response in responses) {
      final question = response['question'];
      final options = response['options'];
      final selected = response['selectedIndex'];
      final correct = response['correctIndex'];
      if (question is! String || question.isEmpty || question.length > 1000 ||
          options is! List || options.length < 2 || options.length > 6 ||
          options.any((option) => option is! String || option.length > 300) ||
          selected is! int || selected < 0 || selected >= options.length ||
          correct is! int || correct < 0 || correct >= options.length ||
          response['explanation'] is! String ||
          (response['explanation'] as String).length > 2000) {
        throw ArgumentError('टेस्ट के उत्तर का विवरण सही नहीं है।');
      }
    }
    await _quizAttemptsCol.add({
      'quizId': quizId,
      'score': score,
      'total': total,
      'responses': responses,
      'createdAt': FieldValue.serverTimestamp(),
    }).timeout(const Duration(seconds: 15));
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> quizAttempts() =>
      _quizAttemptsCol.orderBy('createdAt', descending: true).limit(50).snapshots();

  Future<void> updateProfile(Map<String, dynamic> data) => _userDoc
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
