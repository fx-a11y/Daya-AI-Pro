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
  Future<String?> getAiKey() => _storage.read(key: 'gemini_api_key');
  Future<void> saveAiKey(String key) => _storage.write(key: 'gemini_api_key', value: key.trim());
  Future<void> clearAiKey() => _storage.delete(key: 'gemini_api_key');

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
  final double close, changePct, score, rsi, ema20, ema50, ema200, atr, entry, tp1, tp2, tp3, sl, rr1, rr2, rr3;
  final String trendReason, momentumReason, riskReason;
  final int bars;
  StockAnalysis({required this.symbol, required this.name, required this.signal, required this.reason,
    required this.close, required this.changePct, required this.score, required this.rsi,
    required this.ema20, required this.ema50, required this.ema200, required this.atr,
    required this.entry, required this.tp1, required this.tp2, required this.tp3, required this.sl, required this.rr1, required this.rr2, required this.rr3, required this.trendReason, required this.momentumReason, required this.riskReason, required this.bars});
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
  final e20 = ema(closes,20), e50 = ema(closes,50), e200 = ema(closes,200), strength = rsi(closes);
  double atr = 0;
  if (bars.length >= 15) {
    final trs = <double>[];
    for (int i = bars.length - 14; i < bars.length; i++) {
      final high = numVal(bars[i]['high']), low = numVal(bars[i]['low']);
      final prev = numVal(bars[i-1]['close']);
      if (high > 0 && low > 0 && prev > 0) {
        trs.add([high-low, (high-prev).abs(), (low-prev).abs()].reduce((a,b)=>a>b?a:b));
      }
    }
    if (trs.isNotEmpty) atr = trs.reduce((a,b)=>a+b)/trs.length;
  }
  double score = 0;
  if (e20 > 0 && close > e20) score += 20;
  if (e50 > 0 && e20 > e50) score += 20;
  if (e200 > 0 && close > e200) score += 20;
  if (strength >= 50 && strength <= 68) score += 15;
  if (strength > 68 && strength <= 75) score += 8;
  if (change > 0) score += 10;
  if (bars.length >= 200) score += 15; else if (bars.length >= 50) score += 8;
  final valid = bars.length >= 50 && close > 0 && atr > 0;
  // Entry acuan menggunakan EMA20 sebagai area rencana pullback.
  final entry = valid && e20 > 0 ? e20 : 0.0;
  final sl = valid ? entry - (1.5 * atr) : 0.0;
  final tp1 = valid ? entry + (1.5 * atr) : 0.0;
  final tp2 = valid ? entry + (2.25 * atr) : 0.0;
  final tp3 = valid ? entry + (3.0 * atr) : 0.0;
      ? (close > e20 && e20 > e50 && e50 > e200
          ? 'Tren naik tersusun: harga > EMA20 > EMA50 > EMA200.'
          : 'Susunan tren belum ideal: ${close > e20 ? 'harga di atas EMA20' : 'harga di bawah EMA20'}, ${e20 > e50 ? 'EMA20 di atas EMA50' : 'EMA20 di bawah/menyentuh EMA50'}, ${e50 > e200 ? 'EMA50 di atas EMA200' : 'EMA50 belum di atas EMA200'}.')
      : 'Data belum cukup untuk membaca seluruh EMA20/50/200.';
  final momentumReason = strength >= 50 && strength <= 68
      ? 'RSI14 ${strength.toStringAsFixed(1)} berada pada area momentum positif yang relatif belum terlalu panas.'
      : strength > 68
          ? 'RSI14 ${strength.toStringAsFixed(1)} menunjukkan momentum kuat tetapi mulai rawan jenuh beli.'
          : 'RSI14 ${strength.toStringAsFixed(1)} belum menunjukkan momentum bullish yang kuat.';
  final riskReason = valid
      ? 'ATR14 ${atr.toStringAsFixed(2)} dipakai untuk membuat level risiko. Stop referensi 1,5 ATR; target bertahap 1,5 / 2,25 / 3 ATR. Risiko rencana per transaksi 1% dan batas rugi harian 2% adalah parameter panduan, bukan pemantauan saldo otomatis.'
      : 'Belum ada cukup data untuk menghitung ATR dan level risiko secara wajar.';
  final trendValid = valid &&
    close > e20 &&
    e20 > e50 &&
    strength >= 50 &&
    strength <= 75;

