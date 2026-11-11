import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ───────────────────────── Strings (fa / en) ─────────────────────────

const Map<String, Map<String, String>> _t = {
  'fa': {
    'exams': 'آزمون‌ها',
    'progress': 'پیشرفت',
    'settings': 'تنظیمات',
    'add_exam': 'ثبت آزمون جدید',
    'edit_exam': 'ویرایش آزمون',
    'subject': 'درس',
    'total_q': 'تعداد کل سوال‌ها',
    'correct': 'درست',
    'wrong': 'غلط',
    'blank': 'نزده',
    'penalty': 'نمره منفی',
    'penalty_none': 'بدون منفی',
    'penalty_third': 'منفی ۱/۳',
    'penalty_quarter': 'منفی ۱/۴',
    'penalty_hint': 'با منفی ۱/۳ هر ۳ غلط، یک درست رو از بین می‌بره.',
    'result': 'درصد تو',
    'bad_count': 'مجموع درست و غلط از کل سوال‌ها بیشتره',
    'default_penalty': 'نمره منفی پیش‌فرض',
    'date': 'تاریخ',
    'note': 'یادداشت (اختیاری)',
    'save': 'ذخیره',
    'empty': 'هنوز آزمونی ثبت نکرده‌ای.\nبا دکمه‌ی پایین اولین آزمون رو اضافه کن.',
    'count': 'تعداد آزمون',
    'average': 'میانگین',
    'overall': 'میانگین کل',
    'best': 'بهترین',
    'last': 'آخرین',
    'all': 'همه',
    'language': 'زبان',
    'theme': 'تم برنامه',
    'delete_all': 'حذف همه اطلاعات',
    'delete_all_q': 'همه آزمون‌های ثبت‌شده پاک می‌شن. مطمئنی؟',
    'cancel': 'انصراف',
    'delete': 'حذف',
    'deleted': 'آزمون حذف شد',
    'undo': 'بازگردانی',
    'required': 'این فیلد لازمه',
    'invalid': 'عدد معتبر وارد کن',
    'no_data': 'برای نمایش نمودار حداقل یک آزمون لازمه.',
    'about': 'همه اطلاعات فقط روی همین گوشی ذخیره می‌شه.',
    'change': 'تغییر نسبت به آزمون قبل',
  },
  'en': {
    'exams': 'Exams',
    'progress': 'Progress',
    'settings': 'Settings',
    'add_exam': 'Add new exam',
    'edit_exam': 'Edit exam',
    'subject': 'Subject',
    'total_q': 'Total questions',
    'correct': 'Correct',
    'wrong': 'Wrong',
    'blank': 'Blank',
    'penalty': 'Negative marking',
    'penalty_none': 'None',
    'penalty_third': 'Negative 1/3',
    'penalty_quarter': 'Negative 1/4',
    'penalty_hint':
        'Each wrong answer removes a fraction of one correct answer (1/3 means 3 wrong cancel 1 correct).',
    'result': 'Your percentage',
    'bad_count': 'Correct + wrong is more than total questions',
    'default_penalty': 'Default negative marking',
    'date': 'Date',
    'note': 'Note (optional)',
    'save': 'Save',
    'empty': 'No exams yet.\nTap the button below to add your first one.',
    'count': 'Exams',
    'average': 'Average',
    'overall': 'Overall average',
    'best': 'Best',
    'last': 'Latest',
    'all': 'All',
    'language': 'Language',
    'theme': 'App theme',
    'delete_all': 'Delete all data',
    'delete_all_q': 'All saved exams will be erased. Are you sure?',
    'cancel': 'Cancel',
    'delete': 'Delete',
    'deleted': 'Exam deleted',
    'undo': 'Undo',
    'required': 'This field is required',
    'invalid': 'Enter a valid number',
    'no_data': 'Add at least one exam to see the chart.',
    'about': 'All data is stored only on this phone.',
    'change': 'Change vs previous exam',
  },
};

String t(BuildContext c, String key) =>
    _t[StoreScope.of(c).lang]![key] ?? key;

const String _faDigits = '۰۱۲۳۴۵۶۷۸۹';
const String _arDigits = '٠١٢٣٤٥٦٧٨٩';

String toFaDigits(String s) {
  final b = StringBuffer();
  for (final ch in s.split('')) {
    final i = '0123456789'.indexOf(ch);
    b.write(i < 0 ? ch : _faDigits[i]);
  }
  return b.toString();
}

/// Converts digits to Persian when the app language is Persian.
String nd(BuildContext c, String s) =>
    StoreScope.of(c).lang == 'fa' ? toFaDigits(s) : s;

double? parseNum(String s) {
  var r = s.trim();
  for (var i = 0; i < 10; i++) {
    r = r.replaceAll(_faDigits[i], '$i').replaceAll(_arDigits[i], '$i');
  }
  r = r.replaceAll('٫', '.').replaceAll(',', '.').replaceAll('،', '.');
  return double.tryParse(r);
}

String fmtNum(double v) {
  if (v == v.roundToDouble()) return v.toInt().toString();
  var s = v.toStringAsFixed(2);
  s = s.replaceFirst(RegExp(r'0+$'), '');
  return s;
}

const double kThird = 1 / 3;

