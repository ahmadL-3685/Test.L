import 'dart:convert';

import 'package:flutter/material.dart';
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
    'empty': 'هنوز آزمونی ثبت نکرده‌ای.\nبا دکمه + اولین آزمون رو اضافه کن.',
    'count': 'تعداد',
    'average': 'میانگین',
    'best': 'بهترین',
    'last': 'آخرین',
    'all': 'همه',
    'language': 'زبان',
    'dark_mode': 'حالت تاریک',
    'delete_all': 'حذف همه اطلاعات',
    'delete_all_q': 'همه آزمون‌های ثبت‌شده پاک می‌شن. مطمئنی؟',
    'cancel': 'انصراف',
    'delete': 'حذف',
    'deleted': 'آزمون حذف شد',
    'undo': 'بازگردانی',
    'required': 'این فیلد لازمه',
    'invalid': 'عدد معتبر وارد کن',
    'score_gt_max': 'نمره نمی‌تونه از نمره کل بیشتر باشه',
    'no_data': 'برای نمایش نمودار حداقل یک آزمون لازمه.',
    'about': 'همه اطلاعات فقط روی همین گوشی ذخیره می‌شه.',
    'change': 'تغییر نسبت به آزمون قبل',
    'your_subjects': 'درس‌های قبلی',
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
    'penalty_hint': 'Each wrong answer removes a fraction of one correct answer (1/3 means 3 wrong cancel 1 correct).',
    'result': 'Your percentage',
    'bad_count': 'Correct + wrong is more than total questions',
    'default_penalty': 'Default negative marking',
    'date': 'Date',
    'note': 'Note (optional)',
    'save': 'Save',
    'empty': 'No exams yet.\nTap + to add your first one.',
    'count': 'Count',
    'average': 'Average',
    'best': 'Best',
    'last': 'Latest',
    'all': 'All',
    'language': 'Language',
    'dark_mode': 'Dark mode',
    'delete_all': 'Delete all data',
    'delete_all_q': 'All saved exams will be erased. Are you sure?',
    'cancel': 'Cancel',
    'delete': 'Delete',
    'deleted': 'Exam deleted',
    'undo': 'Undo',
    'required': 'This field is required',
    'invalid': 'Enter a valid number',
    'score_gt_max': 'Score cannot exceed max score',
    'no_data': 'Add at least one exam to see the chart.',
    'about': 'All data is stored only on this phone.',
    'change': 'Change vs previous exam',
    'your_subjects': 'Previous subjects',
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
  bool dark;
  double penalty;

  Store(this.prefs)
      : lang = prefs.getString('lang') ?? 'fa',
        dark = prefs.getBool('dark') ?? false,
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

  void setDark(bool v) {
    dark = v;
    prefs.setBool('dark', v);
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
            theme: ThemeData(
              useMaterial3: true,
              colorSchemeSeed: const Color(0xFF6C4BFF),
              brightness: Brightness.light,
            ),
            darkTheme: ThemeData(
              useMaterial3: true,
              colorSchemeSeed: const Color(0xFF6C4BFF),
              brightness: Brightness.dark,
            ),
            themeMode: store.dark ? ThemeMode.dark : ThemeMode.light,
            home: const HomePage(),
          ),
        );
      },
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
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
      appBar: AppBar(title: Text(titles[_index])),
      body: SafeArea(child: pages[_index]),
      floatingActionButton: _index == 0
          ? FloatingActionButton.extended(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ExamFormPage()),
              ),
              icon: const Icon(Icons.add),
              label: Text(t(context, 'add_exam')),
            )
          : null,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: [
          NavigationDestination(
              icon: const Icon(Icons.list_alt_outlined),
              selectedIcon: const Icon(Icons.list_alt),
              label: titles[0]),
          NavigationDestination(
              icon: const Icon(Icons.show_chart),
              selectedIcon: const Icon(Icons.show_chart),
              label: titles[1]),
          NavigationDestination(
              icon: const Icon(Icons.settings_outlined),
              selectedIcon: const Icon(Icons.settings),
              label: titles[2]),
        ],
      ),
    );
  }
}

