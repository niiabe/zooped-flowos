import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/responsive.dart';
import '../../domain/entities/kennel_profile.dart';
import '../providers/settings_providers.dart';
import '../../../pedigree/presentation/providers/shared_providers.dart';

class KennelProfileScreen extends ConsumerStatefulWidget {
  const KennelProfileScreen({super.key});

  @override
  ConsumerState<KennelProfileScreen> createState() => _KennelProfileScreenState();
}

class _KennelProfileScreenState extends ConsumerState<KennelProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _kennelNameController = TextEditingController();
  final _breederNameController = TextEditingController();
  final _contactInfoController = TextEditingController();
  final _phoneController = TextEditingController();
  final _whatsappController = TextEditingController();
  final _emailController = TextEditingController();
  final _imagePicker = ImagePicker();
  
  bool _sameAsPhone = false;
  String? _logoPath;
  bool _dataLoaded = false;

  void _initFromProfile(KennelProfile profile) {
    if (_dataLoaded) return;
    _dataLoaded = true;
    _kennelNameController.text = profile.kennelName;
    _breederNameController.text = profile.breederName ?? '';
    _contactInfoController.text = profile.contactInfo ?? '';
    _phoneController.text = profile.phone ?? '';
    _whatsappController.text = profile.whatsapp ?? '';
    _emailController.text = profile.email ?? '';
    _logoPath = profile.localLogoPath;
    if (_whatsappController.text.isNotEmpty && _whatsappController.text == _phoneController.text) {
      _sameAsPhone = true;
    }
  }

  @override
  void dispose() {
    _kennelNameController.dispose();
    _breederNameController.dispose();
    _contactInfoController.dispose();
    _phoneController.dispose();
    _whatsappController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(kennelProfileProvider);
    final padding = Responsive.padding(context);
    final isTablet = Responsive.isTablet(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Kennel Profile'),
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
          _initFromProfile(profile);

          return SingleChildScrollView(
            padding: EdgeInsets.all(padding),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Kennel Name & Breeder',
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
                    controller: _phoneController,
                    decoration: const InputDecoration(
                      labelText: 'Phone Number (Required)',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.phone),
                    ),
                    keyboardType: TextInputType.phone,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Phone number is required';
                      }
                      return null;
                    },
                    onChanged: (value) {
                      if (_sameAsPhone) {
                        _whatsappController.text = value;
                      }
                    },
                  ),
                  SizedBox(height: padding),
                  Row(
                    children: [
                      Checkbox(
                        value: _sameAsPhone,
                        onChanged: (val) {
                          setState(() {
                            _sameAsPhone = val ?? false;
                            if (_sameAsPhone) {
                              _whatsappController.text = _phoneController.text;
                            } else {
                              _whatsappController.clear();
                            }
                          });
                        },
                      ),
                      const Text('WhatsApp is the same as Phone'),
                    ],
                  ),
                  if (!_sameAsPhone) ...[
                    SizedBox(height: padding),
                    TextFormField(
                      controller: _whatsappController,
                      decoration: const InputDecoration(
                        labelText: 'WhatsApp Number',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.chat),
                      ),
                      keyboardType: TextInputType.phone,
                    ),
                  ],
                  SizedBox(height: padding),
                  TextFormField(
                    controller: _emailController,
                    decoration: const InputDecoration(
                      labelText: 'Email Address',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.email),
                    ),
                    keyboardType: TextInputType.emailAddress,
                  ),
                  SizedBox(height: padding),
                  TextFormField(
                    controller: _contactInfoController,
                    decoration: const InputDecoration(
                      labelText: 'Other Contact Information (Legacy/Extra)',

                      border: OutlineInputBorder(),
                    ),
                    maxLines: 3,
                  ),
                  SizedBox(height: padding * 2),

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
                                      child: Icon(Icons.image, size: 50.0, color: Colors.grey),
                                    );
                                  },
                                ),
                              )
                            : const Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.add_a_photo, size: 40.0, color: Colors.grey),
                                    SizedBox(height: 8.0),
                                    Text('Tap to add logo', style: TextStyle(color: Colors.grey, fontSize: 12.0)),
                                  ],
                                ),
                              ),
                      ),
                    ),
                  ),
                  SizedBox(height: padding * 3),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _saveProfile,
                      style: ElevatedButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: isTablet ? 16.0 : 12.0),
                      ),
                      child: const Text('Save Kennel Profile'),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
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
        breederName: _breederNameController.text.trim().isEmpty ? null : _breederNameController.text.trim(),
        contactInfo: _contactInfoController.text.trim().isEmpty ? null : _contactInfoController.text.trim(),
        phone: _phoneController.text.trim(),
        whatsapp: _sameAsPhone ? _phoneController.text.trim() : (_whatsappController.text.trim().isEmpty ? null : _whatsappController.text.trim()),
        email: _emailController.text.trim().isEmpty ? null : _emailController.text.trim(),
        localLogoPath: _logoPath,
      );

      await updateUseCase(updatedProfile);
      ref.invalidate(kennelProfileProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Kennel profile saved')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving: $e')),
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
    final pickedFile = await _imagePicker.pickImage(source: source);
    if (pickedFile != null) {
      setState(() => _logoPath = pickedFile.path);
    }
  }
}
