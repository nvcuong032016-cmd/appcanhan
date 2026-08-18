import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MrCuongApp());
}

class Task {
  String title;
  bool done;
  Task(this.title, {this.done = false});
  Map<String, dynamic> toJson() => {'title': title, 'done': done};
  factory Task.fromJson(Map<String, dynamic> j) => Task(j['title']?.toString() ?? '', done: j['done'] == true);
}

class Project {
  String name;
  List<Task> tasks;
  Project(this.name, [List<Task>? tasks]) : tasks = tasks ?? [];
  int get completed => tasks.where((t) => t.done).length;
  double get progress => tasks.isEmpty ? 0 : completed / tasks.length;
  Map<String, dynamic> toJson() => {'name': name, 'tasks': tasks.map((t) => t.toJson()).toList()};
  factory Project.fromJson(Map<String, dynamic> j) => Project(
        j['name']?.toString() ?? '',
        (j['tasks'] as List? ?? []).map((e) => Task.fromJson(Map<String, dynamic>.from(e))).toList(),
      );
}

class CardData {
  String bank, last4;
  int statementDay, paymentDay;
  double balance, limit;
  CardData({required this.bank, required this.last4, required this.statementDay, required this.paymentDay, this.balance = 0, this.limit = 0});
  Map<String, dynamic> toJson() => {'bank': bank, 'last4': last4, 'statementDay': statementDay, 'paymentDay': paymentDay, 'balance': balance, 'limit': limit};
  factory CardData.fromJson(Map<String, dynamic> j) => CardData(
        bank: j['bank']?.toString() ?? '', last4: j['last4']?.toString() ?? '',
        statementDay: (j['statementDay'] as num?)?.toInt() ?? 1, paymentDay: (j['paymentDay'] as num?)?.toInt() ?? 1,
        balance: (j['balance'] as num?)?.toDouble() ?? 0, limit: (j['limit'] as num?)?.toDouble() ?? 0,
      );
}

class Loan {
  String name;
  double amount, monthly;
  int term, paid, paymentDay;
  Loan({required this.name, required this.amount, required this.monthly, required this.term, required this.paid, required this.paymentDay});
  Map<String, dynamic> toJson() => {'name': name, 'amount': amount, 'monthly': monthly, 'term': term, 'paid': paid, 'paymentDay': paymentDay};
  factory Loan.fromJson(Map<String, dynamic> j) => Loan(
        name: j['name']?.toString() ?? '', amount: (j['amount'] as num?)?.toDouble() ?? 0,
        monthly: (j['monthly'] as num?)?.toDouble() ?? 0, term: (j['term'] as num?)?.toInt() ?? 0,
        paid: (j['paid'] as num?)?.toInt() ?? 0, paymentDay: (j['paymentDay'] as num?)?.toInt() ?? 1,
      );
}

class AppData extends ChangeNotifier {
  List<Project> projects = [];
  List<CardData> cards = [];
  List<Loan> loans = [];
  bool ready = false;

  Future<void> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final p = prefs.getString('projects');
      final c = prefs.getString('cards');
      final l = prefs.getString('loans');
      if (p != null) projects = (jsonDecode(p) as List).map((e) => Project.fromJson(Map<String, dynamic>.from(e))).toList();
      if (c != null) cards = (jsonDecode(c) as List).map((e) => CardData.fromJson(Map<String, dynamic>.from(e))).toList();
      if (l != null) loans = (jsonDecode(l) as List).map((e) => Loan.fromJson(Map<String, dynamic>.from(e))).toList();
    } catch (_) {
      projects = [];
      cards = [];
      loans = [];
    }
    if (projects.isEmpty) projects = [Project('DVCI Đà Lạt', [Task('Lập kế hoạch', done: true), Task('Theo dõi tiến độ'), Task('Đăng hồ sơ'), Task('Kiểm tra kết quả'), Task('Ký hợp đồng')])];
    if (cards.isEmpty) cards = [CardData(bank: 'VPBank', last4: '1234', statementDay: 15, paymentDay: 5, balance: 25000000, limit: 100000000), CardData(bank: 'Techcombank', last4: '5678', statementDay: 20, paymentDay: 10, balance: 12000000, limit: 50000000)];
    if (loans.isEmpty) loans = [Loan(name: 'Khoản vay A', amount: 20000000, monthly: 1800000, term: 12, paid: 5, paymentDay: 10)];
    ready = true;
    notifyListeners();
  }

  Future<void> save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('projects', jsonEncode(projects.map((e) => e.toJson()).toList()));
    await prefs.setString('cards', jsonEncode(cards.map((e) => e.toJson()).toList()));
    await prefs.setString('loans', jsonEncode(loans.map((e) => e.toJson()).toList()));
    notifyListeners();
  }
}

