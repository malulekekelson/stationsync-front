import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:geolocator/geolocator.dart';
import '../../../core/api/api_client.dart';
import '../../../core/constants/app_colors.dart';
import '../../../widgets/common/loading_button.dart';
import 'new_application_step4.dart';

class NewApplicationStep3 extends StatefulWidget {
  final String applicationId;
  final String licenseType;

  const NewApplicationStep3({
    super.key,
    required this.applicationId,
    required this.licenseType,
  });

  @override
  State<NewApplicationStep3> createState() => _NewApplicationStep3State();
}

class _NewApplicationStep3State extends State<NewApplicationStep3> {
  final _formKey = GlobalKey<FormState>();
  final _siteNameController = TextEditingController();
  final _addressController = TextEditingController();
  final _latitudeController = TextEditingController();
  final _longitudeController = TextEditingController();
  final _capacityController = TextEditingController();

  bool _isLoading = false;
  bool _gettingLocation = false;

  Future<void> _getCurrentLocation() async {
    setState(() => _gettingLocation = true);

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _showError('Location services are disabled');
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _showError('Location permissions are denied');
          return;
        }
      }

      Position position = await Geolocator.getCurrentPosition();
      setState(() {
        _latitudeController.text = position.latitude.toString();
        _longitudeController.text = position.longitude.toString();
      });
    } catch (e) {
      _showError('Failed to get location');
    } finally {
      if (mounted) setState(() => _gettingLocation = false);
    }
  }

  Future<void> _saveAndContinue() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final apiClient = ApiClient();
      final response = await apiClient.updateApplication(widget.applicationId, {
        'site_details': {
          'site_name': _siteNameController.text.trim(),
          'physical_address': _addressController.text.trim(),
          'gps_coordinates':
              '${_latitudeController.text},${_longitudeController.text}',
          'storage_capacity': int.tryParse(_capacityController.text) ?? 0,
        },
      });

      if (response['success'] == true) {
        if (mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => NewApplicationStep4(
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
        title: const Text('Site Details'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          _buildProgressIndicator(3),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Step 3 of 7',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Site Details',
                      style: GoogleFonts.inter(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 24),
                    TextFormField(
                      controller: _siteNameController,
                      decoration: const InputDecoration(
                        labelText: 'Site Name',
                        prefixIcon: Icon(Icons.location_city),
                      ),
                      validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _addressController,
                      decoration: const InputDecoration(
                        labelText: 'Physical Address',
                        prefixIcon: Icon(Icons.location_on),
                      ),
                      maxLines: 2,
                      validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _capacityController,
                      decoration: const InputDecoration(
                        labelText: 'Storage Capacity (liters)',
                        prefixIcon: Icon(Icons.warehouse),
                      ),
                      keyboardType: TextInputType.number,
                      validator: (v) {
                        if (v?.isEmpty ?? true) return 'Required';
                        if (int.tryParse(v!) == null) return 'Invalid number';
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'GPS Coordinates',
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _latitudeController,
                            decoration: const InputDecoration(
                              labelText: 'Latitude',
                              prefixIcon: Icon(Icons.map),
                            ),
                            validator: (v) =>
                                v?.isEmpty ?? true ? 'Required' : null,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: _longitudeController,
                            decoration: const InputDecoration(
                              labelText: 'Longitude',
                            ),
                            validator: (v) =>
                                v?.isEmpty ?? true ? 'Required' : null,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    LoadingButton(
                      onPressed: _getCurrentLocation,
                      isLoading: _gettingLocation,
                      text: 'Get Current Location',
                      isOutlined: true,
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
