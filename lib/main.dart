import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

void main() => runApp(const DayaAiApp());

const bg = Color(0xFF06111D), panel = Color(0xFF0D2030), panel2 = Color(0xFF102A3D);
const teal = Color(0xFF16D6B0), muted = Color(0xFF8FA8B9), green = Color(0xFF25D69A);
const amber = Color(0xFFFFBD4A), red = Color(0xFFFF667A);

class DayaAiApp extends StatelessWidget {
  const DayaAiApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Daya AI Pro', debugShowCheckedModeBanner: false,
    theme: ThemeData(brightness: Brightness.dark, scaffoldBackgroundColor: bg,
      colorScheme: const ColorScheme.dark(primary: teal, surface: panel), useMaterial3: true),
    home: const MainShell(),
  );
}

class ApiService {
  static const _storage = FlutterSecureStorage();
  static const _base = 'https://use.api.co.id/idx/v2';
  Future<String?> getKey() => _storage.read(key: 'api_co_id_key');
  Future<void> saveKey(String key) => _storage.write(key: 'api_co_id_key', value: key.trim());
  Future<void> clearKey() => _storage.delete(key: 'api_co_id_key');

  Future<Map<String, dynamic>> get(String path, {Map<String, String>? query}) async {
    final key = await getKey();
    if (key == null || key.trim().isEmpty) throw Exception('API Key belum diatur. Buka Lainnya > Sumber Data.');
    final uri = Uri.parse('$_base$path').replace(queryParameters: query);
    final response = await http.get(uri, headers: {'x-api-co-id': key, 'Accept': 'application/json'}).timeout(const Duration(seconds: 25));
    Map<String, dynamic> json;
    try { json = jsonDecode(response.body) as Map<String, dynamic>; }
    catch (_) { throw Exception('Respons API tidak terbaca (HTTP ${response.statusCode}).'); }
    if (response.statusCode < 200 || response.statusCode >= 300 || json['is_success'] == false) {
      throw Exception('${json['message'] ?? 'API gagal'} (HTTP ${response.statusCode}). Periksa paket, key, dan kuota.');
    }
    return json;
  }

  Future<List<Map<String, dynamic>>> instruments() async {
    final json = await get('/instruments', query: {'index': 'IHSG', 'limit': '100'});
    final root = json['data'];
    final rows = root is Map ? root['data'] : null;
    if (rows is! List) return [];
    return rows.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).where((e) {
      final symbol = (e['symbol'] ?? '').toString().toUpperCase();
      final board = (e['board'] ?? '').toString().toLowerCase();
      return RegExp(r'^[A-Z]{4}$').hasMatch(symbol) && !board.contains('etf');
    }).toList();
  }

  Future<List<Map<String, dynamic>>> daily(String symbol) async {
    final json = await get('/chart/daily/$symbol', query: {'timeframe': '1d', 'order': 'asc'});
    final root = json['data'];
    final rows = root is Map ? root['data'] : null;
    if (rows is! List) return [];
    return rows.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
  }

  Future<List<Map<String, dynamic>>> news() async {
    final json = await get('/news');
    final root = json['data']; final rows = root is Map ? root['data'] : null;
    if (rows is! List) return [];
    return rows.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
  }
}

class StockAnalysis {
  final String symbol, name, signal, reason;
  final double close, changePct, score, rsi, ema20, ema50;
  final int bars;
  StockAnalysis({required this.symbol, required this.name, required this.signal, required this.reason,
    required this.close, required this.changePct, required this.score, required this.rsi,
    required this.ema20, required this.ema50, required this.bars});
}

