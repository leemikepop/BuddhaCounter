import 'dart:ui';

import 'package:flutter/services.dart';
import '../content/chant_content.dart';
import '../content/embedded_song_artists.dart';
import '../utils/audio_metadata_reader.dart';

export '../content/chant_content.dart' show HuiXiangItem;

/// 佛曲分類標籤 (穩定識別碼；顯示文字見 lib/l10n/chant_tag_labels.dart)
/// 宣告順序即為篩選列的預設排序
enum ChantTag {
  fourCharAmitabha,
  sixCharAmitabha,
  bodhisattvaMantra,
  pilgrimage,
  lingyan,
  masterChant,
  briskMedium,
  slowSolemn,
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
  final List<ChantTag> tags; // 佛曲分類標籤（支援多標籤篩選）

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

  /// 節拍秒數 (顯示用，小數兩位)，例如 `3.85`
  String get beatSeconds => (effectiveBeatIntervalMs / 1000).toStringAsFixed(2);

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

  ChantSong copyWith({String? title, String? artist, String? album}) {
    return ChantSong(
      id: id,
      title: title ?? this.title,
      assetPath: assetPath,
      phraseMarkersMs: phraseMarkersMs,
      beatIntervalMs: beatIntervalMs,
      artist: artist ?? this.artist,
      album: album ?? this.album,
      tags: tags,
    );
  }
}

