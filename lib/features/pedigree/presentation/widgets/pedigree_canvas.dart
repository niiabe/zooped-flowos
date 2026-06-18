import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/responsive.dart';
import '../../domain/entities/dog.dart';
import 'pedigree_card_node.dart';

class PedigreeCanvas extends StatelessWidget {
  final Dog rootDog;
  final Function(Dog) onDogTap;
  final Function(Dog? childDog, bool isSire, String roleName)? onUnknownTap;

  const PedigreeCanvas({
    super.key,
    required this.rootDog,
    required this.onDogTap,
    this.onUnknownTap,
  });

  @override
  Widget build(BuildContext context) {
    final bool isMobile = Responsive.isMobile(context);
    final bool isTablet = Responsive.isTablet(context);
    final double spacing = isMobile ? 12.0 : (isTablet ? 20.0 : 30.0);
    final double nodeH = isMobile ? 80.0 : (isTablet ? 90.0 : 100.0);
    final double cardW = isMobile ? 150.0 : (isTablet ? 170.0 : 200.0);
    final double gen4Gap = isMobile ? 6.0 : (isTablet ? 8.0 : 10.0);

    final double colH = nodeH * 8 + gen4Gap * 7;

    // Great-grandparent centers (8 nodes, spaceBetween)
    final List<double> ggCenters = List.generate(8, (i) =>
      i * (colH - nodeH) / 7 + nodeH / 2);

    // Grandparent centers - each centered between their 2 children in gen4
    final double g1Center = (ggCenters[0] + ggCenters[1]) / 2;
    final double g2Center = (ggCenters[2] + ggCenters[3]) / 2;
    final double g3Center = (ggCenters[4] + ggCenters[5]) / 2;
    final double g4Center = (ggCenters[6] + ggCenters[7]) / 2;
    final List<double> grandCenters = [g1Center, g2Center, g3Center, g4Center];

    // Parent centers - each centered between their 2 children in gen3
    final double sireCenter = (g1Center + g2Center) / 2;
    final double damCenter = (g3Center + g4Center) / 2;

    // Root center - centered between sire and dam
    final double rootCenter = colH / 2;

    return InteractiveViewer(
      constrained: false,
      boundaryMargin: const EdgeInsets.all(80.0),
      minScale: 0.2,
      maxScale: 3.0,
      clipBehavior: Clip.hardEdge,
      child: Padding(
        padding: EdgeInsets.all(spacing),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Gen1: Root
            SizedBox(
              height: colH,
              child: Center(
                child: PedigreeCardNode(
                  roleName: 'Target',
                  isMale: rootDog.sex == 'Male',
                  callName: rootDog.callName,
                  registeredName: rootDog.registeredName,
                  microchip: rootDog.microchipNumber,
                  registerType: rootDog.registerType,
                  onTap: () => onDogTap(rootDog),
                ),
              ),
            ),
            SizedBox(width: spacing),
            // Connector 1: Root → Sire & Dam
            _buildConnector(spacing, colH, ConnectorType.oneToTwo,
              leftY1: rootCenter,
              rightY1: sireCenter,
              rightY2: damCenter,
            ),
            SizedBox(width: spacing),
            // Gen2: Parents
            SizedBox(
              width: cardW,
              height: colH,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  _positionedNode(sireCenter - nodeH / 2, 'Sire', true, rootDog.sire, rootDog, true),
                  _positionedNode(damCenter - nodeH / 2, 'Dam', false, rootDog.dam, rootDog, false),
                ],
              ),
            ),
            SizedBox(width: spacing),
            // Connector 2: Sire & Dam → 4 Grandparents
            _buildConnector(spacing, colH, ConnectorType.twoToFour,
              leftY1: sireCenter,
              leftY2: damCenter,
              rightY1: grandCenters[0],
              rightY2: grandCenters[1],
              rightY3: grandCenters[2],
              rightY4: grandCenters[3],
            ),
            SizedBox(width: spacing),
            // Gen3: Grandparents
            SizedBox(
              width: cardW,
              height: colH,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  _positionedNode(grandCenters[0] - nodeH / 2, 'Grandparent', true, rootDog.sire?.sire, rootDog.sire, true),
                  _positionedNode(grandCenters[1] - nodeH / 2, 'Grandparent', false, rootDog.sire?.dam, rootDog.sire, false),
                  _positionedNode(grandCenters[2] - nodeH / 2, 'Grandparent', true, rootDog.dam?.sire, rootDog.dam, true),
                  _positionedNode(grandCenters[3] - nodeH / 2, 'Grandparent', false, rootDog.dam?.dam, rootDog.dam, false),
                ],
              ),
            ),
            SizedBox(width: spacing),
            // Connector 3: 4 Grandparents → 8 Great-grandparents
            _buildConnector(spacing, colH, ConnectorType.fourToEight,
              leftY1: grandCenters[0],
              leftY2: grandCenters[1],
              leftY3: grandCenters[2],
              leftY4: grandCenters[3],
              rightY1: ggCenters[0],
              rightY2: ggCenters[1],
              rightY3: ggCenters[2],
              rightY4: ggCenters[3],
              rightY5: ggCenters[4],
              rightY6: ggCenters[5],
              rightY7: ggCenters[6],
              rightY8: ggCenters[7],
            ),
            SizedBox(width: spacing),
            // Gen4: Great-grandparents
            SizedBox(
              width: cardW,
              height: colH,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _grandNode(rootDog.sire?.sire?.sire, rootDog.sire?.sire, true),
                  _grandNode(rootDog.sire?.sire?.dam, rootDog.sire?.sire, false),
                  _grandNode(rootDog.sire?.dam?.sire, rootDog.sire?.dam, true),
                  _grandNode(rootDog.sire?.dam?.dam, rootDog.sire?.dam, false),
                  _grandNode(rootDog.dam?.sire?.sire, rootDog.dam?.sire, true),
                  _grandNode(rootDog.dam?.sire?.dam, rootDog.dam?.sire, false),
                  _grandNode(rootDog.dam?.dam?.sire, rootDog.dam?.dam, true),
                  _grandNode(rootDog.dam?.dam?.dam, rootDog.dam?.dam, false),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _positionedNode(double top, String role, bool isMale,
      Dog? dog, Dog? childDog, bool isSire) {
    return Positioned(
      top: top,
      child: PedigreeCardNode(
        roleName: role,
        isMale: isMale,
        callName: dog?.callName,
        registeredName: dog?.registeredName,
        microchip: dog?.microchipNumber,
        registerType: dog?.registerType,
        onTap: () {
          if (dog != null) {
            onDogTap(dog);
          } else if (onUnknownTap != null) {
            onUnknownTap!(childDog, isSire, role);
          }
        },
      ),
    );
  }

  Widget _grandNode(Dog? dog, Dog? childDog, bool isSire) {
    if (dog != null) {
      return PedigreeCardNode(
        roleName: 'Great Grandparent',
        isMale: dog.sex == 'Male',
        callName: dog.callName,
        registeredName: dog.registeredName,
        microchip: dog.microchipNumber,
        registerType: dog.registerType,
        onTap: () => onDogTap(dog),
      );
    }
    return PedigreeCardNode(
      roleName: 'Great Grandparent',
      isMale: isSire,
      onTap: () {
        if (onUnknownTap != null) {
          onUnknownTap!(childDog, isSire, 'Great Grandparent');
        }
      },
    );
  }

  Widget _buildConnector(double spacing, double height, ConnectorType type,
      {double? leftY1, double? leftY2, double? leftY3, double? leftY4,
       double? rightY1, double? rightY2, double? rightY3, double? rightY4,
       double? rightY5, double? rightY6, double? rightY7, double? rightY8}) {
    return SizedBox(
      width: spacing * 0.6,
      height: height,
      child: CustomPaint(
        painter: BezierConnectorPainter(
          type: type,
          color: AppTheme.primaryColor.withValues(alpha: 0.3),
          leftY1: leftY1,
          leftY2: leftY2,
          leftY3: leftY3,
          leftY4: leftY4,
          rightY1: rightY1,
          rightY2: rightY2,
          rightY3: rightY3,
          rightY4: rightY4,
          rightY5: rightY5,
          rightY6: rightY6,
          rightY7: rightY7,
          rightY8: rightY8,
        ),
      ),
    );
  }
}

