import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/desktop_theme.dart';
import '../../../core/providers/desktop_providers.dart';

class DesktopTopBar extends ConsumerWidget {
  const DesktopTopBar({super.key, this.title = ''});

  final String title;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final healthAsync = ref.watch(backendHealthProvider);

    return SizedBox(
      height: Dt.topBarHeight,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: Dt.contentPadH),
        decoration: Dt.topBar,
        child: Row(
          children: [
            // ── Page title ───────────────────────────────────────────────
            if (title.isNotEmpty)
              Text(title, style: Dt.pageTitle),

            const Spacer(),

            // ── Search ───────────────────────────────────────────────────
            _SearchBar(),
            const SizedBox(width: 12),

            // ── New Research shortcut ────────────────────────────────────
            _TopBarButton(
              icon: Icons.add_rounded,
              label: 'New Research',
              onTap: () => context.go('/desktop/new-research'),
            ),
            const SizedBox(width: 8),

            // ── Backend status ────────────────────────────────────────────
            healthAsync.when(
              data: (ok) => _BackendChip(connected: ok, onRefresh: () {
                ref.invalidate(backendHealthProvider);
              }),
              loading: () => const _BackendChip(connected: null),
              error: (_, __) => _BackendChip(connected: false, onRefresh: () {
                ref.invalidate(backendHealthProvider);
              }),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _SearchBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) => SizedBox(
        width: 220,
        height: 32,
        child: TextField(
          decoration: InputDecoration(
            hintText: 'Search reports, jobs…',
            hintStyle: const TextStyle(fontSize: 13, color: Dt.textMuted),
            prefixIcon: const Icon(Icons.search_rounded, size: 16, color: Dt.textMuted),
            contentPadding: const EdgeInsets.symmetric(vertical: 0),
            isDense: true,
            filled: true,
            fillColor: Dt.bgInput,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(Dt.inputRadius),
              borderSide: const BorderSide(color: Dt.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(Dt.inputRadius),
              borderSide: const BorderSide(color: Dt.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(Dt.inputRadius),
              borderSide: const BorderSide(color: Dt.borderFocus, width: 1.5),
            ),
          ),
          style: const TextStyle(fontSize: 13, color: Dt.textPrimary),
        ),
      );
}

// ─────────────────────────────────────────────────────────────────────────────

class _TopBarButton extends StatefulWidget {
  const _TopBarButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String   label;
  final VoidCallback onTap;

  @override
  State<_TopBarButton> createState() => _TopBarButtonState();
}

class _TopBarButtonState extends State<_TopBarButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) => MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _hovered = true),
        onExit:  (_) => setState(() => _hovered = false),
        child: GestureDetector(
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 120),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: _hovered ? Dt.primaryLight : Dt.bgInput,
              borderRadius: BorderRadius.circular(Dt.inputRadius),
              border: Border.all(color: _hovered ? Dt.primaryMid : Dt.border),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(widget.icon, size: 15,
                    color: _hovered ? Dt.primary : Dt.textSecondary),
                const SizedBox(width: 5),
                Text(
                  widget.label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: _hovered ? Dt.primary : Dt.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
}

// ─────────────────────────────────────────────────────────────────────────────

class _BackendChip extends StatelessWidget {
  const _BackendChip({this.connected, this.onRefresh});

  final bool? connected;      // null = loading
  final VoidCallback? onRefresh;

  @override
  Widget build(BuildContext context) {
    Color bg, fg;
    IconData icon;
    String  label;

    if (connected == null) {
      bg = Dt.bgMuted; fg = Dt.textMuted; icon = Icons.sync_rounded; label = 'Checking';
    } else if (connected!) {
      bg = Dt.successBg; fg = Dt.success; icon = Icons.circle; label = 'Connected';
    } else {
      bg = Dt.errorBg; fg = Dt.error; icon = Icons.circle; label = 'Offline';
    }

    return GestureDetector(
      onTap: onRefresh,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            connected == null
                ? SizedBox(
                    width: 8,
                    height: 8,
                    child: CircularProgressIndicator(
                      strokeWidth: 1.5,
                      color: fg,
                    ),
                  )
                : Icon(icon, size: 7, color: fg),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: fg),
            ),
          ],
        ),
      ),
    );
  }
}
