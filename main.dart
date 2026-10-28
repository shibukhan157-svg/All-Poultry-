import 'dart:async';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:webview_flutter/webview_flutter.dart';

// Configure these two values in lib/main.dart before building the app.
const supabaseUrl = 'https://jpwqitycnmabavvxztir.supabase.co';
const supabaseAnonKey = 'sb_publishable_2MlcX44DKUglpAbGhZclog_BsPc_7Yp';
final supabaseConfigured = !supabaseUrl.startsWith('YOUR_') && !supabaseAnonKey.startsWith('YOUR_');

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (supabaseConfigured) {
    await Supabase.initialize(url: supabaseUrl, anonKey: supabaseAnonKey);
  }
  runApp(const BroilerFarmApp());
}

class AppPrefs {
  static bool english = false;
  static String t(String hi, String en) => english ? en : hi;
}

class BroilerFarmApp extends StatelessWidget {
  const BroilerFarmApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
    debugShowCheckedModeBanner: false,
    title: 'Broiler Farm Manager',
    theme: ThemeData(colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xff18794e)), useMaterial3: true),
    home: !supabaseConfigured ? const SetupScreen() : const AuthGate(),
  );
}

class SetupScreen extends StatelessWidget {
  const SetupScreen({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Broiler Farm Manager')),
    body: ListView(padding: const EdgeInsets.all(22), children: [
      const Icon(Icons.cloud_sync, size: 64, color: Color(0xff18794e)),
      const SizedBox(height: 12),
      Text(AppPrefs.t('क्लाउड सेटअप बाकी है', 'Cloud setup required'), style: Theme.of(context).textTheme.headlineSmall),
      const SizedBox(height: 12),
      Text(AppPrefs.t('ऐप को कई मोबाइल पर एक ही डेटा के साथ चलाने के लिए Supabase प्रोजेक्ट बनाएं। फिर lib/main.dart में YOUR_SUPABASE_PROJECT_URL और YOUR_SUPABASE_ANON_KEY बदलें।', 'Create a Supabase project for multi-device sync. Replace YOUR_SUPABASE_PROJECT_URL and YOUR_SUPABASE_ANON_KEY in lib/main.dart with your project URL and anon key.')),
      const SizedBox(height: 12),
      const Text('1. Supabase SQL Editor में supabase/schema.sql चलाएं.\n2. Authentication → Providers में Email enabled करें.\n3. Project URL और anon/publishable key डालें.\n4. flutter pub get और flutter run चलाएं.'),
      const SizedBox(height: 16),
      OutlinedButton.icon(onPressed: () => AppPrefs.english = !AppPrefs.english, icon: const Icon(Icons.language), label: const Text('हिंदी / English')),
    ]),
  );
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});
  @override
  Widget build(BuildContext context) => StreamBuilder<AuthState>(
    stream: Supabase.instance.client.auth.onAuthStateChange,
    builder: (context, snapshot) => Supabase.instance.client.auth.currentSession == null
      ? const LoginScreen() : const HomeScreen(),
  );
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override State<LoginScreen> createState() => _LoginScreenState();
}
class _LoginScreenState extends State<LoginScreen> {
  final email = TextEditingController(), password = TextEditingController(), name = TextEditingController();
  bool signup = false, busy = false;
  String message = '';
  Future<void> submit() async {
    setState(() { busy = true; message = ''; });
    try {
      final auth = Supabase.instance.client.auth;
      if (signup) {
        final result = await auth.signUp(email: email.text.trim(), password: password.text);
        if (result.user != null && result.session != null) {
          await Supabase.instance.client.from('users').insert({'id': result.user!.id, 'full_name': name.text.trim().isEmpty ? email.text.trim() : name.text.trim(), 'role': 'farmer', 'district': '', 'state': ''});
        }
        message = AppPrefs.t('अकाउंट बनाया गया। अगर ईमेल पुष्टि मांगी जाए तो ईमेल verify करके लॉगिन करें।', 'Account created. If email confirmation is required, verify your email and then log in.');
      } else {
        await auth.signInWithPassword(email: email.text.trim(), password: password.text);
      }
    } on AuthException catch (e) { message = e.message; }
      catch (e) { message = '$e'; }
    if (mounted) setState(() => busy = false);
  }
  @override
  Widget build(BuildContext context) => Scaffold(body: Center(child: SingleChildScrollView(padding: const EdgeInsets.all(24), child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 440), child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
    const Icon(Icons.agriculture, size: 68, color: Color(0xff18794e)),
    Text('Broiler Farm Manager', textAlign: TextAlign.center, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
    const SizedBox(height: 8), Text(AppPrefs.t('ऑनलाइन फार्म रिकॉर्ड • Multi-device Sync', 'Cloud farm records • Multi-device sync'), textAlign: TextAlign.center),
    const SizedBox(height: 24),
    if (signup) TextField(controller: name, decoration: InputDecoration(labelText: AppPrefs.t('पूरा नाम / Full name', 'Full name'), border: const OutlineInputBorder())),
    if (signup) const SizedBox(height: 12),
    TextField(controller: email, keyboardType: TextInputType.emailAddress, decoration: const InputDecoration(labelText: 'Email', border: OutlineInputBorder())),
    const SizedBox(height: 12), TextField(controller: password, obscureText: true, decoration: InputDecoration(labelText: AppPrefs.t('पासवर्ड / Password', 'Password'), border: const OutlineInputBorder())),
    const SizedBox(height: 16), FilledButton(onPressed: busy ? null : submit, child: Text(busy ? '...' : signup ? AppPrefs.t('अकाउंट बनाएं', 'Create account') : AppPrefs.t('लॉगिन', 'Log in'))),
    TextButton(onPressed: () => setState(() { signup = !signup; message = ''; }), child: Text(signup ? AppPrefs.t('पहले से अकाउंट है? लॉगिन', 'Already registered? Log in') : AppPrefs.t('नया अकाउंट बनाएं', 'Create a new account'))),
    TextButton(onPressed: () => setState(() => AppPrefs.english = !AppPrefs.english), child: const Text('हिंदी / English')),
    if (message.isNotEmpty) Padding(padding: const EdgeInsets.only(top: 8), child: Text(message, style: const TextStyle(color: Colors.deepOrange))),
  ])))));
}

