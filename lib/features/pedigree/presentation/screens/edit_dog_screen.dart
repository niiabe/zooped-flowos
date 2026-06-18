import 'dart:io';
import 'package:sqlite3/sqlite3.dart' show SqliteException;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/responsive.dart';
import '../../domain/entities/dog.dart';
import '../providers/pedigree_providers.dart';
import '../providers/shared_providers.dart';
import 'dashboard_screen.dart';

final _editDogProvider = FutureProvider.family<Dog, int>((ref, dogId) async {
  final repo = ref.watch(pedigreeRepositoryProvider);
  return await repo.getDogById(dogId);
});

class EditDogScreen extends ConsumerStatefulWidget {
  final int dogId;

  const EditDogScreen({super.key, required this.dogId});

  @override
  ConsumerState<EditDogScreen> createState() => _EditDogScreenState();
}

class _EditDogScreenState extends ConsumerState<EditDogScreen> {
  final _formKey = GlobalKey<FormState>();
  final _registeredNameController = TextEditingController();
  final _callNameController = TextEditingController();
  final _microchipController = TextEditingController();
  final _colorController = TextEditingController();
  final _notesController = TextEditingController();
  final _dateOfBirthController = TextEditingController();
  final _imagePicker = ImagePicker();
  bool _dataLoaded = false;

  String _sex = 'Male';
  int? _selectedSireId;
  int? _selectedDamId;
  DateTime? _dateOfBirth;
  String? _photoPath;

  void _initFromDog(Dog dog) {
    if (_dataLoaded) return;
    _dataLoaded = true;
    _registeredNameController.text = dog.registeredName;
    _callNameController.text = dog.callName;
    _microchipController.text = dog.microchipNumber ?? '';
    _colorController.text = dog.colorMarkings ?? '';
    _notesController.text = dog.notes ?? '';
    _dateOfBirthController.text = dog.dateOfBirth != null
        ? DateFormat('yyyy-MM-dd').format(dog.dateOfBirth!)
        : '';
    _sex = dog.sex;
    _selectedSireId = dog.sire?.id;
    _selectedDamId = dog.dam?.id;
    _photoPath = dog.photoPath;
    _dateOfBirth = dog.dateOfBirth;
  }

  @override
  void dispose() {
    _registeredNameController.dispose();
    _callNameController.dispose();
    _microchipController.dispose();
    _colorController.dispose();
    _notesController.dispose();
    _dateOfBirthController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dogAsync = ref.watch(_editDogProvider(widget.dogId));
    final padding = Responsive.padding(context);
    final isTablet = Responsive.isTablet(context);
    final siresAsync = ref.watch(siresProvider);
    final damsAsync = ref.watch(damsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Dog'),
      ),
      body: dogAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Error: $e'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref.invalidate(_editDogProvider(widget.dogId)),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
        data: (dog) {
          _initFromDog(dog);

          return Form(
            key: _formKey,
            child: SingleChildScrollView(
              padding: EdgeInsets.all(padding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Basic Information',
                    style: TextStyle(
                      fontSize: isTablet ? 20.0 : 18.0,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.secondaryColor,
                    ),
                  ),
                  SizedBox(height: padding),

                  GestureDetector(
                    onTap: () async {
                  final picked = await _imagePicker.pickImage(source: ImageSource.gallery);
                      if (picked != null) {
                        setState(() => _photoPath = picked.path);
                      }
                    },
                    child: Container(
                      width: double.infinity,
                      height: 120,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: _photoPath != null
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.file(File(_photoPath!), fit: BoxFit.cover),
                            )
                          : Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.camera_alt, size: 32, color: Colors.grey.shade400),
                                const SizedBox(height: 8),
                                Text('Tap to add photo', style: TextStyle(color: Colors.grey.shade500)),
                              ],
                            ),
                    ),
                  ),
                  SizedBox(height: padding),

                  TextFormField(
                    controller: _registeredNameController,
                    decoration: const InputDecoration(
                      labelText: 'Registered Name *',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter registered name';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: padding),

                  TextFormField(
                    controller: _callNameController,
                    decoration: const InputDecoration(
                      labelText: 'Call Name *',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter call name';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: padding),

                  DropdownButtonFormField<String>(
                    initialValue: _sex,
                    decoration: const InputDecoration(
                      labelText: 'Sex *',
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'Male', child: Text('Male')),
                      DropdownMenuItem(value: 'Female', child: Text('Female')),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _sex = value!;
                      });
                    },
                  ),
                  SizedBox(height: padding),

                  TextFormField(
                    controller: _microchipController,
                    decoration: const InputDecoration(
                      labelText: 'Microchip Number (9-15 digits)',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value != null && value.isNotEmpty) {
                        if (value.length < 9 || value.length > 15) {
                          return 'Must be 9-15 digits';
                        }
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: padding),

                  TextFormField(
                    controller: _colorController,
                    decoration: const InputDecoration(
                      labelText: 'Color / Markings',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  SizedBox(height: padding),

                  TextFormField(
                    readOnly: true,
                    decoration: const InputDecoration(
                      labelText: 'Date of Birth',
                      border: OutlineInputBorder(),
                      suffixIcon: Icon(Icons.calendar_today),
                    ),
                    onTap: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: _dateOfBirth ?? DateTime.now(),
                        firstDate: DateTime(2000),
                        lastDate: DateTime.now(),
                      );
                      if (date != null) {
                        setState(() {
                          _dateOfBirth = date;
                        });
                      }
                    },
                  controller: _dateOfBirthController,
                  ),
                  SizedBox(height: padding * 2),

                  Text(
                    'Lineage (Optional)',
                    style: TextStyle(
                      fontSize: isTablet ? 20.0 : 18.0,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.secondaryColor,
                    ),
                  ),
                  SizedBox(height: padding),

                  siresAsync.when(
                    loading: () => const LinearProgressIndicator(),
                    error: (e, _) => Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('Error: $e'),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () => ref.invalidate(siresProvider),
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                    data: (sires) => DropdownButtonFormField<int>(
                      initialValue: _selectedSireId,
                      decoration: const InputDecoration(
                        labelText: 'Sire (Father) - Optional',
                        border: OutlineInputBorder(),
                      ),
                      items: [
                        const DropdownMenuItem<int>(value: null, child: Text('None')),
                        ...sires.where((d) => d.id != widget.dogId).map((d) {
                          return DropdownMenuItem(
                            value: d.id,
                            child: Text('${d.callName} (${d.registeredName})'),
                          );
                        }),
                      ],
                      onChanged: (value) {
                        setState(() {
                          _selectedSireId = value;
                        });
                      },
                    ),
                  ),
                  SizedBox(height: padding),
                  damsAsync.when(
                    loading: () => const LinearProgressIndicator(),
                    error: (e, _) => Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('Error: $e'),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () => ref.invalidate(damsProvider),
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                    data: (dams) => DropdownButtonFormField<int>(
                      initialValue: _selectedDamId,
                      decoration: const InputDecoration(
                        labelText: 'Dam (Mother) - Optional',
                        border: OutlineInputBorder(),
                      ),
                      items: [
                        const DropdownMenuItem<int>(value: null, child: Text('None')),
                        ...dams.where((d) => d.id != widget.dogId).map((d) {
                          return DropdownMenuItem(
                            value: d.id,
                            child: Text('${d.callName} (${d.registeredName})'),
                          );
                        }),
                      ],
                      onChanged: (value) {
                        setState(() {
                          _selectedDamId = value;
                        });
                      },
                    ),
                  ),
                  SizedBox(height: padding),

                  TextFormField(
                    controller: _notesController,
                    decoration: const InputDecoration(
                      labelText: 'Notes',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 3,
                  ),
                  SizedBox(height: padding * 2),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => _saveDog(dog),
                      style: ElevatedButton.styleFrom(
                        padding: EdgeInsets.symmetric(
                          vertical: isTablet ? 16.0 : 12.0,
                        ),
                      ),
                      child: const Text('Save Changes'),
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

  Future<void> _saveDog(Dog dog) async {
    if (!_formKey.currentState!.validate()) return;

    try {
      final repo = ref.read(pedigreeRepositoryProvider);

      final updated = dog.copyWith(
        registeredName: _registeredNameController.text.trim(),
        callName: _callNameController.text.trim(),
        sex: _sex,
        dateOfBirth: _dateOfBirth,
        microchipNumber: _microchipController.text.isEmpty
            ? null
            : _microchipController.text.trim(),
        colorMarkings: _colorController.text.isEmpty
            ? null
            : _colorController.text.trim(),
        photoPath: _photoPath,
        notes: _notesController.text.isEmpty
            ? null
            : _notesController.text.trim(),
      );

      await repo.updateDog(updated, sireId: _selectedSireId, damId: _selectedDamId);

      if (mounted) {
        ref.invalidate(dogsProvider);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Dog updated successfully')),
        );
        context.pop();
      }
    } on SqliteException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.message.contains('UNIQUE')
                ? 'A dog with this name or microchip already exists'
                : 'Error updating dog: $e'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating dog: $e')),
        );
      }
    }
  }
}
