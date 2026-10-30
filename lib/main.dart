import 'package:flutter/material.dart';

void main() => runApp(const DayaAiApp());

const bg = Color(0xFF06111D);
const panel = Color(0xFF0D2030);
const panel2 = Color(0xFF102A3D);
const teal = Color(0xFF16D6B0);
const muted = Color(0xFF8FA8B9);
const green = Color(0xFF25D69A);
const amber = Color(0xFFFFBD4A);
const red = Color(0xFFFF667A);

class DayaAiApp extends StatelessWidget {
  const DayaAiApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Daya AI Pro',
    debugShowCheckedModeBanner: false,
    theme: ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: bg,
      colorScheme: const ColorScheme.dark(primary: teal, surface: panel),
      useMaterial3: true,
      fontFamily: 'Roboto',
      appBarTheme: const AppBarTheme(backgroundColor: bg, foregroundColor: Colors.white),
    ),
    home: const MainShell(),
  );
}

class MainShell extends StatefulWidget {
  const MainShell({super.key});
  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int selected = 0;
  final pages = const [
    DashboardPage(), ScreenerPage(), AnalysisPage(), AlertsPage(), MorePage()
  ];
  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(child: IndexedStack(index: selected, children: pages)),
    bottomNavigationBar: NavigationBar(
      selectedIndex: selected,
      onDestinationSelected: (i) => setState(() => selected = i),
      backgroundColor: const Color(0xFF081824),
      indicatorColor: teal.withOpacity(.16),
      destinations: const [
        NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home, color: teal), label: 'Beranda'),
        NavigationDestination(icon: Icon(Icons.manage_search), selectedIcon: Icon(Icons.manage_search, color: teal), label: 'Screener'),
        NavigationDestination(icon: Icon(Icons.auto_awesome_outlined), selectedIcon: Icon(Icons.auto_awesome, color: teal), label: 'Analisis'),
        NavigationDestination(icon: Icon(Icons.notifications_none), selectedIcon: Icon(Icons.notifications, color: teal), label: 'Alert'),
        NavigationDestination(icon: Icon(Icons.grid_view_rounded), selectedIcon: Icon(Icons.grid_view_rounded, color: teal), label: 'Lainnya'),
      ],
    ),
  );
}

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});
  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.fromLTRB(18, 16, 18, 24),
    children: [
      Row(children: [
        Container(width: 42, height: 42, decoration: BoxDecoration(color: teal.withOpacity(.14), borderRadius: BorderRadius.circular(13)), child: const Icon(Icons.show_chart, color: teal, size: 28)),
        const SizedBox(width: 10),
        const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Daya AI Pro', style: TextStyle(fontSize: 21, fontWeight: FontWeight.w800)),
          Text('AI Analyst Saham Indonesia', style: TextStyle(color: muted, fontSize: 12)),
        ])),
        IconButton(onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AlertsPage())), icon: const Icon(Icons.notifications_none))
      ]),
      const SizedBox(height: 22),
      Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(gradient: const LinearGradient(colors: [Color(0xFF103B4A), Color(0xFF0D2030)]), borderRadius: BorderRadius.circular(22), border: Border.all(color: teal.withOpacity(.25))),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('PASAR INDONESIA', style: TextStyle(color: muted, fontSize: 11, letterSpacing: 1.4)),
          const SizedBox(height: 8),
          const Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text('IHSG', style: TextStyle(fontSize: 16, color: Colors.white70)),
            Spacer(),
            Text('DATA DEMO', style: TextStyle(fontSize: 10, color: amber, fontWeight: FontWeight.bold)),
          ]),
          const SizedBox(height: 3),
          const Text('7.842,45', style: TextStyle(fontSize: 31, fontWeight: FontWeight.w800)),
          const Row(children: [Icon(Icons.trending_up, color: green, size: 17), SizedBox(width: 4), Text('+0,87% (contoh)', style: TextStyle(color: green, fontWeight: FontWeight.w700))]),
          const SizedBox(height: 18),
          Row(children: [
            _marketStat('Nilai transaksi', 'Rp 11,2 T'),
            _marketStat('Volume', '18,4 T'),
            _marketStat('Frekuensi', '1,1 M'),
          ]),
        ]),
      ),
      const SizedBox(height: 24),
      _sectionHeader('Sinyal terbaru', 'Contoh'),
      const SizedBox(height: 10),
      const SignalCard(code: 'BBCA', name: 'Bank Central Asia', status: 'BUY', color: green, entry: '8.200鈥�8.250', tp: '8.600 / 8.900', sl: '8.050', confidence: '78%'),
      const SignalCard(code: 'KLBF', name: 'Kalbe Farma', status: 'WAIT', color: amber, entry: '705鈥�715', tp: '825 / 935', sl: '665', confidence: '56%'),
      const SignalCard(code: 'PGAS', name: 'Perusahaan Gas Negara', status: 'NO TRADE', color: red, entry: 'Belum tersedia', tp: '鈥�', sl: '鈥�', confidence: '32%'),
      const SizedBox(height: 14),
      _sectionHeader('Analisis 8 pilar', 'Lihat semua'),
      const SizedBox(height: 10),
      Wrap(spacing: 8, runSpacing: 8, children: const [
        PillChip(icon: Icons.candlestick_chart, label: 'Teknikal'),
        PillChip(icon: Icons.account_balance, label: 'Fundamental'),
        PillChip(icon: Icons.newspaper, label: 'Berita & Katalis'),
        PillChip(icon: Icons.swap_horiz, label: 'Foreign Flow'),
        PillChip(icon: Icons.show_chart, label: 'IHSG'),
        PillChip(icon: Icons.factory_outlined, label: 'Sektor'),
        PillChip(icon: Icons.public, label: 'Makro'),
        PillChip(icon: Icons.event_note, label: 'Corporate Action'),
      ]),
      const SizedBox(height: 18),
      const DemoDisclaimer(),
    ],
  );
}

