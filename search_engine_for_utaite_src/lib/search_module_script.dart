import 'package:korean_romanization_converter/korean_romanization_converter.dart';
import 'package:dart_phonetics/dart_phonetics.dart';

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

void searchModule(String inputText) {
  List<String> doubleMetaphoneInputText = inputToDoubleMetaPhone(inputText);
}

void main() {
  searchModule("요시노");
}
