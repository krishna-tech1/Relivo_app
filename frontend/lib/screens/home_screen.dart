import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_theme.dart';
import '../models/grant.dart';
import '../services/grant_service.dart';
import '../services/auth_services.dart';
import 'grant_detail_screen.dart';
import 'filter_screen.dart';
import 'login_screen.dart';
import 'my_grants_screen.dart';
import '../widgets/grant_card.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // State for filtering
  List<Grant> _allGrants = [];
  List<Grant> _filteredGrants = [];
  String _selectedCategory = 'All Categories';
  String _selectedCountry = 'All Countries';
  final TextEditingController _searchController = TextEditingController();
  DateTime? _lastBackPressTime;
  bool _isLoading = true;
  final _grantService = GrantService();

  @override
  void initState() {
    super.initState();
    _fetchGrants();
  }

  Future<void> _fetchGrants() async {
    setState(() => _isLoading = true);
    try {
      final grants = await _grantService.getGrants();
      if (mounted) {
        setState(() {
          _allGrants = grants;
          _isLoading = false;
        });
        _filterGrants(); // Initial filter
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load grants: $e')),
        );
      }
    }
  }

  void _handleSearch(String query) {
    _filterGrants(query: query);
  }

  void _filterGrants({String? query}) {
    final searchQuery = query ?? _searchController.text;
    
    setState(() {
      _filteredGrants = _allGrants.where((grant) {
        final matchesCategory = _selectedCategory == 'All Categories' || 
                              grant.category.trim().toLowerCase() == _selectedCategory.trim().toLowerCase();
        final matchesCountry = _selectedCountry == 'All Countries' || 
                             grant.country.trim().toLowerCase() == _selectedCountry.trim().toLowerCase();
        final matchesSearch = grant.title.toLowerCase().contains(searchQuery.toLowerCase()) ||
                            grant.description.toLowerCase().contains(searchQuery.toLowerCase());
        
        return matchesCategory && matchesCountry && matchesSearch;
      }).toList();
    });
  }

  Future<void> _navigateToFilter() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const FilterScreen(),
        settings: RouteSettings(
          arguments: {
            'category': _selectedCategory,
            'country': _selectedCountry,
          },
        ),
      ),
    );

    if (result != null && result is Map) {
      setState(() {
        _selectedCategory = result['category'] ?? 'All Categories';
        _selectedCountry = result['country'] ?? 'All Countries';
      });
      _filterGrants();
    }
  }

  void _handleLogout() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              // Clear session first
              await AuthService().logout();
              
              if (context.mounted) {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => const LoginScreen()),
                  (route) => false,
                );
              }
            },
            child: const Text('Logout', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        final now = DateTime.now();
        if (_lastBackPressTime == null || 
            now.difference(_lastBackPressTime!) > const Duration(seconds: 2)) {
          _lastBackPressTime = now;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Press back again to exit'),
              duration: Duration(seconds: 2),
            ),
          );
          return false;
        }
        return true;
      },
      child: Scaffold(
        backgroundColor: AppTheme.offWhite,
        body: SafeArea(
          child: Column(
            children: [
              // Header Section
              Container(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
                decoration: BoxDecoration(
                  color: AppTheme.white,
                  borderRadius: const BorderRadius.vertical(bottom: Radius.circular(32)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.03),
                      blurRadius: 30,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'REFUGIEE CARE',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w900,
                                color: AppTheme.primaryBlue,
                                letterSpacing: 2.0,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Available Grants',
                              style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.w900,
                                color: AppTheme.darkGray,
                                height: 1.1,
                              ),
                            ),
                          ],
                        ),
                        // Enhanced Profile Button
                        Material(
                          color: Colors.transparent,
                          child: PopupMenuButton<String>(
                            onSelected: (value) {
                              if (value == 'logout') {
                                _handleLogout();
                              } else if (value == 'my_submissions') {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (context) => const MyGrantsScreen()),
                                );
                              }
                            },
                            offset: const Offset(0, 50),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                              PopupMenuItem<String>(
                                value: 'my_submissions',
                                child: Row(
                                  children: [
                                    Icon(Icons.assignment_ind_rounded, size: 20, color: AppTheme.primaryBlue),
                                    const SizedBox(width: 12),
                                    const Text('My Submissions', style: TextStyle(fontWeight: FontWeight.w600)),
                                  ],
                                ),
                              ),
                              const PopupMenuDivider(),
                              const PopupMenuItem<String>(
                                value: 'logout',
                                child: Row(
                                  children: [
                                    Icon(Icons.logout_rounded, size: 20, color: Colors.redAccent),
                                    const SizedBox(width: 12),
                                    const Text('Logout', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.w600)),
                                  ],
                                ),
                              ),
                            ],
                            child: Container(
                              height: 48,
                              width: 48,
                              decoration: BoxDecoration(
                                color: AppTheme.offWhite,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: AppTheme.lightGray, width: 1.5),
                              ),
                              child: const Center(
                                child: Icon(Icons.person_outline_rounded, color: AppTheme.darkGray, size: 24),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    
                    // Search and Filter Row
                    Row(
                      children: [
                        Expanded(
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            decoration: BoxDecoration(
                              color: AppTheme.offWhite,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: _searchController.text.isNotEmpty 
                                  ? AppTheme.primaryBlue.withOpacity(0.5) 
                                  : AppTheme.lightGray,
                                width: 1.5,
                              ),
                              boxShadow: _searchController.text.isNotEmpty ? [
                                BoxShadow(
                                  color: AppTheme.primaryBlue.withOpacity(0.05),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                )
                              ] : [],
                            ),
                            child: TextField(
                              controller: _searchController,
                              textInputAction: TextInputAction.search,
                              onSubmitted: (value) {
                                _handleSearch(value);
                                FocusScope.of(context).unfocus();
                              },
                              onChanged: (value) {
                                setState(() {}); // Update to show/hide clear button
                                _handleSearch(value);
                              },
                              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                              decoration: InputDecoration(
                                hintText: 'Search grants...',
                                hintStyle: TextStyle(color: AppTheme.mediumGray.withOpacity(0.6)),
                                prefixIcon: const Icon(Icons.search_rounded, color: AppTheme.mediumGray),
                                suffixIcon: _searchController.text.isNotEmpty
                                  ? IconButton(
                                      icon: const Icon(Icons.cancel_rounded, color: AppTheme.mediumGray, size: 20),
                                      onPressed: () {
                                        _searchController.clear();
                                        setState(() {});
                                        _handleSearch('');
                                        FocusScope.of(context).unfocus();
                                      },
                                    )
                                  : null,
                                border: InputBorder.none,
                                enabledBorder: InputBorder.none,
                                focusedBorder: InputBorder.none,
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16, 
                                  vertical: 14,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        GestureDetector(
                          onTap: _navigateToFilter,
                          child: Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              gradient: AppTheme.primaryGradient,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: AppTheme.primaryBlue.withOpacity(0.3),
                                  blurRadius: 12,
                                  offset: const Offset(0, 6),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.tune_rounded,
                              color: AppTheme.white,
                              size: 24,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Category Quick Filter
              Padding(
                padding: const EdgeInsets.only(top: 20, bottom: 0),
                child: SizedBox(
                  height: 44,
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    scrollDirection: Axis.horizontal,
                    itemCount: GrantData.categories.length,
                    separatorBuilder: (context, index) => const SizedBox(width: 10),
                    itemBuilder: (context, index) {
                      final category = GrantData.categories[index];
                      final isSelected = _selectedCategory == category;
                      final catColor = AppTheme.getCategoryColor(category);
                      
                      return InkWell(
                        onTap: () {
                          setState(() => _selectedCategory = category);
                          _filterGrants();
                        },
                        borderRadius: BorderRadius.circular(20),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: isSelected ? catColor : catColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: isSelected ? catColor : catColor.withOpacity(0.2),
                              width: 1.5,
                            ),
                            boxShadow: isSelected ? [
                              BoxShadow(
                                color: catColor.withOpacity(0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              )
                            ] : null,
                          ),
                          child: Text(
                            category,
                            style: TextStyle(
                              color: isSelected ? Colors.white : catColor,
                              fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),

              // Filters Status (if active)
              if (_selectedCategory != 'All Categories' || _selectedCountry != 'All Countries')
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                  child: Row(
                    children: [
                      Icon(Icons.filter_list, size: 16, color: AppTheme.primaryBlue),
                      const SizedBox(width: 8),
                      Text(
                        'Active Filters:',
                        style: TextStyle(
                          color: AppTheme.mediumGray,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              if (_selectedCategory != 'All Categories')
                                _FilterBadge(label: _selectedCategory),
                              if (_selectedCountry != 'All Countries') ...[
                                const SizedBox(width: 8),
                                _FilterBadge(label: _selectedCountry),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

              // Grants List
              Expanded(
                child: RefreshIndicator(
                  onRefresh: _fetchGrants,
                  child: _isLoading 
                    ? const Center(child: CircularProgressIndicator())
                    : _filteredGrants.isEmpty
                    ? LayoutBuilder(
                        builder: (context, constraints) => SingleChildScrollView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          child: ConstrainedBox(
                            constraints: BoxConstraints(minHeight: constraints.maxHeight),
                            child: Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(24),
                                    decoration: BoxDecoration(
                                      color: AppTheme.offWhite,
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      Icons.search_off_rounded,
                                      size: 80, // Slightly larger icon
                                      color: AppTheme.mediumGray.withOpacity(0.3),
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    'No grants found',
                                    style: TextStyle(
                                      fontSize: 20,
                                      color: AppTheme.darkGray,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Try adjusting your search or filters',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 15,
                                      color: AppTheme.mediumGray,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.all(AppConstants.paddingLarge),
                        physics: const AlwaysScrollableScrollPhysics(),
                        itemCount: _filteredGrants.length,
                        separatorBuilder: (context, index) => const SizedBox(height: 20),
                        itemBuilder: (context, index) {
                          return GrantCard(
                            grant: _filteredGrants[index],
                            // Custom onTap for HomeScreen (view details only)
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const GrantDetailScreen(),
                                  settings: RouteSettings(arguments: _filteredGrants[index]),
                                ),
                              );
                            },
                          );
                        },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Internal widget classes removed. Using imported GrantCard. 

class _FilterBadge extends StatelessWidget {
  final String label;

  const _FilterBadge({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppTheme.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.primaryBlue.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryBlue.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 12,
          color: AppTheme.primaryBlue,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
 
