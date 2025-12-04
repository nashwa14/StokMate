import 'package:flutter/material.dart';
import 'package:nashwaluthfiya_124230016_pam_a/models/inventory_models.dart';
import 'package:nashwaluthfiya_124230016_pam_a/controllers/inventory_controller.dart';
import 'package:nashwaluthfiya_124230016_pam_a/controllers/auth_controller.dart';
import 'package:nashwaluthfiya_124230016_pam_a/services/notification_service.dart';
import 'package:nashwaluthfiya_124230016_pam_a/menu/add_edit_page.dart';

class DetailItemPage extends StatefulWidget {
  final InventoryItem item;
  const DetailItemPage({super.key, required this.item});

  @override
  State<DetailItemPage> createState() => _DetailItemPageState();
}

class _DetailItemPageState extends State<DetailItemPage> {
  final _invController = InventoryController();
  final _auth = AuthController();
  String? _currentUsername;
  late Future<Map<String, dynamic>> _dataFuture;

  // Helper untuk format angka desimal
  String _formatQuantity(double quantity) {
    if (quantity == quantity.toInt()) {
      return quantity.toInt().toString();
    }
    return quantity.toStringAsFixed(2);
  }

  String _formatPrice(double price) {
    if (price == price.toInt()) {
      return price.toInt().toString();
    }
    return price.toStringAsFixed(2);
  }

  @override
  void initState() {
    super.initState();
    _loadCurrentUser();
    _dataFuture = _loadConversionData();
  }

  Future<void> _loadCurrentUser() async {
    final username = _auth.getSession();
    if (username != null) {
      setState(() => _currentUsername = username);
    }
  }

  Future<Map<String, dynamic>> _loadConversionData() async {
    final rates = await _invController.getExchangeRates();
    final offsets = await _invController.getTimeZoneOffsets();
    return {'rates': rates, 'offsets': offsets};
  }

