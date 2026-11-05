/// 各音檔內嵌的演唱者 (artist 標籤)，key 是 ChantSong.id；沒有內嵌 artist 的曲目不列 (使用預設演出者)。
///
/// 原生 App 啟動時直接讀音檔檔頭取得這些資訊；Web 版為了不在開啟網頁時下載全部音檔，
/// 改用這份清單 (見 ChantConstants.applyEmbeddedMetadata)。
/// 換音檔或改了音檔的 artist 標籤後要更新這裡，test/embedded_song_artists_test.dart 會檢查兩者一致。
const Map<int, String> kEmbeddedSongArtists = {
  0: '悟道法師',
  5: '淨空法師',
  6: '淨空法師',
  7: '淨空法師',
  8: '悟行法師',
  9: '佛光山',
  11: '開松法師',
  14: '靈巖山寺',
  17: '佛光山',
  20: '淨宗法師',
  21: '陳有宏居士',
  22: '夏蓮居老居士',
  23: '沙彌師父',
  24: '沙彌師父',
  25: '沙彌師父',
  26: '沙彌師父',
  27: '靈巖梵唄',
  28: '靈巖梵唄',
};
