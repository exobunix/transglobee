// import 'package:flutter/material.dart';
// import 'package:flutter_riverpod/flutter_riverpod.dart';
// import '../core/theme.dart';
// import '../widgets/leaflet_map.dart';
// import '../providers/logistics_provider.dart';
// import '../providers/logistics_vehicle_provider.dart';
// import 'package:latlong2/latlong.dart';
// import 'package:flutter_map/flutter_map.dart';
// import 'package:http/http.dart' as http;
// import 'dart:convert';
// import 'package:flutter/services.dart';
// import '../core/config.dart';
// import '../services/auth_service.dart';
// import '../services/api_service.dart';
// import 'dart:async';
// import 'address_book_screen.dart';
// import '../models/address_model.dart';
// import 'my_logistics_bookings_screen.dart';
// import '../services/rest_api_repository.dart';
// import '../providers/api_state_providers.dart';


// // ─── Helper cost per person ─────────────────────────────
// const double _helperCostPerPerson = 800.0; // ₹800 per helper

// class _ItemEntry {
//   String name;
//   String type;
//   double length;
//   double height;
//   double width;
//   String unit;
//   Uint8List? imageBytes;
//   String? imageName;
//   String? savedImageUrl; // After ImageKit upload

//   _ItemEntry({
//     required this.name,
//     required this.type,
//     this.length = 0,
//     this.height = 0,
//     this.width = 0,
//     this.unit = 'cm',
//     this.imageBytes,
//     this.imageName,
//     this.savedImageUrl,
//   });
// }

// class LogisticsBookingScreen extends ConsumerStatefulWidget {
//   const LogisticsBookingScreen({super.key});

//   @override
//   ConsumerState<LogisticsBookingScreen> createState() => _LogisticsBookingScreenState();
// }

// class _LogisticsBookingScreenState extends ConsumerState<LogisticsBookingScreen> {
//   // Vehicle
//   String? _selectedVehicle;
//   LogisticsVehicle? _selectedVehicleData;

//   // Goods type
//   String? _selectedGoodType;

//   // Added items list
//   final List<_ItemEntry> _addedItems = [];
//   String _selectedUnit = 'cm';
//   final List<String> _units = ['cm', 'm', 'feet', 'inch'];

//   // Current item form fields
//   final _itemNameController = TextEditingController();
//   final _goodTypeController = TextEditingController();
//   final _lengthController = TextEditingController();
//   final _heightController = TextEditingController();
//   final _widthController = TextEditingController();
//   Uint8List? _currentImageBytes;
//   String? _currentImageName;
//   bool _isAddingItem = false; // loader for "Add Item" button

//   // Helpers
//   int _helperCount = 0; // 0 = no helper, 1/2/3

//   // Location + route
//   Map<String, dynamic>? _pickup;
//   Map<String, dynamic>? _dropoff;
//   List<LatLng> _routePoints = [];
//   double _distance = 0.0;

//   // Coupon
//   String? _appliedCoupon;
//   double _discountAmount = 0.0;

//   // Selected addresses from address book
//   AddressEntry? _selectedPickupAddress;
//   AddressEntry? _selectedDeliveryAddress;

//   // Booking loader
//   bool _isSavingGood = false;

//   // In-page search state
//   final _pickupSearchController = TextEditingController();
//   final _dropoffSearchController = TextEditingController();
//   final _pickupFocusNode = FocusNode();
//   final _dropoffFocusNode = FocusNode();
//   List<Map<String, dynamic>> _searchResults = [];
//   Timer? _debounce;
//   bool _showSuggestions = false;
//   bool _activeSearchingPickup = true;

//   @override
//   void initState() {
//     super.initState();
//     _pickupFocusNode.addListener(_onFocusChanged);
//     _dropoffFocusNode.addListener(_onFocusChanged);
//   }

//   void _onFocusChanged() {
//     if (!mounted) return;
//     setState(() {
//       if (_pickupFocusNode.hasFocus) {
//         _activeSearchingPickup = true;
//         _showSuggestions = true;
//       } else if (_dropoffFocusNode.hasFocus) {
//         _activeSearchingPickup = false;
//         _showSuggestions = true;
//       } else {
//         // Delay hiding suggestions to allow tap events to fire
//         Future.delayed(const Duration(milliseconds: 250), () {
//           if (mounted && !_pickupFocusNode.hasFocus && !_dropoffFocusNode.hasFocus) {
//             setState(() => _showSuggestions = false);
//           }
//         });
//       }
//     });
//   }

//   @override
//   void dispose() {
//     _debounce?.cancel();
//     _pickupSearchController.dispose();
//     _dropoffSearchController.dispose();
//     _pickupFocusNode.removeListener(_onFocusChanged);
//     _dropoffFocusNode.removeListener(_onFocusChanged);
//     _pickupFocusNode.dispose();
//     _dropoffFocusNode.dispose();
//     _itemNameController.dispose();
//     _goodTypeController.dispose();
//     _lengthController.dispose();
//     _heightController.dispose();
//     _widthController.dispose();
//     super.dispose();
//   }

//   Future<Map<String, String>> _authHeaders({bool includeContentType = true}) {
//     return ref.read(authServiceProvider).buildAuthHeaders(
//           includeContentType: includeContentType,
//         );
//   }

//   // ─── Suggestions & Selection ────────────────────────────
//   Future<void> _fetchSuggestions(String query) async {
//     if (query.trim().isEmpty) {
//       if (mounted) {
//         setState(() {
//           _searchResults = [];
//         });
//       }
//       return;
//     }

//     try {
//       final apiKey = AppConfig.googleMapsApiKey;
//       final apiService = ref.read(apiServiceProvider);
//       final response = await apiService.get(
//         '/maps/autocomplete?input=${Uri.encodeComponent(query)}&key=$apiKey&components=country:in',
//       );

//       if (mounted) {
//         final List predictions = (response as Map<String, dynamic>)['predictions'] ?? [];
//         setState(() {
//           _searchResults = predictions
//               .map((item) => {
//                     'name': item['structured_formatting']['main_text'] as String,
//                     'address': item['description'] as String,
//                     'place_id': item['place_id'] as String,
//                   })
//               .toList();
//         });
//       }
//     } catch (e) {
//       // Keep suggestion list unchanged on API failures.
//     }
//   }

//   Future<void> _selectSuggestion(Map<String, dynamic> suggestion, bool isPickup) async {
//     try {
//       final apiKey = AppConfig.googleMapsApiKey;
//       final apiService = ref.read(apiServiceProvider);
//       final response = await apiService.get(
//         '/maps/details?place_id=${suggestion['place_id']}&key=$apiKey&fields=geometry',
//       );
//       final loc = (response as Map<String, dynamic>)['result']['geometry']['location'];
//       final lat = loc['lat'] as double;
//       final lng = loc['lng'] as double;

//       final result = {
//         'name': suggestion['name'],
//         'address': suggestion['address'],
//         'lat': lat,
//         'lng': lng,
//       };

//           if (mounted) {
//             setState(() {
//               _showSuggestions = false;
//               if (isPickup) {
//                 _pickup = result;
//                 _pickupSearchController.text = "${suggestion['name']}, ${suggestion['address']}";
//                 _pickupFocusNode.unfocus();
//               } else {
//                 _dropoff = result;
//                 _dropoffSearchController.text = "${suggestion['name']}, ${suggestion['address']}";
//                 _dropoffFocusNode.unfocus();
//               }
//               _searchResults = [];
//             });
//             _fetchRoute();
//           }
//     } catch (e) {
//       // Keep current selection state on API failures.
//     }
//   }