  void _deleteItem() async {
    if (widget.item.id == null || _currentUsername == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        backgroundColor: const Color(0xFFF5FFFE),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFFF6B6B).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.delete_outline, color: Color(0xFFFF6B6B)),
            ),
            const SizedBox(width: 12),
            const Text(
              'Konfirmasi Hapus',
              style: TextStyle(color: Color(0xFF00695C), fontSize: 18),
            ),
          ],
        ),
        content: Text(
          'Yakin ingin menghapus "${widget.item.name}"? Tindakan ini tidak bisa dibatalkan.',
          style: const TextStyle(color: Color(0xFF00796B)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Batal', style: TextStyle(color: Color(0xFF80CBC4))),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF6B6B),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Hapus', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _invController.deleteItem(widget.item.id!, _currentUsername!);
      
      if (!mounted) return;
      await NotificationService.showItemDeletedNotification(widget.item.name);
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
      backgroundColor: const Color(0xFFE0F7F4),
      body: CustomScrollView(
        slivers: [
          _buildAppBar(),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: FutureBuilder<Map<String, dynamic>>(
                future: _dataFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.all(40),
                        child: CircularProgressIndicator(color: Color(0xFF26A69A)),
                      ),
                    );
                  }

                  final rates = snapshot.data?['rates'] as Map<String, double>? ?? {};
                  final offsets = snapshot.data?['offsets'] as Map<String, int>? ?? {};

                  return Column(
                    children: [
                      _buildMainInfoCard(),
                      const SizedBox(height: 16),
                      _buildStatusCard(),
                      const SizedBox(height: 16),
                      _buildConversionCard(rates, offsets),
                      const SizedBox(height: 16),
                      _buildLocationCard(),
                      const SizedBox(height: 16),
                      _buildActionButtons(),
                      const SizedBox(height: 20),
                    ],
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      expandedHeight: 120,
      pinned: true,
      backgroundColor: const Color(0xFF26A69A),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.white),
        onPressed: () => Navigator.pop(context),
      ),
      flexibleSpace: FlexibleSpaceBar(
        title: Text(
          widget.item.name,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF26A69A), Color(0xFF4DB6AC)],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMainInfoCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFF5FFFE),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF26A69A).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  _getCategoryIcon(widget.item.category),
                  color: const Color(0xFF26A69A),
                  size: 32,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.item.name,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF00695C),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.item.category,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF00796B),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const Divider(height: 32, color: Color(0xFF80CBC4)),
          _buildInfoRow(
            Icons.inventory_2_outlined,
            'Stok Tersisa',
            '${_formatQuantity(widget.item.quantity)} ${widget.item.unit}',
            widget.item.quantity == 0 ? const Color(0xFFFF6B6B) : const Color(0xFF26A69A),
          ),
          const SizedBox(height: 12),
          _buildInfoRow(
            Icons.payments_outlined,
            'Harga Beli',
            '${_formatPrice(widget.item.price)} ${widget.item.currency}',
            const Color(0xFF26A69A),
          ),
          const SizedBox(height: 12),
          _buildInfoRow(
            Icons.calendar_today_outlined,
            'Tanggal Kadaluarsa',
            _formatDate(widget.item.expiryDate),
            _getExpiryColor(widget.item.expiryDate),
          ),
          const SizedBox(height: 12),
          _buildInfoRow(
            Icons.location_on_outlined,
            'Lokasi Pembelian',
            widget.item.location,
            const Color(0xFF26A69A),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusCard() {
    final status = _invController.getStatus(widget.item);
    final daysRemaining = widget.item.expiryDate.difference(DateTime.now()).inDays;

    Color statusColor;
    IconData statusIcon;
    String statusMessage;

    if (widget.item.quantity == 0) {
      statusColor = const Color(0xFFFF6B6B);
      statusIcon = Icons.remove_shopping_cart;
      statusMessage = 'Stok barang ini sudah habis';
    } else if (daysRemaining <= 0) {
      statusColor = const Color(0xFFFF6B6B);
      statusIcon = Icons.warning_amber_rounded;
      statusMessage = 'Barang ini sudah kadaluarsa';
    } else if (widget.item.quantity <= 1) {
      statusColor = const Color(0xFFFFB74D);
      statusIcon = Icons.trending_down;
      statusMessage = 'Stok barang hampir habis';
    } else if (daysRemaining <= 7) {
      statusColor = const Color(0xFFFFB74D);
      statusIcon = Icons.access_time;
      statusMessage = 'Akan kadaluarsa dalam $daysRemaining hari';
    } else {
      statusColor = const Color(0xFF26A69A);
      statusIcon = Icons.check_circle_outline;
      statusMessage = 'Barang dalam kondisi baik';
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: statusColor.withOpacity(0.3), width: 2),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(statusIcon, color: statusColor, size: 32),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  status,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: statusColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(statusMessage, style: TextStyle(fontSize: 13, color: statusColor)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConversionCard(Map<String, double> rates, Map<String, int> offsets) {
    final price = widget.item.price;
    final currency = widget.item.currency;
    final eurRate = rates['EUR'] ?? 0.9;
    final jpyRate = rates['JPY'] ?? 150.0;
    final krwRate = rates['KRW'] ?? 1300.0;
    final gbpRate = rates['GBP'] ?? 0.8;
    final idrRate = rates['IDR'] ?? 16000.0;

    double priceInUsd;
    if (currency == 'USD') {
      priceInUsd = price;
    } else if (currency == 'EUR') {
      priceInUsd = price / eurRate;
    } else if (currency == 'JPY') {
      priceInUsd = price / jpyRate;
    } else if (currency == 'KRW') {
      priceInUsd = price / krwRate;
    } else if (currency == 'GBP') {
      priceInUsd = price / gbpRate;
    } else if (currency == 'IDR') {
      priceInUsd = price / idrRate;
    } else {
      priceInUsd = price;
    }

    final priceInIdr = priceInUsd * idrRate;
    final priceInEur = priceInUsd * eurRate;
    final priceInJpy = priceInUsd * jpyRate;
    final priceInKrw = priceInUsd * krwRate;
    final priceInGbp = priceInUsd * gbpRate;

    const wibOffsetHours = 7;
    final witaOffsetHours = offsets['WITA'] ?? 8;
    final witOffsetHours = offsets['WIT'] ?? 9;
    final londonOffsetHours = offsets['London'] ?? 0;

    final expiryWita = widget.item.expiryDate.add(Duration(hours: witaOffsetHours - wibOffsetHours));
    final expiryWit = widget.item.expiryDate.add(Duration(hours: witOffsetHours - wibOffsetHours));
    final expiryLondon = widget.item.expiryDate.add(Duration(hours: londonOffsetHours - wibOffsetHours));

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFF5FFFE),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.swap_horiz, color: Color(0xFF26A69A)),
              SizedBox(width: 8),
              Text(
                'Konversi Nilai',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF00695C),
                ),
              ),
            ],
          ),
          const Divider(height: 24, color: Color(0xFF80CBC4)),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF26A69A).withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFF26A69A).withOpacity(0.3)),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline, size: 18, color: Color(0xFF26A69A)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Harga asli: ${_formatPrice(price)} $currency',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF26A69A),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Harga dalam Mata Uang Lain',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF00796B),
            ),
          ),
          const SizedBox(height: 12),
          if (currency != 'IDR') _buildConversionItem('IDR (Rupiah)', priceInIdr, Icons.currency_exchange),
          if (currency != 'USD') _buildConversionItem('USD (Dollar)', priceInUsd, Icons.attach_money),
          if (currency != 'EUR') _buildConversionItem('EUR (Euro)', priceInEur, Icons.euro_symbol),
          if (currency != 'JPY') _buildConversionItem('JPY (Yen)', priceInJpy, Icons.currency_yen),
          if (currency != 'KRW') _buildConversionItem('KRW (Won)', priceInKrw, Icons.currency_exchange),
          if (currency != 'GBP') _buildConversionItem('GBP (Pound)', priceInGbp, Icons.currency_pound),
          const SizedBox(height: 20),
          const Text(
            'Waktu Kadaluarsa Zona Lain',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF00796B),
            ),
          ),
          const SizedBox(height: 12),
          _buildTimeItem('WIB (Indonesia Barat)', widget.item.expiryDate),
          _buildTimeItem('WITA (Indonesia Tengah)', expiryWita),
          _buildTimeItem('WIT (Indonesia Timur)', expiryWit),
          _buildTimeItem('London (GMT)', expiryLondon),
        ],
      ),
    );
  }

  Widget _buildLocationCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFF5FFFE),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.location_on, color: const Color(0xFF26A69A)),
              const SizedBox(width: 8),
              const Text(
                'Lokasi Pembelian',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF00695C),
                ),
              ),
            ],
          ),
          const Divider(height: 24, color: Color(0xFF80CBC4)),
          _buildInfoRow(
            Icons.place_outlined,
            'Alamat',
            widget.item.location,
            const Color(0xFF26A69A),
          ),
          const SizedBox(height: 12),
          _buildInfoRow(
            Icons.gps_fixed,
            'Koordinat',
            'Lat: ${widget.item.latitude.toStringAsFixed(4)}, Lon: ${widget.item.longitude.toStringAsFixed(4)}',
            const Color(0xFF26A69A),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value, Color color) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: color),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 13,
                  color: Color(0xFF80CBC4),
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: TextStyle(
                  fontSize: 15,
                  color: color,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildConversionItem(String currency, double value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 18, color: const Color(0xFF26A69A)),
          const SizedBox(width: 8),
          Text(
            currency,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Color(0xFF00695C),
            ),
          ),
          const Spacer(),
          Text(
            _formatPrice(value),
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: Color(0xFF26A69A),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeItem(String zone, DateTime date) {
    final formatted = '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(Icons.access_time, size: 18, color: const Color(0xFF26A69A)),
          const SizedBox(width: 8),
          Text(
            zone,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Color(0xFF00695C),
            ),
          ),
          const Spacer(),
          Text(
            formatted,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Color(0xFF26A69A),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: _editItem,
            icon: const Icon(Icons.edit_outlined),
            label: const Text('Edit'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF26A69A),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: _deleteItem,
            icon: const Icon(Icons.delete_outline),
            label: const Text('Hapus'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF6B6B),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
      ],
    );
  }

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'bumbu dapur': return Icons.restaurant;
      case 'produk segar': return Icons.grass;
      case 'minuman': return Icons.local_drink;
      case 'kesehatan': return Icons.medication;
      case 'kamar mandi': return Icons.bathroom;
      case 'kebersihan': return Icons.cleaning_services;
      case 'perawatan diri & kosmetik': return Icons.face;
      case 'atk': return Icons.edit;
      default: return Icons.inventory_2;
    }
  }

  String _formatDate(DateTime date) {
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  Color _getExpiryColor(DateTime expiryDate) {
    final days = expiryDate.difference(DateTime.now()).inDays;
    if (days <= 0) return const Color(0xFFFF6B6B);
    if (days <= 7) return const Color(0xFFFFB74D);
    return const Color(0xFF26A69A);
  }
}