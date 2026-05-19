import 'package:learnhub/core/navigation/app_routes.dart';
import 'package:learnhub/core/navigation/route_args.dart';
import 'package:flutter/material.dart';
import 'package:learnhub/core/shared_widgets/empty_state.dart';
import 'package:learnhub/domain/entities/certificate.dart';
import 'package:learnhub/features/student_side/profile/providers/certificate_provider.dart';
import 'package:learnhub/features/student_side/profile/widgets/certificate_card.dart';
import 'package:provider/provider.dart';

class CertificatesScreen extends StatefulWidget {
  const CertificatesScreen({super.key});

  @override
  State<CertificatesScreen> createState() => _CertificatesScreenState();
}

class _CertificatesScreenState extends State<CertificatesScreen> {
  @override
  void initState() {
    super.initState();
    // Load certificates from Firestore
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CertificateProvider>().initialize();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Certificates'),
        centerTitle: false,
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: Consumer<CertificateProvider>(
        builder: (context, provider, _) {
          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header with Stats
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'MY ACHIEVEMENTS',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 1.2,
                          color: colorScheme.primary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Certificates',
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Stats Cards
                SizedBox(
                  height: 100,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    children: [
                      _StatCard(
                        number: provider.totalEarned.toString(),
                        label: 'Earned',
                        icon: Icons.emoji_events_rounded,
                        colorScheme: colorScheme,
                      ),
                      const SizedBox(width: 12),
                      _StatCard(
                        number: provider.inProgress.toString(),
                        label: 'In Progress',
                        icon: Icons.hourglass_bottom_rounded,
                        colorScheme: colorScheme,
                      ),
                      const SizedBox(width: 12),
                      _StatCard(
                        number: '${provider.averageScore.toStringAsFixed(0)}%',
                        label: 'Avg. Score',
                        icon: Icons.trending_up_rounded,
                        colorScheme: colorScheme,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 28),

                // Filter Tabs
                SizedBox(
                  height: 40,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    children: ['All', 'Completed', 'In Progress', 'Shared'].map(
                      (filter) {
                        final isSelected = provider.filterType == filter;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: FilterChip(
                            selected: isSelected,
                            onSelected: (_) => provider.setFilterType(filter),
                            label: Text(filter),
                            backgroundColor: colorScheme.surfaceContainer,
                            selectedColor: colorScheme.primary,
                            labelStyle: TextStyle(
                              color: isSelected
                                  ? Colors.white
                                  : colorScheme.onSurface,
                            ),
                          ),
                        );
                      },
                    ).toList(),
                  ),
                ),
                const SizedBox(height: 20),

                // Certificates List
                if (provider.filteredCertificates.isEmpty)
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: EmptyState(
                      icon: Icons.badge_outlined,
                      title: 'No certificates yet',
                      subtitle: 'Complete courses to earn certificates.',
                    ),
                  )
                else
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      children: provider.filteredCertificates
                          .map(
                            (cert) => CertificateCard(
                              certificate: cert,
                              onTap: cert.completionPercentage >= 100
                                  ? () => _showCertificateDetail(context, cert)
                                  : null,
                              onDownload: cert.completionPercentage >= 100
                                  ? () => _downloadCertificate(context, cert)
                                  : null,
                              onShare: cert.completionPercentage >= 100
                                  ? () => _shareCertificate(cert)
                                  : null,
                            ),
                          )
                          .toList(),
                    ),
                  ),
                const SizedBox(height: 20),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showCertificateDetail(BuildContext context, Certificate certificate) {
    Navigator.of(context).pushNamed(
      AppRoutes.certificateDetails,
      arguments: CertificateDetailsArgs(certificate: certificate),
    );
  }

  void _downloadCertificate(
    BuildContext context,
    Certificate certificate,
  ) async {
    final provider = context.read<CertificateProvider>();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Generating PDF...'),
        duration: Duration(seconds: 2),
      ),
    );

    final pdfPath = await provider.downloadCertificate(certificate);

    if (mounted) {
      if (pdfPath != null) {
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Certificate saved to: $pdfPath'),
            duration: const Duration(seconds: 3),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to download certificate'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  void _shareCertificate(Certificate certificate) async {
    final provider = context.read<CertificateProvider>();
    await provider.shareCertificate(certificate);
  }
}

class _StatCard extends StatelessWidget {
  final String number;
  final String label;
  final IconData icon;
  final ColorScheme colorScheme;

  const _StatCard({
    required this.number,
    required this.label,
    required this.icon,
    required this.colorScheme,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 100,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.outline.withValues(alpha: 0.2)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            number,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: colorScheme.primary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }
}