final signal = !valid
    ? 'DATA KURANG'
    : !trendValid
        ? 'WAIT'
        : close <= entry * 1.02
            ? 'AREA ENTRY'
            : 'MENUNGGU PULLBACK';
  final reason = !valid ? 'Riwayat candle harian belum cukup untuk analisis swing yang layak.' : '$trendReason $momentumReason';
  return StockAnalysis(symbol: (instrument['symbol'] ?? '').toString(), name: (instrument['name'] ?? '').toString(),
    signal: signal, reason: reason, close: close, changePct: change, score: score, rsi: strength,
    ema20: e20, ema50: e50, ema200: e200, atr: atr, entry: entry, tp1: tp1, tp2: tp2, tp3: tp3, sl: sl,
    rr1: rr1, rr2: rr2, rr3: rr3, trendReason: trendReason, momentumReason: momentumReason, riskReason: riskReason, bars: closes.length);
}

class GeminiService {
  static const _storage = FlutterSecureStorage();
  Future<String?> getKey() => _storage.read(key: 'gemini_api_key');
  Future<void> saveKey(String key) => _storage.write(key: 'gemini_api_key', value: key.trim());
  Future<void> clearKey() => _storage.delete(key: 'gemini_api_key');

  Future<String> summarize(List<StockAnalysis> candidates) async {
    final key = await getKey();
    if (key == null || key.isEmpty) throw Exception('Gemini API Key belum diatur. Buka Lainnya > API AI.');
    final payload = candidates.map((s) => {
      'ticker': s.symbol, 'score': s.score.round(), 'close': s.close,
      'rsi14': double.parse(s.rsi.toStringAsFixed(1)), 'ema20': s.ema20,
      'ema50': s.ema50, 'ema200': s.ema200, 'atr14': s.atr,
      'entry_reference': s.entry, 'stop_reference': s.sl,
      'target1_reference': s.tp1, 'target2_reference': s.tp2, 'target3_reference': s.tp3,
      'stop_distance': s.entry - s.sl, 'rr_tp1': s.rr1, 'rr_tp2': s.rr2, 'rr_tp3': s.rr3,
      'reason': s.reason, 'trend_reason': s.trendReason, 'momentum_reason': s.momentumReason, 'risk_reason': s.riskReason,
      'technical_status': s.signal, 'bars': s.bars,
    }).toList();
    final uri = Uri.parse('https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent');
    final response = await http.post(uri, headers: {'Content-Type':'application/json','x-goog-api-key':key}, body: jsonEncode({
      'contents':[{'parts':[{'text':'Kamu adalah analis teknikal saham BEI untuk mode SWING. Untuk SETIAP saham, jelaskan secara terstruktur: (1) keputusan SETUP POTENSIAL/WAIT/DATA KURANG, (2) alasan tren berdasarkan posisi harga terhadap EMA20/50/200, (3) alasan momentum berdasarkan RSI14, (4) level entry referensi dari penutupan terakhir, (5) TP1, TP2, TP3, (6) stop loss, (7) rasio risk/reward tiap target, (8) risiko dan kondisi yang membatalkan skenario. Jangan pernah mengarang data, indikator, berita, fundamental, volume, atau harga yang tidak disediakan. Jika metrik tidak tersedia, tulis tidak tersedia. Jangan menyebut BUY pasti. Entry/TP/SL hanyalah level perencanaan berbasis candle harian dan ATR, bukan harga real-time. Money management tanpa input modal: panduan risiko 1% per transaksi, batas rugi harian 2%, maksimal 3 posisi bersamaan. Break-even dipertimbangkan setelah TP1; trailing stop mengikuti swing low harian atau ATR. Jelaskan bahwa aplikasi belum memantau saldo/posisi broker sehingga batas ini harus diterapkan manual. Sertakan alasan mengapa kandidat layak atau tidak layak dipantau. Data: ${jsonEncode(payload)}'}]}],
      'generationConfig': {'temperature':0.2, 'maxOutputTokens':3500}
    })).timeout(const Duration(seconds:35));
    final body = jsonDecode(response.body);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      final msg = body is Map ? (body['error']?['message'] ?? 'Permintaan Gemini gagal') : 'Permintaan Gemini gagal';
      throw Exception(msg.toString());
    }
    final text = body['candidates']?[0]?['content']?['parts']?[0]?['text'];
    if (text == null) throw Exception('Gemini tidak mengembalikan ringkasan.');
    return text.toString();
  }
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
  final api=ApiService(); final ai=GeminiService(); final search=TextEditingController();
  bool loading=false, aiLoading=false; String error='', aiSummary='';
  List<Map<String,dynamic>> all=[]; List<StockAnalysis> ranked=[]; int scanned=0; int total=0;
  static const int scanLimit=18; // preserve monthly free-tier request budget

  Future<void> scanSwing() async {
    setState(()=>{loading=true,error='',aiSummary='',ranked=[]});
    try {
      final instruments=await api.instruments();
      final eligible=instruments.where((e) {
        final symbol=(e['symbol']??'').toString().toUpperCase();
        final board=(e['board']??'').toString().toLowerCase();
        final type=(e['type']??e['instrument_type']??'').toString().toLowerCase();
        return RegExp(r'^[A-Z]{4}$').hasMatch(symbol) && !board.contains('etf') && !type.contains('warrant') && !type.contains('right');
      }).toList();
      all=eligible; total=eligible.length;
      // Free tier: do not pretend we can request daily candles for every IDX issuer.
      final ordered=[...eligible]..sort((a,b)=>numVal(b['change_pct']).compareTo(numVal(a['change_pct'])));
      final batch=ordered.take(scanLimit).toList();
      final found=<StockAnalysis>[]; int done=0;
      for (final instrument in batch) {
        try {
          final symbol=(instrument['symbol']??'').toString();
          final bars=await api.daily(symbol);
          final analysis=analyzeDaily(instrument,bars);
          if (analysis.bars >= 50) found.add(analysis);
        } catch (_) { /* one symbol may lack history; continue with the next */ }
        done++;
        if (mounted) setState(()=>scanned=done);
      }
      found.sort((a,b)=>b.score.compareTo(a.score));
      if (mounted) setState(()=>ranked=found.take(10).toList());
      if (found.isEmpty) error='Data harian belum berhasil diambil untuk batch ini. Periksa API Key, endpoint, dan kuota.';
    } catch(e) { error=e.toString().replaceFirst('Exception: ',''); }
    finally { if(mounted)setState(()=>loading=false); }
  }

  Future<void> askAi() async {
    if (ranked.isEmpty) return;
    setState(()=>aiLoading=true);
    try { final summary=await ai.summarize(ranked); if(mounted)setState(()=>aiSummary=summary); }
    catch(e){if(mounted)setState(()=>aiSummary=e.toString().replaceFirst('Exception: ',''));}
    finally{if(mounted)setState(()=>aiLoading=false);}
  }
  @override void dispose(){search.dispose();super.dispose();}
  @override Widget build(BuildContext context) {
    final q=search.text.toUpperCase();
    final rows=all.where((e)=>(e['symbol']??'').toString().contains(q)||(e['name']??'').toString().toUpperCase().contains(q)).toList();
    return ListView(padding:const EdgeInsets.all(18),children:[
      const PageTitle(title:'AI Screener • Swing',subtitle:'Pemindaian kandidat berdasarkan candle harian BEI'),
      const SizedBox(height:12),
      _panel(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
        const Row(children:[Icon(Icons.calendar_month,color:teal),SizedBox(width:8),Text('MODE SWING TRADING',style:TextStyle(fontWeight:FontWeight.w900,letterSpacing:.6))]),
        const SizedBox(height:8),const Text('Timeframe: 1D • Horizon: beberapa hari hingga beberapa minggu',style:TextStyle(color:muted,fontSize:11)),
        const SizedBox(height:12),SizedBox(width:double.infinity,child:FilledButton.icon(onPressed:loading?null:scanSwing,icon:loading?const SizedBox(width:16,height:16,child:CircularProgressIndicator(strokeWidth:2)):const Icon(Icons.radar),label:Text(loading?'Memindai $scanned/$scanLimit saham...':'Pindai kandidat swing'))),
        const SizedBox(height:6),const Text('Indikator: EMA20/50/200, RSI14, ATR14. Ranking dihitung dari data teknikal, bukan keputusan AI semata.',style:TextStyle(color:muted,fontSize:10,height:1.4)),
      ])),
      if(error.isNotEmpty) InfoBox(error),
      if(loading) Padding(padding:const EdgeInsets.symmetric(vertical:8),child:LinearProgressIndicator(value:scanned/scanLimit,minHeight:5)),
      if(ranked.isNotEmpty) ...[
        const SizedBox(height:16),SectionTitle('Top ${ranked.length} kandidat swing','BATCH $scanned/$total'),
        const SizedBox(height:8),
        ...ranked.asMap().entries.map(
        (entry) => CandidateCard(
        analysis: entry.value,
        rank: entry.key + 1,
        ),
       ),
        const SizedBox(height:8),const InfoBox('Money Management tanpa input modal: panduan risiko 1% per transaksi, batas rugi harian 2%, maksimal 3 posisi bersamaan. Break-even: pertimbangkan memindahkan SL ke entry setelah harga mencapai TP1; trailing stop: ikuti swing low harian/ATR setelah TP1. Aplikasi belum terhubung ke broker sehingga tidak menghitung saldo, lot, atau memaksa batas risiko secara otomatis. Terapkan batas ini secara manual.'),
        FilledButton.icon(onPressed:aiLoading?null:askAi,icon:const Icon(Icons.auto_awesome),label:Text(aiLoading?'AI sedang menganalisis...':'Minta ringkasan AI Gemini')),
        if(aiSummary.isNotEmpty)_panel(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[const Text('RINGKASAN AI',style:TextStyle(color:teal,fontWeight:FontWeight.w900)),const SizedBox(height:8),Text(aiSummary,style:const TextStyle(height:1.5,color:Colors.white70))])),
      ],
      const SizedBox(height:16),const InfoBox('Batas penting paket Free: 500 hit/bulan. Satu pemindaian ini memakai sekitar 1 hit daftar instrumen + maksimal 18 hit riwayat harian. Jadi aplikasi belum dapat mengambil candle harian semua emiten BEI setiap hari. Hasil ini adalah batch kandidat, bukan pemindaian penuh seluruh bursa.'),
      const InfoBox('Entry/TP/SL adalah level referensi berbasis ATR dari penutupan harian, bukan order real-time. Periksa likuiditas, spread, berita, dan risiko sebelum transaksi.'),
      const SizedBox(height:16),const SectionTitle('Daftar emiten yang tersedia','API'),
      TextField(controller:search,onChanged:(_)=>setState((){}),decoration:const InputDecoration(prefixIcon:Icon(Icons.search),hintText:'Cari kode atau nama saham',filled:true,fillColor:panel,border:OutlineInputBorder(borderSide:BorderSide.none))),
      if(all.isEmpty)const InfoBox('Tekan Pindai kandidat swing untuk memuat daftar instrumen.'),
      ...rows.take(60).map((e)=>InstrumentTile(item:e)),
    ]);
  }
}