//   // ─── Price ──────────────────────────────────────────────
//   double get _vehiclePrice {
//     if (_selectedVehicleData == null) return 0.0;
//     // Return base price even if locations aren't selected yet
//     double total = _selectedVehicleData!.basePrice;
//     if (_pickup != null && _dropoff != null) {
//       total += _selectedVehicleData!.pricePerKm * _distance;
//     }
//     // Add cost per piece
//     total += _selectedVehicleData!.pricePerPiece * _addedItems.length;
//     return total;
//   }

//   double get _helperCost => _helperCount * _helperCostPerPerson;

//   double get _totalPrice =>
//       (_vehiclePrice + _helperCost - _discountAmount).clamp(0.0, double.infinity);


//   // ─── Route & distance ───────────────────────────────────
//   Future<void> _fetchRoute() async {
//     if (_pickup == null || _dropoff == null) return;
//     final pLat = _parseDouble(_pickup!['lat']);
//     final pLng = _parseDouble(_pickup!['lng']);
//     final dLat = _parseDouble(_dropoff!['lat']);
//     final dLng = _parseDouble(_dropoff!['lng']);
//     if (pLat == 0 || dLat == 0) return;

//     final url =
//         'https://router.project-osrm.org/route/v1/driving/$pLng,$pLat;$dLng,$dLat?overview=full&geometries=geojson';
//     try {
//       final response = await http.get(Uri.parse(url));
//       if (response.statusCode == 200) {
//         final data = json.decode(response.body);
//         final routes = data['routes'] as List;
//         if (routes.isNotEmpty) {
//           final route = routes[0];
//           final geometry = route['geometry']['coordinates'] as List;
//           final distance = (route['distance'] as num).toDouble() / 1000.0;
//           if (mounted) {
//             setState(() {
//               _distance = distance;
//               _routePoints = geometry
//                   .map((coord) => LatLng(coord[1].toDouble(), coord[0].toDouble()))
//                   .toList();
//             });
//           }
//         }
//       }
//     } catch (e) {
//       debugPrint('Error fetching route: $e');
//     }
//   }

//   String? _validateItemInputs() {
//     final name = _itemNameController.text.trim();
//     final length = double.tryParse(_lengthController.text.trim()) ?? 0;
//     final height = double.tryParse(_heightController.text.trim()) ?? 0;
//     final width = double.tryParse(_widthController.text.trim()) ?? 0;

//     if (_goodTypeController.text.trim().isEmpty) {
//       return 'Please enter a goods type before adding an item';
//     }
//     if (name.length < 2) {
//       return 'Item name must be at least 2 characters';
//     }
//     if (length <= 0 || height <= 0 || width <= 0) {
//       return 'Length, height, and width must all be greater than 0';
//     }

//     return null;
//   }

//   String? _validateBookingInputs() {
//     if (_selectedVehicleData == null) {
//       return 'Please select a vehicle before booking';
//     }
//     if (_pickup == null || _dropoff == null) {
//       return 'Please select both pickup and drop locations on the map';
//     }
//     if ((_pickup?['address']?.toString().trim().toLowerCase() ?? '') ==
//         (_dropoff?['address']?.toString().trim().toLowerCase() ?? '')) {
//       return 'Pickup and drop locations must be different';
//     }
//     if (_addedItems.isEmpty) {
//       return 'Please add at least one item with complete details';
//     }
//     // Require pickup address from address book
//     if (_selectedPickupAddress == null) {
//       return 'Please select a Pickup Address from your address book (tap "Pickup Address" below)';
//     }
//     if (_selectedPickupAddress!.type != 'pickup') {
//       return 'The selected pickup address is not of type "Pickup". Please choose a valid pickup address';
//     }
//     // Require delivery address from address book
//     if (_selectedDeliveryAddress == null) {
//       return 'Please select a Delivery Address from your address book (tap "Delivery Address" below)';
//     }
//     if (_selectedDeliveryAddress!.type != 'received') {
//       return 'The selected delivery address is not of type "Received". Please choose a valid delivery address';
//     }
//     return null;
//   }

//   Map<String, dynamic>? _buildValidatedPickupAddressPayload() {
//     if (_selectedPickupAddress == null || _pickup == null) return null;

//     return {
//       'type': 'pickup',
//       'label': _selectedPickupAddress!.label,
//       'fullAddress': _pickup!['address'],
//       'houseNumber': _selectedPickupAddress!.houseNumber,
//       'floorNumber': _selectedPickupAddress!.floorNumber,
//       'landmark': _selectedPickupAddress!.landmark,
//       'city': _selectedPickupAddress!.city,
//       'pincode': _selectedPickupAddress!.pincode,
//       'phone': _selectedPickupAddress!.phone,
//       'email': _selectedPickupAddress!.email,
//     };
//   }

//   Map<String, dynamic>? _buildValidatedReceivedAddressPayload() {
//     if (_selectedDeliveryAddress == null || _dropoff == null) return null;

//     return {
//       'type': 'received',
//       'label': _selectedDeliveryAddress!.label,
//       'fullAddress': _dropoff!['address'],
//       'houseNumber': _selectedDeliveryAddress!.houseNumber,
//       'floorNumber': _selectedDeliveryAddress!.floorNumber,
//       'landmark': _selectedDeliveryAddress!.landmark,
//       'city': _selectedDeliveryAddress!.city,
//       'pincode': _selectedDeliveryAddress!.pincode,
//       'phone': _selectedDeliveryAddress!.phone,
//       'email': _selectedDeliveryAddress!.email,
//     };
//   }

//   // ─── Add item to list ────────────────────────────────────
//   Future<void> _addItemToList() async {
//     final validationError = _validateItemInputs();
//     if (validationError != null) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text(validationError)),
//       );
//       return;
//     }

//     final name = _itemNameController.text.trim();
//     String goodTypeName = _goodTypeController.text.trim();
//     if (goodTypeName.isEmpty) goodTypeName = 'General';

//     setState(() => _isAddingItem = true);

//     try {
//       // Upload image to ImageKit via backend
//       String? uploadedUrl;
//       if (_currentImageBytes != null && _currentImageName != null) {
//         uploadedUrl = await _uploadImageToImageKit(
//           _currentImageBytes!,
//           _currentImageName!,
//         );
//       }

//       final item = _ItemEntry(
//         name: name,
//         type: goodTypeName,
//         length: double.tryParse(_lengthController.text.trim()) ?? 0,
//         height: double.tryParse(_heightController.text.trim()) ?? 0,
//         width: double.tryParse(_widthController.text.trim()) ?? 0,
//         unit: _selectedUnit,
//         imageBytes: _currentImageBytes,
//         imageName: _currentImageName,
//         savedImageUrl: uploadedUrl,
//       );

//       setState(() {
//         _addedItems.add(item);
//         // Reset form for next item
//         _itemNameController.clear();
//         _lengthController.clear();
//         _heightController.clear();
//         _widthController.clear();
//         _currentImageBytes = null;
//         _currentImageName = null;
//       });

//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: Text('✅ "${item.name}" added! Add more or Book Now.'),
//           backgroundColor: Colors.green,
//           duration: const Duration(seconds: 2),
//         ),
//       );
//     } catch (e) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Error adding item: $e')),
//       );
//     } finally {
//       if (mounted) setState(() => _isAddingItem = false);
//     }
//   }

//   // ─── Upload image to ImageKit via backend ────────────────
//   Future<String?> _uploadImageToImageKit(Uint8List bytes, String fileName) async {
//     final authService = ref.read(authServiceProvider);
//     await authService.waitForSession();
//     final userId = authService.currentUser?.uid as String? ?? 'guest';

