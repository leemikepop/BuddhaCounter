import 'package:flutter/services.dart';
import '../utils/audio_metadata_reader.dart';

class ChantTags {
  static const String fourCharAmitabha = '四字彌陀';
  static const String sixCharAmitabha = '六字彌陀';
  static const String bodhisattvaMantra = '菩薩・持咒';
  static const String pilgrimage = '朝山聖號';
  static const String lingyan = '靈巖梵唄';
  static const String masterChant = '法師大德';
  static const String briskMedium = '快中板';
  static const String slowSolemn = '慢板';

  static const List<String> defaultOrder = [
    fourCharAmitabha,
    sixCharAmitabha,
    bodhisattvaMantra,
    pilgrimage,
    lingyan,
    masterChant,
    briskMedium,
    slowSolemn,
  ];
}

class ChantSong {
  static const String defaultArtist = '三寶弟子';
  static const String defaultAlbum = '念佛計數器';
  static const int defaultBeatIntervalMs = 4000;

  final int id;
  final String title;
  final String assetPath;
  final List<int> phraseMarkersMs; // 每一句佛號尾端的精準時間標記（毫秒遞增清單，經過標記點+1）
  final int? beatIntervalMs; // 非必要：單句平均唱誦週期（毫秒），未設定時自動由標記推算
  final String artist; // 參與演出者（優先讀取音檔 metadata，預設為「三寶弟子」）
  final String album; // 專輯（優先讀取音檔 metadata，預設為「念佛計數器」）
  final List<String> tags; // 佛曲分類標籤（支援多標籤篩選）

  const ChantSong({
    required this.id,
    required this.title,
    required this.assetPath,
    required this.phraseMarkersMs,
    this.beatIntervalMs,
    this.artist = defaultArtist,
    this.album = defaultAlbum,
    this.tags = const [],
  });

  /// 是否具備精確時間戳標記（若為 false 則回退採用 effectiveBeatIntervalMs 週期計算）
  bool get hasMarkers => phraseMarkersMs.isNotEmpty;

  /// 有效節拍週期（毫秒）：
  /// 若有指定 beatIntervalMs 則採用之；否則由 phraseMarkersMs 自動推算平均單句時長；皆無則回退預設值
  int get effectiveBeatIntervalMs {
    if (beatIntervalMs != null && beatIntervalMs! > 0) {
      return beatIntervalMs!;
    }
    if (phraseMarkersMs.isNotEmpty) {
      return (phraseMarkersMs.last / phraseMarkersMs.length)
          .round()
          .clamp(200, 60000);
    }
    return defaultBeatIntervalMs;
  }

  /// 優先套用音檔內嵌 Metadata 的 title、artist（參與演出者）、album（專輯）；
  /// 若音檔未記錄該標籤或為空字串，則回退至欄位值與預設值
  ChantSong withAudioMetadata(AudioMetadata? meta) {
    if (meta == null) return this;
    final resolvedTitle = (meta.title != null && meta.title!.trim().isNotEmpty)
        ? meta.title!.trim()
        : title;
    final resolvedArtist =
        (meta.artist != null && meta.artist!.trim().isNotEmpty)
            ? meta.artist!.trim()
            : (artist.trim().isNotEmpty ? artist : defaultArtist);
    final resolvedAlbum = (meta.album != null && meta.album!.trim().isNotEmpty)
        ? meta.album!.trim()
        : (album.trim().isNotEmpty ? album : defaultAlbum);

    return ChantSong(
      id: id,
      title: resolvedTitle,
      assetPath: assetPath,
      phraseMarkersMs: phraseMarkersMs,
      beatIntervalMs: beatIntervalMs,
      artist: resolvedArtist,
      album: resolvedAlbum,
      tags: tags,
    );
  }
}

