import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  final store = Store();
  runApp(App(store));
  // Cho Flutter render frame đầu tiên trước khi đọc dữ liệu nền.
  Timer(const Duration(milliseconds: 150), store.load);
}

class Task {
  String title; bool done;
  Task(this.title, {this.done = false});
  Map<String, dynamic> j() => {'title': title, 'done': done};
  factory Task.f(Map<String, dynamic> j) => Task(j['title'] as String, done: j['done'] ?? false);
}

class Project {
  String name; List<Task> tasks;
  Project(this.name, [this.tasks = const []]);
  int get done => tasks.where((e) => e.done).length;
  Map<String, dynamic> j() => {'name': name, 'tasks': tasks.map((e) => e.j()).toList()};
  factory Project.f(Map<String, dynamic> j) => Project(j['name'] as String, (j['tasks'] as List).map((e) => Task.f(Map<String, dynamic>.from(e))).toList());
}

class CardData {
  String bank, last4; int statement, payment; double balance, limit;
  CardData(this.bank, this.last4, this.statement, this.payment, {this.balance = 0, this.limit = 0});
  Map<String, dynamic> j() => {'bank': bank, 'last4': last4, 'statement': statement, 'payment': payment, 'balance': balance, 'limit': limit};
  factory CardData.f(Map<String, dynamic> j) => CardData(j['bank'] as String, j['last4'] as String, j['statement'] as int, j['payment'] as int, balance: (j['balance'] ?? 0).toDouble(), limit: (j['limit'] ?? 0).toDouble());
}

class Loan {
  String name; double amount, monthly; int term, paid, payment;
  Loan(this.name, this.amount, this.monthly, this.term, this.paid, this.payment);
  Map<String, dynamic> j() => {'name': name, 'amount': amount, 'monthly': monthly, 'term': term, 'paid': paid, 'payment': payment};
  factory Loan.f(Map<String, dynamic> j) => Loan(j['name'] as String, (j['amount'] ?? 0).toDouble(), (j['monthly'] ?? 0).toDouble(), j['term'] as int, j['paid'] as int, j['payment'] as int);
}

class Store extends ChangeNotifier {
  List<Project> projects = []; List<CardData> cards = []; List<Loan> loans = [];
  Future<void> load() async {
    try {
      final p = await SharedPreferences.getInstance();
      final a = p.getString('projects'), b = p.getString('cards'), d = p.getString('loans');
      if (a != null) projects = (jsonDecode(a) as List).map((e) => Project.f(Map<String, dynamic>.from(e))).toList();
      if (b != null) cards = (jsonDecode(b) as List).map((e) => CardData.f(Map<String, dynamic>.from(e))).toList();
      if (d != null) loans = (jsonDecode(d) as List).map((e) => Loan.f(Map<String, dynamic>.from(e))).toList();
    } catch (_) {}
    if (projects.isEmpty) projects = [Project('DVCI Đà Lạt', [Task('Lập kế hoạch', done: true), Task('Theo dõi tiến độ'), Task('Đăng hồ sơ'), Task('Kiểm tra kết quả'), Task('Ký hợp đồng')])];
    if (cards.isEmpty) cards = [CardData('VPBank', '1234', 15, 5, balance: 25000000, limit: 100000000), CardData('Techcombank', '5678', 20, 10, balance: 12000000, limit: 50000000)];
    if (loans.isEmpty) loans = [Loan('Khoản vay A', 20000000, 1800000, 12, 5, 10)];
    notifyListeners();
  }
  Future<void> save() async {
    final p = await SharedPreferences.getInstance();
    await p.setString('projects', jsonEncode(projects.map((e) => e.j()).toList()));
    await p.setString('cards', jsonEncode(cards.map((e) => e.j()).toList()));
    await p.setString('loans', jsonEncode(loans.map((e) => e.j()).toList()));
    notifyListeners();
  }
}

class App extends StatelessWidget {
  final Store s; const App(this.s, {super.key});
  @override Widget build(BuildContext c) => AnimatedBuilder(animation: s, builder: (_, __) => MaterialApp(debugShowCheckedModeBanner: false, title: 'Mr Cuog', theme: ThemeData(useMaterial3: true, colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xff1769e0)), scaffoldBackgroundColor: const Color(0xfff7f8fa)), home: Home(s)));
}

