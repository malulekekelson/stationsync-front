import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/api/api_client.dart';
import '../../core/constants/app_colors.dart';
import '../../models/site.dart';
import '../../widgets/common/loading_button.dart';

class ScheduleInspectionScreen extends StatefulWidget {
  final Site site;

  const ScheduleInspectionScreen({super.key, required this.site});

  @override
  State<ScheduleInspectionScreen> createState() =>
      _ScheduleInspectionScreenState();
}

class _ScheduleInspectionScreenState extends State<ScheduleInspectionScreen> {
  final _apiClient = ApiClient();
  final _notesController = TextEditingController();
  DateTime _selectedDate = DateTime.now().add(const Duration(days: 7));
  String _inspectionType = 'annual';
  bool _isLoading = false;

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _scheduleInspection() async {
    setState(() => _isLoading = true);

    try {
      await _apiClient.scheduleInspection({
        'site_id': widget.site.id,
        'scheduled_date': _selectedDate.toIso8601String(),
        'inspection_type': _inspectionType,
        'notes': _notesController.text,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Inspection scheduled successfully!'),
              backgroundColor: AppColors.success),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Failed to schedule: $e'),
              backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Schedule Inspection')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Icon(Icons.calendar_today, size: 60, color: AppColors.primary),
            const SizedBox(height: 24),
            Text('Site: ${widget.site.siteName}',
                style: GoogleFonts.inter(
                    fontSize: 18, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center),
            const SizedBox(height: 8),
            Text(widget.site.physicalAddress,
                style: GoogleFonts.inter(color: AppColors.textSecondary),
                textAlign: TextAlign.center),
            const SizedBox(height: 32),

            // Inspection Type
            DropdownButtonFormField<String>(
              initialValue: _inspectionType,
              decoration: const InputDecoration(
                  labelText: 'Inspection Type', border: OutlineInputBorder()),
              items: const [
                DropdownMenuItem(
                    value: 'initial', child: Text('Initial Inspection')),
                DropdownMenuItem(
                    value: 'annual', child: Text('Annual Inspection')),
                DropdownMenuItem(
                    value: 'follow_up', child: Text('Follow-up Inspection')),
                DropdownMenuItem(
                    value: 'random', child: Text('Random Inspection')),
              ],
              onChanged: (value) => setState(() => _inspectionType = value!),
            ),
            const SizedBox(height: 16),

            // Date Picker
            InkWell(
              onTap: () => _selectDate(context),
              child: InputDecorator(
                decoration: const InputDecoration(
                    labelText: 'Preferred Date', border: OutlineInputBorder()),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                        '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}'),
                    const Icon(Icons.calendar_today),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Notes
            TextField(
              controller: _notesController,
              maxLines: 3,
              decoration: const InputDecoration(
                  labelText: 'Additional Notes (Optional)',
                  border: OutlineInputBorder(),
                  alignLabelWithHint: true),
            ),
            const SizedBox(height: 32),

            LoadingButton(
                onPressed: _scheduleInspection,
                isLoading: _isLoading,
                text: 'Schedule Inspection'),
          ],
        ),
      ),
    );
  }
}
