import 'package:flutter/material.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/brand_colors.dart';
import '../../../shared/widgets/section_chip.dart';
import '../logic/suggestion.dart';
import 'ticket_card.dart';

/// Mục "Gợi ý hằng ngày": chip tiêu đề + danh sách thẻ vé (tối đa 4).
class SuggestionSection extends StatelessWidget {
  final List<Suggestion> suggestions;
  final ValueChanged<Suggestion> onTap;
  final ValueChanged<Suggestion> onDismiss;

  const SuggestionSection({
    super.key,
    required this.suggestions,
    required this.onTap,
    required this.onDismiss,
  });

  static const Color _iconColor = Color(0xFFA3AEC2);

  @override
  Widget build(BuildContext context) {
    if (suggestions.isEmpty) return const SizedBox.shrink();

    return Column(
      children: [
        const Align(
          alignment: Alignment.centerLeft,
          child: Padding(
            padding: EdgeInsets.only(left: 20),
            child: SectionChip('Gợi ý hằng ngày'),
          ),
        ),
        const SizedBox(height: 12),
        for (final s in suggestions)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: TicketCard(
              title: s.song != null ? 'Bài hát hôm nay' : s.title,
              subtitle: s.song != null ? '' : s.subtitle,
              isWarning: s.isWarning,
              right: _rightOf(s),
              onTap: () => onTap(s),
              onDismiss: () => onDismiss(s),
            ),
          ),
      ],
    );
  }

  Widget _rightOf(Suggestion s) {
    final song = s.song;
    if (song != null) return _SongCover(title: song.title, artist: song.artist, coverUrl: song.coverUrl);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(_iconOf(s.kind), size: 44, color: _iconColor),
        const SizedBox(height: 8),
        Text(
          s.cta,
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: AppTextStyles.ticketOnDark.copyWith(fontSize: 14),
        ),
      ],
    );
  }

  IconData _iconOf(SuggestionKind kind) => switch (kind) {
        SuggestionKind.screenTimeWarning => Icons.warning_amber_rounded,
        SuggestionKind.sleep => Icons.bedtime_rounded,
        SuggestionKind.meditation => Icons.self_improvement_rounded,
        SuggestionKind.happyMusic => Icons.music_note_rounded,
        SuggestionKind.sadMusic => Icons.music_note_rounded,
        SuggestionKind.run => Icons.directions_run_rounded,
        SuggestionKind.songOfTheDay => Icons.music_note_rounded,
      };
}

class _SongCover extends StatelessWidget {
  final String title;
  final String artist;
  final String coverUrl;

  const _SongCover({
    required this.title,
    required this.artist,
    required this.coverUrl,
  });

  @override
  Widget build(BuildContext context) {
    final placeholder = Container(
      width: 64,
      height: 64,
      color: const Color(0xFF2E3B52),
      child: const Icon(Icons.music_note_rounded, color: SuggestionSection._iconColor),
    );

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: coverUrl.startsWith('http')
              ? Image.network(
                  coverUrl,
                  width: 64,
                  height: 64,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => placeholder,
                )
              : placeholder, // chưa có link thật (đang là chỗ giữ chỗ)
        ),
        const SizedBox(height: 6),
        Text(
          title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppTextStyles.ticketOnDark.copyWith(fontSize: 13),
        ),
        Text(
          artist,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: BrandColors.textOnDark,
          ),
        ),
      ],
    );
  }
}
