import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/grant.dart';
import 'package:refugee_app/screens/admin_login_screen.dart';
import 'package:refugee_app/services/auth_services.dart';
import 'package:refugee_app/services/grant_service.dart';
import 'package:intl/intl.dart';

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

  Future<void> _showGrantDialog([Grant? grant]) async {
    await showDialog(
      context: context,
      builder: (context) => _GrantEditor(
        grant: grant, 
        onSave: (newGrant) async {
            try {
              if (grant == null) {
                // Create
                await _grantService.createGrant(newGrant);
              } else {
                // Update - keep the same ID
                 final updatedGrant = Grant(
                    id: grant.id,
                    title: newGrant.title,
                    organizer: newGrant.organizer,
                    country: newGrant.country,
                    category: newGrant.category,
                    deadline: newGrant.deadline,
                    amount: newGrant.amount,
                    description: newGrant.description,
                    eligibilityCriteria: [],
                    requiredDocuments: [],
                 );
                await _grantService.updateGrant(updatedGrant);
              }
              _fetchGrants(); // Refresh list
              if (mounted) Navigator.pop(context);
            } catch (e) {
              ScaffoldMessenger.of(context).showSnackBar(
                 SnackBar(content: Text('Error saving grant: $e')),
              );
            }
        },
      ),
    );
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
                        onEdit: _showGrantDialog,
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
              onPressed: () => _showGrantDialog(null),
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
          );
        },
      ),
    );
  }
}

// Simple editor dialog for adding/editing grants
class _GrantEditor extends StatefulWidget {
  final Grant? grant;
  final Function(Grant) onSave;

  const _GrantEditor({this.grant, required this.onSave});

  @override
  State<_GrantEditor> createState() => _GrantEditorState();
}

class _GrantEditorState extends State<_GrantEditor> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleCtrl;
  late TextEditingController _providerCtrl;
  late TextEditingController _amountCtrl;
  late TextEditingController _descCtrl;
  late TextEditingController _locationCtrl;
  DateTime _selectedDate = DateTime.now().add(const Duration(days: 30));

  @override
  void initState() {
    super.initState();
    _titleCtrl = TextEditingController(text: widget.grant?.title ?? '');
    _providerCtrl = TextEditingController(text: widget.grant?.organizer ?? '');
    _amountCtrl = TextEditingController(text: widget.grant?.amount ?? '');
    _descCtrl = TextEditingController(text: widget.grant?.description ?? '');
    _locationCtrl = TextEditingController(text: widget.grant?.country ?? '');
    if (widget.grant != null) _selectedDate = widget.grant!.deadline;
  }
  
  @override
  void dispose() {
    _titleCtrl.dispose();
    _providerCtrl.dispose();
    _amountCtrl.dispose();
    _descCtrl.dispose();
    _locationCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
       child: Padding(
         padding: const EdgeInsets.all(24.0),
         child: SingleChildScrollView(
           child: Form(
             key: _formKey,
             child: Column(
               mainAxisSize: MainAxisSize.min,
               crossAxisAlignment: CrossAxisAlignment.stretch,
               children: [
                 Text(
                   widget.grant == null ? 'Add New Grant' : 'Edit Grant',
                   style: Theme.of(context).textTheme.headlineSmall,
                   textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  TextFormField(
                    controller: _titleCtrl,
                    decoration: const InputDecoration(labelText: 'Title'),
                    validator: (v) => v!.isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _providerCtrl,
                    decoration: const InputDecoration(labelText: 'Provider/Organization'),
                    validator: (v) => v!.isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _amountCtrl,
                    decoration: const InputDecoration(labelText: 'Amount (e.g. \$5000)'),
                    validator: (v) => v!.isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 12),
                   TextFormField(
                    controller: _locationCtrl,
                    decoration: const InputDecoration(labelText: 'Location/Country'),
                    validator: (v) => v!.isEmpty ? 'Required' : null,
                  ),
                   const SizedBox(height: 12),
                  TextFormField(
                    controller: _descCtrl,
                    decoration: const InputDecoration(labelText: 'Description'),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 12),
                  ListTile(
                    title: const Text("Deadline"),
                    subtitle: Text(DateFormat('yyyy-MM-dd').format(_selectedDate)),
                    trailing: const Icon(Icons.calendar_today),
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: _selectedDate,
                        firstDate: DateTime.now(),
                        lastDate: DateTime(2030),
                      );
                      if (picked != null) setState(() => _selectedDate = picked);
                    },
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () {
                      if (_formKey.currentState!.validate()) {
                        final newGrant = Grant(
                          id: '', // Ignored on create
                          title: _titleCtrl.text,
                          organizer: _providerCtrl.text,
                          country: _locationCtrl.text,
                          category: 'General',
                          deadline: _selectedDate,
                          amount: _amountCtrl.text,
                          description: _descCtrl.text,
                          eligibilityCriteria: [],
                          requiredDocuments: [],
                        );
                        widget.onSave(newGrant);
                      }
                    },
                    child: const Text('Save Grant'),
                  ),
               ],
             ),
           ),
         ),
       ),
    );
  }
}
