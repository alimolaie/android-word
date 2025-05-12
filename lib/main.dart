import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:async';

void main() {
  runApp(const FlashCardApp());
}

class FlashCardApp extends StatelessWidget {
  const FlashCardApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flash Card App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
        scaffoldBackgroundColor: Colors.white,
        textTheme: const TextTheme(
          headlineMedium: TextStyle(
              fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black87),
          bodyLarge: TextStyle(fontSize: 18, color: Colors.black54),
          bodyMedium: TextStyle(fontSize: 16, color: Colors.black87),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            foregroundColor: Colors.white,
            backgroundColor: Colors.blueAccent,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            textStyle:
                const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            elevation: 8,
          ),
        ),
        dialogTheme: DialogTheme(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          backgroundColor: Colors.white,
          elevation: 8,
        ),
      ),
      home: const HomePage(),
    );
  }
}

class DataStorage {
  static Future<SharedPreferences> get _prefs async =>
      await SharedPreferences.getInstance();

  static Future<bool> saveWord(String english, String meaning) async {
    final prefs = await _prefs;
    List<String> words = prefs.getStringList('words') ?? [];

    // Check for duplicate word
    bool isDuplicate = words.any((word) =>
        jsonDecode(word)['english'].toLowerCase() == english.toLowerCase());
    if (isDuplicate) {
      return false; // Indicate duplicate
    }

    // Save new word
    int id = words.length + 1;
    final word = {
      'id': id,
      'english': english,
      'meaning': meaning,
      'first_review_completed': false
    };
    words.add(jsonEncode(word));
    await prefs.setStringList('words', words);

    // Add review dates: today, tomorrow, 3 days, 10 days
    List<String> schedule = prefs.getStringList('review_schedule') ?? [];
    final reviewDates = [
      DateTime.now(),
      DateTime.now().add(const Duration(days: 1)),
      DateTime.now().add(const Duration(days: 3)),
      DateTime.now().add(const Duration(days: 10)),
    ];
    for (var date in reviewDates) {
      schedule.add(jsonEncode({
        'word_id': id,
        'review_date': date.toIso8601String().split('T')[0],
      }));
    }
    await prefs.setStringList('review_schedule', schedule);
    return true; // Indicate success
  }

  static Future<List<Map<String, dynamic>>> getWordsForReview(
      String date) async {
    final prefs = await _prefs;
    List<String> schedule = prefs.getStringList('review_schedule') ?? [];
    List<String> words = prefs.getStringList('words') ?? [];
    List<Map<String, dynamic>> result = [];

    for (var entry in schedule) {
      final scheduleEntry = jsonDecode(entry);
      if (scheduleEntry['review_date'] == date) {
        int wordId = scheduleEntry['word_id'];
        for (var wordEntry in words) {
          final word = jsonDecode(wordEntry);
          if (word['id'] == wordId) {
            result.add(word);
          }
        }
      }
    }
    return result;
  }

  static Future<void> updateReviewSchedule(
      int wordId, bool known, bool isFirstReview, String currentDate) async {
    final prefs = await _prefs;
    List<String> schedule = prefs.getStringList('review_schedule') ?? [];

    // Remove today's schedule for this word
    schedule.removeWhere((entry) {
      final entryData = jsonDecode(entry);
      return entryData['word_id'] == wordId &&
          entryData['review_date'] == currentDate;
    });

    // If not first review and not known, reset schedule
    if (!isFirstReview && !known) {
      // Remove all future schedules for this word
      schedule.removeWhere((entry) => jsonDecode(entry)['word_id'] == wordId);
      // Add new schedule: tomorrow, 2 days, 5 days, 7 days, 15 days
      final reviewDates = [
        DateTime.now().add(const Duration(days: 1)),
        DateTime.now().add(const Duration(days: 2)),
        DateTime.now().add(const Duration(days: 5)),
        DateTime.now().add(const Duration(days: 7)),
        DateTime.now().add(const Duration(days: 15)),
      ];
      for (var date in reviewDates) {
        schedule.add(jsonEncode({
          'word_id': wordId,
          'review_date': date.toIso8601String().split('T')[0],
        }));
      }
    }

    await prefs.setStringList('review_schedule', schedule);
  }

  static Future<void> updateFirstReviewStatus(int wordId) async {
    final prefs = await _prefs;
    List<String> words = prefs.getStringList('words') ?? [];

    for (int i = 0; i < words.length; i++) {
      final word = jsonDecode(words[i]);
      if (word['id'] == wordId) {
        word['first_review_completed'] = true;
        words[i] = jsonEncode(word);
        break;
      }
    }
    await prefs.setStringList('words', words);
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  void _showAboutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('درباره برنامه'),
        content: const Text(
          'این برنامه آموزش کلمه زبان به صورت زمان‌بندی شده است و از متد معروف آموزش جی پنج پیروی می‌کند و به شما کمک می‌کند تا کلمات زبان را در مقاطع زمانی از پیش تعیین شده به شما نمایش دهد تا راحت‌تر کلمات را یاد بگیرید.',
          textAlign: TextAlign.right,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child:
                const Text('بستن', style: TextStyle(color: Colors.blueAccent)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title:
            const Text('Flash Card App', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.blueAccent,
        elevation: 4,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.blueAccent, Colors.white],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const AddWordPage()),
                  );
                },
                child: const Text('کلمه جدید'),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const ReviewWordsPage()),
                  );
                },
                child: const Text('مرور کلمات امروز'),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAboutDialog(context),
        backgroundColor: Colors.blueAccent,
        child: const Icon(Icons.info, color: Colors.white),
        tooltip: 'درباره برنامه',
      ),
    );
  }
}

