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
  "】",
  "【",
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
