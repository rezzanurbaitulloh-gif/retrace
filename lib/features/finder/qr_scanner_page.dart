import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:retrace/core/theme/retrace_colors.dart';
import 'package:retrace/core/theme/retrace_spacing.dart';
import 'package:retrace/design_system/components/retrace_buttons.dart';
import 'package:retrace/features/finder/finder_repository.dart';

/// QR Scanner page — scans finder QR codes.
class QrScannerPage extends ConsumerStatefulWidget {
  const QrScannerPage({super.key});

  @override
  ConsumerState<QrScannerPage> createState() => _QrScannerPageState();
}

class _QrScannerPageState extends ConsumerState<QrScannerPage> {
  MobileScannerController? _controller;
  bool _processing = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _controller = MobileScannerController(
      detectionSpeed: DetectionSpeed.normal,
      facing: CameraFacing.back,
      torchEnabled: false,
    );
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _onDetect(BarcodeCapture capture) async {
    if (_processing) return;
    final String? code = capture.barcodes.firstOrNull?.rawValue;
    if (code == null) return;

    setState(() => _processing = true);
    try {
      // Extract recovery ID from QR data
      final String recoveryId = _extractRecoveryId(code);
      if (recoveryId.isEmpty) {
        setState(() => _error = 'Invalid QR code format.');
        return;
      }

      // Start finder session
      final session = await ref.read(finderControllerProvider).startSession(
        recoveryId,
        'unknown', // device ID will be resolved on backend
      );

      if (mounted) {
        context.go('/finder/$recoveryId', extra: session);
      }
    } on Object catch (e) {
      if (mounted) setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _processing = false);
    }
  }

  String _extractRecoveryId(String qrData) {
    // QR data format: https://retrace.app/recover/RT-XXXXXX
    final Uri? uri = Uri.tryParse(qrData);
    if (uri == null) return '';
    final List<String> segments = uri.pathSegments;
    if (segments.length >= 2 && segments[0] == 'recover') {
      return segments[1];
    }
    return '';
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan QR Code'),
        actions: [
          IconButton(
            tooltip: 'Toggle Flash',
            onPressed: () => _controller?.toggleTorch(),
            icon: const Icon(Icons.flash_on),
          ),
        ],
      ),
      body: Stack(
        children: [
          MobileScanner(
            controller: _controller!,
            onDetect: _onDetect,
            errorBuilder: (BuildContext context, MobileScannerException error) {
              return Center(
                child: Text('Camera error: ${error.errorDetails?.message ?? error.errorCode.name}'),
              );
            },
          ),
          if (_error != null)
            Positioned(
              bottom: 100,
              left: RetraceSpacing.md,
              right: RetraceSpacing.md,
              child: Card(
                color: RetraceColors.danger.withValues(alpha: 0.9),
                child: Padding(
                  padding: const EdgeInsets.all(RetraceSpacing.md),
                  child: Text(
                    _error!,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium?.copyWith(color: Colors.white),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}