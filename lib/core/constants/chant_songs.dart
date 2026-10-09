class ChantSong {
  final int id;
  final String title;
  final String assetPath;
  final int beatIntervalMs; // 每唱誦一次佛號的週期（毫秒），對應原版 bb 變數

  const ChantSong({
    required this.id,
    required this.title,
    required this.assetPath,
    required this.beatIntervalMs,
  });
}

class ChantConstants {
  /// 完整 31 首佛曲清單、正確音檔路徑與精確節拍週期 (bb 毫秒數)
  /// 忠實提取自原 Count3 專案 Main6Activity.java 及 strings.xml
  static const List<ChantSong> allSongs = [
    ChantSong(
      id: 0,
      title: '阿彌陀佛-四字四音',
      assetPath: 'audio/amitabha.mp3',
      beatIntervalMs: 3850,
    ),
    ChantSong(
      id: 1,
      title: '思鄉佛號-六字洪名-南無阿彌陀佛',
      assetPath: 'audio/bb2.mp3',
      beatIntervalMs: 7580,
    ),
    ChantSong(
      id: 2,
      title: '靈巖梵唄-南無阿彌陀佛聖號-六度彌陀',
      assetPath: 'audio/bb3.mp3',
      beatIntervalMs: 13510,
    ),
    ChantSong(
      id: 3,
      title: '靈巖梵唄-懷念恩師六度彌陀',
      assetPath: 'audio/bb4.mp3',
      beatIntervalMs: 8060,
    ),
    ChantSong(
      id: 4,
      title: '阿彌陀佛-四字四配樂',
      assetPath: 'audio/bb5.mp3',
      beatIntervalMs: 3420,
    ),
    ChantSong(
      id: 5,
      title: '南無阿彌陀佛聖號-六字四音-歸鄉佛號',
      assetPath: 'audio/bb6.mp3',
      beatIntervalMs: 9460,
    ),
    ChantSong(
      id: 6,
      title: '阿彌陀佛-四字四音-男聲清晰慢速版',
      assetPath: 'audio/bb7.mp3',
      beatIntervalMs: 5590,
    ),
    ChantSong(
      id: 7,
      title: '阿彌陀佛聖號 四字四音 快板',
      assetPath: 'audio/bb8.mp3',
      beatIntervalMs: 1920,
    ),
    ChantSong(
      id: 8,
      title: '南無阿彌陀佛 華樂版',
      assetPath: 'audio/bb9.mp3',
      beatIntervalMs: 7990,
    ),
    ChantSong(
      id: 9,
      title: '阿彌陀佛聖號 助念',
      assetPath: 'audio/bb10.mp3',
      beatIntervalMs: 5400,
    ),
    ChantSong(
      id: 10,
      title: '淨空法師念佛 中速 四字版',
      assetPath: 'audio/bb11.mp3',
      beatIntervalMs: 1380,
    ),
    ChantSong(
      id: 11,
      title: '阿彌陀佛 十念法',
      assetPath: 'audio/bb12.mp3',
      beatIntervalMs: 5900,
    ),
    ChantSong(
      id: 12,
      title: '南無阿彌陀佛 六字二音 慢速 台灣靈嚴山寺',
      assetPath: 'audio/bb13.mp3',
      beatIntervalMs: 8850,
    ),
    ChantSong(
      id: 13,
      title: '阿彌陀佛聖號 男女對唱',
      assetPath: 'audio/bb14.mp3',
      beatIntervalMs: 5970,
    ),
    ChantSong(
      id: 14,
      title: '佛光山唱誦佛號 六字',
      assetPath: 'audio/bb15.mp3',
      beatIntervalMs: 5400,
    ),
    ChantSong(
      id: 15,
      title: '佛光山唱誦佛號 四字',
      assetPath: 'audio/bb16.mp3',
      beatIntervalMs: 2700,
    ),
    ChantSong(
      id: 16,
      title: '南無觀世音菩薩聖號 七字五音',
      assetPath: 'audio/bb17.mp3',
      beatIntervalMs: 6450,
    ),
    ChantSong(
      id: 17,
      title: '淨空老法師念佛(慢版)',
      assetPath: 'audio/bb18.mp3',
      beatIntervalMs: 6020,
    ),
    ChantSong(
      id: 18,
      title: '南無阿彌陀佛(朝山)',
      assetPath: 'audio/bb19.mp3',
      beatIntervalMs: 9540,
    ),
    ChantSong(
      id: 19,
      title: '南無釋迦牟尼佛(朝山)',
      assetPath: 'audio/bb20.mp3',
      beatIntervalMs: 8920,
    ),
    ChantSong(
      id: 20,
      title: '南無觀世音菩薩(朝山)',
      assetPath: 'audio/bb21.mp3',
      beatIntervalMs: 9550,
    ),
    ChantSong(
      id: 21,
      title: '南無地藏王菩薩(朝山)',
      assetPath: 'audio/bb22.mp3',
      beatIntervalMs: 7820,
    ),
    ChantSong(
      id: 22,
      title: '南無阿彌陀佛-六字四音-印光大師版',
      assetPath: 'audio/bb23.mp3',
      beatIntervalMs: 5530,
    ),
    ChantSong(
      id: 23,
      title: '六字大明咒',
      assetPath: 'audio/bb24.mp3',
      beatIntervalMs: 3630,
    ),
    ChantSong(
      id: 24,
      title: '悟行法師地鐘念佛(全)',
      assetPath: 'audio/bb25.mp3',
      beatIntervalMs: 2000,
    ),
    ChantSong(
      id: 25,
      title: '呼吸五段念佛',
      assetPath: 'audio/bb26.mp3',
      beatIntervalMs: 4000,
    ),
    ChantSong(
      id: 26,
      title: '淨空法師念佛 快速四字版',
      assetPath: 'audio/bb27.mp3',
      beatIntervalMs: 750,
    ),
    ChantSong(
      id: 27,
      title: '南無阿彌陀佛 台語六字',
      assetPath: 'audio/bb28.mp3',
      beatIntervalMs: 4248,
    ),
    ChantSong(
      id: 28,
      title: '夏蓮居老居士六字佛號音調',
      assetPath: 'audio/bb29.mp3',
      beatIntervalMs: 3352,
    ),
    ChantSong(
      id: 29,
      title: '南無阿彌陀佛-印光大師版(木魚)',
      assetPath: 'audio/bb30.mp3',
      beatIntervalMs: 6909,
    ),
    ChantSong(
      id: 30,
      title: '南無阿彌陀佛淨宗法師念誦',
      assetPath: 'audio/bb31.mp3',
      beatIntervalMs: 3949,
    ),
  ];

  static List<ChantSong> getAllSongs() => allSongs;

  static ChantSong getSongById(int id) {
    if (id >= 0 && id < allSongs.length) {
      return allSongs[id];
    }
    return allSongs[0];
  }

  // 大回向西方文
  static const String huiXiangTitle = '大回向西方文';
  static const List<String> huiXiangVerses = [
    '願我臨終無障礙 阿彌陀佛遠相迎',
    '觀音甘露灑吾頭 勢至金臺安我足',
    '一剎那中離五濁 屈伸臂頃到蓮池',
    '蓮花開後見慈尊 親聽法音可了了',
    '聞已即悟無生忍 不違安養入娑婆',
    '善知方便度眾生 巧把塵勞為佛事',
  ];
}