class HomeScreen extends StatefulWidget { const HomeScreen({super.key}); @override State<HomeScreen> createState() => _HomeScreenState(); }
class _HomeScreenState extends State<HomeScreen> {
  int tab = 0;
  @override Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Broiler Farm Manager'), actions: [IconButton(tooltip: 'हिंदी / English', onPressed: () => setState(() => AppPrefs.english = !AppPrefs.english), icon: const Icon(Icons.language)), IconButton(tooltip: 'Logout', onPressed: () => Supabase.instance.client.auth.signOut(), icon: const Icon(Icons.logout))]),
    body: IndexedStack(index: tab, children: const [DashboardPage(), BatchesPage(), RatesPage(), ProfilePage()]),
    bottomNavigationBar: NavigationBar(selectedIndex: tab, onDestinationSelected: (v) => setState(() => tab = v), destinations: [
      NavigationDestination(icon: const Icon(Icons.dashboard_outlined), label: AppPrefs.t('डैशबोर्ड','Dashboard')),
      NavigationDestination(icon: const Icon(Icons.egg_alt_outlined), label: AppPrefs.t('बैच','Batches')),
      NavigationDestination(icon: const Icon(Icons.storefront_outlined), label: AppPrefs.t('मंडी रेट','Mandi rates')),
      NavigationDestination(icon: const Icon(Icons.person_outline), label: AppPrefs.t('प्रोफाइल','Profile')),
    ]),
  );
}

