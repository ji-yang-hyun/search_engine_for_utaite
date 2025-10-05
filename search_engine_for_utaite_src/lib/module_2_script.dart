import 'dart:convert';
// import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:dart_phonetics/dart_phonetics.dart';
import 'package:dotenv/dotenv.dart' as dotenv;
import 'package:http/http.dart' as http;
import 'package:korean_romanization_converter/korean_romanization_converter.dart';
import 'package:search_engine_for_utaite_src/module_1_script.dart';

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

/*
우려했던 ai사용의 문제점이 나타났다.
ai는 어쩔 수 없이 답변이 매 번 다를 수 밖에 없으니까 에러가 날 때가 있다. 확률적으로 2번에 한 번 꼴이니
결코 적지 않다.

해결방안
1. 프롬프트를 더 강화한다. 어떻게 안되는건지 연구 후 프롬프트를 고치자. -> 함
2. 프롬프트에 추가될 예시의 개수를 늘린다.
3. 확률을 최대한 높이고 그냥 될때까지 하게 만든다 -> 함

프롬프트를 강화했더니 7번에 1번꼴로 에러가 났다. 이정도 성능으로 일단 만족하자.
토큰 수와 성능 사이의 절충안을 찾아야 하기 떄문.
에휴 이래서 ai란....ㅉㅉ
*/


/*
내가 이 결과를 디버깅을 할 수가 없으니까 몰랐는데 더블 메타폰 결괏값 개판이였네.
조졌다 ㅎㅎㅎ

결과가 일정하지도 못 하고, 결과 퀄리티도 그닥이고, ai부담도 줄여줄 겸 그냥 더블메타폰은 페키지로 바꾸자... ㅋㅋ;
겸사겸사 번역 관련된것도 좀 손 대볼까?
LLM이 설마 번역을 못해줄까
근데 굳이? 저번에 썼듯이 한국어로 번역된걸 일본어 병음으로 검색하는것만 아니면 거의 모든 케이스가 가능해서
아 근데 영어로 번역된 제목... 아냐 근데 그것도 극소수니까 일단은 이렇게 놓자.
*/


/*
요소를 영어로 번역하고 그걸 배경으로 또 이상하게 module 1 처럼 쪼개서 계속 wrong response가 났었다.
그래서 프롬프트 수정함
*/

/*
프롬프트가 이상한지 지피티 얘가 계속 뭐 이상한 특수기호를 넣네 이걸 변환하면서
그리고 띄어쓰기 module 1에서 잘 못거른다

그리고 무엇보다 일본어는 띄어쓰기 없이 문장에서 단어가 많이 구분되니까...
원본 키워드에서 로마자로 바꾼거랑 번역한거에서 또 띄어쓰기를 포함한게 있으면 그걸 기준으로 나눠줘야겠다.
그리고 그 과정은 간단히 또 module1에 넣는걸로 하자 ㅋㅋ -> 그냥 모듈1에서 띄어쓰기 구분을 없애고 나중에 나누는걸로 바꿨다. 오히려 더 나을수도?
일단 gpt부담은 줄었음 ㅇㅇ
*/

/*
지금 봤는데 내가 거르지 못 한 특수기호가 있는 경우에 더블 메타폰 변환을 못한다.
이걸 프롬프트로 해결하기도 뭐하고 해서 그냥 모든 특수기호를 없애야할 것 같다.
그리고 이모지도 안된다.
그리고 더블 메타폰으로 변환할 때 숫자"만" 있으면 안된다, 근데 어차피 숫자는 걸러진다... 어차피 노래 제목에서 그리 중요하지 않을 가능성이 높으므로
그냥 불용어 취급을 해버리자.
*/


/*
한국어 로마자로 바꿀때 계속 그 리스트에 있는 영어로 쓰는 것 같아서
예를 들어 
리제 -> rije가 맞는데
리스트에 lize있다고 그걸 그대로 쓰거나 막 그래서 프롬프트 수정했다.
골치아파서 그냥 한국어는 어차피 로마자 변환 규칙이 명확하니까 그냥 라이브러리 돌릴까도 했지만, 그냥 뒀다.
*/

