// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'mock_config.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(UseMockData)
const useMockDataProvider = UseMockDataProvider._();

final class UseMockDataProvider extends $NotifierProvider<UseMockData, bool> {
  const UseMockDataProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'useMockDataProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$useMockDataHash();

  @$internal
  @override
  UseMockData create() => UseMockData();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(bool value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<bool>(value),
    );
  }
}

String _$useMockDataHash() => r'4009b3e3a3411617b5b190177482c4447330d8df';

abstract class _$UseMockData extends $Notifier<bool> {
  bool build();
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build();
    final ref = this.ref as $Ref<bool, bool>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<bool, bool>,
              bool,
              Object?,
              Object?
            >;
    element.handleValue(ref, created);
  }
}