//     final uri = Uri.parse('${AppConfig.apiBaseUrl}/api/logistic-goods/upload-image');
//     final request = http.MultipartRequest('POST', uri);
//     request.headers.addAll(await _authHeaders(includeContentType: false));
//     request.fields['userId'] = userId;
//     request.files.add(http.MultipartFile.fromBytes('image', bytes, filename: fileName));

//     final streamed = await request.send();
//     final response = await http.Response.fromStream(streamed);
//     if (response.statusCode == 200 || response.statusCode == 201) {
//       final data = json.decode(response.body);
//       return data['url'] as String?;
//     }
//     debugPrint('ImageKit upload failed: ${response.body}');
//     return null;
//   }

//   // ─── Save all items to DB + book ride ───────────────────
//   Future<void> _saveAllItemsAndBook(String goodTypeName) async {
//     final authService = ref.read(authServiceProvider);
//     await authService.waitForSession();
//     final userId = authService.currentUser?.uid as String? ?? 'guest';
//     final headers = await _authHeaders(includeContentType: false);

//     for (final item in _addedItems) {
//       try {
//         final uri = Uri.parse('${AppConfig.apiBaseUrl}/logistic-goods');
//         final request = http.MultipartRequest('POST', uri);
//         request.headers.addAll(headers);
//         request.fields['userId'] = userId;
//         request.fields['itemName'] = item.name;
//         request.fields['type'] = item.type;
//         request.fields['length'] = item.length.toString();
//         request.fields['height'] = item.height.toString();
//         request.fields['width'] = item.width.toString();
//         request.fields['unit'] = item.unit;
//         if (item.savedImageUrl != null) {
//           request.fields['imageUrl'] = item.savedImageUrl!;
//         }
//         final streamed = await request.send();
//         final resp = await http.Response.fromStream(streamed);
//         debugPrint('Saved item "${item.name}": ${resp.statusCode}');
//       } catch (e) {
//         debugPrint('Error saving item "${item.name}": $e');
//       }
//     }
//   }

//   // ─── POST full logistics booking to MongoDB ───────────
//   Future<String> _saveLogisticsBooking({
//     required String goodTypeName,
//     Map<String, dynamic>? pickupAddress,
//     Map<String, dynamic>? receivedAddress,
//   }) async {
//     final repo = ref.read(restApiRepositoryProvider);
    
//     final payload = {
//       'type': 'logistics',
//       'pickupLocation': {
//         'title':    _pickup!['name'],
//         'address': _pickup!['address'],
//         'latitude':     _parseDouble(_pickup!['lat']),
//         'longitude':     _parseDouble(_pickup!['lng']),
//       },
//       'dropLocation': {
//         'title':    _dropoff!['name'],
//         'address': _dropoff!['address'],
//         'latitude':     _parseDouble(_dropoff!['lat']),
//         'longitude':     _parseDouble(_dropoff!['lng']),
//       },
//       'distance':     _distance,
//       'vehicleType':    _selectedVehicle ?? 'General',
//       'items': _addedItems.map((item) => {
//         'itemName': item.name,
//         'type':     item.type,
//         'length':   item.length,
//         'height':   item.height,
//         'width':    item.width,
//         'unit':     item.unit,
//         'imageUrl': item.savedImageUrl,
//       }).toList(),
//       'helperCount':    _helperCount,
//       'discount': _discountAmount,
//       'fare':     _totalPrice,
//       'couponCode':  _appliedCoupon,
//       'pickupAddressDetails':  pickupAddress,
//       'deliveryAddressDetails': receivedAddress,
//     };

//     final response = await repo.createBooking(payload);

//     if (response.success && response.data != null) {
//       debugPrint('Logistics booking saved: ${response.data!.bookingId}');
//       return response.data!.bookingId;
//     } else {
//       throw Exception(response.message ?? 'Failed to save booking');
//     }
//   }


//   // ─── Build ───────────────────────────────────────────────
//   @override
//   Widget build(BuildContext context) {
//     final typeGoodsAsync = ref.watch(typeGoodsProvider);
//     final vehiclesAsync = ref.watch(logisticsVehiclesProvider);

//     // No auto-selection to keep initial cost zero

//     return Scaffold(
//       backgroundColor: context.theme.scaffoldBackgroundColor,
//       appBar: AppBar(
//         leading: IconButton(
//           icon: Icon(Icons.arrow_back_ios, size: 20, color: context.colors.textPrimary),
//           onPressed: () => Navigator.pop(context),
//         ),
//         title: Text('Book Logistics',
//             style: TextStyle(fontWeight: FontWeight.bold, color: context.colors.textPrimary)),
//         centerTitle: true,
//         backgroundColor: context.theme.scaffoldBackgroundColor,
//         elevation: 0,
//       ),
//       body: Column(
//         children: [
//           Expanded(
//             child: SingleChildScrollView(
//               padding: const EdgeInsets.symmetric(vertical: 0),
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   // ── Map ──────────────────────────────────────────────
//                   SizedBox(
//                     height: 250,
//                     width: double.infinity,
//                     child: LeafletMap(
//                       location: _pickup ?? _dropoff,
//                       polylines: [
//                         if (_routePoints.isNotEmpty)
//                           Polyline(
//                             points: _routePoints,
//                             color: context.theme.primaryColor,
//                             strokeWidth: 5,
//                           ),
//                       ],
//                       markers: [
//                         if (_pickup != null)
//                           Marker(
//                             point: LatLng(
//                                 _parseDouble(_pickup!['lat']), _parseDouble(_pickup!['lng'])),
//                             width: 60,
//                             height: 60,
//                             child: const Icon(Icons.circle, color: Colors.green, size: 24),
//                           ),
//                         if (_dropoff != null)
//                           Marker(
//                             point: LatLng(
//                                 _parseDouble(_dropoff!['lat']), _parseDouble(_dropoff!['lng'])),
//                             width: 60,
//                             height: 60,
//                             child: const Icon(Icons.location_on, color: Colors.red, size: 40),
//                           ),
//                       ],
//                     ),
//                   ),

//                   // ── Location Input ───────────────────────────────────
//                   Container(
//                     margin: const EdgeInsets.all(16),
//                     padding: const EdgeInsets.all(16),
//                     decoration: BoxDecoration(
//                       color: context.theme.cardColor,
//                       borderRadius: BorderRadius.circular(16),
//                     ),
//                     child: Column(
//                       children: [
//                         _buildSearchField(
//                           controller: _pickupSearchController,
//                           focusNode: _pickupFocusNode,
//                           icon: Icons.circle,
//                           iconColor: Colors.green,
//                           label: 'Pickup Location',
//                           hint: 'Search Pickup Location',
//                           isPickup: true,
//                         ),
//                         if (_showSuggestions && _activeSearchingPickup && _searchResults.isNotEmpty)
//                           _buildSuggestionsList(true),
//                         const SizedBox(height: 16),
//                         _buildSearchField(
//                           controller: _dropoffSearchController,
//                           focusNode: _dropoffFocusNode,
//                           icon: Icons.circle,
//                           iconColor: Colors.red,
//                           label: 'Drop Location',
//                           hint: 'Search Drop Location',
//                           isPickup: false,
//                         ),
//                         if (_showSuggestions && !_activeSearchingPickup && _searchResults.isNotEmpty)
//                           _buildSuggestionsList(false),
//                       ],
//                     ),
//                   ),

