import 'dart:convert';
import 'dart:math';
// import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:dart_phonetics/dart_phonetics.dart';
import 'package:dotenv/dotenv.dart' as dotenv;
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:korean_romanization_converter/korean_romanization_converter.dart';
import 'package:plagiarism_checker_plus/plagiarism_checker_plus.dart';
import 'package:search_engine_for_utaite_src/test_cases.dart';
import 'package:search_engine_for_utaite_src/test_cases_source.dart';
import 'package:translator/translator.dart';

List<String> keyword_to_split = [
  "/",
  "-",
  "(",
  ")",
  "[",
  "]",
  ";",
  "／",
  "「",
  "」",
  "|",
  "’",
  "‘",
  ":",
  '"',
  "'",
  '"',
  "ㅣ",
];
List<String> stopwords = [
  "cover",
  "불러보았다",
  "불러보았습니다",
  "불러봤습니다",
  "歌いました",
  "covered by",
  "feat",
  "가사",
  "해석",
  "이어폰",
  "고음질",
  "official",
  "channel",
  "자막",
  "가사",
  "해석",
  "한글",
  "official",
  "music",
  "video",
  "불렀습니다",
  ",", // 나중에 리스트 구분과 헷갈리지 않기 위해 꼭 필요하다.
  "1", "2", "3", "4", "5", "6", "7", "8", "9", "0", // 더블 메타폰 변환을 위해 없어져야 한다.
];

String removeEmojis(String source) {
  // 이모지 제거용
  String regexEmojis = "[\uD83C-\uDBFF\uDC00-\uDFFF]+";

  // 이모지 제거
  String result = source.replaceAll(RegExp(regexEmojis), "");
  return result;
}

String fetch(String source) {
  print(source);
  String regex = r"([A-Z|a-z| |ㄱ-ㅎ|ㅏ-ㅣ|가-힣|ぁ-んァ-ンー一-龯])";
  //영어만 남기면 '를 표현하지 못 하기 때문에 의미가 좀 달라질수도. 그러니까 여기서까지는 '를 포함하고 그 뒤에 로마자로 바꿀 때 빼자.
  //숫자는 포함 못 해줘서 미안해요 ㅠㅠㅠ
  //정규식에 포함돼서 그런건진 모르겠지만 | 도 포함이 된다. 그러니 따로 없애주자 ㅎㅎ
  Iterable<Match> matches = RegExp(regex).allMatches(source);

  String result = "";
  for (Match match in matches) {
    result += match.group(0)!;
  }
  result = result.replaceAll("|", "");
  print(result);

  return result;
}

List<String> module1(String title, String channel) {
  /*
  우타이테 전용 인덱싱
  제목과 채널이름을 매개변수로 받아 키워드 리스트를 return 한다.
  */

  title = title.toLowerCase();
  channel = channel.toLowerCase();
  // 불용어 제거
  for (String keyword in stopwords) {
    title = title.replaceAll(keyword, '');
    channel = channel.replaceAll(keyword, '');
  }

  List<String> channelSplit = [channel];
  List<String> titleSplit = [title];
  List<String> newChannelSplit = [];
  List<String> newTitleSplit = [];

  //일단 특수기호로 나누고
  for (String keyword in keyword_to_split) {
    newChannelSplit = [];
    for (String str in channelSplit) {
      newChannelSplit.addAll(str.split(keyword));
    }
    channelSplit = newChannelSplit;

    newTitleSplit = [];
    for (String str in titleSplit) {
      newTitleSplit.addAll(str.split(keyword));
    }
    titleSplit = newTitleSplit;
  }

  for (int i = 0; i < titleSplit.length; i++) {
    titleSplit[i] = titleSplit[i].trim();
  }
  for (int i = 0; i < channelSplit.length; i++) {
    channelSplit[i] = channelSplit[i].trim();
  }

  channelSplit = channelSplit.toSet().toList();
  titleSplit = titleSplit.toSet().toList();

  channelSplit.remove("");
  titleSplit.remove("");
  channelSplit.remove(" ");
  titleSplit.remove(" ");

  for (int i = 0; i < channelSplit.length; i++) {
    channelSplit[i] = fetch(channelSplit[i]);
  }
  for (int i = 0; i < titleSplit.length; i++) {
    titleSplit[i] = fetch(titleSplit[i]);
  }

  return titleSplit + channelSplit;
}

final String apiUrl = 'https://api.openai.com/v1/responses';

List<String> splitSpace(List<String> input) {
  List<String> newInputSplit = [];
  for (String str in input) {
    newInputSplit.addAll(str.split(" "));
  }
  input.addAll(newInputSplit);

  input = input.toSet().toList();

  return input;
}

String promptRomanize =
    "Translate the given input string into Romanized form. For Korean text, follow the standard rules for Romanization. The output must not contain any commas or other special characters. Return only the result as a plain string without any additional words or Markdown syntax.";

