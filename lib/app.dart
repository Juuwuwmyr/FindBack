import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class FindBackApp extends ConsumerWidget {
  const FindBackApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return const MaterialApp(
      title: 'FindBack',
      home: Scaffold(
        body: Center(child: Text('FindBack')),
      ),
    );
  }
}
