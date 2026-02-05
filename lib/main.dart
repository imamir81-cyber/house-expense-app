// =====================
// HOUSE EXPENSE APP
// Offline • Simple • Excel-like
// =====================

import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:fl_chart/fl_chart.dart';

const String kBoxName = 'expensesBox';

class Expense {
  Expense({required this.name, required this.amount, required this.isDone});

  String name;
  double amount;
  bool isDone;

  Map<String, dynamic> toMap() => {
        'name': name,
        'amount': amount,
        'isDone': isDone,
      };

  static Expense fromMap(Map map) => Expense(
        name: map['name'] ?? '',
        amount: (map['amount'] ?? 0).toDouble(),
        isDone: map['isDone'] ?? false,
      );
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  await Hive.openBox(kBoxName);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'House Expenses',
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final box = Hive.box(kBoxName);

  List<Expense> get items {
    final raw = box.get('items', defaultValue: []) as List;
    return raw
        .map((e) => Expense.fromMap(Map<String, dynamic>.from(e)))
        .toList();
  }

  void save(List<Expense> list) =>
      box.put('items', list.map((e) => e.toMap()).toList());

  double get total =>
      items.fold(0, (sum, e) => sum + e.amount);

  bool get overallDone =>
      items.isNotEmpty && items.every((e) => e.isDone);

  @override
  void initState() {
    super.initState();
    if (items.isEmpty) {
      save([
        Expense(name: 'House Rent', amount: 0, isDone: false),
        Expense(name: 'Electricity Bill', amount: 0, isDone: false),
        Expense(name: 'Gas Bill', amount: 0, isDone: false),
        Expense(name: 'Internet', amount: 0, isDone: false),
        Expense(name: 'Groceries', amount: 0, isDone: false),
      ]);
    }
  }

  @override
  Widget build(BuildContext context) {
    final doneItems =
        items.where((e) => e.isDone && e.amount > 0).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('House Expenses')),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          Card(
            child: ListTile(
              title: const Text('Total Amount (Auto)'),
              subtitle: Text(total.toStringAsFixed(0)),
              trailing: Chip(
                label: Text(overallDone ? 'DONE' : 'PENDING'),
                backgroundColor:
                    overallDone ? Colors.green : Colors.orange,
              ),
            ),
          ),
          const SizedBox(height: 12),

          // CHART
          if (doneItems.isNotEmpty)
            SizedBox(
              height: 220,
              child: BarChart(
                BarChartData(
                  barGroups: List.generate(
                    doneItems.length,
                    (i) => BarChartGroupData(
                      x: i,
                      barRods: [
                        BarChartRodData(
                          toY: doneItems[i].amount,
                        )
                      ],
                    ),
                  ),
                ),
              ),
            ),

          const SizedBox(height: 12),

          ...List.generate(items.length, (i) {
            final e = items[i];
            return Card(
              color: e.isDone ? Colors.green.shade100 : null,
              child: ListTile(
                title: Text(e.name),
                subtitle: Text('Amount: ${e.amount.toStringAsFixed(0)}'),
                trailing: Switch(
                  value: e.isDone,
                  onChanged: (v) {
                    final list = items;
                    list[i].isDone = v;
                    save(list);
                    setState(() {});
                  },
                ),
                onTap: () async {
                  final ctrl = TextEditingController(
                      text: e.amount.toString());
                  final ok = await showDialog<bool>(
                    context: context,
                    builder: (_) => AlertDialog(
                      title: Text(e.name),
                      content: TextField(
                        controller: ctrl,
                        keyboardType: TextInputType.number,
                      ),
                      actions: [
                        TextButton(
                            onPressed: () =>
                                Navigator.pop(context, false),
                            child: const Text('Cancel')),
                        ElevatedButton(
                            onPressed: () =>
                                Navigator.pop(context, true),
                            child: const Text('Save')),
                      ],
                    ),
                  );
                  if (ok == true) {
                    final list = items;
                    list[i].amount =
                        double.tryParse(ctrl.text) ?? e.amount;
                    save(list);
                    setState(() {});
                  }
                },
              ),
            );
          }),
        ],
      ),
    );
  }
}
