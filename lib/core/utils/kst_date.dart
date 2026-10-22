// 서버가 운동 기록 날짜(record_date)를 KST 기준으로 저장하므로, 앱에서 "오늘"을
// 따질 때도 기기 시간대가 아니라 KST로 맞춰야 날짜가 어긋나지 않는다.
DateTime kstToday() {
  final kstNow = DateTime.now().toUtc().add(const Duration(hours: 9));
  return DateTime(kstNow.year, kstNow.month, kstNow.day);
}
