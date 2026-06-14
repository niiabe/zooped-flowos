class Litter {
  final int id;
  final int sireId;
  final int damId;
  final DateTime? matingDate;
  final DateTime whelpingDate;
  final int puppiesBornAlive;
  final int puppiesStillborn;
  final String? notes;

  const Litter({
    required this.id,
    required this.sireId,
    required this.damId,
    this.matingDate,
    required this.whelpingDate,
    this.puppiesBornAlive = 0,
    this.puppiesStillborn = 0,
    this.notes,
  });

  int get totalPuppiesBorn => puppiesBornAlive + puppiesStillborn;
}
