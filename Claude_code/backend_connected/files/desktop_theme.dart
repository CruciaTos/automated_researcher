import 'package:flutter/material.dart';

/// Design tokens for the desktop layout.
/// All mobile styles remain in [AppTheme]. This file only adds
/// desktop-specific constants so the two systems stay independent.
abstract class Dt {
  Dt._();

  // ─── Layout ────────────────────────────────────────────────────────────────
  static const double sidebarWidth      = 224.0;
  static const double topBarHeight      = 52.0;
  static const double rightPanelWidth   = 300.0;
  static const double contentPadH       = 32.0;
  static const double contentPadV       = 28.0;
  static const double cardRadius        = 10.0;
  static const double inputRadius       = 8.0;
  static const double navItemRadius     = 7.0;
  static const double dividerThickness  = 1.0;

  // ─── Palette ───────────────────────────────────────────────────────────────
  static const Color primary        = Color(0xFF4F46E5); // brand indigo
  static const Color primaryLight   = Color(0xFFEEF2FF); // indigo-50
  static const Color primaryMid     = Color(0xFFC7D2FE); // indigo-200

  static const Color bgPage         = Color(0xFFF8FAFC); // slate-50
  static const Color bgSidebar      = Color(0xFFFFFFFF);
  static const Color bgCard         = Color(0xFFFFFFFF);
  static const Color bgInput        = Color(0xFFF1F5F9); // slate-100
  static const Color bgMuted        = Color(0xFFF1F5F9);
  static const Color bgDark         = Color(0xFF0F172A); // log area

  static const Color border         = Color(0xFFE2E8F0); // slate-200
  static const Color borderFocus    = Color(0xFF818CF8); // indigo-400

  static const Color textPrimary    = Color(0xFF0F172A); // slate-900
  static const Color textSecondary  = Color(0xFF475569); // slate-600
  static const Color textMuted      = Color(0xFF94A3B8); // slate-400
  static const Color textOnDark     = Color(0xFFCDD6F4);

  static const Color success        = Color(0xFF16A34A);
  static const Color successBg      = Color(0xFFF0FDF4);
  static const Color warning        = Color(0xFFD97706);
  static const Color warningBg      = Color(0xFFFFFBEB);
  static const Color error          = Color(0xFFDC2626);
  static const Color errorBg        = Color(0xFFFEF2F2);
  static const Color info           = Color(0xFF0284C7);
  static const Color infoBg         = Color(0xFFF0F9FF);

  // ─── Typography ────────────────────────────────────────────────────────────
  static const TextStyle pageTitle = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w700,
    color: textPrimary,
    letterSpacing: -0.4,
    height: 1.2,
  );

  static const TextStyle sectionLabel = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w600,
    color: textMuted,
    letterSpacing: 1.0,
  );

  static const TextStyle cardTitle = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: textPrimary,
    height: 1.3,
  );

  static const TextStyle bodyMd = TextStyle(
    fontSize: 13,
    color: textSecondary,
    height: 1.55,
  );

  static const TextStyle bodySm = TextStyle(
    fontSize: 12,
    color: textMuted,
    height: 1.4,
  );

  static const TextStyle mono = TextStyle(
    fontSize: 12,
    fontFamily: 'monospace',
    color: textOnDark,
    height: 1.6,
  );

  static const TextStyle statValue = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.w700,
    color: textPrimary,
    letterSpacing: -0.8,
    height: 1.1,
  );

  static const TextStyle navItem = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.1,
  );

  // ─── Decorations ───────────────────────────────────────────────────────────
  static BoxDecoration get card => BoxDecoration(
        color: bgCard,
        borderRadius: BorderRadius.circular(cardRadius),
        border: Border.all(color: border),
        boxShadow: const [
          BoxShadow(
            color: Color(0x08000000),
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      );

  static BoxDecoration get cardElevated => BoxDecoration(
        color: bgCard,
        borderRadius: BorderRadius.circular(cardRadius),
        border: Border.all(color: border),
        boxShadow: const [
          BoxShadow(
            color: Color(0x12000000),
            blurRadius: 16,
            offset: Offset(0, 4),
          ),
          BoxShadow(
            color: Color(0x06000000),
            blurRadius: 4,
            offset: Offset(0, 1),
          ),
        ],
      );

  static BoxDecoration get sidebar => const BoxDecoration(
        color: bgSidebar,
        border: Border(right: BorderSide(color: border)),
      );

  static BoxDecoration get topBar => const BoxDecoration(
        color: bgSidebar,
        border: Border(bottom: BorderSide(color: border)),
      );

  static BoxDecoration get logArea => BoxDecoration(
        color: bgDark,
        borderRadius: BorderRadius.circular(cardRadius),
      );

  /// Active nav item pill decoration.
  static BoxDecoration get navActive => BoxDecoration(
        color: primaryLight,
        borderRadius: BorderRadius.circular(navItemRadius),
      );

  // ─── Helpers ───────────────────────────────────────────────────────────────

  /// Returns the badge color pair (background, foreground) for a job status.
  static ({Color bg, Color fg}) statusColors(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return (bg: successBg, fg: success);
      case 'queued':
        return (bg: bgMuted, fg: textSecondary);
      case 'retrieving_sources':
      case 'fetching_documents':
      case 'chunking_documents':
      case 'embedding_documents':
      case 'drafting_outline':
      case 'writing_report':
        return (bg: infoBg, fg: info);
      case 'failed':
        return (bg: errorBg, fg: error);
      default:
        return (bg: warningBg, fg: warning);
    }
  }

  /// Human-readable status label.
  static String statusLabel(String status) {
    switch (status.toLowerCase()) {
      case 'queued':              return 'Queued';
      case 'retrieving_sources':  return 'Finding Sources';
      case 'fetching_documents':  return 'Fetching Docs';
      case 'chunking_documents':  return 'Processing';
      case 'embedding_documents': return 'Embedding';
      case 'drafting_outline':    return 'Outlining';
      case 'writing_report':      return 'Writing';
      case 'completed':           return 'Completed';
      case 'failed':              return 'Failed';
      default:                    return status;
    }
  }
}
