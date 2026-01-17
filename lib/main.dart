import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_options.dart';

// --- GLOBAL KULLANICI HAFIZASI ---
// Uygulamanın her yerinden "Şu an kim içeride?" sorusunun cevabını buradan alacağız.
class AktifKullanici {
  static String? email;
  static String? rol; // 'superadmin', 'yonetici', 'personel'
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Firebase'i başlat
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const MasrafUygulamasi());
}

class MasrafUygulamasi extends StatelessWidget {
  const MasrafUygulamasi({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Masraf Asistanı',
      theme: ThemeData(
        // --- MODERN TEMA AYARLARI ---
        primaryColor: Colors.indigo,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.indigo,
          secondary: Colors.orangeAccent,
        ),
        useMaterial3: true,
        scaffoldBackgroundColor: Colors.grey[50], // Arka plan hafif gri
        // AppBar Tasarımı
        appBarTheme: const AppBarTheme(
          centerTitle: true,
          elevation: 0,
          backgroundColor: Colors.indigo,
          foregroundColor: Colors.white,
          titleTextStyle: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),

        // Input (Yazı Kutusu) Tasarımı
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.all(16),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: const BorderSide(color: Colors.indigo, width: 2),
          ),
        ),
      ),
      home: const LoginEkrani(),
    );
  }
}

// --- GİRİŞ EKRANI (LOGIN) ---
class LoginEkrani extends StatefulWidget {
  const LoginEkrani({super.key});

  @override
  State<LoginEkrani> createState() => _LoginEkraniState();
}

class _LoginEkraniState extends State<LoginEkrani> {
  String? _seciliMod; // Kullanıcı hangi kartı seçti?
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _sifreController = TextEditingController();
  bool _isLoading = false;

