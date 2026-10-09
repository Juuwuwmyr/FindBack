import 'package:flutter/material.dart';

class ClaimDetailScreen extends StatelessWidget {
  const ClaimDetailScreen({super.key, required this.id});
  final String id;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Claim Detail')),
      body: Center(child: Text('Claim Detail ($id) — coming soon')),
    );
  }
}
