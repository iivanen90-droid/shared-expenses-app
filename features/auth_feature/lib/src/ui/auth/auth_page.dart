import 'package:auth_feature/src/ui/auth/auth_cubit.dart';
import 'package:auth_feature/src/ui/auth/auth_state.dart';
import 'package:common/common.dart';
import 'package:core/core.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
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

  String _messageKey(AuthState state) {
    if (state.failure != null) {
      return switch (state.failure!) {
        AuthenticationFailureKind.configuration => LocaleKeys.authNotConfigured,
        AuthenticationFailureKind.connection => LocaleKeys.authFailed,
        AuthenticationFailureKind.cancelled => LocaleKeys.authCancelled,
        AuthenticationFailureKind.storage => LocaleKeys.authStorageFailed,
      };
    }
    if (state.status == AuthStatus.waitingForGoogle) return LocaleKeys.authWaiting;
    return switch (state.session) {
      AuthenticationStatus.unconfigured => LocaleKeys.authNotConfigured,
      AuthenticationStatus.signedOut => LocaleKeys.authDescription,
      AuthenticationStatus.signedIn => LocaleKeys.authSignedIn,
    };
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(LocaleKeys.authTitle.tr(context: context))),
    body: SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: BlocBuilder<AuthCubit, AuthState>(
              builder: (context, state) {
                final cubit = context.read<AuthCubit>();
                final busy = state.status != AuthStatus.ready;
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
                    if (busy) const Center(child: CircularProgressIndicator()),
                    if (state.session == AuthenticationStatus.signedOut)
                      Semantics(
                        identifier: 'auth_google',
                        child: FilledButton(
                          onPressed: busy ? null : cubit.signInWithGoogle,
                          child: Text(LocaleKeys.authGoogle.tr(context: context)),
                        ),
                      ),
                    if (state.status == AuthStatus.waitingForGoogle)
                      TextButton(
                        onPressed: cubit.cancelSignIn,
                        child: Text(LocaleKeys.authCancel.tr(context: context)),
                      ),
                    if (state.session == AuthenticationStatus.signedIn)
                      Semantics(
                        identifier: 'auth_sign_out',
                        child: FilledButton(
                          onPressed: busy ? null : cubit.signOut,
                          child: Text(LocaleKeys.authSignOut.tr(context: context)),
                        ),
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
