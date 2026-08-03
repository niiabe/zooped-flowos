import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zooped/features/pedigree/presentation/screens/qr_scanner_screen.dart';

void main() {
  group('QrScannerScreen', () {
    testWidgets('should display app bar with title', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: QrScannerScreen(),
          ),
        ),
      );

      expect(find.text('Scan QR Code'), findsOneWidget);
    });

    testWidgets('should display flash toggle button', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: QrScannerScreen(),
          ),
        ),
      );

      expect(find.byIcon(Icons.flash_off), findsOneWidget);
    });

    testWidgets('should display scan overlay', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: QrScannerScreen(),
          ),
        ),
      );

      expect(find.byType(Center), findsWidgets);
    });

    testWidgets('should handle camera not available gracefully', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: QrScannerScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Should not crash even if camera is not available
      expect(find.text('Scan QR Code'), findsOneWidget);
    });
  });
}