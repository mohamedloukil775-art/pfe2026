class _CacheEntry<T> {
  _CacheEntry(this.value, this.expiresAt);

  final T value;
  final DateTime expiresAt;
}

class RequestCache {
  static final Map<String, _CacheEntry<dynamic>> _entries = {};

  static T? get<T>(String key) {
    final entry = _entries[key];
    if (entry == null) return null;
    if (DateTime.now().isAfter(entry.expiresAt)) {
      _entries.remove(key);
      return null;
    }
    return entry.value as T;
  }

  static void set<T>(String key, T value, {Duration ttl = const Duration(seconds: 30)}) {
    _entries[key] = _CacheEntry<T>(value, DateTime.now().add(ttl));
  }

  static void invalidate(String key) {
    _entries.remove(key);
  }

  static void clear() {
    _entries.clear();
  }
}