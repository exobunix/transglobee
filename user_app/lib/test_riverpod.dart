import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class MyNotifier extends AsyncNotifier<String> {
  @override
  FutureOr<String> build() => 'test';

  void test() {
    state = const AsyncValue.loading();
  }
}
void main() {}
