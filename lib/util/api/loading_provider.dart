import 'package:chattingapp/util/api/api_notifier.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod/riverpod.dart' show ProviderContainer;

/// 로딩 카운트 Notifier
class GlobalLoadingCountNotifier extends Notifier<int> {
  @override
  int build() {
    return 0;
  }

  void increment() {
    state = state + 1;
  }

  void decrement() {
    if (state > 0) {
      state = state - 1;
    }
  }
}

/// API 로딩 카운트 Provider
/// 여러 API 요청이 동시에 발생해도 정확히 카운트 관리
final globalLoadingCountProvider = NotifierProvider<GlobalLoadingCountNotifier, int>(() {
  return GlobalLoadingCountNotifier();
});

/// 로딩 중인지 확인하는 Provider (count > 0 이면 true)
final isGlobalLoadingProvider = Provider<bool>((ref) {
  return ref.watch(globalLoadingCountProvider) > 0;
});

/// 로컬 로딩 카운트 Notifier
class LocalLoadingCountNotifier extends Notifier<int> {
  @override
  int build() {
    return 0;
  }

  void increment() {
    state = state + 1;
  }

  void decrement() {
    if (state > 0) {
      state = state - 1;
    }
  }
}

/// 로컬 API 로딩 카운트 Provider
/// 여러 API 요청이 동시에 발생해도 정확히 카운트 관리
final localLoadingCountProvider = NotifierProvider<LocalLoadingCountNotifier, int>(() {
  return LocalLoadingCountNotifier();
});

/// 로컬 로딩 중인지 확인하는 Provider (count > 0 이면 true)
final isLocalLoadingProvider = Provider<bool>((ref) {
  return ref.watch(localLoadingCountProvider) > 0;
});

/// 전역 ProviderContainer (interceptor에서 사용)
/// main.dart에서 초기화 필요
ProviderContainer? _globalContainer;

/// 전역 ProviderContainer 설정
void setGlobalProviderContainer(ProviderContainer container) {
  _globalContainer = container;
}

/// 전역 ProviderContainer 가져오기
ProviderContainer? getGlobalProviderContainer() {
  return _globalContainer;
}

/// 로딩 카운트 증가 (전역 Container 사용 - interceptor에서 호출)
void incrementLoadingCountGlobal() {
  if (_globalContainer != null) {
    _globalContainer!.read(globalLoadingCountProvider.notifier).increment();
  }
}

/// 로딩 카운트 감소 (전역 Container 사용 - interceptor에서 호출)
void decrementLoadingCountGlobal() {
  if (_globalContainer != null) {
    _globalContainer!.read(globalLoadingCountProvider.notifier).decrement();
  }
}

/// 로딩 카운트 증가 (전역 Container 사용 - 로컬 로딩)
void incrementLoadingCountLocal() {
  if (_globalContainer != null) {
    _globalContainer!.read(localLoadingCountProvider.notifier).increment();
  }
}

/// 로딩 카운트 감소 (전역 Container 사용 - 로컬 로딩)
void decrementLoadingCountLocal() {
  if (_globalContainer != null) {
    _globalContainer!.read(localLoadingCountProvider.notifier).decrement();
  }
}

void logout() {
  if (_globalContainer != null) {
    _globalContainer!.read(apiNotifier.notifier).logout();
  }
}