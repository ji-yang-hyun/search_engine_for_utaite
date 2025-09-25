import 'package:korean_romanization_converter/korean_romanization_converter.dart';
import 'package:dart_phonetics/dart_phonetics.dart';
import 'package:plagiarism_checker_plus/plagiarism_checker_plus.dart';
import 'package:search_engine_for_utaite_src/module_1_script.dart';
import 'package:search_engine_for_utaite_src/test_cases_source.dart';
import 'package:translator/translator.dart';

double Max(double a, double b) {
  if (a > b)
    return a;
  else
    return b;
}

List<String> inputToDoubleMetaPhone(String inputText) {
  final converter = KoreanRomanizationConverter();
  var romanizedInputText = converter.romanize(inputText);
  // print(romanizedInputText);
  final doubleMetaphone = DoubleMetaphone.withMaxLength(100);
  final encoding = doubleMetaphone.encode(romanizedInputText);
  List<String> doubleMetaphoneInputText = [encoding?.primary ?? ""];
  doubleMetaphoneInputText += encoding!.alternates!.toList();

  return doubleMetaphoneInputText;
}

Future<String> inputToTrans(String inputText) async {
  final translator = GoogleTranslator();

  var translation = await translator.translate(inputText, to: 'en');
  // print(translation);

  return translation.text;
}

double comparisonString(String input, String target) {
  //두 DMP를 비교하기 위한 함수
  //순서가 중요하다.
  // 앞쪽부터 쭉 따라가면서 순서에 맞는 알파벳이 순서에 있는게 몇 개가 있는지 체크하자.

  List<String> inputCList = input.split("");
  List<String> targetCList = target.split("");

  int s = 0;
  int cnt = 0;
  for (int i = 0; i < inputCList.length; i++) {
    for (int j = s; j < targetCList.length; j++) {
      if (inputCList[i] == targetCList[j]) {
        s = j + 1;
        cnt += 1;
        break;
      }
    }
  }

  //더블 메타폰 형태의 유사도 점수.
  double point = cnt / Max(inputCList.length + 0.0, targetCList.length + 0.0);

  return point;
}

double comparisonDMP(List<String> inputDMPList, List<String> targetDMPList) {
  double max = 0;
  double point;
  String match = "";
  for (String inputDMP in inputDMPList) {
    for (String targetDMP in targetDMPList) {
      point = comparisonString(inputDMP, targetDMP);
      if (point > max) {
        max = point;
        match = targetDMP;
      }
    }
  }

  print(match);

  return max;
}

double comparisonTrans(List<String> inputList, List<String> targetList) {
  var checker = PlagiarismCheckerPlus();
  double max = 0;
  String match = "";
  for (String input in inputList) {
    for (String target in targetList) {
      var result = checker.check(input, target);
      print(result.similarityScore);
      if (max < result.similarityScore) {
        max = result.similarityScore;
        match = target;
      }
    }
  }

  print(match);

  return max;
}

Future<List<Map<String, dynamic>>> searchModule(String input) async {
  if (input.isEmpty) {
    return [];
  }
  List<String> inputDMPList = [];
  List<String> inputTransList = [];
  List<String> inputKeywordList = module1(input, "");
  for (String keyword in inputKeywordList) {
    inputDMPList += inputToDoubleMetaPhone(keyword);
    inputTransList.add(await inputToTrans(input));
  }

  List<Map<String, dynamic>> songs = searchCases;
  List<double> songsPoints = [];
  List<dynamic> songsLog = [];

  for (Map<String, dynamic> song in songs) {
    List<String> keyword = [];
    List<String> romanized = [];
    List<String> translated = [];
    List<String> doubleMetaphone = [];
    romanized = song["search_tag"][0];
    translated = song["search_tag"][1];
    doubleMetaphone = song["search_tag"][2];

    print(song["title"]);
    double transPoint = comparisonTrans(inputTransList, translated);
    double doubleMetaPhonePoint = comparisonDMP(inputDMPList, doubleMetaphone);
    double point = Max(transPoint, doubleMetaPhonePoint);
    print(point);
    print("\n\n");
    songsPoints.add(point);
  }

  List<Map<String, dynamic>> songsSorted = songs.toList();
  songsSorted.sort(
    (a, b) => songsPoints[a["number"]].compareTo(songsPoints[b["number"]]),
  );

  return songsSorted;
}

void main() async {
  String input = "dazbee";
  List<Map<String, dynamic>> result = await searchModule(input);
  for (Map<String, dynamic> song in result) {
    print(song["title"]);
  }
}
