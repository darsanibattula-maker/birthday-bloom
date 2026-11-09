
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

const pink = Color(0xFFE8A2B8);
const cream = Color(0xFFF2E5D5);
const burgundy = Color(0xFF702D49);
const pastelBlue = Color(0xFFAEC9DC);
const background = Color(0xFF171216);
const cardColor = Color(0xFF30242D);

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const BirthdayBloomApp());
}

class Birthday {
  String name;
  String relationship;
  String date;
  String note;

  Birthday({
    required this.name,
    required this.relationship,
    required this.date,
    this.note = '',
  });

  Map<String, dynamic> toJson() => {
    'name': name,
    'relationship': relationship,
    'date': date,
    'note': note,
  };

  factory Birthday.fromJson(Map<String, dynamic> json) {
    return Birthday(
      name: json['name'],
      relationship: json['relationship'],
      date: json['date'],
      note: json['note'] ?? '',
    );
  }

  DateTime get birthDate => DateTime.parse(date);

  int get daysLeft {
    final today = DateTime.now();
    var next = DateTime(
      today.year,
      birthDate.month,
      birthDate.day,
    );

    if (next.isBefore(DateTime(today.year, today.month, today.day))) {
      next = DateTime(today.year + 1, birthDate.month, birthDate.day);
    }

    return next.difference(
      DateTime(today.year, today.month, today.day),
    ).inDays;
  }
}