//                   // ── Vehicle Type ─────────────────────────────────────
//                   Padding(
//                     padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
//                     child: Text('Select Vehicle Type',
//                         style: TextStyle(
//                             fontSize: 18,
//                             fontWeight: FontWeight.bold,
//                             color: context.colors.textPrimary)),
//                   ),
//                   Padding(
//                     padding: const EdgeInsets.symmetric(horizontal: 16),
//                     child: vehiclesAsync.when(
//                       data: (vehicles) => SingleChildScrollView(
//                         scrollDirection: Axis.horizontal,
//                         padding: const EdgeInsets.only(bottom: 8),
//                         child: Row(
//                           children: vehicles.map((vehicle) {
//                             final isSelected = _selectedVehicle == vehicle.name;
//                             return GestureDetector(
//                               onTap: () => setState(() {
//                                 _selectedVehicle = vehicle.name;
//                                 _selectedVehicleData = vehicle;
//                               }),
//                               child: AnimatedContainer(
//                                 duration: const Duration(milliseconds: 200),
//                                 width: 140,
//                                 margin: const EdgeInsets.only(right: 12),
//                                 padding: const EdgeInsets.all(12),
//                                 decoration: BoxDecoration(
//                                   color: isSelected
//                                       ? context.theme.primaryColor.withAlpha(38)
//                                       : context.theme.cardColor,
//                                   borderRadius: BorderRadius.circular(16),
//                                   border: Border.all(
//                                     color: isSelected
//                                         ? context.theme.primaryColor
//                                         : context.theme.dividerColor.withAlpha(25),
//                                     width: isSelected ? 2 : 1,
//                                   ),
//                                 ),
//                                 child: Column(
//                                   children: [
//                                     ClipRRect(
//                                       borderRadius: BorderRadius.circular(8),
//                                       child: Image.network(
//                                         vehicle.imageUrl,
//                                         height: 50,
//                                         width: 50,
//                                         fit: BoxFit.cover,
//                                         errorBuilder: (_, __, ___) =>
//                                             const Icon(Icons.broken_image, size: 50),
//                                       ),
//                                     ),
//                                     const SizedBox(height: 8),
//                                     Text(vehicle.name,
//                                         style: TextStyle(
//                                             fontSize: 12,
//                                             fontWeight: FontWeight.bold,
//                                             color: context.colors.textPrimary),
//                                         textAlign: TextAlign.center,
//                                         maxLines: 1,
//                                         overflow: TextOverflow.ellipsis),
//                                     Text(vehicle.capacity,
//                                         style: TextStyle(
//                                             fontSize: 10,
//                                             color: context.colors.textSecondary)),
//                                     const SizedBox(height: 6),
//                                     Text(
//                                         '₹${vehicle.basePrice.toInt()} + ₹${vehicle.pricePerKm.toInt()}/km + ₹${vehicle.pricePerPiece.toInt()}/pc',
//                                         style: TextStyle(
//                                             fontSize: 9,
//                                             fontWeight: FontWeight.bold,
//                                             color: context.theme.primaryColor)),
//                                   ],
//                                 ),
//                               ),
//                             );
//                           }).toList(),
//                         ),
//                       ),
//                       loading: () => const Center(child: CircularProgressIndicator()),
//                       error: (err, _) => Text('Error: $err'),
//                     ),
//                   ),

//                   // ── Type of Goods ────────────────────────────────────
//                   /*
//                   Padding(
//                     padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
//                     child: Text('Type of Goods',
//                         style: TextStyle(
//                             fontSize: 18,
//                             fontWeight: FontWeight.bold,
//                             color: context.colors.textPrimary)),
//                   ),
//                   Padding(
//                     padding: const EdgeInsets.symmetric(horizontal: 16),
//                     child: typeGoodsAsync.when(
//                       data: (goods) => Column(
//                         children: goods.map((good) {
//                           return RadioListTile<String>(
//                             title: Text(good.name),
//                             value: good.id,
//                             groupValue: _selectedGoodType,
//                             onChanged: (val) => setState(() => _selectedGoodType = val),
//                             contentPadding: EdgeInsets.zero,
//                             activeColor: context.theme.primaryColor,
//                           );
//                         }).toList(),
//                       ),
//                       loading: () => const Center(child: CircularProgressIndicator()),
//                       error: (err, _) => Text('Error loading goods: $err'),
//                     ),
//                   ),
//                   */
//                   Padding(
//                     padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
//                     child: Text('Type of Goods',
//                         style: TextStyle(
//                             fontSize: 18,
//                             fontWeight: FontWeight.bold,
//                             color: context.colors.textPrimary)),
//                   ),
//                   Padding(
//                     padding: const EdgeInsets.symmetric(horizontal: 16),
//                     child: TextField(
//                       controller: _goodTypeController,
//                       decoration: InputDecoration(
//                         hintText: 'Enter type of goods (e.g., Furniture, Electronics)',
//                         hintStyle: TextStyle(color: context.colors.textSecondary),
//                         filled: true,
//                         // fillColor: context.colors.accent,
//                         border: OutlineInputBorder(
//                           borderRadius: BorderRadius.circular(12),
//                           borderSide: BorderSide.none,
//                         ),
//                         contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
//                       ),
//                       style: TextStyle(color: context.colors.textPrimary),
//                     ),
//                   ),

//                   // ── ITEM DETAILS FORM ────────────────────────────────
//                   Padding(
//                     padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
//                     child: Row(
//                       mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                       children: [
//                         Text('Item Details',
//                             style: TextStyle(
//                                 fontSize: 18,
//                                 fontWeight: FontWeight.bold,
//                                 color: context.colors.textPrimary)),
//                         if (_addedItems.isNotEmpty)
//                           Container(
//                             padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
//                             decoration: BoxDecoration(
//                               color: context.theme.primaryColor,
//                               borderRadius: BorderRadius.circular(20),
//                             ),
//                             child: Text(
//                               '${_addedItems.length} item${_addedItems.length > 1 ? 's' : ''} added',
//                               style: const TextStyle(
//                                   color: Colors.white,
//                                   fontSize: 12,
//                                   fontWeight: FontWeight.bold),
//                             ),
//                           ),
//                       ],
//                     ),
//                   ),

//                   // Added items chips
//                   if (_addedItems.isNotEmpty)
//                     Padding(
//                       padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
//                       child: Column(
//                         children: _addedItems.asMap().entries.map((entry) {
//                           final idx = entry.key;
//                           final item = entry.value;
//                           return Container(
//                             margin: const EdgeInsets.only(bottom: 8),
//                             padding: const EdgeInsets.all(12),
//                             decoration: BoxDecoration(
//                               color: context.theme.primaryColor.withAlpha(15),
//                               borderRadius: BorderRadius.circular(12),
//                               border: Border.all(
//                                   color: context.theme.primaryColor.withAlpha(50)),
//                             ),
//                             child: Row(
//                               children: [
//                                 if (item.imageBytes != null)
//                                   ClipRRect(
//                                     borderRadius: BorderRadius.circular(8),
//                                     child: Image.memory(item.imageBytes!,
//                                         width: 48, height: 48, fit: BoxFit.cover),
//                                   )
//                                 else
//                                   Container(
//                                     width: 48,
//                                     height: 48,
//                                     decoration: BoxDecoration(
//                                       color: context.theme.primaryColor.withAlpha(30),
//                                       borderRadius: BorderRadius.circular(8),
//                                     ),
//                                     child: Icon(Icons.inventory_2,
//                                         color: context.theme.primaryColor),
//                                   ),
//                                 const SizedBox(width: 12),
//                                 Expanded(
//                                   child: Column(
//                                     crossAxisAlignment: CrossAxisAlignment.start,
//                                     children: [
//                                       Text(item.name,
//                                           style: TextStyle(
//                                               fontWeight: FontWeight.bold,
//                                               color: context.colors.textPrimary)),
//                                       Text(
//                                           '${item.type} · ${item.length}×${item.height}×${item.width} ${item.unit}',
//                                           style: TextStyle(
//                                               fontSize: 12,
//                                               color: context.colors.textSecondary)),
//                                     ],
//                                   ),
//                                 ),
//                                 IconButton(
//                                   icon: const Icon(Icons.delete_outline, color: Colors.red),
//                                   onPressed: () => setState(() => _addedItems.removeAt(idx)),
//                                 ),
//                               ],
//                             ),
//                           );
//                         }).toList(),
//                       ),
//                     ),

