import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/theme.dart';
import '../providers/vehicle_type_provider.dart';

class VehicleTypeSelector extends ConsumerStatefulWidget {
  const VehicleTypeSelector({super.key});

  @override
  ConsumerState<VehicleTypeSelector> createState() =>
      _VehicleTypeSelectorState();
}

class _VehicleTypeSelectorState extends ConsumerState<VehicleTypeSelector>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context, ) {
    final selectedType = ref.watch(vehicleTypeProvider);

    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: AppTheme.darkCard.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.darkDivider, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: VehicleType.values.map((type) {
          final isSelected = selectedType == type;
          return Expanded(
            child: GestureDetector(
              onTap: () {
                ref.read(vehicleTypeProvider.notifier).select(type);
                // Also select default sub-vehicle for this type
                ref
                    .read(selectedSubVehicleProvider.notifier)
                    .select(type.subOptions.first.id);
                _animController.reset();
                _animController.forward();
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 350),
                curve: Curves.easeOutCubic,
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 10),
                decoration: BoxDecoration(
                  gradient: isSelected
                      ? LinearGradient(
                          colors: [
                            type.accentColor.withValues(alpha: 0.25),
                            type.accentColor.withValues(alpha: 0.1),
                          ],
                        )
                      : null,
                  borderRadius: BorderRadius.circular(17),
                  border: isSelected
                      ? Border.all(
                          color: type.accentColor.withValues(alpha: 0.6),
                          width: 1.5,
                        )
                      : null,
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: type.accentColor.withValues(alpha: 0.2),
                            blurRadius: 12,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      type.icon,
                      size: isSelected ? 18 : 16,
                      color: isSelected
                          ? type.accentColor
                          : AppTheme.darkTextSecondary,
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        type.label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: isSelected
                              ? type.accentColor
                              : AppTheme.darkTextSecondary,
                          fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
                          fontSize: isSelected ? 13 : 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ── Sub-Vehicle Options Grid (like Ola's Mini/Sedan/SUV) ──
class VehicleSubOptions extends ConsumerStatefulWidget {
  const VehicleSubOptions({super.key});

  @override
  ConsumerState<VehicleSubOptions> createState() => _VehicleSubOptionsState();
}

class _VehicleSubOptionsState extends ConsumerState<VehicleSubOptions>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _fadeAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vehicleType = ref.watch(vehicleTypeProvider);
    final selectedSub = ref.watch(selectedSubVehicleProvider);
    final options = vehicleType.subOptions;

    // Reset animation when vehicle type changes
    ref.listen(vehicleTypeProvider, (prev, next) {
      _controller.reset();
      _controller.forward();
    });

    return SlideTransition(
      position: _slideAnim,
      child: FadeTransition(
        opacity: _fadeAnim,
        child: Container(
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 0),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppTheme.darkCard.withValues(alpha: 0.95),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: AppTheme.darkDivider.withValues(alpha: 0.5),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.25),
                blurRadius: 20,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 4, bottom: 10),
                child: Row(
                  children: [
                    Icon(
                      vehicleType.icon,
                      color: vehicleType.accentColor,
                      size: 16,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Select ${vehicleType.label} Type',
                        style: TextStyle(
                          color: vehicleType.accentColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              Row(
                children: options.asMap().entries.map((entry) {
                  final index = entry.key;
                  final option = entry.value;
                  final isActive = selectedSub == option.id;

                  return Expanded(
                    child: GestureDetector(
                      onTap: () {
                        ref
                            .read(selectedSubVehicleProvider.notifier)
                            .select(option.id);
                      },
                      child: TweenAnimationBuilder<double>(
                        duration: Duration(milliseconds: 300 + (index * 100)),
                        tween: Tween(begin: 0, end: 1),
                        builder: (context, value, child) {
                          return Transform.translate(
                            offset: Offset(0, 20 * (1 - value)),
                            child: Opacity(opacity: value, child: child),
                          );
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          margin: EdgeInsets.only(
                            right: index < options.length - 1 ? 8 : 0,
                          ),
                          padding: const EdgeInsets.symmetric(
                            vertical: 12,
                            horizontal: 6,
                          ),
                          decoration: BoxDecoration(
                            gradient: isActive
                                ? LinearGradient(
                                    colors: [
                                      option.color.withValues(alpha: 0.2),
                                      option.color.withValues(alpha: 0.08),
                                    ],
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                  )
                                : null,
                            color: isActive ? null : AppTheme.darkSurface,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: isActive
                                  ? option.color.withValues(alpha: 0.6)
                                  : AppTheme.darkDivider.withValues(alpha: 0.3),
                              width: isActive ? 1.5 : 1,
                            ),
                            boxShadow: isActive
                                ? [
                                    BoxShadow(
                                      color:
                                          option.color.withValues(alpha: 0.15),
                                      blurRadius: 10,
                                    ),
                                  ]
                                : null,
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              AnimatedContainer(
                                duration: const Duration(milliseconds: 300),
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: isActive
                                      ? option.color.withValues(alpha: 0.2)
                                      : AppTheme.darkCardLight
                                          .withValues(alpha: 0.5),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Icon(
                                  option.icon,
                                  size: isActive ? 24 : 20,
                                  color: isActive
                                      ? option.color
                                      : AppTheme.darkTextSecondary,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                option.name,
                                style: TextStyle(
                                  color: isActive
                                      ? AppTheme.darkTextPrimary
                                      : AppTheme.darkTextSecondary,
                                  fontSize: 12,
                                  fontWeight: isActive
                                      ? FontWeight.w700
                                      : FontWeight.w500,
                                ),
                                textAlign: TextAlign.center,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                option.perKm,
                                style: TextStyle(
                                  color: isActive
                                      ? option.color
                                      : AppTheme.darkTextSecondary
                                          .withValues(alpha: 0.5),
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
