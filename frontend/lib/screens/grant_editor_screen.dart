import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:refugee_app/models/grant.dart';
import 'package:refugee_app/theme/app_theme.dart';
import 'package:refugee_app/services/grant_service.dart';

class GrantEditorScreen extends StatefulWidget {
  final Grant? grant;

  const GrantEditorScreen({
    super.key, 
    this.grant,
  });

  @override
  State<GrantEditorScreen> createState() => _GrantEditorScreenState();
}

class _GrantEditorScreenState extends State<GrantEditorScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleCtrl;
  late TextEditingController _providerCtrl;
  late TextEditingController _amountCtrl;
  late TextEditingController _descCtrl;
  late TextEditingController _locationCtrl;
  late TextEditingController _applyUrlCtrl;
  
  List<String> _eligibilityCriteria = [];
  List<String> _requiredDocuments = [];
  DateTime _selectedDate = DateTime.now().add(const Duration(days: 30));
  String _selectedCategory = 'General';
  bool _isLoading = false;

  final _grantService = GrantService();

  @override
  void initState() {
    super.initState();
    _titleCtrl = TextEditingController(text: widget.grant?.title ?? '');
    _providerCtrl = TextEditingController(text: widget.grant?.organizer ?? '');
    _amountCtrl = TextEditingController(text: widget.grant?.amount ?? '');
    _descCtrl = TextEditingController(text: widget.grant?.description ?? '');
    _locationCtrl = TextEditingController(text: widget.grant?.country ?? '');
    _applyUrlCtrl = TextEditingController(text: widget.grant?.applyUrl ?? '');
    
    if (widget.grant != null) {
      _selectedDate = widget.grant!.deadline;
      _selectedCategory = widget.grant!.category;
      _eligibilityCriteria = List.from(widget.grant!.eligibilityCriteria);
      _requiredDocuments = List.from(widget.grant!.requiredDocuments);
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _providerCtrl.dispose();
    _amountCtrl.dispose();
    _descCtrl.dispose();
    _locationCtrl.dispose();
    _applyUrlCtrl.dispose();
    super.dispose();
  }

  Future<void> _saveGrant() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _isLoading = true);
    
    try {
      final newGrant = Grant(
        id: widget.grant?.id ?? '', // ID ignored on create
        title: _titleCtrl.text,
        organizer: _providerCtrl.text,
        country: _locationCtrl.text,
        category: _selectedCategory,
        deadline: _selectedDate,
        amount: _amountCtrl.text,
        description: _descCtrl.text,
        eligibilityCriteria: _eligibilityCriteria,
        requiredDocuments: _requiredDocuments,
        applyUrl: _applyUrlCtrl.text.isEmpty ? 'https://example.com/apply' : _applyUrlCtrl.text,
        isVerified: widget.grant?.isVerified ?? false, // Preserve existing or default to false
      );

      if (widget.grant == null) {
        await _grantService.submitUserGrant(newGrant);
      } else {
        await _grantService.updateMyGrant(newGrant);
      }
      
      if (mounted) {
        AppTheme.showSuccess(context, widget.grant == null ? 'Grant submitted successfully!' : 'Grant updated successfully!');
        Navigator.pop(context, true); // Return true to indicate success
      }
    } catch (e) {
      if (mounted) {
        AppTheme.showAlert(context, 'Error saving grant: $e');
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _addListItem(List<String> list, String itemName) {
    showDialog(
      context: context,
      builder: (context) {
        final ctrl = TextEditingController();
        return AlertDialog(
          title: Text('Add $itemName'),
          content: TextField(
            controller: ctrl,
            decoration: InputDecoration(
              hintText: 'e.g., Valid Passport',
              filled: true,
              fillColor: AppTheme.offWhite,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            ),
            autofocus: true,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context), 
              child: const Text('Cancel', style: TextStyle(color: AppTheme.mediumGray)),
            ),
            ElevatedButton(
              onPressed: () {
                if (ctrl.text.isNotEmpty) {
                  setState(() => list.add(ctrl.text));
                  Navigator.pop(context);
                }
              },
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Add Item'),
            ),
          ],
        );
      },
    );
  }

  void _editListItem(List<String> list, int index, String itemName) {
    showDialog(
      context: context,
      builder: (context) {
        final ctrl = TextEditingController(text: list[index]);
        return AlertDialog(
          title: Text('Edit $itemName'),
          content: TextField(
            controller: ctrl,
            decoration: InputDecoration(
              hintText: 'e.g., Valid Passport',
              filled: true,
              fillColor: AppTheme.offWhite,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            ),
            autofocus: true,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context), 
              child: const Text('Cancel', style: TextStyle(color: AppTheme.mediumGray)),
            ),
            TextButton(
              onPressed: () {
                setState(() => list.removeAt(index));
                Navigator.pop(context);
              },
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Remove'),
            ),
            ElevatedButton(
              onPressed: () {
                if (ctrl.text.isNotEmpty) {
                  setState(() => list[index] = ctrl.text);
                  Navigator.pop(context);
                }
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSectionHeader(String title, VoidCallback onAdd) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
          IconButton(
            onPressed: onAdd,
            icon: const Icon(Icons.add_circle, color: AppTheme.primaryColor),
          ),
        ],
      ),
    );
  }

  Widget _buildList(List<String> list, String itemName) {
    if (list.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(8.0),
        child: Text('No $itemName added yet.', style: const TextStyle(color: Colors.grey, fontStyle: FontStyle.italic)),
      );
    }
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: list.length,
      itemBuilder: (context, index) {
        return Card(
          elevation: 0,
          color: Colors.grey[100],
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            title: Text(list[index]),
            trailing: const Icon(Icons.edit, size: 16),
            onTap: () => _editListItem(list, index, itemName),
            dense: true,
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.grant == null ? 'Create Grant' : 'Edit Grant'),
        actions: [
          IconButton(
            onPressed: _isLoading ? null : _saveGrant,
            icon: _isLoading 
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) 
                : const Icon(Icons.save),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 100.0), // Added bottom padding for navigation bar
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Basic Info Section
              const Text('Basic Information', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.primaryColor)),
              const SizedBox(height: 16),
              
              TextFormField(
                controller: _titleCtrl,
                maxLength: 100,
                decoration: const InputDecoration(labelText: 'Grant Title *', prefixIcon: Icon(Icons.title)),
                validator: (v) => v!.isEmpty ? 'Required' : (v.length < 3 ? 'Too short' : null),
              ),
              const SizedBox(height: 16),

              DropdownButtonFormField<String>(
                value: GrantData.categories.contains(_selectedCategory) && _selectedCategory != 'All Categories' 
                    ? _selectedCategory 
                    : 'General',
                decoration: const InputDecoration(
                  labelText: 'Category *',
                  prefixIcon: Icon(Icons.category),
                ),
                items: GrantData.categories
                    .where((c) => c != 'All Categories')
                    .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                    .toList(),
                onChanged: (v) => setState(() => _selectedCategory = v!),
                validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _providerCtrl,
                      maxLength: 100,
                      decoration: const InputDecoration(labelText: 'Provider *', prefixIcon: Icon(Icons.business)),
                      validator: (v) => v!.isEmpty ? 'Required' : null,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _locationCtrl,
                      maxLength: 50,
                      decoration: const InputDecoration(labelText: 'Location *', prefixIcon: Icon(Icons.location_on)),
                      validator: (v) => v!.isEmpty ? 'Required' : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _amountCtrl,
                maxLength: 50,
                decoration: const InputDecoration(
                  labelText: 'Amount *', 
                  prefixIcon: Icon(Icons.payments_outlined),
                  hintText: 'e.g., \$500 or €1,000',
                ),
                validator: (v) => v!.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _descCtrl,
                maxLength: 2000,
                decoration: const InputDecoration(labelText: 'Description', prefixIcon: Icon(Icons.description)),
                maxLines: 5,
              ),
              const SizedBox(height: 16),

              InkWell(
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _selectedDate,
                    firstDate: DateTime.now(),
                    lastDate: DateTime(2030),
                  );
                  if (picked != null) setState(() => _selectedDate = picked);
                },
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Deadline',
                    prefixIcon: Icon(Icons.calendar_today),
                  ),
                  child: Text(DateFormat('yyyy-MM-dd').format(_selectedDate)),
                ),
              ),
              
              const SizedBox(height: 24),
              const Divider(),
              const SizedBox(height: 16),
              
              // Apply Configuration
              const Text('Application Settings', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.primaryColor)),
              const SizedBox(height: 8),
               TextFormField(
                controller: _applyUrlCtrl,
                decoration: const InputDecoration(
                  labelText: 'Apply Button URL', 
                  prefixIcon: Icon(Icons.link),
                  hintText: 'https://example.com/apply-here',
                  helperText: 'Users will be redirected to this link when they click Apply',
                ),
                validator: (v) {
                  if (v == null || v.isEmpty) return null; // Optional
                  if (!v.contains('.') || v.length < 5) return 'Invalid URL';
                  return null;
                },
              ),
              
              const SizedBox(height: 24),
              const Divider(),
              const SizedBox(height: 16),

              // Dynamic Lists
              _buildSectionHeader('Eligibility Criteria', () => _addListItem(_eligibilityCriteria, 'Criteria')),
              _buildList(_eligibilityCriteria, 'Criteria'),

              const SizedBox(height: 16),


              
              const SizedBox(height: 32),
              
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveGrant,
                  child: const Text('Save Grant'),
                ),
              ),
              const SizedBox(height: 24), // Extra spacing after button
            ],
          ),
        ),
      ),
    );
  }
}