class ChantConstants {
  /// 完整佛曲預設清單，依 App 內顯示順序排列（阿彌陀佛 → 南無阿彌陀佛 → 其他聖號與咒語）。
  /// 清單順序可以調整、可以在中間插入新曲；但每首的 [ChantSong.id] 一經發佈就不能改。
  /// App 啟動時會呼叫 [loadMetadataFromAssets] 自動優先讀取各音檔內嵌之 title / artist / album
  static const List<ChantSong> defaultSongs = [
    // ==================== 一、四字「阿彌陀佛」開頭（01 ~ 11） ====================
    ChantSong(
      id: 0,
      title: '阿彌陀佛-四字四音-華藏淨宗-悟道法師',
      assetPath: 'audio/阿彌陀佛-四字四音-華藏淨宗-悟道法師.ogg',
      beatIntervalMs: 3846,
      tags: [
        ChantTag.fourCharAmitabha,
        ChantTag.briskMedium,
        ChantTag.masterChant,
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
      assetPath: 'audio/阿彌陀佛-四字四音配樂-華藏淨宗.ogg',
      beatIntervalMs: 3429,
      tags: [
        ChantTag.fourCharAmitabha,
        ChantTag.briskMedium,
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
      assetPath: 'audio/阿彌陀佛-四字四音-引磬慢板.ogg',
      beatIntervalMs: 5559,
      tags: [
        ChantTag.fourCharAmitabha,
        ChantTag.slowSolemn,
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
      assetPath: 'audio/阿彌陀佛-四字四音-女眾慢版.ogg',
      beatIntervalMs: 5400,
      tags: [
        ChantTag.fourCharAmitabha,
        ChantTag.slowSolemn,
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
      assetPath: 'audio/阿彌陀佛-四字四音-女眾快版-靈巖山寺.ogg',
      beatIntervalMs: 1925,
      tags: [
        ChantTag.fourCharAmitabha,
        ChantTag.briskMedium,
        ChantTag.lingyan,
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
      assetPath: 'audio/阿彌陀佛-四字中速-淨空法師.ogg',
      beatIntervalMs: 1348,
      tags: [
        ChantTag.fourCharAmitabha,
        ChantTag.briskMedium,
        ChantTag.masterChant,
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
      assetPath: 'audio/阿彌陀佛-四字快速-淨空法師.ogg',
      beatIntervalMs: 747,
      tags: [
        ChantTag.fourCharAmitabha,
        ChantTag.briskMedium,
        ChantTag.masterChant,
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
      assetPath: 'audio/阿彌陀佛-純人聲慢版-淨空法師.ogg',
      beatIntervalMs: 5979,
      tags: [
        ChantTag.fourCharAmitabha,
        ChantTag.slowSolemn,
        ChantTag.masterChant,
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
      assetPath: 'audio/阿彌陀佛-地鐘念佛慢版-悟行法師.ogg',
      beatIntervalMs: 3434,
      tags: [
        ChantTag.fourCharAmitabha,
        ChantTag.slowSolemn,
        ChantTag.masterChant,
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
      id: 31,
      title: '阿彌陀佛-地鐘念佛快版-悟行法師',
      assetPath: 'audio/阿彌陀佛-地鐘念佛快版-悟行法師.ogg',
      beatIntervalMs: 1113,
      tags: [
        ChantTag.fourCharAmitabha,
        ChantTag.briskMedium,
      ],
      phraseMarkersMs: [
        1142,
        2185,
        3320,
        4544,
        5732,
        6741,
        7865,
        9023,
        10183,
        11344,
        12446,
        13517,
        14676,
        15802,
        16942,
        18096,
        19164,
        20278,
        21465,
        22575,
        23721,
        24782,
        25884,
        27029,
        28183,
        29282,
        30331,
        31427,
        32503,
        33745,
        34760,
        35744,
        36848,
        37923,
        39014,
        40142,
        41185,
        42295,
        43206,
        44516,
      ],
    ),
    ChantSong(
      id: 32,
      title: '阿彌陀佛-地鐘念佛急速-悟行法師',
      assetPath: 'audio/阿彌陀佛-地鐘念佛急速-悟行法師.ogg',
      beatIntervalMs: 887,
      tags: [
        ChantTag.fourCharAmitabha,
        ChantTag.briskMedium,
      ],
      phraseMarkersMs: [
        799,
        1553,
        2445,
        3259,
        4270,
        5090,
        6015,
        6905,
        7845,
        8735,
        9631,
        10540,
        11412,
        12360,
        13217,
        14012,
        14821,
        15699,
        16852,
        17799,
        18635,
        19548,
        20338,
        21302,
        22229,
        23108,
        23973,
        24820,
        25793,
        26669,
        27517,
        28308,
        29312,
        30189,
        31086,
        31941,
        32931,
        33762,
        34726,
        35571,
        36454,
        37330,
        38208,
        39163,
        40260,
        40973,
        41730,
        42473,
        43450,
        44391,
        45281,
        46103,
        47010,
        48001,
        48830,
        49655,
        50567,
        51472,
        52347,
        53229,
        54169,
        54968,
        55932,
        56788,
        57708,
        58446,
        59359,
        60273,
        61191,
        62194,
        62957,
        63737,
        64839,
        65690,
        66512,
        67496,
        68309,
        69220,
        70107,
        71033,
        71919,
        72753,
        73662,
        74523,
        75402,
        76318,
        77207,
        78000,
        78910,
        79838,
      ],
    ),
    ChantSong(
      id: 9,
      title: '阿彌陀佛-唱誦-佛光山',
      assetPath: 'audio/阿彌陀佛-唱誦-佛光山.ogg',
      beatIntervalMs: 2692,
      tags: [
        ChantTag.fourCharAmitabha,
        ChantTag.briskMedium,
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
      assetPath: 'audio/阿彌陀佛-十念法.ogg',
      beatIntervalMs: 5863,
      tags: [
        ChantTag.fourCharAmitabha,
        ChantTag.slowSolemn,
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
      assetPath: 'audio/南無阿彌陀佛-思鄉佛號-祥林精舍-開松法師.ogg',
      beatIntervalMs: 7279,
      tags: [
        ChantTag.sixCharAmitabha,
        ChantTag.slowSolemn,
        ChantTag.masterChant,
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
      assetPath: 'audio/南無阿彌陀佛-六字四音-歸鄉佛號.ogg',
      beatIntervalMs: 9046,
      tags: [
        ChantTag.sixCharAmitabha,
        ChantTag.slowSolemn,
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
      assetPath: 'audio/南無阿彌陀佛-六字四音-華樂版.ogg',
      beatIntervalMs: 7874,
      tags: [
        ChantTag.sixCharAmitabha,
        ChantTag.slowSolemn,
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
      assetPath: 'audio/南無阿彌陀佛-六字二音-慢速-靈巖山寺.ogg',
      beatIntervalMs: 8648,
      tags: [
        ChantTag.sixCharAmitabha,
        ChantTag.slowSolemn,
        ChantTag.lingyan,
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
      assetPath: 'audio/南無阿彌陀佛-六字唱誦慢速-印光大師版.ogg',
      beatIntervalMs: 6797,
      tags: [
        ChantTag.sixCharAmitabha,
        ChantTag.slowSolemn,
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
      assetPath: 'audio/南無阿彌陀佛-六字唱誦中速-印光大師版.ogg',
      beatIntervalMs: 5338,
      tags: [
        ChantTag.sixCharAmitabha,
        ChantTag.briskMedium,
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
      assetPath: 'audio/南無阿彌陀佛-唱誦-佛光山.ogg',
      beatIntervalMs: 5365,
      tags: [
        ChantTag.sixCharAmitabha,
        ChantTag.slowSolemn,
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
      assetPath: 'audio/南無阿彌陀佛-六字四字-男女對唱.ogg',
      beatIntervalMs: 4791,
      tags: [
        ChantTag.sixCharAmitabha,
        ChantTag.fourCharAmitabha,
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
      assetPath: 'audio/南無阿彌陀佛-呼吸五段配樂.ogg',
      beatIntervalMs: 4062,
      tags: [
        ChantTag.sixCharAmitabha,
        ChantTag.briskMedium,
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
      id: 33,
      title: '南無阿彌陀佛-佛光常照-念佛回家',
      assetPath: 'audio/南無阿彌陀佛-佛光常照-念佛回家.ogg',
      beatIntervalMs: 7232,
      tags: [
        ChantTag.sixCharAmitabha,
        ChantTag.slowSolemn,
      ],
      phraseMarkersMs: [
        5349,
        12466,
        20208,
        27384,
        35165,
        42287,
        49818,
        56868,
        64432,
        71791,
        79246,
        86778,
      ],
    ),
    ChantSong(
      id: 20,
      title: '南無阿彌陀佛-慢速念誦-淨宗法師',
      assetPath: 'audio/南無阿彌陀佛-慢速念誦-淨宗法師.ogg',
      beatIntervalMs: 3879,
      tags: [
        ChantTag.sixCharAmitabha,
        ChantTag.slowSolemn,
        ChantTag.masterChant,
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
      assetPath: 'audio/南無阿彌陀佛-台語慢速-沙鹿彌陀念佛堂-陳有宏居士.ogg',
      beatIntervalMs: 4684,
      tags: [
        ChantTag.sixCharAmitabha,
        ChantTag.slowSolemn,
        ChantTag.masterChant,
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
      assetPath: 'audio/南無阿彌陀佛-夏蓮居老居士.ogg',
      beatIntervalMs: 3332,
      tags: [
        ChantTag.sixCharAmitabha,
        ChantTag.briskMedium,
        ChantTag.masterChant,
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
      assetPath: 'audio/南無阿彌陀佛-六度彌陀-靈巖梵唄-沙彌師父.ogg',
      beatIntervalMs: 12906,
      tags: [
        ChantTag.sixCharAmitabha,
        ChantTag.slowSolemn,
        ChantTag.lingyan,
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
      assetPath: 'audio/南無阿彌陀佛-懷念恩師-靈巖梵唄-沙彌師父.ogg',
      beatIntervalMs: 7608,
      tags: [
        ChantTag.sixCharAmitabha,
        ChantTag.slowSolemn,
        ChantTag.lingyan,
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
      assetPath: 'audio/南無阿彌陀佛-朝山聖號-靈巖梵唄-沙彌師父.ogg',
      beatIntervalMs: 9276,
      tags: [
        ChantTag.sixCharAmitabha,
        ChantTag.slowSolemn,
        ChantTag.lingyan,
        ChantTag.pilgrimage,
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
      assetPath: 'audio/南無釋迦牟尼佛-朝山聖號-靈巖梵唄-沙彌師父.ogg',
      beatIntervalMs: 8660,
      tags: [
        ChantTag.bodhisattvaMantra,
        ChantTag.slowSolemn,
        ChantTag.lingyan,
        ChantTag.pilgrimage,
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
      assetPath: 'audio/南無地藏王菩薩-朝山聖號-靈巖梵唄-沙彌師父.ogg',
      beatIntervalMs: 7672,
      tags: [
        ChantTag.bodhisattvaMantra,
        ChantTag.slowSolemn,
        ChantTag.lingyan,
        ChantTag.pilgrimage,
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
      assetPath: 'audio/南無觀世音菩薩-朝山聖號-靈巖梵唄-沙彌師父.ogg',
      beatIntervalMs: 9199,
      tags: [
        ChantTag.bodhisattvaMantra,
        ChantTag.slowSolemn,
        ChantTag.lingyan,
        ChantTag.pilgrimage,
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
      assetPath: 'audio/南無觀世音菩薩-七字五音-莊嚴樂曲.ogg',
      beatIntervalMs: 6456,
      tags: [
        ChantTag.bodhisattvaMantra,
        ChantTag.slowSolemn,
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
      assetPath: 'audio/六字大明咒-女聲唱誦.ogg',
      beatIntervalMs: 3653,
      tags: [
        ChantTag.bodhisattvaMantra,
        ChantTag.briskMedium,
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

  /// 繁中基底清單 (已套用音檔 metadata)；各語言版本由此衍生
  static List<ChantSong> _metadataSongs =
      List<ChantSong>.unmodifiable(defaultSongs);

  /// 目前語言的曲目清單
  static List<ChantSong> _resolvedSongs = _metadataSongs;

  static ChantContent _content = chantContentFor(
      const Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hant'));

  /// 依語言重建曲目清單與迴向文：
  /// - 繁中：沿用 metadata 解析結果 (音檔 metadata → 程式碼常數)
  /// - 其他：該語言目錄 → metadata → 繁中
  static void applyLocale(Locale locale) {
    _content = chantContentFor(locale);
    _rebuildLocalizedSongs();
  }

  static void _rebuildLocalizedSongs() {
    final c = _content;
    if (c.songTitles.isEmpty && c.artistNames.isEmpty) {
      _resolvedSongs = _metadataSongs;
      return;
    }
    _resolvedSongs = List<ChantSong>.unmodifiable(_metadataSongs.map((s) {
      return s.copyWith(
        title: c.songTitles[s.id],
        artist: c.artistNames[s.artist] ??
            (s.artist == ChantSong.defaultArtist ? c.defaultArtist : null),
        album: s.album == ChantSong.defaultAlbum ? c.defaultAlbum : null,
      );
    }));
  }

  /// 迴向文數量 (各語言一致)
  static const int huiXiangCount = 2;

  /// 目前語言的迴向文
  static List<HuiXiangItem> get huiXiangItems => _content.huiXiangItems;

  static bool _metadataLoaded = false;
  static bool get isMetadataLoaded => _metadataLoaded;

  /// 取得目前所有佛曲清單（若已執行 [loadMetadataFromAssets]，將包含音檔內嵌之最新 Metadata）
  static List<ChantSong> get allSongs => _resolvedSongs;

  static List<ChantSong> getAllSongs() => _resolvedSongs;

  /// 以 [ChantSong.id] 取曲目；找不到時回傳清單第一首。
  /// id 是永久識別碼 (使用者存下的「上次播放曲目」靠它)，**不等於**清單位置：
  /// 新曲目可以插在清單任何位置，id 接續最大值。
  static ChantSong getSongById(int id) {
    final i = indexOfId(id);
    return _resolvedSongs[i < 0 ? 0 : i];
  }

  /// [id] 在清單中的位置 (0 起算)；找不到回傳 -1
  static int indexOfId(int id) => _resolvedSongs.indexWhere((s) => s.id == id);

  /// 顯示用的曲目編號 (1 起算，依清單順序；找不到回傳 1)
  static int numberOfId(int id) {
    final i = indexOfId(id);
    return i < 0 ? 1 : i + 1;
  }

  /// 清單中 [id] 往後 ([delta] > 0) 或往前 ([delta] < 0) 第 |delta| 首的 id，頭尾相接
  static int neighborId(int id, int delta) {
    final n = _resolvedSongs.length;
    final i = indexOfId(id);
    final from = i < 0 ? 0 : i;
    return _resolvedSongs[((from + delta) % n + n) % n].id;
  }

  /// 取得目前所有可用分類標籤（依推薦順序排列，並自動納入曲庫內新增的自訂標籤）
  static List<ChantTag> get availableTags {
    final present = <ChantTag>{};
    for (final s in _resolvedSongs) {
      present.addAll(s.tags);
    }
    return [
      for (final t in ChantTag.values)
        if (present.contains(t)) t,
    ];
  }

  /// 計算指定標籤下的佛曲數量
  static int countSongsByTag(ChantTag tag) {
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
    _metadataSongs = List<ChantSong>.unmodifiable(enriched);
    _rebuildLocalizedSongs();
    _metadataLoaded = true;
  }

  /// Web 版用：不讀音檔 (避免開網頁就下載全部佛曲)，改用 [kEmbeddedSongArtists]。
  /// 曲名與專輯在程式碼常數裡已經和音檔標籤一致，只有演唱者需要補上。
  static void applyEmbeddedMetadata() {
    _metadataSongs = List<ChantSong>.unmodifiable(defaultSongs.map((song) =>
        song.withAudioMetadata(
            AudioMetadata(artist: kEmbeddedSongArtists[song.id]))));
    _rebuildLocalizedSongs();
    _metadataLoaded = true;
  }
}