//                   // Item form card
//                   Padding(
//                     padding: const EdgeInsets.symmetric(horizontal: 16),
//                     child: Container(
//                       padding: const EdgeInsets.all(16),
//                       decoration: BoxDecoration(
//                         color: context.theme.cardColor,
//                         borderRadius: BorderRadius.circular(16),
//                         boxShadow: [
//                           BoxShadow(
//                             color: Colors.black.withAlpha(13),
//                             blurRadius: 10,
//                             offset: const Offset(0, 4),
//                           )
//                         ],
//                       ),
//                       child: Column(
//                         crossAxisAlignment: CrossAxisAlignment.start,
//                         children: [
//                           // Item Name
//                           TextField(
//                             controller: _itemNameController,
//                             decoration: InputDecoration(
//                               labelText: 'Item Name',
//                               prefixIcon: const Icon(Icons.inventory_2_outlined),
//                               border: OutlineInputBorder(
//                                   borderRadius: BorderRadius.circular(12)),
//                               filled: true,
//                             ),
//                           ),
//                           const SizedBox(height: 16),

//                           // Dimensions Row
//                           Row(
//                             children: [
//                               Expanded(
//                                 child: TextField(
//                                   controller: _lengthController,
//                                   keyboardType: const TextInputType.numberWithOptions(decimal: true),
//                                   inputFormatters: [
//                                     FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
//                                   ],
//                                   decoration: InputDecoration(
//                                     labelText: 'Length ($_selectedUnit)',
//                                     prefixIcon: const Icon(Icons.straighten),
//                                     border: OutlineInputBorder(
//                                         borderRadius: BorderRadius.circular(12)),
//                                     filled: true,
//                                   ),
//                                 ),
//                               ),
//                               const SizedBox(width: 8),
//                               Expanded(
//                                 child: TextField(
//                                   controller: _heightController,
//                                   keyboardType: const TextInputType.numberWithOptions(decimal: true),
//                                   inputFormatters: [
//                                     FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
//                                   ],
//                                   decoration: InputDecoration(
//                                     labelText: 'Height ($_selectedUnit)',
//                                     prefixIcon: const Icon(Icons.height),
//                                     border: OutlineInputBorder(
//                                         borderRadius: BorderRadius.circular(12)),
//                                     filled: true,
//                                   ),
//                                 ),
//                               ),
//                               const SizedBox(width: 8),
//                               Expanded(
//                                 child: TextField(
//                                   controller: _widthController,
//                                   keyboardType: const TextInputType.numberWithOptions(decimal: true),
//                                   inputFormatters: [
//                                     FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
//                                   ],
//                                   decoration: InputDecoration(
//                                     labelText: 'Width ($_selectedUnit)',
//                                     prefixIcon: const Icon(Icons.width_normal),
//                                     border: OutlineInputBorder(
//                                         borderRadius: BorderRadius.circular(12)),
//                                     filled: true,
//                                   ),
//                                 ),
//                               ),
//                             ],
//                           ),
//                           const SizedBox(height: 16),

//                           // Unit Selection
//                           const Text('Dimension Unit', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
//                           const SizedBox(height: 8),
//                           Row(
//                             children: _units.map((unit) {
//                               final isSelected = _selectedUnit == unit;
//                               return Padding(
//                                 padding: const EdgeInsets.only(right: 8),
//                                 child: ChoiceChip(
//                                   label: Text(unit),
//                                   selected: isSelected,
//                                   onSelected: (selected) {
//                                     if (selected) setState(() => _selectedUnit = unit);
//                                   },
//                                   selectedColor: context.theme.primaryColor.withAlpha(50),
//                                   labelStyle: TextStyle(
//                                     color: isSelected ? context.theme.primaryColor : context.colors.textSecondary,
//                                     fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
//                                   ),
//                                 ),
//                               );
//                             }).toList(),
//                           ),
//                           const SizedBox(height: 16),


//                           // Add Item Button
//                           SizedBox(
//                             width: double.infinity,
//                             child: OutlinedButton.icon(
//                               onPressed: _isAddingItem ? null : _addItemToList,
//                               icon: _isAddingItem
//                                   ? SizedBox(
//                                       width: 18,
//                                       height: 18,
//                                       child: CircularProgressIndicator(
//                                           strokeWidth: 2,
//                                           color: context.theme.primaryColor))
//                                   : Icon(Icons.add_circle_outline,
//                                       color: context.theme.primaryColor),
//                               label: Text(
//                                 _isAddingItem ? 'Saving…' : 'Add Item',
//                                 style: TextStyle(
//                                     color: context.theme.primaryColor,
//                                     fontWeight: FontWeight.bold),
//                               ),
//                               style: OutlinedButton.styleFrom(
//                                 side: BorderSide(color: context.theme.primaryColor),
//                                 padding: const EdgeInsets.symmetric(vertical: 14),
//                                 shape: RoundedRectangleBorder(
//                                     borderRadius: BorderRadius.circular(12)),
//                               ),
//                             ),
//                           ),
//                         ],
//                       ),
//                     ),
//                   ),

//                   // ── HELPER SECTION ───────────────────────────────────
//                   Padding(
//                     padding: const EdgeInsets.fromLTRB(16, 28, 16, 12),
//                     child: Text('Need Helpers?',
//                         style: TextStyle(
//                             fontSize: 18,
//                             fontWeight: FontWeight.bold,
//                             color: context.colors.textPrimary)),
//                   ),
//                   Padding(
//                     padding: const EdgeInsets.symmetric(horizontal: 16),
//                     child: Container(
//                       padding: const EdgeInsets.all(16),
//                       decoration: BoxDecoration(
//                         color: context.theme.cardColor,
//                         borderRadius: BorderRadius.circular(16),
//                         boxShadow: [
//                           BoxShadow(
//                             color: Colors.black.withAlpha(13),
//                             blurRadius: 10,
//                             offset: const Offset(0, 4),
//                           )
//                         ],
//                       ),
//                       child: Column(
//                         crossAxisAlignment: CrossAxisAlignment.start,
//                         children: [
//                           Text(
//                             '₹${_helperCostPerPerson.toInt()} per helper · Loading & unloading assistance',
//                             style: TextStyle(
//                                 fontSize: 13, color: context.colors.textSecondary),
//                           ),
//                           const SizedBox(height: 16),
//                           Row(
//                             mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                             children: [
//                               Text(
//                                 'Number of Helpers',
//                                 style: TextStyle(
//                                     fontSize: 16,
//                                     fontWeight: FontWeight.bold,
//                                     color: context.colors.textPrimary),
//                               ),
//                               Container(
//                                 decoration: BoxDecoration(
//                                   color: context.theme.primaryColor.withAlpha(20),
//                                   borderRadius: BorderRadius.circular(24),
//                                   border: Border.all(
//                                       color: context.theme.primaryColor.withAlpha(50)),
//                                 ),
//                                 child: Row(
//                                   children: [
//                                     IconButton(
//                                       onPressed: _helperCount > 0
//                                           ? () => setState(() => _helperCount--)
//                                           : null,
//                                       icon: const Icon(Icons.remove),
//                                       color: _helperCount > 0 ? context.theme.primaryColor : Colors.grey,
//                                       padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
//                                       constraints: const BoxConstraints(),
//                                     ),
//                                     Text(
//                                       '$_helperCount',
//                                       style: TextStyle(
//                                           fontSize: 18,
//                                           fontWeight: FontWeight.bold,
//                                           color: context.colors.textPrimary),
//                                     ),
//                                     IconButton(
//                                       onPressed: () => setState(() => _helperCount++),
//                                       icon: const Icon(Icons.add),
//                                       color: context.theme.primaryColor,
//                                       padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
//                                       constraints: const BoxConstraints(),
//                                     ),
//                                   ],
//                                 ),
//                               ),
//                             ],
//                           ),
//                           if (_helperCount > 0) ...[
//                             const SizedBox(height: 12),
//                             Container(
//                               padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
//                               decoration: BoxDecoration(
//                                 color: Colors.orange.withAlpha(25),
//                                 borderRadius: BorderRadius.circular(10),
//                               ),
//                               child: Row(
//                                 children: [
//                                   const Icon(Icons.info_outline,
//                                       color: Colors.orange, size: 16),
//                                   const SizedBox(width: 8),
//                                   Text(
//                                     '$_helperCount helper${_helperCount > 1 ? 's' : ''} × ₹${_helperCostPerPerson.toInt()} = ₹${_helperCost.toInt()}',
//                                     style: const TextStyle(
//                                         color: Colors.orange,
//                                         fontWeight: FontWeight.w600,
//                                         fontSize: 13),
//                                   ),
//                                 ],
//                               ),
//                             ),
//                           ],
//                         ],
//                       ),
//                     ),
//                   ),