class CandidateCard extends StatelessWidget {
  final StockAnalysis analysis;
  final int rank;

  const CandidateCard({
    super.key,
    required this.analysis,
    required this.rank,
  });

  @override
  Widget build(BuildContext context) {
    final instrument = <String, dynamic>{
      'symbol': analysis.symbol,
      'name': analysis.name,
      'last': analysis.close,
      'change_pct': analysis.changePct,
    };

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(17),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => StockDetailPage(instrument: instrument),
            ),
          );
        },
        child: _panel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: teal.withOpacity(.12),
                    child: Text(
                      '$rank',
                      style: const TextStyle(
                        color: teal,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${analysis.symbol} • ${analysis.name}',
                          style: const TextStyle(fontWeight: FontWeight.w900),
                        ),
                        Text(
                          'Skor ${analysis.score.toStringAsFixed(0)}/100 • RSI ${analysis.rsi.toStringAsFixed(1)}',
                          style: const TextStyle(color: muted, fontSize: 10),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right, color: muted),
                ],
              ),
              const Divider(color: panel2),
              Wrap(
                spacing: 12,
                runSpacing: 8,
                children: [
                  _metric('Harga terakhir', analysis.close),
                  _metric('Entry acuan', analysis.entry),
                  _metric('Stop Loss', analysis.sl),
                  _metric('TP1', analysis.tp1),
                  _metric('TP2', analysis.tp2),
                  _metric('TP3', analysis.tp3),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                analysis.signal,
                style: const TextStyle(
                  color: teal,
                  fontWeight: FontWeight.w900,
                ),
              ),
              Text(
                'Alasan tren: ${analysis.trendReason}',
                style: const TextStyle(color: Colors.white70, fontSize: 11),
              ),
              const SizedBox(height: 4),
              Text(
                'Alasan momentum: ${analysis.momentumReason}',
                style: const TextStyle(color: Colors.white70, fontSize: 11),
              ),
              const SizedBox(height: 6),
              Text(
                'Risk/Reward: TP1 1:${analysis.rr1.toStringAsFixed(2)} • '
                'TP2 1:${analysis.rr2.toStringAsFixed(2)} • '
                'TP3 1:${analysis.rr3.toStringAsFixed(2)}',
                style: const TextStyle(
                  color: teal,
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 5),
              const Text(
                'Sentuh untuk melihat detail emiten',
                style: TextStyle(color: muted, fontSize: 10),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
Widget _metric(String label,double value)=>SizedBox(width:105,child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text(label,style:const TextStyle(color:muted,fontSize:9)),const SizedBox(height:3),Text(money(value),style:const TextStyle(fontSize:11,fontWeight:FontWeight.w800))]));

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
class _MorePageState extends State<MorePage>{
 final api=ApiService(); final ai=GeminiService(); String apiStatus='Memeriksa...'; String aiStatus='Memeriksa...';
 @override void initState(){super.initState();check();}
 Future<void>check()async{final k=await api.getKey();final a=await ai.getKey();if(mounted)setState(()=>{apiStatus:k==null||k.isEmpty?'API saham belum disimpan':'API saham tersimpan aman di perangkat.',aiStatus:a==null||a.isEmpty?'API AI Gemini belum disimpan':'API AI Gemini tersimpan aman di perangkat.'});}
 Future<void>edit({required bool isAi})async{
   final current=isAi?await ai.getKey():await api.getKey(); if(!mounted)return;
   final c=TextEditingController(text:current??'');
   final value=await showDialog<String>(context:context,builder:(ctx)=>AlertDialog(backgroundColor:panel,title:Text(isAi?'API Key AI • Gemini':'API Key Saham • Api.co.id'),content:TextField(controller:c,obscureText:true,autocorrect:false,decoration:InputDecoration(hintText:isAi?'Tempel Gemini API Key':'Tempel Api.co.id API Key')),actions:[TextButton(onPressed:()=>Navigator.pop(ctx),child:const Text('Batal')),FilledButton(onPressed:()=>Navigator.pop(ctx,c.text.trim()),child:const Text('Simpan'))]));
   if(value!=null&&value.isNotEmpty){if(isAi)await ai.saveKey(value);else await api.saveKey(value);await check();if(mounted)ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('API Key disimpan secara lokal.')));}
 }
 @override Widget build(BuildContext context)=>ListView(padding:const EdgeInsets.all(18),children:[
  const PageTitle(title:'Lainnya',subtitle:'Pengaturan koneksi data dan AI'),const SizedBox(height:18),
  _panel(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[const Text('SUMBER DATA SAHAM',style:TextStyle(color:teal,fontWeight:FontWeight.w900,letterSpacing:1)),const SizedBox(height:8),Text(apiStatus,style:const TextStyle(color:Colors.white70)),const SizedBox(height:10),SizedBox(width:double.infinity,child:FilledButton.icon(onPressed:()=>edit(isAi:false),icon:const Icon(Icons.key),label:const Text('Atur API Key Api.co.id'))),TextButton.icon(onPressed:()async{await api.clearKey();await check();},icon:const Icon(Icons.delete_outline),label:const Text('Hapus API saham'))])),
  const SizedBox(height:12),_panel(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[const Text('KECERDASAN BUATAN',style:TextStyle(color:teal,fontWeight:FontWeight.w900,letterSpacing:1)),const SizedBox(height:8),Text(aiStatus,style:const TextStyle(color:Colors.white70)),const SizedBox(height:10),SizedBox(width:double.infinity,child:FilledButton.icon(onPressed:()=>edit(isAi:true),icon:const Icon(Icons.auto_awesome),label:const Text('Atur API Key AI Gemini'))),TextButton.icon(onPressed:()async{await ai.clearKey();await check();},icon:const Icon(Icons.delete_outline),label:const Text('Hapus API AI'))])),
  const SizedBox(height:12),const InfoBox('AI Gemini sekarang diminta menjelaskan keputusan per saham: tren EMA, momentum RSI, alasan entry, TP1–TP3, Stop Loss, Risk/Reward, risiko, dan kondisi pembatalan. AI tidak boleh mengarang data yang tidak tersedia.'),
  const InfoBox('Money Management tanpa modal: panduan risiko 1% per transaksi, batas rugi harian 2%, maksimal 3 posisi. Break-even dapat dipertimbangkan setelah TP1; trailing stop mengikuti swing low/ATR. Ini parameter panduan manual; belum terhubung ke saldo broker atau eksekusi order.'),
  const InfoBox('Keamanan: key disimpan di secure storage perangkat, tetapi key yang dipakai langsung dari APK masih dapat diekstrak oleh pihak yang menguasai perangkat. Untuk aplikasi publik, gunakan backend pribadi.'),
  const InfoBox('Paket Api.co.id Free memiliki batas 500 hit/bulan. Karena setiap emiten membutuhkan request riwayat harian, pemindaian seluruh saham BEI setiap hari belum dapat dilakukan dengan paket ini.'),
  const SizedBox(height:12),const MenuRow(icon:Icons.info_outline,title:'Tentang Daya AI Pro',subtitle:'Versi 0.3.1 • Swing + Gemini + MM tanpa modal')
 ]);
}

