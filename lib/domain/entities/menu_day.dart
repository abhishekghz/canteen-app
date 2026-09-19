/// Meal types offered by the canteen.
enum MealType { breakfast, lunch, dinner }

extension MealTypeX on MealType {
  String get label => switch (this) {
        MealType.breakfast => 'Breakfast',
        MealType.lunch => 'Lunch',
        MealType.dinner => 'Dinner',
      };
}

/// The seven weekdays, keyed lowercase (mon..sun).
const kWeekdays = ['mon', 'tue', 'wed', 'thu', 'fri', 'sat', 'sun'];

String weekdayLabel(String key) => switch (key) {
      'mon' => 'Monday',
      'tue' => 'Tuesday',
      'wed' => 'Wednesday',
      'thu' => 'Thursday',
      'fri' => 'Friday',
      'sat' => 'Saturday',
      'sun' => 'Sunday',
      _ => key,
    };

/// One day's worth of menu items per meal.
class MenuDay {
  final String weekday; // mon..sun
  final List<String> breakfast;
  final List<String> lunch;
  final List<String> dinner;

  const MenuDay({
    required this.weekday,
    required this.breakfast,
    required this.lunch,
    required this.dinner,
  });

  List<String> itemsFor(MealType type) => switch (type) {
        MealType.breakfast => breakfast,
        MealType.lunch => lunch,
        MealType.dinner => dinner,
      };

  MenuDay copyWith({
    List<String>? breakfast,
    List<String>? lunch,
    List<String>? dinner,
  }) =>
      MenuDay(
        weekday: weekday,
        breakfast: breakfast ?? this.breakfast,
        lunch: lunch ?? this.lunch,
        dinner: dinner ?? this.dinner,
      );

  Map<String, dynamic> toMap() => {
        'weekday': weekday,
        'breakfast': breakfast,
        'lunch': lunch,
        'dinner': dinner,
      };

  factory MenuDay.fromMap(Map<String, dynamic> m) => MenuDay(
        weekday: m['weekday'] as String,
        breakfast: List<String>.from(m['breakfast'] as List? ?? const []),
        lunch: List<String>.from(m['lunch'] as List? ?? const []),
        dinner: List<String>.from(m['dinner'] as List? ?? const []),
      );
}
