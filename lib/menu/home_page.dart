import 'package:flutter/material.dart';
import '../controllers/inventory_controller.dart';
import '../models/inventory_models.dart';
import '../services/notification_service.dart';
import '../services/notification_helper.dart';
import 'add_edit_page.dart';
import 'detail_page.dart';
import 'profile_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _controller = InventoryController();
  List<InventoryItem> _allItems = [];
  List<InventoryItem> _filteredItems = [];
  bool _isLoading = true;
  bool _isCheckingNotification = false;

  String _searchQuery = '';
  String _selectedStatusFilter = 'Semua Status';

  final List<String> _statusFilters = [
    'Semua Status',
    'Stok Habis',
    'Kadaluarsa',
    'Stok Menipis',
    'Hampir Kadaluarsa',
    'Stok Aman',
    'Aman Konsumsi',
  ];

  Map<String, int> _statusCounts = {};

  @override
  void initState() {
    super.initState();
    _loadItems();
  }

  Future<void> _loadItems() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final items = await _controller.getAllItems();
      if (!mounted) return;
      setState(() {
        _allItems = items;
        _calculateStatusCounts();
        _applyFilters();
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading items: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _calculateStatusCounts() {
    final summary = NotificationHelper.getStockSummary(_allItems);
    _statusCounts = {
      'outOfStock': summary['outOfStock']?.length ?? 0,
      'expired': summary['expired']?.length ?? 0,
      'lowStock': summary['lowStock']?.length ?? 0,
      'nearExpiry': summary['nearExpiry']?.length ?? 0,
    };
  }

  void _applyFilters() {
    List<InventoryItem> filtered = List.from(_allItems);

    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((item) {
        return item.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
               item.category.toLowerCase().contains(_searchQuery.toLowerCase()) ||
               item.unit.toLowerCase().contains(_searchQuery.toLowerCase());
      }).toList();
    }

    if (_selectedStatusFilter != 'Semua Status') {
      filtered = filtered.where((item) {
        final days = item.expiryDate.difference(DateTime.now()).inDays;
        switch (_selectedStatusFilter) {
          case 'Stok Habis':
            return item.quantity == 0;
          case 'Kadaluarsa':
            return days <= 0;
          case 'Stok Menipis':
            return item.quantity > 0 && item.quantity <= 1;
          case 'Hampir Kadaluarsa':
            return days > 0 && days <= 7;
          case 'Stok Aman':
            return item.quantity > 1 && days > 7;
          case 'Aman Konsumsi':
            return item.quantity > 0 && days > 7;
          default:
            return true;
        }
      }).toList();
    }

    if (mounted) {
      setState(() {
        _filteredItems = filtered;
      });
    }
  }

  void _onSearchChanged(String query) {
    _searchQuery = query;
    _applyFilters();
  }

  void _onStatusFilterChanged(String? newFilter) {
    if (newFilter != null && mounted) {
      setState(() {
        _selectedStatusFilter = newFilter;
        _applyFilters();
      });
    }
  }

  Future<void> _checkNotifications() async {
    if (_isCheckingNotification || !mounted) return;

    setState(() => _isCheckingNotification = true);

    try {
      await NotificationService.checkAndNotify();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Pengecekan notifikasi selesai'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isCheckingNotification = false);
      }
    }
  }

  Future<void> _navigateToAddEdit({InventoryItem? item}) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => AddEditPage(itemToEdit: item)),
    );
    if (result == true && mounted) {
      _loadItems();
    }
  }

  Future<void> _navigateToDetail(InventoryItem item) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => DetailItemPage(item: item)),
    );
    if (result == true && mounted) {
      _loadItems();
    }
  }

  void _navigateToProfile() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ProfilePage()),
    );
  }

  Color _getStatusColor(String status) {
    if (status.contains('Habis') || status.contains('Kadaluarsa')) {
      return Colors.red;
    } else if (status.contains('Menipis') || status.contains('Hampir Kadaluarsa')) {
      return Colors.orange;
    } else {
      return Colors.green;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: Column(
        children: [
          // Header
          Container(
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
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Inventory Manager',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Total ${_allItems.length} item',
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: _isCheckingNotification ? null : _checkNotifications,
                          icon: _isCheckingNotification
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.notifications_active, color: Colors.white, size: 24),
                          tooltip: 'Cek Notifikasi',
                          style: IconButton.styleFrom(
                            backgroundColor: Colors.white.withOpacity(0.2),
                            padding: const EdgeInsets.all(8),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _buildStatusSummaryCard(),
                    const SizedBox(height: 12),
                    // Search Bar
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: TextField(
                        onChanged: _onSearchChanged,
                        decoration: InputDecoration(
                          hintText: 'Cari barang...',
                          hintStyle: TextStyle(fontSize: 13, color: Colors.grey[400]),
                          prefixIcon: const Icon(Icons.search, color: Color(0xFF4CAF50), size: 20),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          filled: true,
                          fillColor: Colors.white,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.15),
                    spreadRadius: 1,
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  const Icon(Icons.filter_list, color: Color(0xFF4CAF50), size: 20),
                  const SizedBox(width: 8),
                  const Text('Filter:', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: DropdownButton<String>(
                      value: _selectedStatusFilter,
                      isExpanded: true,
                      underline: const SizedBox(),
                      style: const TextStyle(fontSize: 13, color: Colors.black87),
                      items: _statusFilters.map((f) => DropdownMenuItem(value: f, child: Text(f))).toList(),
                      onChanged: _onStatusFilterChanged,
                    ),
                  ),
                ],
              ),
            ),
          ),

          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: Color(0xFF4CAF50)))
                : _filteredItems.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.inventory_2_outlined, size: 70, color: Colors.grey[400]),
                            const SizedBox(height: 12),
                            Text(
                              _searchQuery.isNotEmpty || _selectedStatusFilter != 'Semua Status'
                                  ? 'Tidak ada item yang sesuai'
                                  : 'Belum ada item',
                              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _loadItems,
                        color: const Color(0xFF4CAF50),
                        child: ListView.builder(
                          padding: const EdgeInsets.only(left: 20, right: 20, top: 8, bottom: 90),
                          itemCount: _filteredItems.length,
                          itemBuilder: (context, index) => _buildItemCard(_filteredItems[index]),
                        ),
                      ),
          ),
        ],
      ),

      bottomNavigationBar: Container(
        height: 65,
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(color: Colors.grey.withOpacity(0.3), spreadRadius: 1, blurRadius: 10, offset: const Offset(0, -3)),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            // Home
            Expanded(
              child: InkWell(
                onTap: () {},
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.home, color: const Color(0xFF4CAF50), size: 28),
                    const SizedBox(height: 4),
                    const Text('Home', style: TextStyle(color: Color(0xFF4CAF50), fontSize: 12, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            ),

            Expanded(
              child: InkWell(
                onTap: () => _navigateToAddEdit(),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: const BoxDecoration(color: Color(0xFF4CAF50), shape: BoxShape.circle),
                      child: const Icon(Icons.add, color: Colors.white, size: 28),
                    ),
                    const SizedBox(height: 4),
                    const Text('Tambah', style: TextStyle(color: Color(0xFF4CAF50), fontSize: 12, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            ),

            Expanded(
              child: InkWell(
                onTap: _navigateToProfile,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.person, color: const Color(0xFF4CAF50), size: 28),
                    const SizedBox(height: 4),
                    const Text('Profile', style: TextStyle(color: Color(0xFF4CAF50), fontSize: 12, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusSummaryCard() {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white.withOpacity(0.3), width: 1),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatusItem(_statusCounts['outOfStock'] ?? 0, 'Habis'),
          _buildStatusItem(_statusCounts['expired'] ?? 0, 'Exp'),
          _buildStatusItem(_statusCounts['lowStock'] ?? 0, 'Tipis'),
          _buildStatusItem(_statusCounts['nearExpiry'] ?? 0, 'Hampir Kadaluarsa'),
        ],
      ),
    );
  }

  Widget _buildStatusItem(int count, String label) {
    return Column(
      children: [
        Text('$count', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
        Text(label, style: const TextStyle(fontSize: 10, color: Colors.white70)),
      ],
    );
  }

  Widget _buildItemCard(InventoryItem item) {
    final status = _controller.getStatus(item);
    final statusColor = _getStatusColor(status);
    final daysRemaining = item.expiryDate.difference(DateTime.now()).inDays;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => _navigateToDetail(item),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(item.name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF2E7D32))),
                        const SizedBox(height: 2),
                        Text(item.category, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: statusColor, width: 1.2),
                    ),
                    child: Text(status, style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 10)),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              const Divider(height: 1),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(child: _buildInfoChip(Icons.inventory_2, 'Stok: ${item.quantity} ${item.unit}', item.quantity == 0 ? Colors.red : item.quantity <= 1 ? Colors.orange : Colors.green)),
                  const SizedBox(width: 6),
                  Expanded(child: _buildInfoChip(Icons.attach_money, '${item.price} ${item.currency}', const Color(0xFF2E7D32))),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Expanded(child: _buildInfoChip(Icons.calendar_today, daysRemaining <= 0 ? 'Kadaluarsa' : '$daysRemaining hari', daysRemaining <= 0 ? Colors.red : daysRemaining <= 7 ? Colors.orange : Colors.green)),
                  const SizedBox(width: 6),
                  Expanded(child: _buildInfoChip(Icons.location_on, item.location, const Color(0xFF2E7D32))),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 5),
      decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(6)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 3),
          Expanded(
            child: Text(text, style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w500), overflow: TextOverflow.ellipsis),
          ),
        ],
      ),
    );
  }
}