import 'package:search_engine_for_utaite_src/module_1_script.dart';
// import 'package:search_engine_for_utaite_src/module_2_script.dart';
import 'dart:io';

import 'package:search_engine_for_utaite_src/module_2_script.dart';

List<String> testCases = [
  "저 진짜 열심히 살았는데 왜😭😭 : AJR - Karma [가사/해석/lyrics]",
  'Thutmose - " Memories " (Spider-Man into the Spider-Verse)',

  "[한글자막] 장송의 프리렌 op Full - 용사 / YOASOBI",
  "비비디바 / 호시마치 스이세이 (공식)",
  "NEXT COLOR PLANET / 星街すいせい(official)",
  "YOASOBI「ラブレター」Official Music Video",
  "ソワレ / 星街すいせい(official)",
  "전방향 미소녀 (全方向美少女 ; noa) ／다즈비 COVER",
  "Aijanai",
  "Guitar, Loneliness and Blue Planet",
  "그래서 나는 음악을 그만두었다 (요루시카) ／다즈비 COVER 13",
  "DAZBEE (ダズビー) | ‘野兎と海亀 (Parallel World)’ M/V",
  "재 즈 소 비| 요아소비 재즈 편곡 플리 III (2025) [playlist]",
];

// List<String> test_cases = [];

String elementsToString(List<String> elements) {
  String result = "";
  for (String element in elements) {
    result = '$result"$element",';
  }
  return result;
}

void main() async {
  File logfile = File(
    'search_engine_for_utaite_src/lib/test_cases_source.dart',
  );
  await logfile.writeAsString(
    'List<Map<String, dynamic>> searchCases = [',
    mode: FileMode.write,
  );
  for (int i = 0; i < testCases.length; i++) {
    String testCase = testCases[i];
    List<String> keywords = module1(testCase, "dzb");
    print(keywords);
    List<List<String>> keyword3form = await module2(keywords);
    await logfile.writeAsString(
      '{"number" : $i, "title" : "$testCase", "search_tag" : [[${elementsToString(keyword3form[0])}],[${elementsToString(keyword3form[1])}],[${elementsToString(keyword3form[2])}]], "keywords" : [${elementsToString(keywords)}]},',
      mode: FileMode.append,
    );
    // for (String element in keywords) {
    //   await logfile.writeAsString('', mode: FileMode.append);
    // }

    // await logfile.writeAsString(
    //   '$testCase \n ${keywords.toString()} \n ${keyword3form.toString()} \n \n \n',
    //   mode: FileMode.append,
    // );
  }
  await logfile.writeAsString('];', mode: FileMode.append);
}
