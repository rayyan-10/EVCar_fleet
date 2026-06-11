class CatalogVehicle {
  final String vehicleId;
  final String brand;
  final String carName;
  final double vehicleWeightKg;
  final double motorPowerKw;
  final double batteryCapacityKwh;
  final double maxRangeKm;

  const CatalogVehicle({
    required this.vehicleId,
    required this.brand,
    required this.carName,
    required this.vehicleWeightKg,
    required this.motorPowerKw,
    required this.batteryCapacityKwh,
    required this.maxRangeKm,
  });

  String get displayName => '$brand $carName';
}

class VehicleCatalog {
  static const List<CatalogVehicle> vehicles = [
    CatalogVehicle(vehicleId: 'VH001', brand: 'Volkswagen', carName: 'ID.4',           vehicleWeightKg: 2100, motorPowerKw: 150, batteryCapacityKwh: 77.0,  maxRangeKm: 520),
    CatalogVehicle(vehicleId: 'VH002', brand: 'Volkswagen', carName: 'ID.4 Pro',        vehicleWeightKg: 2200, motorPowerKw: 150, batteryCapacityKwh: 82.0,  maxRangeKm: 550),
    CatalogVehicle(vehicleId: 'VH003', brand: 'Volkswagen', carName: 'ID.5',            vehicleWeightKg: 2200, motorPowerKw: 174, batteryCapacityKwh: 82.0,  maxRangeKm: 530),
    CatalogVehicle(vehicleId: 'VH004', brand: 'Tata',       carName: 'Nexon EV',        vehicleWeightKg: 1400, motorPowerKw: 95,  batteryCapacityKwh: 40.5,  maxRangeKm: 465),
    CatalogVehicle(vehicleId: 'VH005', brand: 'Tata',       carName: 'Curvv EV',        vehicleWeightKg: 1500, motorPowerKw: 123, batteryCapacityKwh: 55.0,  maxRangeKm: 585),
    CatalogVehicle(vehicleId: 'VH006', brand: 'Tata',       carName: 'Punch EV',        vehicleWeightKg: 1250, motorPowerKw: 90,  batteryCapacityKwh: 35.0,  maxRangeKm: 421),
    CatalogVehicle(vehicleId: 'VH007', brand: 'Hyundai',    carName: 'Kona EV',         vehicleWeightKg: 1685, motorPowerKw: 100, batteryCapacityKwh: 39.2,  maxRangeKm: 452),
    CatalogVehicle(vehicleId: 'VH008', brand: 'Hyundai',    carName: 'Kona Long Range', vehicleWeightKg: 1750, motorPowerKw: 150, batteryCapacityKwh: 64.0,  maxRangeKm: 484),
    CatalogVehicle(vehicleId: 'VH009', brand: 'Hyundai',    carName: 'Creta EV',        vehicleWeightKg: 1600, motorPowerKw: 126, batteryCapacityKwh: 51.4,  maxRangeKm: 473),
    CatalogVehicle(vehicleId: 'VH010', brand: 'Hyundai',    carName: 'Creta EV Pro',    vehicleWeightKg: 1650, motorPowerKw: 135, batteryCapacityKwh: 55.0,  maxRangeKm: 490),
  ];
}
