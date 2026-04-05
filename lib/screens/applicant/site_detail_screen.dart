import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/api/api_client.dart';
import '../../../core/constants/app_colors.dart';
import '../../../models/site.dart';
import '../../../models/inspection.dart';
import '../../../models/compliance_history.dart';
import '../../../widgets/common/status_badge.dart';
import 'renewal_workflow.dart';
import 'schedule_inspection.dart';

class SiteDetailScreen extends StatefulWidget {
  final Site site;

  const SiteDetailScreen({super.key, required this.site});

  @override
  State<SiteDetailScreen> createState() => _SiteDetailScreenState();
}

class _SiteDetailScreenState extends State<SiteDetailScreen> {
  final _apiClient = ApiClient();
  List<Inspection> _inspections = [];
  List<ComplianceHistory> _history = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final data = await _apiClient.getSite(widget.site.id);
      setState(() {
        _inspections = (data['inspections'] as List)
            .map((json) => Inspection.fromJson(json))
            .toList();
        _history = (data['history'] as List)
            .map((json) => ComplianceHistory.fromJson(json))
            .toList();
      });
    } catch (e) {
      // Handle error
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.site.siteName),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildLicenseCard(),
                  const SizedBox(height: 16),
                  _buildRiskScoreCard(),
                  const SizedBox(height: 16),
                  _buildSiteDetailsCard(),
                  const SizedBox(height: 16),
                  if (widget.site.isExpiringSoon && !widget.site.isExpired)
                    _buildRenewalCard(),
                  const SizedBox(height: 16),
                  if (!widget.site.isExpired)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ScheduleInspectionScreen(
                                site: widget.site,
                              ),
                            ),
                          );
                        },
                        icon: const Icon(Icons.calendar_month),
                        label: const Text('Schedule Inspection'),
                      ),
                    ),
                  const SizedBox(height: 16),
                  if (_inspections.isNotEmpty) _buildInspectionsCard(),
                  const SizedBox(height: 16),
                  if (_history.isNotEmpty) _buildHistoryCard(),
                ],
              ),
            ),
    );
  }

  Widget _buildLicenseCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'License Status',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                StatusBadge(
                  status: widget.site.isExpired
                      ? 'expired'
                      : widget.site.isExpiringSoon
                          ? 'expiring_soon'
                          : 'active',
                ),
              ],
            ),
            const Divider(),
            _buildInfoRow('License Number', widget.site.licenseNumber),
            _buildInfoRow('Issue Date', widget.site.formattedLicenseIssueDate),
            _buildInfoRow(
              'Expiry Date',
              widget.site.formattedLicenseExpiryDate,
            ),
            _buildInfoRow('Days Remaining', widget.site.daysUntilExpiry),
          ],
        ),
      ),
    );
  }

  Widget _buildRiskScoreCard() {
    final riskLevel = widget.site.riskLevel;
    final riskColor = widget.site.riskColor;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Risk Score',
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: LinearProgressIndicator(
                    value: widget.site.riskScore / 100,
                    backgroundColor: Colors.grey[200],
                    color: riskColor,
                    minHeight: 8,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  '${widget.site.riskScore}%',
                  style: GoogleFonts.inter(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: riskColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Risk Level: $riskLevel',
              style: GoogleFonts.inter(
                fontSize: 14,
                color: riskColor,
              ),
            ),
            Text(
              'Last Inspection: ${widget.site.formattedLastInspection}',
              style: GoogleFonts.inter(
                fontSize: 12,
                color: AppColors.textHint,
              ),
            ),
            if (widget.site.needsInspection)
              Container(
                margin: const EdgeInsets.only(top: 8),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.warning.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.warning, size: 16, color: AppColors.warning),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Inspection overdue - please schedule inspection',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: AppColors.warning,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSiteDetailsCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Site Details',
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const Divider(),
            _buildInfoRow('Site Name', widget.site.siteName),
            _buildInfoRow('Address', widget.site.physicalAddress),
            _buildInfoRow('GPS Coordinates', widget.site.gpsCoordinates),
            if (widget.site.storageCapacity != null)
              _buildInfoRow(
                'Storage Capacity',
                '${widget.site.storageCapacity} liters',
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildRenewalCard() {
    return Card(
      color: AppColors.warning.withOpacity(0.1),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(Icons.warning_amber, color: AppColors.warning, size: 32),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'License Expiring Soon',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.warning,
                    ),
                  ),
                  Text(
                    'Your license expires in ${widget.site.licenseExpiryDate.difference(DateTime.now()).inDays} days',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: AppColors.warning,
                    ),
                  ),
                ],
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => RenewalWorkflow(site: widget.site),
                  ),
                );
              },
              child: const Text('Renew Now'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInspectionsCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Inspection History',
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const Divider(),
            ..._inspections.map(
              (inspection) => ListTile(
                leading: Icon(
                  inspection.statusIcon,
                  color: inspection.statusColor,
                ),
                title: Text(
                  inspection.inspectionType.toUpperCase(),
                  style: GoogleFonts.inter(fontWeight: FontWeight.w500),
                ),
                subtitle: Text(
                  inspection.findings.isNotEmpty
                      ? inspection.findings
                      : 'No findings recorded',
                ),
                trailing: Text(
                  inspection.formattedDate,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: AppColors.textHint,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Compliance Timeline',
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const Divider(),
            ..._history.map(
              (event) => ListTile(
                leading: Icon(
                  event.eventIcon,
                  color: event.eventColor,
                ),
                title: Text(event.eventTypeDisplay),
                subtitle: Text(event.description),
                trailing: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      event.formattedDate,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: AppColors.textHint,
                      ),
                    ),
                    if (event.riskScoreChange != 0)
                      Text(
                        event.riskScoreDisplay,
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          color: event.riskScoreColor,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
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
