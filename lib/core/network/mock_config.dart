import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'mock_config.g.dart';

@Riverpod(keepAlive: true)
class UseMockData extends _$UseMockData {
  @override
  bool build() {
    // Default to dev mode (false means use real API)
    return false;
  }

  void toggle() {
    state = !state;
  }

  void setMock(bool value) {
    state = value;
  }
}