Widget _marketStat(String title, String value) => Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
  Text(title, style: const TextStyle(color: muted, fontSize: 10)),
  const SizedBox(height: 4),
  Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
]));

Widget _sectionHeader(String title, String action) => Row(children: [
  Expanded(child: Text(title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800))),
  Text(action, style: const TextStyle(color: teal, fontSize: 12, fontWeight: FontWeight.w600)),
]);

class SignalCard extends StatelessWidget {
  final String code, name, status, entry, tp, sl, confidence;
  final Color color;
  const SignalCard({super.key, required this.code, required this.name, required this.status, required this.color, required this.entry, required this.tp, required this.sl, required this.confidence});
  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 10),
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(color: panel, borderRadius: BorderRadius.circular(17), border: Border.all(color: color.withOpacity(.19))),
    child: Column(children: [
      Row(children: [
        Container(width: 37, height: 37, decoration: BoxDecoration(color: color.withOpacity(.13), borderRadius: BorderRadius.circular(11)), child: Center(child: Text(code.substring(0, 1), style: TextStyle(color: color, fontWeight: FontWeight.w900)))),
        const SizedBox(width: 10),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(code, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
          Text(name, style: const TextStyle(color: muted, fontSize: 11)),
        ])),
        Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6), decoration: BoxDecoration(color: color.withOpacity(.13), borderRadius: BorderRadius.circular(8)), child: Text(status, style: TextStyle(color: color, fontWeight: FontWeight.w900, fontSize: 10))),
      ]),
      const Divider(height: 22, color: Color(0xFF1B3547)),
      Row(children: [
        _miniValue('Entry', entry),
        _miniValue('TP1 / TP2', tp),
        _miniValue('SL', sl),
        _miniValue('Skor', confidence),
      ]),
    ]),
  );
}

Widget _miniValue(String title, String value) => Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
  Text(title, style: const TextStyle(color: muted, fontSize: 10)),
  const SizedBox(height: 4),
  Text(value, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700)),
]));

