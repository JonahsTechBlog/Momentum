import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wakelock/wakelock.dart';

/// ---------------------------------------------------------------------------
///                          GLOBAL DATA
/// ---------------------------------------------------------------------------

/// Default presets available in Momentum.
List<Map<String, dynamic>> PRESETS = [
  {'name': 'Plank Challenge', 'work': 60, 'rest': 0},
  {'name': 'HIIT Classic', 'work': 30, 'rest': 10},
  {'name': 'Tabata', 'work': 20, 'rest': 10},
  {'name': 'Endurance', 'work': 45, 'rest': 15},
  {'name': 'Pyramid', 'work': 15, 'rest': 5},
  {'name': 'Core Blast', 'work': 30, 'rest': 15},
  {'name': 'Cardio Blitz', 'work': 60, 'rest': 30},
  {'name': 'Yoga Flow', 'work': 90, 'rest': 20},
  {'name': 'Strength Training', 'work': 45, 'rest': 30},
  {'name': 'Power', 'work': 40, 'rest': 20},
  {'name': 'Custom', 'work': 60, 'rest': 0},
  {'name': 'Boxing Round', 'work': 180, 'rest': 60},
  {'name': 'Circuit Training', 'work': 45, 'rest': 20},
  {'name': 'CrossFit WOD', 'work': 60, 'rest': 45},
  {'name': 'AMRAP', 'work': 10, 'rest': 0},
  {'name': 'EMOM', 'work': 60, 'rest': 0},
];

/// Favorites that appear on Home. Defaults are loaded if none stored.
List<Map<String, dynamic>> favoritePresets = [];

/// The user's workout history is appended here after finishing a workout.
List<Map<String, dynamic>> workoutHistory = [];

/// On a fresh install, we use these as the initial favorites:
List<Map<String, dynamic>> get defaultFavorites => PRESETS.where((preset) {
  return ['Plank Challenge', 'Tabata', 'Power', 'Custom'].contains(preset['name']);
}).toList();

/// SharedPreferences keys for storing data:
const String kFavKey = 'momentum_favorites';
const String kHistKey = 'momentum_history';
const String kCustomKey = 'momentum_custom_presets';

/// ---------------------------------------------------------------------------
///                          PERSISTENCE (SharedPreferences)
/// ---------------------------------------------------------------------------

/// Reads data from SharedPreferences (Web + Mobile-friendly).
Future<void> loadUserData() async {
  final prefs = await SharedPreferences.getInstance();

  // FAVORITES:
  final favString = prefs.getString(kFavKey);
  if (favString != null) {
    final List favList = jsonDecode(favString);
    favoritePresets = favList.map((e) => Map<String, dynamic>.from(e)).toList();
  } else {
    // No favorites => default
    favoritePresets = defaultFavorites;
  }

  // HISTORY:
  final histString = prefs.getString(kHistKey);
  if (histString != null) {
    final List histList = jsonDecode(histString);
    workoutHistory = histList.map((e) => Map<String, dynamic>.from(e)).toList();
  }

  // USER-CREATED PRESETS:
  final customString = prefs.getString(kCustomKey);
  if (customString != null) {
    final List customList = jsonDecode(customString);
    for (var item in customList) {
      final map = Map<String, dynamic>.from(item);
      // Add only if not already present
      if (!PRESETS.any((p) => p['name'] == map['name'])) {
        PRESETS.add(map);
      }
    }
  }
}

/// Persists [favoritePresets], [workoutHistory], and user-created presets (not default).
Future<void> saveUserData() async {
  final prefs = await SharedPreferences.getInstance();

  // Favorites
  await prefs.setString(kFavKey, jsonEncode(favoritePresets));

  // History
  await prefs.setString(kHistKey, jsonEncode(workoutHistory));

  // Derive user-created presets (anything not in the original default set).
  final defaultSet = {
    jsonEncode({'name': 'Plank Challenge', 'work': 60, 'rest': 0}),
    jsonEncode({'name': 'HIIT Classic', 'work': 30, 'rest': 10}),
    jsonEncode({'name': 'Tabata', 'work': 20, 'rest': 10}),
    jsonEncode({'name': 'Endurance', 'work': 45, 'rest': 15}),
    jsonEncode({'name': 'Pyramid', 'work': 15, 'rest': 5}),
    jsonEncode({'name': 'Core Blast', 'work': 30, 'rest': 15}),
    jsonEncode({'name': 'Cardio Blitz', 'work': 60, 'rest': 30}),
    jsonEncode({'name': 'Yoga Flow', 'work': 90, 'rest': 20}),
    jsonEncode({'name': 'Strength Training', 'work': 45, 'rest': 30}),
    jsonEncode({'name': 'Power', 'work': 40, 'rest': 20}),
    jsonEncode({'name': 'Custom', 'work': 60, 'rest': 0}),
    jsonEncode({'name': 'Boxing Round', 'work': 180, 'rest': 60}),
    jsonEncode({'name': 'Circuit Training', 'work': 45, 'rest': 20}),
    jsonEncode({'name': 'CrossFit WOD', 'work': 60, 'rest': 45}),
    jsonEncode({'name': 'AMRAP', 'work': 10, 'rest': 0}),
    jsonEncode({'name': 'EMOM', 'work': 60, 'rest': 0}),
  };

  final userCreatedPresets = PRESETS.where((p) {
    final encoded =
        jsonEncode({'name': p['name'], 'work': p['work'], 'rest': p['rest']});
    return !defaultSet.contains(encoded);
  }).toList();

  await prefs.setString(kCustomKey, jsonEncode(userCreatedPresets));
}