class Home extends StatefulWidget { final Store s; const Home(this.s, {super.key}); @override State<Home> createState() => _HomeState(); }
class _HomeState extends State<Home> {
  int tab = 0;
  @override Widget build(BuildContext c) {
    final p = [Dash(widget.s), Work(widget.s), Personal(widget.s)];
    return Scaffold(body: SafeArea(child: p[tab]), bottomNavigationBar: NavigationBar(selectedIndex: tab, onDestinationSelected: (i) => setState(() => tab = i), destinations: const [NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'Trang chủ'), NavigationDestination(icon: Icon(Icons.checklist_outlined), selectedIcon: Icon(Icons.checklist), label: 'Công việc'), NavigationDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person), label: 'Cá nhân')]));
  }
}

class Dash extends StatelessWidget {
  final Store s; const Dash(this.s, {super.key});
  @override Widget build(BuildContext c) => ListView(padding: const EdgeInsets.all(18), children: [const Text('Trang chủ', style: TextStyle(fontSize: 27, fontWeight: FontWeight.w800)), const SizedBox(height: 18), const Text('Hôm nay', style: TextStyle(color: Color(0xff1769e0), fontWeight: FontWeight.w800)), const SizedBox(height: 8), Card(child: Padding(padding: const EdgeInsets.all(14), child: Column(children: const [_R('09:00', 'Công việc cần làm'), Divider(), _R('14:00', 'Theo dõi tiến độ'), Divider(), _R('20:00', 'Kiểm tra thanh toán')]))), const SizedBox(height: 18), const Text('Công việc', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)), ...s.projects.map((p) => PC(p, () => Navigator.push(c, MaterialPageRoute(builder: (_) => ProjectPage(s, p))))), const SizedBox(height: 14), const Text('Cá nhân', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)), Row(children: [Expanded(child: SC(Icons.credit_card, 'Thẻ tín dụng', '${s.cards.length} thẻ')), const SizedBox(width: 10), Expanded(child: SC(Icons.account_balance, 'Khoản vay', '${s.loans.length} khoản'))])]);
}

class _R extends StatelessWidget { final String a, b; const _R(this.a, this.b); @override Widget build(BuildContext c) => Row(children: [SizedBox(width: 55, child: Text(a, style: const TextStyle(color: Colors.red, fontWeight: FontWeight.w800))), Expanded(child: Text(b, style: const TextStyle(fontWeight: FontWeight.w600))), const Icon(Icons.chevron_right, size: 20)]); }
class SC extends StatelessWidget { final IconData i; final String a, b; const SC(this.i, this.a, this.b); @override Widget build(BuildContext c) => Card(child: Padding(padding: const EdgeInsets.all(15), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Icon(i, color: const Color(0xff5d48d9)), const SizedBox(height: 8), Text(a, style: const TextStyle(fontWeight: FontWeight.w700)), Text(b, style: const TextStyle(color: Colors.black54))]))); }

class PC extends StatelessWidget {
  final Project p; final VoidCallback tap; const PC(this.p, this.tap, {super.key});
  @override Widget build(BuildContext c) { final x = p.tasks.isEmpty ? 0.0 : p.done / p.tasks.length; return Card(child: InkWell(onTap: tap, child: Padding(padding: const EdgeInsets.all(14), child: Column(children: [Row(children: [const Icon(Icons.folder_rounded, color: Color(0xff1769e0)), const SizedBox(width: 10), Expanded(child: Text(p.name, style: const TextStyle(fontWeight: FontWeight.w800))), Text('${(x * 100).round()}%')]), const SizedBox(height: 8), LinearProgressIndicator(value: x, minHeight: 5), const SizedBox(height: 5), Align(alignment: Alignment.centerLeft, child: Text('${p.done}/${p.tasks.length} nhiệm vụ', style: const TextStyle(fontSize: 11, color: Colors.black54)))]))); }
}

class Work extends StatelessWidget {
  final Store s; const Work(this.s, {super.key});
  @override Widget build(BuildContext c) => Scaffold(backgroundColor: Colors.transparent, appBar: AppBar(title: const Text('Công việc', style: TextStyle(fontWeight: FontWeight.w800)), actions: [IconButton(onPressed: () async { final n = await dlg(c, 'Tạo dự án'); if (n?.isNotEmpty ?? false) { s.projects.add(Project(n!)); await s.save(); } }, icon: const Icon(Icons.add, color: Color(0xff1769e0)))]), body: ListView(padding: const EdgeInsets.all(12), children: s.projects.map((p) => PC(p, () => Navigator.push(c, MaterialPageRoute(builder: (_) => ProjectPage(s, p))))).toList()));
}

class ProjectPage extends StatefulWidget { final Store s; final Project p; const ProjectPage(this.s, this.p, {super.key}); @override State<ProjectPage> createState() => _ProjectState(); }
class _ProjectState extends State<ProjectPage> {
  @override Widget build(BuildContext c) { final p = widget.p; final x = p.tasks.isEmpty ? 0.0 : p.done / p.tasks.length; return Scaffold(appBar: AppBar(title: Text(p.name, style: const TextStyle(fontWeight: FontWeight.w800)), actions: [IconButton(onPressed: () async { final n = await dlg(c, 'Thêm nhiệm vụ'); if (n?.isNotEmpty ?? false) { p.tasks.add(Task(n!)); await widget.s.save(); setState(() {}); } }, icon: const Icon(Icons.add))]), body: ListView(padding: const EdgeInsets.all(16), children: [Container(padding: const EdgeInsets.all(18), decoration: BoxDecoration(color: const Color(0xff3478e8), borderRadius: BorderRadius.circular(16)), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(p.name, style: const TextStyle(color: Colors.white, fontSize: 21, fontWeight: FontWeight.w800)), Text('${p.done}/${p.tasks.length} nhiệm vụ hoàn thành', style: const TextStyle(color: Colors.white70)), const SizedBox(height: 10), LinearProgressIndicator(value: x, minHeight: 7), const SizedBox(height: 6), Text('${(x * 100).round()}%', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800))]),), const SizedBox(height: 15), ...p.tasks.map((t) => Card(child: CheckboxListTile(value: t.done, onChanged: (_) async { t.done = !t.done; await widget.s.save(); setState(() {}); }, title: Text(t.title, style: TextStyle(decoration: t.done ? TextDecoration.lineThrough : null, fontWeight: FontWeight.w600))))]); }
}

