import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:retrace/core/theme/retrace_spacing.dart';
import 'package:retrace/design_system/components/retrace_buttons.dart';
import 'package:retrace/design_system/components/retrace_overlays.dart';
import 'package:retrace/design_system/components/retrace_states.dart';
import 'package:retrace/features/evidence/evidence.dart';
import 'package:retrace/features/evidence/evidence_repository.dart';
import 'package:retrace/features/notifications/notifications_controller.dart';
import 'package:retrace/services/permission_service.dart';

/// Owner evidence page (§33-34): photo capture (camera/gallery) with
/// permission gating, §34 limit messaging, and offline-queue honesty.
/// Route: /devices/:id/evidence.
class EvidencePage extends ConsumerStatefulWidget {
  const EvidencePage({super.key, required this.deviceId, this.recoveryId});

  final String deviceId;
  final String? recoveryId;

  @override
  ConsumerState<EvidencePage> createState() => _EvidencePageState();
}

class _EvidencePageState extends ConsumerState<EvidencePage> {
  List<EvidenceItem> _items = <EvidenceItem>[];
  bool _loading = true;
  bool _capturing = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final List<EvidenceItem> items = await ref
          .read(evidenceControllerProvider)
          .listByDevice(widget.deviceId);
      if (mounted) {
        setState(() {
          _items = items;
          _loading = false;
        });
      }
    } on Object catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString().replaceFirst('Exception: ', '');
          _loading = false;
        });
      }
    }
  }

  Future<void> _pickSource() async {
    final ImageSource? source = await showRetraceSheet<ImageSource>(
      context,
      semanticLabel: 'Choose photo source',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Text('Add photo evidence',
              style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: RetraceSpacing.sm),
          Text(
            'Photos up to $kMaxEvidenceLabel (JPG, PNG, HEIC). '
            'Saved on-device first, uploaded when possible.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: RetraceSpacing.md),
          RetraceButton(
            label: 'Take photo',
            icon: Icons.camera_alt_outlined,
            onPressed: () => Navigator.of(context).pop(ImageSource.camera),
          ),
          const SizedBox(height: RetraceSpacing.sm),
          RetraceButton(
            label: 'Choose from gallery',
            icon: Icons.photo_library_outlined,
            isSecondary: true,
            onPressed: () => Navigator.of(context).pop(ImageSource.gallery),
          ),
          const SizedBox(height: RetraceSpacing.sm),
        ],
      ),
    );
    if (source != null && mounted) {
      await _capture(source);
    }
  }

  Future<void> _capture(ImageSource source) async {
    if (_capturing) return;
    setState(() => _capturing = true);
    try {
      // Permission gate — camera source needs camera grant; gallery does not.
      if (source == ImageSource.camera) {
        final PermissionState state = await ref
            .read(permissionServiceProvider)
            .check(AppPermission.camera);
        if (!state.isGranted && mounted) {
          setState(() => _capturing = false);
          await _showPermissionSheet();
          return;
        }
      }
      final EvidenceItem item =
          await ref.read(evidenceControllerProvider).capturePhoto(
                deviceId: widget.deviceId,
                source: source,
                recoveryId: widget.recoveryId,
              );
      if (!mounted) return;
      setState(() => _capturing = false);
      await _load();
      if (!mounted) return;
      unawaited(
        ref.read(notificationControllerProvider).evidenceStored(
              deviceId: widget.deviceId,
              fileName: item.fileName,
              uploaded: item.uploaded,
            ),
      );
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            item.uploaded
                ? 'Photo uploaded.'
                : 'Saved on-device — upload retries when online.',
          ),
        ),
      );
    } on EvidenceCancelled {
      if (mounted) setState(() => _capturing = false);
    } on EvidenceRejected catch (e) {
      if (!mounted) return;
      setState(() => _capturing = false);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.message)));
    } on Object catch (e) {
      if (!mounted) return;
      setState(() => _capturing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Could not save photo: ${e.toString().replaceFirst('Exception: ', '')}',
          ),
        ),
      );
    }
  }

  Future<void> _showPermissionSheet() async {
    await showRetraceSheet<void>(
      context,
      semanticLabel: 'Camera permission needed',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Text('Camera access needed',
              style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: RetraceSpacing.sm),
          Text(
            'Evidence photos need camera access. RETRACE never enables it '
            'itself — grant it in Settings, then try again.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: RetraceSpacing.md),
          RetraceButton(
            label: 'Open Settings',
            icon: Icons.settings_outlined,
            onPressed: () async {
              final ScaffoldMessengerState messenger =
                  ScaffoldMessenger.of(context);
              Navigator.of(context).pop();
              try {
                await ref.read(permissionServiceProvider).openSettings();
              } on PermissionSettingsUnavailable catch (e) {
                messenger.showSnackBar(SnackBar(content: Text(e.message)));
              }
            },
          ),
          const SizedBox(height: RetraceSpacing.sm),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Evidence')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: (_loading || _capturing) ? null : _pickSource,
        icon: _capturing
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.add_a_photo_outlined),
        label: Text(_capturing ? 'Saving…' : 'Add photo'),
      ),
      body: _loading
          ? const LoadingState(message: 'Loading evidence…')
          : _error != null
              ? ErrorState(message: _error!, onRetry: _load)
              : _items.isEmpty
                  ? EmptyState(
                      icon: Icons.photo_library_outlined,
                      title: 'No evidence yet',
                      message:
                          'Add a photo of the area, a sighting, or anything '
                          'that helps recovery. Items stay on-device until upload succeeds.',
                      actionLabel: 'Add photo',
                      onAction: _pickSource,
                    )
                  : ListView(
                      padding: const EdgeInsets.all(RetraceSpacing.md),
                      children: <Widget>[
                        ..._items.map(_tile),
                        const SizedBox(height: RetraceSpacing.sm),
                        Text(
                          'Limit $kMaxEvidenceLabel per photo (JPG, PNG, HEIC). '
                          'Documents arrive in a later update.',
                          style: theme.textTheme.bodySmall,
                        ),
                      ],
                    ),
    );
  }

  Widget _tile(EvidenceItem item) {
    final ThemeData theme = Theme.of(context);
    final bool uploaded = item.uploaded;
    final Color chipColor =
        uploaded ? theme.colorScheme.primary : theme.colorScheme.tertiary;
    return Card(
      margin: const EdgeInsets.only(bottom: RetraceSpacing.sm),
      child: ListTile(
        leading: const Icon(Icons.image_outlined),
        title: Text(
          item.fileName,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          '${_formatSize(item.sizeBytes)} · ${_formatDate(item.metadata.capturedAt)}'
          '${item.metadata.hasLocation ? ' · located' : ''}',
          style: theme.textTheme.bodySmall,
        ),
        trailing: Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: chipColor.withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(RetraceRadius.pill),
          ),
          child: Text(
            uploaded ? 'Uploaded' : 'Queued',
            style: theme.textTheme.labelMedium?.copyWith(color: chipColor),
          ),
        ),
      ),
    );
  }

  static String _formatSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  static String _formatDate(DateTime dt) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${dt.year}-${two(dt.month)}-${two(dt.day)} ${two(dt.hour)}:${two(dt.minute)}';
  }
}
