import 'dart:convert';
// import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:dotenv/dotenv.dart' as dotenv;
import 'package:http/http.dart' as http;

final String apiUrl = 'https://api.openai.com/v1/chat/completions';

String prompt =
    "The elements in the given list are separated by commas. Convert the given list into Romanized form, translated form, and Double Metaphone form.	•	Romanized form means converting everything into Romanization, regardless of the original language. Use only lowercase alphabets. All spaces must be removed when converting into Romanized form.	•	Translated form means converting everything into English, regardless of the original language.	• The Double Metaphone form must be generated based on the Romanized form. In this process, all spaces in the Romanized text must be removed. In other words, each list element (separated by commas) should be treated as a single string without spaces and commas when converting to Double Metaphone. (Example: “gilgo jjalbeun chugje” -> “KLPJNXJ”)	•	Double Metaphone form includes both primary and secondary results, so the resulting array will be twice as long. In the generated answer, commas must never be used for anything other than separating list elements. Example: Input: [안녕, 吉乃, 길고 짧은 축제] Romanized form: [annyeong, yoshino, gilgo jjalbeun chugje] Translated form: [hello, yoshino, long and short festival] Double Metaphone form: [ANNK, ANNK, AHSN, YXN, KLPJNXJ, KLPJNXJ] Output should be exactly three result lists printed in order, without any extra words or Markdown formatting. Example Input: [안녕, 吉乃, 길고 짧은 축제] Example Output: [annyeong, yoshino, gilgo jjalbeun chugje],[hello, yoshino, long and short festival],[ANNK, ANNK, AHSN, YXN, KLPJNXJ, KLPJNXJ]";

