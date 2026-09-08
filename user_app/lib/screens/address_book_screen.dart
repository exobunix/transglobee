import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../core/theme.dart';
import '../core/config.dart';
import '../models/address_model.dart';
import '../services/api_service.dart';

// ─── Address Book Screen ──────────────────────────────────
class AddressBookScreen extends ConsumerStatefulWidget {
  final Function(AddressEntry)? onSelect;
  const AddressBookScreen({super.key, this.onSelect});

  @override
  ConsumerState<AddressBookScreen> createState() => _AddressBookScreenState();
}

class _AddressBookScreenState extends ConsumerState<AddressBookScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final List<AddressEntry> _pickupAddresses = [];
  final List<AddressEntry> _receivedAddresses = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadAddresses();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadAddresses() async {
    setState(() => _isLoading = true);
    try {
      final apiService = ref.read(apiServiceProvider);
      final response = await apiService.get('/user/profile/addresses');
      if (response != null && response['success'] == true) {
        final List list = response['addresses'] ?? [];
        final loaded = list.map((json) => AddressEntry.fromJson(json)).toList();
        setState(() {
          _pickupAddresses.clear();
          _receivedAddresses.clear();
          for (var addr in loaded) {
            if (addr.type == 'pickup') {
              _pickupAddresses.add(addr);
            } else {
              _receivedAddresses.add(addr);
            }
          }
        });
      }
    } catch (e) {
      debugPrint('Error loading saved addresses: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load saved addresses: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showAddressForm({AddressEntry? existing, required String type}) {
    final labelController = TextEditingController(text: existing?.label ?? '');
    final addressController = TextEditingController(text: existing?.fullAddress ?? '');
    final houseController = TextEditingController(text: existing?.houseNumber ?? '');
    final floorController = TextEditingController(text: existing?.floorNumber ?? '');
    final landmarkController = TextEditingController(text: existing?.landmark ?? '');
    final cityController = TextEditingController(text: existing?.city ?? '');
    final districtController = TextEditingController(text: existing?.district ?? '');
    final pincodeController = TextEditingController(text: existing?.pincode ?? '');
    pincodeController.addListener(() async {
      final pin = pincodeController.text.trim();
      if (pin.length == 6 && int.tryParse(pin) != null) {
        try {
          final baseUrl = AppConfig.apiBaseUrl;
          final res = await http.get(Uri.parse('$baseUrl/maps/pincode/$pin'));
          if (res.statusCode == 200) {
            final List list = jsonDecode(res.body);
            if (list.isNotEmpty && list[0]['Status'] == 'Success') {
              final postOffices = list[0]['PostOffice'] as List;
              if (postOffices.isNotEmpty) {
                // Find the main Sub Post Office or Head Post Office if available
                final mainOffice = postOffices.firstWhere(
                  (office) => 
                    office['BranchType']?.toString().toLowerCase() == 'sub post office' ||
                    office['BranchType']?.toString().toLowerCase() == 'head post office',
                  orElse: () => postOffices[0],
                );

                final district = mainOffice['District']?.toString() ?? '';
                final block = mainOffice['Block']?.toString() ?? '';
                final name = mainOffice['Name']?.toString() ?? '';

                String city = name;
                if (mainOffice['BranchType']?.toString().toLowerCase() != 'sub post office' &&
                    mainOffice['BranchType']?.toString().toLowerCase() != 'head post office') {
                  if (block.isNotEmpty && block.toLowerCase() != 'not available') {
                    city = block;
                  }
                }

                if (city.isNotEmpty) {
                  cityController.text = city;
                }
                if (district.isNotEmpty) {
                  districtController.text = district;
                }
              }
            }
          }
        } catch (e) {
          debugPrint('Error fetching city/district from pincode: $e');
        }
      }
    });
    final phoneController = TextEditingController(text: existing?.phone ?? '');
    final emailController = TextEditingController(text: existing?.email ?? '');
    IconData selectedIcon = existing?.icon ?? Icons.location_on_rounded;

    final iconOptions = [
      Icons.home_rounded,
      Icons.work_rounded,
      Icons.location_on_rounded,
      Icons.star_rounded,
      Icons.favorite_rounded,
    ];

    bool isLoading = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(builder: (ctx, setSheet) {
          return Container(
            decoration: BoxDecoration(
              color: context.theme.scaffoldBackgroundColor,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            ),
            padding: EdgeInsets.only(
              top: 24,
              left: 24,
              right: 24,
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 32,
            ),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Handle bar
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  Text(
                    existing == null
                        ? 'Add New ${type == 'pickup' ? 'Pickup' : 'Delivery'} Address'
                        : 'Edit Address',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: context.colors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    type == 'pickup'
                        ? 'Where should we pick up from?'
                        : 'Where should we deliver to?',
                    style: TextStyle(fontSize: 13, color: context.colors.textSecondary),
                  ),
                  const SizedBox(height: 24),

                  // Icon picker
                  _sectionLabel('Choose Icon'),
                  const SizedBox(height: 10),
                  Row(
                    children: iconOptions.map((icon) {
                      final isSelected = selectedIcon == icon;
                      return GestureDetector(
                        onTap: () => setSheet(() => selectedIcon = icon),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          margin: const EdgeInsets.only(right: 10),
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: isSelected
                                ? context.theme.primaryColor
                                : context.theme.cardColor,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: isSelected
                                  ? context.theme.primaryColor
                                  : context.theme.dividerColor.withOpacity(0.2),
                            ),
                          ),
                          child: Icon(icon,
                              color: isSelected ? Colors.white : context.colors.textSecondary,
                              size: 24),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 22),

                  // ── Address Label ──
                  _sectionLabel('Address Label'),
                  const SizedBox(height: 8),
                  _buildField(labelController, 'Label', 'e.g. Home, Office, Warehouse',
                      Icons.label_outline),
                  const SizedBox(height: 16),

                  // ── Contact Information ──
                  _sectionLabel('Contact Information'),
                  const SizedBox(height: 8),
                  _buildField(phoneController, 'Phone Number', '9876543210',
                      Icons.phone_outlined,
                      keyboardType: TextInputType.phone,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(10),
                      ]),
                  const SizedBox(height: 12),
                  _buildField(emailController, 'Email Address', 'example@email.com',
                      Icons.email_outlined,
                      keyboardType: TextInputType.emailAddress),
                  const SizedBox(height: 16),

                  // ── Address Details ──
                  _sectionLabel('Address Details'),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: _buildField(houseController, 'House / Flat No.',
                            'e.g. A-12', Icons.house_outlined),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildField(floorController, 'Floor', 'e.g. 3rd Floor',
                            Icons.layers_outlined),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildField(addressController, 'Full Address',
                      'Street, Area, Locality', Icons.location_on_outlined,
                      maxLines: 2),
                  const SizedBox(height: 12),
                  _buildField(landmarkController, 'Landmark (optional)',
                      'e.g. Near City Mall', Icons.place_outlined),
                  const SizedBox(height: 12),
                  _buildField(pincodeController, 'Pincode', '400001',
                      Icons.pin_drop_outlined,
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(6),
                      ]),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _buildField(
                            cityController, 'City', 'Mumbai', Icons.location_city_outlined),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildField(
                            districtController, 'District', 'Thane', Icons.map_outlined),
                      ),
                    ],
                  ),
                  const SizedBox(height: 28),

                  // Save button
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton(
                      onPressed: isLoading
                          ? null
                          : () async {
                              if (addressController.text.trim().isEmpty ||
                                  cityController.text.trim().isEmpty ||
                                  districtController.text.trim().isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                      content: Text('Please fill address, city and district')),
                                );
                                return;
                              }

                              final pincodeStr = pincodeController.text.trim();
                              if (pincodeStr.length != 6) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                      content: Text('Pincode must be exactly 6 digits')),
                                );
                                return;
                              }

                              final phoneStr = phoneController.text.trim();
                              if (phoneStr.length != 10) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                      content: Text('Phone number must be exactly 10 digits')),
                                );
                                return;
                              }

                              final newEntry = AddressEntry(
                                id: existing?.id ?? '',
                                label: labelController.text.trim().isEmpty
                                    ? (type == 'pickup' ? 'Pickup' : 'Delivery')
                                    : labelController.text.trim(),
                                fullAddress: addressController.text.trim(),
                                houseNumber: houseController.text.trim().isEmpty
                                    ? null
                                    : houseController.text.trim(),
                                floorNumber: floorController.text.trim().isEmpty
                                    ? null
                                    : floorController.text.trim(),
                                landmark: landmarkController.text.trim().isEmpty
                                    ? null
                                    : landmarkController.text.trim(),
                                city: cityController.text.trim(),
                                district: districtController.text.trim().isEmpty
                                    ? null
                                    : districtController.text.trim(),
                                pincode: pincodeController.text.trim(),
                                phone: phoneController.text.trim().isEmpty
                                    ? null
                                    : phoneController.text.trim(),
                                email: emailController.text.trim().isEmpty
                                    ? null
                                    : emailController.text.trim(),
                                type: type,
                                icon: selectedIcon,
                              );

                              setSheet(() {
                                isLoading = true;
                              });

                              try {
                                final apiService = ref.read(apiServiceProvider);
                                if (existing == null) {
                                  await apiService.post('/user/profile/addresses', newEntry.toJson());
                                } else {
                                  await apiService.put('/user/profile/addresses/${existing.id}', newEntry.toJson());
                                }
                                _loadAddresses();
                                if (ctx.mounted) {
                                  Navigator.pop(ctx);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(existing == null ? 'Address saved!' : 'Address updated!'),
                                      backgroundColor: Colors.green,
                                      behavior: SnackBarBehavior.floating,
                                      shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(12)),
                                    ),
                                  );
                                }
                              } catch (e) {
                                debugPrint('Error saving address: $e');
                                if (ctx.mounted) {
                                  ScaffoldMessenger.of(ctx).showSnackBar(
                                    SnackBar(
                                      content: Text('Failed to save address: $e'),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                }
                              } finally {
                                if (ctx.mounted) {
                                  setSheet(() {
                                    isLoading = false;
                                  });
                                }
                              }
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: context.theme.primaryColor,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16)),
                      ),
                      child: isLoading
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.save_rounded, color: Colors.white),
                                const SizedBox(width: 8),
                                Text(
                                  existing == null ? 'Save Address' : 'Update Address',
                                  style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white),
                                ),
                              ],
                            ),
                    ),
                  ),
                ],
              ),
            ),
          );
        });
      },
    );
  }

  Widget _sectionLabel(String text) {
    return Text(
      text,
      style: TextStyle(
        fontWeight: FontWeight.w700,
        fontSize: 13,
        color: context.colors.textPrimary,
        letterSpacing: 0.3,
      ),
    );
  }

  Widget _buildField(
    TextEditingController controller,
    String label,
    String hint,
    IconData icon, {
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
    List<TextInputFormatter>? inputFormatters,
  }) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, size: 20),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
        filled: true,
        fillColor: context.theme.cardColor,
        contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
      ),
    );
  }

  void _deleteAddress(AddressEntry entry) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Delete Address'),
        content: Text('Remove "${entry.label}"?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              try {
                final apiService = ref.read(apiServiceProvider);
                await apiService.delete('/user/profile/addresses/${entry.id}');
                _loadAddresses();
                if (ctx.mounted) {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Address deleted!'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } catch (e) {
                debugPrint('Error deleting address: $e');
                if (ctx.mounted) {
                  ScaffoldMessenger.of(ctx).showSnackBar(
                    SnackBar(
                      content: Text('Failed to delete address: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.theme.scaffoldBackgroundColor,
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, size: 20, color: context.colors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('My Address Book',
            style: TextStyle(
                fontWeight: FontWeight.bold, color: context.colors.textPrimary)),
        centerTitle: true,
        backgroundColor: context.theme.scaffoldBackgroundColor,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: context.theme.primaryColor,
          labelColor: context.theme.primaryColor,
          unselectedLabelColor: context.colors.textSecondary,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          tabs: const [
            Tab(icon: Icon(Icons.upload_rounded), text: 'Pickup'),
            Tab(icon: Icon(Icons.download_rounded), text: 'Received'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildAddressList(_pickupAddresses, 'pickup'),
                _buildAddressList(_receivedAddresses, 'received'),
              ],
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddressForm(
            type: _tabController.index == 0 ? 'pickup' : 'received'),
        backgroundColor: context.theme.primaryColor,
        icon: const Icon(Icons.add_location_alt_rounded, color: Colors.white),
        label: const Text('Add Address',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildAddressList(List<AddressEntry> addresses, String type) {
    if (addresses.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              type == 'pickup' ? Icons.upload_rounded : Icons.download_rounded,
              size: 64,
              color: context.theme.primaryColor.withOpacity(0.3),
            ),
            const SizedBox(height: 16),
            Text(
              'No ${type == 'pickup' ? 'Pickup' : 'Delivery'} Addresses',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: context.colors.textPrimary),
            ),
            const SizedBox(height: 8),
            Text('Tap "Add Address" to save one',
                style: TextStyle(fontSize: 13, color: context.colors.textSecondary)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      itemCount: addresses.length,
      itemBuilder: (_, idx) {
        final addr = addresses[idx];
        return Container(
          margin: const EdgeInsets.only(bottom: 14),
          decoration: BoxDecoration(
            color: context.theme.cardColor,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(18),
            child: InkWell(
              onTap: () => _showAddressForm(existing: addr, type: type),
              borderRadius: BorderRadius.circular(18),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header row
                    Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: context.theme.primaryColor.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Icon(addr.icon,
                              color: context.theme.primaryColor, size: 24),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(addr.label,
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 15,
                                          color: context.colors.textPrimary)),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: (type == 'pickup'
                                              ? Colors.green
                                              : Colors.blue)
                                          .withOpacity(0.12),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      type == 'pickup' ? 'Pickup' : 'Delivery',
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: type == 'pickup'
                                            ? Colors.green
                                            : Colors.blue,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 2),
                              Text('${addr.city} - ${addr.pincode}',
                                  style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: context.theme.primaryColor)),
                            ],
                          ),
                        ),
                        // Edit & Delete buttons
                        Row(
                          children: [
                            IconButton(
                              icon: Icon(Icons.edit_rounded,
                                  size: 18, color: context.theme.primaryColor),
                              onPressed: () =>
                                  _showAddressForm(existing: addr, type: type),
                              tooltip: 'Edit',
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                            ),
                            const SizedBox(width: 12),
                            IconButton(
                              icon: const Icon(Icons.delete_outline_rounded,
                                  size: 18, color: Colors.red),
                              onPressed: () => _deleteAddress(addr),
                              tooltip: 'Delete',
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                            ),
                          ],
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),
                    const Divider(height: 1),
                    const SizedBox(height: 12),

                    if (widget.onSelect != null) ...[
                      SizedBox(
                        width: double.infinity,
                        child: TextButton.icon(
                          onPressed: () {
                            widget.onSelect!(addr);
                            Navigator.pop(context);
                          },
                          icon: const Icon(Icons.check_circle_outline, size: 18),
                          label: const Text('Select this Address',
                              style: TextStyle(fontWeight: FontWeight.bold)),
                          style: TextButton.styleFrom(
                            foregroundColor: context.theme.primaryColor,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            backgroundColor: context.theme.primaryColor.withOpacity(0.08),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],

                    // Address info rows
                    _infoRow(Icons.location_on_outlined, addr.fullAddress),
                    if (addr.houseNumber != null || addr.floorNumber != null)
                      _infoRow(
                        Icons.house_outlined,
                        [
                          if (addr.houseNumber != null)
                            'House/Flat: ${addr.houseNumber}',
                          if (addr.floorNumber != null)
                            'Floor: ${addr.floorNumber}',
                        ].join('  ·  '),
                      ),
                    if (addr.landmark != null)
                      _infoRow(Icons.place_outlined, addr.landmark!),
                    if (addr.phone != null)
                      _infoRow(Icons.phone_outlined, addr.phone!),
                    if (addr.email != null)
                      _infoRow(Icons.email_outlined, addr.email!),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _infoRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 15, color: context.colors.textSecondary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                  fontSize: 13, color: context.colors.textSecondary),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