enum ConnectorType { oneToTwo, twoToFour, fourToEight }

class BezierConnectorPainter extends CustomPainter {
  final Color color;
  final ConnectorType type;
  final double? leftY1;
  final double? leftY2;
  final double? leftY3;
  final double? leftY4;
  final double? rightY1;
  final double? rightY2;
  final double? rightY3;
  final double? rightY4;
  final double? rightY5;
  final double? rightY6;
  final double? rightY7;
  final double? rightY8;

  BezierConnectorPainter({
    required this.color,
    required this.type,
    this.leftY1,
    this.leftY2,
    this.leftY3,
    this.leftY4,
    this.rightY1,
    this.rightY2,
    this.rightY3,
    this.rightY4,
    this.rightY5,
    this.rightY6,
    this.rightY7,
    this.rightY8,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    switch (type) {
      case ConnectorType.oneToTwo:
        _drawOneToTwo(canvas, size, paint);
      case ConnectorType.twoToFour:
        _drawTwoToFour(canvas, size, paint);
      case ConnectorType.fourToEight:
        _drawFourToEight(canvas, size, paint);
    }
  }

  void _drawCurve(Path path, double w, double y1, double y2) {
    path.moveTo(0, y1);
    path.cubicTo(
      w * 0.6, y1,
      w * 0.4, y2,
      w, y2,
    );
  }

  void _drawOneToTwo(Canvas canvas, Size size, Paint paint) {
    final path = Path();
    final lY = leftY1 ?? size.height / 2;
    final rY1 = rightY1 ?? 0;
    final rY2 = rightY2 ?? size.height;

    _drawCurve(path, size.width, lY, rY1);
    _drawCurve(path, size.width, lY, rY2);
    canvas.drawPath(path, paint);
  }

  void _drawTwoToFour(Canvas canvas, Size size, Paint paint) {
    final path = Path();
    final lY1 = leftY1 ?? size.height / 4;
    final lY2 = leftY2 ?? size.height * 3 / 4;
    final rY1 = rightY1 ?? size.height / 8;
    final rY2 = rightY2 ?? size.height * 3 / 8;
    final rY3 = rightY3 ?? size.height * 5 / 8;
    final rY4 = rightY4 ?? size.height * 7 / 8;

    _drawCurve(path, size.width, lY1, rY1);
    _drawCurve(path, size.width, lY1, rY2);
    _drawCurve(path, size.width, lY2, rY3);
    _drawCurve(path, size.width, lY2, rY4);
    canvas.drawPath(path, paint);
  }

  void _drawFourToEight(Canvas canvas, Size size, Paint paint) {
    final path = Path();
    final lY1 = leftY1 ?? size.height / 8;
    final lY2 = leftY2 ?? size.height * 3 / 8;
    final lY3 = leftY3 ?? size.height * 5 / 8;
    final lY4 = leftY4 ?? size.height * 7 / 8;
    final rY1 = rightY1 ?? size.height / 16;
    final rY2 = rightY2 ?? size.height * 3 / 16;
    final rY3 = rightY3 ?? size.height * 5 / 16;
    final rY4 = rightY4 ?? size.height * 7 / 16;
    final rY5 = rightY5 ?? size.height * 9 / 16;
    final rY6 = rightY6 ?? size.height * 11 / 16;
    final rY7 = rightY7 ?? size.height * 13 / 16;
    final rY8 = rightY8 ?? size.height * 15 / 16;

    _drawCurve(path, size.width, lY1, rY1);
    _drawCurve(path, size.width, lY1, rY2);
    _drawCurve(path, size.width, lY2, rY3);
    _drawCurve(path, size.width, lY2, rY4);
    _drawCurve(path, size.width, lY3, rY5);
    _drawCurve(path, size.width, lY3, rY6);
    _drawCurve(path, size.width, lY4, rY7);
    _drawCurve(path, size.width, lY4, rY8);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant BezierConnectorPainter oldDelegate) =>
      oldDelegate.color != color ||
      oldDelegate.type != type ||
      oldDelegate.leftY1 != leftY1 ||
      oldDelegate.leftY2 != leftY2 ||
      oldDelegate.leftY3 != leftY3 ||
      oldDelegate.leftY4 != leftY4 ||
      oldDelegate.rightY1 != rightY1 ||
      oldDelegate.rightY2 != rightY2 ||
      oldDelegate.rightY3 != rightY3 ||
      oldDelegate.rightY4 != rightY4 ||
      oldDelegate.rightY5 != rightY5 ||
      oldDelegate.rightY6 != rightY6 ||
      oldDelegate.rightY7 != rightY7 ||
      oldDelegate.rightY8 != rightY8;
}
