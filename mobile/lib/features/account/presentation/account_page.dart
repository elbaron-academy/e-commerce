import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../app/app.dart';
import '../../../app/config.dart';
import '../../../app/di.dart';
import '../../../app/theme.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/widgets/common.dart';
import '../../../core/widgets/load_state.dart';
import '../../auth/domain/auth.dart';
import '../../auth/presentation/session_cubit.dart';
import '../../settings/locale_cubit.dart';
import '../../support/presentation/chat_entry.dart';
import '../domain/address.dart';
import 'address_form_sheet.dart';

class AddressesCubit extends LoadCubit<List<Address>> {
  AddressesCubit(this._repository) : super(_repository.list);

  final AddressRepository _repository;

  Future<void> remove(int id) async {
    await _repository.delete(id);
    await load(silent: true);
  }

  Future<void> makeDefault(int id) async {
    await _repository.setDefault(id);
    await load(silent: true);
  }
}

class AccountPage extends StatelessWidget {
  const AccountPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final session = context.watch<SessionCubit>().state;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.accountTitle)),
      body: session.user == null
          ? ListView(
              padding: const EdgeInsets.all(16),
              children: [
                EmptyState(
                  emoji: '👋',
                  title: l10n.authTitle,
                  text: l10n.accountSignInPrompt,
                  action: FilledButton(onPressed: () => context.push('/login'), child: Text(l10n.headerLogin)),
                ),
                const _LanguageCard(),
              ],
            )
          : BlocProvider(
              key: ValueKey('${context.lang}-${session.user!.id}'),
              create: (_) => AddressesCubit(sl())..load(),
              child: _AccountView(user: session.user!),
            ),
    );
  }
}

class _AccountView extends StatelessWidget {
  const _AccountView({required this.user});

  final User user;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final initial = (user.name.isNotEmpty ? user.name : user.phone).characters.first.toUpperCase();
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: AppColors.brand600,
                  child: Text(
                    initial,
                    style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user.name.isNotEmpty ? user.name : l10n.accountGuest,
                        style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
                      ),
                      Text(
                        user.phone,
                        textDirection: TextDirection.ltr,
                        style: const TextStyle(color: AppColors.muted),
                      ),
                    ],
                  ),
                ),
                OutlinedButton.icon(
                  onPressed: () => context.go('/orders'),
                  icon: const Icon(Icons.inventory_2_outlined, size: 18),
                  label: Text(l10n.accountOrders),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        const ChatTile(),
        const SizedBox(height: 12),
        _ProfileCard(user: user),
        const SizedBox(height: 12),
        const _AddressesCard(),
        const SizedBox(height: 12),
        const _LanguageCard(),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: () => context.read<SessionCubit>().logout(),
          style: OutlinedButton.styleFrom(foregroundColor: AppColors.danger),
          icon: const Icon(Icons.logout),
          label: Text(l10n.accountLogout),
        ),
        if (!sl<AppConfig>().isProd)
          Padding(
            padding: const EdgeInsets.only(top: 16),
            child: Text(
              '${sl<AppConfig>().flavor.name} · ${sl<AppConfig>().apiBaseUrl}',
              textAlign: TextAlign.center,
              textDirection: TextDirection.ltr,
              style: const TextStyle(fontSize: 11, color: AppColors.muted),
            ),
          ),
      ],
    );
  }
}

class _ProfileCard extends StatefulWidget {
  const _ProfileCard({required this.user});

  final User user;

  @override
  State<_ProfileCard> createState() => _ProfileCardState();
}

class _ProfileCardState extends State<_ProfileCard> {
  late final _name = TextEditingController(text: widget.user.name);
  late final _email = TextEditingController(text: widget.user.email);
  bool _saving = false;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final l10n = context.l10n;
    final session = context.read<SessionCubit>();
    setState(() => _saving = true);
    try {
      session.updated(await sl<AuthRepository>().updateProfile(name: _name.text.trim(), email: _email.text.trim()));
      showMessage(l10n.accountSaved);
    } catch (error) {
      showMessage(errorText(error, l10n));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return SectionCard(
      title: l10n.accountProfile,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: _name,
            decoration: InputDecoration(labelText: l10n.accountName),
            autofillHints: const [AutofillHints.name],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _email,
            keyboardType: TextInputType.emailAddress,
            textDirection: TextDirection.ltr,
            decoration: InputDecoration(labelText: '${l10n.accountEmail} (${l10n.commonOptional})'),
          ),
          const SizedBox(height: 12),
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: FilledButton(onPressed: _saving ? null : _save, child: Text(l10n.commonSave)),
          ),
        ],
      ),
    );
  }
}

class _AddressesCard extends StatelessWidget {
  const _AddressesCard();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final cubit = context.read<AddressesCubit>();
    return SectionCard(
      title: l10n.accountAddresses,
      child: BlocBuilder<AddressesCubit, LoadState<List<Address>>>(
        builder: (context, state) {
          final addresses = state.data ?? const <Address>[];
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (state.status == LoadStatus.loading) const Skeleton(height: 56),
              for (final a in addresses)
                Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(color: AppColors.canvas, borderRadius: BorderRadius.circular(12)),
                  child: ListTile(
                    leading: const Icon(Icons.location_on_outlined, color: AppColors.brand700),
                    title: Text(
                      a.isDefault ? '${a.title} · ${l10n.addressDefault}' : a.title,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    subtitle: Text(a.line, maxLines: 1, overflow: TextOverflow.ellipsis),
                    onTap: a.isDefault ? null : () => cubit.makeDefault(a.id),
                    trailing: IconButton(
                      tooltip: l10n.commonDelete,
                      icon: const Icon(Icons.delete_outline),
                      onPressed: () => cubit.remove(a.id),
                    ),
                  ),
                ),
              OutlinedButton.icon(
                onPressed: () async {
                  if (await showAddressForm(context) != null) await cubit.load(silent: true);
                },
                icon: const Icon(Icons.add),
                label: Text(l10n.checkoutAddAddress),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _LanguageCard extends StatelessWidget {
  const _LanguageCard();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final locale = context.watch<LocaleCubit>().state;
    return SectionCard(
      title: l10n.accountLanguage,
      child: SegmentedButton<String>(
        segments: [
          ButtonSegment(value: 'ar', label: Text(l10n.languageArabic)),
          ButtonSegment(value: 'en', label: Text(l10n.languageEnglish)),
        ],
        selected: {locale.languageCode},
        onSelectionChanged: (value) {
          context.read<LocaleCubit>().select(value.first);
          if (context.read<SessionCubit>().state.isLoggedIn) {
            sl<AuthRepository>().updateProfile(language: value.first).ignore();
          }
        },
      ),
    );
  }
}
