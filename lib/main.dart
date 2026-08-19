import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() { WidgetsFlutterBinding.ensureInitialized(); runApp(const MrCuongApp()); }

class Task {
  String title; bool done;
  Task(this.title, {this.done = false});
  Map<String,dynamic> toJson()=>{'title':title,'done':done};
  factory Task.fromJson(Map<String,dynamic> j)=>Task('${j['title'] ?? ''}',done:j['done']==true);
}
class Project {
  String name; List<Task> tasks;
  Project(this.name,[List<Task>? tasks]):tasks=tasks??[];
  int get completed=>tasks.where((e)=>e.done).length;
  double get progress=>tasks.isEmpty?0:completed/tasks.length;
  Map<String,dynamic> toJson()=>{'name':name,'tasks':tasks.map((e)=>e.toJson()).toList()};
  factory Project.fromJson(Map<String,dynamic> j)=>Project('${j['name'] ?? ''}',(j['tasks'] as List? ?? []).map((e)=>Task.fromJson(Map<String,dynamic>.from(e))).toList());
}
class CardData {
  String bank,last4; int statementDay,paymentDay; double balance,limit;
  CardData({required this.bank,required this.last4,required this.statementDay,required this.paymentDay,this.balance=0,this.limit=0});
  Map<String,dynamic> toJson()=>{'bank':bank,'last4':last4,'statementDay':statementDay,'paymentDay':paymentDay,'balance':balance,'limit':limit};
  factory CardData.fromJson(Map<String,dynamic> j)=>CardData(bank:'${j['bank']??''}',last4:'${j['last4']??''}',statementDay:(j['statementDay'] as num?)?.toInt()??1,paymentDay:(j['paymentDay'] as num?)?.toInt()??1,balance:(j['balance'] as num?)?.toDouble()??0,limit:(j['limit'] as num?)?.toDouble()??0);
}
class Loan {
  String name; double amount,monthly; int term,paid,paymentDay;
  Loan({required this.name,required this.amount,required this.monthly,required this.term,required this.paid,required this.paymentDay});
  Map<String,dynamic> toJson()=>{'name':name,'amount':amount,'monthly':monthly,'term':term,'paid':paid,'paymentDay':paymentDay};
  factory Loan.fromJson(Map<String,dynamic> j)=>Loan(name:'${j['name']??''}',amount:(j['amount'] as num?)?.toDouble()??0,monthly:(j['monthly'] as num?)?.toDouble()??0,term:(j['term'] as num?)?.toInt()??0,paid:(j['paid'] as num?)?.toInt()??0,paymentDay:(j['paymentDay'] as num?)?.toInt()??1);
}
class AppData extends ChangeNotifier {
  List<Project> projects=[]; List<CardData> cards=[]; List<Loan> loans=[]; bool ready=false;
  Future<void> load() async {
    try {
      final p=await SharedPreferences.getInstance();
      final ps=p.getString('projects'),cs=p.getString('cards'),ls=p.getString('loans');
      if(ps!=null) projects=(jsonDecode(ps) as List).map((e)=>Project.fromJson(Map<String,dynamic>.from(e))).toList();
      if(cs!=null) cards=(jsonDecode(cs) as List).map((e)=>CardData.fromJson(Map<String,dynamic>.from(e))).toList();
      if(ls!=null) loans=(jsonDecode(ls) as List).map((e)=>Loan.fromJson(Map<String,dynamic>.from(e))).toList();
    } catch (_) {}
    if(projects.isEmpty) projects=[Project('DVCI Đà Lạt',[Task('Lập kế hoạch',done:true),Task('Theo dõi tiến độ'),Task('Đăng hồ sơ'),Task('Kiểm tra kết quả'),Task('Ký hợp đồng')])];
    if(cards.isEmpty) cards=[CardData(bank:'VPBank',last4:'1234',statementDay:15,paymentDay:5,balance:25000000,limit:100000000)];
    if(loans.isEmpty) loans=[Loan(name:'Khoản vay A',amount:20000000,monthly:1800000,term:12,paid:5,paymentDay:10)];
    ready=true; notifyListeners();
  }
  Future<void> save() async { final p=await SharedPreferences.getInstance(); await p.setString('projects',jsonEncode(projects.map((e)=>e.toJson()).toList())); await p.setString('cards',jsonEncode(cards.map((e)=>e.toJson()).toList())); await p.setString('loans',jsonEncode(loans.map((e)=>e.toJson()).toList())); notifyListeners(); }
}
class MrCuongApp extends StatefulWidget { const MrCuongApp({super.key}); @override State<MrCuongApp> createState()=>_MrCuongAppState(); }
class _MrCuongAppState extends State<MrCuongApp> {
  final data=AppData(); @override void initState(){super.initState();data.load();} @override void dispose(){data.dispose();super.dispose();}
  @override Widget build(BuildContext context)=>AnimatedBuilder(animation:data,builder:(_,__)=>MaterialApp(debugShowCheckedModeBanner:false,title:'Mr Cuog',theme:ThemeData(useMaterial3:true,colorScheme:ColorScheme.fromSeed(seedColor:const Color(0xff1769e0)),scaffoldBackgroundColor:const Color(0xfff7f8fa)),home:data.ready?HomePage(data:data):const Scaffold(body:Center(child:CircularProgressIndicator()))));
}
class HomePage extends StatefulWidget { final AppData data; const HomePage({super.key,required this.data}); @override State<HomePage> createState()=>_HomePageState(); }
class _HomePageState extends State<HomePage> { int tab=0; @override Widget build(BuildContext context){ final pages=[DashboardPage(data:widget.data),WorkPage(data:widget.data),PersonalPage(data:widget.data)]; return Scaffold(body:SafeArea(child:pages[tab]),bottomNavigationBar:NavigationBar(selectedIndex:tab,onDestinationSelected:(i)=>setState(()=>tab=i),destinations:const [NavigationDestination(icon:Icon(Icons.home_outlined),selectedIcon:Icon(Icons.home),label:'Trang chủ'),NavigationDestination(icon:Icon(Icons.checklist_outlined),selectedIcon:Icon(Icons.checklist),label:'Công việc'),NavigationDestination(icon:Icon(Icons.person_outline),selectedIcon:Icon(Icons.person),label:'Cá nhân')])); } }
class DashboardPage extends StatelessWidget { final AppData data; const DashboardPage({super.key,required this.data}); @override Widget build(BuildContext context)=>ListView(padding:const EdgeInsets.all(18),children:[const Text('Mr Cuog',style:TextStyle(fontSize:28,fontWeight:FontWeight.w800)),const SizedBox(height:5),const Text('Quản lý công việc và cá nhân'),const SizedBox(height:20),const Text('Công việc',style:TextStyle(fontSize:18,fontWeight:FontWeight.w800)),...data.projects.map((p)=>ProjectCard(project:p,onTap:()=>Navigator.push(context,MaterialPageRoute(builder:(_)=>ProjectPage(data:data,project:p))))),const SizedBox(height:15),const Text('Cá nhân',style:TextStyle(fontSize:18,fontWeight:FontWeight.w800)),Row(children:[Expanded(child:InfoCard(icon:Icons.credit_card,title:'Thẻ tín dụng',value:'${data.cards.length} thẻ')),const SizedBox(width:10),Expanded(child:InfoCard(icon:Icons.account_balance,title:'Khoản vay',value:'${data.loans.length} khoản'))])]); }
class InfoCard extends StatelessWidget { final IconData icon; final String title,value; const InfoCard({super.key,required this.icon,required this.title,required this.value}); @override Widget build(BuildContext context)=>Card(child:Padding(padding:const EdgeInsets.all(15),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Icon(icon),const SizedBox(height:8),Text(title,style:const TextStyle(fontWeight:FontWeight.w700)),Text(value,style:const TextStyle(color:Colors.black54))]))); }
class ProjectCard extends StatelessWidget { final Project project; final VoidCallback onTap; const ProjectCard({super.key,required this.project,required this.onTap}); @override Widget build(BuildContext context)=>Card(child:InkWell(onTap:onTap,borderRadius:BorderRadius.circular(12),child:Padding(padding:const EdgeInsets.all(14),child:Column(children:[Row(children:[const Icon(Icons.folder_rounded),const SizedBox(width:10),Expanded(child:Text(project.name,style:const TextStyle(fontWeight:FontWeight.w800))),Text('${(project.progress*100).round()}%')]),const SizedBox(height:8),LinearProgressIndicator(value:project.progress),const SizedBox(height:5),Align(alignment:Alignment.centerLeft,child:Text('${project.completed}/${project.tasks.length} nhiệm vụ',style:const TextStyle(fontSize:11,color:Colors.black54))) ])))); }
class WorkPage extends StatelessWidget { final AppData data; const WorkPage({super.key,required this.data}); Future<void> add(BuildContext c)async{final n=await textDialog(c,'Tạo dự án');if(n!=null&&n.trim().isNotEmpty){data.projects.add(Project(n.trim()));await data.save();}} @override Widget build(BuildContext context)=>Scaffold(appBar:AppBar(title:const Text('Công việc',style:TextStyle(fontWeight:FontWeight.w800)),actions:[IconButton(onPressed:()=>add(context),icon:const Icon(Icons.add))]),body:ListView(padding:const EdgeInsets.all(12),children:data.projects.map((p)=>ProjectCard(project:p,onTap:()=>Navigator.push(context,MaterialPageRoute(builder:(_)=>ProjectPage(data:data,project:p)))).toList())); }
class ProjectPage extends StatefulWidget { final AppData data; final Project project; const ProjectPage({super.key,required this.data,required this.project}); @override State<ProjectPage> createState()=>_ProjectPageState(); }
class _ProjectPageState extends State<ProjectPage> { Future<void> addTask()async{final n=await textDialog(context,'Thêm nhiệm vụ');if(n!=null&&n.trim().isNotEmpty){widget.project.tasks.add(Task(n.trim()));await widget.data.save();setState((){});}} @override Widget build(BuildContext context){final p=widget.project;return Scaffold(appBar:AppBar(title:Text(p.name),actions:[IconButton(onPressed:addTask,icon:const Icon(Icons.add))]),body:ListView(padding:const EdgeInsets.all(16),children:[Card(child:Padding(padding:const EdgeInsets.all(18),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text(p.name,style:const TextStyle(fontSize:21,fontWeight:FontWeight.w800)),Text('${p.completed}/${p.tasks.length} nhiệm vụ hoàn thành'),const SizedBox(height:10),LinearProgressIndicator(value:p.progress),const SizedBox(height:5),Text('${(p.progress*100).round()}%')])),const SizedBox(height:12),...p.tasks.map((t)=>Card(child:CheckboxListTile(value:t.done,onChanged:(_)async{setState(()=>t.done=!t.done);await widget.data.save();},title:Text(t.title,style:TextStyle(decoration:t.done?TextDecoration.lineThrough:null)))))]);}}
class PersonalPage extends StatelessWidget { final AppData data; const PersonalPage({super.key,required this.data}); @override Widget build(BuildContext context)=>DefaultTabController(length:2,child:Scaffold(appBar:AppBar(title:const Text('Cá nhân',style:TextStyle(fontWeight:FontWeight.w800)),bottom:const TabBar(tabs:[Tab(text:'Thẻ tín dụng'),Tab(text:'Khoản vay')])),body:TabBarView(children:[ListView(padding:const EdgeInsets.all(12),children:data.cards.map((c)=>Card(child:ListTile(leading:const Icon(Icons.credit_card),title:Text('${c.bank}  ****${c.last4}'),subtitle:Text('Sao kê: ngày ${c.statementDay} • Thanh toán: ngày ${c.paymentDay}\nDư: ${money(c.balance)}'))).toList()),ListView(padding:const EdgeInsets.all(12),children:data.loans.map((l)=>Card(child:ListTile(leading:const Icon(Icons.account_balance),title:Text(l.name),subtitle:Text('Trả ${money(l.monthly)}/tháng • ${l.paid}/${l.term} kỳ • Ngày ${l.paymentDay}'))).toList())])); }
Future<String?> textDialog(BuildContext context,String title)async{final c=TextEditingController();return showDialog<String>(context:context,builder:(ctx)=>AlertDialog(title:Text(title),content:TextField(controller:c,autofocus:true,decoration:const InputDecoration(hintText:'Nhập tên')),actions:[TextButton(onPressed:()=>Navigator.pop(ctx),child:const Text('Hủy')),FilledButton(onPressed:()=>Navigator.pop(ctx,c.text),child:const Text('Lưu'))]));}
String money(double v){final s=v.round().toString();final b=StringBuffer();for(var i=0;i<s.length;i++){if(i>0&&(s.length-i)%3==0)b.write('.');b.write(s[i]);}return '${b.toString()} đ';}