//                   // ── Pickup Address Selector ──────────────────────────────
//                   Padding(
//                     padding: const EdgeInsets.fromLTRB(16, 28, 16, 8),
//                     child: _buildAddressSelector(
//                       title: 'Pickup Address',
//                       subtitle: 'Select saved home/office address',
//                       selected: _selectedPickupAddress,
//                       onTap: () => Navigator.push(
//                         context,
//                         MaterialPageRoute(
//                           builder: (_) => AddressBookScreen(
//                             onSelect: (addr) => setState(() => _selectedPickupAddress = addr),
//                           ),
//                         ),
//                       ),
//                     ),
//                   ),

//                   // ── Delivery Address Selector ──────────────────────────────
//                   Padding(
//                     padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
//                     child: _buildAddressSelector(
//                       title: 'Delivery Address',
//                       subtitle: 'Select saved destination address',
//                       selected: _selectedDeliveryAddress,
//                       onTap: () => Navigator.push(
//                         context,
//                         MaterialPageRoute(
//                           builder: (_) => AddressBookScreen(
//                             onSelect: (addr) => setState(() => _selectedDeliveryAddress = addr),
//                           ),
//                         ),
//                       ),
//                     ),
//                   ),

//                   const SizedBox(height: 120),
//                 ],
//               ),
//             ),
//           ),

//           // ── Footer ──────────────────────────────────────────
//           Container(
//             padding: const EdgeInsets.all(20),
//             decoration: BoxDecoration(
//               color: context.theme.cardColor,
//               borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
//               boxShadow: [
//                 BoxShadow(
//                   color: Colors.black.withAlpha(77),
//                   blurRadius: 25,
//                   offset: const Offset(0, -10),
//                 )
//               ],
//             ),
//             child: SafeArea(
//               child: Column(
//                 mainAxisSize: MainAxisSize.min,
//                 children: [
//                   Row(
//                     mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                     children: [
//                       Column(
//                         crossAxisAlignment: CrossAxisAlignment.start,
//                         children: [
//                           Text('Estimated Total',
//                               style: TextStyle(
//                                   color: context.colors.textSecondary, fontSize: 12)),
//                           if (_distance > 0)
//                             Text('Distance: ${_distance.toStringAsFixed(1)} km',
//                                 style: TextStyle(
//                                     color: context.colors.textSecondary, fontSize: 12)),
//                           Text('₹${_totalPrice.toInt()}',
//                               style: TextStyle(
//                                   fontSize: 28,
//                                   fontWeight: FontWeight.bold,
//                                   color: context.colors.textPrimary)),
//                           // Breakdown
//                           Column(
//                             crossAxisAlignment: CrossAxisAlignment.start,
//                             children: [
//                               if (_selectedVehicleData != null)
//                                 Text(
//                                     'Vehicle: ₹${(_selectedVehicleData!.basePrice + _selectedVehicleData!.pricePerKm * _distance).toInt()}',
//                                     style: TextStyle(
//                                         fontSize: 11,
//                                         color: context.colors.textSecondary)),
//                               if (_addedItems.isNotEmpty && _selectedVehicleData != null)
//                                 Text(
//                                     'Items (${_addedItems.length}): +₹${(_selectedVehicleData!.pricePerPiece * _addedItems.length).toInt()}',
//                                     style: const TextStyle(
//                                         fontSize: 11, color: Colors.blueAccent)),
//                               if (_helperCount > 0)
//                                 Text(
//                                     'Helpers ($_helperCount): +₹${_helperCost.toInt()}',
//                                     style: const TextStyle(
//                                         fontSize: 11, color: Colors.orange)),
//                               if (_discountAmount > 0)
//                                 Text('Discount: -₹${_discountAmount.toInt()}',
//                                     style: const TextStyle(
//                                         fontSize: 11, color: Colors.green)),
//                             ],
//                           ),
//                         ],
//                       ),
//                       Column(
//                         crossAxisAlignment: CrossAxisAlignment.end,
//                         children: [
//                           if (_appliedCoupon != null)
//                             Container(
//                               padding: const EdgeInsets.symmetric(
//                                   horizontal: 8, vertical: 4),
//                               decoration: BoxDecoration(
//                                 color: Colors.green.withAlpha(25),
//                                 borderRadius: BorderRadius.circular(8),
//                               ),
//                               child: Text(
//                                 'Coupon: $_appliedCoupon (-₹${_discountAmount.toInt()})',
//                                 style: const TextStyle(
//                                     color: Colors.green,
//                                     fontSize: 10,
//                                     fontWeight: FontWeight.bold),
//                               ),
//                             ),
//                           TextButton.icon(
//                             onPressed: _showCouponBottomSheet,
//                             icon: Icon(
//                               _appliedCoupon != null
//                                   ? Icons.check_circle
//                                   : Icons.confirmation_num_outlined,
//                               color: _appliedCoupon != null
//                                   ? Colors.green
//                                   : context.theme.primaryColor,
//                               size: 18,
//                             ),
//                             label: Text(
//                               _appliedCoupon != null ? 'Change Coupon' : 'Apply Coupon',
//                               style: TextStyle(
//                                 color: _appliedCoupon != null
//                                     ? Colors.green
//                                     : context.theme.primaryColor,
//                                 fontWeight: FontWeight.bold,
//                               ),
//                             ),
//                           ),
//                         ],
//                       ),
//                     ],
//                   ),
//                   const SizedBox(height: 12),
//                   ElevatedButton(
//                     onPressed: (_pickup != null &&
//                             _dropoff != null &&
//                             _addedItems.isNotEmpty)
//                         ? () async {
//                             final bookingValidationError = _validateBookingInputs();
//                             if (bookingValidationError != null) {
//                               ScaffoldMessenger.of(context).showSnackBar(
//                                 SnackBar(content: Text(bookingValidationError)),
//                               );
//                               return;
//                             }

//                             String goodTypeName = _goodTypeController.text.trim();
//                             if (goodTypeName.isEmpty) goodTypeName = 'General';

