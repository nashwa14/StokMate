import 'package:flutter/material.dart';
import '../controllers/inventory_controller.dart';
import '../services/location_service.dart';
import '../models/inventory_models.dart';
import 'dart:async';

class AddEditPage extends StatefulWidget {
  final InventoryItem? itemToEdit;
  const AddEditPage({super.key, this.itemToEdit});

  @override
  State<AddEditPage> createState() => _AddEditPageState();
}

class _AddEditPageState extends State<AddEditPage> {
  final _controller = InventoryController();
  final _locationService = LocationService();
  final _formKey = GlobalKey<FormState>();

  final _name = TextEditingController();
  final _quantity = TextEditingController();
  final _price = TextEditingController();
  final _category = TextEditingController();
  final _unit = TextEditingController();
  final _currency = TextEditingController(text: 'IDR'); // ✅ Default IDR

  DateTime _expiryDate = DateTime.now().add(const Duration(days: 30));
  String _locationName = 'Lokasi belum diambil/dipilih';
  double _lat = 0.0;
  double _lon = 0.0;
  bool _loading = false;

  // Suggestions untuk autocomplete
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
  ];

  @override
  void initState() {
    super.initState();
    if (widget.itemToEdit != null) {
      _initializeEditMode(widget.itemToEdit!);
    } else {
      _category.text = '';
      _unit.text = 'pcs';
      _currency.text = 'IDR';
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
    _quantity.text = item.quantity.toString();
    _price.text = item.price.toStringAsFixed(0);
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
      if (mounted && showMsg) _msg(e.message ?? 'Timeout.', false);
    } catch (e) {
      if (mounted && showMsg) _msg('Gagal mengambil lokasi: $e', false);
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
      _msg('Lokasi berhasil diambil: $address', true);
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
          colorScheme: const ColorScheme.light(primary: Color(0xFF4CAF50)),
        ),
        child: child!,
      ),
    );
    if (picked != null && picked != _expiryDate) {
      setState(() => _expiryDate = picked);
    }
  }

  Future<void> _onSaveItem() async {
    if (_loading) return;
    if (!_formKey.currentState!.validate()) {
      _msg('Harap lengkapi semua field yang wajib diisi.', false);
      return;
    }
    if (_lat == 0.0 && _lon == 0.0) {
      _msg('Harap ambil lokasi pembelian terlebih dahulu!', false);
      return;
    }

    setState(() => _loading = true);

    try {
      final newItem = InventoryItem(
        id: widget.itemToEdit?.id,
        name: _name.text.trim(),
        category: _category.text.trim(),
        quantity: int.parse(_quantity.text),
        unit: _unit.text.trim(),
        price: double.parse(_price.text),
        currency: _currency.text.trim(),
        expiryDate: _expiryDate,
        location: _locationName,
        latitude: _lat,
        longitude: _lon,
      );

      await _controller.saveItem(newItem);

      if (!mounted) return;
      final action = widget.itemToEdit == null ? 'ditambahkan' : 'diperbarui';
      _msg('Item berhasil $action!', true);
      await Future.delayed(const Duration(milliseconds: 500));
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      _msg('Gagal menyimpan item: $e', false);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _msg(String msg, bool isSuccess) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isSuccess ? Colors.green : Colors.red,
        duration: Duration(seconds: isSuccess ? 2 : 4),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.itemToEdit != null;
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: Stack(
        children: [
          // Header
          Container(
            height: 1000,
            width: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF4CAF50), Color(0xFF81C784)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(30),
                bottomRight: Radius.circular(30),
              ),
            ),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.only(top: 10, left: 10),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      isEditing ? 'Edit Item' : 'Tambah Item Stok',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Form
          Positioned(
            top: 150,
            left: 0,
            right: 0,
            bottom: 0,
            child: SingleChildScrollView(
              padding: const EdgeInsets.only(left: 25, right: 25, bottom: 150),
              child: Container(
                padding: const EdgeInsets.all(25),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.3),
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
                      _buildCustomTextField(_name, 'masukkan barangnya', Icons.inventory_2),
                      const Divider(height: 30),

                      _buildLabel('Kategori Barang'),
                      _buildAutocompleteField(
                        controller: _category,
                        suggestions: _categorySuggestions,
                        hint: 'Pilih atau ketik kategori',
                        icon: Icons.category,
                      ),
                      const Divider(height: 30),

                      _buildLabel('Jumlah & Satuan'),
                      Row(
                        children: [
                          Expanded(
                            child: _buildCustomTextField(_quantity, '', Icons.numbers, isNumeric: true),
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
                      const Divider(height: 30),

                      _buildLabel('Harga Beli & Mata Uang'),
                      Row(
                        children: [
                          Expanded(
                            child: _buildCustomTextField(_price, '', Icons.payments, isNumeric: true),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildCustomTextField(_currency, 'Mata uang (contoh: IDR)', Icons.payments_outlined),
                          ),
                        ],
                      ),
                      const Divider(height: 30),

                      _buildLabel('Tanggal Kadaluarsa'),
                      _buildDateDisplay(),
                      const Divider(height: 30),

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
                            style: const TextStyle(fontSize: 18, color: Colors.white),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _loading ? Colors.grey : const Color(0xFF689F38),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            elevation: _loading ? 0 : 5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // === WIDGET HELPER ===
  Widget _buildLabel(String title) => Padding(
        padding: const EdgeInsets.only(bottom: 8.0),
        child: Text(title,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.grey)),
      );

  Widget _buildCustomTextField(TextEditingController c, String hint, IconData icon,
      {bool isNumeric = false}) {
    return TextFormField(
      controller: c,
      keyboardType: isNumeric ? TextInputType.number : TextInputType.text,
      decoration: InputDecoration(
        hintText: hint,
        border:
            OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
        filled: true,
        fillColor: Colors.grey[100],
        prefixIcon: Icon(icon, color: Colors.green),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 15),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) return 'Wajib diisi';
        if (isNumeric && double.tryParse(value) == null) return 'Harus angka';
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
        return suggestions.where((option) =>
            option.toLowerCase().contains(textEditingValue.text.toLowerCase()));
      },
      onSelected: (selection) => controller.text = selection,
      fieldViewBuilder: (context, textEditingController, focusNode, _) {
        textEditingController.text = controller.text;
        textEditingController.selection =
            TextSelection.fromPosition(TextPosition(offset: textEditingController.text.length));

        return TextFormField(
          controller: textEditingController,
          focusNode: focusNode,
          decoration: InputDecoration(
            hintText: hint,
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
            filled: true,
            fillColor: Colors.grey[100],
            prefixIcon: Icon(icon, color: Colors.green),
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
          borderRadius: BorderRadius.circular(10),
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
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('${_expiryDate.day} ${_getMonthName(_expiryDate.month)} ${_expiryDate.year}',
                style: const TextStyle(fontSize: 16)),
            IconButton(icon: const Icon(Icons.edit_calendar, color: Colors.green), onPressed: _selectDate),
          ],
        ),
      );

  String _getMonthName(int m) =>
      ['Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'][m - 1];

  Widget _buildLocationMapPlaceholder() {
    final valid = _lat != 0.0 || _lon != 0.0;
    return Container(
      height: 150,
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(valid ? Icons.check_circle : Icons.location_on,
                size: 40, color: valid ? Colors.green : Colors.red),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Text(
                _locationName,
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: valid ? Colors.green[800] : Colors.red, fontSize: 13),
              ),
            ),
            if (valid)
              Text('Lat: ${_lat.toStringAsFixed(4)}, Lon: ${_lon.toStringAsFixed(4)}',
                  style: const TextStyle(fontSize: 12)),
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
          label: Text(_loading ? 'Mengambil Lokasi...' : 'Ambil Lokasi Sekarang',
              style: const TextStyle(color: Colors.white)),
          style: ElevatedButton.styleFrom(
            backgroundColor: _loading ? Colors.grey : Colors.teal,
            padding: const EdgeInsets.symmetric(vertical: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        ),
      );
}