Future<List<Map<String, dynamic>>> queryRows(String table, String order) async {
  final data = await Supabase.instance.client.from(table).select().order(order, ascending: false);
  return List<Map<String, dynamic>>.from(data);
}
String dateToday() => DateTime.now().toIso8601String().substring(0, 10);
Future<void> showError(BuildContext context, Object e) async { if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e'))); }

class DashboardPage extends StatefulWidget { const DashboardPage({super.key}); @override State<DashboardPage> createState() => _DashboardPageState(); }
class _DashboardPageState extends State<DashboardPage> {
  late Future<List<Map<String, dynamic>>> batches, logs, rates;
  void reload() { batches = queryRows('broiler_batches','placement_date'); logs = queryRows('daily_logs','logged_at'); rates = queryRows('mandi_rates','date'); }
  @override void initState() { super.initState(); reload(); }
  @override Widget build(BuildContext context) => RefreshIndicator(onRefresh: () async => setState(reload), child: ListView(padding: const EdgeInsets.all(16), children: [
    Container(padding: const EdgeInsets.all(20), decoration: BoxDecoration(borderRadius: BorderRadius.circular(20), gradient: const LinearGradient(colors: [Color(0xff14532d), Color(0xff16a34a)])), child: Text(AppPrefs.t('नमस्ते किसान 👋\nआपके फार्म का पूरा हिसाब\nबैच • दाना • वजन • FCR • मंडी', 'Welcome 👋\nYour farm at a glance\nBatches • Feed • Weight • FCR • Market'), style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold))),
    const SizedBox(height: 12),
    FutureBuilder<List<dynamic>>(future: Future.wait([batches,logs,rates]), builder: (context,s) { if (!s.hasData) return const Center(child: Padding(padding: EdgeInsets.all(30), child: CircularProgressIndicator())); final bs=s.data![0] as List<Map<String,dynamic>>, ls=s.data![1] as List<Map<String,dynamic>>, rs=s.data![2] as List<Map<String,dynamic>>; final active=bs.where((b)=>b['is_active']==true).length; final deaths=ls.fold<int>(0,(a,l)=>a+((l['daily_mortality'] as num?)?.toInt()??0)); return Column(children: [GridView.count(shrinkWrap:true, physics:const NeverScrollableScrollPhysics(), crossAxisCount:2, childAspectRatio:1.5, children:[metric(AppPrefs.t('एक्टिव बैच','Active batches'),'$active',Icons.egg_alt),metric(AppPrefs.t('कुल चूजे','Placed chicks'),'${bs.fold<int>(0,(a,b)=>a+((b['chicks_placed'] as num?)?.toInt()??0))}',Icons.pets),metric(AppPrefs.t('कुल मृत्यु','Total mortality'),'$deaths',Icons.monitor_heart_outlined),metric(AppPrefs.t('दैनिक एंट्री','Daily logs'),'${ls.length}',Icons.edit_note)]), const SizedBox(height:8), Card(child:ListTile(leading:const Icon(Icons.currency_rupee), title:Text(AppPrefs.t('नवीनतम मंडी रेट','Latest mandi rate')), subtitle:Text(rs.isEmpty?AppPrefs.t('अभी कोई रेट नहीं','No rate entered yet'):'${rs.first['district']}, ${rs.first['state']} • ${rs.first['date']}'), trailing:Text(rs.isEmpty?'—':'₹${rs.first['broiler_rate_per_kg']}/kg')))]); }),
    const SizedBox(height:12), Text(AppPrefs.t('डेटा क्लाउड में सेव होता है और उसी अकाउंट से दूसरे मोबाइल पर भी उपलब्ध है।','Data is stored in the cloud and available on other devices using the same account.'), style: const TextStyle(color: Colors.grey)),
  ]));
}
Widget metric(String title,String value,IconData icon)=>Card(child:Padding(padding:const EdgeInsets.all(14),child:Column(crossAxisAlignment:CrossAxisAlignment.start,mainAxisAlignment:MainAxisAlignment.spaceBetween,children:[Icon(icon,color:const Color(0xff18794e)),Text(value,style:const TextStyle(fontSize:24,fontWeight:FontWeight.bold)),Text(title,style:const TextStyle(fontSize:12))])));

