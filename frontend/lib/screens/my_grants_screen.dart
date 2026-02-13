import 'package:flutter/material.dart';
import '../models/grant.dart';
import '../services/grant_service.dart';
import '../theme/app_theme.dart';
import '../widgets/grant_card.dart';
import 'grant_editor_screen.dart';
import 'grant_detail_screen.dart';

class MyGrantsScreen extends StatefulWidget {
  const MyGrantsScreen({super.key});

  @override
  State<MyGrantsScreen> createState() => _MyGrantsScreenState();
}

class _MyGrantsScreenState extends State<MyGrantsScreen> {
  final _grantService = GrantService();
  List<Grant> _myGrants = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchMyGrants();
  }

  Future<void> _fetchMyGrants() async {
    setState(() => _isLoading = true);
    try {
      final grants = await _grantService.getMyGrants();
      if (mounted) {
        setState(() {
          _myGrants = grants;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        AppTheme.showAlert(context, 'Failed to load my grants: $e');
      }
    }
  }

  Future<void> _deleteGrant(String id) async {
    try {
      await _grantService.deleteMyGrant(id);
      _fetchMyGrants(); 
      if (mounted) {
        AppTheme.showSuccess(context, 'Grant deleted successfully');
      }
    } catch (e) {
      if (mounted) {
        AppTheme.showAlert(context, 'Failed to delete grant: $e');
      }
    }
  }

  void _confirmDelete(String id) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.delete_outline_rounded, color: Colors.red, size: 40),
        title: const Text('Delete Submission?'),
        content: const Text(
          'This action cannot be undone. Are you sure you want to permanently delete this grant?',
          textAlign: TextAlign.center,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: AppTheme.mediumGray, fontWeight: FontWeight.bold)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteGrant(id);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade50,
              foregroundColor: Colors.red,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Delete Now', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.white,
      appBar: AppBar(
        title: const Text('My Submissions'),
        backgroundColor: AppTheme.white,
        surfaceTintColor: AppTheme.white,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: const TextStyle(
          color: AppTheme.darkGray,
          fontSize: 18,
          fontWeight: FontWeight.w900,
        ),
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: CircleAvatar(
            backgroundColor: AppTheme.offWhite,
            child: IconButton(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppTheme.darkGray, size: 18),
            ),
          ),
        ),
      ),
      floatingActionButton: Container(
        height: 56,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: FloatingActionButton.extended(
          onPressed: () async {
            final result = await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const GrantEditorScreen(),
              ),
            );
            if (result == true) _fetchMyGrants();
          },
          label: const Text(
            'New Submission',
            style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 0.5),
          ),
          icon: const Icon(Icons.add_rounded, size: 24),
          backgroundColor: AppTheme.darkGray,
          foregroundColor: Colors.white,
          elevation: 4,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _myGrants.isEmpty
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
                              height: 120,
                              width: 120,
                              decoration: BoxDecoration(
                                color: AppTheme.offWhite,
                                borderRadius: BorderRadius.circular(40),
                              ),
                              child: Icon(
                                Icons.note_add_rounded, 
                                size: 50, 
                                color: AppTheme.mediumGray.withOpacity(0.2)
                              ),
                            ),
                            const SizedBox(height: 24),
                            const Text(
                              'No submissions yet',
                              style: TextStyle(
                                fontSize: 22,
                                color: AppTheme.darkGray,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 40),
                              child: Text(
                                'Help the community by submitting available grants you know of.',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 16,
                                  color: AppTheme.mediumGray,
                                  height: 1.5,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(24, 12, 24, 100),
                  itemCount: _myGrants.length,
                  separatorBuilder: (ctx, i) => const SizedBox(height: 20),
                  itemBuilder: (ctx, index) {
                    final grant = _myGrants[index];
                    return Column(
                      children: [
                        GrantCard(
                          grant: grant,
                          showEditButton: !grant.isVerified,
                          onTap: () async {
                            if (!grant.isVerified) {
                              final result = await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => GrantEditorScreen(
                                    grant: grant,
                                  ),
                                ),
                              );
                              if (result == true) _fetchMyGrants();
                            } else {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const GrantDetailScreen(),
                                  settings: RouteSettings(arguments: grant),
                                ),
                              );
                            }
                          },
                        ),
                        if (!grant.isVerified)
                          Padding(
                            padding: const EdgeInsets.only(top: 8, right: 8),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                TextButton.icon(
                                  onPressed: () => _confirmDelete(grant.id),
                                  icon: const Icon(Icons.delete_outline_rounded, size: 16),
                                  label: const Text('Remove submission', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                                  style: TextButton.styleFrom(
                                    foregroundColor: Colors.redAccent,
                                    visualDensity: VisualDensity.compact,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    );
                  },
                ),
    );
  }
}
