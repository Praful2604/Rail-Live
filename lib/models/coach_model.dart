class CoachModel {
  final String coachName;
  final String coachType;
  final int seatCapacity;

  const CoachModel({
    required this.coachName,
    required this.coachType,
    required this.seatCapacity,
  });

  factory CoachModel.fromJson(Map<String, dynamic> json) {
    return CoachModel(
      coachName: json['coachName']?.toString() ?? '',
      coachType: json['coachType']?.toString() ?? '',
      seatCapacity: json['seatCapacity'] is int
          ? json['seatCapacity'] as int
          : int.tryParse(json['seatCapacity']?.toString() ?? '') ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
        'coachName': coachName,
        'coachType': coachType,
        'seatCapacity': seatCapacity,
      };
}

List<Map<String, dynamic>> fallbackCoachComposition() {
  return const [
    CoachModel(coachName: 'ENG', coachType: 'ENG', seatCapacity: 0),
    CoachModel(coachName: 'H1', coachType: 'EOG', seatCapacity: 0),
    CoachModel(coachName: 'A1', coachType: '1A', seatCapacity: 18),
    CoachModel(coachName: 'B1', coachType: '2A', seatCapacity: 46),
    CoachModel(coachName: 'B2', coachType: '2A', seatCapacity: 46),
    CoachModel(coachName: 'B3', coachType: '2A', seatCapacity: 46),
    CoachModel(coachName: 'C1', coachType: '3A', seatCapacity: 64),
    CoachModel(coachName: 'C2', coachType: '3A', seatCapacity: 64),
    CoachModel(coachName: 'C3', coachType: '3A', seatCapacity: 64),
    CoachModel(coachName: 'C4', coachType: '3A', seatCapacity: 64),
    CoachModel(coachName: 'S1', coachType: 'SL', seatCapacity: 72),
    CoachModel(coachName: 'S2', coachType: 'SL', seatCapacity: 72),
    CoachModel(coachName: 'GS', coachType: 'GEN', seatCapacity: 0),
    CoachModel(coachName: 'EOG', coachType: 'EOG', seatCapacity: 0),
  ].map((c) => c.toJson()).toList();
}
