class SerialConfig {
  const SerialConfig({
    required this.baudRate,
    required this.dataBits,
    required this.stopBits,
    required this.parity,
    this.portLabel,
  });

  const SerialConfig.defaults()
      : baudRate = 115200,
        dataBits = 8,
        stopBits = 1,
        parity = 'none',
        portLabel = null;

  final int baudRate;
  final int dataBits;
  final int stopBits;
  final String parity;
  final String? portLabel;

  SerialConfig copyWith({
    int? baudRate,
    int? dataBits,
    int? stopBits,
    String? parity,
    String? portLabel,
  }) {
    return SerialConfig(
      baudRate: baudRate ?? this.baudRate,
      dataBits: dataBits ?? this.dataBits,
      stopBits: stopBits ?? this.stopBits,
      parity: parity ?? this.parity,
      portLabel: portLabel ?? this.portLabel,
    );
  }

  Map<String, Object?> toJson() => {
        'baudRate': baudRate,
        'dataBits': dataBits,
        'stopBits': stopBits,
        'parity': parity,
        'portLabel': portLabel,
      };

  factory SerialConfig.fromJson(Map<String, Object?> json) {
    return SerialConfig(
      baudRate: json['baudRate'] as int? ?? 115200,
      dataBits: json['dataBits'] as int? ?? 8,
      stopBits: json['stopBits'] as int? ?? 1,
      parity: json['parity'] as String? ?? 'none',
      portLabel: json['portLabel'] as String?,
    );
  }
}
