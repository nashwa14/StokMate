import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:nashwaluthfiya_124230016_pam_a/controllers/inventory_controller.dart';
import 'package:nashwaluthfiya_124230016_pam_a/controllers/auth_controller.dart';
import 'package:nashwaluthfiya_124230016_pam_a/services/location_service.dart';
import 'package:nashwaluthfiya_124230016_pam_a/services/notification_service.dart';
import 'package:nashwaluthfiya_124230016_pam_a/models/inventory_models.dart';
import 'dart:async';

class AddEditPage extends StatefulWidget {
  final InventoryItem? itemToEdit;
  const AddEditPage({super.key, this.itemToEdit});

  @override
  State<AddEditPage> createState() => _AddEditPageState();
}

const List<String> supportedCurrencies = [
  'USD',
  'EUR',
  'JPY',
  'KRW',
  'GBP',
  'IDR',
];

class _AddEditPageState extends State<AddEditPage> {
  final _controller = InventoryController();
  final _auth = AuthController();
  final _locationService = LocationService();
  final _formKey = GlobalKey<FormState>();

  String? _currentUsername;
  final _name = TextEditingController();
  final _quantity = TextEditingController();
  final _price = TextEditingController();
  final _category = TextEditingController();
  final _unit = TextEditingController();
  final _currency = TextEditingController(text: 'IDR');

  DateTime _expiryDate = DateTime.now().add(const Duration(days: 30));
  String _locationName = 'Lokasi belum diambil/dipilih';
  double _lat = 0.0;
  double _lon = 0.0;
  bool _loading = false;

  final List<String> _categorySuggestions = [
    "Bumbu Dapur",
    "Produk Segar",
    "Minuman",
    "Kesehatan",
    "Kamar Mandi",
    "Kebersihan",
    "Perawatan Diri & Kosmetik",
    "ATK",
    "Lainnya",
  ];

  final List<String> _unitSuggestions = [
    'pcs',
    'botol',
    'kg',
    'buah',
    'liter',
    'mililiter',
    'pak',
    'roll',
    'gram',
    'box',
  ];

  @override
  void initState() {
    super.initState();
    _loadCurrentUser();
    if (widget.itemToEdit != null) {
      _initializeEditMode(widget.itemToEdit!);
    } else {
      _category.text = '';
      _unit.text = 'pcs';
      _currency.text = 'IDR';
    }
  }