class MrCuongApp extends StatefulWidget {
  const MrCuongApp({super.key});
  @override State<MrCuongApp> createState() => _MrCuongAppState();
}
class _MrCuongAppState extends State<MrCuongApp> {
  final data = AppData();
  @override void initState() { super.initState(); data.load(); }
  @override void dispose() { data.dispose(); super.dispose(); }
  @override Widget build(BuildContext context) => AnimatedBuilder(
    animation: data,
    builder: (context, _) => MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Mr Cuog',
      theme: ThemeData(useMaterial3: true, colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xff1769e0)), scaffoldBackgroundColor: const Color(0xfff7f8fa)),
      home: data.ready ? HomePage(data: data) : const LoadingPage(),
    ),
  );
}
class LoadingPage extends StatelessWidget { const LoadingPage({super.key}); @override Widget build(BuildContext context) => const Scaffold(body: Center(child: CircularProgressIndicator())); }

class HomePage extends StatefulWidget {
  final AppData data;
  const HomePage({super.key, required this.data});
  @override State<HomePage> createState() => _HomePageState();
}
class _HomePageState extends State<HomePage> {
  int tab = 0;
  @override Widget build(BuildContext context) {
    final pages = [DashboardPage(data: widget.data), WorkPage(data: widget.data), PersonalPage(data: widget.data)];
    return Scaffold(
      body: SafeArea(child: pages[tab]),
      bottomNavigationBar: NavigationBar(selectedIndex: tab, onDestinationSelected: (i) => setState(() => tab = i), destinations: const [
        NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'Trang chủ'),
        NavigationDestination(icon: Icon(Icons.checklist_outlined), selectedIcon: Icon(Icons.checklist), label: 'Công việc'),
        NavigationDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person), label: 'Cá nhân'),
      ]),
    );
  }
}

class DashboardPage extends StatelessWidget {
  final AppData data;
  const DashboardPage({super.key, required this.data});
  @override Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.all(18),
    children: [
      const Text('Trang chủ', style: TextStyle(fontSize: 27, fontWeight: FontWeight.w800)),
      const SizedBox(height: 18),
      const Text('Hôm nay', style: TextStyle(color: Color(0xff1769e0), fontWeight: FontWeight.w800)),
      const SizedBox(height: 8),
      Card(child: Padding(padding: const EdgeInsets.all(14), child: Column(children: const [
        ReminderRow(time: '09:00', title: 'Công việc cần làm'), Divider(), ReminderRow(time: '14:00', title: 'Theo dõi tiến độ'), Divider(), ReminderRow(time: '20:00', title: 'Kiểm tra thanh toán')
      ]))),
      const SizedBox(height: 18),
      const Text('Công việc', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
      ...data.projects.map((p) => ProjectCard(project: p, onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ProjectPage(data: data, project: p))))),
      const SizedBox(height: 14),
      const Text('Cá nhân', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
      Row(children: [Expanded(child: SummaryCard(icon: Icons.credit_card, title: 'Thẻ tín dụng', value: '${data.cards.length} thẻ')), const SizedBox(width: 10), Expanded(child: SummaryCard(icon: Icons.account_balance, title: 'Khoản vay', value: '${data.loans.length} khoản'))]),
    ],
  );
}
class ReminderRow extends StatelessWidget { final String time, title; const ReminderRow({super.key, required this.time, required this.title}); @override Widget build(BuildContext context) => Row(children: [SizedBox(width: 55, child: Text(time, style: const TextStyle(color: Colors.red, fontWeight: FontWeight.w800))), Expanded(child: Text(title, style: const TextStyle(fontWeight: FontWeight.w600))), const Icon(Icons.chevron_right, size: 20)]); }
class SummaryCard extends StatelessWidget { final IconData icon; final String title, value; const SummaryCard({super.key, required this.icon, required this.title, required this.value}); @override Widget build(BuildContext context) => Card(child: Padding(padding: const EdgeInsets.all(15), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Icon(icon, color: const Color(0xff5d48d9)), const SizedBox(height: 8), Text(title, style: const TextStyle(fontWeight: FontWeight.w700)), Text(value, style: const TextStyle(color: Colors.black54))]))); }

