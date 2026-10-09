import 'package:flutter/material.dart';

class EditReportScreen extends StatelessWidget {
  const EditReportScreen({super.key, required this.id});
  final String id;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Edit Report')),
      body: Center(child: Text('Edit Report ($id) — coming soon')),
    );
  }
}
