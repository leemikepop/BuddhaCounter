import 'chant_content.dart';

/// English content. Titles follow `Name - version - source`.
/// Terminology follows lib/l10n/GLOSSARY.md (draft — to be reviewed).
class ChantContentEn extends ChantContent {
  const ChantContentEn();

  @override
  Map<int, String> get songTitles => const {
        0: 'Amitabha Buddha - 4-character, 4-tone - Hwa Dzan Pure Land - Ven. Wu Dao',
        1: 'Amitabha Buddha - 4-character, 4-tone with music - Hwa Dzan Pure Land',
        2: 'Amitabha Buddha - 4-character, 4-tone - slow, with hand bell',
        3: 'Amitabha Buddha - 4-character, 4-tone - female voices, slow',
        4: 'Amitabha Buddha - 4-character, 4-tone - female voices, fast - Ling Yen Mountain Temple',
        5: 'Amitabha Buddha - 4-character, medium - Ven. Master Chin Kung',
        6: 'Amitabha Buddha - 4-character, fast - Ven. Master Chin Kung',
        7: 'Amitabha Buddha - voice only, slow - Ven. Master Chin Kung',
        8: 'Amitabha Buddha - earth-bell recitation, slow - Ven. Wu Xing',
        9: 'Amitabha Buddha - chant - Fo Guang Shan',
        10: 'Amitabha Buddha - Ten Recitations method',
        11: 'Namo Amitabha Buddha - Longing for Home - Xianglin Vihara - Ven. Kai Song',
        12: 'Namo Amitabha Buddha - 6-character, 4-tone - Returning Home',
        13: 'Namo Amitabha Buddha - 6-character, 4-tone - Chinese orchestral',
        14: 'Namo Amitabha Buddha - 6-character, 2-tone, slow - Ling Yen Mountain Temple',
        15: 'Namo Amitabha Buddha - 6-character chant, slow - Great Master Yinguang style',
        16: 'Namo Amitabha Buddha - 6-character chant, medium - Great Master Yinguang style',
        17: 'Namo Amitabha Buddha - chant - Fo Guang Shan',
        18: 'Namo Amitabha Buddha - 6- and 4-character - male & female duet',
        19: 'Namo Amitabha Buddha - five-stage breathing, with music',
        20: 'Namo Amitabha Buddha - slow recitation - Ven. Jing Zong',
        21: 'Namo Amitabha Buddha - Taiwanese, slow - Shalu Amitabha Hall - Upasaka Chen You-hong',
        22: 'Namo Amitabha Buddha - Elder Upasaka Xia Lianju',
        23: 'Namo Amitabha Buddha - Six Paramitas - Ling Yen Chant - Novice Monk',
        24: 'Namo Amitabha Buddha - Remembering Our Teacher - Ling Yen Chant - Novice Monk',
        25: 'Namo Amitabha Buddha - Pilgrimage chant - Ling Yen Chant - Novice Monk',
        26: 'Namo Shakyamuni Buddha - Pilgrimage chant - Ling Yen Chant - Novice Monk',
        27: 'Namo Ksitigarbha Bodhisattva - Pilgrimage chant - Ling Yen Chant - Novice Monk',
        28: 'Namo Avalokiteshvara Bodhisattva - Pilgrimage chant - Ling Yen Chant - Novice Monk',
        29: 'Namo Avalokiteshvara Bodhisattva - 7-character, 5-tone - solemn music',
        30: 'Six-Syllable Mantra (Om Mani Padme Hum) - female voice',
      };

  @override
  Map<String, String> get artistNames => const {
        '三寶弟子': 'Disciple of the Triple Gem',
        '悟道法師': 'Ven. Wu Dao',
        '淨空法師': 'Ven. Master Chin Kung',
        '悟行法師': 'Ven. Wu Xing',
        '佛光山': 'Fo Guang Shan',
        '開松法師': 'Ven. Kai Song',
        '靈巖山寺': 'Ling Yen Mountain Temple',
        '淨宗法師': 'Ven. Jing Zong',
        '陳有宏居士': 'Upasaka Chen You-hong',
        '夏蓮居老居士': 'Elder Upasaka Xia Lianju',
        '沙彌師父': 'Novice Monk',
        '靈巖梵唄': 'Ling Yen Chant',
      };

  @override
  String get defaultArtist => 'Disciple of the Triple Gem';

  @override
  String get defaultAlbum => 'Buddha Counter';

  @override
  List<HuiXiangItem> get huiXiangItems => const [
        HuiXiangItem(
          title: 'Great Dedication to the Western Pure Land',
          verses: [
            'May I, at life\'s end, be free of all obstacles, and may Amitabha Buddha come from afar to welcome me.',
            'May Avalokiteshvara sprinkle sweet dew upon my head, and Mahasthamaprapta set my feet on the golden dais.',
            'In a single instant may I leave the five turbidities, and in the time it takes to bend an arm, reach the lotus pond.',
            'When the lotus opens, may I behold the Compassionate Honored One and clearly hear the Dharma.',
            'Having heard it, may I awaken to the patience with the non-production of dharmas, and, never leaving the Land of Peace, return to this world.',
            'Skilled in expedient means to save all beings, may I turn worldly toil into the work of the Buddha.',
          ],
        ),
        HuiXiangItem(
          title: 'Verse of Dedication',
          verses: [
            'May we be reborn in the Western Pure Land, with the nine grades of lotus as our parents.',
            'When the lotus blooms, may we see the Buddha and awaken to the non-production of dharmas, with non-retreating Bodhisattvas as our companions.',
          ],
        ),
      ];
}
