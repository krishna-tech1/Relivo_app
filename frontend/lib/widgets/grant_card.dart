import 'package:flutter/material.dart';
import '../models/grant.dart';
import '../theme/app_theme.dart';
import '../screens/grant_detail_screen.dart';

class GrantCard extends StatelessWidget {
  final Grant grant;
  final VoidCallback? onTap;
  final bool showEditButton;

  const GrantCard({
    super.key, 
    required this.grant,
    this.onTap,
    this.showEditButton = false,
  });

  @override
  Widget build(BuildContext context) {
    final catColor = AppTheme.getCategoryColor(grant.category);
    
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap ?? () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const GrantDetailScreen(),
                settings: RouteSettings(arguments: grant),
              ),
            );
          },
          borderRadius: BorderRadius.circular(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Top Section with Category and Status
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: catColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        grant.category.toUpperCase(),
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          color: catColor,
                          letterSpacing: 1.0,
                        ),
                      ),
                    ),
                    if (grant.isVerified)
                      const Icon(Icons.verified_rounded, color: AppTheme.success, size: 22)
                    else 
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.amber.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          "PENDING",
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                            color: Colors.orange,
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              // Title and Organizer
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      grant.title,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.darkGray,
                        height: 1.2,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.apartment_rounded, size: 14, color: AppTheme.mediumGray),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            grant.organizer,
                            style: const TextStyle(
                              fontSize: 14,
                              color: AppTheme.mediumGray,
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Bottom Info Bar
              Container(
                margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.offWhite,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'AMOUNT',
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.mediumGray,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            grant.amount,
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w900,
                              color: AppTheme.primaryBlue,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      width: 1,
                      height: 30,
                      color: AppTheme.lightGray,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'DEADLINE',
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                              color: grant.hasUpcomingDeadline ? Colors.red : AppTheme.mediumGray,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            grant.formattedDeadline,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: grant.hasUpcomingDeadline ? Colors.red : AppTheme.darkGray,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (showEditButton)
                      Padding(
                        padding: const EdgeInsets.only(left: 8),
                        child: CircleAvatar(
                          radius: 18,
                          backgroundColor: AppTheme.primaryBlue,
                          child: IconButton(
                            icon: const Icon(Icons.edit_rounded, size: 16, color: Colors.white),
                            onPressed: onTap,
                            padding: EdgeInsets.zero,
                          ),
                        ),
                      )
                    else 
                      const Icon(Icons.chevron_right_rounded, color: AppTheme.mediumGray),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _IconText extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color color;

  const _IconText({
    required this.icon,
    required this.text,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 6),
        Text(
          text,
          style: TextStyle(
            fontSize: 13,
            color: color,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
