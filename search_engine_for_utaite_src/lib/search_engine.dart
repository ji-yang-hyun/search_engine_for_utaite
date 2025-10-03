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

List<String> module1(String title, String channel) {
  /*
  우타이테 전용 인덱싱
  제목과 채널이름을 매개변수로 받아 키워드 리스트를 return 한다.
  */

  title = title.toLowerCase();
  channel = channel.toLowerCase();
  title = removeEmojis(title);
  channel = removeEmojis(channel);
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

  // //띄어쓰기로 한 번 더 나누자
  // newChannelSplit = [];
  // for (String str in channelSplit) {
  //   newChannelSplit.addAll(str.split(" "));
  // }
  // channelSplit.addAll(newChannelSplit);

  // newTitleSplit = [];
  // for (String str in titleSplit) {
  //   newTitleSplit.addAll(str.split(" "));
  // }
  // titleSplit.addAll(newTitleSplit);

  //그리고 splt때문에 비어있는 부분들 없애주자.

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

  return titleSplit + channelSplit;
}

final String apiUrl = 'https://api.openai.com/v1/chat/completions';

List<String> splitSpace(List<String> input) {
  List<String> newInputSplit = [];
  for (String str in input) {
    newInputSplit.addAll(str.split(" "));
  }
  input.addAll(newInputSplit);

  input = input.toSet().toList();

  return input;
}

String prompt =
    "The given list elements are separated by commas.Convert the given list into Romanized form and Translated form. \n•	Romanized form means converting everything into Romanization, regardless of the original language.\n•	Translated form means converting everything into English, regardless of the original language. \n When converting into the translated form, you don’t need to consider any relationships or contexts between the elements in the list. Just translate each element from given list into English on a one-to-one basis. \n When converting into Romanized form, do not establish any correlation between the elements of the list. You must not consider any relationships or contexts between the elements in the list. \n When you convert korean to romanized, Convert each element individually and strictly follow the official Romanization rules of the korean. Every element must be Romanized consistently and accurately according to the standardized rules, with no exceptions. \n •	The lists will mainly contain Korean, English, and Japanese. \n The result must never contain special characters. \nExample input: [안녕, 吉乃, 길고 짧은 축제] \nExample output: [annyeong, yoshino, gilgo jjalbeun chugje],[hello, yoshino, long and short festival] \n When outputting, print only the two resulting lists in order. Do not use Markdown syntax, extra words, or commas for anything other than separating list elements or separating the two result lists.";

Future<String> generateResponse(List<String> inputList) async {
  /*
  module1에서 indexing한 키워드들의 리스트를 받아서 chatGPT에게 입력으로 전달한다.
  chatGPT는 프롬프트를 따라 로마자, 번역 형태를 쉼표와 []로 구분된
  String 으로 return 해준다. 그리고 이 함수는 그 String을 return한다.
  response는 [로마자, 번역]형식.
  */
  // await dotenv.load(fileName: '.env');

  // String apiKey = dotenv.env['API_KEY']!;

  dotenv.load('search_engine_for_utaite_src/.env');

  String? apiKey = dotenv.env['API_KEY'];

  String token = "Bearer $apiKey";

  var response = await http.post(
    Uri.parse(apiUrl),
    headers: {"Content-Type": "application/json", "Authorization": token},
    body: jsonEncode({
      "model": "gpt-4o",
      'messages': [
        {'role': 'system', 'content': prompt},
        {'role': 'user', 'content': inputList.toString()},
      ],
      'max_tokens': 10000,
    }),
  );
  if (response.statusCode == 200) {
    Map<String, dynamic> data = jsonDecode(utf8.decode(response.bodyBytes));
    String text = data["choices"][0]["message"]["content"].toString().trim();
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

Future<List<List<String>>> responseFetch(
  String response,
  int keywordCount,
  List<String> keywords,
) async {
  /*
    generateResponse에서 response를 받고, 알맞은 결과인지 확인을 위해
    처음 입력값으로 주어진 키워드들의 개수도 확인한다.
  */

  List<String> romanized = [];
  List<String> translated = [];
  List<String> doubleMetaphone = [];
  List<List<String>> result = [[], [], []];

  List<String> responseSplit = [];

  response = response.replaceAll("[", "");
  response = response.replaceAll("]", "");
  response = response.replaceAll("\n", "");
  responseSplit = response.split(',');

  if (keywordCount * 2 == responseSplit.length) {
    print("good");
  } else {
    print("wrong response try again");
    var value = await module2(keywords);
    return value;
  }

  for (int i = 0; i < responseSplit.length; i++) {
    if (i < responseSplit.length / 2) {
      romanized.add(responseSplit[i].trim());
    } else {
      translated.add(responseSplit[i].trim());
    }
  }

  print(romanized);

  //원래 공백이 없는 일본어를 위해 나중에 나눈다.
  romanized = splitSpace(romanized);
  translated = splitSpace(translated);

  doubleMetaphone = romanizedToDoubleMetaPhone(romanized);

  result = [romanized, translated, doubleMetaphone];

  return result;
}

Future<List<List<String>>> module2(List<String> keywordSplit) async {
  String response = await generateResponse(keywordSplit);
  List<List<String>> keyword3form = await responseFetch(
    response,
    keywordSplit.length,
    keywordSplit,
  );

  return keyword3form;
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
