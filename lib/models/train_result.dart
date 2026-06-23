class TrainResult {
  final String trainNumber;
  final String trainName;
  final String fromStation;   // display name of selected source
  final String toStation;     // display name of selected destination
  final int fromIndex;        // index of source in the stops list
  final int toIndex;          // index of destination in the stops list
  final int stopsBetween;     // number of intermediate stops
  final List<String> runningDays;
  final List<String> allStops; // full stop list (station names, in order)

  const TrainResult({
    required this.trainNumber,
    required this.trainName,
    required this.fromStation,
    required this.toStation,
    required this.fromIndex,
    required this.toIndex,
    required this.stopsBetween,
    required this.runningDays,
    required this.allStops,
  });
}
