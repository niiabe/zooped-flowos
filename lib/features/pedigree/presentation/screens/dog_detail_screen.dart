import 'dart:io';
import 'dart:typed_data';
import 'package:share_plus/share_plus.dart';
import 'package:sqlite3/sqlite3.dart' show SqliteException;
import 'package:printing/printing.dart';
import '../../../../core/database/app_database.dart' hide Dog;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/services/certificate_service.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/services/file_storage_service.dart';
import '../../../../core/utils/responsive.dart';
import '../../domain/entities/dog.dart';
import '../providers/pedigree_providers.dart';
import '../providers/shared_providers.dart';
import '../widgets/pedigree_canvas.dart';
import 'dashboard_screen.dart';

final _dogProvider = FutureProvider.family<Dog, int>((ref, dogId) async {
  final repo = ref.watch(pedigreeRepositoryProvider);
  return await repo.getDogByIdWithPedigree(dogId);
});

class DogDetailScreen extends ConsumerStatefulWidget {
  final int dogId;

  const DogDetailScreen({super.key, required this.dogId});

  @override
  ConsumerState<DogDetailScreen> createState() => _DogDetailScreenState();
}

class _DogDetailScreenState extends ConsumerState<DogDetailScreen> {
  bool _generatingPdf = false;
  final GlobalKey _pedigreeExportKey = GlobalKey();
  Dog? _dog;
  final _imagePicker = ImagePicker();

