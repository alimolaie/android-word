import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

// مدل داده برای کلمه
class Word {
  final String english;
  final String meaning;
  List<String> reviewDates;

  Word(this.english, this.meaning, this.reviewDates);
}

// آداپتور برای Hive
class WordAdapter extends TypeAdapter<Word> {
  @override
  final int typeId = 0;

  @override
  Word read(BinaryReader reader) {
    return Word(
      reader.readString(),
      reader.readString(),
      List<String>.from(reader.readList()),
    );
  }

  @override
  void write(BinaryWriter writer, Word obj) {
    writer.writeString(obj.english);
    writer.writeString(obj.meaning);
    writer.writeList(obj.reviewDates);
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final directory = await getApplicationDocumentsDirectory();
  await Hive.initFlutter(directory.path);
  Hive.registerAdapter(WordAdapter());
  await Hive.openBox<Word>('words');
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Vocabulary App',
      theme: ThemeData(
        primarySwatch: Colors.teal,
        fontFamily: 'Vazir',
        textTheme: TextTheme(
          bodyText1: TextStyle(fontSize: 16),
          headline6: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            primary: Colors.teal,
            onPrimary: Colors.white,
            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 5,
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          filled: true,
          fillColor: Colors.grey[100],
        ),
      ),
      home: HomePage(),
    );
  }
}

// صفحه اصلی
class HomePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('اپلیکیشن واژگان'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.teal,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.teal[50]!, Colors.white],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedButton(
                text: 'کلمه جدید',
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => AddWordPage()),
                  );
                },
              ),
              SizedBox(height: 20),
              AnimatedButton(
                text: 'مرور کلمات امروز',
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => ReviewPage()),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ویجت دکمه با انیمیشن
class AnimatedButton extends StatefulWidget {
  final String text;
  final VoidCallback onPressed;

  AnimatedButton({required this.text, required this.onPressed});

  @override
  _AnimatedButtonState createState() => _AnimatedButtonState();
}

class _AnimatedButtonState extends State<AnimatedButton> {
  bool _isTapped = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isTapped = true),
      onTapUp: (_) {
        setState(() => _isTapped = false);
        widget.onPressed();
      },
      onTapCancel: () => setState(() => _isTapped = false),
      child: AnimatedContainer(
        duration: Duration(milliseconds: 200),
        transform: Matrix4.identity()..scale(_isTapped ? 0.95 : 1.0),
        child: ElevatedButton(
          onPressed: widget.onPressed,
          child: Text(widget.text, style: TextStyle(fontSize: 18)),
        ),
      ),
    );
  }
}

// صفحه افزودن کلمه جدید
class AddWordPage extends StatefulWidget {
  @override
  _AddWordPageState createState() => _AddWordPageState();
}

class _AddWordPageState extends State<AddWordPage> {
  final _englishController = TextEditingController();
  final _meaningController = TextEditingController();

  void _saveWord() {
    if (_englishController.text.isEmpty || _meaningController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('لطفاً هر دو فیلد را پر کنید')),
      );
      return;
    }

    final now = DateTime.now();
    final reviewDates = [
      DateFormat('yyyy-MM-dd').format(now),
      DateFormat('yyyy-MM-dd').format(now.add(Duration(days: 1))),
      DateFormat('yyyy-MM-dd').format(now.add(Duration(days: 3))),
      DateFormat('yyyy-MM-dd').format(now.add(Duration(days: 10))),
    ];

    final word = Word(_englishController.text, _meaningController.text, reviewDates);
    final box = Hive.box<Word>('words');
    box.add(word);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('کلمه ذخیره شد'),
        backgroundColor: Colors.teal,
      ),
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('اضافه کردن کلمه جدید'),
        centerTitle: true,
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Card(
          elevation: 5,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: _englishController,
                  decoration: InputDecoration(
                    labelText: 'کلمه انگلیسی',
                    prefixIcon: Icon(Icons.language),
                  ),
                ),
                SizedBox(height: 16),
                TextField(
                  controller: _meaningController,
                  decoration: InputDecoration(
                    labelText: 'معنی کلمه',
                    prefixIcon: Icon(Icons.translate),
                  ),
                ),
                SizedBox(height: 20),
                AnimatedButton(
                  text: 'ذخیره کلمه',
                  onPressed: _saveWord,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// صفحه مرور کلمات
class ReviewPage extends StatefulWidget {
  @override
  _ReviewPageState createState() => _ReviewPageState();
}

class _ReviewPageState extends State<ReviewPage> with SingleTickerProviderStateMixin {
  List<Word> todayWords = [];
  int currentIndex = 0;
  bool showMeaning = false;
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: Duration(milliseconds: 500),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    _loadTodayWords();
  }

  void _loadTodayWords() {
    final box = Hive.box<Word>('words');
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    todayWords = box.values
        .where((word) => word.reviewDates.contains(today))
        .toList();
    setState(() {
      _controller.forward();
    });
  }

  void _updateWordStatus(bool known) {
    final word = todayWords[currentIndex];
    final now = DateTime.now();
    final today = DateFormat('yyyy-MM-dd').format(now);

    if (!known) {
      word.reviewDates = [
        DateFormat('yyyy-MM-dd').format(now.add(Duration(days: 1))),
        DateFormat('yyyy-MM-dd').format(now.add(Duration(days: 2))),
        DateFormat('yyyy-MM-dd').format(now.add(Duration(days: 5))),
        DateFormat('yyyy-MM-dd').format(now.add(Duration(days: 7))),
        DateFormat('yyyy-MM-dd').format(now.add(Duration(days: 15))),
      ];
    } else {
      word.reviewDates.remove(today);
    }

    final box = Hive.box<Word>('words');
    final index = box.values.toList().indexOf(word);
    box.putAt(index, word);

    setState(() {
      currentIndex++;
      showMeaning = false;
      _controller.reset();
      _controller.forward();
      if (currentIndex >= todayWords.length) {
        todayWords = [];
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('کلمات امروز مرور شده‌اند'),
            backgroundColor: Colors.teal,
          ),
        );
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (todayWords.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: Text('مرور کلمات'), centerTitle: true),
        body: Center(
          child: Text(
            'هیچ کلمه‌ای برای مرور امروز وجود ندارد',
            style: TextStyle(fontSize: 18, color: Colors.grey[600]),
          ),
        ),
      );
    }

    final word = todayWords[currentIndex];

    return Scaffold(
      appBar: AppBar(title: Text('مرور کلمات'), centerTitle: true),
      body: Center(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Card(
            elevation: 8,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            margin: EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              padding: EdgeInsets.all(24),
              width: double.infinity,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    word.english,
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.teal[800],
                    ),
                    textAlign: TextAlign.center,
                  ),
                  if (showMeaning) ...[
                    SizedBox(height: 20),
                    Text(
                      word.meaning,
                      style: TextStyle(fontSize: 20, color: Colors.grey[700]),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        AnimatedButton(
                          text: 'بلد بودم',
                          onPressed: () => _updateWordStatus(true),
                        ),
                        SizedBox(width: 20),
                        AnimatedButton(
                          text: 'بلد نبودم',
                          onPressed: () => _updateWordStatus(false),
                        ),
                      ],
                    ),
                  ],
                  SizedBox(height: 20),
                  if (!showMeaning)
                    AnimatedButton(
                      text: 'نمایش معنی',
                      onPressed: () {
                        setState(() {
                          showMeaning = true;
                          _controller.reset();
                          _controller.forward();
                        });
                      },
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}