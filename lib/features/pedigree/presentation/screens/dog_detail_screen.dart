import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:sqlite3/sqlite3.dart' show SqliteException;
import 'package:intl/intl.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/responsive.dart';
import '../../../../core/widgets/delete_confirm_dialog.dart';
import '../../domain/entities/dog.dart';
import '../providers/pedigree_providers.dart';
import '../widgets/pedigree_canvas.dart';
import 'dog_detail/health_tab.dart';
import 'dog_detail/shows_tab.dart';
import 'dog_detail/offspring_tab.dart';
import 'dog_detail/photo_gallery.dart';
import 'dog_detail/certificate_actions.dart';
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

  @override
  void initState() {
    super.initState();
    _loadDog();
  }

  void _loadDog() {
    ref.read(_dogProvider(widget.dogId)).whenData((dog) {
      if (mounted) setState(() => _dog = dog);
    });
  }

  @override
  Widget build(BuildContext context) {
    final dogAsync = ref.watch(_dogProvider(widget.dogId));
    final padding = Responsive.padding(context);
    final isTablet = Responsive.isTablet(context);

    ref.listen<AsyncValue<Dog>>(_dogProvider(widget.dogId), (prev, next) {
      next.whenData((dog) {
        if (mounted) setState(() => _dog = dog);
      });
    });

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('Dog Profile', style: TextStyle(fontWeight: FontWeight.w600)),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: AppTheme.secondaryColor,
        actions: [
          IconButton(
            icon: const Icon(Icons.qr_code),
            tooltip: 'Generate QR Code',
            onPressed: _dog != null ? () => _showQrCode(context) : null,
          ),
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
          const tabBar = TabBar(
            isScrollable: true,
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
                      const SnackBar(
                          content: Text(
                              'Please add the missing parent first before adding grandparents.')),
                    );
                    return;
                  }

                  final confirmed = await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: Text('Add $roleName'),
                      content: Text(
                          'Would you like to add a new dog as the $roleName for ${childDog.callName}?'),
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
              HealthTab(dog: dog),
              ShowsTab(dog: dog),
              OffspringTab(dog: dog),
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

  void _showQrCode(BuildContext context) {
    final dog = _dog;
    if (dog == null) return;

    final qrData =
        'ZOOPED:${dog.id}|${dog.registeredName}|${dog.callName}|${dog.breed ?? "Unknown"}|${dog.sex}|${dog.microchipNumber ?? "N/A"}';

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Dog QR Code'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            QrImageView(
              data: qrData,
              version: QrVersions.auto,
              size: 200.0,
              backgroundColor: Colors.white,
            ),
            const SizedBox(height: 16),
            Text(
              dog.registeredName,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              '${dog.breed ?? "Unknown"} • ${dog.sex}',
              style: TextStyle(color: Colors.grey.shade600),
              textAlign: TextAlign.center,
            ),
            if (dog.microchipNumber != null) ...[
              const SizedBox(height: 4),
              Text(
                'Microchip: ${dog.microchipNumber}',
                style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final dog = _dog;
    if (dog == null) return;

    final confirmed = await showDeleteConfirmDialog(
      context,
      title: 'Delete Dog',
      message:
          'Are you sure you want to delete ${dog.callName}? This will remove all records related to this dog, including pedigree links and associated litters.',
    );

    if (confirmed && context.mounted) {
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
                    backgroundImage:
                        ResizeImage(FileImage(File(dog.photoPath!)), width: 150),
                    onBackgroundImageError: (e, s) => {},
                  ),
                ),
            ],
          ),
        ),

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
                  errorBuilder: (context, error, stackTrace) =>
                      const SizedBox.shrink(),
                ),
              ),
            ),
          ),

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
                _buildDetailChip(Icons.cake, 'DOB',
                    DateFormat('yyyy-MM-dd').format(dog.dateOfBirth!)),
              if (dog.colorMarkings != null && dog.colorMarkings!.isNotEmpty)
                _buildDetailChip(Icons.palette, 'Color', dog.colorMarkings!),
              if (dog.registerType != null && dog.registerType!.isNotEmpty)
                _buildDetailChip(Icons.badge, 'Reg', dog.registerType!),
              if (dog.appraisalScore != null)
                _buildAppraisalBadge(dog.appraisalScore!),
              if (dog.inbreedingCoefficient != null)
                _buildDetailChip(
                    Icons.science, 'COI', '${dog.inbreedingCoefficient}%'),
            ],
          ),
        ),

        SafeArea(
          top: false,
          child: Padding(
            padding: EdgeInsets.all(padding),
            child: CertificateActions(
              dog: dog,
              generatingPdf: _generatingPdf,
              onGeneratingChanged: (value) {
                if (mounted) setState(() => _generatingPdf = value);
              },
              exportKey: _pedigreeExportKey,
            ),
          ),
        ),

        PhotoGallery(dog: dog),
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
          colors: [
            badgeColor.withValues(alpha: 0.1),
            badgeColor.withValues(alpha: 0.2)
          ],
        ),
        borderRadius: BorderRadius.circular(10.0),
        border: Border.all(
            color: badgeColor.withValues(alpha: 0.3), width: 1.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16.0, color: badgeColor),
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
    );
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