  // --- İLK KURULUM (GELİŞTİRİCİ BUTONU) ---
  Future<void> _gelistiriciHesabiOlustur() async {
    // Bu buton veritabanına senin hesabını yazar.
    await FirebaseFirestore.instance
        .collection('kullanicilar')
        .doc('dev@yazilim.com')
        .set({
          'email': 'dev@yazilim.com',
          'sifre': 'admin123',
          'rol': 'superadmin', // En yüksek yetki
          'olusturan': 'system',
        });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("✅ Geliştirici Hesabı (dev@yazilim.com) oluşturuldu!"),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  // --- GİRİŞ YAP FONKSİYONU ---
  Future<void> _girisYap() async {
    if (_emailController.text.isEmpty || _sifreController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Lütfen tüm alanları doldurun."),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // 1. Veritabanından kullanıcıyı sorgula
      var sorgu = await FirebaseFirestore.instance
          .collection('kullanicilar')
          .where('email', isEqualTo: _emailController.text.trim())
          .where('sifre', isEqualTo: _sifreController.text.trim())
          .get();

      if (sorgu.docs.isNotEmpty) {
        var kullaniciVerisi = sorgu.docs.first.data();
        String veritabaniRolu = kullaniciVerisi['rol'];

        // 2. KAPI KONTROLÜ (Doğru karttan mı girdi?)
        if (_seciliMod == 'personel' && veritabaniRolu != 'personel') {
          throw "HATA: Yöneticiler 'Personel Girişi' kısmını kullanamaz.";
        }
        if (_seciliMod == 'yonetici' && veritabaniRolu == 'personel') {
          throw "HATA: Personeller 'Yönetici Girişi' kısmını kullanamaz.";
        }

        // 3. Giriş Başarılı - Bilgileri hafızaya al
        AktifKullanici.email = kullaniciVerisi['email'];
        AktifKullanici.rol = veritabaniRolu;

        if (mounted) {
          // Doğru panele yönlendir
          if (AktifKullanici.rol == 'personel') {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const KullaniciPanel()),
            );
          } else {
            // Süper Admin veya Yönetici ise
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const YoneticiPanel()),
            );
          }
        }
      } else {
        throw "Kullanıcı adı veya şifre hatalı!";
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            // Mod seçildiyse Formu, seçilmediyse Kartları göster
            child: _seciliMod == null
                ? _buildSecimEkrani()
                : _buildGirisFormu(),
          ),
        ),
      ),
    );
  }

  // EKRAN 1: KART SEÇİMİ
  Widget _buildSecimEkrani() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.shield_moon, size: 80, color: Colors.indigo),
        const SizedBox(height: 20),
        const Text(
          "Masraf Asistanı",
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Colors.indigo,
          ),
        ),
        const Text(
          "Güvenli Giriş Portalı",
          style: TextStyle(fontSize: 16, color: Colors.grey),
        ),
        const SizedBox(height: 50),

        // Kartlar Yan Yana
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildRolKarti(
              baslik: "PERSONEL",
              ikon: Icons.badge,
              renk: Colors.blueAccent,
              tiklama: () => setState(() => _seciliMod = 'personel'),
            ),
            const SizedBox(width: 20),
            _buildRolKarti(
              baslik: "YÖNETİCİ\n(Patron)",
              ikon: Icons.business_center,
              renk: Colors.orange.shade800,
              tiklama: () => setState(() => _seciliMod = 'yonetici'),
            ),
          ],
        ),

        const SizedBox(height: 60),
        // GİZLİ KURULUM BUTONU
        TextButton.icon(
          onPressed: _gelistiriciHesabiOlustur,
          icon: const Icon(Icons.build_circle, size: 20, color: Colors.grey),
          label: const Text(
            "Geliştirici Kurulumu (İlk Sefer)",
            style: TextStyle(color: Colors.grey),
          ),
        ),
      ],
    );
  }

  // EKRAN 2: FORM GİRİŞİ
  Widget _buildGirisFormu() {
    bool isPersonel = _seciliMod == 'personel';
    Color temaRengi = isPersonel ? Colors.blueAccent : Colors.orange.shade800;
    String baslik = isPersonel ? "Personel Girişi" : "Yönetici Girişi";

    return Column(
      children: [
        Align(
          alignment: Alignment.topLeft,
          child: IconButton(
            icon: const Icon(Icons.arrow_back_ios, color: Colors.grey),
            onPressed: () => setState(() => _seciliMod = null),
          ),
        ),

        const SizedBox(height: 10),
        Icon(
          isPersonel ? Icons.badge : Icons.business_center,
          size: 70,
          color: temaRengi,
        ),
        const SizedBox(height: 15),
        Text(
          baslik,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: temaRengi,
          ),
        ),
        const SizedBox(height: 40),

        TextField(
          controller: _emailController,
          decoration: const InputDecoration(
            labelText: "E-posta Adresi",
            prefixIcon: Icon(Icons.email_outlined),
          ),
        ),
        const SizedBox(height: 20),
        TextField(
          controller: _sifreController,
          obscureText: true,
          decoration: const InputDecoration(
            labelText: "Şifre",
            prefixIcon: Icon(Icons.lock_outline),
          ),
        ),

        const SizedBox(height: 30),

        _isLoading
            ? CircularProgressIndicator(color: temaRengi)
            : SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: _girisYap,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: temaRengi,
                    foregroundColor: Colors.white,
                    elevation: 5,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                  child: const Text(
                    "GÜVENLİ GİRİŞ",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
      ],
    );
  }

  Widget _buildRolKarti({
    required String baslik,
    required IconData ikon,
    required Color renk,
    required VoidCallback tiklama,
  }) {
    return GestureDetector(
      onTap: tiklama,
      child: Container(
        width: 150,
        height: 190,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(25),
          border: Border.all(color: renk.withOpacity(0.2), width: 2),
          boxShadow: [
            BoxShadow(
              color: renk.withOpacity(0.15),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: renk.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(ikon, size: 40, color: renk),
            ),
            const SizedBox(height: 20),
            Text(
              baslik,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: renk,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// --- YÖNETİCİ VE SÜPER ADMIN PANELİ ---
class YoneticiPanel extends StatefulWidget {
  const YoneticiPanel({super.key});
  @override
  State<YoneticiPanel> createState() => _YoneticiPanelState();
}

class _YoneticiPanelState extends State<YoneticiPanel> {
  int _seciliSayfa = 0;

  // Sayfa Listesi
  final List<Widget> _sayfalar = [
    const DashboardSayfasi(), // 0: Özet
    const TumGiderlerSayfasi(), // 1: Tüm Liste
    const KullaniciEkleSayfasi(), // 2: Ekip Yönetimi
    const ProfilSayfasi(), // 3: Profil
  ];

  @override
  Widget build(BuildContext context) {
    String baslik = AktifKullanici.rol == 'superadmin'
        ? "Geliştirici Konsolu"
        : "Patron Paneli";

    return Scaffold(
      appBar: AppBar(
        title: Text(baslik),
        backgroundColor: Colors.orange.shade800,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const LoginEkrani()),
            ),
          ),
        ],
      ),
      body: _sayfalar[_seciliSayfa],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _seciliSayfa,
        onDestinationSelected: (index) => setState(() => _seciliSayfa = index),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.dashboard), label: "Özet"),
          NavigationDestination(
            icon: Icon(Icons.receipt_long),
            label: "Giderler",
          ),
          NavigationDestination(icon: Icon(Icons.group_add), label: "Yönetim"),
          NavigationDestination(icon: Icon(Icons.person), label: "Profil"),
        ],
      ),
    );
  }
}

