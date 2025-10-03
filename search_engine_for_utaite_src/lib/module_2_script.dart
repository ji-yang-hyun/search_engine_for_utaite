import 'dart:convert';
// import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:dart_phonetics/dart_phonetics.dart';
import 'package:dotenv/dotenv.dart' as dotenv;
import 'package:http/http.dart' as http;

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
    "The given list elements are separated by commas.Convert the given list into Romanized form and Translated form. \n•	Romanized form means converting everything into Romanization, regardless of the original language.\n•	Translated form means converting everything into English, regardless of the original language. \n When converting into the translated form, you don’t need to consider any relationships or contexts between the elements in the list. Just translate each element from given list into English on a one-to-one basis. \n When converting into Romanized form, do not establish any correlation between the elements of the list. Convert each element individually based on the Romanization rules.\n•	The lists will mainly contain Korean, English, and Japanese. \n The result must never contain special characters. \nExample input: [안녕, 吉乃, 길고 짧은 축제] \nExample output: [annyeong, yoshino, gilgo jjalbeun chugje],[hello, yoshino, long and short festival] \n When outputting, print only the two resulting lists in order. Do not use Markdown syntax, extra words, or commas for anything other than separating list elements or separating the two result lists.";

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
/*
지금 봤는데 내가 거르지 못 한 특수기호가 있는 경우에 더블 메타폰 변환을 못한다.
이걸 프롬프트로 해결하기도 뭐하고 해서 그냥 모든 특수기호를 없애야할 것 같다.
그리고 이모지도 안된다.
그리고 더블 메타폰으로 변환할 때 숫자"만" 있으면 안된다, 근데 어차피 숫자는 걸러진다... 어차피 노래 제목에서 그리 중요하지 않을 가능성이 높으므로
그냥 불용어 취급을 해버리자.
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
한국어 로마자로 바꿀때 계속 그 리스트에 있는 영어로 쓰는 것 같아서
예를 들어 
리제 -> rije가 맞는데
리스트에 lize있다고 그걸 그대로 쓰거나 막 그래서 프롬프트 수정했다.
*/



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
[하이, 안녕, 吉乃, phone]
주어진 리스트의 각 요소들은 콤마로 구분돼있어.
주어진 리스트를 로마자 형태와 번역 형태로 바꿔줘.
로마자 형태는 언어에 상관 없이 전부 로마자 표기로 바꾸는 걸 말해.
번역 형태는 어떤 언어던지 전부 영어로 번역하여 표기하는 걸 말해.
리스트는 주로 한국어, 영어, 일본어가 사용될거야.

첫 형태의 배열 : [안녕, 吉乃, 길고 짧은 축제]
로마자 형태 : [annyeong, yoshino, gilgo jjalbeun chugje]
번역 형태 : [hello, yoshino, long and short festival]
출력은 아무런 말이나 마크다운 문법 없이 두 개의 결과 리스트를 차례로 출력해주면 돼.
리스트의 요소 구분 외에 다른 용도로는 절대 콤마를 사용하면 안 돼.

입출력 예시)
입력 : [안녕, 吉乃, 길고 짧은 축제]
출력 : 
[annyeong, yoshino, gilgo jjalbeun chugje]
[hello, yoshino, long and short festival]


The given list elements are separated by commas.
Convert the given list into Romanized form and Translated form.
	•	Romanized form means converting everything into Romanization, regardless of the original language.
	•	Translated form means converting everything into English, regardless of the original language.
	•	The lists will mainly contain Korean, English, and Japanese.

Example input:
[안녕, 吉乃, 길고 짧은 축제]

Example output:
[annyeong, yoshino, gilgo jjalbeun chugje]
[hello, yoshino, long and short festival]

When outputting, print only the two resulting lists in order.
Do not use Markdown syntax, extra words, or commas for anything other than separating list elements.
*/