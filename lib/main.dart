import 'package:flutter/material.dart';

void main() {
  runApp(const MasrafUygulamasi());
}

class MasrafUygulamasi extends StatelessWidget {
  const MasrafUygulamasi({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Masraf Yöneticisi',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blueAccent),
        useMaterial3: true,
      ),
      home: const GirisEkrani(),
    );
  }
}

// --- 1. GİRİŞ EKRANI (Aynı kaldı) ---
class GirisEkrani extends StatefulWidget {
  const GirisEkrani({super.key});

  @override
  State<GirisEkrani> createState() => _GirisEkraniState();
}

class _GirisEkraniState extends State<GirisEkrani> {
  final TextEditingController _kullaniciAdiController = TextEditingController();
  final TextEditingController _sifreController = TextEditingController();

  void _girisYap() {
    String kAdi = _kullaniciAdiController.text;
    String rol = "Kullanıcı";
    
    if (kAdi.toLowerCase() == "admin") {
      rol = "Yönetici";
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AnaSayfa(kullaniciRolu: rol, isim: kAdi),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.account_balance_wallet_rounded, size: 100, color: Colors.blueAccent),
              const SizedBox(height: 20),
              const Text('Masraf Yönetim', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
              const SizedBox(height: 40),
              TextField(
                controller: _kullaniciAdiController,
                decoration: InputDecoration(
                  labelText: 'Kullanıcı Adı',
                  prefixIcon: const Icon(Icons.person),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _sifreController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: 'Şifre',
                  prefixIcon: const Icon(Icons.lock),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _girisYap,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('GİRİŞ YAP', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// --- 2. ANA SAYFA (Burası Güzelleşti!) ---
class AnaSayfa extends StatelessWidget {
  final String kullaniciRolu;
  final String isim;

  const AnaSayfa({super.key, required this.kullaniciRolu, required this.isim});

  @override
  Widget build(BuildContext context) {
    Color temaRengi = kullaniciRolu == "Yönetici" ? Colors.redAccent : Colors.blueAccent;

    return Scaffold(
      backgroundColor: Colors.grey[100], // Hafif gri arka plan
      appBar: AppBar(
        title: Text('$kullaniciRolu Paneli'),
        backgroundColor: temaRengi,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.exit_to_app),
            onPressed: () {
              Navigator.pop(context); // Çıkış yap (Geri dön)
            },
          )
        ],
      ),
      // Yuvarlak + Butonu
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          print("Masraf Ekleme tıklandı");
        },
        backgroundColor: temaRengi,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: Column(
        children: [
          // ÜSTTEKİ BİLGİ KARTI
          Container(
            padding: const EdgeInsets.all(20),
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: temaRengi,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(color: temaRengi.withOpacity(0.5), blurRadius: 10, offset: const Offset(0, 5))
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Hoşgeldin, $isim', style: const TextStyle(color: Colors.white70, fontSize: 16)),
                    const SizedBox(height: 5),
                    const Text('₺ 14,250.00', style: TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)),
                    const Text('Bu ayki toplam harcama', style: TextStyle(color: Colors.white70, fontSize: 12)),
                  ],
                ),
                const Icon(Icons.bar_chart, color: Colors.white, size: 50),
              ],
            ),
          ),

          // LİSTE BAŞLIĞI
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("Son Harcamalar", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
                TextButton(onPressed: () {}, child: Text("Tümü", style: TextStyle(color: temaRengi))),
              ],
            ),
          ),

          // HARCAMA LİSTESİ (Örnek Veriler)
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: const [
                HarcamaKarti(baslik: "Migros Market", tarih: "Bugün, 14:30", tutar: "-₺450.00", icon: Icons.shopping_cart),
                HarcamaKarti(baslik: "Shell Benzin", tarih: "Dün, 09:15", tutar: "-₺1,200.00", icon: Icons.local_gas_station),
                HarcamaKarti(baslik: "Netflix Üyelik", tarih: "12 Ocak", tutar: "-₺299.99", icon: Icons.movie),
                HarcamaKarti(baslik: "YemekSepeti", tarih: "10 Ocak", tutar: "-₺320.50", icon: Icons.restaurant),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Liste elemanlarını şık göstermek için özel bir parça (Widget)
class HarcamaKarti extends StatelessWidget {
  final String baslik;
  final String tarih;
  final String tutar;
  final IconData icon;

  const HarcamaKarti({
    super.key,
    required this.baslik,
    required this.tarih,
    required this.tutar,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.blueAccent.withOpacity(0.1),
          child: Icon(icon, color: Colors.blueAccent),
        ),
        title: Text(baslik, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(tarih, style: const TextStyle(color: Colors.grey)),
        trailing: Text(tutar, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.red)),
      ),
    );
  }
}