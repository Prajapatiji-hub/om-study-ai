import 'package:flutter_test/flutter_test.dart';
import 'package:om_study_ai/services/chat_message_pagination.dart';

class _Message {
  final String id;
  final int createdAt;
  const _Message(this.id, this.createdAt);
}

void main() {
  group('mergeChatMessagePages', () {
    int compare(_Message a, _Message b) => b.createdAt.compareTo(a.createdAt);

    test('keeps newest live messages before older pages', () {
      const live = [_Message('m5', 5), _Message('m4', 4)];
      const older = [_Message('m3', 3), _Message('m2', 2)];
      final result = mergeChatMessagePages(
        live: live,
        older: older,
        id: (message) => message.id,
        compareDescending: compare,
      );
      expect(result.map((message) => message.id), ['m5', 'm4', 'm3', 'm2']);
    });

    test('deduplicates overlapping live and older pages by document ID', () {
      const live = [_Message('m5', 5), _Message('m4', 4)];
      const older = [_Message('m4', 4), _Message('m3', 3)];
      final result = mergeChatMessagePages(
        live: live,
        older: older,
        id: (message) => message.id,
        compareDescending: compare,
      );
      expect(result.map((message) => message.id), ['m5', 'm4', 'm3']);
      expect(result.length, 3);
    });
  });
}