double numVal(dynamic value) => double.tryParse((value ?? '').toString().replaceAll(',', '')) ?? 0;
double ema(List<double> values, int period) {
  if (values.length < period) return 0;
  final k = 2 / (period + 1); double result = values.take(period).reduce((a,b) => a+b) / period;
  for (final v in values.skip(period)) { result = v * k + result * (1-k); }
  return result;
}
double rsi(List<double> values, [int period = 14]) {
  if (values.length <= period) return 50;
  double gains = 0, losses = 0;
  for (int i = values.length-period; i < values.length; i++) {
    final d = values[i] - values[i-1]; if (d >= 0) gains += d; else losses -= d;
  }
  if (losses == 0) return 100;
  final rs = (gains/period) / (losses/period);
  return 100 - (100/(1+rs));
}
StockAnalysis analyzeDaily(Map<String,dynamic> instrument, List<Map<String,dynamic>> bars) {
  final closes = bars.map((e) => numVal(e['close'])).where((v) => v > 0).toList();
  final close = closes.isEmpty ? numVal(instrument['last']) : closes.last;
  final change = numVal(instrument['change_pct']);
  final e20 = ema(closes,20), e50 = ema(closes,50), strength = rsi(closes);
  double score = 0;
  if (e20 > 0 && close > e20) score += 25;
  if (e50 > 0 && e20 > e50) score += 25;
  if (strength >= 50 && strength <= 70) score += 20;
  if (change > 0) score += 15;
  if (bars.length >= 50) score += 15;
  final valid = bars.length >= 50 && e20 > 0 && e50 > 0;
  final signal = !valid ? 'DATA KURANG' : (score >= 70 ? 'WATCHLIST KUAT' : 'WAIT');
  final reason = !valid ? 'Butuh minimal 50 candle harian. Ini belum cukup untuk sinyal scalping.' :
    'Analisis candle harian: ${close > e20 ? 'harga di atas EMA20' : 'harga di bawah EMA20'}, ${e20 > e50 ? 'EMA20 di atas EMA50' : 'EMA20 belum di atas EMA50'}, RSI ${strength.toStringAsFixed(1)}.';
  return StockAnalysis(symbol: (instrument['symbol'] ?? '').toString(), name: (instrument['name'] ?? '').toString(),
    signal: signal, reason: reason, close: close, changePct: change, score: score, rsi: strength,
    ema20: e20, ema50: e50, bars: closes.length);
}

class MainShell extends StatefulWidget { const MainShell({super.key}); @override State<MainShell> createState()=>_MainShellState(); }
class _MainShellState extends State<MainShell> {
  int selected=0;
  @override Widget build(BuildContext context) => Scaffold(
    body: SafeArea(child: IndexedStack(index:selected, children: const [DashboardPage(), ScreenerPage(), AnalysisPage(), AlertsPage(), MorePage()])),
    bottomNavigationBar: NavigationBar(selectedIndex:selected, onDestinationSelected:(i)=>setState(()=>selected=i), backgroundColor:const Color(0xFF081824), indicatorColor:teal.withOpacity(.16),
      destinations: const [NavigationDestination(icon:Icon(Icons.home_outlined),label:'Beranda'),NavigationDestination(icon:Icon(Icons.manage_search),label:'Screener'),NavigationDestination(icon:Icon(Icons.auto_awesome_outlined),label:'Analisis'),NavigationDestination(icon:Icon(Icons.notifications_none),label:'Berita'),NavigationDestination(icon:Icon(Icons.grid_view_rounded),label:'Lainnya')]),
  );
}

