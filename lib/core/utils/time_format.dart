/// 秒數 → `HH:MM:SS` (碼表、自動計數計時)
String formatHms(int totalSeconds) {
  String two(int n) => n.toString().padLeft(2, '0');
  return '${two(totalSeconds ~/ 3600)}:'
      '${two(totalSeconds % 3600 ~/ 60)}:'
      '${two(totalSeconds % 60)}';
}

/// 播放位置 → `MM:SS` (播放器進度條)
String formatMinSec(Duration d) {
  String two(int n) => n.toString().padLeft(2, '0');
  return '${two(d.inMinutes.remainder(60))}:${two(d.inSeconds.remainder(60))}';
}
