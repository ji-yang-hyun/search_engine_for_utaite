import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

final String apiUrl = 'https://api.openai.com/v1/chat/completions';

String prompt =
    " Convert the given list into Romanized form, translated form, and Double Metaphone form.	•	Romanized form means converting everything into Romanization, regardless of the original language. Use only lowercase alphabets.	•	Translated form means converting everything into English, regardless of the original language.	• Double Metaphone form means converting the Romanized list into Double Metaphone codes.  • When converting into Double Metaphone form, all spaces in the Romanized text must be removed.	•	Double Metaphone form includes both primary and secondary results, so the resulting array will be twice as long. Example: Input: [안녕, 吉乃, 길고 짧은 축제] Romanized form: [annyeong, yoshino, gilgo jjalbeun chugje] Translated form: [hello, yoshino, long and short festival] Double Metaphone form: [ANNK, ANNK, AHSN, YXN, KLPJNXJ, KLPJNXJ] Output should be exactly three result lists printed in order, without any extra words or Markdown formatting. Example Input: [안녕, 吉乃, 길고 짧은 축제] Example Output: [annyeong, yoshino, gilgo jjalbeun chugje],[hello, yoshino, long and short festival],[ANNK, ANNK, AHSN, YXN, KLPJNXJ, KLPJNXJ]";

Future<String> generateResponse(List<String> inputList) async {
  /*
  module1에서 indexing한 키워드들의 리스트를 받아서 chatGPT에게 입력으로 전달한다.
  chatGPT는 프롬프트를 따라 로마자, 번역, 더블메타폰 형태를 쉼표와 []로 구분된
  String 으로 return 해준다. 그리고 이 함수는 그 String을 return한다.
  */
  await dotenv.load(fileName: '.env');

  String apiKey = dotenv.env['API_KEY']!;
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
      'max_tokens': 60,
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

List<List<String>> responseFetch(String response, int keywordCount) {
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
  } else {
    print("wrong response try again");
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

void module2(List<String> stringSplit) async {}

void main() {
  print(
    responseFetch(
      "[yooei, dazeubi, yoshino, phone],[yooei, dazeubi, yoshino, phone],[Y, A, TSP, TSP, AHSN, YXN, FN, FN]",
      4,
    ),
  );
  // print(["하이", "사랑", "吉乃", "phone"].toString());
}

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
나 서브모듈 아니야. 다시
*/