// --- PERSONEL PANELİ ---
class KullaniciPanel extends StatefulWidget {
  const KullaniciPanel({super.key});
  @override
  State<KullaniciPanel> createState() => _KullaniciPanelState();
}

class _KullaniciPanelState extends State<KullaniciPanel> {
  int _seciliSayfa = 1; // Başlangıçta "Ekle" sayfasını açabiliriz veya listeyi.

  final List<Widget> _sayfalar = [
    const KullaniciGiderListesi(), // 0: Kendi Listesi
    const GiderEkleSayfasi(), // 1: Ekleme
    const ProfilSayfasi(), // 2: Profil
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Personel Paneli"),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const LoginEkrani()),
            ),
          ),
        ],
      ),
      body: _sayfalar[_seciliSayfa],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _seciliSayfa,
        onDestinationSelected: (index) => setState(() => _seciliSayfa = index),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.history), label: "Geçmiş"),
          NavigationDestination(
            icon: Icon(Icons.add_circle, size: 30, color: Colors.indigo),
            label: "Masraf Ekle",
          ),
          NavigationDestination(icon: Icon(Icons.person), label: "Profil"),
        ],
      ),
    );
  }
}

// --- EKİP KURMA / KULLANICI EKLEME SAYFASI ---
class KullaniciEkleSayfasi extends StatefulWidget {
  const KullaniciEkleSayfasi({super.key});

  @override
  State<KullaniciEkleSayfasi> createState() => _KullaniciEkleSayfasiState();
}

class _KullaniciEkleSayfasiState extends State<KullaniciEkleSayfasi> {
  final TextEditingController _mailController = TextEditingController();
  final TextEditingController _sifreController = TextEditingController();

  Future<void> _kullaniciyiKaydet() async {
    if (_mailController.text.isEmpty || _sifreController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Lütfen tüm alanları doldurun.")),
      );
      return;
    }

    // --- SENARYO MANTIĞI ---
    String eklenecekRol = '';
    String basariMesaji = '';

    if (AktifKullanici.rol == 'superadmin') {
      // Sen -> Patron Eklersin
      eklenecekRol = 'yonetici';
      basariMesaji = "✅ Yeni Müşteri (Patron) sisteme tanımlandı!";
    } else if (AktifKullanici.rol == 'yonetici') {
      // Patron -> Personel Ekler
      eklenecekRol = 'personel';
      basariMesaji = "✅ Yeni Personel ekibe eklendi!";
    } else {
      return;
    }

