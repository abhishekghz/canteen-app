/// A configurable snack time (e.g. Morning 11:00, Evening 16:30).
class SnackSlot {
  final String id;
  final String label;
  final String time; // "HH:mm"

  const SnackSlot({required this.id, required this.label, required this.time});

  SnackSlot copyWith({String? label, String? time}) => SnackSlot(
        id: id,
        label: label ?? this.label,
        time: time ?? this.time,
      );

  Map<String, dynamic> toMap() => {'id': id, 'label': label, 'time': time};

  factory SnackSlot.fromMap(Map<String, dynamic> m) => SnackSlot(
        id: m['id'] as String,
        label: m['label'] as String,
        time: m['time'] as String,
      );
}
