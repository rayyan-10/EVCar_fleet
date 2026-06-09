class VehicleModel {
  final String? id;
  final String driverId;
  final String driverIdStr;
  final String driverName;
  final String email;
  final String carName;
  final double batteryCapacity;
  final double vehicleWeight;
  final double motorPower;
  final double torque;
  final double motorEfficiency;
  final int runningType; // 0 = City, 1 = Highway
  final int vehicleCondition; // 1 = Working, 0 = Garage
  final double currentSpeed;
  final double monthlyIncome;
  final String currentDate;
  final String currentTime;
  final String currentMonth;
  final String? location;
  final DateTime? createdAt;

  VehicleModel({
    this.id,
    required this.driverId,
    required this.driverIdStr,
    required this.driverName,
    required this.email,
    required this.carName,
    required this.batteryCapacity,
    required this.vehicleWeight,
    required this.motorPower,
    required this.torque,
    required this.motorEfficiency,
    required this.runningType,
    required this.vehicleCondition,
    required this.currentSpeed,
    required this.monthlyIncome,
    required this.currentDate,
    required this.currentTime,
    required this.currentMonth,
    this.location,
    this.createdAt,
  });

  factory VehicleModel.fromJson(Map<String, dynamic> json) {
    return VehicleModel(
      id: json['id'] as String?,
      driverId: json['driver_id'] as String,
      driverIdStr: json['driver_id_str'] as String,
      driverName: json['driver_name'] as String,
      email: json['email'] as String,
      carName: json['car_name'] as String,
      batteryCapacity: (json['battery_capacity'] as num).toDouble(),
      vehicleWeight: (json['vehicle_weight'] as num).toDouble(),
      motorPower: (json['motor_power'] as num).toDouble(),
      torque: (json['torque'] as num).toDouble(),
      motorEfficiency: (json['motor_efficiency'] as num).toDouble(),
      runningType: (json['running_type'] as num).toInt(),
      vehicleCondition: (json['vehicle_condition'] as num).toInt(),
      currentSpeed: (json['current_speed'] as num).toDouble(),
      monthlyIncome: (json['monthly_income'] as num).toDouble(),
      currentDate: json['current_date'] as String,
      currentTime: json['current_time'] as String,
      currentMonth: json['current_month'] as String,
      location: json['location'] as String?,
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at'] as String) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'driver_id': driverId,
      'driver_id_str': driverIdStr,
      'driver_name': driverName,
      'email': email,
      'car_name': carName,
      'battery_capacity': batteryCapacity,
      'vehicle_weight': vehicleWeight,
      'motor_power': motorPower,
      'torque': torque,
      'motor_efficiency': motorEfficiency,
      'running_type': runningType,
      'vehicle_condition': vehicleCondition,
      'current_speed': currentSpeed,
      'monthly_income': monthlyIncome,
      'current_date': currentDate,
      'current_time': currentTime,
      'current_month': currentMonth,
      'location': location,
      if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
    };
  }

  VehicleModel copyWith({
    String? id,
    String? driverId,
    String? driverIdStr,
    String? driverName,
    String? email,
    String? carName,
    double? batteryCapacity,
    double? vehicleWeight,
    double? motorPower,
    double? torque,
    double? motorEfficiency,
    int? runningType,
    int? vehicleCondition,
    double? currentSpeed,
    double? monthlyIncome,
    String? currentDate,
    String? currentTime,
    String? currentMonth,
    String? location,
    DateTime? createdAt,
  }) {
    return VehicleModel(
      id: id ?? this.id,
      driverId: driverId ?? this.driverId,
      driverIdStr: driverIdStr ?? this.driverIdStr,
      driverName: driverName ?? this.driverName,
      email: email ?? this.email,
      carName: carName ?? this.carName,
      batteryCapacity: batteryCapacity ?? this.batteryCapacity,
      vehicleWeight: vehicleWeight ?? this.vehicleWeight,
      motorPower: motorPower ?? this.motorPower,
      torque: torque ?? this.torque,
      motorEfficiency: motorEfficiency ?? this.motorEfficiency,
      runningType: runningType ?? this.runningType,
      vehicleCondition: vehicleCondition ?? this.vehicleCondition,
      currentSpeed: currentSpeed ?? this.currentSpeed,
      monthlyIncome: monthlyIncome ?? this.monthlyIncome,
      currentDate: currentDate ?? this.currentDate,
      currentTime: currentTime ?? this.currentTime,
      currentMonth: currentMonth ?? this.currentMonth,
      location: location ?? this.location,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
