import 'package:search_engine_for_utaite_src/module_1_script.dart';
import 'package:dotenv/dotenv.dart' as dotenv;
// import 'package:search_engine_for_utaite_src/module_2_script.dart';
import 'dart:io';

List<String> testCases = [
  "[한글자막] 장송의 프리렌 op Full - 용사 / YOASOBI",
  "비비디바 / 호시마치 스이세이 (공식)",
  "NEXT COLOR PLANET / 星街すいせい(official)",
  "YOASOBI「ラブレター」Official Music Video",
  "ソワレ / 星街すいせい(official)",
  "전방향 미소녀 (全方向美少女 ; noa) ／다즈비 COVER",
  "Aijanai",
  "Guitar, Loneliness and Blue Planet",
  "그래서 나는 음악을 그만두었다 (요루시카) ／다즈비 COVER",
];

void main() async {
  File logfile = File('search_engine_for_utaite_src/lib/test_cases.txt');
  await logfile.writeAsString('hello', mode: FileMode.append);
  // for (String testCase in testCases) {
  //   List<String> keywords = module1(testCase, "dzb");
  //   List<List<String>> keyword3form = await module2(keywords);
  //   await logfile.writeAsString(
  //     '$testCase \n ${keywords.toString()} \n ${keyword3form.toString()} \n \n \n',
  //     mode: FileMode.append,
  //   );
  // }
}
