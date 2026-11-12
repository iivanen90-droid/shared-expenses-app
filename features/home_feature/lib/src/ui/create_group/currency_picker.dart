import 'dart:convert';

import 'package:common/common.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:home_feature/src/domain/entity/group_currency.dart';
import 'package:ui_kit/ui_kit.dart';

class CurrencyPicker extends StatefulWidget {
  const CurrencyPicker({required this.selectedCode, super.key});

  final String? selectedCode;

  @override
  State<CurrencyPicker> createState() => _CurrencyPickerState();
}

class _CurrencyPickerState extends State<CurrencyPicker> {
  Future<List<GroupCurrency>>? _catalog;
  String _search = '';

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _catalog ??= _loadCatalog(DefaultAssetBundle.of(context));
  }

  Future<List<GroupCurrency>> _loadCatalog(AssetBundle bundle) async {
    final json = await bundle.loadString('packages/home_feature/assets/currencies.json');
    final entries = jsonDecode(json) as Map<String, dynamic>;
    return [
      for (final MapEntry(key: code, value: names as List<dynamic>) in entries.entries)
        GroupCurrency(code: code, english: names[0] as String, ukrainian: names[1] as String),
    ];
  }

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
    child: FractionallySizedBox(
      heightFactor: 0.85,
      child: SafeArea(
        top: false,
        child: Column(
          children: [
            Row(
              children: [
                const CloseButton(),
                Expanded(
                  child: Text(LocaleKeys.groupCurrency.tr(context: context), style: context.texts.heading),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: TextField(
                key: const ValueKey('currency_search'),
                onChanged: (value) => setState(() => _search = value.trim().toLowerCase()),
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.search),
                  labelText: LocaleKeys.currencySearch.tr(context: context),
                  border: const OutlineInputBorder(),
                ),
              ),
            ),
            Expanded(
              child: FutureBuilder<List<GroupCurrency>>(
                future: _catalog,
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Center(child: Text(LocaleKeys.currencyLoadError.tr(context: context)));
                  }
                  final catalog = snapshot.data;
                  if (catalog == null) return const Center(child: CircularProgressIndicator());
                  final languageCode = context.locale.languageCode;
                  final currencies =
                      catalog
                          .where(
                            (item) =>
                                item.code.toLowerCase().contains(_search) ||
                                item.name(languageCode).toLowerCase().contains(_search),
                          )
                          .toList()
                        ..sort(
                          (left, right) =>
                              left.name(languageCode).toLowerCase().compareTo(right.name(languageCode).toLowerCase()),
                        );
                  if (currencies.isEmpty) return Center(child: Text(LocaleKeys.currencyNoResults.tr(context: context)));
                  return ListView.builder(
                    keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                    itemCount: currencies.length,
                    itemBuilder: (context, index) {
                      final item = currencies[index];
                      final selected = item.code == widget.selectedCode;
                      return ListTile(
                        selected: selected,
                        title: Text(item.name(languageCode), style: context.texts.title),
                        subtitle: Text(item.code),
                        trailing: selected ? const Icon(Icons.check) : null,
                        onTap: () => Navigator.pop(context, item),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