class Personal extends StatelessWidget { final Store s; const Personal(this.s, {super.key}); @override Widget build(BuildContext c) => DefaultTabController(length: 2, child: Scaffold(backgroundColor: Colors.transparent, appBar: AppBar(title: const Text('Cá nhân', style: TextStyle(fontWeight: FontWeight.w800)), bottom: const TabBar(tabs: [Tab(text: 'Thẻ tín dụng'), Tab(text: 'Khoản vay')])), body: TabBarView(children: [ListView(padding: const EdgeInsets.all(12), children: s.cards.map((x) => CardTile(x)).toList()), ListView(padding: const EdgeInsets.all(12), children: s.loans.map((x) => LoanTile(x)).toList())])); }
class CardTile extends StatelessWidget { final CardData x; const CardTile(this.x); @override Widget build(BuildContext c) => Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Row(children: [const Icon(Icons.credit_card, color: Color(0xff5d48d9)), const SizedBox(width: 10), Expanded(child: Text(x.bank, style: const TextStyle(fontWeight: FontWeight.w800))), Text('**** ${x.last4}')]), const SizedBox(height: 14), Text('Ngày sao kê: ${x.statement} hàng tháng'), Text('Ngày thanh toán: ${x.payment} hàng tháng'), const SizedBox(height: 10), LinearProgressIndicator(value: x.limit == 0 ? 0 : (x.balance / x.limit).clamp(0, 1)), const SizedBox(height: 7), Text('Dư hiện tại: ${money(x.balance)}', style: const TextStyle(fontWeight: FontWeight.w700))]))); }
class LoanTile extends StatelessWidget { final Loan x; const LoanTile(this.x); @override Widget build(BuildContext c) => Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Row(children: [const Icon(Icons.account_balance, color: Color(0xff1769e0)), const SizedBox(width: 10), Expanded(child: Text(x.name, style: const TextStyle(fontWeight: FontWeight.w800)))]), const SizedBox(height: 12), Text('Số tiền vay: ${money(x.amount)}'), Text('Mỗi tháng: ${money(x.monthly)}'), Text('Đã trả: ${x.paid}/${x.term} kỳ'), const SizedBox(height: 8), LinearProgressIndicator(value: x.term == 0 ? 0 : x.paid / x.term), const SizedBox(height: 8), Text('Kỳ tới: ngày ${x.payment}', style: const TextStyle(fontWeight: FontWeight.w700))]))); }

Future<String?> dlg(BuildContext c, String title) async { final t = TextEditingController(); return showDialog<String>(context: c, builder: (_) => AlertDialog(title: Text(title), content: TextField(controller: t, autofocus: true, decoration: const InputDecoration(labelText: 'Tên')), actions: [TextButton(onPressed: () => Navigator.pop(c), child: const Text('Hủy')), FilledButton(onPressed: () => Navigator.pop(c, t.text.trim()), child: const Text('Lưu'))])); }
String money(double v) { final n = v.round().toString(); var r = ''; for (var i = 0; i < n.length; i++) { if (i > 0 && (n.length - i) % 3 == 0) r += '.'; r += n[i]; } return '$r đ'; }