// ───────────────────────── Shared widgets ─────────────────────────

Color percentColor(double p) {
  if (p >= 70) return Colors.green;
  if (p >= 50) return Colors.orange;
  return Colors.red;
}

class StatBox extends StatelessWidget {
  final String label;
  final String value;
  const StatBox({super.key, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
          child: Column(
            children: [
              Text(value,
                  style: Theme.of(context)
                      .textTheme
                      .titleLarge
                      ?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text(label, style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        ),
      ),
    );
  }
}

double averagePercent(List<Exam> list) {
  if (list.isEmpty) return 0;
  var sum = 0.0;
  for (final e in list) {
    sum += e.percent;
  }
  return sum / list.length;
}

// ───────────────────────── Exams tab ─────────────────────────

class ExamsTab extends StatelessWidget {
  const ExamsTab({super.key});

  @override
  Widget build(BuildContext context) {
    final s = StoreScope.of(context);
    if (s.exams.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.school_outlined,
                  size: 72, color: Theme.of(context).colorScheme.outline),
              const SizedBox(height: 16),
              Text(t(context, 'empty'), textAlign: TextAlign.center),
            ],
          ),
        ),
      );
    }
    final list = s.exams.reversed.toList();
    final best = list.map((e) => e.percent).reduce((a, b) => a > b ? a : b);
    return ListView(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 100),
      children: [
        Row(
          children: [
            StatBox(
                label: t(context, 'count'),
                value: nd(context, '${list.length}')),
            StatBox(
                label: t(context, 'average'),
                value: nd(context, fmtPct(averagePercent(list)))),
            StatBox(
                label: t(context, 'best'),
                value: nd(context, fmtPct(best))),
          ],
        ),
        const SizedBox(height: 8),
        ...list.map((e) => ExamTile(exam: e)),
      ],
    );
  }
}

class ExamTile extends StatelessWidget {
  final Exam exam;
  const ExamTile({super.key, required this.exam});

