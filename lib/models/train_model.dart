class TrainModel {
  final String trainNumber;
  final String trainName;

  TrainModel({
    required this.trainNumber,
    required this.trainName,
  });

  factory TrainModel.fromJson(Map<String, dynamic> json) {
    return TrainModel(
      trainNumber: json['train_number'].toString(),
      trainName: json['train_name'].toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'train_number': trainNumber,
      'train_name': trainName,
    };
  }
}