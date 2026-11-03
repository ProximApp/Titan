class FirebaseTokenExpiration {
  late final String userId;
  late final DateTime? expiration;

  FirebaseTokenExpiration(this.userId, this.expiration);

  FirebaseTokenExpiration.fromJson(Map<String, dynamic> json) {
    userId = json['token'];
    final rawExpiration = json['expiration'];
    expiration = rawExpiration == null
        ? null
        : DateTime.tryParse(rawExpiration.toString());
  }

  Map<String, dynamic> toJson() => {
    'token': userId,
    'expiration': expiration?.toString(),
  };

  FirebaseTokenExpiration.empty() {
    userId = '';
    expiration = null;
  }

  FirebaseTokenExpiration copyWith({String? userId, DateTime? expiration}) {
    return FirebaseTokenExpiration(
      userId ?? this.userId,
      expiration ?? this.expiration,
    );
  }
}
