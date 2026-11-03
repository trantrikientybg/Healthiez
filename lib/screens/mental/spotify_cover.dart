import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class SpotifyCoverService {
  // Nhớ kết quả để không gọi lại mỗi lần danh sách rebuild.
  static final Map<String, String?> _cache = {};

  /// Trả về link ảnh, hoặc null nếu không lấy được.
  static Future<String?> getCoverUrl(String spotifyUrl) async {
    if (_cache.containsKey(spotifyUrl)) return _cache[spotifyUrl];

    try {
      final uri = Uri.https(
        'open.spotify.com',
        '/oembed',
        {'url': spotifyUrl}, // tự được mã hóa URL
      );
      final res = await http.get(uri).timeout(const Duration(seconds: 8));

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        final cover = data['thumbnail_url'] as String?; // có thể null
        _cache[spotifyUrl] = cover;
        return cover;
      }
    } catch (_) {
    }
    return null;
  }
}
class SongCover extends StatefulWidget {
  final String spotifyUrl;
  final double size;
  final double radius; // bo góc
  final Color? placeholderColor; // màu nền khi đang tải hoặc lỗi
  const SongCover({
    super.key,
    required this.spotifyUrl,
    this.size = 64,
    this.radius = 12,
    this.placeholderColor,
  });

  @override
  State<SongCover> createState() => _SongCoverState();
}

class _SongCoverState extends State<SongCover> {
  late final Future<String?> _future;

  @override
  void initState() {
    super.initState();
    // Gán future một lần ở initState để không bị gọi lại mỗi lần build.
    _future = SpotifyCoverService.getCoverUrl(widget.spotifyUrl);
  }

  Widget _placeholder() => Container(
    color: widget.placeholderColor ?? Colors.grey.shade300,
    child: const Icon(Icons.music_note, color: Colors.grey),
  );

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(widget.radius),
      child: SizedBox(
        width: widget.size,
        height: widget.size,
        child: FutureBuilder<String?>(
          future: _future,
          builder: (context, snap) {
            final url = snap.data;
            if (url == null) return _placeholder();
            return Image.network(
              url,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => _placeholder(),
            );
          },
        ),
      ),
    );
  }
}