import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/api/api_client.dart';
import '../../core/constants/app_colors.dart';
import '../../widgets/common/loading_button.dart';
import '../auth/change_password_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _apiClient = ApiClient();
  final _fullNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _companyController = TextEditingController();

  bool _isLoading = true;
  bool _isSaving = false;
  String? _userId;
  String? _role;
  String? _originalEmail;
  bool _isEditingCompany = false;

  // OTP for email change
  bool _isEmailOtpSent = false;
  bool _isEmailOtpVerified = false;
  String? _newEmail;
  final _otpController = TextEditingController();
  int _resendCooldown = 0;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _companyController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    setState(() => _isLoading = true);
    try {
      final response = await _apiClient.getProfile();
      final user = response['user'];
      setState(() {
        _fullNameController.text = user['full_name'] ?? '';
        _phoneController.text = user['phone'] ?? '';
        _emailController.text = user['email'] ?? '';
        _companyController.text = user['company_name'] ?? '';
        _userId = user['id'];
        _role = user['role'];
        _originalEmail = user['email'];
      });
    } catch (e) {
      _showSnackBar('Failed to load profile', AppColors.error);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveProfile() async {
    setState(() => _isSaving = true);
    try {
      await _apiClient.updateProfile({
        'full_name': _fullNameController.text.trim(),
        'phone': _phoneController.text.trim(),
      });
      _showSnackBar('Profile updated successfully', AppColors.success);
      await _loadProfile();
    } catch (e) {
      _showSnackBar('Failed to update profile', AppColors.error);
    } finally {
      setState(() => _isSaving = false);
    }
  }

  Future<void> _sendEmailOtp() async {
    if (_emailController.text == _originalEmail) {
      _showSnackBar('Email is the same as current', AppColors.error);
      return;
    }

    if (!_isValidEmail(_emailController.text)) {
      _showSnackBar('Please enter a valid email address', AppColors.error);
      return;
    }

    setState(() => _isSaving = true);
    try {
      final response = await _apiClient.sendOtp(
        _emailController.text.trim(),
        _fullNameController.text.trim(),
      );

      if (response['success'] == true) {
        setState(() {
          _isEmailOtpSent = true;
          _newEmail = _emailController.text.trim();
          _resendCooldown = 60;
        });
        _startResendTimer();
        _showSnackBar('Verification code sent to new email', AppColors.success);
      } else {
        _showSnackBar(
            response['error'] ?? 'Failed to send OTP', AppColors.error);
      }
    } catch (e) {
      _showSnackBar('Failed to send OTP', AppColors.error);
    } finally {
      setState(() => _isSaving = false);
    }
  }

  void _startResendTimer() {
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted && _resendCooldown > 0) {
        setState(() => _resendCooldown--);
        _startResendTimer();
      }
    });
  }

  Future<void> _verifyEmailOtp() async {
    if (_otpController.text.isEmpty) {
      _showSnackBar('Please enter verification code', AppColors.error);
      return;
    }

    setState(() => _isSaving = true);
    try {
      final response = await _apiClient.verifyOtp(
        _newEmail!,
        _otpController.text.trim(),
      );

      if (response['success'] == true) {
        // Now change the email
        final changeResponse = await _apiClient.changeEmail(
          _newEmail!,
          _otpController.text.trim(),
        );

        if (changeResponse['success'] == true) {
          setState(() {
            _isEmailOtpVerified = true;
            _originalEmail = _newEmail;
          });
          _showSnackBar('Email updated successfully!', AppColors.success);
          await _loadProfile();
        } else {
          _showSnackBar(changeResponse['error'] ?? 'Failed to update email',
              AppColors.error);
        }
      } else {
        _showSnackBar(
            response['error'] ?? 'Invalid verification code', AppColors.error);
      }
    } catch (e) {
      _showSnackBar('Verification failed', AppColors.error);
    } finally {
      setState(() => _isSaving = false);
    }
  }

  Future<void> _updateCompanyName() async {
    if (_companyController.text.isEmpty) {
      _showSnackBar('Please enter company name', AppColors.error);
      return;
    }

    setState(() => _isSaving = true);
    try {
      await _apiClient.updateCompanyName(
          _userId!, _companyController.text.trim());
      _showSnackBar('Company name updated successfully', AppColors.success);
      setState(() => _isEditingCompany = false);
    } catch (e) {
      _showSnackBar('Failed to update company name', AppColors.error);
    } finally {
      setState(() => _isSaving = false);
    }
  }

  bool _isValidEmail(String email) {
    return RegExp(r'^[^\s@]+@([^\s@]+\.)+[^\s@]+$').hasMatch(email);
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: color),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Avatar
                  Center(
                    child: CircleAvatar(
                      radius: 50,
                      backgroundColor: AppColors.primary,
                      child: Text(
                        _fullNameController.text.isNotEmpty
                            ? _fullNameController.text[0].toUpperCase()
                            : 'U',
                        style:
                            const TextStyle(fontSize: 40, color: Colors.white),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Full Name
                  TextField(
                    controller: _fullNameController,
                    decoration: const InputDecoration(
                      labelText: 'Full Name',
                      prefixIcon: Icon(Icons.person),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Phone
                  TextField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(
                      labelText: 'Phone Number',
                      prefixIcon: Icon(Icons.phone),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Email (with OTP verification)
                  TextField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                      labelText: 'Email Address',
                      prefixIcon: const Icon(Icons.email),
                      suffixIcon: _isEmailOtpVerified
                          ? const Icon(Icons.verified, color: AppColors.success)
                          : _emailController.text != _originalEmail
                              ? IconButton(
                                  icon: Icon(
                                    Icons.send,
                                    color: _isEmailOtpSent
                                        ? AppColors.textHint
                                        : AppColors.primary,
                                  ),
                                  onPressed:
                                      _isEmailOtpSent ? null : _sendEmailOtp,
                                )
                              : null,
                    ),
                  ),

                  // OTP Section
                  if (_isEmailOtpSent && !_isEmailOtpVerified) ...[
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _otpController,
                            keyboardType: TextInputType.number,
                            maxLength: 6,
                            decoration: const InputDecoration(
                              labelText: 'Verification Code',
                              prefixIcon: Icon(Icons.pin),
                              counterText: '',
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        ElevatedButton(
                          onPressed: _verifyEmailOtp,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            minimumSize: const Size(80, 56),
                          ),
                          child: const Text('Verify'),
                        ),
                      ],
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: _resendCooldown > 0 ? null : _sendEmailOtp,
                          child: Text(
                            _resendCooldown > 0
                                ? 'Resend in ${_resendCooldown}s'
                                : 'Resend Code',
                          ),
                        ),
                      ],
                    ),
                  ],

                  const SizedBox(height: 16),

                  // Company Name (editable by officer/admin only)
                  if (_role == 'officer' || _role == 'super_admin') ...[
                    const Divider(),
                    const SizedBox(height: 8),
                    Text(
                      'Company Management',
                      style: GoogleFonts.inter(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _isEditingCompany
                              ? TextField(
                                  controller: _companyController,
                                  decoration: const InputDecoration(
                                    labelText: 'Company Name',
                                    prefixIcon: Icon(Icons.business),
                                  ),
                                )
                              : Text(
                                  _companyController.text.isEmpty
                                      ? 'No company name'
                                      : _companyController.text,
                                  style: GoogleFonts.inter(fontSize: 16),
                                ),
                        ),
                        if (_isEditingCompany) ...[
                          IconButton(
                            icon: const Icon(Icons.save,
                                color: AppColors.success),
                            onPressed: _updateCompanyName,
                          ),
                          IconButton(
                            icon:
                                const Icon(Icons.close, color: AppColors.error),
                            onPressed: () {
                              setState(() {
                                _isEditingCompany = false;
                                _companyController.text =
                                    _companyController.text;
                              });
                            },
                          ),
                        ] else ...[
                          IconButton(
                            icon: const Icon(Icons.edit,
                                color: AppColors.primary),
                            onPressed: () {
                              setState(() => _isEditingCompany = true);
                            },
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 16),
                  ],

                  const Divider(),
                  const SizedBox(height: 16),

                  // Change Password Button
                  ListTile(
                    leading: const Icon(Icons.lock),
                    title: const Text('Change Password'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const ChangePasswordScreen(
                            token: '',
                            user: {},
                          ),
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 24),

                  // Save Button
                  LoadingButton(
                    onPressed: _saveProfile,
                    isLoading: _isSaving,
                    text: 'Save Changes',
                  ),
                ],
              ),
            ),
    );
  }
}