  Future<void> _loadCurrentUser() async {
    final username = _auth.getSession();
    if (username != null) {
      setState(() => _currentUsername = username);
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _quantity.dispose();
    _price.dispose();
    _category.dispose();
    _unit.dispose();
    _currency.dispose();
    super.dispose();
  }

  void _initializeEditMode(InventoryItem item) {
    _name.text = item.name;
    // Tampilkan angka desimal dengan format yang tepat
    _quantity.text = item.quantity.toString();
    _price.text = item.price.toString();
    _category.text = item.category;
    _unit.text = item.unit;
    _currency.text = item.currency;
    _expiryDate = item.expiryDate;
    _locationName = item.location;
    _lat = item.latitude;
    _lon = item.longitude;
  }

  Future<void> _getCurrentLocation({bool showMsg = true}) async {
    if (_loading) return;
    setState(() => _loading = true);

    try {
      await Future.any([
        _fetchLocationWithGeocoding(),
        Future.delayed(const Duration(seconds: 10), () {
          throw TimeoutException('Waktu pengambilan lokasi habis (10 detik).');
        }),
      ]);
    } on TimeoutException catch (e) {
      if (mounted && showMsg) _showSnackbar(e.message ?? 'Timeout.', SnackbarType.warning);
    } catch (e) {
      if (mounted && showMsg) _showSnackbar('Gagal mengambil lokasi: $e', SnackbarType.error);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _fetchLocationWithGeocoding() async {
    final position = await _locationService.getCurrentLocation();
    if (!mounted) return;

    if (position != null) {
      final address = await _locationService.getAddressFromCoordinates(
        position.latitude,
        position.longitude,
      );
      if (!mounted) return;
      setState(() {
        _locationName = address;
        _lat = position.latitude;
        _lon = position.longitude;
      });
      _showSnackbar('Lokasi berhasil diambil: $address', SnackbarType.success);
    } else {
      throw Exception('GPS tidak aktif atau gagal mendapatkan lokasi.');
    }
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _expiryDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
      builder: (context, child) => Theme(
        data: ThemeData.light().copyWith(
          colorScheme: const ColorScheme.light(primary: Color(0xFF26A69A)),
        ),
        child: child!,
      ),
    );
    if (picked != null && picked != _expiryDate) {
      setState(() => _expiryDate = picked);
    }
  }

  Future<void> _onSaveItem() async {
    if (_currentUsername == null) {
      _showSnackbar('User tidak ditemukan. Silakan login kembali.', SnackbarType.error);
      return;
    }

    if (_loading) return;
    if (!_formKey.currentState!.validate()) {
      _showSnackbar('Harap lengkapi semua field yang wajib diisi.', SnackbarType.warning);
      return;
    }
    if (_lat == 0.0 && _lon == 0.0) {
      _showSnackbar('Harap ambil lokasi pembelian terlebih dahulu!', SnackbarType.warning);
      return;
    }

    setState(() => _loading = true);

    try {
      // Parse quantity dan price sebagai double untuk mendukung desimal
      final quantity = double.parse(_quantity.text);
      final price = double.parse(_price.text);

      final newItem = InventoryItem(
        id: widget.itemToEdit?.id,
        name: _name.text.trim(),
        category: _category.text.trim(),
        quantity: quantity,
        unit: _unit.text.trim(),
        price: price,
        currency: _currency.text.trim(),
        expiryDate: _expiryDate,
        location: _locationName,
        latitude: _lat,
        longitude: _lon,
      );

      await _controller.saveItem(newItem, _currentUsername!);

      if (!mounted) return;
      
      // Tampilkan notifikasi sistem berdasarkan aksi
      if (widget.itemToEdit == null) {
        // Barang baru ditambahkan
        await NotificationService.showItemAddedNotification(_name.text.trim());
      } else {
        // Barang diupdate
        await NotificationService.showItemUpdatedNotification(_name.text.trim());
      }
      
      await Future.delayed(const Duration(milliseconds: 500));
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      _showSnackbar('Gagal menyimpan item: $e', SnackbarType.error);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showSnackbar(String text, SnackbarType type) {
    if (!mounted) return;
    
    Color backgroundColor;
    IconData icon;
    
    switch (type) {
      case SnackbarType.success:
        backgroundColor = const Color(0xFF26A69A);
        icon = Icons.check_circle_outline;
        break;
      case SnackbarType.error:
        backgroundColor = const Color(0xFFFF6B6B);
        icon = Icons.error_outline;
        break;
      case SnackbarType.warning:
        backgroundColor = const Color(0xFFFFB74D);
        icon = Icons.warning_amber_rounded;
        break;
      case SnackbarType.info:
        backgroundColor = const Color(0xFF4DB6AC);
        icon = Icons.info_outline;
        break;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                text,
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
        backgroundColor: backgroundColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: Duration(seconds: type == SnackbarType.error ? 4 : 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.itemToEdit != null;
    return Scaffold(
      backgroundColor: const Color(0xFFE0F7F4),
      appBar: AppBar(
        title: Text(
          isEditing ? 'Edit Item' : 'Tambah Item Stok',
          style: const TextStyle(color: Colors.white),
        ),
        backgroundColor: const Color(0xFF26A69A),
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Container(
          padding: const EdgeInsets.all(25),
          decoration: BoxDecoration(
            color: const Color(0xFFF5FFFE),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                spreadRadius: 3,
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                _buildLabel('Nama Barang'),
                _buildCustomTextField(_name, 'Masukkan nama barang', Icons.inventory_2),
                const SizedBox(height: 20),

                _buildLabel('Kategori Barang'),
                _buildAutocompleteField(
                  controller: _category,
                  suggestions: _categorySuggestions,
                  hint: 'Pilih atau ketik kategori',
                  icon: Icons.category,
                ),
                const SizedBox(height: 20),

                _buildLabel('Jumlah & Satuan'),
                Row(
                  children: [
                    Expanded(
                      child: _buildDecimalTextField(
                        _quantity, 
                        'Jumlah (boleh desimal)', 
                        Icons.numbers,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildAutocompleteField(
                        controller: _unit,
                        suggestions: _unitSuggestions,
                        hint: 'Satuan',
                        icon: Icons.balance,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                _buildLabel('Harga Beli & Mata Uang'),
                Row(
                  children: [
                    Expanded(
                      child: _buildDecimalTextField(
                        _price, 
                        'Harga (boleh desimal)', 
                        Icons.payments,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: supportedCurrencies.contains(_currency.text) ? _currency.text : 'IDR',
                        decoration: InputDecoration(
                          hintText: 'Mata uang',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          filled: true,
                          fillColor: const Color(0xFFE0F7F4),
                          prefixIcon: const Icon(Icons.payments_outlined, color: Color(0xFF26A69A)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 15),
                        ),
                        items: supportedCurrencies
                            .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                            .toList(),
                        onChanged: (value) {
                          if (value != null) {
                            setState(() => _currency.text = value);
                          }
                        },
                        validator: (value) => (value == null || value.isEmpty) ? 'Wajib diisi' : null,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                _buildLabel('Tanggal Kadaluarsa'),
                _buildDateDisplay(),
                const SizedBox(height: 20),

                _buildLabel('Lokasi Pembelian'),
                _buildLocationMapPlaceholder(),
                const SizedBox(height: 10),
                _buildLocationButton(),
                const SizedBox(height: 30),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _loading ? null : _onSaveItem,
                    icon: _loading
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Icon(Icons.save, color: Colors.white),
                    label: Text(
                      _loading
                          ? 'MENYIMPAN...'
                          : (isEditing ? 'SIMPAN PERUBAHAN' : 'TAMBAH BARANG'),
                      style: const TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _loading ? const Color(0xFF80CBC4) : const Color(0xFF26A69A),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: _loading ? 0 : 3,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String title) => Padding(
        padding: const EdgeInsets.only(bottom: 8.0),
        child: Text(
          title,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF00695C)),
        ),
      );

  Widget _buildCustomTextField(TextEditingController c, String hint, IconData icon) {
    return TextFormField(
      controller: c,
      keyboardType: TextInputType.text,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Color(0xFF80CBC4)),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        filled: true,
        fillColor: const Color(0xFFE0F7F4),
        prefixIcon: Icon(icon, color: const Color(0xFF26A69A)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 15),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) return 'Wajib diisi';
        return null;
      },
    );
  }

  // Widget khusus untuk input desimal
  Widget _buildDecimalTextField(TextEditingController c, String hint, IconData icon) {
    return TextFormField(
      controller: c,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
      ],
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Color(0xFF80CBC4)),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        filled: true,
        fillColor: const Color(0xFFE0F7F4),
        prefixIcon: Icon(icon, color: const Color(0xFF26A69A)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 15),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) return 'Wajib diisi';
        final number = double.tryParse(value);
        if (number == null) return 'Harus berupa angka';
        if (number < 0) return 'Tidak boleh negatif';
        return null;
      },
    );
  }

  Widget _buildAutocompleteField({
    required TextEditingController controller,
    required List<String> suggestions,
    required String hint,
    required IconData icon,
  }) {
    return Autocomplete<String>(
      initialValue: TextEditingValue(text: controller.text),
      optionsBuilder: (TextEditingValue textEditingValue) {
        if (textEditingValue.text.isEmpty) return suggestions;
        return suggestions.where((option) => option.toLowerCase().contains(textEditingValue.text.toLowerCase()));
      },
      onSelected: (selection) => controller.text = selection,
      fieldViewBuilder: (context, textEditingController, focusNode, _) {
        textEditingController.text = controller.text;
        textEditingController.selection = TextSelection.fromPosition(TextPosition(offset: textEditingController.text.length));

        return TextFormField(
          controller: textEditingController,
          focusNode: focusNode,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: Color(0xFF80CBC4)),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            filled: true,
            fillColor: const Color(0xFFE0F7F4),
            prefixIcon: Icon(icon, color: const Color(0xFF26A69A)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 15),
          ),
          onChanged: (value) => controller.text = value,
          validator: (value) => (value == null || value.isEmpty) ? 'Wajib diisi' : null,
        );
      },
      optionsViewBuilder: (context, onSelected, options) => Align(
        alignment: Alignment.topLeft,
        child: Material(
          elevation: 4,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            constraints: const BoxConstraints(maxHeight: 200),
            width: MediaQuery.of(context).size.width - 50,
            child: ListView.builder(
              padding: EdgeInsets.zero,
              shrinkWrap: true,
              itemCount: options.length,
              itemBuilder: (context, index) {
                final option = options.elementAt(index);
                return ListTile(title: Text(option), onTap: () => onSelected(option));
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDateDisplay() => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 15),
        decoration: BoxDecoration(
          color: const Color(0xFFE0F7F4),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '${_expiryDate.day} ${_getMonthName(_expiryDate.month)} ${_expiryDate.year}',
              style: const TextStyle(fontSize: 15, color: Color(0xFF00695C)),
            ),
            IconButton(
              icon: const Icon(Icons.edit_calendar, color: Color(0xFF26A69A)),
              onPressed: _selectDate,
            ),
          ],
        ),
      );

  String _getMonthName(int m) => ['Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'][m - 1];

  Widget _buildLocationMapPlaceholder() {
    final valid = _lat != 0.0 || _lon != 0.0;
    return Container(
      height: 120,
      decoration: BoxDecoration(
        color: const Color(0xFFE0F7F4),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF80CBC4)),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              valid ? Icons.check_circle : Icons.location_on,
              size: 36,
              color: valid ? const Color(0xFF26A69A) : const Color(0xFF80CBC4),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12.0),
              child: Text(
                _locationName,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: valid ? const Color(0xFF26A69A) : const Color(0xFF80CBC4),
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            if (valid)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  'Lat: ${_lat.toStringAsFixed(4)}, Lon: ${_lon.toStringAsFixed(4)}',
                  style: const TextStyle(fontSize: 11, color: Color(0xFF00796B)),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildLocationButton() => SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: _loading ? null : () => _getCurrentLocation(showMsg: true),
          icon: _loading
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                )
              : const Icon(Icons.gps_fixed, color: Colors.white),
          label: Text(
            _loading ? 'Mengambil Lokasi...' : 'Ambil Lokasi Sekarang',
            style: const TextStyle(color: Colors.white),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: _loading ? const Color(0xFF80CBC4) : const Color(0xFF4DB6AC),
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      );
}

enum SnackbarType { success, error, warning, info }