//import 'dart:math' as math;
//import 'mental_screen.dart';
import 'package:flutter/services.dart';

enum Overview { positive, neutral, negative }
enum Mood {
  happy(
    label: 'Hạnh phúc',
    asset: 'assets/images/Mood/mood_happy.png',
    color: Color(0xFF4C8DFF),
  ),
  neutral(
    label: 'Trung lập',
    asset: 'assets/images/Mood/mood_neutral.png',
    color: Color(0xFFFFC94A),
  ),
  angry(
    label: 'Tức giận',
    asset: 'assets/images/Mood/mood_angry.png',
    color: Color(0xFFFF7A5C),
  ),
  tired(
    label: 'Mệt mỏi',
    asset: 'assets/images/Mood/mood_tired.png',
    color: Color(0xFF7B6CF6),
  ),
  cry(
    label: 'Buồn',
    asset: 'assets/images/Mood/mood_cry.png',
    color: Color(0xFF5CC8B5),
  );

  final String label;
  final String asset;
  final Color color;

  const Mood({
    required this.label,
    required this.asset,
    required this.color,
  });
}

class MoodOverview {
  final String status; // ví dụ: 'Tích cực'
  final String message; // đoạn mô tả
  final Color color; // màu chữ của status
  final Overview overview;

  const MoodOverview({
    required this.status,
    required this.message,
    required this.color,
    required this.overview,
  });
}

const positiveOverview = MoodOverview(
  status: 'Tích cực',
  message:
  'Tâm trạng của bạn đang tốt lên mỗi ngày, hãy giữ lấy đà này nhé.\n'
      '• Ghi nhớ cảm giác dễ chịu này, nó sẽ là điểm tựa những lúc khó khăn.\n'
      '• Duy trì thói quen tốt như ngủ đủ giấc và vận động nhẹ nhàng.\n'
      '• Dành thời gian cho điều bạn yêu thích.\n'
      '• Chia sẻ niềm vui với người xung quanh, niềm vui sẽ được nhân lên.',
  color: Color(0xFF2E9E8F),
  overview: Overview.positive,
);

const neutralOverview = MoodOverview(
  status: 'Ổn định',
  message:
  'Tâm trạng của bạn đang ở mức ổn định, và như vậy là hoàn toàn bình thường.\n'
      '• Giữ gìn những điều nhỏ khiến bạn dễ chịu: một tách trà ấm, một bản nhạc, một buổi đi dạo.\n'
      '• Thử một hoạt động mới như đọc sách, vẽ, nấu ăn hoặc tập thể dục nhẹ.\n'
      '• Dành cho mình một khoảng yên tĩnh khi thấy mệt, nghỉ ngơi cũng là chăm sóc tinh thần.',
  color: Color(0xFF2FC25D),
  overview: Overview.neutral,
);

const negativeOverview = MoodOverview(
  status: 'Cần chăm sóc',
  message:
  'Dạo này tâm trạng của bạn có vẻ chưa tốt, và điều đó hoàn toàn bình thường. Bạn không cần phải gồng mình hay tự trách bản thân.\n'
      '• Cho mình thời gian nghỉ ngơi, ngủ đủ giấc và ăn uống đầy đủ.\n'
      '• Thử những việc nhẹ nhàng như nghe nhạc, đọc sách, đi dạo hoặc thiền.\n'
      '• Trò chuyện với người thân hoặc bạn bè mà bạn tin tưởng.\n'
      '• Nếu cảm giác này kéo dài nhiều ngày hoặc ảnh hưởng đến sinh hoạt hằng ngày, hãy tìm đến chuyên gia tâm lý hoặc bác sĩ. Tìm sự giúp đỡ là một việc dũng cảm.',
  color: Color(0xFFFF8A5C),
  overview: Overview.negative,
);

extension OverviewX on Overview {
  String get label => const {
    Overview.positive : 'Tích cực',
    Overview.neutral : 'Trung lập',
    Overview.negative : 'Tiêu cực',
  }[this]!;

