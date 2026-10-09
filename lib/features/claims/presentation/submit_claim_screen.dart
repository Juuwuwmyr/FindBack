import 'package:flutter/material.dart';

class SubmitClaimScreen extends StatelessWidget {
  const SubmitClaimScreen({super.key, required this.reportId});
  final String reportId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Submit Claim')),
      body: Center(child: Text('Submit Claim ($reportId) — coming soon')),
    );
  }
}
