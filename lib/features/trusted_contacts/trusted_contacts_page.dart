import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:retrace/core/theme/retrace_spacing.dart';
import 'package:retrace/design_system/components/retrace_buttons.dart';
import 'package:retrace/design_system/components/retrace_lists.dart';
import 'package:retrace/design_system/components/retrace_overlays.dart';
import 'package:retrace/design_system/components/retrace_states.dart';
import 'package:retrace/features/trusted_contacts/trusted_contacts.dart';
import 'package:retrace/features/trusted_contacts/trusted_contacts_repository.dart';

/// Trusted contacts roster (§40): owner-managed list with intended scopes.
/// Route: /trusted-contacts. Entries are stored on-device and queued for
/// sync — the sheet and list state this plainly; no access is granted
/// before the server-side table + RLS policies exist.
class TrustedContactsPage extends ConsumerStatefulWidget {
  const TrustedContactsPage({super.key});

  @override
  ConsumerState<TrustedContactsPage> createState() =>
      _TrustedContactsPageState();
}

class _TrustedContactsPageState extends ConsumerState<TrustedContactsPage> {
  List<TrustedContact> _contacts = <TrustedContact>[];
  bool _loading = true;
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
      final List<TrustedContact> contacts =
          await ref.read(trustedContactsControllerProvider).listAll();
      if (mounted) {
        setState(() {
          _contacts = contacts;
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

  Future<void> _showAdd() async {
    final bool? added = await showRetraceSheet<bool>(
      context,
      semanticLabel: 'Add trusted contact',
      child: const _AddContactForm(),
    );
    if (added ?? false) {
      await _load();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Saved on this device — syncs when the contacts service lands.',
            ),
          ),
        );
      }
    }
  }

  Future<void> _showDetail(TrustedContact contact) async {
    await showRetraceSheet<void>(
      context,
      semanticLabel: 'Contact details',
      child: _DetailSheet(
        contact: contact,
        onChanged: _load,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Trusted Contacts')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _loading ? null : _showAdd,
        icon: const Icon(Icons.person_add_outlined),
        label: const Text('Add contact'),
      ),
      body: _loading
          ? const LoadingState(message: 'Loading contacts…')
          : _error != null
              ? ErrorState(message: _error!, onRetry: _load)
              : _contacts.isEmpty
                  ? EmptyState(
                      icon: Icons.group_outlined,
                      title: 'No trusted contacts',
                      message:
                          'Add people who should help in an emergency or '
                          'recovery. Scopes record your intent — access itself '
                          'is granted only after the contacts service lands.',
                      actionLabel: 'Add contact',
                      onAction: _showAdd,
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.all(RetraceSpacing.md),
                      itemCount: _contacts.length + 1,
                      separatorBuilder: (_, int i) => i < _contacts.length
                          ? const SizedBox(height: RetraceSpacing.sm)
                          : const SizedBox.shrink(),
                      itemBuilder: (BuildContext context, int i) {
                        if (i == _contacts.length) {
                          return Padding(
                            padding: const EdgeInsets.only(
                              top: RetraceSpacing.sm,
                            ),
                            child: Text(
                              'Stored on this device and queued for sync. '
                              'No access is granted before the contacts '
                              'table + RLS policies exist.',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          );
                        }
                        final TrustedContact c = _contacts[i];
                        return TrustedContactCard(
                          name: c.name,
                          scope:
                              '${scopeLabel(c.scopes)} — ${c.status.title}',
                          onTap: () => _showDetail(c),
                        );
                      },
                    ),
    );
  }
}

class _AddContactForm extends ConsumerStatefulWidget {
  const _AddContactForm();

  @override
  ConsumerState<_AddContactForm> createState() => _AddContactFormState();
}