class BrandHeader extends StatelessWidget{const BrandHeader({super.key});@override Widget build(BuildContext context)=>Row(children:[Container(width:42,height:42,decoration:BoxDecoration(color:teal.withOpacity(.14),borderRadius:BorderRadius.circular(13)),child:const Icon(Icons.show_chart,color:teal,size:28)),const SizedBox(width:10),const Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text('Daya AI Pro',style:TextStyle(fontSize:21,fontWeight:FontWeight.w800)),Text('AI Analyst Saham Indonesia',style:TextStyle(color:muted,fontSize:12))]))]);}
class PageTitle extends StatelessWidget{final String title,subtitle;const PageTitle({super.key,required this.title,required this.subtitle});@override Widget build(BuildContext context)=>Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text(title,style:const TextStyle(fontSize:25,fontWeight:FontWeight.w900)),const SizedBox(height:5),Text(subtitle,style:const TextStyle(color:muted,fontSize:12))]);}
class SectionTitle extends StatelessWidget{final String title,tag;const SectionTitle(this.title,this.tag,{super.key});@override Widget build(BuildContext context)=>Row(children:[Expanded(child:Text(title,style:const TextStyle(fontSize:17,fontWeight:FontWeight.w800))),Text(tag,style:const TextStyle(color:teal,fontSize:10,fontWeight:FontWeight.bold))]);}
Widget _panel({required Widget child})=>Container(padding:const EdgeInsets.all(16),decoration:BoxDecoration(color:panel,borderRadius:BorderRadius.circular(17),border:Border.all(color:teal.withOpacity(.12))),child:child);
Widget _statBox(String title,String value)=>Expanded(child:_panel(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text(title,style:const TextStyle(color:muted,fontSize:10)),const SizedBox(height:6),Text(value,style:const TextStyle(fontWeight:FontWeight.w800,fontSize:13))])));
class InfoBox extends StatelessWidget{final String text;const InfoBox(this.text,{super.key});@override Widget build(BuildContext context)=>Container(margin:const EdgeInsets.symmetric(vertical:7),padding:const EdgeInsets.all(12),decoration:BoxDecoration(color:amber.withOpacity(.07),borderRadius:BorderRadius.circular(12),border:Border.all(color:amber.withOpacity(.18))),child:Row(crossAxisAlignment:CrossAxisAlignment.start,children:[const Icon(Icons.info_outline,color:amber,size:18),const SizedBox(width:8),Expanded(child:Text(text,style:const TextStyle(color:Colors.white70,fontSize:11,height:1.45)))]));}
class InstrumentTile extends StatelessWidget {
  final Map<String, dynamic> item;
  const InstrumentTile({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    final ch = numVal(item['change_pct']);
    final symbol = (item['symbol'] ?? '').toString().toUpperCase();
    final name = (item['name'] ?? symbol).toString();
    return Material(
      color: panel,
      borderRadius: BorderRadius.circular(13),
      child: InkWell(
        borderRadius: BorderRadius.circular(13),
        onTap: symbol.isEmpty ? null : () {
          Navigator.push(context, MaterialPageRoute(
            builder: (_) => StockDetailPage(instrument: Map<String, dynamic>.from(item)),
          ));
        },
        child: Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(13),
            border: Border.all(color: teal.withOpacity(.10)),
          ),
          child: Row(children: [
            CircleAvatar(
              backgroundColor: teal.withOpacity(.12),
              child: Text(symbol.isEmpty ? '?' : symbol.substring(0, 1), style: const TextStyle(color: teal)),
            ),
            const SizedBox(width: 10),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(symbol.isEmpty ? '—' : symbol, style: const TextStyle(fontWeight: FontWeight.w800)),
              Text(name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: muted, fontSize: 10)),
            ])),
            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Text(money(numVal(item['last'])), style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
              Text('${ch >= 0 ? '+' : ''}${ch.toStringAsFixed(2)}%', style: TextStyle(color: ch >= 0 ? green : red, fontSize: 11, fontWeight: FontWeight.bold)),
            ]),
            const SizedBox(width: 5),
            const Icon(Icons.chevron_right, color: muted, size: 19),
          ]),
        ),
      ),
    );
  }
}

