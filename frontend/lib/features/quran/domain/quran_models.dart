/// سورة من القرآن الكريم مع آياتها.
class Surah {
  final int number; // 1..114
  final String name; // الاسم بالعربية
  final String englishName; // النقحرة اللاتينية
  final bool isMeccan;
  final List<String> ayahs; // نص كل آية (الفهرس 0 = الآية 1)

  const Surah({
    required this.number,
    required this.name,
    required this.englishName,
    required this.isMeccan,
    required this.ayahs,
  });

  int get ayahCount => ayahs.length;

  factory Surah.fromJson(Map<String, dynamic> j) => Surah(
        number: j['i'] as int,
        name: j['n'] as String,
        englishName: j['e'] as String,
        isMeccan: (j['t'] as String) == 'meccan',
        ayahs: (j['v'] as List).map((e) => e as String).toList(),
      );
}

/// بداية كل جزء من الأجزاء الثلاثين: (رقم السورة، رقم الآية) — رواية حفص.
class JuzStart {
  final int juz;
  final int surah;
  final int ayah;
  const JuzStart(this.juz, this.surah, this.ayah);
}

const List<JuzStart> kJuzStarts = [
  JuzStart(1, 1, 1),
  JuzStart(2, 2, 142),
  JuzStart(3, 2, 253),
  JuzStart(4, 3, 93),
  JuzStart(5, 4, 24),
  JuzStart(6, 4, 148),
  JuzStart(7, 5, 82),
  JuzStart(8, 6, 111),
  JuzStart(9, 7, 88),
  JuzStart(10, 8, 41),
  JuzStart(11, 9, 93),
  JuzStart(12, 11, 6),
  JuzStart(13, 12, 53),
  JuzStart(14, 15, 1),
  JuzStart(15, 17, 1),
  JuzStart(16, 18, 75),
  JuzStart(17, 21, 1),
  JuzStart(18, 23, 1),
  JuzStart(19, 25, 21),
  JuzStart(20, 27, 56),
  JuzStart(21, 29, 46),
  JuzStart(22, 33, 31),
  JuzStart(23, 36, 28),
  JuzStart(24, 39, 32),
  JuzStart(25, 41, 47),
  JuzStart(26, 46, 1),
  JuzStart(27, 51, 31),
  JuzStart(28, 58, 1),
  JuzStart(29, 67, 1),
  JuzStart(30, 78, 1),
];

JuzStart juzStartFor(int juz) =>
    kJuzStarts.firstWhere((j) => j.juz == juz, orElse: () => kJuzStarts.first);