/// ---------------------------------------------------------------------------
///                             MAIN APP
/// ---------------------------------------------------------------------------

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load stored data (favorites, history, user-created presets)
  await loadUserData();

  runApp(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF006D77)),
        appBarTheme: const AppBarTheme(backgroundColor: Color(0xFF006D77)),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.white,
          showSelectedLabels: true,
          showUnselectedLabels: true,
          elevation: 4,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(30)),
            ),
          ),
        ),
        floatingActionButtonTheme: FloatingActionButtonThemeData(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(16)),
          ),
        ),
        pageTransitionsTheme: const PageTransitionsTheme(
          builders: {
            TargetPlatform.android: CupertinoPageTransitionsBuilder(),
            TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
            TargetPlatform.linux: CupertinoPageTransitionsBuilder(),
            TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
            TargetPlatform.windows: CupertinoPageTransitionsBuilder(),
          },
        ),
      ),
      home: const AppNavigator(),
    ),
  );
}

/// A root widget with a bottom nav for Home, Discover, and Me.
class AppNavigator extends StatefulWidget {
  const AppNavigator({Key? key}) : super(key: key);

  @override
  State<AppNavigator> createState() => _AppNavigatorState();
}

class _AppNavigatorState extends State<AppNavigator> {
  int _selectedIndex = 0;
  final PageController _pageController = PageController();

  final List<String> _titles = ['Momentum', 'Discover', 'Me'];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
      _pageController.animateToPage(
        index,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_titles[_selectedIndex]),
      ),
      body: PageView(
        controller: _pageController,
        onPageChanged: (index) => setState(() => _selectedIndex = index),
        children: const [
          HomePage(),
          DiscoverPage(),
          MePage(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        selectedItemColor: const Color(0xFF006D77),
        onTap: _onItemTapped,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.explore), label: 'Discover'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Me'),
        ],
      ),
    );
  }
}

