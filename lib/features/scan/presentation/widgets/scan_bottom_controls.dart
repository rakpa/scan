import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../scan_design_tokens.dart';

class ScanCaptureButton extends StatefulWidget {
  const ScanCaptureButton({
    super.key,
    required this.onPressed,
    this.loading = false,
  });

  final VoidCallback onPressed;
  final bool loading;

  @override
  State<ScanCaptureButton> createState() => _ScanCaptureButtonState();
}

class _ScanCaptureButtonState extends State<ScanCaptureButton> {
  var _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      onTap: widget.loading
          ? null
          : () {
              HapticFeedback.mediumImpact();
              widget.onPressed();
            },
      child: AnimatedScale(
        scale: _pressed ? 0.92 : 1,
        duration: const Duration(milliseconds: 100),
        child: Container(
          width: 76,
          height: 76,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: ScanDesign.primary, width: 4),
            boxShadow: [
              BoxShadow(
                color: ScanDesign.primary.withValues(alpha: 0.35),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Center(
            child: widget.loading
                ? const SizedBox(
                    width: 28,
                    height: 28,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: Colors.white,
                    ),
                  )
                : Container(
                    width: 58,
                    height: 58,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}

class ScanBottomControls extends StatelessWidget {
  const ScanBottomControls({
    super.key,
    required this.pageCount,
    required this.onGallery,
    required this.onCapture,
    required this.onDone,
    this.capturing = false,
  });

  final int pageCount;
  final VoidCallback onGallery;
  final VoidCallback onCapture;
  final VoidCallback onDone;
  final bool capturing;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Align document inside the frame',
              style: TextStyle(
                color: ScanDesign.onDarkMuted,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _SideButton(
                  icon: Icons.photo_library_outlined,
                  label: 'Gallery',
                  onTap: onGallery,
                ),
                ScanCaptureButton(
                  onPressed: onCapture,
                  loading: capturing,
                ),
                _SideButton(
                  icon: Icons.check_rounded,
                  label: pageCount > 0 ? 'Done' : 'Pages',
                  badge: pageCount > 0 ? '$pageCount' : null,
                  onTap: pageCount > 0 ? onDone : () {},
                  enabled: pageCount > 0,
                ),
              ],
            ),
            if (pageCount > 0) ...[
              const SizedBox(height: 12),
              Text(
                pageCount == 1 ? '1 Page' : '$pageCount Pages',
                style: const TextStyle(
                  color: ScanDesign.onDark,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ],
        ),
      ),
    ).animate().fadeIn(delay: 200.ms, duration: 350.ms).slideY(begin: 0.15, end: 0);
  }
}

class _SideButton extends StatelessWidget {
  const _SideButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.badge,
    this.enabled = true,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final String? badge;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: enabled ? 1 : 0.45,
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(12),
        child: SizedBox(
          width: 72,
          child: Column(
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(icon, color: ScanDesign.onDark, size: 24),
                  ),
                  if (badge != null)
                    Positioned(
                      right: -4,
                      top: -4,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: ScanDesign.primary,
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          badge!,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                label,
                style: const TextStyle(
                  color: ScanDesign.onDark,
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
