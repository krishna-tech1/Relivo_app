import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/grant.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  int _selectedTab = 0;

  void _logout() {
    Navigator.pushReplacementNamed(context, '/admin-login');
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
                        child: const Icon(
                          Icons.admin_panel_settings,
                          color: AppTheme.white,
                        ),
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
                              style: TextStyle(
                                fontSize: 12,
                                color: AppTheme.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: _logout,
                        icon: const Icon(
                          Icons.logout,
                          color: AppTheme.white,
                        ),
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
                        value: '${GrantData.sampleGrants.length}',
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
                      label: 'Settings',
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
              child: _selectedTab == 0
                  ? _GrantsTab()
                  : _SettingsTab(),
            ),
          ],
        ),
      ),
      
      // Floating Action Button
      floatingActionButton: _selectedTab == 0
          ? FloatingActionButton.extended(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Add grant functionality will be implemented'),
                    backgroundColor: AppTheme.success,
                  ),
                );
              },
              backgroundColor: AppTheme.slateGray,
              icon: const Icon(Icons.add),
              label: const Text('Add Grant'),
            )
          : null,
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
  });

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
          Icon(
            icon,
            color: AppTheme.white,
            size: 24,
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppTheme.white,
            ),
          ),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              color: AppTheme.white,
            ),
          ),
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

  const _TabButton({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

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
            Icon(
              icon,
              color: isSelected ? AppTheme.slateGray : AppTheme.mediumGray,
            ),
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
  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(AppConstants.paddingMedium),
      itemCount: GrantData.sampleGrants.length,
      itemBuilder: (context, index) {
        final grant = GrantData.sampleGrants[index];
        return Container(
          margin: const EdgeInsets.only(bottom: AppConstants.paddingMedium),
          decoration: AppTheme.cardDecoration,
          child: ListTile(
            contentPadding: const EdgeInsets.all(AppConstants.paddingMedium),
            leading: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                gradient: AppTheme.adminGradient,
                borderRadius: BorderRadius.circular(AppConstants.borderRadiusSmall),
              ),
              child: const Icon(
                Icons.description,
                color: AppTheme.white,
              ),
            ),
            title: Text(
              grant.title,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Text(grant.organizer),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.success.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        grant.amount,
                        style: const TextStyle(
                          color: AppTheme.success,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (grant.isVerified)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.verified.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'VERIFIED',
                          style: TextStyle(
                            color: AppTheme.verified,
                            fontWeight: FontWeight.bold,
                            fontSize: 11,
                          ),
                        ),
                      ),
                  ],
                ),
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
            ),
          ),
        );
      },
    );
  }
}


class _SettingsTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(AppConstants.paddingMedium),
      children: [
        Container(
          decoration: AppTheme.cardDecoration,
          child: Column(
            children: [
              ListTile(
                leading: const Icon(Icons.person, color: AppTheme.slateGray),
                title: const Text('Profile Settings'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {},
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.notifications, color: AppTheme.slateGray),
                title: const Text('Notifications'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {},
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.security, color: AppTheme.slateGray),
                title: const Text('Security'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {},
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.help, color: AppTheme.slateGray),
                title: const Text('Help & Support'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {},
              ),
            ],
          ),
        ),
      ],
    );
  }
}
