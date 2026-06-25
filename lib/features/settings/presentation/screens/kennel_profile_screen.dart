import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/responsive.dart';
import '../../../../core/error/error_handler.dart';
import '../../../../core/services/file_storage_service.dart';
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
  
  late TextEditingController _kennelNameController;
  late TextEditingController _breederNameController;
  late TextEditingController _contactInfoController;
  late TextEditingController _phoneController;
  late TextEditingController _whatsappController;
  late TextEditingController _emailController;
  late TextEditingController _primaryBreedsController;
  
  String? _logoPath;
  String _brandColorHex = '#2F5E36';
  String _certificateBorderTheme = 'Classic';
  bool _sameAsPhone = false;
  
  final _imagePicker = ImagePicker();

  final List<String> _brandColors = [
    '#2F5E36', // Original Green
    '#1A365D', // Navy Blue
    '#702459', // Plum Purple
    '#975A16', // Golden Brown
    '#2C5282', // Royal Blue
    '#805AD5', // Deep Violet
    '#C53030', // Crimson Red
    '#276749', // Forest Green
  ];

  final List<String> _borderDesigns = [
    'Classic',
    'Modern',
    'Elegant',
    'Regal',
    'Bold',
  ];

  @override
  void initState() {
    super.initState();
    _kennelNameController = TextEditingController();
    _breederNameController = TextEditingController();
    _contactInfoController = TextEditingController();
    _phoneController = TextEditingController();
    _whatsappController = TextEditingController();
    _emailController = TextEditingController();
    _primaryBreedsController = TextEditingController();
  }

  void _initFromProfile(KennelProfile profile) {
    if (_kennelNameController.text.isNotEmpty) return;

    _kennelNameController.text = profile.kennelName;
    _breederNameController.text = profile.breederName ?? '';
    _contactInfoController.text = profile.contactInfo ?? '';
    _phoneController.text = profile.phone ?? '';
    _whatsappController.text = profile.whatsapp ?? '';
    _emailController.text = profile.email ?? '';
    _primaryBreedsController.text = profile.primaryBreeds ?? '';
    _logoPath = profile.localLogoPath;
    _brandColorHex = profile.brandColorHex ?? '#2F5E36';
    _certificateBorderTheme = profile.certificateBorderTheme ?? 'Classic';
    
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
    _primaryBreedsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(kennelProfileProvider);

    return profileAsync.when(
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(
        appBar: AppBar(title: const Text('Kennel Profile')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 48, color: Colors.red),
                const SizedBox(height: 16),
                Text(ErrorHandler.getUserFriendlyMessage(e)),
                const SizedBox(height: 16),
                ElevatedButton(
                onPressed: () => ref.invalidate(kennelProfileProvider),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
      data: (profile) {
        _initFromProfile(profile);

        return DefaultTabController(
          length: 4,
          child: Scaffold(
            appBar: AppBar(
              title: const Text('Kennel Profile'),
              bottom: const TabBar(
                isScrollable: true,
                tabs: [
                  Tab(text: 'Identity', icon: Icon(Icons.badge)),
                  Tab(text: 'Breeding', icon: Icon(Icons.pets)),
                  Tab(text: 'Contact', icon: Icon(Icons.contact_mail)),
                  Tab(text: 'Appearance', icon: Icon(Icons.palette)),
                ],
              ),
            ),
            body: Form(
              key: _formKey,
              autovalidateMode: AutovalidateMode.onUserInteraction,
              child: TabBarView(
                children: [
                  _buildIdentityTab(),
                  _buildBreedingTab(),
                  _buildContactTab(),
                  _buildAppearanceTab(),
                ],
              ),
            ),
            bottomNavigationBar: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: ElevatedButton(
                  onPressed: _saveProfile,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16.0),
                  ),
                  child: const Text('Save Kennel Profile'),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildIdentityTab() {
    final padding = Responsive.padding(context);
    final isTablet = Responsive.isTablet(context);

    return SingleChildScrollView(
      padding: EdgeInsets.all(padding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextFormField(
            controller: _kennelNameController,
            decoration: const InputDecoration(
              labelText: 'Kennel Name',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.home),
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
              prefixIcon: Icon(Icons.person),
            ),
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
            ).animate().fadeIn(duration: 400.ms).scale(curve: Curves.easeOutBack),
          ),
        ],
      ),
    );
  }

  Widget _buildBreedingTab() {
    final padding = Responsive.padding(context);

    return SingleChildScrollView(
      padding: EdgeInsets.all(padding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Primary breeds will be used to auto-complete fields when adding new dogs.',
            style: TextStyle(color: Colors.grey),
          ),
          SizedBox(height: padding),
          TextFormField(
            controller: _primaryBreedsController,
            decoration: const InputDecoration(
              labelText: 'Primary Breeds (comma separated)',
              hintText: 'e.g. French Bulldog, Poodle',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.pets),
            ),
            maxLines: 2,
          ),
        ],
      ),
    );
  }

  Widget _buildContactTab() {
    final padding = Responsive.padding(context);

    return SingleChildScrollView(
      padding: EdgeInsets.all(padding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextFormField(
            controller: _phoneController,
            decoration: const InputDecoration(
              labelText: 'Phone',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.phone),
            ),
            keyboardType: TextInputType.phone,
            inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9+\- ]'))],
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
                labelText: 'WhatsApp (Optional)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.chat),
              ),
              keyboardType: TextInputType.phone,
              inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9+\- ]'))],
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
              labelText: 'Other Contact Info / Address',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.location_on),
            ),
            maxLines: 3,
          ),
        ],
      ),
    );
  }

  Widget _buildAppearanceTab() {
    final padding = Responsive.padding(context);
    final isTablet = Responsive.isTablet(context);

    return SingleChildScrollView(
      padding: EdgeInsets.all(padding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Brand Theme Color',
            style: TextStyle(
              fontSize: isTablet ? 20.0 : 18.0,
              fontWeight: FontWeight.bold,
              color: AppTheme.secondaryColor,
            ),
          ),
          const SizedBox(height: 8),
          const Text('This color will be used throughout the app and on your certificates.', style: TextStyle(color: Colors.grey)),
          SizedBox(height: padding),
          Wrap(
            spacing: 12.0,
            runSpacing: 12.0,
            children: _brandColors.map((hex) {
              final isSelected = _brandColorHex == hex;
              final color = Color(int.parse(hex.replaceFirst('#', '0xFF')));
              return GestureDetector(
                onTap: () {
                  setState(() {
                    _brandColorHex = hex;
                  });
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  width: isTablet ? 60.0 : 50.0,
                  height: isTablet ? 60.0 : 50.0,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                    border: isSelected
                        ? Border.all(color: Colors.grey.shade800, width: 3.0)
                        : Border.all(color: Colors.transparent, width: 3.0),
                    boxShadow: isSelected
                        ? [BoxShadow(color: color.withValues(alpha: 0.5), blurRadius: 10, spreadRadius: 2)]
                        : [],
                  ),
                  child: isSelected
                      ? const Icon(Icons.check, color: Colors.white)
                          .animate()
                          .scale(duration: 200.ms, curve: Curves.easeOutBack)
                      : null,
                ),
              ).animate().fadeIn(delay: (100 * _brandColors.indexOf(hex)).ms);
            }).toList(),
          ),
          
          SizedBox(height: padding * 3),
          
          Text(
            'Certificate Border Design',
            style: TextStyle(
              fontSize: isTablet ? 20.0 : 18.0,
              fontWeight: FontWeight.bold,
              color: AppTheme.secondaryColor,
            ),
          ),
          const SizedBox(height: 8),
          const Text('Select a border style for your generated PDF Pedigree Certificates.', style: TextStyle(color: Colors.grey)),
          SizedBox(height: padding),
          
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _borderDesigns.length,
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final design = _borderDesigns[index];
              final isSelected = _certificateBorderTheme == design;
              final activeColor = Color(int.parse(_brandColorHex.replaceFirst('#', '0xFF')));
              
              return InkWell(
                onTap: () {
                  setState(() {
                    _certificateBorderTheme = design;
                  });
                },
                borderRadius: BorderRadius.circular(12),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  decoration: BoxDecoration(
                    color: isSelected ? activeColor.withValues(alpha: 0.1) : Colors.white,
                    border: Border.all(
                      color: isSelected ? activeColor : Colors.grey.shade300,
                      width: isSelected ? 2.0 : 1.0,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Icon(
                        _getIconForBorder(design),
                        color: isSelected ? activeColor : Colors.grey.shade600,
                        size: 32,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              design,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                color: isSelected ? activeColor : Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _getDescriptionForBorder(design),
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (isSelected)
                        Icon(Icons.check_circle, color: activeColor)
                          .animate()
                          .scale(duration: 200.ms, curve: Curves.easeOutBack),
                    ],
                  ),
                ),
              ).animate().fadeIn(delay: (100 * index).ms).slideX(begin: 0.1, end: 0);
            },
          ),
          SizedBox(height: padding * 4), // Bottom padding for FAB/Navbar
        ],
      ),
    );
  }
  
  IconData _getIconForBorder(String design) {
    switch (design) {
      case 'Classic': return Icons.crop_square;
      case 'Modern': return Icons.crop_free;
      case 'Elegant': return Icons.filter_frames;
      case 'Regal': return Icons.workspace_premium;
      case 'Bold': return Icons.check_box_outline_blank;
      default: return Icons.crop_square;
    }
  }
  
  String _getDescriptionForBorder(String design) {
    switch (design) {
      case 'Classic': return 'A traditional, elegant solid line border.';
      case 'Modern': return 'Clean and minimal focus without outer constraints.';
      case 'Elegant': return 'A sophisticated double-line border.';
      case 'Regal': return 'A decorative border with corner accents.';
      case 'Bold': return 'A thick, striking solid border featuring your brand color.';
      default: return '';
    }
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
        primaryBreeds: _primaryBreedsController.text.trim().isEmpty ? null : _primaryBreedsController.text.trim(),
        localLogoPath: _logoPath,
        brandColorHex: _brandColorHex,
        certificateBorderTheme: _certificateBorderTheme,
      );

      await updateUseCase(updatedProfile);
      ref.invalidate(kennelProfileProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Kennel profile saved successfully!')),
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
      final permanentPath = await FileStorageService.saveImagePermanently(pickedFile.path);
      setState(() => _logoPath = permanentPath);
    }
  }
}