class ChantConstants {
  /// 完整 31 首重新編排之佛曲預設清單（阿彌陀佛 → 南無阿彌陀佛 → 其他聖號與咒語）
  /// App 啟動時會呼叫 [loadMetadataFromAssets] 自動優先讀取各音檔內嵌之 title / artist / album
  static const List<ChantSong> defaultSongs = [
    // ==================== 一、四字「阿彌陀佛」開頭（01 ~ 11） ====================
    ChantSong(
      id: 0,
      title: '阿彌陀佛-四字四音-華藏淨宗-悟道法師',
      assetPath: 'audio/bb01-阿彌陀佛-四字四音-華藏淨宗-悟道法師.ogg',
      beatIntervalMs: 3846,
      tags: [
        ChantTags.fourCharAmitabha,
        ChantTags.briskMedium,
        ChantTags.masterChant,
      ],
      phraseMarkersMs: [
        3331,
        7360,
        11144,
        15099,
        19031,
        22882,
        26511,
        30169,
        34066,
        38096,
        42054,
        45782,
        49919,
        53438,
        57279,
        61539,
      ],
    ),
    ChantSong(
      id: 1,
      title: '阿彌陀佛-四字四音配樂-華藏淨宗',
      assetPath: 'audio/bb02-阿彌陀佛-四字四音配樂-華藏淨宗.ogg',
      beatIntervalMs: 3429,
      tags: [
        ChantTags.fourCharAmitabha,
        ChantTags.briskMedium,
      ],
      phraseMarkersMs: [
        2975,
        6372,
        9861,
        13357,
        16784,
        20253,
        23653,
        27081,
        30565,
        34076,
        37562,
        40994,
        44475,
        47772,
        51318,
        54665,
        58161,
        61598,
        65010,
        68587,
      ],
    ),
    ChantSong(
      id: 2,
      title: '阿彌陀佛-四字四音-引磬慢板',
      assetPath: 'audio/bb03-阿彌陀佛-四字四音-引磬慢板.ogg',
      beatIntervalMs: 5559,
      tags: [
        ChantTags.fourCharAmitabha,
        ChantTags.slowSolemn,
      ],
      phraseMarkersMs: [
        5098,
        10780,
        16386,
        21987,
        27311,
        32988,
        38367,
        44013,
        49264,
        55132,
        60742,
        66712,
      ],
    ),
    ChantSong(
      id: 3,
      title: '阿彌陀佛-四字四音-女眾慢版',
      assetPath: 'audio/bb04-阿彌陀佛-四字四音-女眾慢版.ogg',
      beatIntervalMs: 5400,
      tags: [
        ChantTags.fourCharAmitabha,
        ChantTags.slowSolemn,
      ],
      phraseMarkersMs: [
        4826,
        10746,
        15912,
        21311,
        26937,
        32362,
        37623,
        43269,
        48637,
        54076,
        59523,
        64796,
      ],
    ),
    ChantSong(
      id: 4,
      title: '阿彌陀佛-四字四音-女眾快版-靈巖山寺',
      assetPath: 'audio/bb05-阿彌陀佛-四字四音-女眾快版-靈巖山寺.ogg',
      beatIntervalMs: 1925,
      tags: [
        ChantTags.fourCharAmitabha,
        ChantTags.briskMedium,
        ChantTags.lingyan,
      ],
      phraseMarkersMs: [
        1933,
        3764,
        5593,
        7617,
        9608,
        11477,
        13447,
        15401,
      ],
    ),
    ChantSong(
      id: 5,
      title: '阿彌陀佛-四字中速-淨空法師',
      assetPath: 'audio/bb06-阿彌陀佛-四字中速-淨空法師.ogg',
      beatIntervalMs: 1348,
      tags: [
        ChantTags.fourCharAmitabha,
        ChantTags.briskMedium,
        ChantTags.masterChant,
      ],
      phraseMarkersMs: [
        1117,
        2548,
        3949,
        5342,
        6687,
        8064,
        9518,
        10905,
        12353,
        13479,
      ],
    ),
    ChantSong(
      id: 6,
      title: '阿彌陀佛-四字快速-淨空法師',
      assetPath: 'audio/bb07-阿彌陀佛-四字快速-淨空法師.ogg',
      beatIntervalMs: 747,
      tags: [
        ChantTags.fourCharAmitabha,
        ChantTags.briskMedium,
        ChantTags.masterChant,
      ],
      phraseMarkersMs: [
        680,
        1379,
        2117,
        2781,
        3526,
        4303,
        5050,
        5822,
        6600,
        7282,
        7914,
        8787,
        9644,
        10378,
        11123,
        11812,
        12668,
        13413,
        14069,
        14805,
        15622,
        16345,
        17158,
        17930,
        18596,
        19373,
        20131,
        20854,
        21622,
        22385,
        23115,
        23885,
        24592,
        25358,
        26110,
        26909,
        27647,
        28337,
        29096,
        29820,
        30633,
        31359,
        32125,
        32876,
        33643,
        34398,
        35159,
        35910,
        36699,
        37376,
        38124,
        38911,
        39630,
        40372,
        41103,
      ],
    ),
    ChantSong(
      id: 7,
      title: '阿彌陀佛-純人聲慢版-淨空法師',
      assetPath: 'audio/bb08-阿彌陀佛-純人聲慢版-淨空法師.ogg',
      beatIntervalMs: 5979,
      tags: [
        ChantTags.fourCharAmitabha,
        ChantTags.slowSolemn,
        ChantTags.masterChant,
      ],
      phraseMarkersMs: [
        5593,
        11558,
        17601,
        23700,
        29751,
        35784,
        41764,
        47855,
        53976,
        59790,
      ],
    ),
    ChantSong(
      id: 8,
      title: '阿彌陀佛-地鐘念佛慢版-悟行法師',
      assetPath: 'audio/bb09-阿彌陀佛-地鐘念佛慢版-悟行法師.ogg',
      beatIntervalMs: 3434,
      tags: [
        ChantTags.fourCharAmitabha,
        ChantTags.slowSolemn,
        ChantTags.masterChant,
      ],
      phraseMarkersMs: [
        2866,
        6461,
        9866,
        13575,
        16978,
        20554,
        24091,
        27530,
        31026,
        34640,
        37954,
        41528,
        44960,
        48476,
        51876,
        55341,
        58704,
        62069,
        65488,
        68670,
      ],
    ),
    ChantSong(
      id: 9,
      title: '阿彌陀佛-唱誦-佛光山',
      assetPath: 'audio/bb10-阿彌陀佛-唱誦-佛光山.ogg',
      beatIntervalMs: 2692,
      tags: [
        ChantTags.fourCharAmitabha,
        ChantTags.briskMedium,
      ],
      phraseMarkersMs: [
        2383,
        5079,
        7878,
        10574,
        13325,
        16031,
        18794,
        21534,
        24248,
        26853,
        29670,
        32307,
      ],
    ),
    ChantSong(
      id: 10,
      title: '阿彌陀佛-十念法',
      assetPath: 'audio/bb11-阿彌陀佛-十念法.ogg',
      beatIntervalMs: 5863,
      tags: [
        ChantTags.fourCharAmitabha,
        ChantTags.slowSolemn,
      ],
      phraseMarkersMs: [
        5272,
        11118,
        17248,
        23173,
        29279,
        35104,
        40907,
        47015,
        52763,
        58630,
      ],
    ),

    // ==================== 二、六字「南無阿彌陀佛」開頭（12 ~ 26） ====================
    ChantSong(
      id: 11,
      title: '南無阿彌陀佛-思鄉佛號-祥林精舍-開松法師',
      assetPath: 'audio/bb12-南無阿彌陀佛-思鄉佛號-祥林精舍-開松法師.ogg',
      beatIntervalMs: 7279,
      tags: [
        ChantTags.sixCharAmitabha,
        ChantTags.slowSolemn,
        ChantTags.masterChant,
      ],
      phraseMarkersMs: [
        6928,
        12947,
        22546,
        28444,
        34824,
        44690,
        51069,
        60849,
        66721,
        72788,
      ],
    ),
    ChantSong(
      id: 12,
      title: '南無阿彌陀佛-六字四音-歸鄉佛號',
      assetPath: 'audio/bb13-南無阿彌陀佛-六字四音-歸鄉佛號.ogg',
      beatIntervalMs: 9046,
      tags: [
        ChantTags.sixCharAmitabha,
        ChantTags.slowSolemn,
      ],
      phraseMarkersMs: [
        7952,
        14879,
        26959,
        34113,
        45884,
        53087,
        65059,
        72368,
      ],
    ),
    ChantSong(
      id: 13,
      title: '南無阿彌陀佛-六字四音-華樂版',
      assetPath: 'audio/bb14-南無阿彌陀佛-六字四音-華樂版.ogg',
      beatIntervalMs: 7874,
      tags: [
        ChantTags.sixCharAmitabha,
        ChantTags.slowSolemn,
      ],
      phraseMarkersMs: [
        7032,
        15165,
        22620,
        30824,
        39135,
        47211,
        55348,
        62992,
      ],
    ),
    ChantSong(
      id: 14,
      title: '南無阿彌陀佛-六字二音-慢速-靈巖山寺',
      assetPath: 'audio/bb15-南無阿彌陀佛-六字二音-慢速-靈巖山寺.ogg',
      beatIntervalMs: 8648,
      tags: [
        ChantTags.sixCharAmitabha,
        ChantTags.slowSolemn,
        ChantTags.lingyan,
      ],
      phraseMarkersMs: [
        8979,
        17351,
        26068,
        34591,
      ],
    ),
    ChantSong(
      id: 15,
      title: '南無阿彌陀佛-六字唱誦慢速-印光大師版',
      assetPath: 'audio/bb16-南無阿彌陀佛-六字唱誦慢速-印光大師版.ogg',
      beatIntervalMs: 6797,
      tags: [
        ChantTags.sixCharAmitabha,
        ChantTags.slowSolemn,
      ],
      phraseMarkersMs: [
        6001,
        13040,
        19747,
        26525,
        33644,
        40498,
        47503,
        54374,
      ],
    ),
    ChantSong(
      id: 16,
      title: '南無阿彌陀佛-六字唱誦中速-印光大師版',
      assetPath: 'audio/bb17-南無阿彌陀佛-六字唱誦中速-印光大師版.ogg',
      beatIntervalMs: 5338,
      tags: [
        ChantTags.sixCharAmitabha,
        ChantTags.briskMedium,
      ],
      phraseMarkersMs: [
        4701,
        10183,
        15800,
        21353,
      ],
    ),
    ChantSong(
      id: 17,
      title: '南無阿彌陀佛-唱誦-佛光山',
      assetPath: 'audio/bb18-南無阿彌陀佛-唱誦-佛光山.ogg',
      beatIntervalMs: 5365,
      tags: [
        ChantTags.sixCharAmitabha,
        ChantTags.slowSolemn,
      ],
      phraseMarkersMs: [
        4907,
        10156,
        15638,
        21089,
        26509,
        32028,
        37430,
        42920,
      ],
    ),
    ChantSong(
      id: 18,
      title: '南無阿彌陀佛-六字四字-男女對唱',
      assetPath: 'audio/bb19-南無阿彌陀佛-六字四字-男女對唱.ogg',
      beatIntervalMs: 4791,
      tags: [
        ChantTags.sixCharAmitabha,
        ChantTags.fourCharAmitabha,
      ],
      phraseMarkersMs: [
        4086,
        10423,
        14852,
        17856,
        22538,
        29066,
        35418,
        39891,
        43100,
        47911,
      ],
    ),
    ChantSong(
      id: 19,
      title: '南無阿彌陀佛-呼吸五段配樂',
      assetPath: 'audio/bb20-南無阿彌陀佛-呼吸五段配樂.ogg',
      beatIntervalMs: 4062,
      tags: [
        ChantTags.sixCharAmitabha,
        ChantTags.briskMedium,
      ],
      phraseMarkersMs: [
        3783,
        7979,
        11997,
        15974,
        20074,
        24284,
        28138,
        32328,
        36440,
        40516,
        44883,
        48751,
        52762,
        56994,
        61142,
        65326,
        69287,
        73333,
        77594,
        81243,
      ],
    ),
    ChantSong(
      id: 20,
      title: '南無阿彌陀佛-慢速念誦-淨宗法師',
      assetPath: 'audio/bb21-南無阿彌陀佛-慢速念誦-淨宗法師.ogg',
      beatIntervalMs: 3879,
      tags: [
        ChantTags.sixCharAmitabha,
        ChantTags.slowSolemn,
        ChantTags.masterChant,
      ],
      phraseMarkersMs: [
        3039,
        7000,
        10687,
        14935,
        18931,
        22958,
        26830,
        30872,
        34782,
        38621,
        42665,
        46762,
        50437,
        54481,
        58192,
      ],
    ),
    ChantSong(
      id: 21,
      title: '南無阿彌陀佛-台語慢速-沙鹿彌陀念佛堂-陳有宏居士',
      assetPath: 'audio/bb22-南無阿彌陀佛-台語慢速-沙鹿彌陀念佛堂-陳有宏居士.ogg',
      beatIntervalMs: 4684,
      tags: [
        ChantTags.sixCharAmitabha,
        ChantTags.slowSolemn,
        ChantTags.masterChant,
      ],
      phraseMarkersMs: [
        4007,
        8835,
        13729,
        18378,
        23103,
        27895,
        32775,
        37473,
        42256,
        46872,
        51554,
        56209,
      ],
    ),
    ChantSong(
      id: 22,
      title: '南無阿彌陀佛-夏蓮居老居士',
      assetPath: 'audio/bb23-南無阿彌陀佛-夏蓮居老居士.ogg',
      beatIntervalMs: 3332,
      tags: [
        ChantTags.sixCharAmitabha,
        ChantTags.briskMedium,
        ChantTags.masterChant,
      ],
      phraseMarkersMs: [
        2778,
        6074,
        9376,
        12741,
        16038,
        19414,
        22930,
        26258,
        29630,
        33059,
        36192,
        39537,
        42983,
        46264,
        49603,
        53305,
      ],
    ),
    ChantSong(
      id: 23,
      title: '南無阿彌陀佛-六度彌陀-靈巖梵唄-沙彌師父',
      assetPath: 'audio/bb24-南無阿彌陀佛-六度彌陀-靈巖梵唄-沙彌師父.ogg',
      beatIntervalMs: 12906,
      tags: [
        ChantTags.sixCharAmitabha,
        ChantTags.slowSolemn,
        ChantTags.lingyan,
      ],
      phraseMarkersMs: [
        13158,
        25955,
        38841,
        51106,
        64531,
      ],
    ),
    ChantSong(
      id: 24,
      title: '南無阿彌陀佛-懷念恩師-靈巖梵唄-沙彌師父',
      assetPath: 'audio/bb25-南無阿彌陀佛-懷念恩師-靈巖梵唄-沙彌師父.ogg',
      beatIntervalMs: 7608,
      tags: [
        ChantTags.sixCharAmitabha,
        ChantTags.slowSolemn,
        ChantTags.lingyan,
      ],
      phraseMarkersMs: [
        7135,
        14856,
        22388,
        29559,
        38041,
      ],
    ),
    ChantSong(
      id: 25,
      title: '南無阿彌陀佛-朝山聖號-靈巖梵唄-沙彌師父',
      assetPath: 'audio/bb26-南無阿彌陀佛-朝山聖號-靈巖梵唄-沙彌師父.ogg',
      beatIntervalMs: 9276,
      tags: [
        ChantTags.sixCharAmitabha,
        ChantTags.slowSolemn,
        ChantTags.lingyan,
        ChantTags.pilgrimage,
      ],
      phraseMarkersMs: [
        8619,
        17164,
        27095,
        36666,
        46375,
        55657,
      ],
    ),

    // ==================== 三、其他聖號與咒語（27 ~ 31） ====================
    ChantSong(
      id: 26,
      title: '南無釋迦牟尼佛-朝山聖號-靈巖梵唄-沙彌師父',
      assetPath: 'audio/bb27-南無釋迦牟尼佛-朝山聖號-靈巖梵唄-沙彌師父.ogg',
      beatIntervalMs: 8660,
      tags: [
        ChantTags.bodhisattvaMantra,
        ChantTags.slowSolemn,
        ChantTags.lingyan,
        ChantTags.pilgrimage,
      ],
      phraseMarkersMs: [
        7281,
        16153,
        25134,
        34504,
        43017,
        51960,
      ],
    ),
    ChantSong(
      id: 27,
      title: '南無地藏王菩薩-朝山聖號-靈巖梵唄-沙彌師父',
      assetPath: 'audio/bb28-南無地藏王菩薩-朝山聖號-靈巖梵唄-沙彌師父.ogg',
      beatIntervalMs: 7672,
      tags: [
        ChantTags.bodhisattvaMantra,
        ChantTags.slowSolemn,
        ChantTags.lingyan,
        ChantTags.pilgrimage,
      ],
      phraseMarkersMs: [
        6463,
        14208,
        21981,
        29894,
        37939,
        45785,
        53775,
        61376,
      ],
    ),
    ChantSong(
      id: 28,
      title: '南無觀世音菩薩-朝山聖號-靈巖梵唄-沙彌師父',
      assetPath: 'audio/bb29-南無觀世音菩薩-朝山聖號-靈巖梵唄-沙彌師父.ogg',
      beatIntervalMs: 9199,
      tags: [
        ChantTags.bodhisattvaMantra,
        ChantTags.slowSolemn,
        ChantTags.lingyan,
        ChantTags.pilgrimage,
      ],
      phraseMarkersMs: [
        7369,
        17023,
        26319,
        36128,
        45439,
        55193,
      ],
    ),
    ChantSong(
      id: 29,
      title: '南無觀世音菩薩-七字五音-莊嚴樂曲',
      assetPath: 'audio/bb30-南無觀世音菩薩-七字五音-莊嚴樂曲.ogg',
      beatIntervalMs: 6456,
      tags: [
        ChantTags.bodhisattvaMantra,
        ChantTags.slowSolemn,
      ],
      phraseMarkersMs: [
        6543,
        13031,
        19360,
        26052,
        32282,
        38902,
        45488,
        51929,
        58463,
        64562,
      ],
    ),
    ChantSong(
      id: 30,
      title: '六字大明咒-女聲唱誦',
      assetPath: 'audio/bb31-六字大明咒-女聲唱誦.ogg',
      beatIntervalMs: 3653,
      tags: [
        ChantTags.bodhisattvaMantra,
        ChantTags.briskMedium,
      ],
      phraseMarkersMs: [
        3183,
        6807,
        10527,
        14288,
        17962,
        21583,
        25276,
        28808,
        32527,
        36358,
        40071,
        43429,
        47407,
        51063,
        54886,
        58453,
      ],
    ),
  ];

