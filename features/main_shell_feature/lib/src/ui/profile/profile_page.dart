import 'package:common/common.dart';
import 'package:core/core.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:main_shell_feature/src/ui/profile/profile_account_cubit.dart';
import 'package:main_shell_feature/src/ui/profile/profile_account_state.dart';
import 'package:router/router.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});
  @override
  Widget build(BuildContext context) => BlocProvider<ProfileAccountCubit>(
    create: (_) => DependencyProvider.get<ProfileAccountCubit>()..initialize(),
    child: const _ProfileView(),
  );
}

class _ProfileView extends StatelessWidget {
  const _ProfileView();
  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: Semantics(
        container: true,
        identifier: 'profile_page',
        label: LocaleKeys.profileTab.tr(context: context),
        child: Center(
          child: BlocConsumer<ProfileAccountCubit, ProfileAccountState>(
            listenWhen: (previous, current) =>
                previous.status == ProfileAccountStatus.signingOut &&
                current.status == ProfileAccountStatus.initial &&
                current.session == AuthenticationStatus.signedOut,
            listener: (context, _) => context.goTo(const AuthRoute()),
            builder: (context, state) {
              final busy = state.status == ProfileAccountStatus.signingOut;
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (state.failure != null)
                    Text(
                      (state.failure == AuthenticationFailureKind.storage
                              ? LocaleKeys.authStorageFailed
                              : LocaleKeys.authFailed)
                          .tr(context: context),
                    ),
                  if (busy) const CircularProgressIndicator(),
                  if (state.session == AuthenticationStatus.signedIn)
                    Semantics(
                      identifier: 'profile_sign_out',
                      child: FilledButton(
                        onPressed: busy ? null : context.read<ProfileAccountCubit>().signOut,
                        child: Text(LocaleKeys.authSignOut.tr(context: context)),
                      ),
                    )
                  else
                    Semantics(
                      identifier: 'profile_account',
                      child: FilledButton(
                        onPressed: busy ? null : () => context.pushTo<void>(const AuthRoute()),
                        child: Text(LocaleKeys.authAccount.tr(context: context)),
                      ),
                    ),
                ],
              );
            },
          ),
        ),
      ),
    ),
  );
}
