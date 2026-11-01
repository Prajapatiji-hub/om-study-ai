/// Syllabus data models.
///
/// No official syllabus entries have been added yet. Keep [kTracks] empty
/// until content is checked against a current official source.
class SyllabusTopic {
  final String id;
  final String title;
  const SyllabusTopic({required this.id, required this.title});
}

class SyllabusSubject {
  final String id;
  final String title;
  final List<SyllabusTopic> topics;
  const SyllabusSubject({
    required this.id,
    required this.title,
    this.topics = const [],
  });
}

class Track {
  final String id;
  final String goal;
  final String title;
  final String note;
  final bool verified;
  final List<SyllabusSubject> subjects;

  const Track({
    required this.id,
    required this.goal,
    required this.title,
    required this.note,
    this.verified = false,
    this.subjects = const [],
  });

  int get total => subjects.fold<int>(0, (sum, subject) => sum + subject.topics.length);

  String keyOf(SyllabusSubject subject, SyllabusTopic topic) =>
      '${subject.id}__${topic.id}';

  List<String> get allKeys => [
        for (final subject in subjects)
          for (final topic in subject.topics) keyOf(subject, topic),
      ];
}

/// Intentionally empty: add only syllabus content with a traceable source.
const List<Track> kTracks = [];