//                             try {
//                               setState(() => _isSavingGood = true);
//                               if (!mounted) return;
//                               showDialog(
//                                 context: context,
//                                 barrierDismissible: false,
//                                 builder: (ctx) =>
//                                     const Center(child: CircularProgressIndicator()),
//                               );

//                               await _saveAllItemsAndBook(goodTypeName);

//                               // Save the full booking to MongoDB
//                               await _saveLogisticsBooking(
//                                 goodTypeName: goodTypeName,
//                                 pickupAddress: _buildValidatedPickupAddressPayload(),
//                                 receivedAddress: _buildValidatedReceivedAddressPayload(),
//                               );

//                               if (mounted) {
//                                 Navigator.pop(context); // Close the loading dialog
                                
//                                 // Show success snackbar
//                                 ScaffoldMessenger.of(context).showSnackBar(
//                                   const SnackBar(
//                                     content: Text('🎉 Logistics booking successful! Redirecting to your bookings...'),
//                                     backgroundColor: Colors.green,
//                                     duration: Duration(seconds: 3),
//                                   ),
//                                 );

//                                 // Wait for 3 seconds as requested
//                                 await Future.delayed(const Duration(seconds: 3));

//                                 if (mounted) {
//                                   Navigator.pushReplacement(
//                                     context,
//                                     MaterialPageRoute(
//                                       builder: (context) => const MyLogisticsBookingsScreen(),
//                                     ),
//                                   );
//                                 }
//                               }
//                             } catch (e) {
//                               if (mounted) {
//                                 Navigator.pop(context);
//                                 ScaffoldMessenger.of(context).showSnackBar(
//                                   SnackBar(content: Text('Booking failed: $e')),
//                                 );
//                               }
//                             } finally {
//                               if (mounted) setState(() => _isSavingGood = false);
//                             }
//                           }
//                         : null,
//                     style: ElevatedButton.styleFrom(
//                       backgroundColor: context.theme.primaryColor,
//                       foregroundColor: Colors.white,
//                       disabledBackgroundColor: Colors.grey,
//                       minimumSize: const Size(double.infinity, 56),
//                       shape: RoundedRectangleBorder(
//                           borderRadius: BorderRadius.circular(16)),
//                       elevation: 0,
//                     ),
//                     child: _isSavingGood
//                         ? const SizedBox(
//                             height: 24,
//                             width: 24,
//                             child: CircularProgressIndicator(
//                                 color: Colors.white, strokeWidth: 2.5),
//                           )
//                         : Text(
//                             _addedItems.isEmpty
//                                 ? 'Add at least 1 item to book'
//                                 : 'Book ${_selectedVehicle ?? ''} · ${_addedItems.length} item${_addedItems.length > 1 ? 's' : ''}',
//                             style: const TextStyle(
//                                 fontSize: 16, fontWeight: FontWeight.bold),
//                           ),
//                   ),
//                 ],
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   // ─── Helpers ─────────────────────────────────────────────
//   double _parseDouble(dynamic val) {
//     if (val == null) return 0.0;
//     if (val is num) return val.toDouble();
//     if (val is String) return double.tryParse(val) ?? 0.0;
//     return 0.0;
//   }

//   Widget _buildSearchField({
//     required TextEditingController controller,
//     required FocusNode focusNode,
//     required IconData icon,
//     required Color iconColor,
//     required String label,
//     required String hint,
//     required bool isPickup,
//   }) {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Row(
//           children: [
//             Icon(icon, color: iconColor, size: 12),
//             const SizedBox(width: 16),
//             Expanded(
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Text(label, style: TextStyle(fontSize: 11, color: context.colors.textSecondary ?? Colors.grey)),
//                   TextField(
//                     controller: controller,
//                     focusNode: focusNode,
//                     onChanged: (val) {
//                       if (_debounce?.isActive ?? false) _debounce!.cancel();
//                       _debounce = Timer(const Duration(milliseconds: 500), () => _fetchSuggestions(val));
//                     },
//                     decoration: InputDecoration(
//                       hintText: hint,
//                       hintStyle: TextStyle(fontSize: 14, color: (context.colors.textSecondary ?? Colors.grey).withAlpha(100)),
//                       border: InputBorder.none,
//                       enabledBorder: InputBorder.none,
//                       focusedBorder: InputBorder.none,
//                       errorBorder: InputBorder.none,
//                       disabledBorder: InputBorder.none,
//                       focusedErrorBorder: InputBorder.none,
//                       isDense: true,
//                       contentPadding: const EdgeInsets.symmetric(vertical: 4),
//                     ),
//                     style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: context.colors.textPrimary ?? Colors.black),
//                   ),
//                 ],
//               ),
//             ),
//             if (controller.text.isNotEmpty)
//               IconButton(
//                 icon: const Icon(Icons.close, size: 18),
//                 onPressed: () {
//                   controller.clear();
//                   if (isPickup) {
//                     _pickup = null;
//                   } else {
//                     _dropoff = null;
//                   }
//                   setState(() => _searchResults = []);
//                 },
//               )
//             else
//               Icon(Icons.chevron_right, color: context.colors.textSecondary, size: 20),
//           ],
//         ),
//       ],
//     );
//   }

//   Widget _buildSuggestionsList(bool isPickup) {
//     return Container(
//       constraints: const BoxConstraints(maxHeight: 200),
//       child: ListView.separated(
//         shrinkWrap: true,
//         padding: const EdgeInsets.symmetric(vertical: 8),
//         itemCount: _searchResults.length,
//         separatorBuilder: (context, index) => const Divider(height: 1),
//         itemBuilder: (context, index) {
//           final suggestion = _searchResults[index];
//           return ListTile(
//             leading: const Icon(Icons.location_on_outlined, size: 20),
//             title: Text(suggestion['name'], style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
//             subtitle: Text(suggestion['address'], style: const TextStyle(fontSize: 12), maxLines: 1, overflow: TextOverflow.ellipsis),
//             onTap: () => _selectSuggestion(suggestion, isPickup),
//           );
//         },
//       ),
//     );
//   }


//   double _calculateCouponDiscount(String code, String description, double basePrice) {
//     final upperCode = code.toUpperCase();
//     final upperDesc = description.toUpperCase();

//     // 1. Try to find percentage
//     double? percentage;
//     final pctRegExp = RegExp(r'(\d+)\s*%');
//     final pctMatch = pctRegExp.firstMatch(upperDesc) ?? pctRegExp.firstMatch(upperCode);
//     if (pctMatch != null) {
//       percentage = double.tryParse(pctMatch.group(1) ?? '');
//     }

//     // 2. Try to find max/up-to discount or flat discount amount
//     double? limitAmount;
//     final rupeeRegExp = RegExp(r'(?:₹|RS\.?|UP\s*TO\s*₹?|SAVE\s*₹?)\s*(\d+)', caseSensitive: false);
//     final matches = rupeeRegExp.allMatches(upperDesc);
//     if (matches.isNotEmpty) {
//       final upToRegExp = RegExp(r'(?:UP\s*TO|MAX|MAXIMUM)\s*(?:₹|RS\.?)?\s*(\d+)', caseSensitive: false);
//       final upToMatch = upToRegExp.firstMatch(upperDesc);
//       if (upToMatch != null) {
//         limitAmount = double.tryParse(upToMatch.group(1) ?? '');
//       } else {
//         limitAmount = double.tryParse(matches.first.group(1) ?? '');
//       }
//     }

