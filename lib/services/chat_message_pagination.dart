/// Combines the newest live page with older pages without duplicates.
/// Both inputs are expected in descending (newest-first) order.
List<T> mergeChatMessagePages<T>({
  required List<T> live,
  required List<T> older,
  required String Function(T item) id,
  required int Function(T a, T b) compareDescending,
}) {
  final byId = <String, T>{};
  for (final item in [...live, ...older]) {
    byId.putIfAbsent(id(item), () => item);
  }
  final merged = byId.values.toList()..sort(compareDescending);
  return merged;
}
