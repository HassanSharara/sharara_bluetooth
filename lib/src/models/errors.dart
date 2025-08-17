class DeviceBuildingException implements Exception {
  final String code;     // like "52" from your Kotlin side
  final String message;  // short message
  final String details;  // extra info if needed

  DeviceBuildingException(this.code, this.message, [this.details = ""]);

  @override
  String toString() => "BluetoothException($code): $message ${details.isNotEmpty ? '($details)' : ''}";
}