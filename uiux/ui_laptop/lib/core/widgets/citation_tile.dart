import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../theme/app_theme.dart';

class CitationTile extends StatelessWidget {
  const CitationTile({
    super.key,
    required this.index,
    required this.title,
    required this.url,
  });

  final int index;
  final String title;
  final String url;

  String get _domain {
    try {
      return Uri.parse(url).host.replaceFirst('www.', '');
    } catch (_) {
      return url;
    }
  }

  Future<void> _launch() async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border, width: 1),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _launch,
          borderRadius: BorderRadius.circular(12),
          splashColor: AppColors.accentDim,
          highlightColor: Colors.transparent,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                      color: AppColors.border,
                      borderRadius: BorderRadius.circular(6)),
                  child: Center(
                    child: Text('$index',
                        style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.secondaryText,
                            fontFamily: 'GeneralSans')),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title,
                          style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: AppColors.primaryText,
                              height: 1.3,
                              fontFamily: 'GeneralSans'),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 3),
                      Text(_domain,
                          style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.mutedText,
                              fontFamily: 'GeneralSans')),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(Icons.open_in_new_rounded,
                    size: 14, color: AppColors.mutedText),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class InlineCitationBadge extends StatelessWidget {
  const InlineCitationBadge({super.key, required this.number});
  final int number;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
      decoration: BoxDecoration(
          color: AppColors.border, borderRadius: BorderRadius.circular(4)),
      child: Text('[$number]',
          style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: AppColors.secondaryText,
              fontFamily: 'GeneralSans')),
    );
  }
}