class ScreenerPage extends StatelessWidget {
  const ScreenerPage({super.key});
  @override
  Widget build(BuildContext context) => ListView(padding: const EdgeInsets.all(18), children: [
    const PageTitle(title: 'AI Screener', subtitle: 'Cari saham berdasarkan kriteria analisis'),
    const SizedBox(height: 18),
    TextField(decoration: InputDecoration(hintText: 'Cari kode atau nama saham', prefixIcon: const Icon(Icons.search), filled: true, fillColor: panel, border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none))),
    const SizedBox(height: 16),
    const Text('Kriteria screening', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
    const SizedBox(height: 10),
    const FilterRow(title: 'Likuiditas memadai', subtitle: 'Menghindari saham yang sulit diperdagangkan'),
    const FilterRow(title: 'Tren teknikal membaik', subtitle: 'EMA, RSI, MACD dan struktur harga'),
    const FilterRow(title: 'Volume menguat', subtitle: 'Konfirmasi aktivitas transaksi'),
    const FilterRow(title: 'Fundamental diperiksa', subtitle: 'Gunakan data keuangan yang tersedia'),
    const SizedBox(height: 12),
    FilledButton.icon(onPressed: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Prototipe: screening otomatis belum terhubung ke data pasar.'))), icon: const Icon(Icons.manage_search), label: const Text('Cari Saham')),
    const SizedBox(height: 22),
    _sectionHeader('Hasil contoh', 'DATA DEMO'),
    const SizedBox(height: 8),
    const ResultRow(code: 'BBCA', name: 'Bank Central Asia', score: '92', status: 'BUY', color: green),
    const ResultRow(code: 'BMRI', name: 'Bank Mandiri', score: '88', status: 'BUY', color: green),
    const ResultRow(code: 'TLKM', name: 'Telkom Indonesia', score: '72', status: 'WAIT', color: amber),
    const ResultRow(code: 'KLBF', name: 'Kalbe Farma', score: '56', status: 'WAIT', color: amber),
    const DemoDisclaimer(),
  ]);
}

class FilterRow extends StatefulWidget {
  final String title, subtitle;
  const FilterRow({super.key, required this.title, required this.subtitle});
  @override
  State<FilterRow> createState() => _FilterRowState();
}
class _FilterRowState extends State<FilterRow> {
  bool value = true;
  @override
  Widget build(BuildContext context) => SwitchListTile(
    value: value, onChanged: (v) => setState(() => value = v),
    activeColor: teal, contentPadding: const EdgeInsets.symmetric(horizontal: 12),
    tileColor: panel, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    title: Text(widget.title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
    subtitle: Text(widget.subtitle, style: const TextStyle(color: muted, fontSize: 10)),
  );
}

class ResultRow extends StatelessWidget {
  final String code, name, score, status;
  final Color color;
  const ResultRow({super.key, required this.code, required this.name, required this.score, required this.status, required this.color});
  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 8), padding: const EdgeInsets.all(13),
    decoration: BoxDecoration(color: panel, borderRadius: BorderRadius.circular(13)),
    child: Row(children: [
      CircleAvatar(backgroundColor: color.withOpacity(.14), child: Text(code.substring(0,1), style: TextStyle(color: color))),
      const SizedBox(width: 10),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(code, style: const TextStyle(fontWeight: FontWeight.w800)), Text(name, style: const TextStyle(color: muted, fontSize: 11))])),
      Text('Skor $score', style: const TextStyle(color: muted, fontSize: 11)),
      const SizedBox(width: 10),
      Text(status, style: TextStyle(color: color, fontWeight: FontWeight.w900, fontSize: 11)),
    ]),
  );
}

