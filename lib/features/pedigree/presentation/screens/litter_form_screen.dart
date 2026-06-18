import 'package:sqlite3/sqlite3.dart' show SqliteException;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/responsive.dart';
import '../../domain/entities/dog.dart';
import '../../domain/entities/litter.dart';
import '../providers/pedigree_providers.dart';
import '../providers/shared_providers.dart';
import 'dashboard_screen.dart';

class LitterFormScreen extends ConsumerStatefulWidget {
  const LitterFormScreen({super.key});

  @override
  ConsumerState<LitterFormScreen> createState() => _LitterFormScreenState();
}

class _LitterFormScreenState extends ConsumerState<LitterFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _matingDateController = TextEditingController();
  final _whelpingDateController = TextEditingController();
  final _puppiesBornController = TextEditingController();
  final _puppiesStillbornController = TextEditingController();
  final _notesController = TextEditingController();

  int? _selectedSireId;
  int? _selectedDamId;
  DateTime? _matingDate;
  DateTime? _whelpingDate;
  int _puppiesBornAlive = 0;
  int _puppiesStillborn = 0;

  final List<Map<String, dynamic>> _puppyEntries = [];

  @override
  void dispose() {
    _matingDateController.dispose();
    _whelpingDateController.dispose();
    _puppiesBornController.dispose();
    _puppiesStillbornController.dispose();
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
        title: const Text('Register Litter'),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: EdgeInsets.all(padding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Step 1: Select Parents',
                style: TextStyle(
                  fontSize: isTablet ? 20.0 : 18.0,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.secondaryColor,
                ),
              ),
              SizedBox(height: padding),

              if (isTablet)
                Row(
                  children: [
                    Expanded(
                      child: siresAsync.when(
                        loading: () => const LinearProgressIndicator(),
                        error: (e, _) => Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text('Error loading sires: $e'),
                            const SizedBox(height: 8),
                            ElevatedButton(
                              onPressed: () => ref.invalidate(siresProvider),
                              child: const Text('Retry'),
                            ),
                          ],
                        ),
                        data: (sires) => _buildSireDropdown(sires),
                      ),
                    ),
                    SizedBox(width: padding),
                    Expanded(
                      child: damsAsync.when(
                        loading: () => const LinearProgressIndicator(),
                        error: (e, _) => Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text('Error loading dams: $e'),
                            const SizedBox(height: 8),
                            ElevatedButton(
                              onPressed: () => ref.invalidate(damsProvider),
                              child: const Text('Retry'),
                            ),
                          ],
                        ),
                        data: (dams) => _buildDamDropdown(dams),
                      ),
                    ),
                  ],
                )
              else
                Column(
                  children: [
                    siresAsync.when(
                      loading: () => const LinearProgressIndicator(),
                      error: (e, _) => Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('Error loading sires: $e'),
                          const SizedBox(height: 8),
                          ElevatedButton(
                            onPressed: () => ref.invalidate(siresProvider),
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                      data: (sires) => _buildSireDropdown(sires),
                    ),
                    SizedBox(height: padding),
                    damsAsync.when(
                      loading: () => const LinearProgressIndicator(),
                      error: (e, _) => Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('Error loading dams: $e'),
                          const SizedBox(height: 8),
                          ElevatedButton(
                            onPressed: () => ref.invalidate(damsProvider),
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                      data: (dams) => _buildDamDropdown(dams),
                    ),
                  ],
                ),

              SizedBox(height: padding * 2),

              Text(
                'Step 2: Litter Dates',
                style: TextStyle(
                  fontSize: isTablet ? 20.0 : 18.0,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.secondaryColor,
                ),
              ),
              SizedBox(height: padding),

              if (isTablet)
                Row(
                  children: [
                    Expanded(
                      child: _buildMatingDatePicker(),
                    ),
                    SizedBox(width: padding),
                    Expanded(
                      child: _buildWhelpingDatePicker(),
                    ),
                  ],
                )
              else
                Column(
                  children: [
                    _buildMatingDatePicker(),
                    SizedBox(height: padding),
                    _buildWhelpingDatePicker(),
                  ],
                ),

              SizedBox(height: padding * 2),

              Text(
                'Step 3: Puppy Roster',
                style: TextStyle(
                  fontSize: isTablet ? 20.0 : 18.0,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.secondaryColor,
                ),
              ),
              SizedBox(height: padding),

              if (isTablet)
                Row(
                  children: [
                    Expanded(
                      child: _buildPuppiesBornField(),
                    ),
                    SizedBox(width: padding),
                    Expanded(
                      child: _buildPuppiesStillbornField(),
                    ),
                  ],
                )
              else
                Column(
                  children: [
                    _buildPuppiesBornField(),
                    SizedBox(height: padding),
                    _buildPuppiesStillbornField(),
                  ],
                ),

              SizedBox(height: padding),
              _buildNotesField(),
              SizedBox(height: padding * 1.5),

              if (_puppiesBornAlive > 0) ...[
                Text(
                  'Puppy Entries ($_puppiesBornAlive puppies)',
                  style: TextStyle(
                    fontSize: isTablet ? 18.0 : 16.0,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.secondaryColor,
                  ),
                ),
                SizedBox(height: padding * 0.5),
                if (isTablet)
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 2.0,
                      crossAxisSpacing: padding,
                      mainAxisSpacing: padding * 0.5,
                    ),
                    itemCount: _puppiesBornAlive,
                    itemBuilder: (context, index) {
                      return _buildPuppyEntryCard(index);
                    },
                  )
                else
                  ...List.generate(_puppiesBornAlive, (index) {
                    return _buildPuppyEntryCard(index);
                  }),
              ],

              SizedBox(height: padding * 2),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _saveLitter,
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(
                      vertical: isTablet ? 16.0 : 12.0,
                    ),
                  ),
                  child: const Text('Save Litter'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSireDropdown(List<Dog> sires) {
    return DropdownButtonFormField<int>(
      initialValue: _selectedSireId,
      decoration: const InputDecoration(
        labelText: 'Sire (Male)',
        border: OutlineInputBorder(),
      ),
      items: sires.map((dog) {
        return DropdownMenuItem(
          value: dog.id,
          child: Text(dog.callName),
        );
      }).toList(),
      onChanged: (value) {
        setState(() {
          _selectedSireId = value;
        });
      },
      validator: (value) {
        if (value == null) {
          return 'Please select a sire';
        }
        return null;
      },
    );
  }

  Widget _buildDamDropdown(List<Dog> dams) {
    return DropdownButtonFormField<int>(
      initialValue: _selectedDamId,
      decoration: const InputDecoration(
        labelText: 'Dam (Female)',
        border: OutlineInputBorder(),
      ),
      items: dams.map((dog) {
        return DropdownMenuItem(
          value: dog.id,
          child: Text(dog.callName),
        );
      }).toList(),
      onChanged: (value) {
        setState(() {
          _selectedDamId = value;
        });
      },
      validator: (value) {
        if (value == null) {
          return 'Please select a dam';
        }
        return null;
      },
    );
  }

  Widget _buildMatingDatePicker() {
    return TextFormField(
      controller: _matingDateController,
      decoration: const InputDecoration(
        labelText: 'Mating Date (Optional)',
        border: OutlineInputBorder(),
        suffixIcon: Icon(Icons.calendar_today),
      ),
      readOnly: true,
      onTap: () async {
        final date = await showDatePicker(
          context: context,
          initialDate: DateTime.now(),
          firstDate: DateTime(2000),
          lastDate: DateTime.now(),
        );
        if (date != null) {
          setState(() {
            _matingDate = date;
            _matingDateController.text = DateFormat('yyyy-MM-dd').format(date);
          });
        }
      },
    );
  }

  Widget _buildWhelpingDatePicker() {
    return TextFormField(
      controller: _whelpingDateController,
      decoration: const InputDecoration(
        labelText: 'Whelping Date (Birth Date)',
        border: OutlineInputBorder(),
        suffixIcon: Icon(Icons.calendar_today),
      ),
      readOnly: true,
      onTap: () async {
        final date = await showDatePicker(
          context: context,
          initialDate: DateTime.now(),
          firstDate: DateTime(2000),
          lastDate: DateTime.now().add(const Duration(days: 1)),
        );
        if (date != null) {
          setState(() {
            _whelpingDate = date;
            _whelpingDateController.text = DateFormat('yyyy-MM-dd').format(date);
          });
        }
      },
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please select a whelping date';
        }
        return null;
      },
    );
  }

  Widget _buildPuppiesBornField() {
    return TextFormField(
      controller: _puppiesBornController,
      decoration: const InputDecoration(
        labelText: 'Puppies Born Alive',
        border: OutlineInputBorder(),
      ),
      keyboardType: TextInputType.number,
      onChanged: (value) {
        setState(() {
          _puppiesBornAlive = int.tryParse(value) ?? 0;
          while (_puppyEntries.length < _puppiesBornAlive) {
            _puppyEntries.add({'callName': '', 'sex': 'Male', 'microchip': ''});
          }
          if (_puppyEntries.length > _puppiesBornAlive) {
            _puppyEntries.removeRange(_puppiesBornAlive, _puppyEntries.length);
          }
        });
      },
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter number of puppies';
        }
        if (int.tryParse(value) == null) {
          return 'Please enter a valid number';
        }
        return null;
      },
    );
  }

  Widget _buildPuppiesStillbornField() {
    return TextFormField(
      controller: _puppiesStillbornController,
      decoration: const InputDecoration(
        labelText: 'Puppies Stillborn (Optional)',
        border: OutlineInputBorder(),
      ),
      keyboardType: TextInputType.number,
      onChanged: (value) {
        setState(() {
          _puppiesStillborn = int.tryParse(value) ?? 0;
        });
      },
    );
  }

  Widget _buildNotesField() {
    return TextFormField(
      controller: _notesController,
      decoration: const InputDecoration(
        labelText: 'Notes (Optional)',
        border: OutlineInputBorder(),
      ),
      maxLines: 3,
    );
  }

  Widget _buildPuppyEntryCard(int index) {
    final isTablet = Responsive.isTablet(context);
    final padding = Responsive.padding(context);

    return Card(
      key: ValueKey('puppy_entry_$index'),
      margin: EdgeInsets.only(bottom: padding * 0.5),
      child: Padding(
        padding: EdgeInsets.all(padding * 0.75),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Puppy ${index + 1}',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: isTablet ? 14.0 : 12.0,
                color: AppTheme.secondaryColor,
              ),
            ),
            SizedBox(height: padding * 0.5),
            TextFormField(
              decoration: InputDecoration(
                labelText: 'Call Name',
                border: const OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: padding * 0.75,
                  vertical: padding * 0.5,
                ),
              ),
              style: TextStyle(fontSize: isTablet ? 14.0 : 12.0),
              onChanged: (value) {
                if (index < _puppyEntries.length) {
                  _puppyEntries[index]['callName'] = value;
                }
              },
            ),
            SizedBox(height: padding * 0.5),
            DropdownButtonFormField<String>(
              initialValue: _puppyEntries[index]['sex'] as String,
              decoration: InputDecoration(
                labelText: 'Sex',
                border: const OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: padding * 0.75,
                  vertical: padding * 0.5,
                ),
              ),
              items: const [
                DropdownMenuItem(value: 'Male', child: Text('Male')),
                DropdownMenuItem(value: 'Female', child: Text('Female')),
              ],
              onChanged: (value) {
                if (index < _puppyEntries.length) {
                  setState(() {
                    _puppyEntries[index]['sex'] = value!;
                  });
                }
              },
            ),
            SizedBox(height: padding * 0.5),
            TextFormField(
              decoration: InputDecoration(
                labelText: 'Microchip Number',
                border: const OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: padding * 0.75,
                  vertical: padding * 0.5,
                ),
              ),
              style: TextStyle(fontSize: isTablet ? 14.0 : 12.0),
              onChanged: (value) {
                if (index < _puppyEntries.length) {
                  _puppyEntries[index]['microchip'] = value;
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveLitter() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      final repo = ref.read(pedigreeRepositoryProvider);

      final litter = Litter(
        id: 0,
        sireId: _selectedSireId!,
        damId: _selectedDamId!,
        matingDate: _matingDate,
        whelpingDate: _whelpingDate!,
        puppiesBornAlive: _puppiesBornAlive,
        puppiesStillborn: _puppiesStillborn,
        notes: _notesController.text.isEmpty ? null : _notesController.text,
      );

      final puppies = <Dog>[];
      for (final entry in _puppyEntries) {
        final callName = (entry['callName'] as String?)?.trim() ?? '';
        if (callName.isEmpty) continue;

        final sex = entry['sex'] as String;
        final microchip = (entry['microchip'] as String?)?.trim();

        puppies.add(Dog(
          id: 0,
          registeredName: callName,
          callName: callName,
          sex: sex,
          microchipNumber: microchip?.isEmpty == true ? null : microchip,
          sire: null,
          dam: null,
          litterId: 0,
          createdAt: DateTime.now(),
        ));
      }

      await repo.createLitterWithPuppies(litter, puppies);

      if (mounted) {
        ref.invalidate(dogsProvider);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Litter registered successfully')),
        );
        context.pop();
      }
    } on SqliteException catch (e) {
      if (mounted) {
        final message = e.message.contains('UNIQUE')
            ? 'A dog with this name or microchip already exists'
            : 'Database error: ${e.message}';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving litter: $e')),
        );
      }
    }
  }
}