  static List<ChantSong> _resolvedSongs =
      List<ChantSong>.unmodifiable(defaultSongs);

  static bool _metadataLoaded = false;
  static bool get isMetadataLoaded => _metadataLoaded;

  /// 取得目前所有佛曲清單（若已執行 [loadMetadataFromAssets]，將包含音檔內嵌之最新 Metadata）
  static List<ChantSong> get allSongs => _resolvedSongs;

  static List<ChantSong> getAllSongs() => _resolvedSongs;

  static ChantSong getSongById(int id) {
    if (id >= 0 && id < _resolvedSongs.length) {
      return _resolvedSongs[id];
    }
    return _resolvedSongs[0];
  }

  /// 取得目前所有可用分類標籤（依推薦順序排列，並自動納入曲庫內新增的自訂標籤）
  static List<String> get availableTags {
    final present = <String>{};
    for (final s in _resolvedSongs) {
      present.addAll(s.tags);
    }
    final ordered = <String>[
      for (final t in ChantTags.defaultOrder)
        if (present.contains(t)) t,
    ];
    for (final t in present) {
      if (!ordered.contains(t)) {
        ordered.add(t);
      }
    }
    return ordered;
  }

  /// 計算指定標籤下的佛曲數量
  static int countSongsByTag(String tag) {
    return _resolvedSongs.where((s) => s.tags.contains(tag)).length;
  }

