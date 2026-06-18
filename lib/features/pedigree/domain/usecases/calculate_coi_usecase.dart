import 'dart:math';
import '../entities/dog.dart';

class CalculateCoiUseCase {
  double call(Dog sire, Dog dam) {
    final Map<int, int> sireAncestors = {};
    final Map<int, int> damAncestors = {};

    void traverse(Dog dog, int depth, Map<int, int> map) {
      if (depth > 5) return;
      if (map.containsKey(dog.id)) {
        if (depth < map[dog.id]!) {
          map[dog.id] = depth;
        }
      } else {
        map[dog.id] = depth;
      }
      if (dog.sire != null) traverse(dog.sire!, depth + 1, map);
      if (dog.dam != null) traverse(dog.dam!, depth + 1, map);
    }

    if (sire.sire != null) traverse(sire.sire!, 1, sireAncestors);
    if (sire.dam != null) traverse(sire.dam!, 1, sireAncestors);
    
    if (dam.sire != null) traverse(dam.sire!, 1, damAncestors);
    if (dam.dam != null) traverse(dam.dam!, 1, damAncestors);

    double coi = 0.0;
    
    sireAncestors.forEach((id, sireDepth) {
      if (damAncestors.containsKey(id)) {
        final int damDepth = damAncestors[id]!;
        final int n = sireDepth + damDepth + 1;
        coi += 0.5 * pow(0.5, n - 1);
      }
    });

    return coi * 100.0;
  }
}