Future<String> generateResponse(List<String> inputList) async {
  /*
  module1에서 indexing한 키워드들의 리스트를 받아서 chatGPT에게 입력으로 전달한다.
  chatGPT는 프롬프트를 따라 로마자, 번역, 더블메타폰 형태를 쉼표와 []로 구분된
  String 으로 return 해준다. 그리고 이 함수는 그 String을 return한다.
  response는 [로마자, 번역, 더블 메타폰]형식.
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

  if (keywordCount * 4 == responseSplit.length) {
    print("good");
  } else {
    print("wrong response try again");
    module2(keywords).then((value) {
      return value;
    });
    // print(responseSplit.length);
    // print(response);
    // print(keywordCount);
    // print(response);
    // print("\n\n\n\n");
    //chatGPT가 알맞은 응답을 주지 않았기 때문에 다시 generateResponse해야한다.
  }

  int o = 0;
  for (int i = 0; i < responseSplit.length; i++) {
    if (i == keywordCount) {
      o += 1;
    }
    if (i == keywordCount * 2) {
      o += 1;
    }
    result[o].add(responseSplit[i].trim());
  }

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

// void main() {
//   // generateResponse([
//   //   "그래서 나는 음악을 그만두었다",
//   //   "요루시카",
//   //   "다즈비",
//   //   "그래서",
//   //   "나는",
//   //   "음악을",
//   //   "그만두었다",
//   //   "dzb",
//   // ]).then((value) {
//   //   print(value);
//   // });
//   // print(
//   //   responseFetch(
//   //     "[geuraeseo naneun eumageul geumandueotda, yorushika, dazubi, geuraeseo, naneun, eumageul, geumandueotda, dzb],[so i quit music, yorushika, dazubi, so, i, music, quit, dzb],[KRSNNNEMKLKMNTT, KRSNNNEMKLKMNTT, YRXK, YRSK, TSP, TSP, KRSNNN, KRSNNN, NN, NN, AMKL, AMKL, KMNTT, KMNTT, TSP, TSP]",
//   //     8,
//   //   ),
//   // );

//   module2([
//     "그래서 나는 음악을 그만두었다",
//     "요루시카",
//     "다즈비",
//     "그래서",
//     "나는",
//     "음악을",
//     "그만두었다",
//     "dzb",
//   ]).then((value) {});
// }

/*
[하이, 안녕, 吉乃, phone]
주어진 리스트를 로마자 형태, 번역 형태, 더블 메타폰형태로 바꿔줘.
로마자 형태는 언어에 상관 없이 전부 로마자 표기로 바꾸는 걸 말해.
번역 형태는 어떤 언어던지 전부 영어로 번역하여 표기하는 걸 말해.
더블 메타폰 형태는 로마자 형태로 변형된 리스트를 전부 더블 메타폰 형태로 바꾸는 걸 말해.
더블 메타폰 형태는 primary와 secondary가 있어. 둘 다 포함할거기 때문에
더블 메타폰 형태로 변환된 배열은 길이가 두 배가 돼.
첫 형태의 배열 : [안녕, 吉乃, 길고 짧은 축제]
로마자 형태 : [annyeong, yoshino, gilgo jjalbeun chugje]
번역 형태 : [hello, yoshino, long and short festival]
더블 메타폰 형태 : [ANNK, ANNK, AHSN, YXN, KLPJNXJ, KLPJNXJ]
출력은 아무런 말이나 마크다운 문법 없이 세 개의 결과 리스트를 차례로 출력해주면 돼.

입출력 예시)
입력 : [안녕, 吉乃, 길고 짧은 축제]
출력 : 
[annyeong, yoshino, gilgo jjalbeun chugje]
[hello, yoshino, long and short festival]
[ANNK, ANNK, AHSN, YXN, KLPJNXJ, KLPJNXJ]
*/


/*
[하이, 안녕, 吉乃, phone]
Convert the given list into Romanized form, translated form, and Double Metaphone form.
	•	Romanized form means converting everything into Romanization, regardless of the original language. Use only lowercase alphabets.
	•	Translated form means converting everything into English, regardless of the original language.
	• Double Metaphone form means converting the Romanized list into Double Metaphone codes.
  • When converting into Double Metaphone form, all spaces in the Romanized text must be removed.
	•	Double Metaphone form includes both primary and secondary results, so the resulting array will be twice as long.

Example:
Input: [안녕, 吉乃, 길고 짧은 축제]
Romanized form: [annyeong, yoshino, gilgo jjalbeun chugje]
Translated form: [hello, yoshino, long and short festival]
Double Metaphone form: [ANNK, ANNK, AHSN, YXN, KLPJNXJ, KLPJNXJ]

Output should be exactly three result lists printed in order, without any extra words or Markdown formatting.

Example Input: [안녕, 吉乃, 길고 짧은 축제]
Example Output:
[annyeong, yoshino, gilgo jjalbeun chugje]
[hello, yoshino, long and short festival]
[ANNK, ANNK, AHSN, YXN, KLPJNXJ, KLPJNXJ]
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
[
    "그래서 나는 음악을 그만두었다",
    "요루시카",
    "다즈비",
    "그래서",
    "나는",
    "음악을",
    "그만두었다",
    "dzb",
  ]
[geuraeseo naneun eumageul geumandueotda, yorushika, dazubi, geuraeseo, naneun, eumageul, geumandueotda, dzb],
[so i quit music, yorushika, dazubi, so, i, music, quit, dzb],
[KRSNNNEMKLKMNTT, KRSNNNEMKLKMNTT, YRXK, YRSK, TSP, TSP, KRSNNN, KRSNNN, NN, NN, AMKL, AMKL, KMNTT, KMNTT, TSP, TSP]


*/



/*
guraeseo naneun eumageul geumandueotda, yorushika, dazbii, guraeseo, naneun, eumageul, geumandueotda, dzb,
therefore i stopped music, yorushika, dazbii, therefore, i, music, stopped, dzb,
KRS, KRS, NNNN, NNNN, AMKLKMNTRT, AMKLKMNTRT, ARXK, TRXK, TSP, TSP, KRS, KRS, NNNN, NNNN, AMKL, AMKL, KMNTRT, KMNTRT, TSP, TSP
*/


/*
주어진 리스트를 로마자 형태, 번역 형태, 더블 메타폰 형태로 변환하시오.
• 로마자 형태는 모든 언어를 로마자 표기로 변환하며, 알파벳은 모두 소문자만 사용한다.
• 번역 형태는 모든 언어를 영어로 번역한다.
• 더블 메타폰 형태는 로마자 형태를 기준으로 변환한다. 이때 로마자 표기에서 띄어쓰기를 모두 제거해야 한다. 즉 리스트의 요소 하나는 띄어쓰기 없는 하나의 문자열로 보고 더블 메타폰으로 변환하여야 한다.
(예시 "gilgo jjalbeun chugje" -> "KLPJNXJ")
• 더블 메타폰 형태는 1차 결과와 2차 결과를 모두 포함해야 하므로, 결과 배열은 두 배 길이가 된다.


예시:
입력: [안녕, 吉乃, 길고 짧은 축제]
로마자 형태: [annyeong, yoshino, gilgo jjalbeun chugje]
번역 형태: [hello, yoshino, long and short festival]
더블 메타폰 형태: [ANNK, ANNK, AHSN, YXN, KLPJNXJ, KLPJNXJ]

출력은 반드시 세 개의 결과 리스트만 순서대로, 불필요한 단어나 마크다운 없이 작성한다.

예시 입력: [안녕, 吉乃, 길고 짧은 축제]
예시 출력: [annyeong, yoshino, gilgo jjalbeun chugje],[hello, yoshino, long and short festival],[ANNK, ANNK, AHSN, YXN, KLPJNXJ, KLPJNXJ]
*/