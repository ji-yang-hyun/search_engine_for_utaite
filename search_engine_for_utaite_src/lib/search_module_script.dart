import 'dart:ffi';
import 'dart:math';

import 'package:korean_romanization_converter/korean_romanization_converter.dart';
import 'package:dart_phonetics/dart_phonetics.dart';
import 'package:plagiarism_checker_plus/plagiarism_checker_plus.dart';
import 'package:search_engine_for_utaite_src/module_1_script.dart';
import 'package:search_engine_for_utaite_src/test_cases.dart';
import 'package:search_engine_for_utaite_src/test_cases_source.dart';
import 'package:translator/translator.dart';

double Max(double a, double b) {
  if (a > b)
    return a;
  else
    return b;
}

List<String> inputToDoubleMetaPhone(String romanizedInputText) {
  // print(romanizedInputText);
  final doubleMetaphone = DoubleMetaphone.withMaxLength(100);
  final encoding = doubleMetaphone.encode(romanizedInputText);
  List<String> doubleMetaphoneInputText = [encoding?.primary ?? ""];
  doubleMetaphoneInputText += encoding!.alternates!.toList();

  if (doubleMetaphoneInputText.length != 2) {
    print("wrong");
    doubleMetaphoneInputText += doubleMetaphoneInputText;
  }

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

  int cnt = levenshteinDistance(target, input);

  //더블 메타폰 형태의 유사도 점수.
  double point = cnt / input.length;

  return point;
}

int levenshteinDistance(String a, String b) {
  /*
  a 가 목표 문자열
  b 가 원래 문자열
  */
  int result = 0;
  int an = a.length;
  int bn = b.length;
  List<String> al = [" "] + a.split('');
  List<String> bl = [" "] + b.split('');

  List<List<int>> matrix = [];
  for (int i = 0; i <= bn; i++) {
    List<int> l = [i];
    for (int j = 1; j <= an; j++) {
      l.add(j);
    }
    matrix.add(l);
  }

  for (int i = 0; i < bl.length; i++) {
    for (int j = 0; j < al.length; j++) {
      if (i * j == 0) {
        continue;
      }
      int insertions = matrix[i][j - 1] + 1;
      int deletions = matrix[i - 1][j] + 1;
      int substitutions = matrix[i - 1][j - 1] + 1;
      matrix[i][j] = min(insertions, min(deletions, substitutions));
      if (al[j] == bl[i]) {
        matrix[i][j] = matrix[i - 1][j - 1];
      }
    }
  }

  result = matrix[bl.length - 1][al.length - 1];
  return result;
}

List<double> comparisonDMP(
  List<String> inputDMPList,
  List<dynamic> targetDMPList,
  List<String> inputRomanized,
  List<dynamic> targetRomanized,
) {
  double min = -1;
  double point;
  String matchT = "";
  String matchI = "";
  for (String inputDMP in inputDMPList) {
    for (String targetDMP in targetDMPList) {
      point = comparisonString(inputDMP, targetDMP);
      if (point < min || min < 0) {
        min = point;
        matchT = targetDMP;
        matchI = inputDMP;
      }
    }
  }
  double indexOfTd = targetDMPList.indexOf(matchT) / 2;
  int indexOfT = indexOfTd.floor();

  double indexOfId = inputDMPList.indexOf(matchI) / 2;
  int indexOfI = indexOfId.floor();

  double editDistance =
      levenshteinDistance(inputRomanized[indexOfI], targetRomanized[indexOfT]) +
      0.0;

  // double editDistance = 0;

  print("DMP match : $matchT | $matchI");
  print(min);

  return [min, editDistance];
}

double comparisonTrans(
  List<String> inputList,
  List<dynamic> targetList,
  double w,
) {
  var checker = PlagiarismCheckerPlus();
  double max = 0;
  String matchT = "";
  String matchI = "";
  for (String input in inputList) {
    for (String target in targetList) {
      var result = checker.check(input, target);
      print(result.similarityScore);
      if (max < result.similarityScore) {
        max = result.similarityScore;
        matchT = target;
        matchI = input;
      }
    }
  }

  print("Trans match : $matchT | $matchI");

  return (1 - max) * w;
}

int customCompareTo(
  var a,
  var b,
  List<double> songsPoints,
  List<double> editDistances,
  List<String> transOrDMP,
) {
  /*
  1, 0, -1을 return 해야한다.
  */

  if (songsPoints[a["number"]].compareTo(songsPoints[b["number"]]) == 0) {
    if (transOrDMP[a["number"]] == "D" && transOrDMP[b["number"]] == "D") {
      return editDistances[a["number"]].compareTo(editDistances[b["number"]]);
    } else {
      return 0;
    }
  } else {
    return songsPoints[a["number"]].compareTo(songsPoints[b["number"]]);
  }
}

Future<List<Map<String, dynamic>>> searchModule(String input) async {
  double w = 1; //번역과 더블 메타폰 사이의 가중치
  if (input.isEmpty) {
    return [];
  }
  List<String> inputDMPList = [];
  List<String> inputTransList = [];
  List<String> inputRomanized = [];
  List<String> inputKeywordList = module1(input, "");
  for (String keyword in inputKeywordList) {
    final converter = KoreanRomanizationConverter();
    var romanizedInputText = converter.romanize(keyword);
    inputRomanized.add(romanizedInputText);
    inputDMPList += inputToDoubleMetaPhone(romanizedInputText);
    inputTransList.add(await inputToTrans(input));
  }

  List<Map<String, dynamic>> songs = searchCases;
  List<double> songsDMPPoints = [];
  List<double> songsPoints = [];
  List<String> transOrDMP = [];
  List<double> editDistances = [];
  // List<int> songsNums = [for (var song in searchCases) song["number"]];

  for (Map<String, dynamic> song in songs) {
    if (song["number"] == 0) {
      songsPoints.add(0);
      songsDMPPoints.add(0.0);
      transOrDMP.add("T");
      editDistances.add(100);
      continue;
    }
    List<dynamic> keyword = [];
    List<dynamic> romanized = [];
    List<dynamic> translated = [];
    List<dynamic> doubleMetaphone = [];
    romanized = song["search_tag"][0];
    translated = song["search_tag"][1];
    doubleMetaphone = song["search_tag"][2];

    print(song["title"]);
    double transPoint = comparisonTrans(inputTransList, translated, w);
    double doubleMetaPhonePoint = 0.0;
    double editDistance = 0.0;
    List<dynamic> comparisonDMPresult = comparisonDMP(
      inputDMPList,
      doubleMetaphone,
      inputRomanized,
      romanized,
    );
    doubleMetaPhonePoint = comparisonDMPresult[0];
    editDistance = comparisonDMPresult[1];

    songsDMPPoints.add(doubleMetaPhonePoint);
    editDistances.add(editDistance);

    if (doubleMetaPhonePoint <= transPoint) {
      transOrDMP.add("D");
      songsPoints.add(doubleMetaPhonePoint);
    } else {
      transOrDMP.add("T");
      songsPoints.add(transPoint);
    }

    print("\n\n");
  }

  print(songsPoints);

  List<Map<String, dynamic>> songsSorted = List.from(songs);
  songsSorted.sort(
    (a, b) => customCompareTo(a, b, songsPoints, editDistances, transOrDMP),
  );

  return songsSorted;
}

Future<List<int>> searchEngine(String input) async {
  List<Map<String, dynamic>> searchResult = await searchModule(input);
  List<int> result = [for (var song in searchResult) song["number"]];
  return result;
}
