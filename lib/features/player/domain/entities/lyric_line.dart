class LyricLine {
  const LyricLine({required this.timestamp, required this.text});

  factory LyricLine.fromJson(Map<String, dynamic> json) {
    return LyricLine(
      timestamp: Duration(
        milliseconds: (json['timestampMs'] as num?)?.toInt() ?? 0,
      ),
      text: (json['text'] ?? '').toString(),
    );
  }

  final Duration timestamp;
  final String text;

  Map<String, dynamic> toJson() {
    return {'timestampMs': timestamp.inMilliseconds, 'text': text};
  }
}
