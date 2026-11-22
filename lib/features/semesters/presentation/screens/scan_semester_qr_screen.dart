import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:attendly/core/shared/widgets/app_button.dart';
import 'package:attendly/core/shared/widgets/app_text_field.dart';
import 'package:attendly/core/shared/widgets/app_toast.dart';
import 'package:attendly/core/theme/app_colors.dart';
import 'package:attendly/core/theme/app_icons.dart';
import 'package:attendly/core/theme/app_radius.dart';
import 'package:attendly/core/theme/app_typography.dart';
import 'package:attendly/features/semesters/domain/entities/semester_qr_payload.dart';
import 'package:attendly/features/semesters/presentation/widgets/semester_import_preview_sheet.dart';

class ScanSemesterQrScreen extends ConsumerStatefulWidget {
  const ScanSemesterQrScreen({
    super.key,
    this.controller,
    this.disableCameraForTesting = false,
  });

  final MobileScannerController? controller;
  final bool disableCameraForTesting;

  @override
  ConsumerState<ScanSemesterQrScreen> createState() =>
      _ScanSemesterQrScreenState();
}

class _ScanSemesterQrScreenState extends ConsumerState<ScanSemesterQrScreen> {
  late final MobileScannerController _scannerController;
  bool _isProcessing = false;
  bool _isTorchOn = false;

  @override
  void initState() {
    super.initState();
    _scannerController =
        widget.controller ??
        MobileScannerController(
          detectionSpeed: DetectionSpeed.noDuplicates,
          facing: CameraFacing.back,
        );
  }

  @override
  void dispose() {
    if (widget.controller == null) {
      _scannerController.dispose();
    }
    super.dispose();
  }

