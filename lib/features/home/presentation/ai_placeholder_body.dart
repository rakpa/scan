import 'package:flutter/material.dart';

import 'home_design_tokens.dart';

class AiPlaceholderBody extends StatelessWidget {
  const AiPlaceholderBody({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 88,
                height: 88,
                decoration: BoxDecoration(
                  color: HomeDesign.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: const Icon(Icons.auto_awesome_rounded, size: 40, color: HomeDesign.primary),
              ),
              const SizedBox(height: 24),
              const Text(
                'AI Assistant',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: HomeDesign.onSurface,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Smart summaries and document insights are coming soon.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 15, color: HomeDesign.muted, height: 1.45),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
