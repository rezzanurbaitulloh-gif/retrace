import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:retrace/core/theme/retrace_spacing.dart';
import 'package:retrace/data/session/onboarding_store.dart';
import 'package:retrace/design_system/components/retrace_buttons.dart';

/// 4-step onboarding (§8–§9): Welcome → Protect → Always ready → Device type.
/// Progressive disclosure — never 30 fields up front. Completing persists
/// `seen=1` + device type; the router then moves to /login on its own.
class OnboardingPage extends ConsumerStatefulWidget {
  const OnboardingPage({super.key});

  @override
  ConsumerState<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends ConsumerState<OnboardingPage> {
  final PageController _pages = PageController();
  int _index = 0;
  String _deviceType = 'Phone';
  bool _saving = false;

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  Future<void> _finish({bool skipped = false}) async {
    if (_saving) return;
    setState(() => _saving = true);
    try {
      final OnboardingStore store = ref.read(onboardingStoreProvider);
      if (!skipped) await store.setDeviceType(_deviceType);
      await store.markSeen();
      ref.read(onboardingSeenProvider.notifier).state = true;
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    const int total = 4;
    return Scaffold(
      appBar: AppBar(
        actions: [
          if (_index < total - 1)
            TextButton(
              onPressed: _saving ? null : () => _finish(skipped: true),
              child: const Text('Skip'),
            ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(RetraceSpacing.md),
          child: Column(
            children: [
              Expanded(
                child: PageView(
                  controller: _pages,
                  onPageChanged: (int i) =>
                      setState(() => _index = i),
                  children: [
                    const _Step(
                      icon: Icons.shield_outlined,
                      title: 'Welcome to RETRACE',
                      body:
                          'Secure your device, protect your data, stay in control.',
                    ),
                    const _Step(
                      icon: Icons.location_on_outlined,
                      title: 'Protect what matters',
                      body:
                          'RETRACE helps you locate and recover your devices.',
                    ),
                    const _Step(
                      icon: Icons.notifications_active_outlined,
                      title: 'Always ready',
                      body:
                          'Location, notifications, and recovery tools work together.',
                    ),
                    _DeviceTypeStep(
                      selected: _deviceType,
                      onSelect: (String v) =>
                          setState(() => _deviceType = v),
                    ),
                  ],
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List<Widget>.generate(
                  total,
                  (int i) => Semantics(
                    label: 'Step ${i + 1} of $total',
                    child: Container(
                      width: _index == i ? 24 : 8,
                      height: 8,
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      decoration: BoxDecoration(
                        color: _index == i
                            ? theme.colorScheme.primary
                            : theme.dividerColor,
                        borderRadius: BorderRadius.circular(
                            RetraceRadius.pill),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: RetraceSpacing.md),
              SizedBox(
                width: double.infinity,
                child: _index < total - 1
                    ? RetraceButton(
                        label: 'Continue',
                        onPressed: () => _pages.nextPage(
                          duration: const Duration(milliseconds: 220),
                          curve: Curves.easeOutCubic,
                        ),
                      )
                    : RetraceButton(
                        label: 'Get Started',
                        isLoading: _saving,
                        onPressed:
                            _saving ? null : () => _finish(),
                      ),
              ),
              if (_index == 0) ...[
                const SizedBox(height: RetraceSpacing.sm),
                Text('Step 1 of $total',
                    style: theme.textTheme.bodySmall),
              ] else
                Text('Step ${_index + 1} of $total',
                    style: theme.textTheme.bodySmall),
            ],
          ),
        ),
      ),
    );
  }
}

class _Step extends StatelessWidget {
  const _Step(
      {required this.icon, required this.title, required this.body});

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, size: 72, color: theme.colorScheme.primary),
        const SizedBox(height: RetraceSpacing.lg),
        Text(title,
            textAlign: TextAlign.center,
            style: theme.textTheme.headlineMedium),
        const SizedBox(height: RetraceSpacing.sm),
        Text(body,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyLarge),
      ],
    );
  }
}

class _DeviceTypeStep extends StatelessWidget {
  const _DeviceTypeStep({required this.selected, required this.onSelect});

  final String selected;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    const List<({String label, String hint, IconData icon})> types = [
      (label: 'Phone', hint: 'Smartphone', icon: Icons.smartphone_outlined),
      (label: 'Tablet', hint: 'Tablet device', icon: Icons.tablet_outlined),
      (
        label: 'Other',
        hint: 'Laptop, Watch, etc.',
        icon: Icons.devices_outlined
      ),
    ];
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text('What are you protecting?',
            textAlign: TextAlign.center,
            style: theme.textTheme.headlineMedium),
        const SizedBox(height: RetraceSpacing.md),
        RadioGroup<String>(
          groupValue: selected,
          onChanged: (String? v) {
            if (v != null) onSelect(v);
          },
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: types
                .map(
                  (t) => Padding(
                    padding: const EdgeInsets.only(
                        bottom: RetraceSpacing.sm),
                    child: RadioListTile<String>(
                      value: t.label,
                      title: Text(t.label),
                      subtitle: Text(t.hint),
                      secondary: Icon(t.icon),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                            RetraceRadius.md),
                        side: BorderSide(color: theme.dividerColor),
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
        ),
      ],
    );
  }
}
