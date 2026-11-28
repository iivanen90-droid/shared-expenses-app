import 'package:common/common.dart';
import 'package:core/core.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:main_shell_feature/src/ui/profile/profile_cubit.dart';
import 'package:main_shell_feature/src/ui/profile/profile_state.dart';
import 'package:router/router.dart';
import 'package:ui_kit/ui_kit.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});
  @override
  Widget build(BuildContext context) => BlocProvider<ProfileCubit>(
    create: (_) =>
        DependencyProvider.get<ProfileCubit>()
          ..initialize(context.locale.languageCode == 'uk' ? AppLanguage.uk : AppLanguage.en),
    child: const _ProfileView(),
  );
}

class _ProfileView extends StatelessWidget {
  const _ProfileView();
  @override
  Widget build(BuildContext context) => BlocConsumer<ProfileCubit, ProfileState>(
    listenWhen: (previous, current) =>
        previous.language != current.language ||
        (previous.status != ProfileStatus.signedOut && current.status == ProfileStatus.signedOut),
    listener: (context, state) {
      if (state.status == ProfileStatus.signedOut) {
        context.goTo(const AuthRoute());
      } else if (context.locale.languageCode != state.language.name) {
        context.setLocale(Locale(state.language.name));
      }
    },
    builder: (context, state) {
      final cubit = context.read<ProfileCubit>();
      final failureKey = switch (state.failure) {
        ProfileFailure.loading => LocaleKeys.profileLoadFailed,
        ProfileFailure.language => LocaleKeys.profileLanguageFailed,
        ProfileFailure.logout => LocaleKeys.profileLogoutFailed,
        null => null,
      };
      return Scaffold(
        appBar: AppBar(title: Text(LocaleKeys.profileTab.tr(context: context))),
        body: Semantics(
          identifier: 'profile_page',
          container: true,
          child: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Center(child: CircleAvatar(radius: 32, child: Icon(Icons.person_outline, size: 36))),
                  const SizedBox(height: 16),
                  Semantics(
                    identifier: 'profile_name',
                    child: Text(
                      state.profile?.name ?? LocaleKeys.profileNameMissing.tr(context: context),
                      textAlign: TextAlign.center,
                      style: context.texts.heading,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Semantics(
                    identifier: 'profile_email',
                    child: Text(
                      state.profile?.email ?? LocaleKeys.profileEmailMissing.tr(context: context),
                      textAlign: TextAlign.center,
                      style: context.texts.body,
                    ),
                  ),
                  const SizedBox(height: 24),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(LocaleKeys.profileLanguage.tr(context: context)),
                    trailing: Semantics(
                      identifier: 'profile_language',
                      child: DropdownButton<AppLanguage>(
                        value: state.language,
                        onChanged: state.busy
                            ? null
                            : (language) {
                                if (language != null) cubit.changeLanguage(language);
                              },
                        items: const [
                          DropdownMenuItem(value: AppLanguage.uk, child: Text('Українська')),
                          DropdownMenuItem(value: AppLanguage.en, child: Text('English')),
                        ],
                      ),
                    ),
                  ),
                  if (failureKey != null)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Semantics(liveRegion: true, child: Text(failureKey.tr(context: context))),
                    ),
                  if (state.busy) const Center(child: CircularProgressIndicator()),
                  const SizedBox(height: 16),
                  if (state.session == AuthenticationStatus.signedIn)
                    Semantics(
                      identifier: 'profile_logout',
                      child: FilledButton(
                        onPressed: state.busy ? null : cubit.signOut,
                        child: Text(LocaleKeys.authSignOut.tr(context: context)),
                      ),
                    )
                  else
                    Semantics(
                      identifier: 'profile_account',
                      child: FilledButton(
                        onPressed: state.busy ? null : () => context.pushTo<void>(const AuthRoute()),
                        child: Text(LocaleKeys.authAccount.tr(context: context)),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      );
    },
  );
}