/// ---------------------------------------------------------------------------
///                           HOME PAGE (TIMER)
/// ---------------------------------------------------------------------------

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String selectedPreset = PRESETS[0]['name'] as String;
  int workTime = PRESETS[0]['work'] as int;
  int restTime = PRESETS[0]['rest'] as int;

  bool isRunning = false;
  bool isResting = false;
  int currentTime = 60;
  Timer? timer;

  int currentSet = 1;
  int numberOfSets = 1;

  @override
  void initState() {
    super.initState();
    currentTime = workTime;
  }

  @override
  void dispose() {
    timer?.cancel();
    if (!kIsWeb) {
      Wakelock.disable();
    }
    super.dispose();
  }

  void startTimer() {
    if (!kIsWeb) {
      Wakelock.enable();
    }
    timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (currentTime > 0) {
          currentTime--;
        } else {
          if (!isResting && restTime > 0) {
            isResting = true;
            currentTime = restTime;
          } else {
            isResting = false;
            currentSet++;
            if (currentSet <= numberOfSets) {
              currentTime = workTime;
            } else {
              timer.cancel();
              isRunning = false;

              workoutHistory.add({
                'sets': numberOfSets,
                'name': selectedPreset,
                'work': workTime,
                'rest': restTime,
                'timestamp': DateTime.now().toIso8601String(),
              });
              saveUserData();

              currentTime = workTime;
              currentSet = 1;

              if (!kIsWeb) {
                Wakelock.disable();
              }
            }
          }
        }
      });
    });
  }

  void pauseTimer() {
    timer?.cancel();
    if (!kIsWeb) {
      Wakelock.disable();
    }
  }

  void handlePresetChange(Map<String, dynamic> preset) {
    setState(() {
      selectedPreset = preset['name'] as String;
      workTime = preset['work'] as int;
      restTime = preset['rest'] as int;
      currentTime = workTime;
      isRunning = false;
      isResting = false;
      currentSet = 1;
    });
    timer?.cancel();
    if (!kIsWeb) {
      Wakelock.disable();
    }
  }

  void showCustomPresetDialog() {
    final workCtrl = TextEditingController(text: workTime.toString());
    final restCtrl = TextEditingController(text: restTime.toString());

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Custom Preset'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: workCtrl,
                keyboardType: TextInputType.number,
                decoration:
                    const InputDecoration(labelText: 'Work Time (seconds)'),
              ),
              TextField(
                controller: restCtrl,
                keyboardType: TextInputType.number,
                decoration:
                    const InputDecoration(labelText: 'Rest Time (seconds)'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                setState(() {
                  workTime = int.tryParse(workCtrl.text) ?? workTime;
                  restTime = int.tryParse(restCtrl.text) ?? restTime;
                  selectedPreset = 'Custom';
                  currentTime = workTime;
                  isRunning = false;
                  timer?.cancel();
                  if (!kIsWeb) {
                    Wakelock.disable();
                  }
                });
                Navigator.pop(context);
              },
              child: const Text('Apply'),
            ),
          ],
        );
      },
    );
  }

  List<Map<String, dynamic>> reorderFavoritesForHome() {
    final idx = favoritePresets.indexWhere((p) => p['name'] == 'Custom');
    if (idx == -1) return favoritePresets;

    final withoutCustom =
        favoritePresets.where((p) => p['name'] != 'Custom').toList();
    final customPreset = favoritePresets[idx];
    withoutCustom.add(customPreset);
    return withoutCustom;
  }

  @override
  Widget build(BuildContext context) {
    final denom = isResting
        ? (restTime == 0 ? 1 : restTime)
        : (workTime == 0 ? 1 : workTime);
    final progress = (currentTime / denom) * 100;

    final homePresets = reorderFavoritesForHome();

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            children: [
              if (homePresets.isNotEmpty)
                SizedBox(
                  height: 60,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: homePresets.length,
                    itemBuilder: (context, index) {
                      final preset = homePresets[index];
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4.0),
                        child: ElevatedButton(
                          onPressed: () {
                            if (preset['name'] == 'Custom') {
                              showCustomPresetDialog();
                            } else {
                              handlePresetChange(preset);
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: (selectedPreset == preset['name'])
                                ? const Color(0xFF006D77)
                                : Colors.white,
                            foregroundColor: (selectedPreset == preset['name'])
                                ? Colors.white
                                : const Color(0xFF006D77),
                          ),
                          child: Text(preset['name'] as String),
                        ),
                      );
                    },
                  ),
                ),
              const SizedBox(height: 32),

              Column(
                children: [
                  const Text('Number of sets:', style: TextStyle(fontSize: 16)),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      InkWell(
                        onTap: () {
                          setState(() {
                            if (numberOfSets > 1) numberOfSets--;
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: Color(0xFF006D77),
                          ),
                          child: const Icon(Icons.remove, color: Colors.white),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Color(0xFF006D77),
                        ),
                        child: Text(
                          numberOfSets.toString(),
                          style: const TextStyle(
                            fontSize: 24,
                            color: Colors.white
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      InkWell(
                        onTap: () => setState(() => numberOfSets++),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: Color(0xFF006D77),
                          ),
                          child: const Icon(Icons.add, color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),

              Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 288,
                    height: 288,
                    child: CustomPaint(
                      painter: TimerPainter(
                        progress: progress,
                        isResting: isResting,
                      ),
                    ),
                  ),
                  Column(
                    children: [
                      Text(
                        '${(currentTime / 60).floor()}:${(currentTime % 60).toString().padLeft(2, '0')}',
                        style: const TextStyle(
                          fontSize: 48,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF006D77),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        isResting ? 'Rest' : 'Work',
                        style: const TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),

              ElevatedButton(
                onPressed: () {
                  setState(() {
                    isRunning = !isRunning;
                    if (isRunning) {
                      startTimer();
                    } else {
                      pauseTimer();
                    }
                  });
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  shape: const CircleBorder(),
                  padding: const EdgeInsets.all(24),
                ),
                child: Icon(
                  isRunning ? Icons.pause : Icons.play_arrow,
                  size: 32,
                  color: const Color(0xFF006D77),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class TimerPainter extends CustomPainter {
  final double progress; // 0 to 100
  final bool isResting;

  TimerPainter({required this.progress, required this.isResting});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..strokeWidth = 12
      ..style = PaintingStyle.stroke;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    paint.color = Colors.grey.withOpacity(0.3);
    canvas.drawCircle(center, radius, paint);

    final sweepAngle = (progress / 100) * 2 * 3.141592653589793;
    paint.color = isResting ? Colors.red : Colors.green;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -3.141592653589793 / 2,
      sweepAngle,
      false,
      paint,
    );
  }

  @override
  bool shouldRepaint(TimerPainter oldDelegate) => true;
}

/// ---------------------------------------------------------------------------
///                         DISCOVER PAGE
/// ---------------------------------------------------------------------------

class DiscoverPage extends StatefulWidget {
  const DiscoverPage({Key? key}) : super(key: key);

  @override
  State<DiscoverPage> createState() => _DiscoverPageState();
}

class _DiscoverPageState extends State<DiscoverPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView.builder(
          itemCount: PRESETS.length + 1,
          itemBuilder: (context, index) {
            if (index == PRESETS.length) {
              return const SizedBox(height: 80);
            }
            final preset = PRESETS[index];
            final bool isFav =
                favoritePresets.any((fav) => fav['name'] == preset['name']);

            return ListTile(
              title: Text(preset['name'] as String),
              subtitle: preset['name'] == 'Custom'
                  ? const Text('Customizable', style: TextStyle(color: Colors.grey))
                  : Text(
                      'Work: ${preset['work']}s, Rest: ${preset['rest']}s',
                      style: const TextStyle(color: Colors.grey),
                    ),
              trailing: IconButton(
                icon: Icon(
                  isFav ? Icons.favorite : Icons.favorite_border,
                  color: isFav ? Colors.red : null,
                ),
                onPressed: () {
                  setState(() {
                    if (isFav) {
                      favoritePresets.removeWhere(
                        (fav) => fav['name'] == preset['name'],
                      );
                    } else {
                      addPresetBeforeCustom(preset);
                    }
                    saveUserData();
                  });
                },
              ),
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF006D77),
        onPressed: _showCreateWorkoutDialog,
        child: const Icon(Icons.add),
      ),
    );
  }

  void addPresetBeforeCustom(Map<String, dynamic> newPreset) {
    final customIndex = favoritePresets.indexWhere((p) => p['name'] == 'Custom');
    if (customIndex == -1) {
      favoritePresets.add(newPreset);
    } else {
      final beforeCustom = favoritePresets.sublist(0, customIndex);
      final afterCustom = favoritePresets.sublist(customIndex);
      beforeCustom.add(newPreset);
      favoritePresets
        ..clear()
        ..addAll(beforeCustom)
        ..addAll(afterCustom);
    }
  }

  void _showCreateWorkoutDialog() {
    final nameCtrl = TextEditingController();
    final workCtrl = TextEditingController();
    final restCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Create Workout'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(labelText: 'Title'),
              ),
              TextField(
                controller: workCtrl,
                keyboardType: TextInputType.number,
                decoration:
                    const InputDecoration(labelText: 'Work Time (seconds)'),
              ),
              TextField(
                controller: restCtrl,
                keyboardType: TextInputType.number,
                decoration:
                    const InputDecoration(labelText: 'Rest Time (seconds)'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                final newWorkout = {
                  'name': nameCtrl.text.trim().isEmpty
                      ? 'My Custom Workout'
                      : nameCtrl.text.trim(),
                  'work': int.tryParse(workCtrl.text) ?? 0,
                  'rest': int.tryParse(restCtrl.text) ?? 0,
                };
                setState(() {
                  PRESETS.add(newWorkout);
                  addPresetBeforeCustom(newWorkout);
                });
                saveUserData();
                Navigator.pop(context);
              },
              child: const Text('Create'),
            ),
          ],
        );
      },
    );
  }
}

