// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'brand_profile_repository.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(brandProfileRepository)
const brandProfileRepositoryProvider = BrandProfileRepositoryProvider._();

final class BrandProfileRepositoryProvider
    extends
        $FunctionalProvider<
          BrandProfileRepository,
          BrandProfileRepository,
          BrandProfileRepository
        >
    with $Provider<BrandProfileRepository> {
  const BrandProfileRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'brandProfileRepositoryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$brandProfileRepositoryHash();

  @$internal
  @override
  $ProviderElement<BrandProfileRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  BrandProfileRepository create(Ref ref) {
    return brandProfileRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(BrandProfileRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<BrandProfileRepository>(value),
    );
  }
}

String _$brandProfileRepositoryHash() =>
    r'407651a554dfdaefd8d90dae2a8b029c1a26a879';

@ProviderFor(brandProfile)
const brandProfileProvider = BrandProfileProvider._();

final class BrandProfileProvider
    extends
        $FunctionalProvider<
          AsyncValue<BrandProfile>,
          BrandProfile,
          FutureOr<BrandProfile>
        >
    with $FutureModifier<BrandProfile>, $FutureProvider<BrandProfile> {
  const BrandProfileProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'brandProfileProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$brandProfileHash();

  @$internal
  @override
  $FutureProviderElement<BrandProfile> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<BrandProfile> create(Ref ref) {
    return brandProfile(ref);
  }
}

String _$brandProfileHash() => r'0f351268d8660d37ac6d94325eaddf8c73f56dcc';
