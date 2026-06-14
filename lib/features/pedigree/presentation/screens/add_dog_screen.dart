import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/responsive.dart';
import '../../domain/entities/dog.dart';
import '../providers/pedigree_providers.dart';
import '../providers/shared_providers.dart';

class AddDogScreen extends ConsumerStatefulWidget {
  const AddDogScreen({super.key});

  @override
  ConsumerState<AddDogScreen> createState() => _AddDogScreenState();
}

class _AddDogScreenState extends ConsumerState<AddDogScreen> {
  final _formKey = GlobalKey<FormState>();
  final _registeredNameController = TextEditingController();
  final _callNameController = TextEditingController();
  final _microchipController = TextEditingController();
  final _colorController = TextEditingController();
  final _notesController = TextEditingController();

  String _sex = 'Male';
  int? _selectedSireId;
  int? _selectedDamId;
  DateTime? _dateOfBirth;

  @override
  void dispose() {
    _registeredNameController.dispose();
    _callNameController.dispose();
    _microchipController.dispose();
    _colorController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final padding = Responsive.padding(context);
    final isTablet = Responsive.isTablet(context);
    final siresAsync = ref.watch(siresProvider);
    final damsAsync = ref.watch(damsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Dog'),
      ),
      body: Form(
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
                    _selectedSireId = null;
                    _selectedDamId = null;
                  });
                },
              ),
              SizedBox(height: padding),

              TextFormField(
                controller: _microchipController,
                decoration: const InputDecoration(
                  labelText: 'Microchip Number',
                  border: OutlineInputBorder(),
                ),
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
                decoration: InputDecoration(
                  labelText: 'Date of Birth',
                  border: const OutlineInputBorder(),
                  suffixIcon: const Icon(Icons.calendar_today),
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
                controller: TextEditingController(
                  text: _dateOfBirth?.toString().split(' ')[0] ?? '',
                ),
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

              if (_sex == 'Male') ...[
                siresAsync.when(
                  loading: () => const LinearProgressIndicator(),
                  error: (e, _) => Text('Error: $e'),
                  data: (sires) => DropdownButtonFormField<int>(
                    decoration: const InputDecoration(
                      labelText: 'Sire (Father)',
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
              ] else ...[
                damsAsync.when(
                  loading: () => const LinearProgressIndicator(),
                  error: (e, _) => Text('Error: $e'),
                  data: (dams) => DropdownButtonFormField<int>(
                    decoration: const InputDecoration(
                      labelText: 'Dam (Mother)',
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
              ],
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
      final insertUseCase = ref.read(insertDogUseCaseProvider);
      final sire = _selectedSireId != null
          ? await ref.read(getDogByIdUseCaseProvider)(_selectedSireId!)
          : null;
      final dam = _selectedDamId != null
          ? await ref.read(getDogByIdUseCaseProvider)(_selectedDamId!)
          : null;

      final dog = Dog(
        id: 0,
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
        sire: sire,
        dam: dam,
        notes: _notesController.text.isEmpty
            ? null
            : _notesController.text.trim(),
        createdAt: DateTime.now(),
      );

      await insertUseCase(dog);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Dog added successfully')),
        );
        context.pop();
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
