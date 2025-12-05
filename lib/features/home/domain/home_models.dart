class HomeData {
  final String message;
  final DateTime timestamp;

  HomeData({required this.message, required this.timestamp});

  Map<String, dynamic> toJson() => {
    'message': message,
    'timestamp': timestamp.toIso8601String(),
  };

  factory HomeData.fromJson(Map<String, dynamic> json) => HomeData(
    message: json['message'] as String,
    timestamp: DateTime.parse(json['timestamp'] as String),
  );
}