class AnalysisPage extends StatelessWidget {
  const AnalysisPage({super.key});
  @override
  Widget build(BuildContext context) => ListView(padding: const EdgeInsets.all(18), children: [
    const PageTitle(title: 'Analisis Saham', subtitle: 'Lihat kesimpulan dan alasan di balik sinyal'),
    const SizedBox(height: 16),
    Container(padding: const EdgeInsets.all(14), decoration: BoxDecoration(color: panel, borderRadius: BorderRadius.circular(16)), child: const Row(children: [
      Icon(Icons.search, color: teal), SizedBox(width: 10),
      Expanded(child: TextField(decoration: InputDecoration(hintText: 'Masukkan kode saham, contoh KLBF', border: InputBorder.none))),
    ])),
    const SizedBox(height: 16),
    const Text('Contoh analisis: KLBF', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
    const SizedBox(height: 10),
    Container(padding: const EdgeInsets.all(17), decoration: BoxDecoration(gradient: const LinearGradient(colors: [Color(0xFF153C3C), panel]), borderRadius: BorderRadius.circular(18), border: Border.all(color: amber.withOpacity(.25))), child: const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [Text('KLBF', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900)), Spacer(), Text('WAIT', style: TextStyle(color: amber, fontWeight: FontWeight.w900, fontSize: 17))]),
      SizedBox(height: 8),
      Text('Harga masih di atas zona entry pada contoh ini. Tunggu konfirmasi tren dan volume sebelum mengambil keputusan.', style: TextStyle(color: Colors.white70, height: 1.45)),
      SizedBox(height: 14),
      Row(children: [Text('Entry 705鈥�715'), Spacer(), Text('Confidence contoh: 56%', style: TextStyle(color: amber, fontWeight: FontWeight.bold))]),
    ])),
    const SizedBox(height: 18),
    const Text('Analisis 8 Pilar', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
    const SizedBox(height: 10),
    const PillDetail(icon: Icons.candlestick_chart, title: 'Teknikal', desc: 'Tren, EMA, RSI, MACD, volume dan support/resistance.'),
    const PillDetail(icon: Icons.account_balance, title: 'Fundamental', desc: 'Laba, utang, arus kas, valuasi dan pertumbuhan.'),
    const PillDetail(icon: Icons.newspaper, title: 'Berita & Katalis', desc: 'Berita terbaru, sentimen dan peristiwa penting.'),
    const PillDetail(icon: Icons.swap_horiz, title: 'Foreign Flow', desc: 'Arus transaksi asing jika sumber data tersedia.'),
    const PillDetail(icon: Icons.show_chart, title: 'IHSG', desc: 'Kondisi pasar secara keseluruhan.'),
    const PillDetail(icon: Icons.factory_outlined, title: 'Sektor', desc: 'Kekuatan sektor dibandingkan pasar dan emiten sejenis.'),
    const PillDetail(icon: Icons.public, title: 'Makro Ekonomi', desc: 'Suku bunga, inflasi, rupiah dan komoditas.'),
    const PillDetail(icon: Icons.event_note, title: 'Corporate Action', desc: 'Dividen, buyback, rights issue dan aksi korporasi.'),
    const SizedBox(height: 10),
    const DemoDisclaimer(),
  ]);
}

class PillDetail extends StatelessWidget {
  final IconData icon; final String title, desc;
  const PillDetail({super.key, required this.icon, required this.title, required this.desc});
  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 8), padding: const EdgeInsets.all(13),
    decoration: BoxDecoration(color: panel, borderRadius: BorderRadius.circular(14)),
    child: Row(children: [Container(padding: const EdgeInsets.all(9), decoration: BoxDecoration(color: teal.withOpacity(.12), borderRadius: BorderRadius.circular(10)), child: Icon(icon, color: teal, size: 20)), const SizedBox(width: 12), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(fontWeight: FontWeight.w800)), const SizedBox(height: 3), Text(desc, style: const TextStyle(color: muted, fontSize: 11, height: 1.4))]))]),
  );
}

class AlertsPage extends StatelessWidget {
  const AlertsPage({super.key});
  @override
  Widget build(BuildContext context) => ListView(padding: const EdgeInsets.all(18), children: [
    const PageTitle(title: 'Notifikasi & Alert', subtitle: 'Pusat pemberitahuan sinyal dan perubahan kondisi'),
    const SizedBox(height: 18),
    const AlertCard(icon: Icons.trending_up, title: 'Sinyal baru 鈥� BBCA', time: 'Contoh 鈥� 09:15', body: 'BUY | Entry 8.200鈥�8.250 | TP1 8.600 | TP2 8.900 | SL 8.050', color: green),
    const AlertCard(icon: Icons.hourglass_bottom, title: 'Update analisis 鈥� KLBF', time: 'Contoh 鈥� 08:50', body: 'WAIT. Menunggu harga masuk zona entry dan konfirmasi volume.', color: amber),
    const AlertCard(icon: Icons.newspaper, title: 'Berita & katalis', time: 'Contoh 鈥� Kemarin', body: 'Berita penting akan ditampilkan setelah sumber berita dihubungkan.', color: teal),
    const SizedBox(height: 14),
    const DemoDisclaimer(),
  ]);
}

