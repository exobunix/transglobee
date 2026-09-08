import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/booking_model.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../services/driver_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ItemsVerificationScreen extends ConsumerStatefulWidget {
  final BookingModel booking;
  const ItemsVerificationScreen({super.key, required this.booking});

  @override
  ConsumerState<ItemsVerificationScreen> createState() => _ItemsVerificationScreenState();
}

class _ItemsVerificationScreenState extends ConsumerState<ItemsVerificationScreen> {
  late TextEditingController _vehiclePriceCtrl;
  late TextEditingController _helperCostCtrl;
  late TextEditingController _discountCtrl;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _vehiclePriceCtrl = TextEditingController(
      text: (widget.booking.vehiclePrice ?? widget.booking.fare).toStringAsFixed(2),
    );
    _helperCostCtrl = TextEditingController(
      text: (widget.booking.helperCost ?? 0).toStringAsFixed(2),
    );
    _discountCtrl = TextEditingController(
      text: (widget.booking.discountAmount ?? 0).toStringAsFixed(2),
    );
  }

  @override
  void dispose() {
    _vehiclePriceCtrl.dispose();
    _helperCostCtrl.dispose();
    _discountCtrl.dispose();
    super.dispose();
  }

  double get _vehiclePrice => double.tryParse(_vehiclePriceCtrl.text) ?? 0;
  double get _helperCost => double.tryParse(_helperCostCtrl.text) ?? 0;
  double get _discount => double.tryParse(_discountCtrl.text) ?? 0;
  double get _totalAmount => _vehiclePrice + _helperCost - _discount;

  void _openMap() async {
    final lat = widget.booking.dropLat;
    final lng = widget.booking.dropLng;
    if (lat == null || lng == null) return;
    final Uri url = Uri.parse('https://www.google.com/maps/search/?api=1&query=$lat,$lng');
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _saveBilling() async {
    setState(() => _isSaving = true);
    try {
      final service = ref.read(driverServiceProvider);
      await service.updateBilling(
        widget.booking.id,
        vehiclePrice: _vehiclePrice,
        helperCost: _helperCost,
        discountAmount: _discount,
        totalPrice: _totalAmount,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Billing saved successfully!'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final b = widget.booking;
    final items = b.items ?? [];
    final pickupDetails = b.pickupDetails;
    final dropDetails = b.dropDetails;

    const primaryColor = Color(0xFF4456BA);
    const bgColor = Color(0xFFF8F9FB);
    const surfaceColor = Colors.white;
    const textColor = Color(0xFF2C3437);
    const outlineColor = Color(0xFF747C80);
    const billingBg = Color(0xFF3886AF);
    const routeBg = Color(0xFF3A7CA5);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: Colors.white.withOpacity(0.8),
        elevation: 0,
        title: const Text('Shipment Details', style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold, fontSize: 20)),
        centerTitle: false,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: primaryColor),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.map_outlined, color: primaryColor),
            onPressed: _openMap,
            tooltip: 'Open in Maps',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // ═══════════════════════════════════════
            // ROUTE SECTION
            // ═══════════════════════════════════════
            const Text('ROUTE', style: TextStyle(color: outlineColor, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.0)),
            const SizedBox(height: 12),

            // Pickup Card
            _buildRouteCard(
              label: 'PICKUP',
              labelColor: const Color(0xFF66BB6A),
              address: b.pickupAddress,
              details: pickupDetails,
              routeBg: routeBg,
            ),
            const SizedBox(height: 12),

            // Drop Card
            _buildRouteCard(
              label: 'DROP',
              labelColor: const Color(0xFFEF5350),
              address: b.dropAddress,
              details: dropDetails,
              routeBg: routeBg,
            ),

            const SizedBox(height: 24),

            // ═══════════════════════════════════════
            // ITEMS SECTION
            // ═══════════════════════════════════════
            const Text('ITEMS TO TRANSPORT', style: TextStyle(color: outlineColor, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.0)),
            const SizedBox(height: 12),

            ...items.map((item) => Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: surfaceColor,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4)),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: const Color(0xFFEAEEF2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.inventory_2_outlined, color: primaryColor, size: 26),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE0E1F9),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            (item['type'] ?? 'General').toString().toUpperCase(),
                            style: const TextStyle(color: Color(0xFF4E5065), fontSize: 10, fontWeight: FontWeight.bold),
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          item['itemName']?.toString() ?? 'Unnamed Item',
                          style: const TextStyle(color: textColor, fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        if (item['length'] != null) ...[
                          const SizedBox(height: 2),
                          Text(
                            '${item['length']}x${item['width']}x${item['height']} ${item['unit'] ?? 'cm'}',
                            style: const TextStyle(color: outlineColor, fontSize: 11, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            )),

            const SizedBox(height: 16),
 
            if (b.transportName != null || b.transportNumber != null) ...[
              const Text('TRANSPORT INFO', style: TextStyle(color: outlineColor, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.0)),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: surfaceColor,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4)),
                  ],
                ),
                child: Column(
                  children: [
                    if (b.transportName != null)
                      Row(
                        children: [
                          const Icon(Icons.label_important_outline, color: primaryColor, size: 20),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Name', style: TextStyle(color: outlineColor, fontSize: 11)),
                              Text(b.transportName!, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                            ],
                          ),
                        ],
                      ),
                    if (b.transportName != null && b.transportNumber != null)
                      const Divider(height: 24, color: Color(0xFFF0F0F0)),
                    if (b.transportNumber != null)
                      Row(
                        children: [
                          const Icon(Icons.tag_rounded, color: primaryColor, size: 20),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Number', style: TextStyle(color: outlineColor, fontSize: 11)),
                              Text(b.transportNumber!, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                            ],
                          ),
                        ],
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],

            // ═══════════════════════════════════════
            // BILLING SECTION
            // ═══════════════════════════════════════
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: billingBg,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('BILLING', style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.0)),
                  const SizedBox(height: 16),
                  _buildBillingRow('Vehicle Price', _vehiclePriceCtrl),
                  const SizedBox(height: 12),
                  _buildBillingRow('Helper Cost', _helperCostCtrl),
                  const SizedBox(height: 12),
                  _buildBillingRow('Discount Applied', _discountCtrl, isDiscount: true),
                  const SizedBox(height: 16),
                  const Divider(color: Colors.white24, height: 1),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Total Amount', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                      Text('₹${_totalAmount.toStringAsFixed(2)}', style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Save Button
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton.icon(
                      onPressed: _isSaving ? null : _saveBilling,
                      icon: _isSaving
                        ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Color(0xFF3886AF), strokeWidth: 2))
                        : const Icon(Icons.save_rounded, size: 20),
                      label: Text(_isSaving ? 'Saving...' : 'Save Billing', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: billingBg,
                        disabledBackgroundColor: Colors.white70,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Confirm & Start Route button
            Container(
              width: double.infinity,
              height: 56,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(28),
                gradient: const LinearGradient(
                  colors: [Color(0xFF4456BA), Color(0xFF8596FF)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(color: primaryColor.withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 6)),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(28),
                  onTap: () {
                    _openMap();
                    Navigator.pop(context);
                  },
                  child: const Center(
                    child: Text('Confirm & Start Route →', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Route Card (Pickup / Drop) ───
  Widget _buildRouteCard({
    required String label,
    required Color labelColor,
    required String address,
    required Map<String, dynamic>? details,
    required Color routeBg,
  }) {
    final city = details?['city'] ?? '';
    final pincode = details?['pincode'] ?? '';
    final house = details?['houseNumber'] ?? details?['house'] ?? '';
    final floor = details?['floor'] ?? '';
    final landmark = details?['landmark'] ?? '';
    final phone = details?['phone'] ?? '';
    final email = details?['email'] ?? '';
    final locType = details?['locationType'] ?? '';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: routeBg,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: TextStyle(color: labelColor, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
              if (locType.isNotEmpty)
                Text(locType, style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 12)),
            ],
          ),
          const SizedBox(height: 8),

          // Address
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.location_on, color: labelColor, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  address,
                  style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),

          // Detail chips
          if (house.isNotEmpty || floor.isNotEmpty || city.isNotEmpty || pincode.isNotEmpty) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                if (house.isNotEmpty) _chip('House: $house'),
                if (floor.isNotEmpty) _chip('Floor: $floor'),
                if (city.isNotEmpty) _chip(city),
                if (pincode.isNotEmpty) _chip(pincode),
              ],
            ),
          ],

          // Landmark
          if (landmark.isNotEmpty) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.near_me, size: 14, color: Colors.white.withOpacity(0.5)),
                const SizedBox(width: 6),
                Expanded(
                  child: Text('Near $landmark', style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 12, fontStyle: FontStyle.italic)),
                ),
              ],
            ),
          ],

          // Contact info
          if (phone.isNotEmpty || email.isNotEmpty) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                if (phone.isNotEmpty) ...[
                  Icon(Icons.phone, size: 14, color: Colors.white.withOpacity(0.7)),
                  const SizedBox(width: 4),
                  Text(phone, style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 12, fontWeight: FontWeight.w600)),
                  const SizedBox(width: 16),
                ],
                if (email.isNotEmpty) ...[
                  Icon(Icons.email_outlined, size: 14, color: Colors.white.withOpacity(0.7)),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(email, style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 12), overflow: TextOverflow.ellipsis),
                  ),
                ],
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _chip(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(text, style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 11, fontWeight: FontWeight.w600)),
    );
  }

  // ─── Billing Row ───
  Widget _buildBillingRow(String label, TextEditingController ctrl, {bool isDiscount = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(label, style: const TextStyle(color: Colors.white, fontSize: 14)),
          ),
          Container(
            width: 140,
            height: 42,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.white.withOpacity(0.25)),
            ),
            child: TextField(
              controller: ctrl,
              keyboardType: TextInputType.number,
              textAlign: TextAlign.right,
              style: TextStyle(
                color: isDiscount ? const Color(0xFF66BB6A) : Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
              decoration: InputDecoration(
                prefixText: isDiscount ? ' -₹' : ' ₹',
                prefixStyle: TextStyle(
                  color: isDiscount ? const Color(0xFF66BB6A) : Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
                suffixText: '  ',
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
                border: InputBorder.none,
              ),
              onChanged: (_) => setState(() {}),
            ),
          ),
        ],
      ),
    );
  }
}