/*
tlqkf
일단은 문제가 "리제"같은 단어를 원래 로마자 규칙대로라면 rije라고 해야하고 실제로 라이브러리에서는 그렇게 한다.
그런데 gpt가 빡통이라 이걸 옆에있는거 가져와서 lize라고 해버린다.
이걸 뭐 잡기도 뭐하고 그래서 그냥 한국어는 ai 안쓰고 그냥 라이브러리로 로마자로 바꾸려고 한다.
그 과정에서 프롬프트를 수정하여 한국어는 남기도록 했는데 그게 안되는 경우들이 있어서 고치는중이다
ai이 빡통색기

결국은 이렇게 됐네 ㅋㅋㅋ 그래도 성능은 더 나을 것 같다.

지금도 아직 한국어를 영어로 바꿔버리는 만행을 저지르긴 하는데
그것도 꼭 잡아야되나...?
ai 쓰는건데 이정도는 그냥 넘어갈까
잡자 그냥...

이제 한국어가 영어로 바뀌는 거 잡아야함.
결국에는 ai를 사용한다는건 확률싸움이기 때문에 여러가지 안전장치들을 적용하는것이다.
*/

/*
아니 시발 이 미친 ai색기 그냥 한국어랑 일본어 구분해서 하는게 뭐 그리 어려운지 계속 못한다.
내가 프롬프트를 못 짜서 그런걸수도 있는데 나는 뭐 프롬프트 짜는 사람은 아니니까...
이걸 어떻게 해야하는가...
내 생각에는 ai가 판단을 그냥 못 하는 것 같다.
어휴 진짜... temp값도 낮추고 이것저것 해봤는데 얘가 계속 구분을 못 한다...
방법은 두 가지다. 정규식을 잘 써서 일본어 부분이나 한국어 부분을 따로 뺀 상태로 ai에 집어넣거나
아니면 그냥 더 좋은 gpt를 쓰거나.

이것참 열받아서 못해먹겠군요.
gpt5 쓰는거 뭔가 안땡기니 이악물고 gpt4계속 써서 일본어 감지해서 거기만 로마자로 바꿀겁니다 씹새들아.
수고해라
*/

/*
너무 감정적인 판단이야.
지금 문제랑 해결방법을 더 잘 생각해보자.

지금 문제는 gpt의 성능이 낮아서
1. 한국어를 로마자로 변형함에 있어서 표준을 지키지 않는다. 답이 틀리다.
2. 그 문제가 일본어에도 똑같이 있을수도있다.
3. 그래서 한국어라도 라이브러리 쓰려고 한국어 빼고 일본어만 로마자로 하라고 했는데, 마찬가지로 gpt성능때문에 안된다.(내 gpt5는 잘 한다.)

-> 결국은 gpt성능을 높이면 된다.
근데 문제는 그 과정에서 사용법을 찾는게 너무 어렵다는거지.
일단 그러면 첫 번째로 할 일은 gpt5한테 응답을 받는거야.
그 후에는 어떻게 하냐!
1. 지금 프롬프트 잘 되나 확인.
2. 예전 프롬프트(gpt가 모듈 2의 전부를 담당할 때)를 얼마나 소화하는지.

그 후에는 이제 2번 결과가 아쉬우면 어쩔 수 없이 한국어라도 따로 빼는거고...

그리고 주변 문장과의 연관성 찾지 말라는 것 보다 그냥 따로따로 넣어주고 응답받는게 더 나을 것 같다.

근데 이게 속도가 느려지네... 결과물 자체는 정말 정확한 것 같다.
이정도면 사실 원래 그 프롬프트 넣어도 될 것 같은데?
근데 이게 이제 비용이랑 시간도 생각해야 한다.
그러니까 한 번에 다 처리하려고 하면 안될 것 같다.
로마자로 바꾸는거랑 번역하는거랑 다른 걸로 해서 두 개의 구분등등을 위한 프롬프트를 줄이자.
딱히 강조하거나 뭐 그럴 필요는 없어보이니까 비용을 위해서 좀 더 짧은 프롬프트를 만드는게 좋을 것 같다.
*/