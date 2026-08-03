import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/entities/dog.dart';
import '../providers/pedigree_providers.dart';

class QrScannerScreen extends ConsumerStatefulWidget {
  const QrScannerScreen({super.key});

  @override
  ConsumerState<QrScannerScreen> createState() => _QrScannerScreenState();
}

class _QrScannerScreenState extends ConsumerState<QrScannerScreen> {
  MobileScannerController? _scannerController;
  bool _isProcessing = false;
  bool _hasScanned = false;

  @override
  void initState() {
    super.initState();
    try {
      _scannerController = MobileScannerController(
        detectionSpeed: DetectionSpeed.normal,
        facing: CameraFacing.back,
      );
    } catch (e) {
      debugPrint('Failed to initialize camera: $e');
    }
  }

  @override
  void dispose() {
    _scannerController?.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (_isProcessing || _hasScanned) return;

    for (final barcode in capture.barcodes) {
      if (barcode.rawValue != null) {
        _processScannedData(barcode.rawValue!);
        break;
      }
    }
  }

  void _processScannedData(String data) {
    if (!mounted) return;

    _isProcessing = true;
    _hasScanned = true;

    if (data.startsWith('zooped://dog/')) {
      _handleDeepLink(data);
    } else if (data.startsWith('{')) {
      _handleQrData(data);
    } else {
      _showError('Invalid QR code. Please scan a ZooPed QR code.');
    }
  }

  void _handleDeepLink(String url) {
    try {
      final uri = Uri.parse(url);
      final pathSegments = uri.pathSegments;

      if (pathSegments.isNotEmpty) {
        final dogId = int.tryParse(pathSegments.first);
        if (dogId != null && mounted) {
          context.pushReplacement('/dog/$dogId');
          return;
        }
      }
      _showError('Invalid dog link in QR code.');
    } catch (e) {
      _showError('Failed to parse deep link: $e');
    }
  }

  void _handleQrData(String data) {
    try {
      final jsonData = jsonDecode(data) as Map<String, dynamic>;

      if (jsonData['type'] != 'ZOOPED') {
        _showError('Invalid QR code format.');
        return;
      }

      final dogData = {
        'registeredName': jsonData['registeredName'] as String?,
        'callName': jsonData['callName'] as String?,
        'breed': jsonData['breed'] as String?,
        'sex': jsonData['sex'] as String?,
        'microchipNumber': jsonData['microchipNumber'] as String?,
        'colorMarkings': jsonData['colorMarkings'] as String?,
        'dateOfBirth': jsonData['dateOfBirth'] as String?,
        'registerType': jsonData['registerType'] as String?,
        'notes': jsonData['notes'] as String?,
      };

      _showImportDialog(dogData);
    } catch (e) {
      _showError('Failed to parse QR code data: $e');
    }
  }

  void _showImportDialog(Map<String, dynamic> dogData) {
    if (!mounted) return;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Import Dog'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Would you like to import this dog into your kennel?',
                style: TextStyle(color: Colors.grey.shade600),
              ),
              const SizedBox(height: 16),
              _buildDataRow('Name', dogData['registeredName'] ?? 'N/A'),
              _buildDataRow('Call Name', dogData['callName'] ?? 'N/A'),
              _buildDataRow('Breed', dogData['breed'] ?? 'Unknown'),
              _buildDataRow('Sex', dogData['sex'] ?? 'N/A'),
              if (dogData['microchipNumber'] != null)
                _buildDataRow('Microchip', dogData['microchipNumber']),
              if (dogData['colorMarkings'] != null)
                _buildDataRow('Color', dogData['colorMarkings']),
              if (dogData['dateOfBirth'] != null)
                _buildDataRow('DOB', dogData['dateOfBirth']),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _resetScanner();
            },
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              _importDog(dogData);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
            ),
            child: const Text('Import'),
          ),
        ],
      ),
    );
  }

  Widget _buildDataRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade700,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _importDog(Map<String, dynamic> dogData) async {
    try {
      DateTime? dob;
      if (dogData['dateOfBirth'] != null && dogData['dateOfBirth'] != 'null') {
        dob = DateTime.tryParse(dogData['dateOfBirth']);
      }

      final dog = Dog(
        id: 0,
        registeredName: dogData['registeredName'] ?? '',
        callName: dogData['callName'] ?? '',
        breed: dogData['breed'],
        sex: dogData['sex'] ?? 'Male',
        dateOfBirth: dob,
        microchipNumber: dogData['microchipNumber'],
        colorMarkings: dogData['colorMarkings'],
        saleStatus: 'Owned',
        createdAt: DateTime.now(),
      );

      final repo = ref.read(pedigreeRepositoryProvider);
      final newId = await repo.insertDog(dog);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${dog.callName} imported successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        context.pushReplacement('/dog/$newId');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to import dog: $e'),
            backgroundColor: Colors.red,
          ),
        );
        _resetScanner();
      }
    }
  }

  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
        ),
      );
      _resetScanner();
    }
  }

  void _resetScanner() {
    if (mounted) {
      setState(() {
        _isProcessing = false;
        _hasScanned = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_scannerController == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Scan QR Code'),
          backgroundColor: Colors.black,
          foregroundColor: Colors.white,
        ),
        body: const Center(
          child: Text('Camera not available'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan QR Code'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.flash_off),
            onPressed: () => _scannerController?.toggleTorch(),
          ),
        ],
      ),
      body: Stack(
        children: [
          MobileScanner(
            controller: _scannerController,
            onDetect: _onDetect,
          ),
          _buildScanOverlay(),
        ],
      ),
    );
  }

  Widget _buildScanOverlay() {
    return Center(
      child: Container(
        width: 250,
        height: 250,
        decoration: BoxDecoration(
          border: Border.all(
            color: AppTheme.primaryColor,
            width: 3,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Stack(
          children: [
            Positioned(
              top: -1,
              left: -1,
              child: Container(
                width: 30,
                height: 30,
                decoration: const BoxDecoration(
                  border: Border(
                    top: BorderSide(color: AppTheme.primaryColor, width: 4),
                    left: BorderSide(color: AppTheme.primaryColor, width: 4),
                  ),
                ),
              ),
            ),
            Positioned(
              top: -1,
              right: -1,
              child: Container(
                width: 30,
                height: 30,
                decoration: const BoxDecoration(
                  border: Border(
                    top: BorderSide(color: AppTheme.primaryColor, width: 4),
                    right: BorderSide(color: AppTheme.primaryColor, width: 4),
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: -1,
              left: -1,
              child: Container(
                width: 30,
                height: 30,
                decoration: const BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: AppTheme.primaryColor, width: 4),
                    left: BorderSide(color: AppTheme.primaryColor, width: 4),
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: -1,
              right: -1,
              child: Container(
                width: 30,
                height: 30,
                decoration: const BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: AppTheme.primaryColor, width: 4),
                    right: BorderSide(color: AppTheme.primaryColor, width: 4),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}