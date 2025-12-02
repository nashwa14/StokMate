import 'package:flutter/material.dart';
import '../models/inventory_models.dart';
import '../controllers/inventory_controller.dart';
import 'add_edit_page.dart';

class DetailItemPage extends StatefulWidget {
  final InventoryItem item;
  const DetailItemPage({super.key, required this.item});

  @override
  State<DetailItemPage> createState() => _DetailItemPageState(); 
}

class _DetailItemPageState extends State<DetailItemPage> {
  final _invController = InventoryController();
  
  late Future<Map<String, dynamic>> _dataFuture;
  
  @override
  void initState() {
    super.initState();
    _dataFuture = _loadConversionData(); 
  }

  Future<Map<String, dynamic>> _loadConversionData() async {
    final rates = await _invController.getExchangeRates();
    final offsets = await _invController.getTimeZoneOffsets();
    return {'rates': rates, 'offsets': offsets};
  }

  void _deleteItem() async {
    if (widget.item.id == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Konfirmasi Hapus'),
        content: Text('Yakin ingin menghapus item ${widget.item.name}? Tindakan ini tidak bisa dibatalkan.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Batal')),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            child: const Text('Hapus', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _invController.deleteItem(widget.item.id!);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${widget.item.name} berhasil dihapus.'), backgroundColor: Colors.green),
      );
      Navigator.pop(context, true); 
    }
  }

  void _editItem() async {
    final result = await Navigator.push(
      context, 
      MaterialPageRoute(builder: (_) => AddEditPage(itemToEdit: widget.item)), 
    );
    
    if (result == true && mounted) {
      Navigator.pop(context, true); 
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(widget.item.name, style: const TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF4CAF50),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF4CAF50), Color(0xFF81C784)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _dataFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Color(0xFF4CAF50)));
          }
          
          final rates = snapshot.data?['rates'] as Map<String, double>? ?? {};
          final offsets = snapshot.data?['offsets'] as Map<String, int>? ?? {};
          
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildMainInfoCard(widget.item),
                const SizedBox(height: 20),
                _buildConversionCard(rates, offsets),
                const SizedBox(height: 20),
                _buildLocationCard(widget.item),
                const SizedBox(height: 30),
                _buildActionButtons(),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildMainInfoCard(InventoryItem item) {
    String stockStatus;
    Color stockColor;
    String expiryStatus;
    Color expiryColor;
    String overallStatus;
    Color overallColor;

    if (item.quantity == 0) {
      stockStatus = 'Stok Habis';
      stockColor = Colors.red;
    } else if (item.quantity == 1) {
      stockStatus = 'Stok Menipis';
      stockColor = Colors.orange;
    } else {
      stockStatus = 'Stok Aman';
      stockColor = Colors.green;
    }

    final daysRemaining = item.expiryDate.difference(DateTime.now()).inDays;
    if (daysRemaining <= 0) {
      expiryStatus = 'Kadaluarsa';
      expiryColor = Colors.red;
    } else if (daysRemaining >= 7) {
      expiryStatus = 'Hampir Kadaluarsa ($daysRemaining hari)';
      expiryColor = Colors.orange;
    } else {
      expiryStatus = 'Aman';
      expiryColor = Colors.green;
    }

    if (item.quantity == 0) {
      overallStatus = 'Stok Habis';
      overallColor = Colors.red;
    } else if (daysRemaining <= 0) {
      overallStatus = 'Kadaluarsa';
      overallColor = Colors.red;
    } else if (item.quantity == 1) {
      overallStatus = 'Stok Menipis';
      overallColor = Colors.orange;
    } else if (daysRemaining >= 7) {
      overallStatus = 'Hampir Kadaluarsa ($daysRemaining hari)';
      overallColor = Colors.orange;
    } else {
      overallStatus = 'Aman';
      overallColor = Colors.green;
    }

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(item.name, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF4CAF50))),
            const Divider(),
            _infoRow('Kategori', item.category, Icons.category),
            _infoRow('Stok Tersisa', '${item.quantity} ${item.unit}', Icons.inventory_2),
            _infoRow('Harga Beli', '${item.price} ${item.currency}', Icons.payments),
            const Divider(),
            // Status Stok
            _infoRow('Status Stok', stockStatus, Icons.inventory, color: stockColor),
            // Status Kadaluarsa
            _infoRow('Status Kadaluarsa', expiryStatus, Icons.calendar_today, color: expiryColor),
            const Divider(),
            // Status Keseluruhan
            _infoRow('Status Keseluruhan', overallStatus, Icons.info, color: overallColor),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value, IconData icon, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: color ?? const Color(0xFF2E7D32)),
          const SizedBox(width: 8),
          Text('$label: ', style: const TextStyle(fontWeight: FontWeight.w500)),
          Expanded(child: Text(value, style: TextStyle(color: color))),
        ],
      ),
    );
  }

  Widget _buildConversionCard(Map<String, double> rates, Map<String, int> offsets) {
    final price = widget.item.price;
    
    final usdRate = rates['USD'] ?? 0.000064; 
    final eurRate = rates['EUR'] ?? 0.000059;
    final jpyRate = rates['JPY'] ?? 0.0096;

    final double conversionFactor = 1.0 / (rates[widget.item.currency] ?? 1.0); 
    final double priceInIDR = price * conversionFactor;

    const wibOffsetHours = 7;
    final witaOffsetHours = offsets['WITA'] ?? 8;
    final witOffsetHours = offsets['WIT'] ?? 9;
    final londonOffsetHours = offsets['London'] ?? 0;

    final expiryWita = widget.item.expiryDate.add(Duration(hours: witaOffsetHours - wibOffsetHours));
    final expiryWit = widget.item.expiryDate.add(Duration(hours: witOffsetHours - wibOffsetHours));
    final expiryLondon = widget.item.expiryDate.add(Duration(hours: londonOffsetHours - wibOffsetHours));

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Konversi Harga', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey[700])),
            const Divider(),
            _conversionItem('USD', priceInIDR * usdRate, Icons.monetization_on),
            _conversionItem('EUR', priceInIDR * eurRate, Icons.euro),
            _conversionItem('JPY', priceInIDR * jpyRate, Icons.currency_yen),
            
            const SizedBox(height: 16),
            Text('Konversi Waktu Kadaluarsa', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey[700])),
            const Divider(),

            _timeItem('WIB', widget.item.expiryDate, Icons.access_time),
            _timeItem('WITA', expiryWita, Icons.access_time),
            _timeItem('WIT', expiryWit, Icons.access_time),
            _timeItem('London', expiryLondon, Icons.access_time),
          ],
        ),
      ),
    );
  }
  
  Widget _conversionItem(String currency, double convertedPrice, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Icon(icon, size: 18, color: const Color(0xFF2E7D32)),
          const SizedBox(width: 8),
          Text('$currency: ', style: const TextStyle(fontWeight: FontWeight.w500)),
          Text(convertedPrice.toStringAsFixed(3), style: const TextStyle(color: Colors.teal, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _timeItem(String zone, DateTime date, IconData icon) {
    final formattedDate = "${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}";
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Icon(icon, size: 18, color: const Color(0xFF2E7D32)),
          const SizedBox(width: 8),
          Text('$zone: ', style: const TextStyle(fontWeight: FontWeight.w500)),
          Text(formattedDate, style: const TextStyle(color: Colors.teal)),
        ],
      ),
    );
  }

  Widget _buildLocationCard(InventoryItem item) {
    final locationValid = item.latitude != 0.0 && item.longitude != 0.0;
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Lokasi Pembelian (LBS)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey[700])),
            const Divider(),
            _infoRow('Nama Tempat', item.location, Icons.store),
            _infoRow('Koordinat', 'Lat ${item.latitude.toStringAsFixed(4)}, Lon ${item.longitude.toStringAsFixed(4)}', Icons.location_on),
            const SizedBox(height: 10),
            
            // Map Placeholder
            Container(
              height: 200,
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade300)
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.map_outlined, size: 40, color: Colors.grey),
                    const SizedBox(height: 8),
                    Text('Peta lokasi ${item.location}', style: const TextStyle(color: Colors.grey)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: _editItem,
            icon: const Icon(Icons.edit, color: Colors.white),
            label: const Text('Edit Barang', style: TextStyle(color: Colors.white)),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4CAF50),
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: _deleteItem,
            icon: const Icon(Icons.delete, color: Colors.white),
            label: const Text('Hapus', style: TextStyle(color: Colors.white)),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
        ),
      ],
    );
  }
}