  String get asset => const {
    Overview.positive: 'assets/images/Overview/overview_neutral.png',
    Overview.neutral: 'assets/images/Overview/overview_positive.png',
    Overview.negative: 'assets/images/Overview/overview_negative.png',
  }[this]!;

  MoodOverview get overviewData => const {
    Overview.positive: positiveOverview,
    Overview.neutral: neutralOverview,
    Overview.negative: negativeOverview,
  }[this]!;
}

class Song {
  final String title, content;
  final Mood mood; // bài này hợp với tâm trạng nào
  //final String coverUrl; // hình ảnh bài hát;
  final Mood mood2;
  final String id;
  //final String url;
  const Song(this.title, this.content, this.mood, this.mood2, this.id);
  String get url => 'https://open.spotify.com/playlist/$id';
}

class Message {
  final String content;
  final Overview overview;

  const Message(this.content, this.overview);
}
const songs = [
  Song('Cozy Coffee Shop', 'Nhạc Jazz cho 1 ngày phấn khởi', Mood.happy, Mood.neutral, '5vVSfOsF8YRueAI1dOI0Lh'),
  Song('Classical Piano', 'Giúp thư giãn trí óc', Mood.tired, Mood.angry, '37i9dQZF1DWUqIzZNMSCv3'),
  Song('Ambient Relaxation', 'Âm thanh của bình yên', Mood.angry, Mood.neutral, '37i9dQZF1DX3Ogo9pFvBkY'),
  Song('Ocean Ambient', 'Giấc ngủ hòa cùng tiếng đại dương', Mood.neutral, Mood.tired, '3bOWrzil9JfMtd2nqiEUx2'),
  Song('Japanese Zen Garden', 'Nhạc chữa lành phong cách Nhật', Mood.cry, Mood.happy, '0XvBIoFUDrKfoPmnhz1fS4'),
  Song('Sleep', 'Nhạc đi ngủ zzzz', Mood.tired, Mood.neutral, '37i9dQZF1DWZd79rJ6a7lp'),
  Song('Bossa Nova Chill', 'Nhạc Bossa Nova vui tươi nhẹ nhàng', Mood.happy, Mood.neutral, '37i9dQZF1DWWgccrbg3zbJ'),
  Song('Deep Sleep', 'Nhạc đi ngủ nhưng sâuuu', Mood.tired, Mood.cry, '37i9dQZF1DWYcDQ1hSjOpY'),
  Song('Todays Top Híts' , 'Khởi đầu ngày mới năng lượng tích cực', Mood.happy, Mood.angry, '37i9dQZF1DXcBWIGoYBM5M'),
  Song('Peaceful Piano', 'Không gian piano bay bổng', Mood.cry, Mood.neutral, '37i9dQZF1DX4sWSpwq3LiO'),
  Song('Amazing Dance Music', 'Nhạc quẩy sôi động ^-^ ', Mood.happy, Mood.happy, '1fve3LRzJzIbtKgIYoDrqA'),
];