class DashboardPage extends StatefulWidget { const DashboardPage({super.key}); @override State<DashboardPage> createState()=>_DashboardPageState(); }
class _DashboardPageState extends State<DashboardPage> {
  final api=ApiService(); bool loading=false; String message='Hubungkan API Key untuk mulai mengambil data BEI.'; List<Map<String,dynamic>> stocks=[];
  Future<void> load() async { setState(()=>loading=true); try { final data=await api.instruments(); setState(() { stocks=data; message='${data.length} instrumen diterima dari endpoint IHSG. Data harga yang tersedia adalah penutupan harian.'; }); } catch(e) { setState(()=>message=e.toString().replaceFirst('Exception: ','')); } finally { if(mounted)setState(()=>loading=false); } }
  @override Widget build(BuildContext context)=>ListView(padding:const EdgeInsets.all(18), children:[
    const BrandHeader(), const SizedBox(height:20),
    _panel(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[const Text('PASAR INDONESIA',style:TextStyle(color:muted,fontSize:11,letterSpacing:1.3)),const SizedBox(height:8),const Text('Koneksi data BEI',style:TextStyle(fontSize:23,fontWeight:FontWeight.w800)),const SizedBox(height:6),Text(message,style:const TextStyle(color:Colors.white70,fontSize:12,height:1.5)),const SizedBox(height:14),SizedBox(width:double.infinity,child:FilledButton.icon(onPressed:loading?null:load,icon:loading?const SizedBox(width:16,height:16,child:CircularProgressIndicator(strokeWidth:2)):const Icon(Icons.sync),label:Text(loading?'Mengambil data...':'Uji koneksi & muat saham')))])),
    const SizedBox(height:20),const SectionTitle('Ringkasan data','API FREE'),
    Row(children:[_statBox('Instrumen',stocks.length.toString()),const SizedBox(width:8),_statBox('Intraday 5m','Terkunci'),const SizedBox(width:8),_statBox('Paket','500 hit/bln')]),
    const SizedBox(height:20),const SectionTitle('Saham dari API','Data aktual bila berhasil dimuat'),
    if(stocks.isEmpty) const InfoBox('Belum ada data yang dimuat. Tekan tombol Uji koneksi & muat saham. Tidak ada angka demo.'),
    ...stocks.take(8).map((s)=>InstrumentTile(item:s)),
    const SizedBox(height:12),const InfoBox('Catatan: paket Free tidak menyediakan quote live maupun candle intraday. Angka penutupan harian tidak boleh dianggap sebagai sinyal scalping 5 menit.'),
  ]);
}

class ScreenerPage extends StatefulWidget { const ScreenerPage({super.key}); @override State<ScreenerPage> createState()=>_ScreenerPageState(); }
class _ScreenerPageState extends State<ScreenerPage> {
  final api=ApiService(); final search=TextEditingController(); bool loading=false; String error=''; List<Map<String,dynamic>> all=[];
  Future<void> scan() async { setState(()=>{loading=true,error=''}); try { final rows=await api.instruments(); setState(()=>all=rows); } catch(e){setState(()=>error=e.toString().replaceFirst('Exception: ',''));} finally {if(mounted)setState(()=>loading=false);} }
  @override void dispose(){search.dispose();super.dispose();}
  @override Widget build(BuildContext context){final q=search.text.toUpperCase(); final rows=all.where((e)=>(e['symbol']??'').toString().contains(q)||(e['name']??'').toString().toUpperCase().contains(q)).toList()..sort((a,b)=>numVal(b['change_pct']).compareTo(numVal(a['change_pct'])));
    return ListView(padding:const EdgeInsets.all(18),children:[const PageTitle(title:'AI Screener',subtitle:'Daftar instrumen BEI dari endpoint gratis Api.co.id'),const SizedBox(height:14),TextField(controller:search,onChanged:(_)=>setState((){}),decoration:const InputDecoration(prefixIcon:Icon(Icons.search),hintText:'Cari kode atau nama saham',filled:true,fillColor:panel,border:OutlineInputBorder(borderSide:BorderSide.none))),const SizedBox(height:12),FilledButton.icon(onPressed:loading?null:scan,icon:const Icon(Icons.manage_search),label:Text(loading?'Memuat...':'Ambil daftar saham BEI')),
      if(error.isNotEmpty) InfoBox(error),if(all.isNotEmpty) Padding(padding:const EdgeInsets.symmetric(vertical:10),child:Text('${rows.length} saham ditampilkan dari ${all.length} instrumen yang diterima. Urutan berdasarkan perubahan penutupan harian, bukan sinyal scalping.',style:const TextStyle(color:muted,fontSize:11))),
      if(all.isEmpty) const InfoBox('Belum ada hasil. Pemindaian ini memakai satu request daftar instrumen dan belum menghitung sinyal teknikal.'),...rows.map((e)=>InstrumentTile(item:e)),]);}
}

