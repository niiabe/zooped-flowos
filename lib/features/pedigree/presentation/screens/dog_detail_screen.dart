import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import '../../../../core/services/certificate_service.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/responsive.dart';
import '../../domain/entities/dog.dart';
import '../providers/pedigree_providers.dart';
import '../providers/shared_providers.dart';
import '../widgets/pedigree_canvas.dart';

final _dogProvider = FutureProvider.family<Dog, int>((ref, dogId) async {
  final useCase = ref.watch(getDogByIdUseCaseProvider);
  return await useCase(dogId);
});

class DogDetailScreen extends ConsumerStatefulWidget {
  final int dogId;

  const DogDetailScreen({super.key, required this.dogId});

  @override
  ConsumerState<DogDetailScreen> createState() => _DogDetailScreenState();
}

class _DogDetailScreenState extends ConsumerState<DogDetailScreen> {
  bool _generatingPdf = false;

  @override
  Widget build(BuildContext context) {
    final dogAsync = ref.watch(_dogProvider(widget.dogId));
    final padding = Responsive.padding(context);
    final isTablet = Responsive.isTablet(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dog Profile'),
      ),
      body: dogAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 16),
              Text('Error: $e'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref.invalidate(_dogProvider(widget.dogId)),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
        data: (dog) {
          if (isTablet) {
            return Row(
              children: [
                Expanded(
                  flex: 1,
                  child: _buildIdentityPanel(context, dog, padding),
                ),
                const VerticalDivider(width: 1),
                Expanded(
                  flex: 2,
                  child: PedigreeCanvas(
                    rootDog: dog,
                    onDogTap: (selectedDog) {
                      context.push('/dog/${selectedDog.id}');
                    },
                  ),
                ),
              ],
            );
          }

          return Column(
            children: [
              ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.45,
                ),
                child: _buildIdentityPanel(context, dog, padding),
              ),
              const Divider(height: 1),
              Expanded(
                child: PedigreeCanvas(
                  rootDog: dog,
                  onDogTap: (selectedDog) {
                    context.push('/dog/${selectedDog.id}');
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _generateAndPrintCertificate(Dog dog) async {
    setState(() => _generatingPdf = true);
    try {
      final profile = await ref.read(kennelProfileProvider.future);
      final logoFile = profile.localLogoPath != null ? File(profile.localLogoPath!) : null;
      final pdf = await CertificateService.generateCertificate(
        dog: dog,
        kennelProfile: profile,
        logoFile: logoFile,
      );
      await CertificateService.printPdf(pdf);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error generating certificate: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _generatingPdf = false);
    }
  }

  Future<void> _generateAndShareCertificate(Dog dog) async {
    setState(() => _generatingPdf = true);
    try {
      final profile = await ref.read(kennelProfileProvider.future);
      final logoFile = profile.localLogoPath != null ? File(profile.localLogoPath!) : null;
      final pdf = await CertificateService.generateCertificate(
        dog: dog,
        kennelProfile: profile,
        logoFile: logoFile,
      );
      final tempDir = await getTemporaryDirectory();
      final file = File(p.join(tempDir.path, 'zooped_certificate_${dog.id}.pdf'));
      await file.writeAsBytes(await pdf.save());
      await CertificateService.sharePdf(file, dog.registeredName);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error generating certificate: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _generatingPdf = false);
    }
  }

  Widget _buildIdentityPanel(BuildContext context, Dog dog, double padding) {
    final isTablet = Responsive.isTablet(context);

    return SingleChildScrollView(
      padding: EdgeInsets.all(padding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            dog.registeredName,
            style: TextStyle(
              fontSize: isTablet ? 24.0 : 20.0,
              fontWeight: FontWeight.bold,
              color: AppTheme.secondaryColor,
            ),
          ),
          SizedBox(height: padding * 0.25),
          Text(
            'Call Name: ${dog.callName}',
            style: TextStyle(
              fontSize: isTablet ? 16.0 : 14.0,
              color: Colors.grey.shade600,
            ),
          ),
          SizedBox(height: padding),
          Wrap(
            spacing: padding,
            runSpacing: padding * 0.5,
            children: [
              _buildDetailChip('Sex', dog.sex, isTablet),
              if (dog.microchipNumber != null)
                _buildDetailChip('Microchip', dog.microchipNumber!, isTablet),
              if (dog.dateOfBirth != null)
                _buildDetailChip('DOB', dog.dateOfBirth.toString().split(' ')[0], isTablet),
              if (dog.colorMarkings != null)
                _buildDetailChip('Color', dog.colorMarkings!, isTablet),
              if (dog.registerType != null)
                _buildDetailChip('Register', dog.registerType!, isTablet),
              if (dog.appraisalScore != null)
                _buildDetailChip('Appraisal', dog.appraisalScore.toString(), isTablet),
              if (dog.inbreedingCoefficient != null)
                _buildDetailChip('COI', dog.inbreedingCoefficient.toString(), isTablet),
            ],
          ),
          SizedBox(height: padding),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _generatingPdf ? null : () => _generateAndPrintCertificate(dog),
                  icon: _generatingPdf
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.print),
                  label: const Text('Print Certificate'),
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(
                      vertical: isTablet ? 16.0 : 12.0,
                    ),
                  ),
                ),
              ),
              SizedBox(width: padding),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _generatingPdf ? null : () => _generateAndShareCertificate(dog),
                  icon: _generatingPdf
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.share),
                  label: const Text('Share'),
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(
                      vertical: isTablet ? 16.0 : 12.0,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDetailChip(String label, String value, bool isTablet) {
    return Chip(
      label: RichText(
        text: TextSpan(
          children: [
            TextSpan(
              text: '$label: ',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade700,
                fontSize: isTablet ? 14.0 : 12.0,
              ),
            ),
            TextSpan(
              text: value,
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: isTablet ? 14.0 : 12.0,
              ),
            ),
          ],
        ),
      ),
      backgroundColor: Colors.grey.shade100,
      padding: EdgeInsets.symmetric(
        horizontal: isTablet ? 12.0 : 8.0,
        vertical: isTablet ? 6.0 : 4.0,
      ),
    );
  }
}
