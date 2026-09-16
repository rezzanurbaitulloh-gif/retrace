import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:retrace/core/db/app_db.dart';
import 'package:retrace/core/theme/retrace_spacing.dart';
import 'package:retrace/design_system/components/retrace_buttons.dart';
import 'package:retrace/features/devices/devices_repository.dart';
import 'package:retrace/services/device_info_service.dart';

final deviceInfoServiceProvider =
    Provider<DeviceInfoService>((Ref ref) => RealDeviceInfoService());

/// Device registration (§12): minimal profile, progressive disclosure,
/// never fake IMEI. Auto-fills brand/model/OS from platform; shows
/// "Unavailable" when OS does not expose it.
class DeviceRegistrationPage extends ConsumerStatefulWidget {
  const DeviceRegistrationPage({super.key});

  @override
  ConsumerState<DeviceRegistrationPage> createState() =>
      _DeviceRegistrationPageState();
}

class _DeviceRegistrationPageState
    extends ConsumerState<DeviceRegistrationPage> {
  final GlobalKey<FormState> _form = GlobalKey<FormState>();
  final TextEditingController _name = TextEditingController();
  final TextEditingController _imei = TextEditingController();
  final TextEditingController _phone = TextEditingController();
  String _type = 'Phone';
  DeviceIdentity? _identity;
  bool _loadingIdentity = true;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadIdentity();
  }

  Future<void> _loadIdentity() async {
    try {
      final DeviceIdentity id =
          await ref.read(deviceInfoServiceProvider).getIdentity();
      if (mounted) {
        setState(() {
          _identity = id;
          _loadingIdentity = false;
        });
      }
    } on Object catch (_) {
      if (mounted) {
        setState(() => _loadingIdentity = false);
      }
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _imei.dispose();
    _phone.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_form.currentState?.validate() ?? false)) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final AppDb db = ref.read(appDbProvider);
      final String id = DateTime.now().millisecondsSinceEpoch.toString();
      final DeviceIdentity? ident = _identity;
      await db.upsertDevice(
        LocalDevice(
          id: id,
          name: _name.text.trim(),
          deviceType: _type,
          brand: ident?.brand ?? 'Unknown',
          model: ident?.model ?? 'Unknown',
          osName: ident?.osName ?? 'Unknown',
          osVersion: ident?.osVersion ?? 'Unknown',
          ownerId: null,
          createdAt: DateTime.now(),
        ),
      );
      // Offline-first: local is source of truth until Phase 4 sync pushes to Supabase.
      // No fake IMEI/phone stored beyond what user typed; empty → not stored.
      if (mounted) context.pop();
    } on Object catch (e) {
      if (mounted) {
        setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Add Device')),
      body: Form(
        key: _form,
        child: ListView(
          padding: const EdgeInsets.all(RetraceSpacing.md),
          children: [
            Text('Device profile (minimal)', style: theme.textTheme.titleMedium),
            const SizedBox(height: RetraceSpacing.sm),
            TextFormField(
              controller: _name,
              decoration: const InputDecoration(
                labelText: 'Device name',
                hintText: "Rezza's Phone",
              ),
              enabled: !_saving,
              validator: (String? v) =>
                  (v == null || v.trim().isEmpty) ? 'Device name is required.' : null,
            ),
            const SizedBox(height: RetraceSpacing.sm),
            DropdownButtonFormField<String>(
              initialValue: _type,
              decoration: const InputDecoration(labelText: 'Device type'),
              items: const [
                DropdownMenuItem(value: 'Phone', child: Text('Phone')),
                DropdownMenuItem(value: 'Tablet', child: Text('Tablet')),
                DropdownMenuItem(value: 'Other', child: Text('Other')),
              ],
              onChanged: _saving ? null : (String? v) => setState(() => _type = v ?? 'Phone'),
            ),
            const SizedBox(height: RetraceSpacing.md),
            Text('Auto-detected (read-only)', style: theme.textTheme.titleMedium),
            if (_loadingIdentity)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: RetraceSpacing.md),
                child: LinearProgressIndicator(),
              )
            else
              Column(
                children: [
                  _ReadOnlyRow(label: 'Brand', value: _identity?.brand ?? 'Unavailable'),
                  _ReadOnlyRow(label: 'Model', value: _identity?.model ?? 'Unavailable'),
                  _ReadOnlyRow(label: 'OS', value: _identity?.osName ?? 'Unavailable'),
                  _ReadOnlyRow(label: 'OS version', value: _identity?.osVersion ?? 'Unavailable'),
                  _ReadOnlyRow(label: 'Manufacturer', value: _identity?.manufacturer ?? 'Unavailable'),
                  _ReadOnlyRow(
                    label: 'Android ID',
                    value: _identity?.androidId ?? 'Unavailable',
                  ),
                ],
              ),
            const SizedBox(height: RetraceSpacing.md),
            Text('Optional (user-provided only)', style: theme.textTheme.titleMedium),
            const SizedBox(height: RetraceSpacing.sm),
            TextFormField(
              controller: _imei,
              decoration: const InputDecoration(
                labelText: 'IMEI (if you want to store it)',
                hintText: 'Leave empty if not needed',
              ),
              enabled: !_saving,
            ),
            const SizedBox(height: RetraceSpacing.sm),
            TextFormField(
              controller: _phone,
              decoration: const InputDecoration(
                labelText: 'Phone number (if relevant)',
                hintText: 'Optional',
              ),
              keyboardType: TextInputType.phone,
              enabled: !_saving,
            ),
            const SizedBox(height: RetraceSpacing.sm),
            Text(
              'RETRACE never reads IMEI without your input (§12). Unavailable means the OS did not expose it — never a fake value.',
              style: theme.textTheme.bodySmall,
            ),
            if (_error != null) ...[
              const SizedBox(height: RetraceSpacing.md),
              Text(_error!, style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.error)),
            ],
            const SizedBox(height: RetraceSpacing.lg),
            RetraceButton(
              label: 'Save Device',
              isLoading: _saving,
              onPressed: _saving ? null : _submit,
            ),
          ],
        ),
      ),
    );
  }
}

class _ReadOnlyRow extends StatelessWidget {
  const _ReadOnlyRow({required this.label, required this.value});
  final String label;
  final String value;
  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(width: 120, child: Text(label, style: theme.textTheme.bodySmall)),
          Expanded(
            child: Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }
}
