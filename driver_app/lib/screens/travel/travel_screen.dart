import 'package:flutter/material.dart';
import '../../core/theme.dart';

class TravelScreen extends StatelessWidget {
  const TravelScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.darkBg,
      appBar: AppBar(
        backgroundColor: AppTheme.darkSurface,
        title: const Text('Travel'),
        centerTitle: true,
      ),
      body: const Center(
        child: Text(
          'Welcome to the Travel screen! 🌍',
          style: TextStyle(
            color: AppTheme.neonGreen,
            fontSize: 24,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}