class AddWordPage extends StatefulWidget {
  const AddWordPage({super.key});

  @override
  State<AddWordPage> createState() => _AddWordPageState();
}

class _AddWordPageState extends State<AddWordPage> {
  final _englishController = TextEditingController();
  final _meaningController = TextEditingController();

  Future<void> _saveWord() async {
    final english = _englishController.text.trim();
    final meaning = _meaningController.text.trim();

    if (english.isNotEmpty && meaning.isNotEmpty) {
      bool success = await DataStorage.saveWord(english, meaning);
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('کلمه با موفقیت ذخیره شد')),
        );
        _englishController.clear();
        _meaningController.clear();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('این کلمه قبلاً اضافه شده است')),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('لطفاً هر دو فیلد را پر کنید')),
      );
    }
  }

  @override
  void dispose() {
    _englishController.dispose();
    _meaningController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('افزودن کلمه جدید',
            style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.blueAccent,
        elevation: 4,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.blueAccent, Colors.white],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              TextField(
                controller: _englishController,
                decoration: InputDecoration(
                  labelText: 'کلمه انگلیسی',
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                  filled: true,
                  fillColor: Colors.white.withOpacity(0.9),
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9\s]')),
                ],
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _meaningController,
                decoration: InputDecoration(
                  labelText: 'معنی کلمه',
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                  filled: true,
                  fillColor: Colors.white.withOpacity(0.9),
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(
                      RegExp(r'[\u0600-\u06FF\s]')),
                ],
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _saveWord,
                child: const Text('ذخیره کلمه'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ReviewWordsPage extends StatefulWidget {
  const ReviewWordsPage({super.key});

  @override
  State<ReviewWordsPage> createState() => _ReviewWordsPageState();
}

class _ReviewWordsPageState extends State<ReviewWordsPage> {
  List<Map<String, dynamic>> words = [];
  int currentIndex = 0;
  bool showMeaning = false;

  @override
  void initState() {
    super.initState();
    _loadWords();
  }

  Future<void> _loadWords() async {
    final today = DateTime.now().toIso8601String().split('T')[0];
    final loadedWords = await DataStorage.getWordsForReview(today);
    setState(() {
      words = loadedWords;
      currentIndex = 0;
      showMeaning = false;
    });
  }

  Future<void> _handleKnown(bool known) async {
    if (currentIndex < words.length) {
      final word = words[currentIndex];
      final today = DateTime.now().toIso8601String().split('T')[0];
      final isFirstReview = !(word['first_review_completed'] ?? false);

      // Update review schedule
      await DataStorage.updateReviewSchedule(
          word['id'], known, isFirstReview, today);

      // Mark first review as completed if it was the first review
      if (isFirstReview) {
        await DataStorage.updateFirstReviewStatus(word['id']);
      }

      setState(() {
        currentIndex++;
        showMeaning = false;
      });

      if (currentIndex >= words.length) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('کلمات امروز مرور شده‌اند')),
        );
        await _loadWords();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('مرور کلمات امروز',
            style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.blueAccent,
        elevation: 4,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.blueAccent, Colors.white],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Center(
          child: words.isEmpty
              ? const Text(
                  'هیچ کلمه‌ای برای مرور امروز وجود ندارد',
                  style: TextStyle(fontSize: 20, color: Colors.black54),
                )
              : currentIndex >= words.length
                  ? const Text(
                      'کلمات امروز مرور شده‌اند',
                      style: TextStyle(fontSize: 20, color: Colors.black54),
                    )
                  : Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Card(
                          elevation: 8,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16)),
                          color: Colors.white.withOpacity(0.95),
                          child: Padding(
                            padding: const EdgeInsets.all(24.0),
                            child: Column(
                              children: [
                                Text(
                                  words[currentIndex]['english'],
                                  style: Theme.of(context)
                                      .textTheme
                                      .headlineMedium,
                                ),
                                if (showMeaning) ...[
                                  const SizedBox(height: 16),
                                  Text(
                                    words[currentIndex]['meaning'],
                                    style:
                                        Theme.of(context).textTheme.bodyLarge,
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        if (!showMeaning)
                          ElevatedButton(
                            onPressed: () {
                              setState(() {
                                showMeaning = true;
                              });
                            },
                            child: const Text('نمایش معنی'),
                          ),
                        if (showMeaning) ...[
                          ElevatedButton(
                            onPressed: () => _handleKnown(true),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                            ),
                            child: const Text('بلد بودم'),
                          ),
                          const SizedBox(height: 10),
                          ElevatedButton(
                            onPressed: () => _handleKnown(false),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.redAccent,
                            ),
                            child: const Text('بلد نبودم'),
                          ),
                        ],
                      ],
                    ),
        ),
      ),
    );
  }
}
