import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:sizer/sizer.dart';

class LogisticsItemForm extends StatefulWidget {
  final bool isAddingItem;
  final String goodType;
  final Function({
    required String name,
    required double length,
    required double height,
    required double width,
    required String unit,
  }) onAddItem;

  const LogisticsItemForm({
    super.key,
    required this.isAddingItem,
    required this.goodType,
    required this.onAddItem,
  });

  @override
  State<LogisticsItemForm> createState() => _LogisticsItemFormState();
}

class _LogisticsItemFormState extends State<LogisticsItemForm> {
  final _itemNameController = TextEditingController();
  final _lengthController = TextEditingController();
  final _heightController = TextEditingController();
  final _widthController = TextEditingController();

  String _selectedUnit = 'cm';
  final List<String> _units = ['cm', 'm', 'feet', 'inch'];

  @override
  void dispose() {
    _itemNameController.dispose();
    _lengthController.dispose();
    _heightController.dispose();
    _widthController.dispose();
    super.dispose();
  }

  String? _validateItemInputs() {
    final name = _itemNameController.text.trim();
    final length = double.tryParse(_lengthController.text.trim()) ?? 0;
    final height = double.tryParse(_heightController.text.trim()) ?? 0;
    final width = double.tryParse(_widthController.text.trim()) ?? 0;

    if (name.length < 2) {
      return 'Item name must be at least 2 characters';
    }
    if (length <= 0 || height <= 0 || width <= 0) {
      return 'Length, height, and width must all be greater than 0';
    }
    return null;
  }

  void _submitForm() {
    final validationError = _validateItemInputs();
    if (validationError != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(validationError)),
      );
      return;
    }

    widget.onAddItem(
      name: _itemNameController.text.trim(),
      length: double.tryParse(_lengthController.text.trim()) ?? 0,
      height: double.tryParse(_heightController.text.trim()) ?? 0,
      width: double.tryParse(_widthController.text.trim()) ?? 0,
      unit: _selectedUnit,
    );

    // Clear inputs upon successful add
    _itemNameController.clear();
    _lengthController.clear();
    _heightController.clear();
    _widthController.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _itemNameController,
            decoration: InputDecoration(
              labelText: 'Item Name',
              labelStyle: TextStyle(fontSize: 14.sp),
              prefixIcon: const Icon(
                Icons.inventory_2_outlined,
                color: Color(0xFF0F5A3B),
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
            ),
            style: TextStyle(fontSize: 14.sp),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _lengthController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(
                      RegExp(r'^\d+\.?\d{0,2}'),
                    ),
                  ],
                  decoration: InputDecoration(
                    labelText: 'Length',
                    labelStyle: TextStyle(fontSize: 14.sp),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 12,
                    ),
                  ),
                  style: TextStyle(fontSize: 14.sp),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: _heightController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(
                      RegExp(r'^\d+\.?\d{0,2}'),
                    ),
                  ],
                  decoration: InputDecoration(
                    labelText: 'Height',
                    labelStyle: TextStyle(fontSize: 14.sp),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 12,
                    ),
                  ),
                  style: TextStyle(fontSize: 14.sp),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: _widthController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(
                      RegExp(r'^\d+\.?\d{0,2}'),
                    ),
                  ],
                  decoration: InputDecoration(
                    labelText: 'Width',
                    labelStyle: TextStyle(fontSize: 14.sp),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 12,
                    ),
                  ),
                  style: TextStyle(fontSize: 14.sp),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Unit: $_selectedUnit',
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Row(
                children: _units.map((unit) {
                  final isSelected = _selectedUnit == unit;
                  return Padding(
                    padding: const EdgeInsets.only(left: 6),
                    child: ChoiceChip(
                      label: Text(unit),
                      selected: isSelected,
                      onSelected: (selected) {
                        if (selected) {
                          setState(() => _selectedUnit = unit);
                        }
                      },
                      selectedColor: const Color(0xFF0F5A3B).withValues(alpha: 0.2),
                      labelStyle: TextStyle(
                        fontSize: 14.sp,
                        color: isSelected
                            ? const Color(0xFF0F5A3B)
                            : Colors.black,
                        fontWeight: isSelected
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: widget.isAddingItem ? null : _submitForm,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0F5A3B),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(
                  vertical: 12,
                ),
              ),
              child: Text(
                widget.isAddingItem ? 'Saving...' : 'Add Item to List',
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