class _AddContactFormState extends ConsumerState<_AddContactForm> {
  final TextEditingController _name = TextEditingController();
  final TextEditingController _address = TextEditingController();
  Set<ContactScope> _scopes = <ContactScope>{ContactScope.emergency};
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    _address.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_saving) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await ref.read(trustedContactsControllerProvider).add(
            name: _name.text,
            address: _address.text,
            scopes: _scopes,
          );
      if (mounted) Navigator.of(context).pop(true);
    } on TrustedContactRejected catch (e) {
      if (mounted) {
        setState(() {
          _error = e.message;
          _saving = false;
        });
      }
    } on Object catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString().replaceFirst('Exception: ', '');
          _saving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Text('Add trusted contact',
            style: theme.textTheme.headlineSmall),
        const SizedBox(height: RetraceSpacing.sm),
        TextField(
          controller: _name,
          decoration: const InputDecoration(
            labelText: 'Full name',
            hintText: 'Ayu Lestari',
          ),
          textCapitalization: TextCapitalization.words,
          enabled: !_saving,
        ),
        const SizedBox(height: RetraceSpacing.sm),
        TextField(
          controller: _address,
          decoration: const InputDecoration(
            labelText: 'Email or phone',
            hintText: 'ayu@example.com / +62…',
          ),
          keyboardType: TextInputType.emailAddress,
          enabled: !_saving,
        ),
        const SizedBox(height: RetraceSpacing.sm),
        Text('Scopes', style: theme.textTheme.titleSmall),
        const SizedBox(height: 4),
        Wrap(
          spacing: 8,
          children: ContactScope.values.map((ContactScope s) {
            final bool selected = _scopes.contains(s);
            return FilterChip(
              label: Text(s.title),
              selected: selected,
              onSelected: _saving
                  ? null
                  : (bool on) {
                      setState(() {
                        final Set<ContactScope> next =
                            Set<ContactScope>.of(_scopes);
                        if (on) {
                          next.add(s);
                        } else {
                          next.remove(s);
                        }
                        _scopes = next;
                      });
                    },
            );
          }).toList(),
        ),
        if (_error != null) ...<Widget>[
          const SizedBox(height: RetraceSpacing.sm),
          Text(_error!,
              style: theme.textTheme.bodyMedium
                  ?.copyWith(color: theme.colorScheme.error)),
        ],
        const SizedBox(height: RetraceSpacing.md),
        RetraceButton(
          label: 'Save contact',
          isLoading: _saving,
          onPressed: _saving ? null : _save,
        ),
        const SizedBox(height: RetraceSpacing.sm),
      ],
    );
  }
}

class _DetailSheet extends ConsumerWidget {
  const _DetailSheet({required this.contact, required this.onChanged});

  final TrustedContact contact;
  final Future<void> Function() onChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ThemeData theme = Theme.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Text(contact.name, style: theme.textTheme.headlineSmall),
        const SizedBox(height: 4),
        Text(contact.address, style: theme.textTheme.bodyMedium),
        const SizedBox(height: RetraceSpacing.sm),
        Text('Status: ${contact.status.title}',
            style: theme.textTheme.bodySmall),
        const SizedBox(height: RetraceSpacing.sm),
        ...contact.scopes.map((ContactScope s) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text('• ${s.title} — ${s.description}',
                  style: theme.textTheme.bodySmall),
            )),
        const SizedBox(height: RetraceSpacing.md),
        if (contact.status == ContactStatus.invited)
          RetraceButton(
            label: 'Revoke contact',
            icon: Icons.person_remove_outlined,
            isSecondary: true,
            onPressed: () async {
              final bool ok = await ConfirmationDialog.show(
                context,
                title: 'Revoke ${contact.name}?',
                explanation:
                    'They will be removed from your roster on this device, '
                    'and the revocation is queued for sync.',
                confirmLabel: 'Revoke',
              );
              if (!ok) return;
              try {
                await ref
                    .read(trustedContactsControllerProvider)
                    .revoke(contact.id);
                await onChanged();
                if (context.mounted) Navigator.of(context).pop();
              } on Object catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(e
                          .toString()
                          .replaceFirst('Exception: ', '')),
                    ),
                  );
                }
              }
            },
          ),
        const SizedBox(height: RetraceSpacing.sm),
      ],
    );
  }
}
