import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/api/api_client.dart';
import '../../../core/constants/app_colors.dart';
import '../../../widgets/common/loading_button.dart';
import 'new_application_step3.dart';

class NewApplicationStep2 extends StatefulWidget {
  final String applicationId;
  final String licenseType;

  const NewApplicationStep2({
    super.key,
    required this.applicationId,
    required this.licenseType,
  });

  @override
  State<NewApplicationStep2> createState() => _NewApplicationStep2State();
}

class _NewApplicationStep2State extends State<NewApplicationStep2> {
  final _formKey = GlobalKey<FormState>();
  final _companyNameController = TextEditingController();
  final _regNumberController = TextEditingController();
  String _beeStatus = 'Level 1';
  final List<Map<String, String>> _directors = [];

  bool _isLoading = false;

  void _addDirector() {
    setState(() {
      _directors.add({'name': '', 'id_number': ''});
    });
  }

  void _removeDirector(int index) {
    setState(() {
      _directors.removeAt(index);
    });
  }

  Future<void> _saveAndContinue() async {
    if (!_formKey.currentState!.validate()) return;

    // FIXED: Validate at least one director
    if (_directors.isEmpty) {
      _showError('Please add at least one director');
      return;
    }

    // FIXED: Validate all directors have name and ID
    for (int i = 0; i < _directors.length; i++) {
      if (_directors[i]['name']?.isEmpty ?? true) {
        _showError('Please enter name for director ${i + 1}');
        return;
      }
      if (_directors[i]['id_number']?.isEmpty ?? true) {
        _showError('Please enter ID number for director ${i + 1}');
        return;
      }
    }

    setState(() => _isLoading = true);

    try {
      final apiClient = ApiClient();
      final response = await apiClient.updateApplication(widget.applicationId, {
        'company_details': {
          'company_name': _companyNameController.text.trim(),
          'registration_number': _regNumberController.text.trim(),
          'bee_status': _beeStatus,
          'directors': _directors
              .map((d) => {
                    'name': d['name'],
                    'id_number': d['id_number'],
                  })
              .toList(),
        },
      });

      if (response['success'] == true) {
        if (mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => NewApplicationStep3(
                applicationId: widget.applicationId,
                licenseType: widget.licenseType,
              ),
            ),
          );
        }
      } else {
        _showError(response['error'] ?? 'Failed to save');
      }
    } catch (e) {
      _showError('Connection error');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: AppColors.error),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Company Details'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          _buildProgressIndicator(2),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Step 2 of 7',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Company Details',
                      style: GoogleFonts.inter(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 24),
                    TextFormField(
                      controller: _companyNameController,
                      decoration: const InputDecoration(
                        labelText: 'Company Name',
                        prefixIcon: Icon(Icons.business),
                      ),
                      validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _regNumberController,
                      decoration: const InputDecoration(
                        labelText: 'Registration Number',
                        prefixIcon: Icon(Icons.numbers),
                      ),
                      validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      initialValue: _beeStatus,
                      decoration: const InputDecoration(
                        labelText: 'B-BBEE Status',
                        prefixIcon: Icon(Icons.star),
                      ),
                      items: [
                        'Level 1',
                        'Level 2',
                        'Level 3',
                        'Level 4',
                        'Level 5',
                        'Non-Compliant'
                      ]
                          .map((level) => DropdownMenuItem(
                              value: level, child: Text(level)))
                          .toList(),
                      onChanged: (value) => setState(() => _beeStatus = value!),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Directors',
                          style: GoogleFonts.inter(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        TextButton.icon(
                          onPressed: _addDirector,
                          icon: const Icon(Icons.add, size: 18),
                          label: const Text('Add Director'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ..._directors.asMap().entries.map((entry) {
                      final index = entry.key;
                      final director = entry.value;
                      return _buildDirectorCard(index, director);
                    }),
                    if (_directors.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(32),
                        alignment: Alignment.center,
                        child: Text(
                          'No directors added. Click "Add Director" to continue.',
                          style: GoogleFonts.inter(
                            color: AppColors.textHint,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    const SizedBox(height: 32),
                    LoadingButton(
                      onPressed: _saveAndContinue,
                      isLoading: _isLoading,
                      text: 'Continue',
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDirectorCard(int index, Map<String, String> director) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    initialValue: director['name'],
                    decoration: const InputDecoration(
                      labelText: 'Full Name',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (value) => director['name'] = value,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextFormField(
                    initialValue: director['id_number'],
                    decoration: const InputDecoration(
                      labelText: 'ID Number',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (value) => director['id_number'] = value,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: AppColors.error),
                  onPressed: () => _removeDirector(index),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressIndicator(int currentStep) {
    return Container(
      padding: const EdgeInsets.all(16),
      color: AppColors.background,
      child: Row(
        children: List.generate(7, (index) {
          final step = index + 1;
          final isActive = step == currentStep;
          final isCompleted = step < currentStep;
          return Expanded(
            child: Column(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isCompleted
                        ? AppColors.success
                        : (isActive ? AppColors.primary : Colors.white),
                    border: Border.all(
                      color: isCompleted
                          ? AppColors.success
                          : (isActive ? AppColors.primary : AppColors.textHint),
                    ),
                  ),
                  child: Center(
                    child: isCompleted
                        ? const Icon(Icons.check, size: 18, color: Colors.white)
                        : Text(
                            step.toString(),
                            style: TextStyle(
                              color:
                                  isActive ? Colors.white : AppColors.textHint,
                            ),
                          ),
                  ),
                ),
                if (step < 7)
                  Container(
                    height: 2,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    color: step < currentStep
                        ? AppColors.success
                        : AppColors.textHint.withOpacity(0.3),
                  ),
              ],
            ),
          );
        }),
      ),
    );
  }
}