//     if (limitAmount == null) {
//       final genericNumberRegExp = RegExp(r'(\d+)');
//       final genericMatches = genericNumberRegExp.allMatches(upperDesc);
//       for (final match in genericMatches) {
//         final val = double.tryParse(match.group(1) ?? '');
//         if (val != null) {
//           if (percentage != null && val == percentage) {
//             continue;
//           }
//           limitAmount = val;
//           break;
//         }
//       }
//     }

//     if (limitAmount == null) {
//       final codeNumRegExp = RegExp(r'(\d+)');
//       final codeMatch = codeNumRegExp.firstMatch(upperCode);
//       if (codeMatch != null) {
//         final codeVal = double.tryParse(codeMatch.group(1) ?? '');
//         if (codeVal != null) {
//           if (upperCode.contains('PCT') || upperCode.contains('PERCENT') || upperCode.contains('OFF') && codeVal <= 100) {
//             percentage = codeVal;
//           } else {
//             limitAmount = codeVal;
//           }
//         }
//       }
//     }

//     if (percentage == null && limitAmount == null) {
//       return 50.0;
//     }

//     if (percentage != null) {
//       final calcDiscount = basePrice * (percentage / 100.0);
//       if (limitAmount != null) {
//         return calcDiscount > limitAmount ? limitAmount : calcDiscount;
//       }
//       return calcDiscount;
//     }

//     return limitAmount ?? 50.0;
//   }

//   void _showCouponBottomSheet() {
//     showModalBottomSheet(
//       context: context,
//       backgroundColor: Colors.transparent,
//       isScrollControlled: true,
//       builder: (ctx) => Consumer(
//         builder: (context, ref, child) {
//           final couponsAsync = ref.watch(couponsProvider);

//           return Container(
//             decoration: BoxDecoration(
//               color: context.theme.scaffoldBackgroundColor,
//               borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
//             ),
//             padding: EdgeInsets.only(
//               left: 24,
//               right: 24,
//               top: 24,
//               bottom: 24 + MediaQuery.of(context).viewInsets.bottom,
//             ),
//             child: Column(
//               mainAxisSize: MainAxisSize.min,
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Row(
//                   mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                   children: [
//                     Text('Available Coupons',
//                         style: TextStyle(
//                             fontSize: 20,
//                             fontWeight: FontWeight.bold,
//                             color: context.colors.textPrimary)),
//                     if (_appliedCoupon != null)
//                       TextButton(
//                         onPressed: () {
//                           setState(() {
//                             _appliedCoupon = null;
//                             _discountAmount = 0.0;
//                           });
//                           Navigator.pop(ctx);
//                         },
//                         child: const Text('Remove', style: TextStyle(color: Colors.red)),
//                       ),
//                   ],
//                 ),
//                 const SizedBox(height: 16),
//                 couponsAsync.when(
//                   data: (coupons) {
//                     final activeCoupons = coupons.where((c) {
//                       final val = c['value'];
//                       if (val == null) return false;
//                       final status = val['status']?.toString().toLowerCase() ?? 'active';
//                       return status == 'active';
//                     }).toList();

//                     if (activeCoupons.isEmpty) {
//                       return Padding(
//                         padding: const EdgeInsets.symmetric(vertical: 24.0),
//                         child: Center(
//                           child: Text(
//                             'No coupons available at the moment.',
//                             style: TextStyle(color: context.colors.textSecondary),
//                           ),
//                         ),
//                       );
//                     }

//                     return ConstrainedBox(
//                       constraints: BoxConstraints(
//                         maxHeight: MediaQuery.of(context).size.height * 0.4,
//                       ),
//                       child: ListView.builder(
//                         shrinkWrap: true,
//                         itemCount: activeCoupons.length,
//                         itemBuilder: (context, index) {
//                           final c = activeCoupons[index];
//                           final val = c['value'] ?? {};
//                           final code = (val['title'] ?? c['key'] ?? '').toString();
//                           final desc = (val['description'] ?? '').toString();
//                           final discount = _calculateCouponDiscount(code, desc, _vehiclePrice + _helperCost);

//                           return _buildCouponItem(code, desc, discount);
//                         },
//                       ),
//                     );
//                   },
//                   loading: () => const Center(
//                     child: Padding(
//                       padding: EdgeInsets.all(24.0),
//                       child: CircularProgressIndicator(),
//                     ),
//                   ),
//                   error: (err, stack) => Center(
//                     child: Padding(
//                       padding: const EdgeInsets.all(24.0),
//                       child: Text('Failed to load coupons: $err',
//                           style: const TextStyle(color: Colors.red)),
//                     ),
//                   ),
//                 ),
//                 const SizedBox(height: 24),
//               ],
//             ),
//           );
//         },
//       ),
//     );
//   }

//   Widget _buildCouponItem(String code, String desc, double discount) {
//     return ListTile(
//       contentPadding: EdgeInsets.zero,
//       leading: Container(
//         padding: const EdgeInsets.all(8),
//         decoration: BoxDecoration(
//           color: context.theme.primaryColor.withAlpha(25),
//           borderRadius: BorderRadius.circular(8),
//         ),
//         child: Icon(Icons.confirmation_number, color: context.theme.primaryColor),
//       ),
//       title: Text(code, style: const TextStyle(fontWeight: FontWeight.bold)),
//       subtitle: Text(desc),
//       trailing: ElevatedButton(
//         onPressed: () {
//           setState(() {
//             _appliedCoupon = code;
//             _discountAmount = discount;
//           });
//           Navigator.pop(context);
//         },
//         style: ElevatedButton.styleFrom(
//           backgroundColor: context.theme.primaryColor,
//           foregroundColor: Colors.white,
//           shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
//         ),
//         child: const Text('Apply'),
//       ),
//     );
//   }

//   Widget _buildAddressSelector({
//     required String title,
//     required String subtitle,
//     required AddressEntry? selected,
//     required VoidCallback onTap,
//   }) {
//     return GestureDetector(
//       onTap: onTap,
//       child: Container(
//         padding: const EdgeInsets.all(18),
//         decoration: BoxDecoration(
//           color: context.theme.cardColor,
//           borderRadius: BorderRadius.circular(18),
//           border: Border.all(
//             color: selected != null 
//                 ? context.theme.primaryColor 
//                 : context.theme.primaryColor.withOpacity(0.3),
//             width: selected != null ? 2.0 : 1.5,
//           ),
//           boxShadow: [
//             BoxShadow(
//               color: Colors.black.withOpacity(0.05),
//               blurRadius: 10,
//               offset: const Offset(0, 4),
//             ),
//           ],
//         ),
//         child: Row(
//           children: [
//             Container(
//               width: 48,
//               height: 48,
//               decoration: BoxDecoration(
//                 color: context.theme.primaryColor.withOpacity(0.12),
//                 borderRadius: BorderRadius.circular(14),
//               ),
//               child: Icon(
//                 selected?.icon ?? Icons.location_on_rounded,
//                 color: context.theme.primaryColor,
//                 size: 26,
//               ),
//             ),
//             const SizedBox(width: 16),
//             Expanded(
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Text(
//                     selected?.label ?? title,
//                     style: TextStyle(
//                       fontSize: 16,
//                       fontWeight: FontWeight.bold,
//                       color: context.colors.textPrimary,
//                     ),
//                   ),
//                   const SizedBox(height: 3),
//                   Text(
//                     selected?.fullAddress ?? subtitle,
//                     style: TextStyle(
//                       fontSize: 12,
//                       color: context.colors.textSecondary,
//                     ),
//                     maxLines: 1,
//                     overflow: TextOverflow.ellipsis,
//                   ),
//                 ],
//               ),
//             ),
//             Icon(
//               selected != null ? Icons.check_circle_rounded : Icons.arrow_forward_ios_rounded,
//               size: 20,
//               color: context.theme.primaryColor,
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }
