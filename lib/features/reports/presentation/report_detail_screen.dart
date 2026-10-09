import 'package:flutter/material.dart';

class ReportDetailScreen extends StatelessWidget {
  const ReportDetailScreen({super.key, required this.id});
  final String id;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Report Detail')),
      body: Center(child: Text('Report Detail ($id) — coming soon')),
    );
  }
}
