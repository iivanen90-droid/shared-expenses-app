import 'package:auth_feature/src/ui/auth/auth_cubit.dart';
import 'package:auth_feature/src/ui/auth/auth_state.dart';
import 'package:common/common.dart';
import 'package:core/core.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:router/router.dart';
import 'package:ui_kit/ui_kit.dart';

class AuthPage extends StatelessWidget {
  const AuthPage({super.key});

  @override
  Widget build(BuildContext context) => BlocProvider<AuthCubit>(
    create: (_) => DependencyProvider.get<AuthCubit>()..initialize(),
    child: const _AuthView(),
  );
}

class _AuthView extends StatelessWidget {
  const _AuthView();

  String _messageKey(AuthState state) => switch (state.status) {
    AuthStatus.loading => LocaleKeys.authWaiting,
    AuthStatus.cancelling => LocaleKeys.authCancelling,
    AuthStatus.authenticated => LocaleKeys.authSignedIn,
    AuthStatus.error => switch (state.failure) {
      AuthenticationFailureKind.configuration => LocaleKeys.authNotConfigured,
      AuthenticationFailureKind.storage => LocaleKeys.authStorageFailed,
      _ => LocaleKeys.authFailed,
    },
    AuthStatus.initial => switch (state.failure) {
      AuthenticationFailureKind.cancelled => LocaleKeys.authCancelled,
      _ =>
        state.session == AuthenticationStatus.unconfigured ? LocaleKeys.authNotConfigured : LocaleKeys.authDescription,
    },
  };

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(LocaleKeys.authTitle.tr(context: context))),
    body: SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: BlocConsumer<AuthCubit, AuthState>(
              listenWhen: (previous, current) =>
                  previous.status != current.status && current.status == AuthStatus.authenticated,
              listener: (context, _) => context.goTo(const HomeRoute()),
              builder: (context, state) {
                final cubit = context.read<AuthCubit>();
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Semantics(
                      liveRegion: true,
                      child: Text(
                        _messageKey(state).tr(context: context),
                        style: context.texts.body,
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 24),
                    if (state.isBusy) const Center(child: CircularProgressIndicator()),
                    if (state.session == AuthenticationStatus.signedOut)
                      Semantics(
                        identifier: 'auth_google',
                        child: FilledButton(
                          onPressed: state.canSignIn ? cubit.signInWithGoogle : null,
                          child: Text(LocaleKeys.authGoogle.tr(context: context)),
                        ),
                      ),
                    if (state.status == AuthStatus.loading)
                      TextButton(
                        onPressed: cubit.cancelSignIn,
                        child: Text(LocaleKeys.authCancel.tr(context: context)),
                      ),
                    if (state.session == AuthenticationStatus.signedIn && !state.isBusy)
                      FilledButton(
                        onPressed: () => context.goTo(const ProfileRoute()),
                        child: Text(LocaleKeys.authAccount.tr(context: context)),
                      ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    ),
  );
}
