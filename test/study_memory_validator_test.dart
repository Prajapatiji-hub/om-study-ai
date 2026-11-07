import 'package:flutter_test/flutter_test.dart';
import 'package:om_study_ai/services/study_memory_validator.dart';

void main() {
  group('sanitizeStudyMemory', () {
    test('trims text, removes blank items and deduplicates topics', () {
      final result = sanitizeStudyMemory(
        summary: '  गणित में सुधार  ',
        strengths: [' गणित ', '', 'गणित', 'विज्ञान'],
        weakTopics: [' ओम का नियम ', 'ओम का नियम'],
        preferredStyle: ' आसान हिंदी ',
      );
      expect(result['summary'], 'गणित में सुधार');
      expect(result['strengths'], ['गणित', 'विज्ञान']);
      expect(result['weakTopics'], ['ओम का नियम']);
      expect(result['preferredStyle'], 'आसान हिंदी');
    });

    test('accepts maximum documented text lengths and 12 topics', () {
      final result = sanitizeStudyMemory(
        summary: 'स' * 2000,
        strengths: List.generate(12, (i) => 'विषय$i'),
        weakTopics: const [],
        preferredStyle: 'श' * 300,
      );
      expect((result['summary'] as String).length, 2000);
      expect((result['strengths'] as List).length, 12);
      expect((result['preferredStyle'] as String).length, 300);
    });

    test('represents a cleared curated memory with explicit empty fields', () {
      final result = sanitizeStudyMemory(
        summary: '  ',
        strengths: const [],
        weakTopics: const [],
        preferredStyle: '',
      );
      expect(result, {
        'summary': '',
        'strengths': <String>[],
        'weakTopics': <String>[],
        'preferredStyle': '',
      });
    });

    test('rejects summary longer than 2000 characters', () {
      expect(() => sanitizeStudyMemory(
        summary: 'a' * 2001, strengths: const [], weakTopics: const [], preferredStyle: '',
      ), throwsArgumentError);
    });

    test('rejects preferred style longer than 300 characters', () {
      expect(() => sanitizeStudyMemory(
        summary: '', strengths: const [], weakTopics: const [], preferredStyle: 'a' * 301,
      ), throwsArgumentError);
    });

    test('rejects more than 12 topics or an item longer than 60 characters', () {
      expect(() => sanitizeStudyMemory(
        summary: '', strengths: List.generate(13, (i) => 'topic$i'),
        weakTopics: const [], preferredStyle: '',
      ), throwsArgumentError);
      expect(() => sanitizeStudyMemory(
        summary: '', strengths: ['a' * 61], weakTopics: const [], preferredStyle: '',
      ), throwsArgumentError);
    });

    test('trims and removes blank values before applying the topic count limit', () {
      final result = sanitizeStudyMemory(
        summary: '', strengths: List.generate(12, (i) => ' topic$i ') + [' ', 'topic0'],
        weakTopics: ['  ', ' weak topic '], preferredStyle: '',
      );
      expect((result['strengths'] as List).length, 12);
      expect(result['weakTopics'], ['weak topic']);
    });

    test('rejects a 61-character weak topic as well as a long strength', () {
      expect(() => sanitizeStudyMemory(
        summary: '', strengths: const [], weakTopics: ['b' * 61], preferredStyle: '',
      ), throwsArgumentError);
    });
  });
}
