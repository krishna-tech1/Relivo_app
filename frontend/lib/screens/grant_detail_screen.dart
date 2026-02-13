import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../theme/app_theme.dart';
import '../models/grant.dart';

class GrantDetailScreen extends StatelessWidget {
  const GrantDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final grant = ModalRoute.of(context)!.settings.arguments as Grant;

    return Scaffold(
      backgroundColor: AppTheme.white,
      body: CustomScrollView(
        slivers: [
          // Elegant Sliver App Bar
          SliverAppBar(
            expandedHeight: 120,
            floating: false,
            pinned: true,
            elevation: 0,
            backgroundColor: AppTheme.white,
            surfaceTintColor: AppTheme.white,
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
            flexibleSpace: FlexibleSpaceBar(
              centerTitle: true,
              title: Text(
                'Grant Details',
                style: TextStyle(
                  color: AppTheme.darkGray,
                  fontWeight: FontWeight.w900,
                  fontSize: 18,
                ),
              ),
              background: Container(color: AppTheme.white),
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Category and Verify Badge
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppTheme.getCategoryColor(grant.category).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          grant.category.toUpperCase(),
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                            color: AppTheme.getCategoryColor(grant.category),
                            letterSpacing: 1.0,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      if (grant.isVerified)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppTheme.success.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.verified_rounded, size: 14, color: AppTheme.success),
                              const SizedBox(width: 4),
                              const Text(
                                'VERIFIED',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w900,
                                  color: AppTheme.success,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  // Grant Title
                  Text(
                    grant.title,
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      color: AppTheme.darkGray,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Key Info Grid
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: AppTheme.offWhite,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Column(
                      children: [
                        _InfoRow(
                          icon: Icons.monetization_on_rounded,
                          label: 'GRANT AMOUNT',
                          value: grant.amount,
                          valueColor: AppTheme.primaryBlue,
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 16),
                          child: Divider(color: AppTheme.lightGray, height: 1),
                        ),
                        _InfoRow(
                          icon: Icons.calendar_today_rounded,
                          label: 'APPLICATION DEADLINE',
                          value: grant.formattedDeadline,
                          valueColor: grant.hasUpcomingDeadline ? Colors.red : null,
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 16),
                          child: Divider(color: AppTheme.lightGray, height: 1),
                        ),
                        _InfoRow(
                          icon: Icons.apartment_rounded,
                          label: 'ORGANIZATION',
                          value: grant.organizer,
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 16),
                          child: Divider(color: AppTheme.lightGray, height: 1),
                        ),
                        _InfoRow(
                          icon: Icons.public_rounded,
                          label: 'COUNTRY',
                          value: grant.country,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),

                    
                  // Description Card
                  _SectionCard(
                    title: 'Description',
                    icon: Icons.description_rounded,
                    child: Text(
                      grant.description,
                      style: const TextStyle(
                        fontSize: 16,
                        height: 1.6,
                        color: AppTheme.darkGray,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // Eligibility Criteria Card
                  _SectionCard(
                    title: 'Eligibility Criteria',
                    icon: Icons.check_circle_outline_rounded,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: grant.eligibilityCriteria.map((criteria) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Padding(
                                padding: EdgeInsets.only(top: 4),
                                child: Icon(
                                  Icons.check_circle_rounded,
                                  color: AppTheme.success,
                                  size: 18,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  criteria,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    height: 1.5,
                                    color: AppTheme.darkGray,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ),

                  const SizedBox(height: 120), // Bottom padding for FAB
                ],
              ),
            ),
          ),
        ],
      ),
      
      // Floating Apply Button
      floatingActionButton: Container(
        width: double.infinity,
        margin: const EdgeInsets.symmetric(horizontal: 24),
        height: 60,
        decoration: BoxDecoration(
          gradient: AppTheme.primaryGradient,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: AppTheme.primaryBlue.withOpacity(0.3),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: ElevatedButton(
          onPressed: () async {
            if (grant.applyUrl.isEmpty || grant.applyUrl == 'https://example.com/apply') {
               ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('No application link available for this grant'),
                  backgroundColor: AppTheme.warning,
                ),
              );
              return;
            }
            
            try {
              String fixedUrl = grant.applyUrl;
              if (!fixedUrl.startsWith('http://') && !fixedUrl.startsWith('https://')) {
                fixedUrl = 'https://$fixedUrl';
              }
              final Uri url = Uri.parse(fixedUrl);
              final canLaunch = await canLaunchUrl(url);
              
              if (!canLaunch) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Cannot open this URL: $fixedUrl'),
                      backgroundColor: AppTheme.error,
                    ),
                  );
                }
                return;
              }
              
              await launchUrl(url, mode: LaunchMode.externalApplication);
            } catch (e) {
               if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error: $e'),
                      backgroundColor: AppTheme.error,
                    ),
                  );
               }
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
          ),
          child: const Text(
            'Apply Now',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: AppTheme.white,
            ),
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppTheme.white,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, size: 20, color: AppTheme.primaryBlue),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: valueColor ?? AppTheme.darkGray,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.mediumGray,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;

  const _SectionCard({
    required this.title,
    required this.icon,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: AppTheme.darkGray, size: 22),
            const SizedBox(width: 10),
            Text(
              title,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w900,
                color: AppTheme.darkGray,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        child,
      ],
    );
  }
}
