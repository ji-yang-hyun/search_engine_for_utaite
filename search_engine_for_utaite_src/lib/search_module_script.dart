import 'package:korean_romanization_converter/korean_romanization_converter.dart';
import 'package:dart_phonetics/dart_phonetics.dart';
import 'package:translator/translator.dart';

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

  return inputText;
}

int comparisonString(String input, String target) {
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

  return cnt;
}

int comparisonDMP(List<String> inputDMPList, List<String> targetDMPList) {
  int max = 0;
  int point;
  for (String inputDMP in inputDMPList) {
    for (String targetDMP in targetDMPList) {
      point = comparisonString(inputDMP, targetDMP);
      if (point > max) {
        max = point;
      }
    }
  }

  return max;
}

void searchModule(String input) async {
  final translator = GoogleTranslator();
  List<String> inputDMP = [];
  String inputTrans = "";
  inputDMP = inputToDoubleMetaPhone(input);
  inputTrans = await inputToTrans(input);
}

void main() {}