class ProjectCard extends StatelessWidget {
  final Project project; final VoidCallback onTap;
  const ProjectCard({super.key, required this.project, required this.onTap});
  @override Widget build(BuildContext context) => Card(child: InkWell(onTap: onTap, borderRadius: BorderRadius.circular(12), child: Padding(padding: const EdgeInsets.all(14), child: Column(children: [
    Row(children: [const Icon(Icons.folder_rounded, color: Color(0xff1769e0)), const SizedBox(width: 10), Expanded(child: Text(project.name, style: const TextStyle(fontWeight: FontWeight.w800))), Text('${(project.progress * 100).round()}%')]),
    const SizedBox(height: 8), LinearProgressIndicator(value: project.progress, minHeight: 5), const SizedBox(height: 5), Align(alignment: Alignment.centerLeft, child: Text('${project.completed}/${project.tasks.length} nhiệm vụ', style: const TextStyle(fontSize: 11, color: Colors.black54)))
  ]))));
}

class WorkPage extends StatelessWidget {
  final AppData data; const WorkPage({super.key, required this.data});
  Future<void> addProject(BuildContext context) async { final name = await textDialog(context, 'Tạo dự án'); if (name != null && name.isNotEmpty) { data.projects.add(Project(name)); await data.save(); } }
  @override Widget build(BuildContext context) => Scaffold(
    backgroundColor: Colors.transparent,
    appBar: AppBar(title: const Text('Công việc', style: TextStyle(fontWeight: FontWeight.w800)), actions: [IconButton(onPressed: () => addProject(context), icon: const Icon(Icons.add, color: Color(0xff1769e0)))]),
    body: ListView(padding: const EdgeInsets.all(12), children: data.projects.map((p) => ProjectCard(project: p, onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ProjectPage(data: data, project: p)))).toList()),
  );
}

class ProjectPage extends StatefulWidget {
  final AppData data; final Project project;
  const ProjectPage({super.key, required this.data, required this.project});
  @override State<ProjectPage> createState() => _ProjectPageState();
}
class _ProjectPageState extends State<ProjectPage> {
  Future<void> addTask() async { final name = await textDialog(context, 'Thêm nhiệm vụ'); if (name != null && name.isNotEmpty) { widget.project.tasks.add(Task(name)); await widget.data.save(); setState(() {}); } }
  @override Widget build(BuildContext context) {
    final p = widget.project;
    return Scaffold(
      appBar: AppBar(title: Text(p.name, style: const TextStyle(fontWeight: FontWeight.w800)), actions: [IconButton(onPressed: addTask, icon: const Icon(Icons.add))]),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        Container(padding: const EdgeInsets.all(18), decoration: BoxDecoration(color: const Color(0xff3478e8), borderRadius: BorderRadius.circular(16)), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(p.name, style: const TextStyle(color: Colors.white, fontSize: 21, fontWeight: FontWeight.w800)), Text('${p.completed}/${p.tasks.length} nhiệm vụ hoàn thành', style: const TextStyle(color: Colors.white70)), const SizedBox(height: 10), LinearProgressIndicator(value: p.progress, minHeight: 7), const SizedBox(height: 6), Text('${(p.progress * 100).round()}%', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800))]),),
        const SizedBox(height: 15),
        ...p.tasks.map((task) => Card(child: CheckboxListTile(value: task.done, onChanged: (_) async { setState(() => task.done = !task.done); await widget.data.save(); }, title: Text(task.title, style: TextStyle(decoration: task.done ? TextDecoration.lineThrough : null, fontWeight: FontWeight.w600)))))
      ]),
    );
  }
}

