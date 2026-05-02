// Stub for VM (Android, iOS, desktop non-web renderer).
// The actual initialization is handled natively on those platforms.
Future<void> initializeMapsApiKey(String apiKey) async {
  // No-op on non-web platforms
}
