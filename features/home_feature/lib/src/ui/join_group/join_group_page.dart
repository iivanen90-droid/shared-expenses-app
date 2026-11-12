import 'package:common/common.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:ui_kit/ui_kit.dart';

class JoinGroupPage extends StatefulWidget {
  const JoinGroupPage({super.key});

  @override
  State<JoinGroupPage> createState() => _JoinGroupPageState();
}

class _JoinGroupPageState extends State<JoinGroupPage> {
  bool _showNotice = false;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(leading: const CloseButton()),
    body: SafeArea(
      child: Center(
        heightFactor: 1,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Icon(Icons.link_rounded, color: context.colors.primary, size: 44),
                const SizedBox(height: 8),
                Semantics(
                  header: true,
                  child: Text(
                    LocaleKeys.joinGroupTitle.tr(context: context),
                    style: context.texts.heading,
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  LocaleKeys.joinGroupInstructions.tr(context: context),
                  style: context.texts.body.copyWith(color: context.colors.onSurfaceVariant),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                TextField(
                  keyboardType: TextInputType.url,
                  autocorrect: false,
                  decoration: InputDecoration(
                    labelText: LocaleKeys.joinGroupLinkHint.tr(context: context),
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: () {
                    FocusScope.of(context).unfocus();
                    setState(() => _showNotice = true);
                  },
                  child: Text(LocaleKeys.joinGroupAction.tr(context: context)),
                ),
                if (_showNotice)
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Semantics(
                      liveRegion: true,
                      child: Text(
                        LocaleKeys.joinGroupUnavailable.tr(context: context),
                        style: context.texts.body,
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}
