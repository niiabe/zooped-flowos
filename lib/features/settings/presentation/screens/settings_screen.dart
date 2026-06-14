import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import '../../../../core/services/csv_service.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/responsive.dart';
import '../../domain/entities/kennel_profile.dart';
import '../providers/settings_providers.dart';
import '../../../pedigree/presentation/providers/pedigree_providers.dart';
import '../../../pedigree/presentation/providers/shared_providers.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _kennelNameController = TextEditingController();
  final _breederNameController = TextEditingController();
  final _contactInfoController = TextEditingController();

  String? _logoPath;
  bool _controllersInitialized = false;

  @override
  void dispose() {
    _kennelNameController.dispose();
    _breederNameController.dispose();
    _contactInfoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(kennelProfileProvider);
    final padding = Responsive.padding(context);
    final isTablet = Responsive.isTablet(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: profileAsync.when(
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
                onPressed: () => ref.invalidate(kennelProfileProvider),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
        data: (profile) {
          if (!_controllersInitialized) {
            _kennelNameController.text = profile.kennelName;
            _breederNameController.text = profile.breederName ?? '';
            _contactInfoController.text = profile.contactInfo ?? '';
            _logoPath = profile.localLogoPath;
            _controllersInitialized = true;
          }

          return SingleChildScrollView(
            padding: EdgeInsets.all(padding),
            child: Form(
              key: _formKey,
              child: isTablet
                  ? _buildTabletLayout(padding)
                  : _buildPhoneLayout(padding),
            ),
          );
        },
      ),
    );
  }

  Widget _buildPhoneLayout(double padding) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildKennelProfileSection(padding),
        SizedBox(height: padding * 2),
        _buildLogoSection(padding),
        SizedBox(height: padding * 2),
        _buildBackupSection(padding),
        SizedBox(height: padding * 2),
        _buildSaveButton(padding),
        SizedBox(height: padding * 2),
        _buildAboutSection(padding),
      ],
    );
  }

  Widget _buildTabletLayout(double padding) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 1,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildKennelProfileSection(padding),
              SizedBox(height: padding * 2),
              _buildLogoSection(padding),
            ],
          ),
        ),
        SizedBox(width: padding * 2),
        Expanded(
          flex: 1,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildBackupSection(padding),
              SizedBox(height: padding * 2),
              _buildSaveButton(padding),
              SizedBox(height: padding * 2),
              _buildAboutSection(padding),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildKennelProfileSection(double padding) {
    final isTablet = Responsive.isTablet(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Kennel Profile',
          style: TextStyle(
            fontSize: isTablet ? 20.0 : 18.0,
            fontWeight: FontWeight.bold,
            color: AppTheme.secondaryColor,
          ),
        ),
        SizedBox(height: padding),
        TextFormField(
          controller: _kennelNameController,
          decoration: const InputDecoration(
            labelText: 'Kennel Name',
            border: OutlineInputBorder(),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter a kennel name';
            }
            return null;
          },
        ),
        SizedBox(height: padding),
        TextFormField(
          controller: _breederNameController,
          decoration: const InputDecoration(
            labelText: 'Breeder Name',
            border: OutlineInputBorder(),
          ),
        ),
        SizedBox(height: padding),
        TextFormField(
          controller: _contactInfoController,
          decoration: const InputDecoration(
            labelText: 'Contact Information',
            border: OutlineInputBorder(),
          ),
          maxLines: 3,
        ),
      ],
    );
  }

  Widget _buildLogoSection(double padding) {
    final isTablet = Responsive.isTablet(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Kennel Logo',
          style: TextStyle(
            fontSize: isTablet ? 20.0 : 18.0,
            fontWeight: FontWeight.bold,
            color: AppTheme.secondaryColor,
          ),
        ),
        SizedBox(height: padding),
        Center(
          child: GestureDetector(
            onTap: () => _showImagePickerOptions(context),
            child: Container(
              width: isTablet ? 200.0 : 150.0,
              height: isTablet ? 200.0 : 150.0,
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(8.0),
                border: Border.all(
                  color: Colors.grey.shade400,
                  width: 2.0,
                ),
              ),
              child: _logoPath != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(8.0),
                      child: Image.file(
                        File(_logoPath!),
                        fit: BoxFit.cover,
                        cacheHeight: 300,
                        errorBuilder: (context, error, stackTrace) {
                          return const Center(
                            child: Icon(
                              Icons.image,
                              size: 50.0,
                              color: Colors.grey,
                            ),
                          );
                        },
                      ),
                    )
                  : const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.add_a_photo,
                            size: 40.0,
                            color: Colors.grey,
                          ),
                          SizedBox(height: 8.0),
                          Text(
                            'Tap to add logo',
                            style: TextStyle(
                              color: Colors.grey,
                              fontSize: 12.0,
                            ),
                          ),
                        ],
                      ),
                    ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBackupSection(double padding) {
    final isTablet = Responsive.isTablet(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Backup & Migration',
          style: TextStyle(
            fontSize: isTablet ? 20.0 : 18.0,
            fontWeight: FontWeight.bold,
            color: AppTheme.secondaryColor,
          ),
        ),
        SizedBox(height: padding),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () async {
              await _exportDatabase(context);
            },
            icon: const Icon(Icons.upload_file),
            label: const Text('Export Database to CSV'),
            style: ElevatedButton.styleFrom(
              padding: EdgeInsets.symmetric(
                vertical: isTablet ? 16.0 : 12.0,
              ),
            ),
          ),
        ),
        SizedBox(height: padding),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () async {
              await _importDatabase(context);
            },
            icon: const Icon(Icons.download),
            label: const Text('Import Database from CSV'),
            style: OutlinedButton.styleFrom(
              padding: EdgeInsets.symmetric(
                vertical: isTablet ? 16.0 : 12.0,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSaveButton(double padding) {
    final isTablet = Responsive.isTablet(context);

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _saveProfile,
        style: ElevatedButton.styleFrom(
          padding: EdgeInsets.symmetric(
            vertical: isTablet ? 16.0 : 12.0,
          ),
        ),
        child: const Text('Save Settings'),
      ),
    );
  }

  Widget _buildAboutSection(double padding) {
    return ListTile(
      leading: const Icon(Icons.info_outline),
      title: const Text('About ZooPed'),
      subtitle: const Text('Version 1.0.0'),
      trailing: const Icon(Icons.chevron_right),
      onTap: () => context.push('/about'),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
    );
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      final updateUseCase = ref.read(updateKennelProfileUseCaseProvider);
      final currentProfile = await ref.read(kennelProfileProvider.future);

      final updatedProfile = KennelProfile(
        id: currentProfile.id,
        kennelName: _kennelNameController.text.trim(),
        breederName: _breederNameController.text.trim().isEmpty
            ? null
            : _breederNameController.text.trim(),
        contactInfo: _contactInfoController.text.trim().isEmpty
            ? null
            : _contactInfoController.text.trim(),
        localLogoPath: _logoPath,
      );

      await updateUseCase(updatedProfile);
      ref.invalidate(kennelProfileProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Settings saved successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving settings: $e')),
        );
      }
    }
  }

  void _showImagePickerOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Take Photo'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Choose from Gallery'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: source);

    if (pickedFile != null) {
      setState(() {
        _logoPath = pickedFile.path;
      });
    }
  }

  Future<void> _exportDatabase(BuildContext context) async {
    try {
      final repository = ref.read(pedigreeRepositoryProvider);
      final dogs = await repository.getAllDogs();
      final litters = await repository.getAllLitters();

      final dogsFile = await CsvService.exportDogs(dogs);
      final littersFile = await CsvService.exportLitters(litters);

      await CsvService.shareCsvFiles([dogsFile, littersFile]);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Database exported successfully')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error exporting database: $e')),
        );
      }
    }
  }

  Future<void> _importDatabase(BuildContext context) async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final csvFiles = await appDir
          .list()
          .where((f) => f.path.endsWith('.csv'))
          .toList();

      if (csvFiles.isEmpty) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No CSV files found in app storage')),
          );
        }
        return;
      }

      if (!context.mounted) return;

      final selected = await showDialog<File>(
        context: context,
        builder: (ctx) => SimpleDialog(
          title: const Text('Select CSV to import'),
          children: csvFiles.map((f) {
            final file = File(f.path);
            final name = p.basename(f.path);
            final isDogs = name.contains('dogs');
            return SimpleDialogOption(
              onPressed: () => Navigator.pop(ctx, file),
              child: Row(
                children: [
                  Icon(isDogs ? Icons.pets : Icons.family_restroom, size: 20),
                  const SizedBox(width: 12),
                  Text(name),
                ],
              ),
            );
          }).toList(),
        ),
      );

      if (selected == null) return;

      final db = ref.read(databaseProvider);
      final filePath = selected.path;

      if (filePath.contains('dogs')) {
        final dogsCompanion = await CsvService.importDogsFromCsv(filePath);
        await db.bulkInsertDogs(dogsCompanion);
      } else if (filePath.contains('litters')) {
        final littersCompanion = await CsvService.importLittersFromCsv(filePath);
        await db.bulkInsertLitters(littersCompanion);
      }

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Database imported successfully')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error importing database: $e')),
        );
      }
    }
  }
}
