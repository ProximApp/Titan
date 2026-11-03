class PathForwarding {
  final String path;
  final bool isLoggedIn;
  final bool preAuth;

  final Map<String, String>? queryParameters;
  PathForwarding({
    required this.path,
    required this.isLoggedIn,
    this.preAuth = false,
    this.queryParameters,
  });

  PathForwarding copyWith({
    String? path,
    bool? isLoggedIn,
    bool? preAuth,
    Map<String, String>? queryParameters,
  }) {
    return PathForwarding(
      path: path ?? this.path,
      isLoggedIn: isLoggedIn ?? this.isLoggedIn,
      preAuth: preAuth ?? this.preAuth,
      queryParameters: queryParameters ?? this.queryParameters,
    );
  }

  @override
  String toString() {
    return 'PathForwarding(path: $path, isForwarding: $isLoggedIn), queryParameters: $queryParameters';
  }

  PathForwarding.empty() : this(path: '/', isLoggedIn: false);
}