class AlertCard extends StatelessWidget {
  final IconData icon; final String title, time, body; final Color color;
  const AlertCard({super.key, required this.icon, required this.title, required this.time, required this.body, required this.color});
  @override
  Widget build(BuildContext context) => Container(margin: const EdgeInsets.only(bottom: 10), padding: const EdgeInsets.all(15), decoration: BoxDecoration(color: panel, borderRadius: BorderRadius.circular(16)), child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [Icon(icon, color: color), const SizedBox(width: 12), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(fontWeight: FontWeight.w800)), const SizedBox(height: 4), Text(time, style: const TextStyle(color: muted, fontSize: 10)), const SizedBox(height: 8), Text(body, style: const TextStyle(height: 1.45, fontSize: 12, color: Colors.white70))]))]));
}

class MorePage extends StatelessWidget {
  const MorePage({super.key});
  @override
  Widget build(BuildContext context) => ListView(padding: const EdgeInsets.all(18), children: [
    const PageTitle(title: 'Lainnya', subtitle: 'Pengaturan dan informasi aplikasi'),
    const SizedBox(height: 18),
    const MenuRow(icon: Icons.star_border, title: 'Watchlist', subtitle: 'Daftar saham yang ingin dipantau'),
    const MenuRow(icon: Icons.history, title: 'Riwayat Sinyal', subtitle: 'Evaluasi sinyal terdahulu'),
    const MenuRow(icon: Icons.tune, title: 'Pengaturan Alert', subtitle: 'Atur jenis sinyal dan pemicu notifikasi'),
    const MenuRow(icon: Icons.data_object, title: 'Sumber Data', subtitle: 'Status API dan waktu pembaruan data'),
    const MenuRow(icon: Icons.info_outline, title: 'Tentang Daya AI Pro', subtitle: 'Prototipe versi 0.1'),
    const SizedBox(height: 16),
    const DemoDisclaimer(),
  ]);
}

class MenuRow extends StatelessWidget {
  final IconData icon; final String title, subtitle;
  const MenuRow({super.key, required this.icon, required this.title, required this.subtitle});
  @override
  Widget build(BuildContext context) => Container(margin: const EdgeInsets.only(bottom: 9), decoration: BoxDecoration(color: panel, borderRadius: BorderRadius.circular(14)), child: ListTile(leading: Icon(icon, color: teal), title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)), subtitle: Text(subtitle, style: const TextStyle(color: muted, fontSize: 11)), trailing: const Icon(Icons.chevron_right, color: muted)));
}

class PageTitle extends StatelessWidget {
  final String title, subtitle;
  const PageTitle({super.key, required this.title, required this.subtitle});
  @override
  Widget build(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    const SizedBox(height: 6),
    Text(title, style: const TextStyle(fontSize: 25, fontWeight: FontWeight.w900)),
    const SizedBox(height: 5),
    Text(subtitle, style: const TextStyle(color: muted, fontSize: 12)),
  ]);
}

class PillChip extends StatelessWidget {
  final IconData icon; final String label;
  const PillChip({super.key, required this.icon, required this.label});
  @override
  Widget build(BuildContext context) => Container(padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 9), decoration: BoxDecoration(color: panel, borderRadius: BorderRadius.circular(12), border: Border.all(color: teal.withOpacity(.12))), child: Row(mainAxisSize: MainAxisSize.min, children: [Icon(icon, color: teal, size: 16), const SizedBox(width: 6), Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600))]));
}

class DemoDisclaimer extends StatelessWidget {
  const DemoDisclaimer({super.key});
  @override
  Widget build(BuildContext context) => Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: amber.withOpacity(.08), borderRadius: BorderRadius.circular(12), border: Border.all(color: amber.withOpacity(.18))), child: const Row(crossAxisAlignment: CrossAxisAlignment.start, children: [Icon(Icons.info_outline, color: amber, size: 18), SizedBox(width: 8), Expanded(child: Text('Prototipe tampilan. Angka, harga, sinyal, dan skor adalah data contoh, bukan data pasar aktual atau rekomendasi transaksi.', style: TextStyle(color: Colors.white70, fontSize: 10, height: 1.4)))]));
}
