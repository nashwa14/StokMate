import 'package:flutter/material.dart';
import 'package:nashwaluthfiya_124230016_pam_a/controllers/inventory_controller.dart';
import 'package:nashwaluthfiya_124230016_pam_a/controllers/auth_controller.dart';
import 'package:nashwaluthfiya_124230016_pam_a/models/inventory_models.dart';
import 'package:nashwaluthfiya_124230016_pam_a/services/notification_service.dart';
import 'package:nashwaluthfiya_124230016_pam_a/services/notification_helper.dart';
import 'package:nashwaluthfiya_124230016_pam_a/menu/add_edit_page.dart';
import 'package:nashwaluthfiya_124230016_pam_a/menu/detail_page.dart';
import 'package:nashwaluthfiya_124230016_pam_a/menu/profile_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _controller = InventoryController();
  final _auth = AuthController();
  String? _currentUsername;
  List<InventoryItem> _allItems = [];
  List<InventoryItem> _filteredItems = [];
  bool _isLoading = true;
  bool _isCheckingNotification = false;

  String _searchQuery = '';
  String _selectedStatusFilter = 'Semua Status';
  String _selectedSortOption = 'Nama (A-Z)';
  String _selectedCurrencyFilter = 'Semua Mata Uang';

  final List<String> _currencyFilters = [
    'Semua Mata Uang',
    'USD',
    'EUR',
    'JPY',
    'KRW',
    'GBP',
    'IDR',
  ];

  final List<String> _statusFilters = [
    'Semua Status',
    'Stok Habis',
    'Kadaluarsa',
    'Stok Menipis',
    'Hampir Kadaluarsa',
    'Stok Aman',
    'Aman Konsumsi',
  ];

  final List<String> _sortOptions = [
    'Nama (A-Z)',
    'Nama (Z-A)',
    'Harga Tertinggi',
    'Harga Terendah',
  ];

  Map<String, int> _statusCounts = {};

  @override
  void initState() {
    super.initState();
    _loadCurrentUser();
  }

  Future<void> _loadCurrentUser() async {
    final username = _auth.getSession();
    if (username != null) {
      setState(() => _currentUsername = username);
      _loadItems();
    }
  }

  Future<void> _loadItems() async {
    if (_currentUsername == null || !mounted) return;
    setState(() => _isLoading = true);
    try {
      final items = await _controller.getAllItems(_currentUsername!);
      if (!mounted) return;
      setState(() {
        _allItems = items;
        _calculateStatusCounts();
        _applyFiltersAndSort();
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading items: $e');
      if (mounted) setState(() => _isLoading = false);
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

  void _applyFiltersAndSort() {
    List<InventoryItem> filtered = List.from(_allItems);

    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((item) {
        return item.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            item.category.toLowerCase().contains(_searchQuery.toLowerCase());
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

    if (_selectedCurrencyFilter != 'Semua Mata Uang') {
      filtered = filtered
          .where((item) => item.currency == _selectedCurrencyFilter)
          .toList();
    }

    switch (_selectedSortOption) {
      case 'Nama (A-Z)':
        filtered.sort((a, b) => a.name.compareTo(b.name));
        break;
      case 'Nama (Z-A)':
        filtered.sort((a, b) => b.name.compareTo(a.name));
        break;
      case 'Harga Tertinggi':
        filtered.sort((a, b) => b.price.compareTo(a.price));
        break;
      case 'Harga Terendah':
        filtered.sort((a, b) => a.price.compareTo(b.price));
        break;
    }

    if (mounted) {
      setState(() => _filteredItems = filtered);
    }
  }

  Color _getStatusColor(String status) {
    if (status.contains('Habis') || status.contains('Kadaluarsa')) {
      return const Color(0xFFFF6B6B);
    } else if (status.contains('Menipis') || status.contains('Hampir')) {
      return const Color(0xFFFFB74D);
    } else {
      return const Color(0xFF26A69A);
    }
  }

  void _showSnackbar(String text, SnackbarType type) {
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
        duration: const Duration(seconds: 3),
      ),
    );
  }

  Future<void> _checkNotifications() async {
    if (_isCheckingNotification || !mounted) return;

    setState(() => _isCheckingNotification = true);

    try {
      await NotificationService.showStockSummaryNotification(_allItems);
      _showSnackbar('Notifikasi telah dikirim', SnackbarType.info);
    } catch (e) {
      _showSnackbar('Gagal mengirim notifikasi: $e', SnackbarType.error);
    } finally {
      if (mounted) {
        setState(() => _isCheckingNotification = false);
      }
    }
  }

  // Helper untuk format angka desimal
  String _formatQuantity(double quantity) {
    // Jika angka bulat, tampilkan tanpa desimal
    if (quantity == quantity.toInt()) {
      return quantity.toInt().toString();
    }
    // Jika desimal, tampilkan dengan 2 digit desimal
    return quantity.toStringAsFixed(2);
  }

  String _formatPrice(double price) {
    // Jika angka bulat, tampilkan tanpa desimal
    if (price == price.toInt()) {
      return price.toInt().toString();
    }
    // Jika desimal, tampilkan dengan 2 digit desimal
    return price.toStringAsFixed(2);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          _buildAppBar(),
          SliverToBoxAdapter(child: _buildDashboardStats()),
          SliverToBoxAdapter(child: _buildSearchBar()),
          SliverToBoxAdapter(child: _buildFilterSort()),
          _buildItemsList(),
        ],
      ),
      bottomNavigationBar: _buildBottomNavBar(),
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      expandedHeight: 120,
      floating: false,
      pinned: true,
      backgroundColor: const Color(0xFF26A69A),
      flexibleSpace: FlexibleSpaceBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.inventory_2_rounded,
              color: Colors.white,
              size: 24,
            ),
            const SizedBox(width: 8),
            const Text(
              'StokMate',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
          ],
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
      actions: [
        Stack(
          children: [
            IconButton(
              onPressed: _isCheckingNotification ? null : _checkNotifications,
              icon: _isCheckingNotification
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Icon(
                      Icons.notifications_outlined,
                      color: Colors.white,
                    ),
            ),
            if (NotificationHelper.getTotalProblematicItems(_allItems) > 0)
              Positioned(
                right: 8,
                top: 8,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: Color(0xFFFF6B6B),
                    shape: BoxShape.circle,
                  ),
                  constraints: const BoxConstraints(
                    minWidth: 16,
                    minHeight: 16,
                  ),
                  child: Text(
                    '${NotificationHelper.getTotalProblematicItems(_allItems)}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildDashboardStats() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFF5FFFE),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Ringkasan Stok',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF00695C),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF26A69A).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'Total: ${_allItems.length}',
                  style: const TextStyle(
                    color: Color(0xFF26A69A),
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  icon: Icons.remove_shopping_cart,
                  label: 'Habis',
                  count: _statusCounts['outOfStock'] ?? 0,
                  color: const Color(0xFFFF6B6B),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  icon: Icons.warning_amber_rounded,
                  label: 'Kadaluarsa',
                  count: _statusCounts['expired'] ?? 0,
                  color: const Color(0xFFFF6B6B),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  icon: Icons.trending_down,
                  label: 'Menipis',
                  count: _statusCounts['lowStock'] ?? 0,
                  color: const Color(0xFFFFB74D),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  icon: Icons.access_time,
                  label: 'Hampir Exp',
                  count: _statusCounts['nearExpiry'] ?? 0,
                  color: const Color(0xFFFFB74D),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String label,
    required int count,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
          Text(
            '$count',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: TextField(
        onChanged: (value) {
          setState(() {
            _searchQuery = value;
            _applyFiltersAndSort();
          });
        },
        decoration: InputDecoration(
          hintText: 'Cari barang atau kategori...',
          hintStyle: const TextStyle(color: Color(0xFF80CBC4)),
          prefixIcon: const Icon(Icons.search, color: Color(0xFF26A69A)),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear, color: Color(0xFF80CBC4)),
                  onPressed: () {
                    setState(() {
                      _searchQuery = '';
                      _applyFiltersAndSort();
                    });
                  },
                )
              : null,
          filled: true,
          fillColor: const Color(0xFFF5FFFE),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }

  Widget _buildFilterSort() {
    return Container(
      margin: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: _buildDropdownButton(
              icon: Icons.filter_list,
              value: _selectedStatusFilter,
              items: _statusFilters,
              onChanged: (value) {
                setState(() {
                  _selectedStatusFilter = value!;
                  _applyFiltersAndSort();
                });
              },
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildDropdownButton(
              icon: Icons.currency_exchange,
              value: _selectedCurrencyFilter,
              items: _currencyFilters,
              onChanged: (value) {
                setState(() {
                  _selectedCurrencyFilter = value!;
                  _applyFiltersAndSort();
                });
              },
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildDropdownButton(
              icon: Icons.sort,
              value: _selectedSortOption,
              items: _sortOptions,
              onChanged: (value) {
                setState(() {
                  _selectedSortOption = value!;
                  _applyFiltersAndSort();
                });
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDropdownButton({
    required IconData icon,
    required String value,
    required List<String> items,
    required Function(String?) onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF5FFFE),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          icon: Icon(icon, color: const Color(0xFF26A69A), size: 20),
          style: const TextStyle(
            fontSize: 13,
            color: Color(0xFF00695C),
            fontWeight: FontWeight.w500,
          ),
          items: items.map((item) {
            return DropdownMenuItem(
              value: item,
              child: Text(
                item,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 12),
              ),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _buildItemsList() {
    if (_isLoading) {
      return const SliverFillRemaining(
        child: Center(
          child: CircularProgressIndicator(color: Color(0xFF26A69A)),
        ),
      );
    }

    if (_filteredItems.isEmpty) {
      return SliverFillRemaining(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.inventory_2_outlined,
                size: 80,
                color: const Color(0xFF80CBC4).withOpacity(0.5),
              ),
              const SizedBox(height: 16),
              Text(
                _searchQuery.isNotEmpty ||
                        _selectedStatusFilter != 'Semua Status'
                    ? 'Tidak ada item yang sesuai'
                    : 'Belum ada item tersimpan',
                style: const TextStyle(fontSize: 16, color: Color(0xFF00796B)),
              ),
            ],
          ),
        ),
      );
    }

    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) => _buildItemCard(_filteredItems[index]),
          childCount: _filteredItems.length,
        ),
      ),
    );
  }

  Widget _buildItemCard(InventoryItem item) {
    final status = _controller.getStatus(item);
    final statusColor = _getStatusColor(status);
    final daysRemaining = item.expiryDate.difference(DateTime.now()).inDays;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => _navigateToDetail(item),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      _getCategoryIcon(item.category),
                      color: statusColor,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.name,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF00695C),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          item.category,
                          style: const TextStyle(
                            fontSize: 13,
                            color: Color(0xFF00796B),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: statusColor.withOpacity(0.3)),
                    ),
                    child: Text(
                      status,
                      style: TextStyle(
                        color: statusColor,
                        fontWeight: FontWeight.w600,
                        fontSize: 11,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFE0F7F4),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: _buildInfoItem(
                        Icons.inventory_2_outlined,
                        '${_formatQuantity(item.quantity)} ${item.unit}',
                        item.quantity == 0
                            ? const Color(0xFFFF6B6B)
                            : item.quantity <= 1
                            ? const Color(0xFFFFB74D)
                            : const Color(0xFF26A69A),
                      ),
                    ),
                    Container(
                      width: 1,
                      height: 30,
                      color: const Color(0xFF80CBC4).withOpacity(0.3),
                    ),
                    Expanded(
                      child: _buildInfoItem(
                        Icons.payments_outlined,
                        '${_formatPrice(item.price)} ${item.currency}',
                        const Color(0xFF26A69A),
                      ),
                    ),
                    Container(
                      width: 1,
                      height: 30,
                      color: const Color(0xFF80CBC4).withOpacity(0.3),
                    ),
                    Expanded(
                      child: _buildInfoItem(
                        Icons.calendar_today_outlined,
                        daysRemaining <= 0 ? 'Exp' : '$daysRemaining h',
                        daysRemaining <= 0
                            ? const Color(0xFFFF6B6B)
                            : daysRemaining <= 7
                            ? const Color(0xFFFFB74D)
                            : const Color(0xFF26A69A),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoItem(IconData icon, String text, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 4),
        Flexible(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.w600,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'bumbu dapur':
        return Icons.restaurant;
      case 'produk segar':
        return Icons.grass;
      case 'minuman':
        return Icons.local_drink;
      case 'kesehatan':
        return Icons.medication;
      case 'kamar mandi':
        return Icons.bathroom;
      case 'kebersihan':
        return Icons.cleaning_services;
      case 'perawatan diri & kosmetik':
        return Icons.face;
      case 'atk':
        return Icons.edit;
      default:
        return Icons.inventory_2;
    }
  }

  Widget _buildBottomNavBar() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF5FFFE),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: BottomNavigationBar(
        backgroundColor: const Color(0xFFF5FFFE),
        selectedItemColor: const Color(0xFF26A69A),
        unselectedItemColor: const Color(0xFF80CBC4),
        currentIndex: 0,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_rounded),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.add_circle_outline),
            label: 'Tambah',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_rounded),
            label: 'Profile',
          ),
        ],
        onTap: (index) {
          if (index == 1) {
            _navigateToAddEdit();
          } else if (index == 2) {
            _navigateToProfile();
          }
        },
      ),
    );
  }

  Future<void> _navigateToAddEdit({InventoryItem? item}) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => AddEditPage(itemToEdit: item)),
    );
    if (result == true && mounted) _loadItems();
  }

  Future<void> _navigateToDetail(InventoryItem item) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => DetailItemPage(item: item)),
    );
    if (result == true && mounted) _loadItems();
  }

  void _navigateToProfile() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ProfilePage()),
    );
  }
}

enum SnackbarType { success, error, warning, info }