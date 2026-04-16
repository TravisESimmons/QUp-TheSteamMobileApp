// Stub for non-web platforms
void setupWebLogin(String webLoginUrl, Function(String) onSuccess) {
  throw UnsupportedError('Web login is only supported on web platform');
}
