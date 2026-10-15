import 'package:flutter/material.dart';

void main() {
  runApp(const SharedExpensesApp());
}

class SharedExpensesApp extends StatelessWidget {
  const SharedExpensesApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: 'Спільні витрати',
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: SafeArea(child: Center(child: Text('Спільні витрати'))),
      ),
    );
  }
}