const message = [
  // 1. NHÓM POSITIVE (Tích cực, khích lệ, niềm tin, hy vọng)
  Message('Hãy hướng về tương lai tốt đẹp, mọi phiền muộn của quá khứ hãy bỏ lại sau lưng.', Overview.positive),
  Message('Hoàng hôn cho chúng ta ít ngày hơn để sống, nhưng mặt trời cho chúng ta thêm một ngày hi vọng vì vậy hãy vui lên và hy vọng những điều tốt đẹp nhất.', Overview.positive),
  Message('Mỉm cười khi vui, mỉm cười khi đau, mỉm cười với những điều thú vị trong cuộc sống. Mỉm cười khi một ai đó làm tổn thương em, em biết không, nụ cười là liều thuốc đầu tiên luôn làm lành vết thương trong em.', Overview.positive),
  Message('Cố hết sức mình đi, tôi biết bạn sẽ làm được. Đây là thế giới của hành động và thử thách, không phải thế giới của sự lười biếng và hèn nhát.', Overview.positive),
  Message('Đời có bao nhiêu đâu mà buồn, hãy vững tin và quên đi tất cả. Cuộc sống có vô vàn những điều tốt đẹp đang chờ bạn phía trước, vui vẻ đón nhận bạn sẽ thấy thật hạnh phúc và bình yên.', Overview.positive),
  Message('Thượng đế ban cho chúng ta giấc mơ khi chúng ta ngủ để chúng ta biến giấc mơ đó thành sự thật. Vì vậy hãy luôn tin tưởng và bước về phía trước bạn nhé!', Overview.positive),
  Message('Mỗi ngày là một cơ hội mới. Bạn có thể dựa vào thành công của hôm qua hoặc để lại những thất bại phía sau để bắt đầu lại từ đầu. Đó là cách của cuộc sống, một cuộc chơi mới mỗi ngày.', Overview.positive),
  Message('Thành công lớn nhất là đứng dậy sau mỗi lần vấp ngã.', Overview.positive),
  Message('Thành công sẽ không bao giờ từ chối những con người dám nghĩ dám làm. Tôi tin bạn sẽ làm được tốt hơn thế.', Overview.positive),
  Message('Không có gì là không thể. Có công mài sắt, cần cù thì có ngày nên kim.', Overview.positive),
  Message('Sự phát triển cần vốn, và thời gian cũng là một loại vốn, trân quý thời gian chính là cắt giảm vốn. Một trong những câu nói ý nghĩa về cuộc đời về làm kinh tế cho một mình và gia đình có liên quan sự thành công.', Overview.positive),

  // 2. NHÓM NEUTRAL (Trung lập, triết lý, thực tế, chiêm nghiệm)
  Message('Thất bại là mẹ thành công. Không có con đường nào trải đầy hoa hồng, phải có chông gai, có vấp ngã mới trưởng thành.', Overview.neutral),
  Message('Đời là 1 hợp đồng trọn gói -"Niềm vui, hạnh phúc, nỗi buồn và đau khổ". Tất cả chỉ bán chung 1 gói mà không thể nào tách riêng ra được.', Overview.neutral),
  Message('Con người không ai là hoàn hảo, sẽ có khi mắc sai lầm nhưng hãy lấy chúng làm bài học để hoàn thiện bản thân.', Overview.neutral),
  Message('Cuộc đời này rất công bằng. Nếu cuộc sống lấy đi của bạn một thứ gì thì cũng sẽ bù cho bạn lại một thứ khác. Quan trọng bạn có chịu khó đi tìm không thôi. Đừng lo lắng mình sẽ đi cùng bạn.', Overview.neutral),
  Message('Hãy tha thứ cho bản thân khi mọi chăm chỉ không mang lại kết quả hoàn mỹ, thường xuyên bước đi để đạt được những thứ bạn chưa làm được trong lần chăm chỉ thứ nhất.', Overview.neutral),
  Message('Một người không nhìn thấy trọng việc nhỏ thì trọn đời không bao giờ làm được việc lớn.', Overview.neutral),
  Message('Sự phát triển cần vốn, và thời gian cũng là một loại vốn, trân quý thời gian chính là cắt giảm vốn. Một trong những câu nói ý nghĩa về cuộc đời về làm kinh tế cho một mình và gia đình có liên quan sự thành công.', Overview.neutral),
  Message('Mỗi người sinh ra đều có một khả năng nào đó, bẩm sinh hay không để thành công ai cũng phải khổ luyện.', Overview.neutral),
  Message('Muốn làm thay đổi sự việc thì bản thân mình phải thay đổi trước đã.', Overview.neutral),
  Message('Người có trải nghiệm ít thì những việc nhỏ cũng trở nên phức tạp, người có kinh nghiệm nhiều thì những việc to cũng sẽ trở nên nhỏ bé.', Overview.neutral),
  Message('Mỗi vấn đề bất lợi lại là có lợi trong trường hợp khác, hãy thay đổi cách nghĩ để trở nên thành công.', Overview.neutral),

  // 3. NHÓM NEGATIVE (Cảm xúc trầm, sâu lắng, phản ánh tổn thương & bế tắc)
  Message('Đừng bỏ cuộc nhé. Giông bão sẽ sớm qua di và trời sẽ lại tươi xanh. Hãy là cái đầu lạnh với tinh thần thép và mọi chuyện rồi sẽ ổn.', Overview.negative),
  Message('Mạnh mẽ lên vì mọi thứ rồi sẽ tốt đẹp lên thôi, sau cơn mưa trời lại sáng mà.', Overview.negative),
  Message('Tôi không thể khiến những đau khổ của bạn tan biến, cũng không thể dự đoán những điều trong tương lai nhưng tôi biết bạn sẽ đủ niềm tin và nghị lực để vượt qua.', Overview.negative),
  Message('Đừng nghĩ mãi về quá khứ, nó chỉ mang tới những giọt nước mắt. Đừng nghĩ nhiều về tương lai, nó chỉ mang lại lo sợ. Sống ở hiện tại với nụ cười trên môi như trẻ thơ nó sẽ mang lại niềm vui cho bạn.', Overview.negative),
  Message('Cuộc sống không phải là một sự lãng phí miễn là có ít nhất một người trên thế giới này quan tâm đến bạn. Vì vậy, khi mọi thứ đi sai hướng bạn đừng từ bỏ hãy nhớ bạn luôn có tôi bên cạnh!', Overview.negative),
  Message('Vẫn biết rằng quá khứ ở đằng sau và phải sống cho những gì phía trước. Nhưng đôi khi đôi chân vẫn bước ngược để dẫn ta về với những nỗi đau.', Overview.negative),
  Message('Cho dù bạn mất mát đến đâu, bạn vẫn còn tương lai phía trước. Tôi tin bạn sẽ thành công, cuộc đời của mình bạn hãy tự quyết định.', Overview.negative),
  Message('Tôi không thể bảo vệ trái tim bạn khỏi đau thương và rỉ máu, nhưng tôi sẽ cùng bạn làm những điều thật ý nghĩa và tươi đẹp để làm lành vết thương ấy.', Overview.negative),
  Message('Suốt ngày cứ suy nghĩ vẩn vơ rồi tự mình buồn. Không ai hiểu mình cả, không một ai nhiều lúc buồn hay bế tắc cũng chả biết tâm sự với ai. Càng lớn càng suy nghĩ sâu xa, ước gì thời gian có thể quay trở lại không buồn nhiều không nhiều tâm sự như bây giờ. Dù thế nào cũng phải mạnh mẽ, chỉ được phép cố gắng không được phép gục ngã.', Overview.negative),
  Message('Khi chúng ta nghĩ về một vấn đề chúng sẽ lớn gấp đôi, nhưng khi chúng ta cười chúng, chúng sẽ trở thành bong bóng vỡ tan. Vì vậy đừng lo lắng và hãy bắt đầu bằng nụ cười.', Overview.negative),
  Message('Khó khăn là một phần của cuộc sống và nếu bạn không chia sẻ nó, bạn sẽ không mang lại cho người yêu mến bạn cơ may để yêu bạn nhiều hơn.', Overview.negative),
  Message('Khi ta cứ tập trung suy nghĩ về chuyện buồn thì nó như một con sâu đục khoét vào tâm trí ta làm ta suy sụp và ngã gục. Ta hãy nghĩ đến một tương lai tươi sáng đang chờ mình thì sẽ thấy thoải mái và mạnh mẽ hơn.', Overview.negative),

];