String fmtPct(double p) => '${fmtNum((p * 10).round() / 10)}%';

String two(int n) => n.toString().padLeft(2, '0');
String fmtDate(DateTime d) => '${d.year}/${two(d.month)}/${two(d.day)}';
String fmtShort(DateTime d) => '${two(d.month)}/${two(d.day)}';

// ───────────────────────── Themes ─────────────────────────

class AppPalette {
  final String id;
  final String faName;
  final String enName;
  final bool dark;
  final Color bg;
  final Color surface;
  final Color primary;
  final Color secondary;
  final Color onPrimary;
  final Color text;
  final Color muted;
  final Color line;
  final Color swatchA;
  final Color swatchB;

  const AppPalette({
    required this.id,
    required this.faName,
    required this.enName,
    required this.dark,
    required this.bg,
    required this.surface,
    required this.primary,
    required this.secondary,
    required this.onPrimary,
    required this.text,
    required this.muted,
    required this.line,
    required this.swatchA,
    required this.swatchB,
  });

  String name(String lang) => lang == 'fa' ? faName : enName;
}

const Color _darkText = Color(0xFFF3F4F6);
const Color _darkMuted = Color(0xFF9CA3AF);
const Color _darkLine = Color(0x1FFFFFFF);
const Color _lightText = Color(0xFF111827);
const Color _lightMuted = Color(0xFF6B7280);
const Color _lightLine = Color(0x1A000000);

const List<AppPalette> kPalettes = [
  AppPalette(
    id: 'blue_red',
    faName: 'آبی-قرمز',
    enName: 'Blue-Red',
    dark: true,
    bg: Color(0xFF0B1220),
    surface: Color(0xFF131D33),
    primary: Color(0xFF3D8BFF),
    secondary: Color(0xFFFF4D5E),
    onPrimary: Colors.white,
    text: _darkText,
    muted: _darkMuted,
    line: _darkLine,
    swatchA: Color(0xFF3D8BFF),
    swatchB: Color(0xFFFF4D5E),
  ),
  AppPalette(
    id: 'black_red',
    faName: 'مشکی-قرمز',
    enName: 'Black-Red',
    dark: true,
    bg: Color(0xFF000000),
    surface: Color(0xFF151515),
    primary: Color(0xFFFF2D3F),
    secondary: Color(0xFFB3001B),
    onPrimary: Colors.white,
    text: _darkText,
    muted: _darkMuted,
    line: _darkLine,
    swatchA: Color(0xFF000000),
    swatchB: Color(0xFFFF2D3F),
  ),
  AppPalette(
    id: 'black_blue',
    faName: 'مشکی-آبی',
    enName: 'Black-Blue',
    dark: true,
    bg: Color(0xFF000000),
    surface: Color(0xFF121418),
    primary: Color(0xFF2F8CFF),
    secondary: Color(0xFF0A4FD6),
    onPrimary: Colors.white,
    text: _darkText,
    muted: _darkMuted,
    line: _darkLine,
    swatchA: Color(0xFF000000),
    swatchB: Color(0xFF2F8CFF),
  ),
  AppPalette(
    id: 'white_red',
    faName: 'سفید-قرمز',
    enName: 'White-Red',
    dark: false,
    bg: Color(0xFFF6F6F8),
    surface: Color(0xFFFFFFFF),
    primary: Color(0xFFE63946),
    secondary: Color(0xFFFF7A59),
    onPrimary: Colors.white,
    text: _lightText,
    muted: _lightMuted,
    line: _lightLine,
    swatchA: Color(0xFFFFFFFF),
    swatchB: Color(0xFFE63946),
  ),
  AppPalette(
    id: 'black_white',
    faName: 'سیاه-سفید',
    enName: 'Black-White',
    dark: true,
    bg: Color(0xFF000000),
    surface: Color(0xFF161616),
    primary: Color(0xFFFFFFFF),
    secondary: Color(0xFF9E9E9E),
    onPrimary: Color(0xFF000000),
    text: _darkText,
    muted: _darkMuted,
    line: _darkLine,
    swatchA: Color(0xFF000000),
    swatchB: Color(0xFFFFFFFF),
  ),
];

ThemeData buildTheme(AppPalette p) {
  final base = ColorScheme.fromSeed(
    seedColor: p.primary,
    brightness: p.dark ? Brightness.dark : Brightness.light,
  );
  final scheme = base.copyWith(
    primary: p.primary,
    onPrimary: p.onPrimary,
    secondary: p.secondary,
    surface: p.surface,
    onSurface: p.text,
    outline: p.muted,
    outlineVariant: p.line,
  );
  return ThemeData(
    useMaterial3: true,
    brightness: p.dark ? Brightness.dark : Brightness.light,
    colorScheme: scheme,
    scaffoldBackgroundColor: p.bg,
    canvasColor: p.bg,
  );
}

Color percentColor(double p) {
  if (p >= 70) return const Color(0xFF22C55E);
  if (p >= 50) return const Color(0xFFF59E0B);
  return const Color(0xFFEF4444);
}

// ───────────────────────── Model ─────────────────────────

class Exam {
  final String id;
  final String subject;
  final int total;
  final int correct;
  final int wrong;
  final double penalty;
  final DateTime date;
  final String note;

