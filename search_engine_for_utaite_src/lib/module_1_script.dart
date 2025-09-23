List<String> keyword_to_split = ["/", "-", "(", ")", "[", "]"];
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
];

List<String> module1(String title, String channel) {
  /*
  우타이테 전용 인덱싱
  제목과 채널이름을 매개변수로 받아 키워드 리스트를 return 한다.
  */
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

  //띄어쓰기로 한 번 더 나누자
  newChannelSplit = [];
  for (String str in channelSplit) {
    newChannelSplit.addAll(str.split(" "));
  }
  channelSplit.addAll(newChannelSplit);

  newTitleSplit = [];
  for (String str in titleSplit) {
    newTitleSplit.addAll(str.split(" "));
  }
  titleSplit.addAll(newTitleSplit);

  //그리고 splt때문에 비어있는 부분들 없애주자.
  channelSplit = channelSplit.toSet().toList();
  titleSplit = titleSplit.toSet().toList();

  channelSplit.remove("");
  titleSplit.remove("");
  channelSplit.remove(" ");
  titleSplit.remove(" ");

  return titleSplit + channelSplit;
}

// void main() {
//   print(
//     module1(
//       "하나코 나나 - 길고 짧은 축제 (長く短い祭) Live Cover. [가사/해석]",
//       "[이어폰 필수]자상무색(自傷無色) jishou mushoku 하나땅 KK 좌우",
//     ),
//   );
// }