  Future<void> _handleBarcode(String? raw) async {
    if (raw == null || raw.trim().isEmpty || _isProcessing) return;

    setState(() => _isProcessing = true);

    final error = SemesterQrPayload.validateRaw(raw);
    if (error != null) {
      if (mounted) {
        AppToast.showError(context, message: error);
      }
      await Future<void>.delayed(const Duration(milliseconds: 1600));
      if (mounted) {
        setState(() => _isProcessing = false);
      }
      return;
    }

    final payload = SemesterQrPayload.tryParse(raw);
    if (payload == null) {
      if (mounted) {
        setState(() => _isProcessing = false);
        AppToast.showError(
          context,
          message: 'Could not read semester QR code.',
        );
      }
      return;
    }

    if (!mounted) return;
    final imported = await showSemesterImportPreviewSheet(
      context: context,
      payload: payload,
    );

    if (imported == true && mounted) {
      Navigator.of(context).pop(true);
    } else {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  Future<void> _openManualPasteDialog() async {
    final pastedPayload = await showDialog<String>(
      context: context,
      builder: (ctx) => const _ManualPasteDialog(),
    );

    if (pastedPayload != null && pastedPayload.isNotEmpty && mounted) {
      await _handleBarcode(pastedPayload);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Live Camera Feed
          if (!widget.disableCameraForTesting)
            MobileScanner(
              controller: _scannerController,
              onDetect: (capture) {
                if (_isProcessing) return;
                for (final barcode in capture.barcodes) {
                  if (barcode.rawValue != null) {
                    _handleBarcode(barcode.rawValue);
                    break;
                  }
                }
              },
              errorBuilder: (context, error) {
                return _CameraErrorView(
                  onPasteManually: _openManualPasteDialog,
                );
              },
            )
          else
            _CameraDisabledPlaceholder(onPasteManually: _openManualPasteDialog),

          // Reticle Overlay
          SafeArea(
            child: Column(
              children: [
                // Top Action Bar
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: Row(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.5),
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          icon: const AppIcon(
                            AppIcons.close,
                            size: 20,
                            color: Colors.white,
                          ),
                          onPressed: () => Navigator.of(context).pop(false),
                          tooltip: 'Close scanner',
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          'Scan Semester QR',
                          style: TextStyle(
                            fontFamily: 'PlusJakartaSans',
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      if (!widget.disableCameraForTesting)
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.5),
                            shape: BoxShape.circle,
                          ),
                          child: IconButton(
                            icon: AppIcon(
                              _isTorchOn ? AppIcons.flashOff : AppIcons.flash,
                              size: 20,
                              color: Colors.white,
                            ),
                            onPressed: () async {
                              await _scannerController.toggleTorch();
                              setState(() => _isTorchOn = !_isTorchOn);
                            },
                            tooltip: 'Toggle Flashlight',
                          ),
                        ),
                    ],
                  ),
                ),

                const Spacer(),

                // Center Reticle Viewport
                Center(
                  child: Container(
                    width: 250,
                    height: 250,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: _isProcessing
                            ? colors.accentGreen
                            : colors.brandPrimary,
                        width: 2.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color:
                              (_isProcessing
                                      ? colors.accentGreen
                                      : colors.brandPrimary)
                                  .withValues(alpha: 0.2),
                          blurRadius: 20,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: _isProcessing
                        ? Center(
                            child: CircularProgressIndicator(
                              color: colors.brandPrimary,
                            ),
                          )
                        : null,
                  ),
                ),

                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.6),
                    borderRadius: AppRadius.pillBorder,
                  ),
                  child: const Text(
                    'Point camera at an Attendly Semester QR code',
                    style: TextStyle(
                      fontFamily: 'PlusJakartaSans',
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),

                const Spacer(),

                // Bottom Manual Paste Button
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 28),
                  child: AppButton(
                    label: 'Paste Code Manually',
                    icon: AppIcon(
                      AppIcons.importFile,
                      size: 16,
                      color: colors.textPrimary,
                    ),
                    variant: AppButtonVariant.secondary,
                    isFullWidth: true,
                    size: AppButtonSize.medium,
                    onPressed: _openManualPasteDialog,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CameraErrorView extends StatelessWidget {
  const _CameraErrorView({required this.onPasteManually});

  final VoidCallback onPasteManually;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: colors.accentRed.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: AppIcon(
                AppIcons.alert,
                size: 28,
                color: colors.accentRed,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Camera Unavailable',
              style: TextStyle(
                fontFamily: 'PlusJakartaSans',
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Please grant camera permission in system settings, or paste the semester code manually.',
              style: TextStyle(
                fontFamily: 'PlusJakartaSans',
                fontSize: 14,
                color: colors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            AppButton(
              label: 'Paste Code Manually',
              variant: AppButtonVariant.primary,
              onPressed: onPasteManually,
            ),
          ],
        ),
      ),
    );
  }
}

class _CameraDisabledPlaceholder extends StatelessWidget {
  const _CameraDisabledPlaceholder({required this.onPasteManually});

  final VoidCallback onPasteManually;

  @override
  Widget build(BuildContext context) {
    return const SizedBox.expand();
  }
}

class _ManualPasteDialog extends StatefulWidget {
  const _ManualPasteDialog();

  @override
  State<_ManualPasteDialog> createState() => _ManualPasteDialogState();
}

class _ManualPasteDialogState extends State<_ManualPasteDialog> {
  late final TextEditingController _textController;

  @override
  void initState() {
    super.initState();
    _textController = TextEditingController();
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: context.colors.surface,
      shape: const RoundedRectangleBorder(borderRadius: AppRadius.lgBorder),
      title: const Text('Paste Semester Code', style: AppTypography.itemTitle),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Paste the raw JSON or QR payload copied from a classmate\'s Attendly app.',
            style: AppTypography.bodySmall,
          ),
          const SizedBox(height: 14),
          AppTextField(
            controller: _textController,
            label: 'QR Code Data',
            hint: '{"app":"attendly",...}',
            maxLines: 4,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        AppButton(
          label: 'Review',
          size: AppButtonSize.small,
          onPressed: () {
            final raw = _textController.text.trim();
            Navigator.of(context).pop(raw);
          },
        ),
      ],
    );
  }
}

Future<bool?> openScanSemesterQrScreen(BuildContext context) {
  return Navigator.of(context).push<bool>(
    MaterialPageRoute(
      fullscreenDialog: true,
      builder: (context) => const ScanSemesterQrScreen(),
    ),
  );
}