class BatchesPage extends StatefulWidget { const BatchesPage({super.key}); @override State<BatchesPage> createState()=>_BatchesPageState(); }
class _BatchesPageState extends State<BatchesPage> {
  late Future<List<Map<String,dynamic>>> future; void reload()=>future=queryRows('broiler_batches','placement_date');
  @override void initState(){super.initState();reload();}
  Future<void> addBatch() async { final breed=TextEditingController(text:'Cobb 500'), chicks=TextEditingController(); DateTime date=DateTime.now(); final ok=await showDialog<bool>(context:context,builder:(ctx)=>StatefulBuilder(builder:(ctx,sd)=>AlertDialog(title:Text(AppPrefs.t('नया बैच','New batch')),content:SingleChildScrollView(child:Column(mainAxisSize:MainAxisSize.min,children:[TextField(controller:breed,decoration:const InputDecoration(labelText:'Breed type')),TextField(controller:chicks,keyboardType:TextInputType.number,decoration:InputDecoration(labelText:AppPrefs.t('चूजों की संख्या','Chicks placed'))),TextButton(onPressed:()async{final d=await showDatePicker(context:ctx,initialDate:date,firstDate:DateTime(2020),lastDate:DateTime(2100));if(d!=null)sd(()=>date=d);},child:Text('${AppPrefs.t('प्लेसमेंट तारीख','Placement date')}: ${date.toIso8601String().substring(0,10)}'))])),actions:[TextButton(onPressed:()=>Navigator.pop(ctx,false),child:Text(AppPrefs.t('रद्द','Cancel'))),FilledButton(onPressed:()=>Navigator.pop(ctx,true),child:Text(AppPrefs.t('सेव','Save')))]))); if(ok!=true)return; final n=int.tryParse(chicks.text); if(n==null||n<=0)return; try{await Supabase.instance.client.from('broiler_batches').insert({'farmer_id':Supabase.instance.client.auth.currentUser!.id,'breed_type':breed.text.trim().isEmpty?'Cobb 500':breed.text.trim(),'chicks_placed':n,'placement_date':date.toIso8601String().substring(0,10)});setState(reload);}catch(e){showError(context,e);} }
  Future<void> addLog(Map<String,dynamic> batch) async { final age=TextEditingController(),mort=TextEditingController(text:'0'),feed=TextEditingController(),weight=TextEditingController(),water=TextEditingController(); final ok=await showDialog<bool>(context:context,builder:(ctx)=>AlertDialog(title:Text(AppPrefs.t('दैनिक एंट्री','Daily entry')),content:SingleChildScrollView(child:Column(mainAxisSize:MainAxisSize.min,children:[field(age,AppPrefs.t('उम्र (दिन)','Bird age (days)'),true),field(mort,AppPrefs.t('आज की मृत्यु','Mortality today'),true),field(feed,AppPrefs.t('दाना (बोरी)','Feed (bags)'),true),field(weight,AppPrefs.t('औसत वजन (ग्राम)','Avg weight (grams)'),true),field(water,AppPrefs.t('पानी (लीटर)','Water (litres)'),true),Text(AppPrefs.t('FCR अनुमान: 1 बोरी = 50 kg','FCR estimate assumes 1 bag = 50 kg'),style:const TextStyle(fontSize:12))])),actions:[TextButton(onPressed:()=>Navigator.pop(ctx,false),child:Text(AppPrefs.t('रद्द','Cancel'))),FilledButton(onPressed:()=>Navigator.pop(ctx,true),child:Text(AppPrefs.t('सेव','Save')))])); if(ok!=true)return; final a=int.tryParse(age.text),m=int.tryParse(mort.text)??0,f=double.tryParse(feed.text),w=double.tryParse(weight.text),wa=int.tryParse(water.text)??0; if(a==null||a<0||m<0||f==null||f<0)return; try{await Supabase.instance.client.from('daily_logs').insert({'batch_id':batch['batch_id'],'day_age':a,'daily_mortality':m,'feed_consumed_bags':f,'avg_body_weight_grams':w,'water_intake_litres':wa});setState(reload);}catch(e){showError(context,e);} }
  Future<void> toggle(Map<String,dynamic> b) async {try{await Supabase.instance.client.from('broiler_batches').update({'is_active':!(b['is_active']==true)}).eq('batch_id',b['batch_id']);setState(reload);}catch(e){showError(context,e);}}
  @override Widget build(BuildContext context)=>Scaffold(floatingActionButton:FloatingActionButton.extended(onPressed:addBatch,icon:const Icon(Icons.add),label:Text(AppPrefs.t('नया बैच','New batch'))),body:FutureBuilder<List<Map<String,dynamic>>>(future:future,builder:(context,s){if(!s.hasData)return const Center(child:CircularProgressIndicator());final bs=s.data!;if(bs.isEmpty)return Center(child:Text(AppPrefs.t('अभी कोई बैच नहीं है','No batches yet')));return RefreshIndicator(onRefresh:()async=>setState(reload),child:ListView(children:bs.map((b)=>Card(child:ExpansionTile(title:Text('${b['breed_type']} • ${b['chicks_placed']}'),subtitle:Text('${b['placement_date']} • ${b['is_active']==true?AppPrefs.t('एक्टिव','Active'):AppPrefs.t('बंद','Closed')}'),children:[Wrap(spacing:8,children:[FilledButton.icon(onPressed:()=>addLog(b),icon:const Icon(Icons.add),label:Text(AppPrefs.t('दैनिक एंट्री','Daily entry'))),OutlinedButton(onPressed:()=>toggle(b),child:Text(b['is_active']==true?AppPrefs.t('बैच बंद करें','Close batch'):AppPrefs.t('फिर चालू करें','Reactivate')))]),const SizedBox(height:8),FutureBuilder<List<Map<String,dynamic>>>(future:Supabase.instance.client.from('daily_logs').select().eq('batch_id',b['batch_id']).order('logged_at',ascending:false).then((v)=>List<Map<String,dynamic>>.from(v)),builder:(context,l)=>l.hasData?Padding(padding:const EdgeInsets.all(12),child:Text(l.data!.isEmpty?AppPrefs.t('दैनिक रिकॉर्ड नहीं','No daily records'):l.data!.map((x)=>'Day ${x['day_age']} • मृत्यु ${x['daily_mortality']} • Feed ${x['feed_consumed_bags']} bags • Weight ${x['avg_body_weight_grams']??'-'} g • Water ${x['water_intake_litres']??'-'} L').join('\n'))):const Padding(padding:EdgeInsets.all(12),child:CircularProgressIndicator()))])).toList()));}));
}

class RatesPage extends StatefulWidget { const RatesPage({super.key}); @override State<RatesPage> createState()=>_RatesPageState(); }
class _RatesPageState extends State<RatesPage>{
  late Future<List<Map<String,dynamic>>> future;
  void reload()=>future=queryRows('mandi_rates','date');
  @override void initState(){super.initState();reload();}
  Future<void> addRate()async{final state=TextEditingController(),district=TextEditingController(),rate=TextEditingController();final ok=await showDialog<bool>(context:context,builder:(ctx)=>AlertDialog(title:Text(AppPrefs.t('मंडी रेट जोड़ें','Add mandi rate')),content:Column(mainAxisSize:MainAxisSize.min,children:[field(state,AppPrefs.t('राज्य','State')),field(district,AppPrefs.t('जिला','District')),field(rate,AppPrefs.t('रेट प्रति kg (₹)','Rate per kg (₹)',true)]),actions:[TextButton(onPressed:()=>Navigator.pop(ctx,false),child:Text(AppPrefs.t('रद्द','Cancel'))),FilledButton(onPressed:()=>Navigator.pop(ctx,true),child:Text(AppPrefs.t('सेव','Save')))]));if(ok!=true)return;final r=double.tryParse(rate.text);if(r==null||r<0)return;try{await Supabase.instance.client.from('mandi_rates').insert({'user_id':Supabase.instance.client.auth.currentUser!.id,'date':dateToday(),'state':state.text.trim(),'district':district.text.trim(),'broiler_rate_per_kg':r});setState(reload);}catch(e){showError(context,e);}}
  @override Widget build(BuildContext context)=>DefaultTabController(length:2,child:Scaffold(
    floatingActionButton:FloatingActionButton.extended(onPressed:addRate,icon:const Icon(Icons.add),label:Text(AppPrefs.t('रेट जोड़ें','Add rate'))),
    appBar:AppBar(title:Text(AppPrefs.t('ब्रॉयलर मंडी रेट','Broiler market rates')),bottom:TabBar(tabs:[Tab(text:AppPrefs.t('ऑनलाइन रेट','Online rates'),icon:const Icon(Icons.public)),Tab(text:AppPrefs.t('मेरे रेट','My cloud rates'),icon:const Icon(Icons.cloud_done))])),
    body:TabBarView(children:[
      const OnlineRatesPage(),
      FutureBuilder<List<Map<String,dynamic>>>(future:future,builder:(context,s){if(s.connectionState!=ConnectionState.done)return const Center(child:CircularProgressIndicator());if(s.hasError)return Center(child:Text('${AppPrefs.t('लोड नहीं हुआ','Could not load')}: ${s.error}'));if(s.data!.isEmpty)return Center(child:Text(AppPrefs.t('अभी कोई रेट सेव नहीं है। + बटन से जोड़ें।','No saved rates yet. Use + to add a rate.')));return RefreshIndicator(onRefresh:()async=>setState(reload),child:ListView(padding:const EdgeInsets.all(8),children:s.data!.map((r)=>Card(child:ListTile(leading:const CircleAvatar(child:Icon(Icons.currency_rupee)),title:Text('₹${r['broiler_rate_per_kg']} / kg'),subtitle:Text('${r['district']}, ${r['state']} • ${r['date']}'))).toList()));})
    ])
  ));
}

class OnlineRatesPage extends StatefulWidget { const OnlineRatesPage({super.key}); @override State<OnlineRatesPage> createState()=>_OnlineRatesPageState(); }
class _OnlineRatesPageState extends State<OnlineRatesPage>{
  late final WebViewController controller;
  Timer? _autoRefreshTimer;
  bool loading=true; String error='';
  static const sourceUrl='https://www.poultrybazaar.net/daily-rate-sheet/Broiler-Rates-UP/';
  @override void initState(){super.initState();controller=WebViewController()..setJavaScriptMode(JavaScriptMode.unrestricted)..setNavigationDelegate(NavigationDelegate(onPageStarted:(_){if(mounted)setState(()=>loading=true);},onPageFinished:(_){if(mounted)setState(()=>loading=false);},onWebResourceError:(e){if(mounted)setState(() { loading=false; error=e.description; });}))..loadRequest(Uri.parse(sourceUrl));
    // Refresh the source webpage every 10 minutes while this screen is active.
    _autoRefreshTimer = Timer.periodic(const Duration(minutes: 10), (_) {
      if (mounted) {
        setState(() { loading = true; error = ''; });
        controller.reload();
      }
    });
  }
  @override void dispose(){_autoRefreshTimer?.cancel();super.dispose();}
  @override Widget build(BuildContext context)=>Column(children:[
    Container(width:double.infinity,padding:const EdgeInsets.all(12),color:Theme.of(context).colorScheme.surfaceContainerHighest,child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text(AppPrefs.t('ऑनलाइन ब्रॉयलर रेट • उत्तर प्रदेश','Online broiler rates • Uttar Pradesh'),style:const TextStyle(fontWeight:FontWeight.bold)),const SizedBox(height:4),Text(AppPrefs.t('रेट बाहरी वेबसाइट से लोड होते हैं। शहर/कंपनी के अनुसार कीमत अलग हो सकती है।','Rates load from an external website. Prices may vary by city/company.'),style:Theme.of(context).textTheme.bodySmall),Row(children:[TextButton.icon(onPressed:(){setState(() { loading=true; error=''; });controller.reload();},icon:const Icon(Icons.refresh),label:Text(AppPrefs.t('रीफ्रेश','Refresh'))),const Spacer(),TextButton(onPressed:()=>GenUI.openUrl(sourceUrl),child:Text(AppPrefs.t('वेबसाइट खोलें','Open website')))])]),
    if(loading)const LinearProgressIndicator(),
    if(error.isNotEmpty)Padding(padding:const EdgeInsets.all(12),child:Text('${AppPrefs.t('वेबसाइट लोड करने में दिक्कत','Website loading issue')}: $error')),
    Expanded(child:WebViewWidget(controller:controller)),
  ]);
}

class ProfilePage extends StatefulWidget {const ProfilePage({super.key});@override State<ProfilePage> createState()=>_ProfilePageState();}
class _ProfilePageState extends State<ProfilePage>{final name=TextEditingController(),district=TextEditingController(),state=TextEditingController();String role='farmer';bool loaded=false;Future<void> load()async{final id=Supabase.instance.client.auth.currentUser!.id;final row=await Supabase.instance.client.from('users').select().eq('id',id).maybeSingle();if(row!=null){name.text=row['full_name']??'';district.text=row['district']??'';state.text=row['state']??'';role=row['role']??'farmer';}if(mounted)setState(()=>loaded=true);}
@override void initState(){super.initState();load();}
@override Widget build(BuildContext context)=>!loaded?const Center(child:CircularProgressIndicator()):ListView(padding:const EdgeInsets.all(16),children:[Text(AppPrefs.t('फार्म प्रोफाइल','Farm profile'),style:Theme.of(context).textTheme.headlineSmall),const SizedBox(height:12),field(name,AppPrefs.t('पूरा नाम','Full name')),DropdownButtonFormField<String>(value:role,decoration:InputDecoration(labelText:AppPrefs.t('भूमिका','Role'),border:const OutlineInputBorder()),items:const [DropdownMenuItem(value:'farmer',child:Text('Farmer')),DropdownMenuItem(value:'supervisor',child:Text('Supervisor')),DropdownMenuItem(value:'trader',child:Text('Trader'))],onChanged:(v){if(v!=null)setState(()=>role=v);}),const SizedBox(height:12),field(district,AppPrefs.t('जिला','District')),field(state,AppPrefs.t('राज्य','State')),FilledButton.icon(onPressed:()async{try{await Supabase.instance.client.from('users').upsert({'id':Supabase.instance.client.auth.currentUser!.id,'full_name':name.text.trim().isEmpty?Supabase.instance.client.auth.currentUser!.email??'Farmer':name.text.trim(),'district':district.text.trim(),'state':state.text.trim(),'role':role});if(context.mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text(AppPrefs.t('प्रोफाइल सेव हो गई','Profile saved'))));}catch(e){showError(context,e);}},icon:const Icon(Icons.save),label:Text(AppPrefs.t('प्रोफाइल सेव करें','Save profile'))),const SizedBox(height:20),Text(AppPrefs.t('क्लाउड डेटा: users, broiler_batches, daily_logs, mandi_rates','Cloud tables: users, broiler_batches, daily_logs, mandi_rates'),style:const TextStyle(color:Colors.grey))]);}

Widget field(TextEditingController c,String label,[bool number=false])=>Padding(padding:const EdgeInsets.only(bottom:10),child:TextField(controller:c,keyboardType:number?const TextInputType.numberWithOptions(decimal:true):TextInputType.text,decoration:InputDecoration(labelText:label,border:const OutlineInputBorder())));