class AnalysisPage extends StatefulWidget { const AnalysisPage({super.key}); @override State<AnalysisPage> createState()=>_AnalysisPageState(); }
class _AnalysisPageState extends State<AnalysisPage>{final api=ApiService();final ctrl=TextEditingController();bool loading=false;StockAnalysis? result;String error='';
 Future<void> run() async {final symbol=ctrl.text.trim().toUpperCase();if(!RegExp(r'^[A-Z]{4}$').hasMatch(symbol)){setState(()=>error='Masukkan kode saham 4 huruf, misalnya BBCA.');return;}setState(()=>{loading=true,error='',result=null});try{final bars=await api.daily(symbol);final inst={'symbol':symbol,'name':symbol,'last':bars.isNotEmpty?bars.last['close']:0,'change_pct':0};final a=analyzeDaily(inst,bars);setState(()=>result=a);}catch(e){setState(()=>error=e.toString().replaceFirst('Exception: ',''));}finally{if(mounted)setState(()=>loading=false);}}
 @override void dispose(){ctrl.dispose();super.dispose();}
 @override Widget build(BuildContext context)=>ListView(padding:const EdgeInsets.all(18),children:[const PageTitle(title:'Analisis Saham',subtitle:'Analisis teknikal historis harian dari API'),const SizedBox(height:14),TextField(controller:ctrl,textCapitalization:TextCapitalization.characters,decoration:const InputDecoration(prefixIcon:Icon(Icons.search),hintText:'Masukkan kode saham, contoh BBCA',filled:true,fillColor:panel,border:OutlineInputBorder(borderSide:BorderSide.none))),const SizedBox(height:10),FilledButton.icon(onPressed:loading?null:run,icon:const Icon(Icons.auto_awesome),label:Text(loading?'Mengambil data harian...':'Analisis saham')),
 if(error.isNotEmpty) InfoBox(error),if(result!=null) ...[const SizedBox(height:16),_panel(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Row(children:[Expanded(child:Text('${result!.symbol} • ${result!.name}',style:const TextStyle(fontSize:18,fontWeight:FontWeight.w800))),Text(result!.signal,style:TextStyle(color:result!.signal=='WATCHLIST KUAT'?green:amber,fontWeight:FontWeight.w900))]),const SizedBox(height:12),Text('Penutupan terakhir: ${money(result!.close)}'),Text('Skor teknikal harian: ${result!.score.toStringAsFixed(0)}/100'),Text('RSI 14: ${result!.rsi.toStringAsFixed(1)}'),Text('EMA20: ${money(result!.ema20)}'),Text('EMA50: ${money(result!.ema50)}'),Text('Jumlah candle: ${result!.bars}'),const Divider(color:panel2),Text(result!.reason,style:const TextStyle(color:Colors.white70,height:1.5))])),const InfoBox('Ini analisis timeframe harian (EOD), bukan rekomendasi BUY. Tidak menghasilkan Entry/TP/SL scalping karena paket Free tidak memiliki candle 5 menit.')],const SizedBox(height:16),const InfoBox('Setiap analisis saham menggunakan satu hit API. Hindari mengulang permintaan berlebihan karena kuota hanya 500 hit per bulan.')]);}