class StockDetailPage extends StatefulWidget {
  final Map<String, dynamic> instrument;
  const StockDetailPage({super.key, required this.instrument});

  @override
  State<StockDetailPage> createState() => _StockDetailPageState();
}

class _StockDetailPageState extends State<StockDetailPage> {
  final api = ApiService();
  bool loading = true;
  String error = '';
  StockAnalysis? analysis;

  @override
  void initState() {
    super.initState();
    loadAnalysis();
  }

  Future<void> loadAnalysis() async {
    final symbol = (widget.instrument['symbol'] ?? '').toString().toUpperCase();
    try {
      final bars = await api.daily(symbol);
      final result = analyzeDaily(widget.instrument, bars);
      if (mounted) setState(() => analysis = result);
    } catch (e) {
      if (mounted) setState(() => error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final symbol = (widget.instrument['symbol'] ?? '—').toString();
    final name = (widget.instrument['name'] ?? symbol).toString();
    return Scaffold(
      appBar: AppBar(title: Text('$symbol • Detail Emiten')),
      body: ListView(padding: const EdgeInsets.all(18), children: [
        _panel(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(symbol, style: const TextStyle(fontSize: 25, fontWeight: FontWeight.w900)),
          const SizedBox(height: 4),
          Text(name, style: const TextStyle(color: muted)),
          const SizedBox(height: 14),
          const Text('Harga terakhir dari daftar instrumen', style: TextStyle(color: muted, fontSize: 11)),
          const SizedBox(height: 4),
          Text(money(numVal(widget.instrument['last'])), style: const TextStyle(fontSize: 23, fontWeight: FontWeight.w800)),
          Text('Perubahan harian: ${numVal(widget.instrument['change_pct']).toStringAsFixed(2)}%', style: const TextStyle(color: Colors.white70)),
        ])),
        const SizedBox(height: 14),
        const SectionTitle('Analisis teknikal historis', 'DATA HARIAN'),
        const SizedBox(height: 8),
        if (loading) const Center(child: Padding(padding: EdgeInsets.all(24), child: CircularProgressIndicator())),
        if (error.isNotEmpty) InfoBox(error),
        if (!loading && analysis != null) _panel(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            const Expanded(child: Text('Kesimpulan analisis', style: TextStyle(fontWeight: FontWeight.w800))),
            Text(analysis!.signal, style: TextStyle(color: analysis!.signal == 'SETUP POTENSIAL' ? green : amber, fontWeight: FontWeight.w900)),
          ]),
          const SizedBox(height: 12),
          Text('Skor teknikal: ${analysis!.score.toStringAsFixed(0)}/100'),
          Text('RSI 14: ${analysis!.rsi.toStringAsFixed(1)}'),
          Text('EMA20: ${money(analysis!.ema20)}'),
          Text('EMA50: ${money(analysis!.ema50)}'),
          Text('EMA200: ${money(analysis!.ema200)}'),
          Text('ATR14: ${money(analysis!.atr)}'),
          Text('Entry acuan: ${money(analysis!.entry)}'),
          Text('Stop referensi: ${money(analysis!.sl)}'),
          Text('TP1 / TP2 / TP3: ${money(analysis!.tp1)} / ${money(analysis!.tp2)} / ${money(analysis!.tp3)}'),
          Text('Risk/Reward: 1:${analysis!.rr1.toStringAsFixed(2)} / 1:${analysis!.rr2.toStringAsFixed(2)} / 1:${analysis!.rr3.toStringAsFixed(2)}'),
          Text('Candle harian: ${analysis!.bars}'),
          const Divider(color: panel2),
          Text('ALASAN TREN', style: const TextStyle(color: teal, fontWeight: FontWeight.w800)),
          Text(analysis!.trendReason, style: const TextStyle(color: Colors.white70, height: 1.5)),
          const SizedBox(height: 8),
          Text('ALASAN MOMENTUM', style: const TextStyle(color: teal, fontWeight: FontWeight.w800)),
          Text(analysis!.momentumReason, style: const TextStyle(color: Colors.white70, height: 1.5)),
          const SizedBox(height: 8),
          Text('MONEY MANAGEMENT', style: const TextStyle(color: teal, fontWeight: FontWeight.w800)),
          Text(analysis!.riskReason, style: const TextStyle(color: Colors.white70, height: 1.5)),
          const SizedBox(height: 6),
          const Text('Panduan tanpa input modal: risiko 1% per transaksi, batas rugi harian 2%, maksimal 3 posisi. Pertimbangkan break-even setelah TP1 dan trailing stop mengikuti swing low/ATR. Aturan harus diterapkan manual; aplikasi tidak memantau saldo atau order broker.', style: TextStyle(color: Colors.white70, height: 1.5)),
        ])),
        const SizedBox(height: 12),
        const InfoBox('Analisis ini memakai data historis harian dari paket Free, bukan harga real-time atau sinyal scalping 5 menit. Ini bukan rekomendasi beli/jual.'),
      ]),
    );
  }
}
class MenuRow extends StatelessWidget{final IconData icon;final String title,subtitle;const MenuRow({super.key,required this.icon,required this.title,required this.subtitle});@override Widget build(BuildContext context)=>Container(decoration:BoxDecoration(color:panel,borderRadius:BorderRadius.circular(14)),child:ListTile(leading:const Icon(Icons.info_outline,color:teal),title:Text(title,style:const TextStyle(fontWeight:FontWeight.w700,fontSize:13)),subtitle:Text(subtitle,style:const TextStyle(color:muted,fontSize:11))));}
String money(double v)=>v==0?'—':'Rp ${v.toStringAsFixed(0)}';
