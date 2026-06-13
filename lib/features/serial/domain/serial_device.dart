class SerialDevice {
  const SerialDevice({
    required this.id,
    required this.label,
    this.manufacturer,
    this.productName,
  });

  final String id;
  final String label;
  final String? manufacturer;
  final String? productName;
}