class AlertsPage extends StatefulWidget{const AlertsPage({super.key});@override State<AlertsPage> createState()=>_AlertsPageState();}
class _AlertsPageState extends State<AlertsPage>{final api=ApiService();bool loading=false;String error='';List<Map<String,dynamic>> rows=[];Future<void> load()async{setState(()=>{loading=true,error=''});try{final d=await api.news();setState(()=>rows=d);}catch(e){setState(()=>error=e.toString().replaceFirst('Exception: ',''));}finally{if(mounted)setState(()=>loading=false);}}
 @override Widget build(BuildContext context)=>ListView(padding:const EdgeInsets.all(18),children:[const PageTitle(title:'Berita & Alert',subtitle:'Feed berita pasar dari Api.co.id'),const SizedBox(height:14),FilledButton.icon(onPressed:loading?null:load,icon:const Icon(Icons.refresh),label:Text(loading?'Memuat berita...':'Muat berita pasar')),if(error.isNotEmpty)InfoBox(error),if(rows.isEmpty)const InfoBox('Belum ada berita dimuat. Endpoint berita tersedia di paket Free.'),...rows.map((e)=>_panel(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text((e['title']??e['headline']??'Berita pasar').toString(),style:const TextStyle(fontWeight:FontWeight.w800)),const SizedBox(height:6),Text((e['summary']??e['description']??e['source']??'').toString(),style:const TextStyle(color:Colors.white70,fontSize:12)),const SizedBox(height:5),Text((e['published_at']??e['date']??'').toString(),style:const TextStyle(color:muted,fontSize:10))])))]);}

class MorePage extends StatefulWidget{const MorePage({super.key});@override State<MorePage> createState()=>_MorePageState();}
class _MorePageState extends State<MorePage>{final api=ApiService();String status='Memeriksa status key...';@override void initState(){super.initState();check();}Future<void>check()async{final k=await api.getKey();if(mounted)setState(()=>status=k==null||k.isEmpty?'API Key belum disimpan':'API Key tersimpan di penyimpanan aman perangkat.');}
 Future<void>editKey()async{final c=TextEditingController(text:await api.getKey()??'');if(!mounted)return;final value=await showDialog<String>(context:context,builder:(ctx)=>AlertDialog(backgroundColor:panel,title:const Text('API Key Api.co.id'),content:TextField(controller:c,obscureText:true,autocorrect:false,decoration:const InputDecoration(hintText:'Tempel API Key di sini')),actions:[TextButton(onPressed:()=>Navigator.pop(ctx),child:const Text('Batal')),FilledButton(onPressed:()=>Navigator.pop(ctx,c.text.trim()),child:const Text('Simpan'))]));if(value!=null&&value.isNotEmpty){await api.saveKey(value);await check();if(mounted)ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('API Key disimpan di perangkat.')));}}
 @override Widget build(BuildContext context)=>ListView(padding:const EdgeInsets.all(18),children:[const PageTitle(title:'Lainnya',subtitle:'Pengaturan aplikasi dan koneksi data'),const SizedBox(height:18),_panel(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[const Text('SUMBER DATA',style:TextStyle(color:teal,fontWeight:FontWeight.w800,letterSpacing:1)),const SizedBox(height:8),Text(status,style:const TextStyle(color:Colors.white70)),const SizedBox(height:12),SizedBox(width:double.infinity,child:FilledButton.icon(onPressed:editKey,icon:const Icon(Icons.key),label:const Text('Atur API Key'))),TextButton.icon(onPressed:()async{await api.clearKey();await check();},icon:const Icon(Icons.delete_outline),label:const Text('Hapus API Key'))])),const SizedBox(height:12),const InfoBox('API Key disimpan memakai secure storage perangkat. Untuk aplikasi yang dibagikan ke publik, pindahkan pemanggilan API ke backend agar key tidak bisa diekstrak dari APK.'),const SizedBox(height:12),const InfoBox('Paket Free: 500 hit/bulan dan 30 request/menit. Endpoint daftar instrumen, daily EOD, berita, kalender, dan referensi tersedia. Quote live dan intraday 5 menit memerlukan Starter.'),const SizedBox(height:12),const MenuRow(icon:Icons.info_outline,title:'Tentang Daya AI Pro',subtitle:'Versi 0.2 • API integration awal')]);}