class PersonalPage extends StatelessWidget {
  final AppData data; const PersonalPage({super.key, required this.data});
  @override Widget build(BuildContext context) => DefaultTabController(length: 2, child: Scaffold(
    backgroundColor: Colors.transparent,
    appBar: AppBar(title: const Text('Cá nhân', style: TextStyle(fontWeight: FontWeight.w800)), bottom: const TabBar(tabs: [Tab(text: 'Thẻ tín dụng'), Tab(text: 'Khoản vay')])),
    body: TabBarView(children: [ListView(padding: const EdgeInsets.all(12), children: data.cards.map((c) => CreditCardTile(card: c)).toList()), ListView(padding: const EdgeInsets.all(12), children: data.loans.map((l) => LoanTile(loan: l)).toList())]),
  ));
}
class CreditCardTile extends StatelessWidget { final CardData card; const CreditCardTile({super.key, required this.card}); @override Widget build(BuildContext context) { final ratio = card.limit <= 0 ? 0.0 : (card.balance / card.limit).clamp(0.0, 1.0); return Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Row(children: [const Icon(Icons.credit_card, color: Color(0xff5d48d9)), const SizedBox(width: 10), Expanded(child: Text(card.bank, style: const TextStyle(fontWeight: FontWeight.w800))), Text('**** ${card.last4}')]), const SizedBox(height: 14), Text('Ngày sao kê: ${card.statementDay} hàng tháng'), Text('Ngày thanh toán: ${card.paymentDay} hàng tháng'), const SizedBox(height: 10), LinearProgressIndicator(value: ratio), const SizedBox(height: 7), Text('Dư hiện tại: ${money(card.balance)}', style: const TextStyle(fontWeight: FontWeight.w700))]))); } }
class LoanTile extends StatelessWidget { final Loan loan; const LoanTile({super.key, required this.loan}); @override Widget build(BuildContext context) { final ratio = loan.term <= 0 ? 0.0 : (loan.paid / loan.term).clamp(0.0, 1.0); return Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Row(children: [const Icon(Icons.account_balance, color: Color(0xff1769e0)), const SizedBox(width: 10), Expanded(child: Text(loan.name, style: const TextStyle(fontWeight: FontWeight.w800)))]), const SizedBox(height: 12), Text('Số tiền vay: ${money(loan.amount)}'), Text('Mỗi tháng: ${money(loan.monthly)}'), Text('Đã trả: ${loan.paid}/${loan.term} kỳ'), const SizedBox(height: 8), LinearProgressIndicator(value: ratio), const SizedBox(height: 8), Text('Kỳ tới: ngày ${loan.paymentDay}', style: const TextStyle(fontWeight: FontWeight.w700))]))); } }

Future<String?> textDialog(BuildContext context, String title) async {
  final controller = TextEditingController();
  final result = await showDialog<String>(context: context, builder: (context) => AlertDialog(title: Text(title), content: TextField(controller: controller, autofocus: true, decoration: const InputDecoration(labelText: 'Tên')), actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Hủy')), FilledButton(onPressed: () => Navigator.pop(context, controller.text.trim()), child: const Text('Lưu'))]));
  controller.dispose();
  return result;
}
String money(double value) { final n = value.round().toString(); final buffer = StringBuffer(); for (var i = 0; i < n.length; i++) { if (i > 0 && (n.length - i) % 3 == 0) buffer.write('.'); buffer.write(n[i]); } return '${buffer.toString()} đ'; }