  @override
  Widget build(BuildContext context) {
    final dogAsync = ref.watch(_dogProvider(widget.dogId));
    final padding = Responsive.padding(context);
    final isTablet = Responsive.isTablet(context);

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('Dog Profile', style: TextStyle(fontWeight: FontWeight.w600)),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: AppTheme.secondaryColor,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            onPressed: () => context.push('/dog/${widget.dogId}/edit'),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: _dog != null ? () => _confirmDelete(context) : null,
          ),
        ],
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
          _dog = dog;
          
          const tabBar = TabBar(
            labelColor: AppTheme.primaryColor,
            unselectedLabelColor: Colors.grey,
            indicatorColor: AppTheme.primaryColor,
            tabs: [
              Tab(text: 'Pedigree Map'),
              Tab(text: 'Health Records'),
              Tab(text: 'Shows & Titles'),
              Tab(text: 'Litters & Offspring'),
            ],
          );

          final tabBarView = TabBarView(
            physics: const NeverScrollableScrollPhysics(),
            children: [
              PedigreeCanvas(
                exportKey: _pedigreeExportKey,
                rootDog: dog,
                onDogTap: (selectedDog) {
                  context.push('/dog/${selectedDog.id}');
                },
                onUnknownTap: (childDog, isSire, roleName) async {
                  if (childDog == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Please add the missing parent first before adding grandparents.')),
                    );
                    return;
                  }

                  final confirmed = await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: Text('Add $roleName'),
                      content: Text('Would you like to add a new dog as the $roleName for ${childDog.callName}?'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx, false),
                          child: const Text('Cancel'),
                        ),
                        ElevatedButton(
                          onPressed: () => Navigator.pop(ctx, true),
                          child: const Text('Add Dog'),
                        ),
                      ],
                    ),
                  );

                  if (confirmed == true && context.mounted) {
                    final result = await context.push<bool>('/dog/new', extra: {
                      'childId': childDog.id,
                      'isSire': isSire,
                    });
                    
                    if (result == true && context.mounted) {
                      ref.invalidate(_dogProvider(widget.dogId));
                    }
                  }
                },
              ),
              _buildHealthTab(context, dog),
              _buildShowTab(context, dog),
              _buildOffspringTab(context, dog),
            ],
          );

          if (isTablet) {
            return DefaultTabController(
              length: 4,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    width: 350.0,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 15.0,
                          offset: const Offset(4, 0),
                        ),
                      ],
                    ),
                    child: SingleChildScrollView(
                      child: _buildIdentityPanel(context, dog, padding),
                    ),
                  ),
                  Expanded(
                    child: Column(
                      children: [
                        tabBar,
                        Expanded(child: tabBarView),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }

          return DefaultTabController(
            length: 4,
            child: NestedScrollView(
              headerSliverBuilder: (context, innerBoxIsScrolled) {
                return [
                  SliverToBoxAdapter(
                    child: Container(
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
                      child: ClipRRect(
                        borderRadius: const BorderRadius.only(
                          bottomLeft: Radius.circular(24.0),
                          bottomRight: Radius.circular(24.0),
                        ),
                        child: _buildIdentityPanel(context, dog, padding),
                      ),
                    ),
                  ),
                  SliverPersistentHeader(
                    pinned: true,
                    delegate: _SliverAppBarDelegate(tabBar),
                  ),
                ];
              },
              body: tabBarView,
            ),
          );
        },
      ),
    );
  }

  Future<Map<int, Uint8List>> _preloadDogImages(Dog rootDog) async {
    final Map<int, Uint8List> imageMap = {};
    final List<Dog> allAncestors = [rootDog];
    
    // Breadth-first collection of all ancestors
    int i = 0;
    while (i < allAncestors.length) {
      final current = allAncestors[i];
      if (current.sire != null) allAncestors.add(current.sire!);
      if (current.dam != null) allAncestors.add(current.dam!);
      i++;
    }

    // Process all images in parallel
    await Future.wait(allAncestors.map((dog) async {
      if (dog.photoPath != null && dog.photoPath!.isNotEmpty) {
        try {
          final file = File(dog.photoPath!);
          if (await file.exists()) {
            final bytes = await file.readAsBytes();
            imageMap[dog.id] = bytes;
          }
        } catch (_) {
          // Ignore failed image loads
        }
      }
    }));
    
    return imageMap;
  }

  Future<void> _generateAndPrintCertificate(Dog dog) async {
    setState(() => _generatingPdf = true);
    try {
      final profile = await ref.read(kennelProfileProvider.future);
      final logoFile = profile.localLogoPath != null ? File(profile.localLogoPath!) : null;
      final preloadedImages = await _preloadDogImages(dog);
      
      final pdfBytes = await CertificateService.generateCertificate(
        dog: dog,
        kennelProfile: profile,
        logoFile: logoFile,
        preloadedImages: preloadedImages,
      );
      await CertificateService.printPdf(pdfBytes);
    } on SqliteException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.message.contains('UNIQUE')
                ? 'A record with this name or microchip already exists'
                : 'Error generating certificate: $e'),
          ),
        );
      }
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

  Future<void> _generateAndShareSocial(Dog dog) async {
    setState(() => _generatingPdf = true);
    try {
      final profile = await ref.read(kennelProfileProvider.future);
      final logoFile = profile.localLogoPath != null ? File(profile.localLogoPath!) : null;
      final preloadedImages = await _preloadDogImages(dog);
      
      final pdfBytes = await CertificateService.generateCertificate(
        dog: dog,
        kennelProfile: profile,
        logoFile: logoFile,
        preloadedImages: preloadedImages,
      );

      // Rasterize the PDF to an image
      await for (final page in Printing.raster(pdfBytes, pages: [0], dpi: 300)) {
        final pngBytes = await page.toPng();
        final tempDir = await getTemporaryDirectory();
        final file = File(p.join(tempDir.path, 'social_pedigree_${dog.id}.png'));
        await file.writeAsBytes(pngBytes);
        
        await Share.shareXFiles(
          [XFile(file.path)],
          text: 'Check out ${dog.callName}\'s Pedigree! #ZooPed',
        );
        break; // Only need the first page
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error generating image: $e')));
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
      final preloadedImages = await _preloadDogImages(dog);
      
      final pdfBytes = await CertificateService.generateCertificate(
        dog: dog,
        kennelProfile: profile,
        logoFile: logoFile,
        preloadedImages: preloadedImages,
      );
      await CertificateService.sharePdf(pdfBytes, dog.registeredName);
    } on SqliteException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.message.contains('UNIQUE')
                ? 'A record with this name or microchip already exists'
                : 'Error generating certificate: $e'),
          ),
        );
      }
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

  Widget _buildOffspringTab(BuildContext context, Dog dog) {
    final offspringAsync = ref.watch(dogOffspringProvider(dog.id));
    final littersAsync = ref.watch(dogLittersProvider(dog.id));

    return CustomScrollView(
      slivers: [
        const SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text('Litters', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ),
        ),
        littersAsync.when(
          loading: () => const SliverToBoxAdapter(child: Center(child: CircularProgressIndicator())),
          error: (err, stack) => SliverToBoxAdapter(child: Text('Error: $err')),
          data: (litters) {
            if (litters.isEmpty) {
              return const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Text('No litters recorded yet.', style: TextStyle(color: Colors.grey)),
                ),
              );
            }
            return SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final litter = litters[index];
                  return Card(
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    child: ListTile(
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.family_restroom, color: AppTheme.primaryColor),
                      ),
                      title: Text('Whelped: ${DateFormat('yyyy-MM-dd').format(litter.whelpingDate)}'),
                      subtitle: Text('${litter.totalPuppiesBorn} puppies'),
                    ),
                  );
                },
                childCount: litters.length,
              ),
            );
          },
        ),
        const SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.fromLTRB(16, 24, 16, 8),
            child: Text('Offspring', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ),
        ),
        offspringAsync.when(
          loading: () => const SliverToBoxAdapter(child: Center(child: CircularProgressIndicator())),
          error: (err, stack) => SliverToBoxAdapter(child: Text('Error: $err')),
          data: (offspring) {
            if (offspring.isEmpty) {
              return const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Text('No offspring assigned yet.', style: TextStyle(color: Colors.grey)),
                ),
              );
            }
            return SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final puppy = offspring[index];
                  return Card(
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    child: ListTile(
                      leading: const CircleAvatar(child: Icon(Icons.pets)),
                      title: Text(puppy.callName),
                      subtitle: Text(puppy.registeredName),
                      onTap: () => context.push('/dog/${puppy.id}'),
                    ),
                  );
                },
                childCount: offspring.length,
              ),
            );
          },
        ),
        const SliverPadding(padding: EdgeInsets.only(bottom: 24)),
      ],
    );
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final dog = _dog;
    if (dog == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Dog'),
        content: Text(
          'Are you sure you want to delete ${dog.callName}? This will remove all records related to this dog, including pedigree links and associated litters.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      try {
        await ref.read(pedigreeRepositoryProvider).deleteDog(widget.dogId);
        if (context.mounted) {
          ref.invalidate(dogsProvider);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('${dog.callName} has been deleted.')),
          );
          context.go('/');
        }
      } on SqliteException catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(e.message.contains('UNIQUE')
                  ? 'A record with this name or microchip already exists'
                  : 'Error deleting dog: $e'),
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error deleting dog: $e')),
          );
        }
      }
    }
  }

  Widget _buildIdentityPanel(BuildContext context, Dog dog, double padding) {
    final isTablet = Responsive.isTablet(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Premium Gradient Header
        Container(
          padding: EdgeInsets.fromLTRB(padding, padding * 1.5, padding, padding),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppTheme.primaryColor.withValues(alpha: 0.1),
                Colors.white,
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      dog.registeredName,
                      style: TextStyle(
                        fontSize: isTablet ? 28.0 : 22.0,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.secondaryColor,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 6.0),
                    Row(
                      children: [
                        Icon(
                          dog.sex == 'Male' ? Icons.male : Icons.female,
                          color: dog.sex == 'Male' ? Colors.blue : Colors.pink,
                          size: 20.0,
                        ),
                        const SizedBox(width: 4.0),
                        Text(
                          dog.callName,
                          style: TextStyle(
                            fontSize: isTablet ? 18.0 : 16.0,
                            fontWeight: FontWeight.w500,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (dog.photoPath != null && File(dog.photoPath!).existsSync())
                Hero(
                  tag: 'dog_banner_photo_${dog.id}',
                  child: CircleAvatar(
                    radius: isTablet ? 40 : 30,
                    backgroundImage: ResizeImage(FileImage(File(dog.photoPath!)), width: 150),
                    onBackgroundImageError: (e, s) => {},
                  ),
                ),
            ],
          ),
        ),

        // Photo
        if (dog.photoPath != null)
          Padding(
            padding: EdgeInsets.all(padding),
            child: Hero(
              tag: 'dog_photo_${dog.id}',
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.file(
                  File(dog.photoPath!),
                  height: 200,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  cacheWidth: 800,
                  errorBuilder: (context, error, stackTrace) => const SizedBox.shrink(),
                ),
              ),
            ),
          ),
        
        // Chips Area
        Padding(
          padding: EdgeInsets.symmetric(horizontal: padding),
          child: Wrap(
            spacing: 8.0,
            runSpacing: 10.0,
            children: [
              if (dog.breed != null && dog.breed!.isNotEmpty)
                _buildDetailChip(Icons.pets, 'Breed', dog.breed!),
              if (dog.microchipNumber != null && dog.microchipNumber!.isNotEmpty)
                _buildDetailChip(Icons.memory, 'Chip', dog.microchipNumber!),
              if (dog.dateOfBirth != null)
                if (dog.dateOfBirth != null)
                  _buildDetailChip(Icons.cake, 'DOB', DateFormat('yyyy-MM-dd').format(dog.dateOfBirth!)),
              if (dog.colorMarkings != null && dog.colorMarkings!.isNotEmpty)
                _buildDetailChip(Icons.palette, 'Color', dog.colorMarkings!),
              if (dog.registerType != null && dog.registerType!.isNotEmpty)
                _buildDetailChip(Icons.badge, 'Reg', dog.registerType!),
              if (dog.appraisalScore != null)
                _buildAppraisalBadge(dog.appraisalScore!),
              if (dog.inbreedingCoefficient != null)
                _buildDetailChip(Icons.science, 'COI', '${dog.inbreedingCoefficient}%'),
            ],
          ),
        ),

        // Action Buttons
        SafeArea(
          top: false,
          child: Padding(
            padding: EdgeInsets.all(padding),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _generatingPdf ? null : () => _generateAndPrintCertificate(dog),
                    icon: _generatingPdf
                        ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.print, size: 20),
                    label: const Text('Print'),
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: isTablet ? 16.0 : 14.0),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
                    ),
                  ),
                ),
                SizedBox(width: padding * 0.5),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _generatingPdf ? null : () => _generateAndShareCertificate(dog),
                    icon: _generatingPdf
                        ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Icon(Icons.picture_as_pdf, size: 20),
                    label: const Text('PDF'),
                    style: OutlinedButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: isTablet ? 16.0 : 14.0),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
                      side: BorderSide(color: AppTheme.primaryColor.withValues(alpha: 0.5)),
                    ),
                  ),
                ),
                SizedBox(width: padding * 0.5),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _generatingPdf ? null : () => _generateAndShareSocial(dog),
                    icon: _generatingPdf
                        ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Icon(Icons.share, size: 20),
                    label: const Text('Social'),
                    style: OutlinedButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: isTablet ? 16.0 : 14.0),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
                      side: BorderSide(color: AppTheme.primaryColor.withValues(alpha: 0.5)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        // Photo Gallery Section
        _buildPhotoGallery(context, dog),
        const SizedBox(height: 16.0),
      ],
    );
  }

  Widget _buildDetailChip(IconData icon, String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 8.0),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(10.0),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14.0, color: Colors.grey.shade600),
          const SizedBox(width: 6.0),
          Text(
            '$label: ',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade600,
              fontSize: 12.0,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: AppTheme.secondaryColor,
              fontSize: 12.0,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppraisalBadge(double score) {
    Color badgeColor;
    String label;
    IconData icon;

    if (score >= 90) {
      badgeColor = Colors.amber.shade600;
      label = 'Gold';
      icon = Icons.emoji_events;
    } else if (score >= 80) {
      badgeColor = Colors.blueGrey.shade400;
      label = 'Silver';
      icon = Icons.workspace_premium;
    } else if (score >= 70) {
      badgeColor = Colors.brown.shade400;
      label = 'Bronze';
      icon = Icons.military_tech;
    } else {
      badgeColor = Colors.grey.shade600;
      label = 'Appraised';
      icon = Icons.verified;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [badgeColor.withValues(alpha: 0.1), badgeColor.withValues(alpha: 0.2)],
        ),
        borderRadius: BorderRadius.circular(10.0),
        border: Border.all(color: badgeColor.withValues(alpha: 0.3), width: 1.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16.0, color: badgeColor)
              .animate(onPlay: (c) => c.repeat(reverse: true))
              .scaleXY(begin: 0.9, end: 1.1, duration: 1.seconds, curve: Curves.easeInOut),
          const SizedBox(width: 6.0),
          Text(
            '$label: ',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: badgeColor,
              fontSize: 12.0,
            ),
          ),
          Text(
            score.toStringAsFixed(1),
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: badgeColor,
              fontSize: 13.0,
            ),
          ),
        ],
      ),
    ).animate().fadeIn().scale(curve: Curves.easeOutBack);
  }

  Widget _buildPhotoGallery(BuildContext context, Dog dog) {
    final galleryAsync = ref.watch(dogGalleryProvider(dog.id));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Photo Gallery', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              TextButton.icon(
                onPressed: () => _addGalleryPhoto(dog.id),
                icon: const Icon(Icons.add_a_photo, size: 18),
                label: const Text('Add'),
              ),
            ],
          ),
        ),
        galleryAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('Error loading gallery: $e'),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => ref.invalidate(dogGalleryProvider(dog.id)),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
          data: (photos) {
            if (photos.isEmpty) {
              return const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.0),
                child: Text('No photos yet. Add some to build a gallery!', style: TextStyle(color: Colors.grey)),
              );
            }
            return SizedBox(
              height: 120,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                itemCount: photos.length,
                itemBuilder: (context, index) {
                  final photo = photos[index];
                  return Stack(
                    children: [
                      Container(
                        width: 120,
                        margin: const EdgeInsets.only(right: 8.0),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.file(
                            File(photo.photoPath),
                            fit: BoxFit.cover,
                            cacheWidth: 400,
                            errorBuilder: (context, error, stackTrace) => Container(
                              color: Colors.grey.shade200,
                              child: const Icon(Icons.broken_image, color: Colors.grey),
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        top: 4,
                        right: 12,
                        child: GestureDetector(
                          onTap: () => _deleteGalleryPhoto(photo.id, dog.id, photo.photoPath),
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: Colors.black54,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.close, size: 14, color: Colors.white),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            );
          },
        ),
      ],
    );
  }

  Future<void> _addGalleryPhoto(int dogId) async {
    final picked = await _imagePicker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      final db = ref.read(databaseProvider);
      await db.addDogPhoto(DogPhotosCompanion.insert(
        dogId: dogId,
        photoPath: picked.path,
      ));
      ref.invalidate(dogGalleryProvider(dogId));
    }
  }

  Future<void> _deleteGalleryPhoto(int photoId, int dogId, String path) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Photo'),
        content: const Text('Remove this photo from the gallery?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final db = ref.read(databaseProvider);
      await FileStorageService.deleteFile(path);
      await db.deleteDogPhoto(photoId);
      ref.invalidate(dogGalleryProvider(dogId));
    }
  }

  Widget _buildHealthTab(BuildContext context, Dog dog) {
    final healthAsync = ref.watch(healthRecordsProvider(dog.id));
    
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Medical History', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ElevatedButton.icon(
                onPressed: () => context.push('/dog/${dog.id}/health/new'),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Add Record'),
              ),
            ],
          ),
        ),
        Expanded(
          child: healthAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Error: $e'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => ref.invalidate(healthRecordsProvider(dog.id)),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
            data: (records) {
              if (records.isEmpty) {
                return const Center(
                  child: Text('No health records found.', style: TextStyle(color: Colors.grey)),
                );
              }
              return ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                itemCount: records.length,
                itemBuilder: (context, index) {
                  final record = records[index];
                  final dateStr = DateFormat('yyyy-MM-dd').format(record.date);
                  final nextDueStr = record.nextDueDate != null ? DateFormat('yyyy-MM-dd').format(record.nextDueDate!) : 'None';
                  
                  return Card(
                    margin: const EdgeInsets.only(bottom: 12.0),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.1),
                        child: Icon(
                          record.recordType == 'Vaccine' ? Icons.vaccines : 
                          record.recordType == 'Vet Visit' ? Icons.local_hospital :
                          record.recordType == 'Deworming' ? Icons.medication : Icons.favorite,
                          color: AppTheme.primaryColor,
                        ),
                      ),
                      title: Text('${record.recordType} - $dateStr'),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (record.notes != null && record.notes!.isNotEmpty)
                            Text(record.notes!),
                          const SizedBox(height: 4),
                          Text('Next Due: $nextDueStr', style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                        ],
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete_outline, color: Colors.red),
                        onPressed: () => _deleteHealthRecord(record.id, dog.id),
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Future<void> _deleteHealthRecord(int recordId, int dogId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Record'),
        content: const Text('Are you sure you want to delete this health record?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final db = ref.read(databaseProvider);
      await db.deleteHealthRecord(recordId);
      ref.invalidate(healthRecordsProvider(dogId));
    }
  }

  Widget _buildShowTab(BuildContext context, Dog dog) {
    final showAsync = ref.watch(showRecordsProvider(dog.id));
    
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Show & Title History', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ElevatedButton.icon(
                onPressed: () => context.push('/dog/${dog.id}/show/new'),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Add Show'),
              ),
            ],
          ),
        ),
        Expanded(
          child: showAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Error: $e'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => ref.invalidate(showRecordsProvider(dog.id)),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
            data: (records) {
              if (records.isEmpty) {
                return const Center(
                  child: Text('No show records found.', style: TextStyle(color: Colors.grey)),
                );
              }
              return ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                itemCount: records.length,
                itemBuilder: (context, index) {
                  final record = records[index];
                  final dateStr = DateFormat('yyyy-MM-dd').format(record.date);
                  
                  return Card(
                    margin: const EdgeInsets.only(bottom: 12.0),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Colors.amber.withValues(alpha: 0.2),
                        child: const Icon(Icons.emoji_events, color: Colors.amber),
                      ),
                      title: Text(record.eventName, style: const TextStyle(fontWeight: FontWeight.w600)),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 4),
                          Text('Date: $dateStr'),
                          if (record.judge != null && record.judge!.isNotEmpty) Text('Judge: ${record.judge}'),
                          if (record.placement != null && record.placement!.isNotEmpty) 
                            Text('Placement: ${record.placement}', style: const TextStyle(fontWeight: FontWeight.w500, color: AppTheme.secondaryColor)),
                          if (record.titleAwarded != null && record.titleAwarded!.isNotEmpty) 
                            Text('Title: ${record.titleAwarded}', style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryColor)),
                          if (record.notes != null && record.notes!.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text('Notes: ${record.notes}', style: const TextStyle(fontStyle: FontStyle.italic)),
                          ],
                        ],
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete_outline, color: Colors.red),
                        onPressed: () => _deleteShowRecord(record.id, dog.id),
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Future<void> _deleteShowRecord(int recordId, int dogId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Record'),
        content: const Text('Are you sure you want to delete this show record?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final db = ref.read(databaseProvider);
      await db.deleteShowRecord(recordId);
      ref.invalidate(showRecordsProvider(dogId));
    }
  }
}

class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  _SliverAppBarDelegate(this._tabBar);

  final TabBar _tabBar;

  @override
  double get minExtent => _tabBar.preferredSize.height;
  @override
  double get maxExtent => _tabBar.preferredSize.height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: Colors.white,
      child: _tabBar,
    );
  }

  @override
  bool shouldRebuild(_SliverAppBarDelegate oldDelegate) {
    return false;
  }
}