class BrandHeader extends StatelessWidget{const BrandHeader({super.key});@override Widget build(BuildContext context)=>Row(children:[Container(width:42,height:42,decoration:BoxDecoration(color:teal.withOpacity(.14),borderRadius:BorderRadius.circular(13)),child:const Icon(Icons.show_chart,color:teal,size:28)),const SizedBox(width:10),const Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text('Daya AI Pro',style:TextStyle(fontSize:21,fontWeight:FontWeight.w800)),Text('AI Analyst Saham Indonesia',style:TextStyle(color:muted,fontSize:12))]))]);}
class PageTitle extends StatelessWidget{final String title,subtitle;const PageTitle({super.key,required this.title,required this.subtitle});@override Widget build(BuildContext context)=>Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text(title,style:const TextStyle(fontSize:25,fontWeight:FontWeight.w900)),const SizedBox(height:5),Text(subtitle,style:const TextStyle(color:muted,fontSize:12))]);}
class SectionTitle extends StatelessWidget{final String title,tag;const SectionTitle(this.title,this.tag,{super.key});@override Widget build(BuildContext context)=>Row(children:[Expanded(child:Text(title,style:const TextStyle(fontSize:17,fontWeight:FontWeight.w800))),Text(tag,style:const TextStyle(color:teal,fontSize:10,fontWeight:FontWeight.bold))]);}
Widget _panel({required Widget child})=>Container(padding:const EdgeInsets.all(16),decoration:BoxDecoration(color:panel,borderRadius:BorderRadius.circular(17),border:Border.all(color:teal.withOpacity(.12))),child:child);
Widget _statBox(String title,String value)=>Expanded(child:_panel(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text(title,style:const TextStyle(color:muted,fontSize:10)),const SizedBox(height:6),Text(value,style:const TextStyle(fontWeight:FontWeight.w800,fontSize:13))])));
class InfoBox extends StatelessWidget{final String text;const InfoBox(this.text,{super.key});@override Widget build(BuildContext context)=>Container(margin:const EdgeInsets.symmetric(vertical:7),padding:const EdgeInsets.all(12),decoration:BoxDecoration(color:amber.withOpacity(.07),borderRadius:BorderRadius.circular(12),border:Border.all(color:amber.withOpacity(.18))),child:Row(crossAxisAlignment:CrossAxisAlignment.start,children:[const Icon(Icons.info_outline,color:amber,size:18),const SizedBox(width:8),Expanded(child:Text(text,style:const TextStyle(color:Colors.white70,fontSize:11,height:1.45)))]));}
class InstrumentTile extends StatelessWidget{final Map<String,dynamic> item;const InstrumentTile({super.key,required this.item});@override Widget build(BuildContext context){final ch=numVal(item['change_pct']);return Container(margin:const EdgeInsets.only(bottom:8),padding:const EdgeInsets.all(12),decoration:BoxDecoration(color:panel,borderRadius:BorderRadius.circular(13)),child:Row(children:[CircleAvatar(backgroundColor:teal.withOpacity(.12),child:Text((item['symbol']??'?').toString().substring(0,1),style:const TextStyle(color:teal))),const SizedBox(width:10),Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text((item['symbol']??'—').toString(),style:const TextStyle(fontWeight:FontWeight.w800)),Text((item['name']??'').toString(),maxLines:1,overflow:TextOverflow.ellipsis,style:const TextStyle(color:muted,fontSize:10))])),Column(crossAxisAlignment:CrossAxisAlignment.end,children:[Text(money(numVal(item['last'])),style:const TextStyle(fontWeight:FontWeight.w700,fontSize:12)),Text('${ch>=0?'+':''}${ch.toStringAsFixed(2)}%',style:TextStyle(color:ch>=0?green:red,fontSize:11,fontWeight:FontWeight.bold))]) ]));}}
class MenuRow extends StatelessWidget{final IconData icon;final String title,subtitle;const MenuRow({super.key,required this.icon,required this.title,required this.subtitle});@override Widget build(BuildContext context)=>Container(decoration:BoxDecoration(color:panel,borderRadius:BorderRadius.circular(14)),child:ListTile(leading:const Icon(Icons.info_outline,color:teal),title:Text(title,style:const TextStyle(fontWeight:FontWeight.w700,fontSize:13)),subtitle:Text(subtitle,style:const TextStyle(color:muted,fontSize:11))));}
String money(double v)=>v==0?'—':'Rp ${v.toStringAsFixed(0)}';
