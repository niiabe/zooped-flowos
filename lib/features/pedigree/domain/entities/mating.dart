class Mating {
  final int id;
  final int sireId;
  final int damId;
  final DateTime matingDate;
  final String? notes;

  const Mating({
    required this.id,
    required this.sireId,
    required this.damId,
    required this.matingDate,
    this.notes,
  });
}
