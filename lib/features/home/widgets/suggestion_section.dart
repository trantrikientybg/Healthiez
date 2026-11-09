import 'package:flutter/material.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/brand_colors.dart';
import '../../../core/theme/day_period.dart';
import '../../../shared/widgets/section_chip.dart';
import '../logic/suggestion.dart';
import 'ticket_card.dart';

/// Mục "Gợi ý hằng ngày": chip tiêu đề + các thẻ vé (tối đa 4).
/// Thẻ nhạc luôn ở cuối, ngay dưới là ô nhỏ "Xem thêm nhạc".
class SuggestionSection extends StatelessWidget {
  final List<Suggestion> suggestions;
  final ValueChanged<Suggestion> onTap;
  final ValueChanged<Suggestion> onDismiss;
  final VoidCallback? onMoreMusic;

  const SuggestionSection({
    super.key,
    required this.suggestions,
    required this.onTap,
    required this.onDismiss,
    this.onMoreMusic,
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
        for (final s in suggestions) ...[
          Padding(
            padding: EdgeInsets.fromLTRB(16, 0, 16, s.isMusic ? 8 : 12),
            child: TicketCard(
              title: s.title,
              subtitle: s.subtitle,
              isWarning: s.isWarning,
              right: _rightOf(s),
              onTap: () => onTap(s),
              // Thẻ nhạc luôn hiện, không có nút ẩn
              onDismiss: s.isMusic ? null : () => onDismiss(s),
            ),
          ),
          if (s.isMusic)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: _MoreMusicTile(onTap: onMoreMusic),
            ),
        ],
      ],
    );
  }

  Widget _rightOf(Suggestion s) {
    final playlist = s.playlist;
    if (playlist != null) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _PlaylistCover(imageUrl: playlist.imageUrl),
          const SizedBox(height: 8),
          Text(
            s.cta,
            style: AppTextStyles.ticketOnDark.copyWith(fontSize: 14),
          ),
        ],
      );
    }

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
        SuggestionKind.run => Icons.directions_run_rounded,
        SuggestionKind.music => Icons.music_note_rounded,
      };
}

/// Ảnh bìa playlist. Chưa có link ảnh thật (hoặc tải lỗi) thì hiện hình nốt nhạc.
class _PlaylistCover extends StatelessWidget {
  final String imageUrl;
  const _PlaylistCover({required this.imageUrl});

  static const double size = 72;

  @override
  Widget build(BuildContext context) {
    final placeholder = Container(
      width: size,
      height: size,
      color: const Color(0xFF2E3B52),
      child: const Icon(
        Icons.library_music_rounded,
        size: 32,
        color: SuggestionSection._iconColor,
      ),
    );

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: imageUrl.startsWith('http')
          ? Image.network(
              imageUrl,
              width: size,
              height: size,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => placeholder,
            )
          : placeholder,
    );
  }
}

/// Ô nhỏ dưới thẻ nhạc: bấm để sang phần nhạc đầy đủ ở tab Tinh thần.
class _MoreMusicTile extends StatelessWidget {
  final VoidCallback? onTap;
  const _MoreMusicTile({this.onTap});

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Material(
      color: palette.card,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              const Icon(
                Icons.library_music_rounded,
                size: 22,
                color: BrandColors.purple,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Xem thêm nhạc cho tâm trạng của bạn',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: palette.textPrimary,
                  ),
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: palette.textPrimary),
            ],
          ),
        ),
      ),
    );
  }
}
