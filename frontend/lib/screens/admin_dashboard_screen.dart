import 'package:flutter/material.dart';
import 'package:refugee_app/screens/grant_detail_screen.dart';
import '../theme/app_theme.dart';
import '../models/grant.dart';
import 'package:refugee_app/screens/admin_login_screen.dart';
import 'package:refugee_app/services/auth_services.dart';
import 'package:refugee_app/services/grant_service.dart';
import 'package:intl/intl.dart';
import 'package:refugee_app/screens/grant_editor_screen.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  int _selectedTab = 0;
  List<Grant> _grants = [];
  bool _isLoading = true;
  final GrantService _grantService = GrantService();

  @override
  void initState() {
    super.initState();
    _fetchGrants();
  }

  Future<void> _fetchGrants() async {
    setState(() => _isLoading = true);
    try {
      final grants = await _grantService.getGrants();
      setState(() {
        _grants = grants;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading grants: $e')),
        );
      }
    }
  }

  void _logout() async {
    await AuthService().logout();
    if (mounted) {
      Navigator.pushReplacement(
        context, 
        MaterialPageRoute(builder: (context) => const AdminLoginScreen()),
      );
    }
  }

  Future<void> _showGrantEditor([Grant? grant]) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => GrantEditorScreen(grant: grant)),
    );
    
    // Refresh if grant was saved (result == true)
    if (result == true) {
      _fetchGrants();
    }
  }

  Future<void> _deleteGrant(String id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Grant?'),
        content: const Text('This action cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, true), 
            style: TextButton.styleFrom(foregroundColor: AppTheme.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _grantService.deleteGrant(id);
        _fetchGrants();
      } catch (e) {
         if(mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Error deleting grant: $e')),
            );
         }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.offWhite,
      body: SafeArea(
        child: Column(
          children: [
            // Header with slate gradient
            Container(
              decoration: const BoxDecoration(
                gradient: AppTheme.adminGradient,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 8,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(AppConstants.paddingMedium),
              child: Column(
                children: [
                   Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: AppTheme.white.withValues(alpha: 0.2),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.admin_panel_settings, color: AppTheme.white),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Admin Dashboard',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.white,
                              ),
                            ),
                            Text(
                              'Manage grants',
                              style: TextStyle(fontSize: 12, color: AppTheme.white),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: _logout,
                        icon: const Icon(Icons.logout, color: AppTheme.white),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  // Stats Row
                  Center(
                    child: SizedBox(
                      width: 200,
                      child: _StatCard(
                        icon: Icons.description,
                        label: 'Total Grants',
                        value: '${_grants.length}',
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            // Tab Bar
            Container(
              color: AppTheme.white,
              child: Row(
                children: [
                  Expanded(
                    child: _TabButton(
                      label: 'Grants',
                      icon: Icons.description,
                      isSelected: _selectedTab == 0,
                      onTap: () => setState(() => _selectedTab = 0),
                    ),
                  ),
                  Expanded(
                    child: _TabButton(
                      label: 'Settings', // Placeholder for now
                      icon: Icons.settings,
                      isSelected: _selectedTab == 1,
                      onTap: () => setState(() => _selectedTab = 1),
                    ),
                  ),
                ],
              ),
            ),
            
            // Content
            Expanded(
              child: _isLoading 
                ? const Center(child: CircularProgressIndicator())
                : _selectedTab == 0 
                    ? _GrantsTab(
                        grants: _grants, 
                        onEdit: _showGrantEditor,
                        onDelete: _deleteGrant,
                        onRefresh: _fetchGrants
                      ) 
                    : const Center(child: Text("Settings not implemented")),
            ),
          ],
        ),
      ),
      
      // Floating Action Button
      floatingActionButton: _selectedTab == 0
          ? FloatingActionButton.extended(
              onPressed: () => _showGrantEditor(null),
              backgroundColor: AppTheme.slateGray,
              icon: const Icon(Icons.add, color: Colors.white),
              label: const Text('Add Grant', style: TextStyle(color: Colors.white)),
            )
          : null,
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _StatCard({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(AppConstants.borderRadiusMedium),
        border: Border.all(color: AppTheme.white.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: AppTheme.white, size: 24),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.white)),
          Text(label, style: const TextStyle(fontSize: 11, color: AppTheme.white)),
        ],
      ),
    );
  }
}

class _TabButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _TabButton({required this.label, required this.icon, required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: isSelected ? AppTheme.slateGray : Colors.transparent,
              width: 3,
            ),
          ),
        ),
        child: Column(
          children: [
            Icon(icon, color: isSelected ? AppTheme.slateGray : AppTheme.mediumGray),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? AppTheme.slateGray : AppTheme.mediumGray,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GrantsTab extends StatelessWidget {
  final List<Grant> grants;
  final Function(Grant) onEdit;
  final Function(String) onDelete;
  final VoidCallback onRefresh;

  const _GrantsTab({
    required this.grants, 
    required this.onEdit, 
    required this.onDelete,
    required this.onRefresh
  });

  @override
  Widget build(BuildContext context) {
    if (grants.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.inbox_outlined, size: 48, color: Colors.grey),
            const SizedBox(height: 16),
            const Text('No grants found'),
             TextButton(onPressed: onRefresh, child: const Text("Refresh"))
          ],
        ),
      );
    }
    
    return RefreshIndicator(
      onRefresh: () async => onRefresh(),
      child: ListView.builder(
        padding: const EdgeInsets.all(AppConstants.paddingMedium),
        itemCount: grants.length,
        itemBuilder: (context, index) {
          final grant = grants[index];
          return Container(
            margin: const EdgeInsets.only(bottom: AppConstants.paddingMedium),
            decoration: AppTheme.cardDecoration,
            child: InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const GrantDetailScreen(),
                    settings: RouteSettings(arguments: grant),
                  ),
                );
              },
              child: ListTile(
                contentPadding: const EdgeInsets.all(AppConstants.paddingMedium),
              leading: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  gradient: AppTheme.adminGradient,
                  borderRadius: BorderRadius.circular(AppConstants.borderRadiusSmall),
                ),
                child: const Icon(Icons.description, color: AppTheme.white),
              ),
              title: Text(
                grant.title,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 4),
                  Text("Provider: ${grant.organizer}"),
                  Text("Deadline: ${grant.formattedDeadline}"),
                   Text("Amount: ${grant.amount}", style: const TextStyle(color: AppTheme.success, fontWeight: FontWeight.bold)),
                ],
              ),
              trailing: PopupMenuButton(
                icon: const Icon(Icons.more_vert),
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        Icon(Icons.edit, size: 20),
                        SizedBox(width: 8),
                        Text('Edit'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete, size: 20, color: AppTheme.error),
                        SizedBox(width: 8),
                        Text('Delete', style: TextStyle(color: AppTheme.error)),
                      ],
                    ),
                  ),
                ],
                onSelected: (value) {
                  if (value == 'edit') onEdit(grant);
                  if (value == 'delete') onDelete(grant.id);
                },
              ),
            ),
          ),
          );
        },
      ),
    );
  }
}
