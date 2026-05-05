import 'package:flutter/material.dart';
import 'package:learnhub/core/navigation/app_routes.dart';
import 'package:learnhub/core/navigation/route_args.dart';
import 'package:learnhub/core/shared_widgets/empty_state.dart';
import 'package:learnhub/presentation/providers/app_state_provider.dart';
import 'package:provider/provider.dart';

class CertificatesScreen extends StatelessWidget {
  const CertificatesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final certificates = context.watch<AppStateProvider>().certificates;

    return Scaffold(
      appBar: AppBar(title: const Text('Certificates')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: certificates.isEmpty
            ? const EmptyState(
                icon: Icons.badge_outlined,
                title: 'No certificates yet',
                subtitle: 'Complete courses to earn certificates.',
              )
            : ListView.separated(
                itemCount: certificates.length,
                separatorBuilder: (context, index) =>
                    const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final cert = certificates[index];
                  return Card(
                    child: ListTile(
                      leading: const CircleAvatar(
                        child: Icon(Icons.workspace_premium_rounded),
                      ),
                      title: Text(cert.courseTitle),
                      subtitle: Text('Grade: ${cert.grade}'),
                      trailing: const Icon(Icons.chevron_right_rounded),
                      onTap: () {
                        Navigator.of(context).pushNamed(
                          AppRoutes.certificateDetails,
                          arguments: CertificateDetailsArgs(certificate: cert),
                        );
                      },
                    ),
                  );
                },
              ),
      ),
    );
  }
}
