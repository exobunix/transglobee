import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

class StepTracker extends StatelessWidget {
  final int currentStep; // 1 to 4

  const StepTracker({
    super.key,
    required this.currentStep,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildStep(1, Icons.location_on, 'Route', currentStep >= 1),
          _buildStepLine(),
          _buildStep(2, Icons.local_shipping, 'Vehicle', currentStep >= 2),
          _buildStepLine(),
          _buildStep(3, Icons.inventory_2, 'Items', currentStep >= 3),
          _buildStepLine(),
          _buildStep(4, Icons.check_circle, 'Confirm', currentStep >= 4),
        ],
      ),
    );
  }

  Widget _buildStep(int number, IconData icon, String label, bool isActive) {
    const activeColor = Color(0xFF0F5A3B);
    final inactiveColor = Colors.grey.shade400;
    return Column(
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isActive
                    ? activeColor.withValues(alpha: 0.1)
                    : Colors.grey.shade100,
                border: Border.all(
                  color: isActive ? activeColor : inactiveColor,
                  width: isActive ? 2 : 1,
                ),
              ),
              child: Icon(
                icon,
                color: isActive ? activeColor : inactiveColor,
                size: 20,
              ),
            ),
            if (isActive)
              Positioned(
                top: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: const BoxDecoration(
                    color: activeColor,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    '$number',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 8,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: 12.sp,
            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
            color: isActive ? activeColor : Colors.grey.shade600,
          ),
        ),
      ],
    );
  }

  Widget _buildStepLine() {
    return Expanded(
      child: Container(
        height: 1,
        margin: const EdgeInsets.symmetric(horizontal: 4),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final boxWidth = constraints.constrainWidth();
            const dashWidth = 3.0;
            const dashHeight = 1.0;
            final dashCount = (boxWidth / (2 * dashWidth)).floor();
            return Flex(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              direction: Axis.horizontal,
              children: List.generate(dashCount, (_) {
                return SizedBox(
                  width: dashWidth,
                  height: dashHeight,
                  child: DecoratedBox(
                    decoration: BoxDecoration(color: Colors.grey.shade300),
                  ),
                );
              }),
            );
          },
        ),
      ),
    );
  }
}
