import 'package:flutter/material.dart';

import '../recipes_theme.dart';

class RecipeStepIndicator extends StatelessWidget {
  const RecipeStepIndicator({
    super.key,
    required this.steps,
    required this.currentIndex,
  });

  final List<String> steps;
  final int currentIndex;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(
            steps.length,
            (index) => Expanded(
              child: Text(
                steps[index],
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: index <= currentIndex
                      ? RecipeColors.primary
                      : RecipeColors.textMuted,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: List.generate(steps.length * 2 - 1, (index) {
            if (index.isEven) {
              final stepIndex = index ~/ 2;
              final isActive = stepIndex <= currentIndex;
              return _StepDot(isActive: isActive);
            }
            final lineIndex = (index - 1) ~/ 2;
            final isActive = lineIndex < currentIndex;
            return Expanded(child: _StepLine(isActive: isActive));
          }),
        ),
      ],
    );
  }
}

class _StepDot extends StatelessWidget {
  const _StepDot({required this.isActive});

  final bool isActive;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 18,
      height: 18,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isActive ? RecipeColors.primary : RecipeColors.border,
      ),
      child: isActive
          ? const Icon(Icons.circle, size: 8, color: Colors.white)
          : const SizedBox.shrink(),
    );
  }
}

class _StepLine extends StatelessWidget {
  const _StepLine({required this.isActive});

  final bool isActive;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 4,
      margin: const EdgeInsets.symmetric(horizontal: 6),
      decoration: BoxDecoration(
        color: isActive ? RecipeColors.primary : RecipeColors.border,
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }
}
