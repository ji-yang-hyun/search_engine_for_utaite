import 'package:search_engine_for_utaite_src/test_cases.dart';

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
