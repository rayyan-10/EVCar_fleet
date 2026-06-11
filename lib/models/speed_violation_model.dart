class SpeedViolationModel {
  final String? id;
  final String driverId;
  final String driverIdStr;
  final String carName;
  final double speedKmph;
  final double limitKmph;
  final double excessKmph;
  final String? predictionId;
  final DateTime violatedAt;

  SpeedViolationModel({
    this.id,
    required this.driverId,
    required this.driverIdStr,
    required this.carName,
    required this.speedKmph,
    this.limitKmph = 100,
    required this.excessKmph,
    this.predictionId,
    required this.violatedAt,
  });

  factory SpeedViolationModel.fromJson(Map<String, dynamic> json) {
    return SpeedViolationModel(
      id:           json['id'] as String?,
      driverId:     json['driver_id'] as String,
      driverIdStr:  json['driver_id_str'] as String,
      carName:      json['car_name'] as String,
      speedKmph:    (json['speed_kmph'] as num).toDouble(),
      limitKmph:    (json['limit_kmph'] as num? ?? 100).toDouble(),
      excessKmph:   (json['excess_kmph'] as num).toDouble(),
      predictionId: json['prediction_id'] as String?,
      violatedAt:   DateTime.parse(json['violated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
    if (id != null) 'id': id,
    'driver_id':     driverId,
    'driver_id_str': driverIdStr,
    'car_name':      carName,
    'speed_kmph':    speedKmph,
    'limit_kmph':    limitKmph,
    'excess_kmph':   excessKmph,
    if (predictionId != null) 'prediction_id': predictionId,
    'violated_at':   violatedAt.toIso8601String(),
  };

  String get severityLabel {
    if (excessKmph >= 40) return 'CRITICAL';
    if (excessKmph >= 20) return 'HIGH';
    return 'MODERATE';
  }

  bool get isCritical => excessKmph >= 40;
}