    try {
      await FirebaseFirestore.instance
          .collection('kullanicilar')
          .doc(_mailController.text.trim())
          .set({
            'email': _mailController.text.trim(),
            'sifre': _sifreController.text.trim(),
            'rol': eklenecekRol,
            'olusturan': AktifKullanici.email,
            'olusturulma_tarihi': Timestamp.now(),
          });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(basariMesaji), backgroundColor: Colors.green),
      );
      _mailController.clear();
      _sifreController.clear();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Bir hata oluştu!"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    bool isSuperAdmin = AktifKullanici.rol == 'superadmin';

    String baslik = isSuperAdmin
        ? "YENİ MÜŞTERİ (PATRON) EKLE"
        : "YENİ PERSONEL EKLE";
    String aciklama = isSuperAdmin
        ? "Uygulamayı sattığınız işletme sahibinin giriş bilgilerini buradan oluşturun."
        : "İşletmenizde çalışacak personelin giriş bilgilerini tanımlayın.";
    Color renk = isSuperAdmin ? Colors.orange : Colors.indigo;
    IconData ikon = isSuperAdmin ? Icons.domain_add : Icons.person_add;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Column(
              children: [
                Icon(ikon, size: 60, color: renk),
                const SizedBox(height: 15),
                Text(
                  baslik,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: renk,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  aciklama,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 30),

                TextField(
                  controller: _mailController,
                  decoration: const InputDecoration(
                    labelText: "Kullanıcı E-posta Adresi",
                    prefixIcon: Icon(Icons.email),
                  ),
                ),
                const SizedBox(height: 15),
                TextField(
                  controller: _sifreController,
                  decoration: const InputDecoration(
                    labelText: "Giriş Şifresi Belirle",
                    prefixIcon: Icon(Icons.vpn_key),
                  ),
                ),
                const SizedBox(height: 30),

                SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: ElevatedButton.icon(
                    onPressed: _kullaniciyiKaydet,
                    icon: const Icon(Icons.check_circle),
                    label: const Text("KULLANICIYI OLUŞTUR"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black87,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// --- PERSONEL İÇİN ÖZEL LİSTE (HATA YAKALAYICI) ---
class KullaniciGiderListesi extends StatelessWidget {
  const KullaniciGiderListesi({super.key});
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      // Firebase Index gerektiren sorgu:
      stream: FirebaseFirestore.instance
          .collection('giderler')
          .where('ekleyen', isEqualTo: AktifKullanici.email) // Filtre
          .orderBy('tarih', descending: true) // Sıralama
          .snapshots(),
      builder: (context, snapshot) {
        // 🚨 1. HATA DURUMU (INDEX HATASI BURAYA DÜŞER)
        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.warning_amber_rounded,
                    size: 60,
                    color: Colors.red,
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    "FİREBASE YAPILANDIRMASI EKSİK",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.red,
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    "Verileri filtrelemek ve sıralamak için 'Index' oluşturmalısınız.",
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 15),
                  Container(
                    padding: const EdgeInsets.all(10),
                    color: Colors.grey[200],
                    child: SelectableText(
                      "${snapshot.error}", // Hata mesajının kendisi (Link burada)
                      style: const TextStyle(
                        fontSize: 10,
                        fontFamily: 'Courier',
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    "ÇÖZÜM: Yukarıdaki linki kopyalayıp tarayıcıda açın.",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          );
        }

        if (snapshot.connectionState == ConnectionState.waiting)
          return const Center(child: CircularProgressIndicator());

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text("Henüz hiç harcama kaydı yok."));
        }

        // 2. VERİ LİSTELEME VE SİLME (SWIPE)
        return ListView.separated(
          padding: const EdgeInsets.all(15),
          separatorBuilder: (c, i) => const SizedBox(height: 10),
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            var doc = snapshot.data!.docs[index];
            return Dismissible(
              key: Key(doc.id),
              direction: DismissDirection.endToStart,
              background: Container(
                alignment: Alignment.centerRight,
                padding: const EdgeInsets.only(right: 20),
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(15),
                ),
                child: const Icon(Icons.delete, color: Colors.white),
              ),
              confirmDismiss: (direction) async {
                return await showDialog(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text("Silinsin mi?"),
                    content: const Text("Bu harcama silinecek."),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        child: const Text("Vazgeç"),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, true),
                        child: const Text(
                          "SİL",
                          style: TextStyle(color: Colors.red),
                        ),
                      ),
                    ],
                  ),
                );
              },
              onDismissed: (_) => FirebaseFirestore.instance
                  .collection('giderler')
                  .doc(doc.id)
                  .delete(),
              child: Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.indigo[100],
                    child: const Icon(Icons.person, color: Colors.indigo),
                  ),
                  title: Text(
                    doc['aciklama'],
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: const Text("Kişisel Harcama"),
                  trailing: Text(
                    "${doc['tutar']} ₺",
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.indigo,
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

// --- GİDER EKLEME SAYFASI ---
class GiderEkleSayfasi extends StatefulWidget {
  const GiderEkleSayfasi({super.key});
  @override
  State<GiderEkleSayfasi> createState() => _GiderEkleSayfasiState();
}

class _GiderEkleSayfasiState extends State<GiderEkleSayfasi> {
  final TextEditingController _tutar = TextEditingController();
  final TextEditingController _aciklama = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 10),
              ],
            ),
            child: Column(
              children: [
                const Text(
                  "YENİ FİŞ GİRİŞİ",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: Colors.indigo,
                  ),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: _tutar,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: "Tutar",
                    suffixText: "₺",
                    prefixIcon: Icon(Icons.attach_money),
                  ),
                ),
                const SizedBox(height: 15),
                TextField(
                  controller: _aciklama,
                  decoration: const InputDecoration(
                    labelText: "Açıklama / Fiş No",
                    prefixIcon: Icon(Icons.description),
                  ),
                ),
                const SizedBox(height: 30),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: () {
                      if (_tutar.text.isNotEmpty && _aciklama.text.isNotEmpty) {
                        FirebaseFirestore.instance.collection('giderler').add({
                          'tutar': double.parse(_tutar.text),
                          'aciklama': _aciklama.text,
                          'tarih': Timestamp.now(),
                          'ekleyen': AktifKullanici.email,
                        });
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text("Masraf kaydedildi!"),
                            backgroundColor: Colors.green,
                          ),
                        );
                        _tutar.clear();
                        _aciklama.clear();
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.indigo,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text("KAYDET"),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// --- DASHBOARD SAYFASI (PATRON EKRANI) ---
class DashboardSayfasi extends StatelessWidget {
  const DashboardSayfasi({super.key});
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('giderler').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData)
          return const Center(child: CircularProgressIndicator());

        double toplamTutar = 0;
        for (var doc in snapshot.data!.docs) {
          toplamTutar += double.tryParse(doc['tutar'].toString()) ?? 0;
        }

        return Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(25),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.orange.shade800, Colors.orangeAccent],
                  ),
                  borderRadius: BorderRadius.circular(25),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.orange.withOpacity(0.4),
                      blurRadius: 15,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    const Text(
                      "Toplam İşletme Gideri",
                      style: TextStyle(color: Colors.white70, fontSize: 16),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      "${toplamTutar.toStringAsFixed(2)} ₺",
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      "${snapshot.data!.docs.length} İşlem Kaydı",
                      style: const TextStyle(color: Colors.white),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// --- TÜM GİDERLER SAYFASI (PATRON İÇİN SİLME ÖZELLİKLİ) ---
class TumGiderlerSayfasi extends StatelessWidget {
  const TumGiderlerSayfasi({super.key});
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('giderler')
          .orderBy('tarih', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData)
          return const Center(child: CircularProgressIndicator());

        return ListView.separated(
          padding: const EdgeInsets.all(15),
          separatorBuilder: (c, i) => const SizedBox(height: 10),
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            var doc = snapshot.data!.docs[index];
            return Dismissible(
              key: Key(doc.id),
              direction: DismissDirection.endToStart,
              background: Container(
                alignment: Alignment.centerRight,
                padding: const EdgeInsets.only(right: 20),
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(15),
                ),
                child: const Icon(Icons.delete, color: Colors.white),
              ),
              confirmDismiss: (direction) async {
                return await showDialog(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text("Silinsin mi?"),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        child: const Text("Hayır"),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, true),
                        child: const Text("Evet"),
                      ),
                    ],
                  ),
                );
              },
              onDismissed: (_) => FirebaseFirestore.instance
                  .collection('giderler')
                  .doc(doc.id)
                  .delete(),
              child: Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.orange[100],
                    child: const Text(
                      "₺",
                      style: TextStyle(
                        color: Colors.orange,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  title: Text(doc['aciklama']),
                  subtitle: Text(doc['ekleyen']),
                  trailing: Text(
                    "${doc['tutar']} ₺",
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.red,
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

// --- PROFİL SAYFASI ---
class ProfilSayfasi extends StatelessWidget {
  const ProfilSayfasi({super.key});
  @override
  Widget build(BuildContext context) {
    bool isAdmin = AktifKullanici.rol != 'personel';
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircleAvatar(
            radius: 60,
            backgroundColor: isAdmin ? Colors.orange[100] : Colors.indigo[100],
            child: Icon(
              isAdmin ? Icons.business : Icons.person,
              size: 60,
              color: isAdmin ? Colors.orange : Colors.indigo,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            AktifKullanici.email ?? "",
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          Text(
            isAdmin ? "Yönetici / Patron Hesabı" : "Personel Hesabı",
            style: const TextStyle(color: Colors.grey, fontSize: 16),
          ),
          const SizedBox(height: 40),
          ElevatedButton.icon(
            onPressed: () => Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const LoginEkrani()),
            ),
            icon: const Icon(Icons.logout),
            label: const Text("GÜVENLİ ÇIKIŞ"),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade50,
              foregroundColor: Colors.red,
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
            ),
          ),
        ],
      ),
    );
  }
}
