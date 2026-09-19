import '../../domain/entities/app_user.dart';
import '../../domain/entities/menu_day.dart';
import '../../domain/entities/snack_slot.dart';

/// Default admin credentials (seeded). Change before production.
const kSeedAdminEmail = 'admin@canteen.app';
const kSeedAdminPassword = 'admin123';

/// A seeded demo student, handy for trying the app immediately.
const kSeedStudentEmail = 'student@canteen.app';
const kSeedStudentPassword = 'student123';

typedef SeedAccount = ({String password, AppUser user});

List<SeedAccount> seedAccounts() => [
      (
        password: kSeedAdminPassword,
        user: const AppUser(
          uid: 'admin-seed',
          name: 'Canteen Admin',
          email: kSeedAdminEmail,
          role: UserRole.admin,
        ),
      ),
      (
        password: kSeedStudentPassword,
        user: const AppUser(
          uid: 'student-seed',
          name: 'Demo Student',
          email: kSeedStudentEmail,
          role: UserRole.student,
        ),
      ),
    ];

List<SnackSlot> seedSnackSlots() => const [
      SnackSlot(id: 'morning', label: 'Morning Snacks', time: '11:00'),
      SnackSlot(id: 'evening', label: 'Evening Snacks', time: '16:30'),
    ];

List<MenuDay> seedWeek() => const [
      MenuDay(
        weekday: 'mon',
        breakfast: ['Poha', 'Tea'],
        lunch: ['Roti', 'Dal', 'Aloo Sabji', 'Rice'],
        dinner: ['Roti', 'Paneer', 'Rice'],
      ),
      MenuDay(
        weekday: 'tue',
        breakfast: ['Idli', 'Sambar'],
        lunch: ['Roti', 'Rajma', 'Rice', 'Salad'],
        dinner: ['Roti', 'Mix Veg', 'Rice'],
      ),
      MenuDay(
        weekday: 'wed',
        breakfast: ['Paratha', 'Curd'],
        lunch: ['Roti', 'Chole', 'Rice', 'Papad'],
        dinner: ['Roti', 'Bhindi', 'Dal', 'Rice'],
      ),
      MenuDay(
        weekday: 'thu',
        breakfast: ['Upma', 'Coffee'],
        lunch: ['Roti', 'Kadhi', 'Rice', 'Salad'],
        dinner: ['Roti', 'Aloo Gobi', 'Rice'],
      ),
      MenuDay(
        weekday: 'fri',
        breakfast: ['Dosa', 'Chutney'],
        lunch: ['Roti', 'Dal Fry', 'Jeera Rice'],
        dinner: ['Roti', 'Matar Paneer', 'Rice'],
      ),
      MenuDay(
        weekday: 'sat',
        breakfast: ['Aloo Puri'],
        lunch: ['Veg Biryani', 'Raita'],
        dinner: ['Roti', 'Egg Curry / Soya', 'Rice'],
      ),
      MenuDay(
        weekday: 'sun',
        breakfast: ['Chole Bhature'],
        lunch: ['Special Thali'],
        dinner: ['Fried Rice', 'Manchurian'],
      ),
    ];