  /// 從 `assets/audio/` 各音檔檔頭並行讀取內嵌 Metadata（title / artist / album），
  /// 優先採用音檔標籤，缺少處自動回退至 [ChantSong.defaultArtist] 與 [ChantSong.defaultAlbum]
  static Future<void> loadMetadataFromAssets({AssetBundle? bundle}) async {
    final enriched = await Future.wait(
      defaultSongs.map((song) async {
        final meta = await AudioMetadataReader.readFromAsset(
          song.assetPath,
          bundle: bundle,
        );
        return song.withAudioMetadata(meta);
      }),
    );
    _resolvedSongs = List<ChantSong>.unmodifiable(enriched);
    _metadataLoaded = true;
  }

  // 迴向文清單（支援左右滑動切換）
  static const String huiXiangTitle = '大回向西方文';
  static const List<String> huiXiangVerses = [
    '願我臨終無障礙 阿彌陀佛遠相迎',
    '觀音甘露灑吾頭 勢至金臺安我足',
    '一剎那中離五濁 屈伸臂頃到蓮池',
    '蓮花開後見慈尊 親聽法音可了了',
    '聞已即悟無生忍 不違安養入娑婆',
    '善知方便度眾生 巧把塵勞為佛事',
  ];
  static const String huiXiangTitle2 = '回向偈';
  static const List<String> huiXiangVerses2 = [
    '願生西方淨土中 九品蓮花為父母',
    '花開見佛悟無生 不退菩薩為伴侶',
  ];

  static const List<HuiXiangItem> huiXiangItems = [
    HuiXiangItem(
      title: huiXiangTitle,
      verses: huiXiangVerses,
    ),
    HuiXiangItem(
      title: huiXiangTitle2,
      verses: huiXiangVerses2,
    ),
  ];
}

class HuiXiangItem {
  final String title;
  final List<String> verses;

  const HuiXiangItem({
    required this.title,
    required this.verses,
  });
}
