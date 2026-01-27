"""
Quick Reference: Grants.gov Integration API

Copy-paste ready examples for testing and integration.
"""

# ============================================================================
# SETUP
# ============================================================================

# 1. Install dependencies
"""
cd refugee_app_backend
pip install -r requirements.txt
"""

# 2. Run migration
"""
python migrate_grants_schema.py
"""

# 3. Start backend
"""
uvicorn app.main:app --reload --port 8000
"""

# ============================================================================
# CURL EXAMPLES (Replace YOUR_ADMIN_TOKEN with actual token)
# ============================================================================

# Import grants from Grants.gov
"""
curl -X POST "http://localhost:8000/api/grants/admin/import" \
  -H "Authorization: Bearer YOUR_ADMIN_TOKEN" \
  -H "Content-Type: application/json"
"""

# Get unverified grants
"""
curl -X GET "http://localhost:8000/api/grants/admin/unverified" \
  -H "Authorization: Bearer YOUR_ADMIN_TOKEN"
"""

# Get verified grants
"""
curl -X GET "http://localhost:8000/api/grants/admin/verified" \
  -H "Authorization: Bearer YOUR_ADMIN_TOKEN"
"""

# Verify a grant (replace {id} with actual grant ID)
"""
curl -X PUT "http://localhost:8000/api/grants/admin/{id}/verify" \
  -H "Authorization: Bearer YOUR_ADMIN_TOKEN"
"""

# Update grant with refugee country
"""
curl -X PUT "http://localhost:8000/api/grants/admin/{id}" \
  -H "Authorization: Bearer YOUR_ADMIN_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "refugee_country": "Germany",
    "is_verified": true
  }'
"""

# Get public grants (no auth needed)
"""
curl -X GET "http://localhost:8000/api/grants/public?country=Germany"
"""

# Get statistics
"""
curl -X GET "http://localhost:8000/api/grants/admin/stats" \
  -H "Authorization: Bearer YOUR_ADMIN_TOKEN"
"""

# ============================================================================
# PYTHON EXAMPLES
# ============================================================================

# Test import programmatically
"""
from app.services.grants_gov_importer import GrantsGovImporter
from db.session import SessionLocal

db = SessionLocal()
importer = GrantsGovImporter(db)
result = importer.import_grants()

print(f"Imported: {result['imported']}")
print(f"Skipped: {result['skipped']}")
print(f"Errors: {result['errors']}")
"""

# Query grants by verification status
"""
from db.session import SessionLocal
from db import models

db = SessionLocal()

# Get unverified grants
unverified = db.query(models.Grant).filter(
    models.Grant.is_verified == False
).all()

# Get verified grants
verified = db.query(models.Grant).filter(
    models.Grant.is_verified == True
).all()

# Get public grants (verified & active)
public = db.query(models.Grant).filter(
    models.Grant.is_verified == True,
    models.Grant.is_active == True
).all()

print(f"Unverified: {len(unverified)}")
print(f"Verified: {len(verified)}")
print(f"Public: {len(public)}")
"""

# Verify a grant
"""
from db.session import SessionLocal
from db import models

db = SessionLocal()

grant = db.query(models.Grant).filter(models.Grant.id == 1).first()
if grant:
    grant.is_verified = True
    grant.refugee_country = "Germany"
    db.commit()
    print(f"Verified: {grant.title}")
"""

# ============================================================================
# FLUTTER/DART INTEGRATION
# ============================================================================

# Update Grant Service
"""
// Add to grant_service.dart

Future<List<Grant>> getVerifiedGrants() async {
  final response = await _dio.get(
    '/grants/admin/verified',
    options: Options(headers: {'Authorization': 'Bearer \$token'}),
  );
  return (response.data as List).map((g) => Grant.fromJson(g)).toList();
}

Future<List<Grant>> getUnverifiedGrants() async {
  final response = await _dio.get(
    '/grants/admin/unverified',
    options: Options(headers: {'Authorization': 'Bearer \$token'}),
  );
  return (response.data as List).map((g) => Grant.fromJson(g)).toList();
}

Future<Grant> verifyGrant(String grantId) async {
  final response = await _dio.put(
    '/grants/admin/\$grantId/verify',
    options: Options(headers: {'Authorization': 'Bearer \$token'}),
  );
  return Grant.fromJson(response.data);
}

Future<Map<String, dynamic>> importFromGrantsGov() async {
  final response = await _dio.post(
    '/grants/admin/import',
    options: Options(headers: {'Authorization': 'Bearer \$token'}),
  );
  return response.data;
}

Future<List<Grant>> getPublicGrants({String? country}) async {
  final response = await _dio.get(
    '/grants/public',
    queryParameters: country != null ? {'country': country} : null,
  );
  return (response.data as List).map((g) => Grant.fromJson(g)).toList();
}
"""