  Exam({
    required this.id,
    required this.subject,
    required this.total,
    required this.correct,
    required this.wrong,
    required this.penalty,
    required this.date,
    this.note = '',
  });

  int get blank => total - correct - wrong;

  double get percent =>
      total <= 0 ? 0 : (correct - wrong * penalty) / total * 100;

  Map<String, dynamic> toJson() => {
        'id': id,
        'subject': subject,
        'total': total,
        'correct': correct,
        'wrong': wrong,
        'penalty': penalty,
        'date': date.toIso8601String(),
        'note': note,
      };

  factory Exam.fromJson(Map<String, dynamic> j) => Exam(
        id: j['id'] as String,
        subject: j['subject'] as String,
        total: (j['total'] as num).toInt(),
        correct: (j['correct'] as num).toInt(),
        wrong: (j['wrong'] as num).toInt(),
        penalty: (j['penalty'] as num).toDouble(),
        date: DateTime.parse(j['date'] as String),
        note: (j['note'] as String?) ?? '',
      );
}

// ───────────────────────── Store ─────────────────────────

class Store extends ChangeNotifier {
  final SharedPreferences prefs;
  List<Exam> exams = [];
  String lang;
  String themeId;
  double penalty;

  Store(this.prefs)
      : lang = prefs.getString('lang') ?? 'fa',
        themeId = prefs.getString('theme') ?? 'blue_red',
        penalty = prefs.getDouble('penalty') ?? kThird {
    final raw = prefs.getString('exams');
    if (raw != null) {
      try {
        exams = (jsonDecode(raw) as List)
            .map((e) => Exam.fromJson(e as Map<String, dynamic>))
            .toList();
      } catch (_) {
        exams = [];
      }
    }
    _sort();
  }

  static Future<Store> load() async =>
      Store(await SharedPreferences.getInstance());

  AppPalette get palette => kPalettes.firstWhere(
        (p) => p.id == themeId,
        orElse: () => kPalettes.first,
      );

  void _sort() => exams.sort((a, b) => a.date.compareTo(b.date));

  Future<void> _save() async {
    await prefs.setString(
        'exams', jsonEncode(exams.map((e) => e.toJson()).toList()));
  }

  List<String> get subjects {
    final set = <String>{};
    for (final e in exams) {
      set.add(e.subject);
    }
    return set.toList()..sort();
  }

  void addOrUpdate(Exam e) {
    final i = exams.indexWhere((x) => x.id == e.id);
    if (i >= 0) {
      exams[i] = e;
    } else {
      exams.add(e);
    }
    _sort();
    _save();
    notifyListeners();
  }

  void remove(String id) {
    exams.removeWhere((e) => e.id == id);
    _save();
    notifyListeners();
  }

  void clearAll() {
    exams = [];
    _save();
    notifyListeners();
  }

  void setLang(String l) {
    lang = l;
    prefs.setString('lang', l);
    notifyListeners();
  }

  void setTheme(String id) {
    themeId = id;
    prefs.setString('theme', id);
    notifyListeners();
  }

  void setPenalty(double v) {
    penalty = v;
    prefs.setDouble('penalty', v);
    notifyListeners();
  }
}

class StoreScope extends InheritedNotifier<Store> {
  const StoreScope({super.key, required Store store, required super.child})
      : super(notifier: store);

  static Store of(BuildContext c) =>
      c.dependOnInheritedWidgetOfExactType<StoreScope>()!.notifier!;
}

// ───────────────────────── App ─────────────────────────

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final store = await Store.load();
  runApp(TestinoApp(store: store));
}

class TestinoApp extends StatelessWidget {
  final Store store;
  const TestinoApp({super.key, required this.store});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: store,
      builder: (context, _) {
        final p = store.palette;
        return StoreScope(
          store: store,
          child: MaterialApp(
            debugShowCheckedModeBanner: false,
            title: 'Testino',
            locale: Locale(store.lang),
            supportedLocales: const [Locale('fa'), Locale('en')],
            localizationsDelegates: const [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            theme: buildTheme(p),
            home: const HomePage(),
          ),
        );
      },
    );
  }
}

// ───────────────────────── Shared widgets ─────────────────────────

PreferredSizeWidget appBar(BuildContext context, String title) {
  final p = StoreScope.of(context).palette;
  return AppBar(
    title: Text(
      title,
      style: TextStyle(
          fontWeight: FontWeight.w800, fontSize: 24, color: p.text),
    ),
    centerTitle: false,
    backgroundColor: p.bg,
    foregroundColor: p.text,
    surfaceTintColor: Colors.transparent,
    elevation: 0,
    scrolledUnderElevation: 0,
    systemOverlayStyle:
        p.dark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
  );
}

class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;

  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final p = StoreScope.of(context).palette;
    final radius = BorderRadius.circular(22);
    return Material(
      color: p.surface,
      borderRadius: radius,
      child: InkWell(
        borderRadius: radius,
        onTap: onTap,
        child: Container(
          width: double.infinity,
          padding: padding,
          decoration: BoxDecoration(
            borderRadius: radius,
            border: Border.all(color: p.line),
          ),
          child: child,
        ),
      ),
    );
  }
}

class GradientCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  const GradientCard(
      {super.key, required this.child, this.padding = const EdgeInsets.all(20)});

  @override
  Widget build(BuildContext context) {
    final p = StoreScope.of(context).palette;
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: AlignmentDirectional.topStart,
          end: AlignmentDirectional.bottomEnd,
          colors: [p.primary, p.secondary],
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: p.primary.withAlpha(70),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: child,
    );
  }
}

class StatBox extends StatelessWidget {
  final String label;
  final String value;
  const StatBox({super.key, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final p = StoreScope.of(context).palette;
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: AppCard(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
          child: Column(
            children: [
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(value,
                    style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: p.text)),
              ),
              const SizedBox(height: 4),
              Text(label, style: TextStyle(fontSize: 12, color: p.muted)),
            ],
          ),
        ),
      ),
    );
  }
}

Widget appChip(
    BuildContext context, String label, bool selected, VoidCallback onTap) {
  final p = StoreScope.of(context).palette;
  return ChoiceChip(
    label: Text(label),
    selected: selected,
    onSelected: (_) => onTap(),
    showCheckmark: false,
    selectedColor: p.primary,
    backgroundColor: p.surface,
    labelStyle: TextStyle(
      color: selected ? p.onPrimary : p.text,
      fontWeight: FontWeight.w600,
    ),
    side: BorderSide(color: selected ? p.primary : p.line),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
  );
}

InputDecoration fieldDeco(BuildContext context, String label) {
  final p = StoreScope.of(context).palette;
  OutlineInputBorder b(Color c, [double w = 1]) => OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: c, width: w),
      );
  const red = Color(0xFFEF4444);
  return InputDecoration(
    labelText: label,
    labelStyle: TextStyle(color: p.muted),
    filled: true,
    fillColor: p.surface,
    border: b(p.line),
    enabledBorder: b(p.line),
    focusedBorder: b(p.primary, 1.8),
    errorBorder: b(red),
    focusedErrorBorder: b(red, 1.8),
  );
}

double averagePercent(List<Exam> list) {
  if (list.isEmpty) return 0;
  var sum = 0.0;
  for (final e in list) {
    sum += e.percent;
  }
  return sum / list.length;
}

// ───────────────────────── Home ─────────────────────────

class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final p = StoreScope.of(context).palette;
    final titles = [
      t(context, 'exams'),
      t(context, 'progress'),
      t(context, 'settings'),
    ];
    final pages = <Widget>[
      const ExamsTab(),
      const ProgressTab(),
      const SettingsTab(),
    ];
    return Scaffold(
      appBar: appBar(context, titles[_index]),
      body: SafeArea(child: pages[_index]),
      floatingActionButton: _index == 0
          ? FloatingActionButton.extended(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ExamFormPage()),
              ),
              backgroundColor: p.primary,
              foregroundColor: p.onPrimary,
              elevation: 2,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18)),
              icon: const Icon(Icons.add_rounded),
              label: Text(t(context, 'add_exam'),
                  style: const TextStyle(fontWeight: FontWeight.w700)),
            )
          : null,
      bottomNavigationBar: NavigationBar(
        height: 70,
        backgroundColor: p.surface,
        surfaceTintColor: Colors.transparent,
        indicatorColor: p.primary.withAlpha(45),
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: [
          NavigationDestination(
              icon: Icon(Icons.assignment_outlined, color: p.muted),
              selectedIcon: Icon(Icons.assignment, color: p.primary),
              label: titles[0]),
          NavigationDestination(
              icon: Icon(Icons.show_chart_rounded, color: p.muted),
              selectedIcon: Icon(Icons.show_chart_rounded, color: p.primary),
              label: titles[1]),
          NavigationDestination(
              icon: Icon(Icons.tune_rounded, color: p.muted),
              selectedIcon: Icon(Icons.tune_rounded, color: p.primary),
              label: titles[2]),
        ],
      ),
    );
  }
}

// ───────────────────────── Exams tab ─────────────────────────

class ExamsTab extends StatelessWidget {
  const ExamsTab({super.key});

  Widget _mini(BuildContext context, String label, String value) {
    final p = StoreScope.of(context).palette;
    return Expanded(
      child: Column(
        children: [
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(value,
                style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: p.onPrimary)),
          ),
          const SizedBox(height: 2),
          Text(label,
              style: TextStyle(
                  fontSize: 12, color: p.onPrimary.withAlpha(200))),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = StoreScope.of(context);
    final p = s.palette;
    if (s.exams.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  color: p.primary.withAlpha(35),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.edit_note_rounded,
                    size: 52, color: p.primary),
              ),
              const SizedBox(height: 20),
              Text(t(context, 'empty'),
                  textAlign: TextAlign.center,
                  style: TextStyle(color: p.muted, height: 1.6)),
            ],
          ),
        ),
      );
    }
    final list = s.exams.reversed.toList();
    final best = list.map((e) => e.percent).reduce((a, b) => a > b ? a : b);
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 100),
      children: [
        GradientCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(t(context, 'overall'),
                  style: TextStyle(
                      fontSize: 14, color: p.onPrimary.withAlpha(210))),
              const SizedBox(height: 4),
              Text(
                nd(context, fmtPct(averagePercent(list))),
                style: TextStyle(
                    fontSize: 46,
                    fontWeight: FontWeight.w900,
                    color: p.onPrimary),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  _mini(context, t(context, 'count'),
                      nd(context, '${list.length}')),
                  _mini(context, t(context, 'best'),
                      nd(context, fmtPct(best))),
                  _mini(context, t(context, 'last'),
                      nd(context, fmtPct(list.first.percent))),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        ...list.map((e) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: ExamTile(exam: e),
            )),
      ],
    );
  }
}

