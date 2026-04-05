import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../../core/api/api_client.dart';
import '../../../core/constants/app_colors.dart';
import '../../../models/site.dart';
import '../../../widgets/common/loading_button.dart';

class InspectionLogScreen extends StatefulWidget {
  final Site site;

  const InspectionLogScreen({super.key, required this.site});

  @override
  State<InspectionLogScreen> createState() => _InspectionLogScreenState();
}

class _InspectionLogScreenState extends State<InspectionLogScreen> {
  final _formKey = GlobalKey<FormState>();
  final _findingsController = TextEditingController();
  final _apiClient = ApiClient();

  String _inspectionType = 'annual';
  bool _passed = true;
  int _riskImpact = 0;
  final List<File> _photos = [];
  bool _isLoading = false;

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.camera);
    if (pickedFile != null) {
      setState(() {
        _photos.add(File(pickedFile.path));
      });
    }
  }

  Future<void> _submitInspection() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final response = await _apiClient.createInspection({
        'site_id': widget.site.id,
        'inspection_type': _inspectionType,
        'findings': _findingsController.text,
        'passed': _passed,
        'risk_impact': _riskImpact,
      });

      if (response['success'] == true) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Inspection logged successfully'),
              backgroundColor: AppColors.success,
            ),
          );
          Navigator.pop(context, true);
        }
      } else {
        _showError(response['error'] ?? 'Failed to log inspection');
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
        title: Text('Inspection: ${widget.site.siteName}'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Site Info Card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Site Information',
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const Divider(),
                      _buildInfoRow('Site Name', widget.site.siteName),
                      _buildInfoRow('Address', widget.site.physicalAddress),
                      _buildInfoRow('License', widget.site.licenseNumber),
                      _buildInfoRow('Last Inspection',
                          widget.site.formattedLastInspection),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Inspection Type
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Inspection Details',
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const Divider(),
                      DropdownButtonFormField<String>(
                        initialValue: _inspectionType,
                        decoration: const InputDecoration(
                          labelText: 'Inspection Type',
                          border: OutlineInputBorder(),
                        ),
                        items: const [
                          DropdownMenuItem(
                              value: 'initial',
                              child: Text('Initial Inspection')),
                          DropdownMenuItem(
                              value: 'annual',
                              child: Text('Annual Inspection')),
                          DropdownMenuItem(
                              value: 'follow_up',
                              child: Text('Follow-up Inspection')),
                          DropdownMenuItem(
                              value: 'random',
                              child: Text('Random Inspection')),
                        ],
                        onChanged: (value) {
                          if (value != null) {
                            setState(() => _inspectionType = value);
                          }
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _findingsController,
                        maxLines: 4,
                        decoration: const InputDecoration(
                          labelText: 'Findings / Observations',
                          border: OutlineInputBorder(),
                          hintText:
                              'Describe what was found during inspection...',
                        ),
                        validator: (v) =>
                            v?.isEmpty ?? true ? 'Required' : null,
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          const Text('Result:'),
                          const SizedBox(width: 16),
                          Expanded(
                            child: SegmentedButton<bool>(
                              segments: const [
                                ButtonSegment(
                                    value: true,
                                    label: Text('Passed'),
                                    icon: Icon(Icons.check)),
                                ButtonSegment(
                                    value: false,
                                    label: Text('Failed'),
                                    icon: Icon(Icons.close)),
                              ],
                              selected: {_passed},
                              onSelectionChanged: (Set<bool> selection) {
                                setState(() => _passed = selection.first);
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        initialValue: _riskImpact.toString(),
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Risk Impact (points to add/subtract)',
                          border: OutlineInputBorder(),
                          helperText:
                              'Positive = increased risk, Negative = reduced risk',
                        ),
                        onChanged: (value) {
                          _riskImpact = int.tryParse(value) ?? 0;
                        },
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Photos
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Photos / Evidence',
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const Divider(),
                      if (_photos.isNotEmpty)
                        SizedBox(
                          height: 100,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: _photos.length,
                            itemBuilder: (context, index) {
                              return Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: Stack(
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: Image.file(
                                        _photos[index],
                                        width: 100,
                                        height: 100,
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                    Positioned(
                                      top: 4,
                                      right: 4,
                                      child: GestureDetector(
                                        onTap: () {
                                          setState(() {
                                            _photos.removeAt(index);
                                          });
                                        },
                                        child: Container(
                                          decoration: const BoxDecoration(
                                            color: Colors.black54,
                                            shape: BoxShape.circle,
                                          ),
                                          child: const Icon(
                                            Icons.close,
                                            size: 20,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                      const SizedBox(height: 8),
                      OutlinedButton.icon(
                        onPressed: _pickImage,
                        icon: const Icon(Icons.camera_alt),
                        label: const Text('Add Photo'),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              LoadingButton(
                onPressed: _submitInspection,
                isLoading: _isLoading,
                text: 'Submit Inspection Report',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 12,
                color: AppColors.textHint,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.inter(fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}