  @override
  Widget build(BuildContext context) {
    final s = StoreScope.of(context);
    final color = percentColor(exam.percent);
    final sub = [
      nd(context, fmtDate(exam.date)),
      if (exam.note.isNotEmpty) exam.note,
    ].join('  •  ');
    final counts = nd(
        context,
        '${t(context, 'correct')}: ${exam.correct}   '
        '${t(context, 'wrong')}: ${exam.wrong}   '
        '${t(context, 'blank')}: ${exam.blank}');
    return Dismissible(
      key: ValueKey(exam.id),
      direction: DismissDirection.horizontal,
      background: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        decoration: BoxDecoration(
          color: Colors.red,
          borderRadius: BorderRadius.circular(12),
        ),
        alignment: AlignmentDirectional.centerStart,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      secondaryBackground: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        decoration: BoxDecoration(
          color: Colors.red,
          borderRadius: BorderRadius.circular(12),
        ),
        alignment: AlignmentDirectional.centerEnd,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      onDismissed: (_) {
        s.remove(exam.id);
        final m = ScaffoldMessenger.of(context);
        m.clearSnackBars();
        m.showSnackBar(SnackBar(
          content: Text(t(context, 'deleted')),
          action: SnackBarAction(
            label: t(context, 'undo'),
            onPressed: () => s.addOrUpdate(exam),
          ),
        ));
      },
      child: Card(
        margin: const EdgeInsets.symmetric(vertical: 4),
        child: ListTile(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => ExamFormPage(exam: exam)),
          ),
          title: Text(exam.subject,
              style: const TextStyle(fontWeight: FontWeight.bold)),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(counts),
              Text(sub, maxLines: 2, overflow: TextOverflow.ellipsis),
            ],
          ),
          trailing: Text(
            nd(context, fmtPct(exam.percent)),
            style: TextStyle(
                color: color, fontWeight: FontWeight.bold, fontSize: 18),
          ),
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
      children: opts
          .map((o) => ChoiceChip(
                label: Text(t(context, o.key)),
                selected: (value - o.value).abs() < 1e-9,
                onSelected: (_) => onChanged(o.value),
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
    final subjects = s.subjects;
    final pen = _penalty ?? widget.exam?.penalty ?? s.penalty;
    const numKb = TextInputType.number;

    final total = _int(_total) ?? 0;
    final c = _int(_correct, emptyZero: true) ?? 0;
    final w = _int(_wrong, emptyZero: true) ?? 0;
    final valid = total > 0 && c + w <= total;
    final pct = valid ? (c - w * pen) / total * 100 : 0.0;
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(t(context,
            widget.exam == null ? 'add_exam' : 'edit_exam')),
      ),
      body: SafeArea(
        child: Form(
          key: _form,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              TextFormField(
                controller: _subject,
                decoration: InputDecoration(
                  labelText: t(context, 'subject'),
                  border: const OutlineInputBorder(),
                ),
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? t(context, 'required')
                    : null,
              ),
              if (subjects.isNotEmpty) ...[
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: subjects
                      .map((x) => ActionChip(
                            label: Text(x),
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
                decoration: InputDecoration(
                  labelText: t(context, 'total_q'),
                  border: const OutlineInputBorder(),
                ),
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
                      decoration: InputDecoration(
                        labelText: t(context, 'correct'),
                        border: const OutlineInputBorder(),
                      ),
                      validator: (_) => _countCheck(),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _wrong,
                      keyboardType: numKb,
                      onChanged: (_) => setState(() {}),
                      decoration: InputDecoration(
                        labelText: t(context, 'wrong'),
                        border: const OutlineInputBorder(),
                      ),
                      validator: (_) => _countCheck(),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(t(context, 'penalty'),
                  style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: 8),
              PenaltyChips(
                value: pen,
                onChanged: (v) => setState(() => _penalty = v),
              ),
              const SizedBox(height: 6),
              Text(t(context, 'penalty_hint'),
                  style: Theme.of(context).textTheme.bodySmall),
              if (valid) ...[
                const SizedBox(height: 16),
                Card(
                  color: cs.primaryContainer,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        Text(t(context, 'result'),
                            style: TextStyle(color: cs.onPrimaryContainer)),
                        const SizedBox(height: 4),
                        Text(
                          nd(context, fmtPct(pct)),
                          style: TextStyle(
                            fontSize: 36,
                            fontWeight: FontWeight.bold,
                            color: cs.onPrimaryContainer,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          nd(context,
                              '${t(context, 'blank')}: ${total - c - w}'),
                          style: TextStyle(color: cs.onPrimaryContainer),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: _pickDate,
                icon: const Icon(Icons.calendar_today),
                label: Text(
                    '${t(context, 'date')}: ${nd(context, fmtDate(_date))}'),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(52),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _note,
                maxLines: 2,
                decoration: InputDecoration(
                  labelText: t(context, 'note'),
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: () => _save(pen),
                icon: const Icon(Icons.check),
                label: Text(t(context, 'save')),
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(52),
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
    final subjects = s.subjects;
    final sel = subjects.contains(_subject) ? _subject : null;
    final list =
        s.exams.where((e) => sel == null || e.subject == sel).toList();
    final cs = Theme.of(context).colorScheme;

    final chips = Wrap(
      spacing: 8,
      runSpacing: 4,
      children: [
        ChoiceChip(
          label: Text(t(context, 'all')),
          selected: sel == null,
          onSelected: (_) => setState(() => _subject = null),
        ),
        ...subjects.map((x) => ChoiceChip(
              label: Text(x),
              selected: sel == x,
              onSelected: (_) => setState(() => _subject = x),
            )),
      ],
    );

    if (list.isEmpty) {
      return ListView(
        padding: const EdgeInsets.all(16),
        children: [
          chips,
          const SizedBox(height: 48),
          Center(child: Text(t(context, 'no_data'))),
        ],
      );
    }

    final values = list.map((e) => e.percent).toList();
    final labels = list.map((e) => nd(context, fmtShort(e.date))).toList();
    final best = values.reduce((a, b) => a > b ? a : b);
    final last = values.last;
    final fa = s.lang == 'fa';

    String? changeText;
    Color changeColor = cs.outline;
    if (values.length >= 2) {
      final d = values.last - values[values.length - 2];
      final sign = d > 0 ? '+' : '';
      changeText = nd(context, '$sign${d.toStringAsFixed(1)}%');
      changeColor = d > 0
          ? Colors.green
          : (d < 0 ? Colors.red : cs.outline);
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        chips,
        const SizedBox(height: 16),
        Row(
          children: [
            StatBox(
                label: t(context, 'average'),
                value:
                    nd(context, fmtPct(averagePercent(list)))),
            StatBox(
                label: t(context, 'best'),
                value: nd(context, fmtPct(best))),
            StatBox(
                label: t(context, 'last'),
                value: nd(context, fmtPct(last))),
          ],
        ),
        const SizedBox(height: 8),
        Card(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(8, 16, 12, 8),
            child: Directionality(
              textDirection: TextDirection.ltr,
              child: SizedBox(
                height: 260,
                width: double.infinity,
                child: CustomPaint(
                  painter: LineChartPainter(
                    values: values,
                    labels: labels,
                    fa: fa,
                    line: cs.primary,
                    grid: cs.outlineVariant,
                    text: cs.onSurfaceVariant,
                  ),
                ),
              ),
            ),
          ),
        ),
        if (changeText != null) ...[
          const SizedBox(height: 8),
          Card(
            child: ListTile(
              title: Text(t(context, 'change')),
              trailing: Text(
                changeText,
                style: TextStyle(
                    color: changeColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 16),
              ),
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
  final Color grid;
  final Color text;

  LineChartPainter({
    required this.values,
    required this.labels,
    required this.fa,
    required this.line,
    required this.grid,
    required this.text,
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
      path.lineTo(pt(i).dx, pt(i).dy);
    }

    if (values.length > 1) {
      final fill = Path.from(path)
        ..lineTo(pt(values.length - 1).dx, top + h)
        ..lineTo(pt(0).dx, top + h)
        ..close();
      canvas.drawPath(fill, Paint()..color = line.withAlpha(40));
    }

    canvas.drawPath(
      path,
      Paint()
        ..color = line
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..strokeJoin = StrokeJoin.round
        ..strokeCap = StrokeCap.round,
    );

    final dot = Paint()..color = line;
    final dotBg = Paint()..color = Colors.white;
    for (var i = 0; i < values.length; i++) {
      canvas.drawCircle(pt(i), 5.5, dotBg);
      canvas.drawCircle(pt(i), 4, dot);
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

class SettingsTab extends StatelessWidget {
  const SettingsTab({super.key});

  @override
  Widget build(BuildContext context) {
    final s = StoreScope.of(context);
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(t(context, 'language'),
            style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        SegmentedButton<String>(
          segments: const [
            ButtonSegment(value: 'fa', label: Text('فارسی')),
            ButtonSegment(value: 'en', label: Text('English')),
          ],
          selected: {s.lang},
          onSelectionChanged: (v) => s.setLang(v.first),
        ),
        const SizedBox(height: 16),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(t(context, 'dark_mode')),
          value: s.dark,
          onChanged: s.setDark,
        ),
        const Divider(),
        const SizedBox(height: 8),
        Text(t(context, 'default_penalty'),
            style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        PenaltyChips(value: s.penalty, onChanged: s.setPenalty),
        const SizedBox(height: 8),
        const Divider(),
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.delete_forever, color: Colors.red),
          title: Text(t(context, 'delete_all'),
              style: const TextStyle(color: Colors.red)),
          onTap: () async {
            final ok = await showDialog<bool>(
              context: context,
              builder: (ctx) => AlertDialog(
                content: Text(t(context, 'delete_all_q')),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx, false),
                    child: Text(t(context, 'cancel')),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(ctx, true),
                    child: Text(t(context, 'delete'),
                        style: const TextStyle(color: Colors.red)),
                  ),
                ],
              ),
            );
            if (ok == true) s.clearAll();
          },
        ),
        const SizedBox(height: 24),
        Text(t(context, 'about'),
            style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}
