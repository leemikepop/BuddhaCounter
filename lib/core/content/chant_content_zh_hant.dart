import 'chant_content.dart';

/// 繁體中文內容 (主語言)：曲名沿用音檔 metadata 與 [ChantSong.title] 常數
class ChantContentZhHant extends ChantContent {
  const ChantContentZhHant();

  @override
  Map<int, String> get songTitles => const {};

  @override
  Map<String, String> get artistNames => const {};

  @override
  String get defaultArtist => '三寶弟子';

  @override
  String get defaultAlbum => '念佛計數器';

  @override
  List<HuiXiangItem> get huiXiangItems => const [
        HuiXiangItem(
          title: '大回向西方文',
          verses: [
            '願我臨終無障礙 阿彌陀佛遠相迎',
            '觀音甘露灑吾頭 勢至金臺安我足',
            '一剎那中離五濁 屈伸臂頃到蓮池',
            '蓮花開後見慈尊 親聽法音可了了',
            '聞已即悟無生忍 不違安養入娑婆',
            '善知方便度眾生 巧把塵勞為佛事',
          ],
        ),
        HuiXiangItem(
          title: '回向偈',
          verses: [
            '願生西方淨土中 九品蓮花為父母',
            '花開見佛悟無生 不退菩薩為伴侶',
          ],
        ),
      ];
}
