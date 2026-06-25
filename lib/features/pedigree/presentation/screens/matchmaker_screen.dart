import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/responsive.dart';
import '../../domain/entities/dog.dart';
import '../providers/pedigree_providers.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:share_plus/share_plus.dart';
import 'package:printing/printing.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/services/certificate_service.dart';
import '../providers/shared_providers.dart';
import '../widgets/pedigree_canvas.dart';
import 'heat_tracker_tab.dart';

final _allDogsProvider = FutureProvider.autoDispose<List<Dog>>((ref) async {
  final repo = ref.watch(pedigreeRepositoryProvider);
  return await repo.getAllDogs();
});

class MatchmakerScreen extends ConsumerStatefulWidget {
  const MatchmakerScreen({super.key});

  @override
  ConsumerState<MatchmakerScreen> createState() => _MatchmakerScreenState();
}

class _MatchmakerScreenState extends ConsumerState<MatchmakerScreen> {
  Dog? _selectedSire;
  Dog? _selectedDam;
  Dog? _hypotheticalPuppy;

  @override
  Widget build(BuildContext context) {
    final padding = Responsive.padding(context);
    final isTablet = Responsive.isTablet(context);

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: Colors.grey.shade50,
        appBar: AppBar(
          title: const Text('Matchmaker & Heat 🧬', style: TextStyle(fontWeight: FontWeight.w600)),
          backgroundColor: Colors.white,
          foregroundColor: AppTheme.secondaryColor,
          elevation: 0,
          bottom: const TabBar(
            labelColor: AppTheme.primaryColor,
            unselectedLabelColor: Colors.grey,
            tabs: [
              Tab(text: 'COI Predictor'),
              Tab(text: 'Heat Tracker'),
            ],
          ),
        ),
        body: TabBarView(
          physics: const NeverScrollableScrollPhysics(),
          children: [
            Consumer(
              builder: (context, ref, child) {
                final dogsAsync = ref.watch(_allDogsProvider);

                return dogsAsync.when(
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (e, _) => Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('Error: $e'),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () => ref.invalidate(_allDogsProvider),
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                  data: (allDogs) {
                    final sires = allDogs.where((d) => d.sex == 'Male').toList();
                    final dams = allDogs.where((d) => d.sex == 'Female').toList();

                    return Column(
                      children: [
                        Container(
                          padding: EdgeInsets.all(padding),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.05),
                                blurRadius: 15.0,
                                offset: const Offset(0, 4),
                              ),
                            ],
                            borderRadius: const BorderRadius.only(
                              bottomLeft: Radius.circular(24.0),
                              bottomRight: Radius.circular(24.0),
                            ),
                          ),
                          child: isTablet 
                            ? Row(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Expanded(child: _buildSireSelector(sires)),
                                  SizedBox(width: padding),
                                  Expanded(child: _buildDamSelector(dams)),
                                  SizedBox(width: padding),
                                  ElevatedButton(
                                    onPressed: _selectedSire != null && _selectedDam != null ? _generatePrediction : null,
                                    style: ElevatedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
                                    ),
                                    child: const Text('Simulate'),
                                  ),
                                ],
                              )
                            : Column(
                                children: [
                                  _buildSireSelector(sires),
                                  SizedBox(height: padding),
                                  _buildDamSelector(dams),
                                  SizedBox(height: padding),
                                  SizedBox(
                                    width: double.infinity,
                                    child: ElevatedButton(
                                    onPressed: _selectedSire != null && _selectedDam != null ? () => _generatePrediction() : null,
                                      style: ElevatedButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(vertical: 16),
                                      ),
                                      child: const Text('Simulate Breeding'),
                                    ),
                                  ),
                                ],
                              ),
                        ),
                        
                        if (_hypotheticalPuppy != null) ...[
                          Padding(
                            padding: EdgeInsets.all(padding),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.science, color: AppTheme.primaryColor),
                                const SizedBox(width: 8),
                                Text(
                                  'Estimated COI: ${_hypotheticalPuppy!.inbreedingCoefficient?.toStringAsFixed(2) ?? "0.0"}%',
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.primaryColor,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                OutlinedButton.icon(
                                  onPressed: () => _shareHypotheticalPedigree(context),
                                  icon: const Icon(Icons.share),
                                  label: const Text('Preview Pedigree'),
                                ),
                              ],
                            ),
                          ).animate().fadeIn().slideY(begin: 0.2, end: 0.0),
                          Expanded(
                            child: PedigreeCanvas(
                              rootDog: _hypotheticalPuppy!,
                              onDogTap: (dog) {},
                            ).animate().fadeIn(duration: 600.ms),
                          ),
                        ] else ...[
                          Expanded(
                            child: Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.pets, size: 80, color: Colors.grey.shade300)
                                      .animate(onPlay: (controller) => controller.repeat(reverse: true))
                                      .scaleXY(begin: 0.9, end: 1.1, duration: 1.seconds, curve: Curves.easeInOut),
                                  const SizedBox(height: 16),
                                  const Text(
                                    'Select a Sire and Dam to preview the hypothetical puppy.',
                                    style: TextStyle(color: Colors.grey, fontSize: 16),
                                  ),
                                ],
                              ).animate().fadeIn(duration: 500.ms),
                            ),
                          ),
                        ],
                ],
              );
            },
          );
        },
      ),
      const HeatTrackerTab(),
    ],
  ),
),
);
}

  Widget _buildSireSelector(List<Dog> sires) {
    return DropdownButtonFormField<Dog>(
      initialValue: _selectedSire,
      decoration: const InputDecoration(
        labelText: 'Select Sire (Male)',
        border: OutlineInputBorder(),
        prefixIcon: Icon(Icons.male, color: Colors.blue),
      ),
      items: sires.map((dog) {
        return DropdownMenuItem(
          value: dog,
          child: Text('${dog.registeredName} (${dog.callName})'),
        );
      }).toList(),
      onChanged: (value) {
        setState(() {
          _selectedSire = value;
          _hypotheticalPuppy = null;
        });
      },
    );
  }

  Widget _buildDamSelector(List<Dog> dams) {
    return DropdownButtonFormField<Dog>(
      initialValue: _selectedDam,
      decoration: const InputDecoration(
        labelText: 'Select Dam (Female)',
        border: OutlineInputBorder(),
        prefixIcon: Icon(Icons.female, color: Colors.pink),
      ),
      items: dams.map((dog) {
        return DropdownMenuItem(
          value: dog,
          child: Text('${dog.registeredName} (${dog.callName})'),
        );
      }).toList(),
      onChanged: (value) {
        setState(() {
          _selectedDam = value;
          _hypotheticalPuppy = null;
        });
      },
    );
  }

  Future<void> _generatePrediction() async {
    if (_selectedSire == null || _selectedDam == null) return;

    final repo = ref.read(pedigreeRepositoryProvider);
    final results = await Future.wait([
      repo.getDogByIdWithPedigree(_selectedSire!.id),
      repo.getDogByIdWithPedigree(_selectedDam!.id),
    ]);
    if (!mounted) return;
    final sireWithPedigree = results[0];
    final damWithPedigree = results[1];

    final calculateCoi = ref.read(calculateCoiUseCaseProvider);
    final double coi = calculateCoi(sireWithPedigree, damWithPedigree);

    setState(() {
      _hypotheticalPuppy = Dog(
        id: -1,
        registeredName: 'Hypothetical Puppy',
        callName: 'Puppy',
        sex: 'Unknown',
        sire: sireWithPedigree,
        dam: damWithPedigree,
        inbreedingCoefficient: coi,
        createdAt: DateTime.now(),
      );
    });
  }

  Future<void> _shareHypotheticalPedigree(BuildContext context) async {
    if (_hypotheticalPuppy == null) return;
    
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      final kennelProfile = await ref.read(kennelProfileProvider.future);
      File? logoFile;
      if (kennelProfile.hasCustomLogo) {
        logoFile = File(kennelProfile.localLogoPath!);
        if (!await logoFile.exists()) logoFile = null;
      }

      final pdfBytes = await CertificateService.generateCertificate(
        dog: _hypotheticalPuppy!,
        kennelProfile: kennelProfile,
        logoFile: logoFile,
      );

      await for (final page in Printing.raster(pdfBytes, pages: [0], dpi: 300)) {
        final pngBytes = await page.toPng();
        final tempDir = await getTemporaryDirectory();
        final file = File(p.join(tempDir.path, 'hypothetical_pedigree.png'));
        await file.writeAsBytes(pngBytes);
        
        if (!context.mounted) return;
        Navigator.pop(context); // Close loading dialog
        
        final xFile = XFile(file.path, mimeType: 'image/png');
        await Share.shareXFiles(
          [xFile],
          text: 'Check out this hypothetical breeding! Projected COI: ${_hypotheticalPuppy!.inbreedingCoefficient?.toStringAsFixed(2)}%',
        );
        break; // Only need the first page
      }
    } catch (e) {
      if (!context.mounted) return;
      Navigator.pop(context); // Close loading dialog
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error generating preview: $e')),
      );
    }
  }
}