/// ---------------------------------------------------------------------------
///                            ME PAGE
/// ---------------------------------------------------------------------------

class MePage extends StatelessWidget {
  const MePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Workout History',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Expanded(child: WorkoutHistoryList()),
          ],
        ),
      ),
    );
  }
}

class WorkoutHistoryList extends StatefulWidget {
  const WorkoutHistoryList({Key? key}) : super(key: key);

  @override
  State<WorkoutHistoryList> createState() => _WorkoutHistoryListState();
}

class _WorkoutHistoryListState extends State<WorkoutHistoryList> {
  int _displayCount = 5;

  @override
  Widget build(BuildContext context) {
    if (workoutHistory.isEmpty) {
      return const Center(child: Text('No workout history yet.'));
    }

    final reversed = workoutHistory.reversed.toList();
    final count = reversed.length.clamp(0, _displayCount);

    return SingleChildScrollView(
      child: Column(
        children: [
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: count,
            itemBuilder: (context, index) {
              final workout = reversed[index];
              final name = workout['name'] ?? 'Unknown';
              final work = workout['work'] ?? 0;
              final rest = workout['rest'] ?? 0;
              final sets = workout['sets'] ?? 1;

              final displayTitle = (sets > 1) ? '$sets x $name' : name;

              return ListTile(
                title: Text(displayTitle),
                subtitle: Text('Work: ${work}s, Rest: ${rest}s'),
              );
            },
          ),
          if (reversed.length > _displayCount)
            TextButton(
              onPressed: () => setState(() => _displayCount += 5),
              child: const Text(
                'More',
                style: TextStyle(color: Color(0xFF006D77)),
              ),
            ),
        ],
      ),
    );
  }
}
