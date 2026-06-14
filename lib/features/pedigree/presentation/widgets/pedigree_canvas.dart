import 'package:flutter/material.dart';
import '../../../../core/utils/responsive.dart';
import '../../domain/entities/dog.dart';
import 'pedigree_card_node.dart';

class PedigreeCanvas extends StatelessWidget {
  final Dog rootDog;
  final Function(Dog) onDogTap;

  const PedigreeCanvas({
    super.key,
    required this.rootDog,
    required this.onDogTap,
  });

  @override
  Widget build(BuildContext context) {
    final bool isMobile = Responsive.isMobile(context);
    final bool isTablet = Responsive.isTablet(context);
    final double spacing = isMobile ? 8.0 : (isTablet ? 14.0 : 20.0);

    return InteractiveViewer(
      boundaryMargin: const EdgeInsets.all(50.0),
      minScale: 0.3,
      maxScale: 2.5,
      child: Padding(
        padding: EdgeInsets.all(spacing),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Generation 1: Root Dog
            _buildGeneration1(context),
            SizedBox(width: spacing),
            // Connector lines
            _buildConnectorLines(context, 1),
            SizedBox(width: spacing),
            // Generation 2: Parents
            _buildGeneration2(context),
            SizedBox(width: spacing),
            // Connector lines
            _buildConnectorLines(context, 2),
            SizedBox(width: spacing),
            // Generation 3: Grandparents
            _buildGeneration3(context),
          ],
        ),
      ),
    );
  }

  Widget _buildGeneration1(BuildContext context) {
    final bool isMobile = Responsive.isMobile(context);

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        PedigreeCardNode(
          roleName: 'Target',
          isMale: rootDog.sex == 'Male',
          callName: rootDog.callName,
          registeredName: rootDog.registeredName,
          microchip: rootDog.microchipNumber,
          registerType: rootDog.registerType,
          onTap: () => onDogTap(rootDog),
        ),
        if (!isMobile) ...[
          const SizedBox(height: 8.0),
          Text(
            rootDog.callName,
            style: TextStyle(
              fontSize: 10.0,
              color: Colors.grey.shade600,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ],
    );
  }

  Widget _buildGeneration2(BuildContext context) {
    final bool isMobile = Responsive.isMobile(context);
    final double gap = isMobile ? 40.0 : 64.0;

    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        // Sire
        PedigreeCardNode(
          roleName: 'Sire',
          isMale: true,
          callName: rootDog.sire?.callName,
          registeredName: rootDog.sire?.registeredName,
          microchip: rootDog.sire?.microchipNumber,
          registerType: rootDog.sire?.registerType,
          onTap: rootDog.sire != null ? () => onDogTap(rootDog.sire!) : () {},
        ),
        SizedBox(height: gap),
        // Dam
        PedigreeCardNode(
          roleName: 'Dam',
          isMale: false,
          callName: rootDog.dam?.callName,
          registeredName: rootDog.dam?.registeredName,
          microchip: rootDog.dam?.microchipNumber,
          registerType: rootDog.dam?.registerType,
          onTap: rootDog.dam != null ? () => onDogTap(rootDog.dam!) : () {},
        ),
      ],
    );
  }

  Widget _buildGeneration3(BuildContext context) {
    final bool isMobile = Responsive.isMobile(context);
    final double gap = isMobile ? 8.0 : 12.0;

    // Grandparents: Sire's parents, then Dam's parents
    final grandparents = [
      rootDog.sire?.sire, // Sire's Sire
      rootDog.sire?.dam,  // Sire's Dam
      rootDog.dam?.sire,  // Dam's Sire
      rootDog.dam?.dam,   // Dam's Dam
    ];

    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: grandparents.map((dog) {
        return Padding(
          padding: EdgeInsets.symmetric(vertical: gap * 0.5),
          child: PedigreeCardNode(
            roleName: 'Grandparent',
            isMale: dog?.sex == 'Male',
            callName: dog?.callName,
            registeredName: dog?.registeredName,
            microchip: dog?.microchipNumber,
            registerType: dog?.registerType,
            onTap: dog != null ? () => onDogTap(dog) : () {},
          ),
        );
      }).toList(),
    );
  }

  Widget _buildConnectorLines(BuildContext context, int generation) {
    final bool isMobile = Responsive.isMobile(context);
    final double width = isMobile ? 10.0 : 20.0;
    final double height;

    if (generation == 1) {
      height = isMobile ? 70.0 : 86.0;
    } else if (generation == 2) {
      height = isMobile ? 160.0 : 200.0;
    } else {
      height = isMobile ? 280.0 : 350.0;
    }

    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        border: Border.all(
          color: Colors.grey.shade300,
          width: 1.0,
        ),
      ),
    );
  }
}