class BirthdayBloomApp extends StatelessWidget {
  const BirthdayBloomApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Birthday Bloom',
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: background,
        colorScheme: ColorScheme.fromSeed(
          seedColor: pink,
          brightness: Brightness.dark,
        ),
      ),
      home: const MainScreen(),
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  List<Birthday> birthdays = [];
  int selectedTab = 0;
  bool loading = true;
  String searchText = '';

  @override
  void initState() {
    super.initState();
    loadBirthdays();
  }

  Future<void> loadBirthdays() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString('birthdays');

    if (saved != null) {
      final List data = jsonDecode(saved);
      birthdays = data
          .map((item) => Birthday.fromJson(item))
          .toList();
    }

    if (mounted) {
      setState(() => loading = false);
    }
  }

  Future<void> saveBirthdays() async {
    final prefs = await SharedPreferences.getInstance();
    final data = birthdays.map((b) => b.toJson()).toList();
    await prefs.setString('birthdays', jsonEncode(data));
  }

  Future<void> addBirthday() async {
    final result = await showDialog<Birthday>(
      context: context,
      builder: (_) => const BirthdayDialog(),
    );

    if (result != null) {
      setState(() {
        birthdays.add(result);
        birthdays.sort((a, b) => a.daysLeft.compareTo(b.daysLeft));
      });
      await saveBirthdays();
    }
  }

  Future<void> editBirthday(int index) async {
    final result = await showDialog<Birthday>(
      context: context,
      builder: (_) => BirthdayDialog(birthday: birthdays[index]),
    );

    if (result != null) {
      setState(() {
        birthdays[index] = result;
        birthdays.sort((a, b) => a.daysLeft.compareTo(b.daysLeft));
      });
      await saveBirthdays();
    }
  }

  Future<void> deleteBirthday(int index) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: cardColor,
        title: const Text('Delete Birthday?'),
        content: const Text('This birthday will be removed.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: pink)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() => birthdays.removeAt(index));
      await saveBirthdays();
    }
  }

  List<Birthday> get filteredBirthdays {
    return birthdays.where((b) =>
      b.name.toLowerCase().contains(searchText.toLowerCase())
    ).toList()
      ..sort((a, b) => a.daysLeft.compareTo(b.daysLeft));
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      homePage(),
      birthdayPage(),
      calendarPage(),
      wishesPage(),
    ];

    return Scaffold(
      body: SafeArea(
        child: loading
            ? const Center(child: CircularProgressIndicator(color: pink))
            : pages[selectedTab],
      ),
      bottomNavigationBar: NavigationBar(
        backgroundColor: cardColor,
        indicatorColor: burgundy,
        selectedIndex: selectedTab,
        onDestinationSelected: (index) {
          setState(() => selectedTab = index);
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home, color: cream),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.cake_outlined),
            label: 'Birthdays',
          ),
          NavigationDestination(
            icon: Icon(Icons.calendar_month_outlined),
            label: 'Calendar',
          ),
          NavigationDestination(
            icon: Icon(Icons.favorite_outline),
            label: 'Wishes',
          ),
        ],
      ),
    );
  }

  Widget homePage() {
    final upcoming = filteredBirthdays.take(3).toList();

    return ListView(
      padding: const EdgeInsets.all(22),
      children: [
        const SizedBox(height: 12),
        const Text(
          'Birthday Bloom 🌸',
          style: TextStyle(
            fontSize: 29,
            fontWeight: FontWeight.bold,
            color: pink,
          ),
        ),
        const SizedBox(height: 7),
        const Text(
          'Celebrate every special moment.',
          style: TextStyle(color: cream),
        ),
        const SizedBox(height: 25),
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [burgundy, Color(0xFF452538)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(25),
          ),
          child: const Column(
            children: [
              Text('🎂', style: TextStyle(fontSize: 75)),
              SizedBox(height: 12),
              Text(
                'Make Every Birthday Special',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: cream,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Never miss a moment worth celebrating!',
                textAlign: TextAlign.center,
                style: TextStyle(color: cream),
              ),
            ],
          ),
        ),
        const SizedBox(height: 22),
        Row(
          children: [
            Expanded(child: statCard(
              '${birthdays.length}',
              'Saved',
              Icons.people_outline,
              pink,
            )),
            const SizedBox(width: 12),
            Expanded(child: statCard(
              '${birthdays.where((b) => b.daysLeft == 0).length}',
              'Today',
              Icons.celebration,
              pastelBlue,
            )),
          ],
        ),
        const SizedBox(height: 30),
        sectionTitle('Upcoming Birthdays'),
        const SizedBox(height: 14),
        if (upcoming.isEmpty)
          emptyMessage()
        else
          ...upcoming.map((b) => birthdayCard(b)),
        const SizedBox(height: 20),
        addButton(),
      ],
    );
  }

  Widget statCard(String value, String label, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
          Text(value, style: const TextStyle(
            fontSize: 25,
            fontWeight: FontWeight.bold,
            color: cream,
          )),
          Text(label, style: const TextStyle(color: cream)),
        ],
      ),
    );
  }

  Widget birthdayPage() {
    return ListView(
      padding: const EdgeInsets.all(22),
      children: [
        const Text(
          'My Birthdays 🎈',
          style: TextStyle(fontSize: 28, color: pink,
              fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 20),
        TextField(
          onChanged: (value) => setState(() => searchText = value),
          decoration: InputDecoration(
            hintText: 'Search birthdays...',
            prefixIcon: const Icon(Icons.search, color: pink),
            filled: true,
            fillColor: cardColor,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        const SizedBox(height: 20),
        if (filteredBirthdays.isEmpty)
          emptyMessage()
        else
          ...filteredBirthdays.map((b) {
            final index = birthdays.indexOf(b);
            return birthdayCard(b, index: index, editable: true);
          }),
        const SizedBox(height: 20),
        addButton(),
      ],
    );
  }

  Widget calendarPage() {
    final sorted = [...birthdays]
      ..sort((a, b) => a.daysLeft.compareTo(b.daysLeft));

    return ListView(
      padding: const EdgeInsets.all(22),
      children: [
        const Text(
          'Birthday Calendar 📅',
          style: TextStyle(fontSize: 27, color: pink,
              fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        Text(
          'Your upcoming celebrations',
          style: TextStyle(color: cream.withValues(alpha: 0.7)),
        ),
        const SizedBox(height: 20),
        if (sorted.isEmpty)
          emptyMessage()
        else
          ...sorted.map((b) => birthdayCard(b)),
      ],
    );
  }

  Widget wishesPage() {
    const wishes = [
      'Wishing you a day filled with love, laughter and endless happiness! 🎂',
      'May all your dreams bloom beautifully. Happy Birthday! 🌸',
      'Another year, another reason to shine. Have a wonderful birthday! ✨',
      'Sending you hugs, smiles and lots of birthday magic! 🎈',
    ];

    return ListView(
      padding: const EdgeInsets.all(22),
      children: [
        const Text(
          'Wish Studio 💌',
          style: TextStyle(fontSize: 28, color: pink,
              fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        const Text('Beautiful wishes for your special people.',
            style: TextStyle(color: cream)),
        const SizedBox(height: 22),
        ...wishes.map((wish) => Container(
          margin: const EdgeInsets.only(bottom: 14),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(18),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(wish, style: const TextStyle(
                fontSize: 16, color: cream, height: 1.5)),
              Align(
                alignment: Alignment.centerRight,
                child: IconButton(
                  icon: const Icon(Icons.copy, color: pink),
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Wish ready to use!')),
                    );
                  },
                ),
              ),
            ],
          ),
        )),
      ],
    );
  }

  Widget birthdayCard(Birthday b,
      {int? index, bool editable = false}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 13),
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(19),
      ),
      child: Row(
        children: [
          const Text('🎂', style: TextStyle(fontSize: 33)),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(b.name, style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 17,
                  color: cream,
                )),
                const SizedBox(height: 4),
                Text(b.relationship,
                    style: const TextStyle(color: pastelBlue)),
                Text(
                  '${b.birthDate.day}/${b.birthDate.month}',
                  style: const TextStyle(color: cream),
                ),
                const SizedBox(height: 4),
                Text(
                  b.daysLeft == 0
                      ? '🎉 Birthday Today!'
                      : '${b.daysLeft} days left',
                  style: const TextStyle(color: pink,
                      fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          if (editable && index != null)
            PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'edit') editBirthday(index);
                if (value == 'delete') deleteBirthday(index);
              },
              itemBuilder: (_) => const [
                PopupMenuItem(value: 'edit', child: Text('Edit')),
                PopupMenuItem(value: 'delete', child: Text('Delete')),
              ],
              icon: const Icon(Icons.more_vert, color: cream),
            ),
        ],
      ),
    );
  }

  Widget sectionTitle(String title) {
    return Text(title, style: const TextStyle(
      fontSize: 22,
      fontWeight: FontWeight.bold,
      color: cream,
    ));
  }

  Widget emptyMessage() {
    return Container(
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(18),
      ),
      child: const Column(
        children: [
          Text('🎈', style: TextStyle(fontSize: 40)),
          SizedBox(height: 10),
          Text('No birthdays added yet',
              style: TextStyle(color: cream)),
          Text('Add someone special to get started!',
              style: TextStyle(color: pastelBlue)),
        ],
      ),
    );
  }

  Widget addButton() {
    return SizedBox(
      height: 55,
      child: ElevatedButton.icon(
        onPressed: addBirthday,
        icon: const Icon(Icons.add),
        label: const Text('Add Birthday'),
        style: ElevatedButton.styleFrom(
          backgroundColor: pink,
          foregroundColor: background,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }
}

class BirthdayDialog extends StatefulWidget {
  final Birthday? birthday;

  const BirthdayDialog({super.key, this.birthday});

  @override
  State<BirthdayDialog> createState() => _BirthdayDialogState();
}

class _BirthdayDialogState extends State<BirthdayDialog> {
  final nameController = TextEditingController();
  final noteController = TextEditingController();

  String relationship = 'Friend';
  DateTime? selectedDate;

  final relationships = [
    'Friend',
    'Best Friend',
    'Family',
    'Mother',
    'Father',
    'Brother',
    'Sister',
    'Partner',
    'Other',
  ];

  @override
  void initState() {
    super.initState();

    if (widget.birthday != null) {
      nameController.text = widget.birthday!.name;
      noteController.text = widget.birthday!.note;
      relationship = widget.birthday!.relationship;
      selectedDate = widget.birthday!.birthDate;
    }
  }

  @override
  void dispose() {
    nameController.dispose();
    noteController.dispose();
    super.dispose();
  }

  Future<void> pickDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: selectedDate ?? DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      builder: (context, child) => Theme(
        data: ThemeData.dark().copyWith(
          colorScheme: const ColorScheme.dark(
            primary: pink,
            surface: cardColor,
            onSurface: cream,
          ),
        ),
        child: child!,
      ),
    );

    if (date != null) {
      setState(() => selectedDate = date);
    }
  }

  void submit() {
    if (nameController.text.trim().isEmpty || selectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a name and birthday date.'),
        ),
      );
      return;
    }

    Navigator.pop(
      context,
      Birthday(
        name: nameController.text.trim(),
        relationship: relationship,
        date: selectedDate!.toIso8601String(),
        note: noteController.text.trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: cardColor,
      title: Text(
        widget.birthday == null ? 'Add Birthday 🎂' : 'Edit Birthday',
        style: const TextStyle(color: pink),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Person name',
                labelStyle: TextStyle(color: cream),
              ),
            ),
            const SizedBox(height: 15),
            DropdownButtonFormField<String>(
              value: relationship,
              dropdownColor: cardColor,
              decoration: const InputDecoration(
                labelText: 'Relationship',
              ),
              items: relationships.map((item) =>
                DropdownMenuItem(value: item, child: Text(item))
              ).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() => relationship = value);
                }
              },
            ),
            const SizedBox(height: 15),
            TextField(
              controller: noteController,
              decoration: const InputDecoration(
                labelText: 'Special note (optional)',
              ),
            ),
            const SizedBox(height: 18),
            OutlinedButton.icon(
              onPressed: pickDate,
              icon: const Icon(Icons.calendar_month, color: pink),
              label: Text(
                selectedDate == null
                    ? 'Select Birthday'
                    : '${selectedDate!.day}/${selectedDate!.month}/${selectedDate!.year}',
                style: const TextStyle(color: cream),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: submit,
          style: ElevatedButton.styleFrom(
            backgroundColor: pink,
            foregroundColor: background,
          ),
          child: const Text('Save'),
        ),
      ],
    );
  }
}