class PercentRing extends StatelessWidget {
  final double percent;
  final String text;
  final Color color;
  const PercentRing(
      {super.key,
      required this.percent,
      required this.text,
      required this.color});

  @override
  Widget build(BuildContext context) {
    final p = StoreScope.of(context).palette;
    final v = (percent / 100).clamp(0.0, 1.0).toDouble();
    return SizedBox(
      width: 60,
      height: 60,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: 60,
            height: 60,
            child: CircularProgressIndicator(
              value: v,
              strokeWidth: 6,
              color: color,
              backgroundColor: p.line,
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(10),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(text,
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: p.text)),
            ),
          ),
        ],
      ),
    );
  }
}

Widget pill(String text, Color color) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
      decoration: BoxDecoration(
        color: color.withAlpha(36),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(text,
          style: TextStyle(
              color: color, fontSize: 12, fontWeight: FontWeight.w700)),
    );

class ExamTile extends StatelessWidget {
  final Exam exam;
  const ExamTile({super.key, required this.exam});

  @override
  Widget build(BuildContext context) {
    final s = StoreScope.of(context);
    final p = s.palette;
    final color = percentColor(exam.percent);
    final sub = [
      nd(context, fmtDate(exam.date)),
      if (exam.note.isNotEmpty) exam.note,
    ].join('  •  ');

    Widget swipeBg(AlignmentGeometry a) => Container(
          decoration: BoxDecoration(
            color: const Color(0xFFEF4444),
            borderRadius: BorderRadius.circular(22),
          ),
          alignment: a,
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: const Icon(Icons.delete_rounded, color: Colors.white),
        );

    return Dismissible(
      key: ValueKey(exam.id),
      direction: DismissDirection.horizontal,
      background: swipeBg(AlignmentDirectional.centerStart),
      secondaryBackground: swipeBg(AlignmentDirectional.centerEnd),
      onDismissed: (_) {
        final m = ScaffoldMessenger.of(context);
        final msg = t(context, 'deleted');
        final undo = t(context, 'undo');
        s.remove(exam.id);
        m.clearSnackBars();
        m.showSnackBar(SnackBar(
          content: Text(msg),
          action: SnackBarAction(
            label: undo,
            onPressed: () => s.addOrUpdate(exam),
          ),
        ));
      },
      child: AppCard(
        padding: const EdgeInsets.all(14),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => ExamFormPage(exam: exam)),
        ),
        child: Row(
          children: [
            PercentRing(
              percent: exam.percent,
              text: nd(context, fmtPct(exam.percent)),
              color: color,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    exam.subject,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: p.text),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      pill(
                          nd(context,
                              '${t(context, 'correct')} ${exam.correct}'),
                          const Color(0xFF22C55E)),
                      pill(
                          nd(context,
                              '${t(context, 'wrong')} ${exam.wrong}'),
                          const Color(0xFFEF4444)),
                      pill(
                          nd(context,
                              '${t(context, 'blank')} ${exam.blank}'),
                          p.muted),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(sub,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 12, color: p.muted)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ───────────────────────── Add / edit form ─────────────────────────

class PenaltyChips extends StatelessWidget {
  final double value;
  final ValueChanged<double> onChanged;
  const PenaltyChips({super.key, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final opts = <MapEntry<String, double>>[
      const MapEntry('penalty_none', 0.0),
      const MapEntry('penalty_third', kThird),
      const MapEntry('penalty_quarter', 0.25),
    ];
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: opts
          .map((o) => appChip(
                context,
                t(context, o.key),
                (value - o.value).abs() < 1e-9,
                () => onChanged(o.value),
              ))
          .toList(),
    );
  }
}

class ExamFormPage extends StatefulWidget {
  final Exam? exam;
  const ExamFormPage({super.key, this.exam});
  @override
  State<ExamFormPage> createState() => _ExamFormPageState();
}

class _ExamFormPageState extends State<ExamFormPage> {
  final _form = GlobalKey<FormState>();
  late final TextEditingController _subject;
  late final TextEditingController _total;
  late final TextEditingController _correct;
  late final TextEditingController _wrong;
  late final TextEditingController _note;
  late DateTime _date;
  double? _penalty;

  @override
  void initState() {
    super.initState();
    final e = widget.exam;
    _subject = TextEditingController(text: e?.subject ?? '');
    _total = TextEditingController(text: e == null ? '' : '${e.total}');
    _correct = TextEditingController(text: e == null ? '' : '${e.correct}');
    _wrong = TextEditingController(text: e == null ? '' : '${e.wrong}');
    _note = TextEditingController(text: e?.note ?? '');
    _date = e?.date ?? DateTime.now();
  }

  @override
  void dispose() {
    _subject.dispose();
    _total.dispose();
    _correct.dispose();
    _wrong.dispose();
    _note.dispose();
    super.dispose();
  }

  int? _int(TextEditingController c, {bool emptyZero = false}) {
    if (c.text.trim().isEmpty) return emptyZero ? 0 : null;
    final n = parseNum(c.text);
    if (n == null || n < 0 || n != n.roundToDouble()) return null;
    return n.toInt();
  }

  Future<void> _pickDate() async {
    final d = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (d != null) setState(() => _date = d);
  }

  void _save(double penalty) {
    if (!_form.currentState!.validate()) return;
    final s = StoreScope.of(context);
    s.addOrUpdate(Exam(
      id: widget.exam?.id ?? DateTime.now().microsecondsSinceEpoch.toString(),
      subject: _subject.text.trim(),
      total: _int(_total)!,
      correct: _int(_correct, emptyZero: true)!,
      wrong: _int(_wrong, emptyZero: true)!,
      penalty: penalty,
      date: _date,
      note: _note.text.trim(),
    ));
    Navigator.pop(context);
  }

  String? _countCheck() {
    final total = _int(_total);
    final c = _int(_correct, emptyZero: true);
    final w = _int(_wrong, emptyZero: true);
    if (c == null || w == null) return t(context, 'invalid');
    if (total != null && c + w > total) return t(context, 'bad_count');
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final s = StoreScope.of(context);
    final p = s.palette;
    final subjects = s.subjects;
    final pen = _penalty ?? widget.exam?.penalty ?? s.penalty;
    const numKb = TextInputType.number;

    final total = _int(_total) ?? 0;
    final c = _int(_correct, emptyZero: true) ?? 0;
    final w = _int(_wrong, emptyZero: true) ?? 0;
    final valid = total > 0 && c + w <= total;
    final pct = valid ? (c - w * pen) / total * 100 : 0.0;

    return Scaffold(
      appBar: appBar(
          context, t(context, widget.exam == null ? 'add_exam' : 'edit_exam')),
      body: SafeArea(
        child: Form(
          key: _form,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            children: [
              if (valid) ...[
                GradientCard(
                  child: Column(
                    children: [
                      Text(t(context, 'result'),
                          style: TextStyle(
                              color: p.onPrimary.withAlpha(210),
                              fontSize: 14)),
                      const SizedBox(height: 4),
                      Text(
                        nd(context, fmtPct(pct)),
                        style: TextStyle(
                          fontSize: 48,
                          fontWeight: FontWeight.w900,
                          color: p.onPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        nd(context,
                            '${t(context, 'correct')} $c   •   ${t(context, 'wrong')} $w   •   ${t(context, 'blank')} ${total - c - w}'),
                        style: TextStyle(
                            color: p.onPrimary.withAlpha(220), fontSize: 13),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],
              TextFormField(
                controller: _subject,
                decoration: fieldDeco(context, t(context, 'subject')),
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? t(context, 'required')
                    : null,
              ),
              if (subjects.isNotEmpty) ...[
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: subjects
                      .map((x) => ActionChip(
                            label: Text(x),
                            backgroundColor: p.surface,
                            side: BorderSide(color: p.line),
                            labelStyle: TextStyle(color: p.text),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14)),
                            onPressed: () =>
                                setState(() => _subject.text = x),
                          ))
                      .toList(),
                ),
              ],
              const SizedBox(height: 16),
              TextFormField(
                controller: _total,
                keyboardType: numKb,
                onChanged: (_) => setState(() {}),
                decoration: fieldDeco(context, t(context, 'total_q')),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) {
                    return t(context, 'required');
                  }
                  final n = _int(_total);
                  if (n == null || n <= 0) return t(context, 'invalid');
                  return null;
                },
              ),
              const SizedBox(height: 16),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _correct,
                      keyboardType: numKb,
                      onChanged: (_) => setState(() {}),
                      decoration: fieldDeco(context, t(context, 'correct')),
                      validator: (_) => _countCheck(),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _wrong,
                      keyboardType: numKb,
                      onChanged: (_) => setState(() {}),
                      decoration: fieldDeco(context, t(context, 'wrong')),
                      validator: (_) => _countCheck(),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Text(t(context, 'penalty'),
                  style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                      color: p.text)),
              const SizedBox(height: 10),
              PenaltyChips(
                value: pen,
                onChanged: (v) => setState(() => _penalty = v),
              ),
              const SizedBox(height: 8),
              Text(t(context, 'penalty_hint'),
                  style: TextStyle(fontSize: 12, color: p.muted)),
              const SizedBox(height: 20),
              OutlinedButton.icon(
                onPressed: _pickDate,
                icon: const Icon(Icons.calendar_today_rounded, size: 18),
                label: Text(
                    '${t(context, 'date')}: ${nd(context, fmtDate(_date))}'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: p.text,
                  backgroundColor: p.surface,
                  side: BorderSide(color: p.line),
                  minimumSize: const Size.fromHeight(54),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _note,
                maxLines: 2,
                decoration: fieldDeco(context, t(context, 'note')),
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: () => _save(pen),
                icon: const Icon(Icons.check_rounded),
                label: Text(t(context, 'save'),
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w700)),
                style: FilledButton.styleFrom(
                  backgroundColor: p.primary,
                  foregroundColor: p.onPrimary,
                  minimumSize: const Size.fromHeight(56),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ───────────────────────── Progress tab ─────────────────────────

class ProgressTab extends StatefulWidget {
  const ProgressTab({super.key});
  @override
  State<ProgressTab> createState() => _ProgressTabState();
}

class _ProgressTabState extends State<ProgressTab> {
  String? _subject;

  @override
  Widget build(BuildContext context) {
    final s = StoreScope.of(context);
    final p = s.palette;
    final subjects = s.subjects;
    final sel = subjects.contains(_subject) ? _subject : null;
    final list =
        s.exams.where((e) => sel == null || e.subject == sel).toList();

    final chips = Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        appChip(context, t(context, 'all'), sel == null,
            () => setState(() => _subject = null)),
        ...subjects.map((x) => appChip(
            context, x, sel == x, () => setState(() => _subject = x))),
      ],
    );

    if (list.isEmpty) {
      return ListView(
        padding: const EdgeInsets.all(16),
        children: [
          chips,
          const SizedBox(height: 48),
          Center(
              child: Text(t(context, 'no_data'),
                  style: TextStyle(color: p.muted))),
        ],
      );
    }

    final values = list.map((e) => e.percent).toList();
    final labels = list.map((e) => nd(context, fmtShort(e.date))).toList();
    final best = values.reduce((a, b) => a > b ? a : b);
    final last = values.last;
    final fa = s.lang == 'fa';

    String? changeText;
    Color changeColor = p.muted;
    IconData changeIcon = Icons.trending_flat_rounded;
    if (values.length >= 2) {
      final d = values.last - values[values.length - 2];
      final sign = d > 0 ? '+' : '';
      changeText = nd(context, '$sign${d.toStringAsFixed(1)}%');
      if (d > 0) {
        changeColor = const Color(0xFF22C55E);
        changeIcon = Icons.trending_up_rounded;
      } else if (d < 0) {
        changeColor = const Color(0xFFEF4444);
        changeIcon = Icons.trending_down_rounded;
      }
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
      children: [
        chips,
        const SizedBox(height: 16),
        Row(
          children: [
            StatBox(
                label: t(context, 'average'),
                value: nd(context, fmtPct(averagePercent(list)))),
            StatBox(
                label: t(context, 'best'),
                value: nd(context, fmtPct(best))),
            StatBox(
                label: t(context, 'last'),
                value: nd(context, fmtPct(last))),
          ],
        ),
        const SizedBox(height: 12),
        AppCard(
          padding: const EdgeInsets.fromLTRB(8, 20, 14, 10),
          child: Directionality(
            textDirection: TextDirection.ltr,
            child: SizedBox(
              height: 270,
              width: double.infinity,
              child: CustomPaint(
                painter: LineChartPainter(
                  values: values,
                  labels: labels,
                  fa: fa,
                  line: p.primary,
                  accent: p.secondary,
                  grid: p.line,
                  text: p.muted,
                  ring: p.surface,
                ),
              ),
            ),
          ),
        ),
        if (changeText != null) ...[
          const SizedBox(height: 12),
          AppCard(
            child: Row(
              children: [
                Icon(changeIcon, color: changeColor),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(t(context, 'change'),
                      style: TextStyle(color: p.text)),
                ),
                Text(
                  changeText,
                  style: TextStyle(
                      color: changeColor,
                      fontWeight: FontWeight.w800,
                      fontSize: 18),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class LineChartPainter extends CustomPainter {
  final List<double> values;
  final List<String> labels;
  final bool fa;
  final Color line;
  final Color accent;
  final Color grid;
  final Color text;
  final Color ring;

  LineChartPainter({
    required this.values,
    required this.labels,
    required this.fa,
    required this.line,
    required this.accent,
    required this.grid,
    required this.text,
    required this.ring,
  });

  void _text(Canvas c, String s, Offset o, {bool center = false}) {
    final tp = TextPainter(
      text: TextSpan(text: s, style: TextStyle(color: text, fontSize: 11)),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(c, center ? Offset(o.dx - tp.width / 2, o.dy) : o);
  }

  @override
  void paint(Canvas canvas, Size size) {
    const left = 36.0, right = 8.0, top = 8.0, bottom = 26.0;
    final w = size.width - left - right;
    final h = size.height - top - bottom;

    final gridPaint = Paint()
      ..color = grid
      ..strokeWidth = 1;
    for (var i = 0; i <= 4; i++) {
      final y = top + h * (1 - i / 4);
      canvas.drawLine(Offset(left, y), Offset(left + w, y), gridPaint);
      final label = '${i * 25}';
      _text(canvas, fa ? toFaDigits(label) : label, Offset(0, y - 7));
    }
    if (values.isEmpty) return;

    Offset pt(int i) {
      final x = values.length == 1
          ? left + w / 2
          : left + w * i / (values.length - 1);
      final v = values[i].clamp(0.0, 100.0).toDouble();
      final y = top + h * (1 - v / 100);
      return Offset(x, y);
    }

    final path = Path()..moveTo(pt(0).dx, pt(0).dy);
    for (var i = 1; i < values.length; i++) {
      final a = pt(i - 1);
      final b = pt(i);
      final mx = (a.dx + b.dx) / 2;
      path.cubicTo(mx, a.dy, mx, b.dy, b.dx, b.dy);
    }

    if (values.length > 1) {
      final fill = Path.from(path)
        ..lineTo(pt(values.length - 1).dx, top + h)
        ..lineTo(pt(0).dx, top + h)
        ..close();
      canvas.drawPath(
        fill,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [line.withAlpha(95), line.withAlpha(0)],
          ).createShader(Rect.fromLTWH(left, top, w, h)),
      );
    }

    canvas.drawPath(
      path,
      Paint()
        ..shader = LinearGradient(colors: [line, accent])
            .createShader(Rect.fromLTWH(left, top, w, h))
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.5
        ..strokeJoin = StrokeJoin.round
        ..strokeCap = StrokeCap.round,
    );

    final ringPaint = Paint()..color = ring;
    for (var i = 0; i < values.length; i++) {
      final isLast = i == values.length - 1;
      final dot = Paint()..color = isLast ? accent : line;
      canvas.drawCircle(pt(i), isLast ? 7.5 : 6, ringPaint);
      canvas.drawCircle(pt(i), isLast ? 5 : 3.8, dot);
    }

    final step = (values.length / 5).ceil().clamp(1, 1000);
    for (var i = 0; i < values.length; i += step) {
      final p = pt(i);
      _text(canvas, labels[i], Offset(p.dx, top + h + 6), center: true);
    }
  }

  @override
  bool shouldRepaint(covariant LineChartPainter old) => true;
}

// ───────────────────────── Settings tab ─────────────────────────

class ThemeTile extends StatelessWidget {
  final AppPalette pal;
  final bool selected;
  final VoidCallback onTap;
  const ThemeTile(
      {super.key,
      required this.pal,
      required this.selected,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    final s = StoreScope.of(context);
    final cur = s.palette;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 88,
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: selected ? cur.primary : cur.line,
            width: selected ? 2 : 1,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: 54,
                  height: 54,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: cur.muted.withAlpha(120)),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        pal.swatchA,
                        pal.swatchA,
                        pal.swatchB,
                        pal.swatchB
                      ],
                      stops: const [0, 0.5, 0.5, 1],
                    ),
                  ),
                ),
                if (selected)
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                        color: cur.primary, shape: BoxShape.circle),
                    child: Icon(Icons.check_rounded,
                        size: 16, color: cur.onPrimary),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              pal.name(s.lang),
              textAlign: TextAlign.center,
              maxLines: 2,
              style: TextStyle(
                fontSize: 12,
                fontWeight: selected ? FontWeight.w800 : FontWeight.w500,
                color: cur.text,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class SettingsTab extends StatelessWidget {
  const SettingsTab({super.key});

  Widget _section(BuildContext context, String text) {
    final p = StoreScope.of(context).palette;
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 8, 4, 8),
      child: Text(text,
          style: TextStyle(
              fontSize: 14, fontWeight: FontWeight.w700, color: p.muted)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = StoreScope.of(context);
    final p = s.palette;
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
      children: [
        _section(context, t(context, 'language')),
        AppCard(
          child: SizedBox(
            width: double.infinity,
            child: SegmentedButton<String>(
              showSelectedIcon: false,
              segments: const [
                ButtonSegment(value: 'fa', label: Text('فارسی')),
                ButtonSegment(value: 'en', label: Text('English')),
              ],
              selected: {s.lang},
              onSelectionChanged: (v) => s.setLang(v.first),
              style: SegmentedButton.styleFrom(
                selectedBackgroundColor: p.primary,
                selectedForegroundColor: p.onPrimary,
                foregroundColor: p.text,
                side: BorderSide(color: p.line),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        _section(context, t(context, 'theme')),
        AppCard(
          child: Wrap(
            spacing: 10,
            runSpacing: 10,
            alignment: WrapAlignment.center,
            children: kPalettes
                .map((pal) => ThemeTile(
                      pal: pal,
                      selected: pal.id == s.themeId,
                      onTap: () => s.setTheme(pal.id),
                    ))
                .toList(),
          ),
        ),
        const SizedBox(height: 12),
        _section(context, t(context, 'default_penalty')),
        AppCard(
          child: PenaltyChips(value: s.penalty, onChanged: s.setPenalty),
        ),
        const SizedBox(height: 12),
        AppCard(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          onTap: () async {
            final ok = await showDialog<bool>(
              context: context,
              builder: (ctx) => AlertDialog(
                backgroundColor: p.surface,
                surfaceTintColor: Colors.transparent,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(22)),
                content: Text(t(context, 'delete_all_q'),
                    style: TextStyle(color: p.text)),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx, false),
                    child: Text(t(context, 'cancel'),
                        style: TextStyle(color: p.text)),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(ctx, true),
                    child: Text(t(context, 'delete'),
                        style: const TextStyle(color: Color(0xFFEF4444))),
                  ),
                ],
              ),
            );
            if (ok == true) s.clearAll();
          },
          child: Row(
            children: [
              const Padding(
                padding: EdgeInsets.all(8),
                child: Icon(Icons.delete_outline_rounded,
                    color: Color(0xFFEF4444)),
              ),
              Text(t(context, 'delete_all'),
                  style: const TextStyle(
                      color: Color(0xFFEF4444), fontWeight: FontWeight.w700)),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Center(
          child: Text(t(context, 'about'),
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: p.muted)),
        ),
      ],
    );
  }
}
