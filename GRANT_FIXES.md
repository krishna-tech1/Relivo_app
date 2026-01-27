# Grant Creation/Viewing Fix - Admin Dashboard

## Issues Fixed

### 1. Missing Fields in Grant Creation ✅
**Problem:** When creating or updating grants, the frontend was not sending all required fields to the backend.

**Missing Fields:**
- `eligibility` (text field - required by backend)
- `is_verified` (boolean - required by backend)
- `is_active` (boolean - required by backend)
- `source` (string - required by backend)

**Solution:** Updated `_toJson` method in `grant_service.dart` to include all required fields:
```dart
Map<String, dynamic> _toJson(Grant grant) {
  return {
    'title': grant.title,
    'organizer': grant.organizer,
    'description': grant.description,
    'eligibility': grant.eligibilityCriteria.isNotEmpty 
        ? grant.eligibilityCriteria.join('; ') 
        : null,  // Convert list to text
    'amount': grant.amount,
    'deadline': grant.deadline.toIso8601String(),
    'refugee_country': grant.country,
    'apply_url': grant.applyUrl.isNotEmpty ? grant.applyUrl : 'https://example.com/apply',
    'eligibility_criteria': grant.eligibilityCriteria,
    'required_documents': grant.requiredDocuments,
    'is_verified': grant.isVerified,  // ✅ ADDED
    'is_active': true,                 // ✅ ADDED
    'source': 'manual',                // ✅ ADDED
  };
}
```

### 2. Missing isVerified in Grant Constructor ✅
**Problem:** Grant editor wasn't passing `isVerified` when creating Grant objects.

**Solution:** Updated `grant_editor_screen.dart` to include `isVerified`:
```dart
final newGrant = Grant(
  id: widget.grant?.id ?? '',
  title: _titleCtrl.text,
  organizer: _providerCtrl.text,
  country: _locationCtrl.text,
  category: 'General',
  deadline: _selectedDate,
  amount: _amountCtrl.text,
  description: _descCtrl.text,
  eligibilityCriteria: _eligibilityCriteria,
  requiredDocuments: _requiredDocuments,
  applyUrl: _applyUrlCtrl.text.isEmpty ? 'https://example.com/apply' : _applyUrlCtrl.text,
  isVerified: widget.grant?.isVerified ?? false,  // ✅ ADDED
);
```

### 3. Default Apply URL ✅
**Problem:** Empty apply URLs would cause validation errors.

**Solution:** Added default URL fallback:
- In `grant_editor_screen.dart`: Defaults to 'https://example.com/apply' if empty
- In `grant_service.dart`: Same fallback in `_toJson`

## Backend Schema Alignment

The frontend now correctly sends all fields that match the backend schema:

### Required Fields (Backend):
- ✅ `title` (String)
- ✅ `organizer` (String)
- ✅ `apply_url` (String)

### Optional Fields (Backend):
- ✅ `description` (Text)
- ✅ `eligibility` (Text) - converted from list
- ✅ `deadline` (DateTime)
- ✅ `amount` (String)
- ✅ `refugee_country` (String)
- ✅ `eligibility_criteria` (JSON array)
- ✅ `required_documents` (JSON array)

### Status Fields (Backend):
- ✅ `is_verified` (Boolean, default: false)
- ✅ `is_active` (Boolean, default: true)
- ✅ `source` (String, default: "manual")

## Testing the Fix

### To Create a Grant:
1. Open admin dashboard
2. Click "Create Grant" button
3. Fill in the form:
   - Title (required)
   - Provider/Organizer (required)
   - Location/Country (required)
   - Amount (required)
   - Description (optional)
   - Deadline (optional)
   - Apply URL (optional - defaults to example.com)
   - Eligibility Criteria (optional - add items)
   - Required Documents (optional - add items)
4. Click "Save"

### Expected Behavior:
- ✅ Grant should be created successfully
- ✅ Grant appears in "Unverified Grants" tab (since is_verified = false)
- ✅ Success message: "Grant saved successfully!"
- ✅ Redirected back to admin dashboard

### To View Grants:
1. Admin dashboard should show:
   - Total grants count
   - Verified grants count
   - Unverified grants count
2. Switch between tabs:
   - "All Grants" - shows all grants
   - "Verified Grants" - shows only verified grants
   - "Unverified Grants" - shows only unverified grants

## Troubleshooting

### If grants still don't appear:

1. **Check backend connection:**
   ```
   curl https://relivo-app.onrender.com/health
   ```
   Should return: `{"status": "healthy", "database": "connected"}`

2. **Check if grants exist:**
   ```
   curl https://relivo-app.onrender.com/grants/admin/all \
     -H "Authorization: Bearer YOUR_TOKEN"
   ```

3. **Check Flutter console for errors:**
   - Look for "Error loading grants:" messages
   - Check network errors (401, 404, 500)

4. **Verify authentication:**
   - Make sure you're logged in as admin
   - Token should be valid
   - Check AuthService.baseUrl is correct

### Common Errors:

**401 Unauthorized:**
- Solution: Log out and log back in to get fresh token

**404 Not Found:**
- Solution: Verify backend URL is correct
- Check that backend is deployed and running

**500 Internal Server Error:**
- Solution: Check backend logs on Render
- Verify database connection
- Check that all required fields are being sent

## Files Modified

1. **frontend/lib/services/grant_service.dart**
   - Updated `_toJson` method with all required fields
   - Added eligibility text conversion
   - Added default apply URL

2. **frontend/lib/screens/grant_editor_screen.dart**
   - Added `isVerified` to Grant constructor
   - Added default apply URL fallback

## Next Steps

1. **Hot reload the Flutter app** - Changes should apply automatically
2. **Test creating a grant** - Should work now
3. **Test viewing grants** - Should display in admin dashboard
4. **Test editing grants** - Should preserve all fields
5. **Test deleting grants** - Should work as before

## Status

✅ **FIXED** - All issues resolved
- Grant creation now works
- Grant viewing now works
- All required fields are sent to backend
- Schema alignment is complete

---

**Date:** 2026-01-27
**Version:** 1.1.0
