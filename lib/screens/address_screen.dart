import '../utils/city_line_parser.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../providers/cart_provider.dart';
import '../providers/order_provider.dart';
import '../models/order_model.dart';
import '../services/api_service.dart';
import '../features/category_nav/repositories/category_repository.dart';
import 'order_screen.dart';
import 'location_picker_screen.dart';
import '../services/nominatim_service.dart';

class AddressScreen extends StatefulWidget {
  final List<Map<String, dynamic>> items;
  final int totalAmount;
  final String? couponCode;

  const AddressScreen({
    super.key,
    required this.items,
    required this.totalAmount,
    this.couponCode,
  });

  @override
  State<AddressScreen> createState() => _AddressScreenState();
}

class _AddressScreenState extends State<AddressScreen> {
  int _selectedAddress = 0;
  late Razorpay _razorpay;
  bool _isLoading = false;
  int? _currentOrderId;
  String _paymentMethod = 'online'; // 'online' or 'cod'
  final bool _useWallet = false;

  List<Map<String, dynamic>> _addresses = [];

  @override
  void initState() {
    super.initState();
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
    _loadCachedAddressesThenRefresh();
  }

  // Show whatever we saved locally last time immediately (no network wait,
  // no empty-state flash), then quietly refresh from the backend in the
  // background and update the list if anything changed.
  Future<void> _loadCachedAddressesThenRefresh() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cached = prefs.getString('saved_addresses');
      if (cached != null) {
        final List<dynamic> decoded = jsonDecode(cached);
        final cachedList = decoded.map<Map<String, dynamic>>((e) {
          final map = Map<String, dynamic>.from(e);
          map['icon'] = _iconFromType(map['type'] ?? 'Home');
          return map;
        }).toList();
        if (cachedList.isNotEmpty && mounted) {
          setState(() {
            _addresses = cachedList;
          });
        }
      }
    } catch (_) {
      // Ignore cache errors - the backend fetch below is the source of truth.
    }
    _loadAddresses();
  }

  @override
  void dispose() {
    _razorpay.clear();
    super.dispose();
  }

  // Addresses are user-specific and live on the backend (tied to the
  // logged-in account's JWT). We fetch them fresh on every load instead of
  // trusting local device storage, so a new login on any device never shows
  // a previous user's (or a stale dummy) address.
  Future<void> _loadAddresses() async {
    try {
      final backendAddresses = await ApiService.getAddresses();
      if (_syncInFlight.isNotEmpty) return;
      if (!mounted) return;
      setState(() {
        _addresses = backendAddresses.map<Map<String, dynamic>>((a) {
          final map = Map<String, dynamic>.from(a);
          final cityLine = [
            map['city'],
            map['state'],
            map['pincode'],
          ].where((v) => v != null && v.toString().isNotEmpty).join(', ');
          return {
            'type': map['label'] ?? 'Home',
            'icon': _iconFromType(map['label'] ?? 'Home'),
            'name': map['full_name'] ?? '',
            'address': map['line1'] ?? '',
            'building': map['line2'] ?? '',
            'city': cityLine,
            'phone': map['phone'] ?? '',
            'lat': map['lat'],
            'lng': map['lng'],
            'backend_id': map['id'],
          };
        }).toList();
        if (_addresses.isNotEmpty) {
          if (_selectedAddress >= _addresses.length) _selectedAddress = 0;
          final sel = _addresses[_selectedAddress];
          final lat = (sel['lat'] as num?)?.toDouble();
          final lng = (sel['lng'] as num?)?.toDouble();
          CategoryRepository.updateLocation(lat, lng);
        }
      });
      _saveAddresses();
    } catch (e) {
      if (!mounted) return;
      // Network/auth error: show an empty list rather than any cached or
      // placeholder data, so we never risk showing someone else's address.
      setState(() {
        _addresses = [];
      });
    }
  }

  Future<void> _saveAddresses() async {
    final prefs = await SharedPreferences.getInstance();
    final List<Map<String, dynamic>> toSave = _addresses.map((e) {
      final map = Map<String, dynamic>.from(e);
      map.remove('icon');
      return map;
    }).toList();
    await prefs.setString('saved_addresses', jsonEncode(toSave));
  }

  IconData _iconFromType(String type) {
    switch (type) {
      case 'Home':
        return Icons.home_outlined;
      case 'Office':
        return Icons.work_outline;
      default:
        return Icons.location_on_outlined;
    }
  }

  // Creates (or re-creates) this local address as a real backend Address
  // row so checkout has an address_id to work with. Stores the returned
  // id back onto the local entry.
  final Map<Map<String, dynamic>, Future<int?>> _syncInFlight = {};

  // One sync per address at a time, keyed by the address map itself (not its
  // list index, which shifts on delete), so checkout can't create a duplicate
  // of an address that a background save is still syncing.
  Future<int?> _syncAddressToBackend(int index) {
    final addr = _addresses[index];
    final running = _syncInFlight[addr];
    if (running != null) return running;
    final f = _doSyncAddress(addr, index == 0).whenComplete(() {
      _syncInFlight.remove(addr);
    });
    _syncInFlight[addr] = f;
    return f;
  }

  bool _savingAddress = false;

  Future<int?> _doSyncAddress(Map<String, dynamic> addr, bool isDefault) async {
    final phoneDigits = (addr['phone'] ?? '').toString().replaceAll(
      RegExp(r'[^0-9]'),
      '',
    );
    final phone10 = phoneDigits.length >= 10
        ? phoneDigits.substring(phoneDigits.length - 10)
        : phoneDigits.padLeft(10, '0');

    final cityRaw = (addr['city'] ?? '').toString();
    final parsed = parseCityLine(cityRaw);
    final city = parsed.city;
    final state = parsed.state;
    final pincode = parsed.pincode;

    try {
      final payload = {
        'label': addr['type'] ?? 'Home',
        'full_name': addr['name'] ?? '',
        'phone': phone10,
        'line1': addr['address'] ?? '',
        'line2': (addr['building'] ?? '').toString().trim(),
        'city': city.isEmpty ? 'NA' : city,
        'state': state.isEmpty ? 'NA' : state,
        'pincode': pincode,
        'lat': addr['lat'],
        'lng': addr['lng'],
        'is_default': isDefault,
      };
      final existingBackendId = addr['backend_id'];
      final result = existingBackendId != null
          ? await ApiService.updateAddress(
              existingBackendId.toString(),
              payload,
            )
          : await ApiService.createAddress(payload);
      final id = result['id'] ?? existingBackendId;
      if (id != null) {
        if (mounted) {
          setState(() {
            addr['backend_id'] = id;
          });
        }
        _saveAddresses();
      }
      return id;
    } catch (e) {
      return null;
    }
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );
    try {
      if (_currentOrderId == null) throw Exception('Missing order reference');
      await ApiService.verifyPayment(
        orderId: _currentOrderId!,
        razorpayOrderId: response.orderId ?? '',
        razorpayPaymentId: response.paymentId ?? '',
        razorpaySignature: response.signature ?? '',
      );
      if (!mounted) return;
      await context.read<CartProvider>().loadCart();
      if (!mounted) return;
      await context.read<OrderProvider>().loadOrders(
        OrderStatus.active,
        refresh: true,
      );
      if (!mounted) return;
      Navigator.of(context, rootNavigator: true).pop();
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const OrderScreen()),
      );
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Payment Successful! Order Placed \u{1F389}',
            style: GoogleFonts.poppins(),
          ),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (mounted) {
        Navigator.of(context, rootNavigator: true).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e', style: GoogleFonts.poppins()),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Payment Failed: ${response.message}',
          style: GoogleFonts.poppins(),
        ),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'External Wallet: ${response.walletName}',
          style: GoogleFonts.poppins(),
        ),
        backgroundColor: Colors.blue,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // Places the order with the currently selected address + payment method.
  // For 'cod' this is the whole flow (no Razorpay). For 'online' this
  // creates the order then opens Razorpay checkout.
  void _placeOrder() async {
    // A previous online-payment attempt may have already created a real
    // order and consumed the cart server-side, then the payment itself
    // failed (cancelled, network drop, etc). Trying to checkout again
    // here would hit an empty cart. If we already have a pending order,
    // retry Razorpay if still on "online"; if switched to "cod", the
    // order is already placed either way - just open it.
    if (_currentOrderId != null) {
      if (_paymentMethod != 'online') {
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const OrderScreen()),
          );
        }
        return;
      }
      setState(() => _isLoading = true);
      try {
        final orderData = await ApiService.createPaymentOrder(_currentOrderId!);
        if (!mounted) return;
        setState(() => _isLoading = false);
        _openRazorpayCheckout(orderData);
      } catch (e) {
        if (mounted) {
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Could not retry payment: $e')),
          );
        }
      }
      return;
    }
    // Some catalog items (shown via the Categories tab's mock filler
    // products) never sync to the backend cart - they only live in
    // CartProvider.localCartItems. If the cart total shown to the user is
    // made up entirely of these, checkout would silently fail with a
    // confusing backend "cart is empty" error since nothing was ever
    // actually added server-side. Catch that here with a clear message.
    final cart = context.read<CartProvider>();
    if (cart.items.isEmpty && cart.localCartItems.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Some items in your cart aren\'t available for purchase yet. Please remove them and add different products.',
          ),
        ),
      );
      return;
    }
    setState(() => _isLoading = true);
    try {
      int? addressId = _addresses[_selectedAddress]['backend_id'];
      addressId ??= await _syncAddressToBackend(_selectedAddress);
      if (addressId == null) {
        throw Exception('Could not save address');
      }

      final order = await ApiService.checkout(
        addressId: addressId,
        paymentMethod: _paymentMethod,
        couponCode: widget.couponCode,
        useWallet: _useWallet,
      );
      if (order['id'] == null) {
        throw Exception(order['error']?.toString() ?? 'Checkout failed');
      }
      _currentOrderId = order['id'];

      if (_paymentMethod == 'cod') {
        // COD: order is placed directly, nothing more to pay right now.
        if (!mounted) return;
        await context.read<CartProvider>().loadCart();
        if (!mounted) return;
        await context.read<OrderProvider>().loadOrders(
          OrderStatus.active,
          refresh: true,
        );
        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const OrderScreen()),
        );
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Order Placed! Pay on delivery \u{1F4E6}',
              style: GoogleFonts.poppins(),
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
        setState(() => _isLoading = false);
        return;
      }

      // Online: continue to Razorpay.
      final orderData = await ApiService.createPaymentOrder(_currentOrderId!);
      var options = {
        'key': orderData['key_id'],
        'amount': orderData['amount'],
        'name': 'Mepto',
        'order_id': orderData['razorpay_order_id'],
        'description': 'Grocery Order',
        'prefill': {'contact': '9999999999', 'email': 'test@mepto.com'},
        'method': {
          'upi': true,
          'card': true,
          'netbanking': true,
          'wallet': true,
        },
        'theme': {'color': '#D4A574'},
      };
      _razorpay.open(options);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Icon(
                  Icons.shopping_bag_outlined,
                  color: Color(0xFFF5C518),
                  size: 20,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    e.toString().replaceFirst('Exception: ', ''),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
            backgroundColor: const Color(0xFF2D2D2D),
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.only(left: 16, right: 16, bottom: 80),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
    setState(() => _isLoading = false);
  }

  void _openRazorpayCheckout(Map<String, dynamic> orderData) {
    var options = {
      'key': orderData['key_id'],
      'amount': orderData['amount'],
      'name': 'Mepto',
      'order_id': orderData['razorpay_order_id'],
      'description': 'Grocery Order',
      'prefill': {'contact': '9999999999', 'email': 'test@mepto.com'},
      'method': {'upi': true, 'card': true, 'netbanking': true, 'wallet': true},
      'theme': {'color': '#D4A574'},
    };
    _razorpay.open(options);
  }

  void _showAddressSheet({int? editIndex}) {
    final existing = editIndex != null ? _addresses[editIndex] : null;

    final nameController = TextEditingController(text: existing?['name'] ?? '');
    final addressController = TextEditingController(
      text: existing?['address'] ?? '',
    );
    final cityController = TextEditingController(text: existing?['city'] ?? '');
    final phoneController = TextEditingController(
      text: existing?['phone'] ?? '',
    );
    final buildingController = TextEditingController(
      text: existing?['building'] ?? '',
    );
    String selectedType = existing?['type'] ?? 'Home';
    double? capturedLat = (existing?['lat'] as num?)?.toDouble();
    double? capturedLng = (existing?['lng'] as num?)?.toDouble();
    String? formError;
    String? locationErrorModal;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => StatefulBuilder(
        builder: (context, setModalState) {
          return Padding(
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              top: 20,
              bottom: MediaQuery.of(context).viewInsets.bottom + 20,
            ),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    editIndex != null ? 'Edit Address' : 'Add New Address',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),

                  Row(
                    children: ['Home', 'Office', 'Other'].map((type) {
                      final isSelected = selectedType == type;
                      return GestureDetector(
                        onTap: () => setModalState(() => selectedType = type),
                        child: Container(
                          margin: const EdgeInsets.only(right: 10),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? const Color(0xFF0C831F)
                                : Colors.grey[100],
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            type,
                            style: GoogleFonts.poppins(
                              fontSize: 13,
                              color: isSelected ? Colors.white : Colors.grey,
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),

                  _buildTextField(
                    buildingController,
                    'Building & Block No. (Optional)',
                    Icons.home_outlined,
                  ),
                  const SizedBox(height: 12),
                  _buildTextField(
                    addressController,
                    'House No. & Floor',
                    Icons.apartment_outlined,
                  ),
                  const SizedBox(height: 12),
                  _buildTextField(
                    cityController,
                    'City, State, Pincode',
                    Icons.location_city_outlined,
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      GestureDetector(
                        onTap: () async {
                          final picked = await Navigator.push<PickedLocation>(
                            context,
                            MaterialPageRoute(
                              builder: (_) => LocationPickerScreen(
                                initialLat: capturedLat,
                                initialLng: capturedLng,
                              ),
                            ),
                          );
                          if (picked != null) {
                            setModalState(() {
                              capturedLat = picked.lat;
                              capturedLng = picked.lng;
                              if (picked.streetLine.isNotEmpty) {
                                addressController.text = picked.streetLine;
                              }
                              if (picked.cityLine.isNotEmpty) {
                                cityController.text = picked.cityLine;
                              }
                              locationErrorModal = null;
                            });
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade300),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.map_outlined,
                                size: 14,
                                color: Color(0xFF0C831F),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'Select on map',
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  color: const Color(0xFF0C831F),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      if (capturedLat != null && capturedLng != null)
                        Text(
                          'Location captured',
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            color: Colors.green,
                          ),
                        ),
                    ],
                  ),
                  if (locationErrorModal != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        locationErrorModal!,
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          color: Colors.red,
                        ),
                      ),
                    ),
                  const SizedBox(height: 20),
                  Text(
                    'Receiver details',
                    style: GoogleFonts.poppins(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildTextField(
                    nameController,
                    "Receiver's Name",
                    Icons.person_outline,
                  ),
                  const SizedBox(height: 12),
                  _buildTextField(
                    phoneController,
                    "Receiver's Phone Number",
                    Icons.phone_outlined,
                    keyboardType: TextInputType.phone,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    maxLength: 10,
                  ),
                  if (formError != null) ...[
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        formError!,
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () async {
                        if (_savingAddress) return;
                        if (nameController.text.isEmpty ||
                            addressController.text.isEmpty) {
                          setModalState(
                            () => formError = 'Please fill all fields',
                          );
                          return;
                        }

                        if (!RegExp(
                          r'^[6-9]\d{9}$',
                        ).hasMatch(phoneController.text)) {
                          setModalState(
                            () => formError =
                                'Enter a valid 10-digit phone number',
                          );
                          return;
                        }

                        if (!RegExp(
                          r'(?<!\d)\d{6}(?!\d)',
                        ).hasMatch(cityController.text)) {
                          setModalState(
                            () => formError =
                                'Add a 6-digit pincode, e.g. Mumbai, Maharashtra, 400001',
                          );
                          return;
                        }

                        if (capturedLat == null || capturedLng == null) {
                          final query = [
                            buildingController.text.trim(),
                            addressController.text.trim(),
                            cityController.text.trim(),
                          ].where((s) => s.isNotEmpty).join(', ');
                          var results = await NominatimService.search(query);
                          debugPrint(
                            'GEOCODE: query=$query results=${results.length}',
                          );
                          if (results.isEmpty &&
                              cityController.text.trim().isNotEmpty) {
                            final cityQuery = cityController.text.trim();
                            results = await NominatimService.search(cityQuery);
                            debugPrint(
                              'GEOCODE_FALLBACK_CITY: query=$cityQuery results=${results.length}',
                            );
                          }
                          if (results.isEmpty) {
                            final pinMatch = RegExp(
                              r'(\d{6})',
                            ).firstMatch(cityController.text);
                            if (pinMatch != null) {
                              final pinQuery = pinMatch.group(1)!;
                              results = await NominatimService.search(pinQuery);
                              debugPrint(
                                'GEOCODE_FALLBACK_PIN: query=$pinQuery results=${results.length}',
                              );
                            }
                          }
                          if (results.isNotEmpty) {
                            capturedLat = results.first.lat;
                            capturedLng = results.first.lng;
                          }
                        }

                        if (!mounted) return;
                        final newAddress = {
                          'type': selectedType,
                          'icon': _iconFromType(selectedType),
                          'name': nameController.text,
                          'address': addressController.text,
                          'building': buildingController.text,
                          'city': cityController.text,
                          'phone': phoneController.text,
                          'lat': capturedLat,
                          'lng': capturedLng,
                          'backend_id': existing?['backend_id'],
                        };

                        setState(() {
                          if (editIndex != null) {
                            _addresses[editIndex] = newAddress;
                            _selectedAddress = editIndex;
                          } else {
                            _addresses.add(newAddress);
                            _selectedAddress = _addresses.length - 1;
                          }
                        });

                        _saveAddresses();
                        final syncIndex = editIndex ?? _addresses.length - 1;
                        _savingAddress = true;
                        int? syncedId;
                        try {
                          syncedId = await _syncAddressToBackend(syncIndex);
                        } finally {
                          _savingAddress = false;
                        }
                        if (!mounted) return;
                        final syncOk = syncedId != null;
                        Navigator.pop(context);

                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              !syncOk
                                  ? 'Saved on this device, but the server could not save it. Edit it and check phone and pincode.'
                                  : (editIndex != null
                                        ? 'Address updated! \u2705'
                                        : 'Address saved! \u2705'),
                              style: GoogleFonts.poppins(),
                            ),
                            backgroundColor: syncOk
                                ? Colors.green
                                : Colors.orange,
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0C831F),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: Text(
                        editIndex != null ? 'Update Address' : 'Save Address',
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String hint,
    IconData icon, {
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
    List<TextInputFormatter>? inputFormatters,
    int? maxLength,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      inputFormatters: inputFormatters,
      maxLength: maxLength,
      buildCounter: maxLength != null
          ? (
              context, {
              required currentLength,
              required isFocused,
              maxLength,
            }) => null
          : null,
      style: GoogleFonts.poppins(fontSize: 14),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.poppins(color: Colors.grey, fontSize: 13),
        prefixIcon: Icon(icon, color: const Color(0xFF0C831F), size: 20),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF0C831F), width: 2),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
      ),
    );
  }

  Widget _buildPaymentMethodPicker() {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.grey.withValues(alpha: 0.08), blurRadius: 8),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Payment Method',
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          _buildPaymentOption(
            value: 'online',
            title: 'Pay Online',
            subtitle: 'UPI, Card, Netbanking, Wallet',
            icon: Icons.credit_card,
          ),
          const SizedBox(height: 8),
          _buildPaymentOption(
            value: 'cod',
            title: 'Cash on Delivery',
            subtitle: 'Pay when your order arrives',
            icon: Icons.payments_outlined,
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentOption({
    required String value,
    required String title,
    required String subtitle,
    required IconData icon,
  }) {
    final isSelected = _paymentMethod == value;
    return GestureDetector(
      onTap: () => setState(() => _paymentMethod = value),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF0C831F).withValues(alpha: 0.08)
              : Colors.grey[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? const Color(0xFF0C831F) : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isSelected ? const Color(0xFF0C831F) : Colors.grey,
              size: 22,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
              color: isSelected ? const Color(0xFF0C831F) : Colors.grey,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: const Color(0xFF0C831F),
        title: Text(
          'Select Delivery Address',
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddressSheet(),
        backgroundColor: const Color(0xFF0C831F),
        icon: const Icon(Icons.add, color: Colors.white),
        label: Text(
          'Add Address',
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      body: _addresses.isEmpty
          ? Center(
              child: Text(
                'No addresses saved',
                style: GoogleFonts.poppins(color: Colors.grey),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
              itemCount: _addresses.length + 1,
              itemBuilder: (context, index) {
                if (index == _addresses.length) {
                  return _buildPaymentMethodPicker();
                }
                final address = _addresses[index];
                final isSelected = _selectedAddress == index;
                return GestureDetector(
                  onTap: () => setState(() {
                    _selectedAddress = index;
                    final lat = (_addresses[index]['lat'] as num?)?.toDouble();
                    final lng = (_addresses[index]['lng'] as num?)?.toDouble();
                    CategoryRepository.updateLocation(lat, lng);
                  }),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isSelected
                            ? const Color(0xFF0C831F)
                            : Colors.transparent,
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withValues(alpha: 0.08),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: const Color(
                              0xFF0C831F,
                            ).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            address['icon'],
                            color: const Color(0xFF0C831F),
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    address['type'],
                                    style: GoogleFonts.poppins(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  if (isSelected)
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF0C831F),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Text(
                                        'Selected',
                                        style: GoogleFonts.poppins(
                                          color: Colors.white,
                                          fontSize: 10,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                address['name'],
                                style: GoogleFonts.poppins(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              if ((address['building'] ?? '')
                                  .toString()
                                  .trim()
                                  .isNotEmpty)
                                Text(
                                  address['building'],
                                  style: GoogleFonts.poppins(
                                    fontSize: 12,
                                    color: Colors.grey,
                                  ),
                                ),
                              Text(
                                address['address'],
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  color: Colors.grey,
                                ),
                              ),
                              Text(
                                address['city'],
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  color: Colors.grey,
                                ),
                              ),
                              Text(
                                address['phone'],
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  color: Colors.grey,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  GestureDetector(
                                    onTap: () =>
                                        _showAddressSheet(editIndex: index),
                                    child: Text(
                                      'Edit',
                                      style: GoogleFonts.poppins(
                                        fontSize: 13,
                                        color: const Color(0xFF0C831F),
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  GestureDetector(
                                    onTap: () async {
                                      final backendId = address['backend_id'];
                                      try {
                                        if (backendId != null) {
                                          await ApiService.deleteAddress(
                                            backendId.toString(),
                                          );
                                          if (!mounted) return;
                                        }
                                        setState(() {
                                          _addresses.removeAt(index);
                                          if (index < _selectedAddress)
                                            _selectedAddress--;
                                          if (_selectedAddress >=
                                              _addresses.length) {
                                            _selectedAddress = 0;
                                          }
                                        });
                                        _saveAddresses();
                                      } catch (e) {
                                        if (context.mounted) {
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            SnackBar(
                                              content: Text(
                                                'Failed to delete address: $e',
                                              ),
                                            ),
                                          );
                                        }
                                      }
                                    },
                                    child: Text(
                                      'Delete',
                                      style: GoogleFonts.poppins(
                                        fontSize: 13,
                                        color: Colors.red,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 10,
            ),
          ],
        ),
        child: ElevatedButton(
          onPressed: _isLoading || _addresses.isEmpty ? null : _placeOrder,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF0C831F),
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
          child: _isLoading
              ? const CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                )
              : Text(
                  _paymentMethod == 'cod'
                      ? 'Place Order \u2022 \u20b9${widget.totalAmount}'
                      : 'Pay \u20b9${widget.totalAmount}',
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
        ),
      ),
    );
  }
}