# Update Grant Model
"""
// Update grant.dart model

class Grant {
  final String id;
  final String title;
  final String organizer;  // renamed from provider
  final String? description;
  final String? eligibility;
  final DateTime? deadline;
  final String applyUrl;
  final String source;  // "manual" or "grants.gov"
  final String? externalId;
  final String? refugeeCountry;
  final bool isVerified;
  final bool isActive;
  final String? amount;
  final String? location;
  final List<String>? eligibilityCriteria;
  final List<String>? requiredDocuments;
  final DateTime createdAt;
  final DateTime? updatedAt;

  Grant({
    required this.id,
    required this.title,
    required this.organizer,
    this.description,
    this.eligibility,
    this.deadline,
    required this.applyUrl,
    this.source = 'manual',
    this.externalId,
    this.refugeeCountry,
    this.isVerified = false,
    this.isActive = true,
    this.amount,
    this.location,
    this.eligibilityCriteria,
    this.requiredDocuments,
    required this.createdAt,
    this.updatedAt,
  });

  factory Grant.fromJson(Map<String, dynamic> json) {
    return Grant(
      id: json['id'].toString(),
      title: json['title'],
      organizer: json['organizer'],
      description: json['description'],
      eligibility: json['eligibility'],
      deadline: json['deadline'] != null ? DateTime.parse(json['deadline']) : null,
      applyUrl: json['apply_url'],
      source: json['source'] ?? 'manual',
      externalId: json['external_id'],
      refugeeCountry: json['refugee_country'],
      isVerified: json['is_verified'] ?? false,
      isActive: json['is_active'] ?? true,
      amount: json['amount'],
      location: json['location'],
      eligibilityCriteria: json['eligibility_criteria'] != null 
          ? List<String>.from(json['eligibility_criteria']) 
          : null,
      requiredDocuments: json['required_documents'] != null 
          ? List<String>.from(json['required_documents']) 
          : null,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at']) : null,
    );
  }

  String get formattedDeadline {
    if (deadline == null) return 'No deadline';
    return '\${deadline!.day}/\${deadline!.month}/\${deadline!.year}';
  }

  bool get hasUpcomingDeadline {
    if (deadline == null) return false;
    final now = DateTime.now();
    final difference = deadline!.difference(now).inDays;
    return difference <= 7 && difference >= 0;
  }
}
"""

# ============================================================================
# TESTING COMMANDS
# ============================================================================

# Run integration tests
"""
cd refugee_app_backend
python test_grants_integration.py
"""

# Check database directly (PostgreSQL)
"""
psql $DATABASE_URL

-- View all grants
SELECT id, title, organizer, source, is_verified, is_active, refugee_country 
FROM grants 
ORDER BY created_at DESC 
LIMIT 10;

-- Count by status
SELECT 
  COUNT(*) as total,
  SUM(CASE WHEN is_verified THEN 1 ELSE 0 END) as verified,
  SUM(CASE WHEN NOT is_verified THEN 1 ELSE 0 END) as unverified,
  SUM(CASE WHEN is_active THEN 1 ELSE 0 END) as active
FROM grants;

-- Count by source
SELECT source, COUNT(*) 
FROM grants 
GROUP BY source;
"""

# ============================================================================
# TROUBLESHOOTING
# ============================================================================

# If migration fails
"""
# Check current schema
psql $DATABASE_URL -c "\d grants"

# Manually add missing column (example)
psql $DATABASE_URL -c "ALTER TABLE grants ADD COLUMN is_verified BOOLEAN DEFAULT FALSE;"
"""

# If import fails
"""
# Check logs
tail -f logs/app.log

# Test URL manually
curl -I https://www.grants.gov/xml/extract/GrantsDBExtractv2.zip

# Test with smaller dataset (create test XML)
"""

# If grants not appearing publicly
"""
# Check verification status
psql $DATABASE_URL -c "SELECT id, title, is_verified, is_active FROM grants LIMIT 10;"

# Manually verify a grant
psql $DATABASE_URL -c "UPDATE grants SET is_verified = TRUE, is_active = TRUE WHERE id = 1;"
"""

# ============================================================================
# DEPLOYMENT CHECKLIST
# ============================================================================

"""
□ Run migration on production database
□ Test import on staging environment first
□ Set up monitoring for import errors
□ Configure rate limiting on import endpoint
□ Set up scheduled imports (optional)
□ Update frontend to use new endpoints
□ Test verification workflow end-to-end
□ Update user documentation
□ Train admins on verification process
"""

# ============================================================================
# MONITORING & MAINTENANCE
# ============================================================================

# Check import statistics
"""
curl -X GET "http://localhost:8000/api/grants/admin/stats" \
  -H "Authorization: Bearer YOUR_ADMIN_TOKEN"
"""

# Monitor database size
"""
psql $DATABASE_URL -c "
SELECT 
  pg_size_pretty(pg_total_relation_size('grants')) as total_size,
  COUNT(*) as total_grants
FROM grants;
"
"""

# Clean up old unverified grants (optional)
"""
DELETE FROM grants 
WHERE is_verified = FALSE 
  AND created_at < NOW() - INTERVAL '90 days'
  AND source = 'grants.gov';
"""
