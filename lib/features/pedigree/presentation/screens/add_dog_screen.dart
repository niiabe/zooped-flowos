import 'dart:io';
import 'package:sqlite3/sqlite3.dart' show SqliteException;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/responsive.dart';
import '../../../../core/services/file_storage_service.dart';
import '../../domain/entities/dog.dart';
import '../providers/pedigree_providers.dart';
import '../providers/shared_providers.dart';
import 'dashboard_screen.dart';

class AddDogScreen extends ConsumerStatefulWidget {
  final int? childId;
  final bool? isSire;

  const AddDogScreen({super.key, this.childId, this.isSire});

  @override
  ConsumerState<AddDogScreen> createState() => _AddDogScreenState();
}

class _AddDogScreenState extends ConsumerState<AddDogScreen> {
  final _formKey = GlobalKey<FormState>();
  final _registeredNameController = TextEditingController();
  final _callNameController = TextEditingController();
  final _breedController = TextEditingController();
  final _microchipController = TextEditingController();
  final _colorController = TextEditingController();
  final _notesController = TextEditingController();
  final _dateOfBirthController = TextEditingController();
  final _imagePicker = ImagePicker();

  String _sex = 'Male';
  int? _selectedSireId;
  int? _selectedDamId;
  String _saleStatus = 'Not For Sale';
  DateTime? _dateOfBirth;
  String? _photoPath;

  @override
  void initState() {
    super.initState();
    if (widget.isSire != null) {
      _sex = widget.isSire! ? 'Male' : 'Female';
    }
    if (widget.childId != null) {
      _saleStatus = 'Not Owned';
    }
  }

  @override
  void dispose() {
    _registeredNameController.dispose();
    _callNameController.dispose();
    _breedController.dispose();
    _microchipController.dispose();
    _colorController.dispose();
    _notesController.dispose();
    _dateOfBirthController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final padding = Responsive.padding(context);
    final isTablet = Responsive.isTablet(context);
    final siresAsync = ref.watch(siresProvider);
    final damsAsync = ref.watch(damsProvider);
    final kennelProfile = ref.watch(kennelProfileProvider).valueOrNull;
    final availableBreeds = kennelProfile?.primaryBreeds
            ?.split(',')
            .map((e) => e.trim())
            .where((e) => e.isNotEmpty)
            .toList() ??
        [];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Dog'),
      ),
      body: Form(
        key: _formKey,
        autovalidateMode: AutovalidateMode.onUserInteraction,
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
                    final permanentPath = await FileStorageService.saveImagePermanently(picked.path);
                    setState(() => _photoPath = permanentPath);
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

              RawAutocomplete<String>(
                textEditingController: _breedController,
                focusNode: FocusNode(),
                optionsBuilder: (TextEditingValue textEditingValue) {
                  if (textEditingValue.text.isEmpty) {
                    return availableBreeds;
                  }
                  return availableBreeds.where((String option) {
                    return option.toLowerCase().contains(textEditingValue.text.toLowerCase());
                  });
                },
                fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
                  return TextFormField(
                    controller: controller,
                    focusNode: focusNode,
                    decoration: const InputDecoration(
                      labelText: 'Breed',
                      border: OutlineInputBorder(),
                    ),
                  );
                },
                optionsViewBuilder: (context, onSelected, options) {
                  return Align(
                    alignment: Alignment.topLeft,
                    child: Material(
                      elevation: 4.0,
                      child: SizedBox(
                        height: 200.0,
                        width: MediaQuery.of(context).size.width - (padding * 2),
                        child: ListView.builder(
                          padding: EdgeInsets.zero,
                          itemCount: options.length,
                          itemBuilder: (BuildContext context, int index) {
                            final option = options.elementAt(index);
                            return InkWell(
                              onTap: () => onSelected(option),
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Text(option),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  );
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
                onChanged: widget.isSire != null
                    ? null // Disable changing sex if we are specifically adding a Sire or Dam
                    : (value) {
                        setState(() {
                          _sex = value!;
                        });
                      },
              ),
              SizedBox(height: padding),
              
              DropdownButtonFormField<String>(
                  initialValue: _saleStatus,
                  decoration: const InputDecoration(
                    labelText: 'Sale Status',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'Not For Sale', child: Text('Not For Sale')),
                    DropdownMenuItem(value: 'Available', child: Text('Available')),
                    DropdownMenuItem(value: 'Reserved', child: Text('Reserved')),
                    DropdownMenuItem(value: 'Sold', child: Text('Sold')),
                    DropdownMenuItem(value: 'Not Owned', child: Text('Not Owned')),
                  ],
                onChanged: (value) {
                  if (value != null) setState(() => _saleStatus = value);
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
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
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
                    initialDate: DateTime.now(),
                    firstDate: DateTime(2000),
                    lastDate: DateTime.now(),
                  );
                  if (date != null) {
                    setState(() {
                      _dateOfBirth = date;
                    });
                  }
                },
                  controller: _dateOfBirthController
                    ..text = _dateOfBirth != null
                        ? DateFormat('yyyy-MM-dd').format(_dateOfBirth!)
                        : '',
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
                  decoration: const InputDecoration(
                    labelText: 'Sire (Father) - Optional',
                    border: OutlineInputBorder(),
                  ),
                  items: sires.map((dog) {
                    return DropdownMenuItem(
                      value: dog.id,
                      child: Text('${dog.callName} (${dog.registeredName})'),
                    );
                  }).toList(),
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
                  decoration: const InputDecoration(
                    labelText: 'Dam (Mother) - Optional',
                    border: OutlineInputBorder(),
                  ),
                  items: dams.map((dog) {
                    return DropdownMenuItem(
                      value: dog.id,
                      child: Text('${dog.callName} (${dog.registeredName})'),
                    );
                  }).toList(),
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
                  onPressed: _saveDog,
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(
                      vertical: isTablet ? 16.0 : 12.0,
                    ),
                  ),
                  child: const Text('Save Dog'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _saveDog() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      final repo = ref.read(pedigreeRepositoryProvider);

      final dog = Dog(
        id: 0,
        registeredName: _registeredNameController.text.trim(),
        callName: _callNameController.text.trim(),
        breed: _breedController.text.isEmpty ? null : _breedController.text.trim(),
        sex: _sex,
        dateOfBirth: _dateOfBirth,
        microchipNumber: _microchipController.text.isEmpty
            ? null
            : _microchipController.text.trim(),
        colorMarkings: _colorController.text.isEmpty
            ? null
            : _colorController.text.trim(),
        photoPath: _photoPath,
        saleStatus: _saleStatus,
        notes: _notesController.text.isEmpty
            ? null
            : _notesController.text.trim(),
        createdAt: DateTime.now(),
      );

      final newDogId = await repo.insertDog(dog, sireId: _selectedSireId, damId: _selectedDamId);

      if (widget.childId != null && widget.isSire != null) {
        if (!mounted) return;
        if (widget.isSire!) {
          await repo.updateDogParent(widget.childId!, sireId: newDogId, updateSire: true);
        } else {
          await repo.updateDogParent(widget.childId!, damId: newDogId, updateDam: true);
        }
      }

      if (mounted) {
        ref.invalidate(dogsProvider);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Dog added successfully')),
        );
        context.pop(true);
      }
    } on SqliteException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.message.contains('UNIQUE')
                ? 'A dog with this name or microchip already exists'
                : 'Error saving dog: $e'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving dog: $e')),
        );
      }
    }
  }
}
