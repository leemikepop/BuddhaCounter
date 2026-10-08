class ChantSong {
  final int id;
  final String title;
  final String assetPath;

  const ChantSong({
    required this.id,
    required this.title,
    required this.assetPath,
  });
}

class ChantConstants {
  static const List<String> chantTitles = [
    '阿彌陀佛-四字四音',
    '思鄉佛號-六字洪名-南無阿彌陀佛',
    '靈巖梵唄-南無阿彌陀佛聖號-六度彌陀',
    '靈巖梵唄-懷念恩師六度彌陀',
    '阿彌陀佛-四字四配樂',
    '南無阿彌陀佛聖號-六字四音-歸鄉佛號',
    '阿彌陀佛-四字四音-男聲清晰慢速版',
    '阿彌陀佛聖號 四字四音 快板',
    '南無阿彌陀佛 華樂版',
    '阿彌陀佛聖號 助念',
    '淨空法師念佛 中速 四字版',
    '阿彌陀佛 十念法',
    '南無阿彌陀佛 六字二音 慢速 台灣靈嚴山寺',
    '阿彌陀佛聖號 男女對唱',
    '佛光山唱誦佛號 六字',
    '佛光山唱誦佛號 四字',
    '南無觀世音菩薩聖號 七字五音',
    '淨空老法師念佛(慢版)',
    '南無阿彌陀佛(朝山)',
    '南無釋迦牟尼佛(朝山)',
    '南無觀世音菩薩(朝山)',
    '南無地藏王菩薩(朝山)',
    '南無阿彌陀佛-印光大師版(配樂)',
    '六字大明咒',
    '悟行法師地鐘念佛(全)',
    '呼吸五段念佛',
    '淨空法師念佛 快速四字版',
    '南無阿彌陀佛 台語六字',
    '夏蓮居老居士六字佛號音調',
    '南無阿彌陀佛-印光大師版(木魚)',
    '南無阿彌陀佛淨宗法師念誦',
  ];

  static List<ChantSong> getAllSongs() {
    return List.generate(chantTitles.length, (index) {
      final id = index + 1;
      return ChantSong(
        id: id,
        title: chantTitles[index],
        assetPath: 'audio/bb$id.mp3',
      );
    });
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