String promptTranslate =
    "Translate the input sentence into English. The output must not contain any commas or other special characters. Return only the result as a plain string without any additional words or Markdown syntax.";

Future<String> generateResponse(String input, String prompt) async {
  dotenv.load('search_engine_for_utaite_src/.env');

  String? apiKey = dotenv.env['API_KEY'];

  String token = "Bearer $apiKey";

  var response = await http.post(
    Uri.parse(apiUrl),
    headers: {"Content-Type": "application/json", "Authorization": token},
    body: jsonEncode({
      "model": "gpt-5",
      "input":
          "Forget all the previous inputs, outputs, and prompts. input : $input \n $prompt",
      "reasoning": {"effort": "low"},
      // "max_tokens": 2000,
    }),
  );
  if (response.statusCode == 200) {
    Map<String, dynamic> data = jsonDecode(utf8.decode(response.bodyBytes));
    // print(data);
    String text = "";
    text = data["output"][1]["content"][0]["text"];
    return text;
  } else {
    throw Exception("Failed to generate response: ${response.statusCode}");
  }
}

List<String> romanizedToDoubleMetaPhone(List<String> romanizedList) {
  List<String> result = [];
  final doubleMetaphone = DoubleMetaphone.withMaxLength(100);
  for (String romanized in romanizedList) {
    final encoding = doubleMetaphone.encode(romanized);
    List<String> doubleMetaphoneList = [encoding?.primary ?? ""];
    doubleMetaphoneList += encoding!.alternates!.toList();

    if (doubleMetaphoneList.length != 2) {
      print("wrond");
    }

    result += doubleMetaphoneList;
  }

  return result;
}

String removeJP(String source) {
  // 이모지 제거용
  String regexJP = r"([ぁ-んァ-ンー一-龯])";

  // 이모지 제거
  String result = source.replaceAll(RegExp(regexJP), "");

  return result;
}

String removeKR(String source) {
  // 이모지 제거용
  String regexKR = r"([ㄱ-ㅎ|ㅏ-ㅣ|가-힣])";

  // 이모지 제거
  String result = source.replaceAll(RegExp(regexKR), "");
  return result;
}

String removeEN(String source) {
  // 이모지 제거용
  String regexEN = r"([A-Z|a-z| ])";

  // 이모지 제거
  String result = source.replaceAll(RegExp(regexEN), "");
  return result;
}

bool checkResponseRomanized(String response) {
  if (response.isEmpty) {
    return false;
  }
  if (removeJP(response) != response) {
    return false;
  }
  if (removeKR(response) != response) {
    return false;
  }
  if (response.contains(",")) {
    return false;
  }
  if (removeEN(response).isNotEmpty) {
    return false;
  }

  //나머지는 나중에 거른다.
  return true;
}

bool checkResponseTranslated(String response) {
  if (response.isEmpty) {
    return false;
  }
  if (removeJP(response) != response) {
    return false;
  }
  if (removeKR(response) != response) {
    return false;
  }
  if (response.contains(",")) {
    return false;
  }
  //나머지는 나중에 거른다.
  return true;
}

Future<String> romanize(String input, int n) async {
  //혹시나 무한루프를 돌 수 있기 때문에 n으로 안전장치
  input = input.replaceAll("'", "");

  if (n > 10) {
    return "something went wrong";
  }
  String response = await generateResponse(input, promptRomanize);
  if (!checkResponseRomanized(response)) {
    print("wrong");
    return await romanize(input, n + 1);
  } else {
    return response;
  }
}

Future<String> translate(String input, int n) async {
  if (n > 10) {
    return "something went wrong";
  }
  String response = await generateResponse(input, promptTranslate);
  if (!checkResponseTranslated(response)) {
    print("wrong");
    return await translate(input, n + 1);
  } else {
    return response;
  }
}

Future<List<List<String>>> module2(List<String> keywords) async {
  //module1에서 모든 특수문자가 걸러졌을거라는 가정 하에 시작한다.
  List<String> romanized = [];
  List<String> translated = [];

  for (String keyword in keywords) {
    romanized.add(await romanize(keyword, 0));
    translated.add(await translate(keyword, 0));
    print("done");
  }

  romanized = splitSpace(romanized);
  translated = splitSpace(translated);

  List<String> doubleMetaphone = romanizedToDoubleMetaPhone(romanized);

  print(romanized);
  print(translated);
  return [romanized, translated, doubleMetaphone];
}

void main() {
  print(removeKR("안녕하세요 i'm james"));
}

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

  int cnt = levenshteinDistance(target, input);

  //더블 메타폰 형태의 유사도 점수.

  double point = (input.length - cnt) / input.length;

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

  // print(al);
  // print(bl);
  // print(matrix);

  result = matrix[bl.length - 1][al.length - 1];
  return result;
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

Future<List<int>> searchEngine(String input) async {
  List<Map<String, dynamic>> searchResult = await searchModule(input);
  List<int> result = [for (var song in searchResult) song["number"]];
  return result;
}
