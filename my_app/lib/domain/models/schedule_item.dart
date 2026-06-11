class ScheduleItem {
  final String id;
  final int dayOfWeek; // 1=Mon … 7=Sun  (matches DateTime.weekday)
  final String time;   // "08:00"
  final String endTime; // "09:00" (empty if not set)
  final String subject;

  const ScheduleItem({
    required this.id,
    required this.dayOfWeek,
    required this.time,
    this.endTime = '',
    required this.subject,
  });

  factory ScheduleItem.fromJson(Map<String, dynamic> json) => ScheduleItem(
        id: json['id'] as String,
        dayOfWeek: json['day_of_week'] as int,
        time: json['time'] as String,
        endTime: (json['end_time'] as String?) ?? '',
        subject: json['subject'] as String,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'day_of_week': dayOfWeek,
        'time': time,
        'end_time': endTime,
        'subject': subject,
      };

  static const dayNames = <int, String>{
    1: 'الاثنين',
    2: 'الثلاثاء',
    3: 'الأربعاء',
    4: 'الخميس',
    5: 'الجمعة',
    6: 'السبت',
    7: 'الأحد',
  };

  String get dayName => dayNames[dayOfWeek] ?? '';
}
