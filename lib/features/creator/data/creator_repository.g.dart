// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'creator_repository.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(creatorRepository)
const creatorRepositoryProvider = CreatorRepositoryProvider._();

final class CreatorRepositoryProvider
    extends
        $FunctionalProvider<
          CreatorRepository,
          CreatorRepository,
          CreatorRepository
        >
    with $Provider<CreatorRepository> {
  const CreatorRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'creatorRepositoryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$creatorRepositoryHash();

  @$internal
  @override
  $ProviderElement<CreatorRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  CreatorRepository create(Ref ref) {
    return creatorRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(CreatorRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<CreatorRepository>(value),
    );
  }
}

String _$creatorRepositoryHash() => r'264b424f15fa4a00826d95ec9da6133d84e65266';

/// Cached creator search results - persists during app session
/// Automatically refetches when app restarts

@ProviderFor(cachedCreatorSearch)
const cachedCreatorSearchProvider = CachedCreatorSearchProvider._();

/// Cached creator search results - persists during app session
/// Automatically refetches when app restarts

final class CachedCreatorSearchProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<dynamic>>,
          List<dynamic>,
          FutureOr<List<dynamic>>
        >
    with $FutureModifier<List<dynamic>>, $FutureProvider<List<dynamic>> {
  /// Cached creator search results - persists during app session
  /// Automatically refetches when app restarts
  const CachedCreatorSearchProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'cachedCreatorSearchProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$cachedCreatorSearchHash();

  @$internal
  @override
  $FutureProviderElement<List<dynamic>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<dynamic>> create(Ref ref) {
    return cachedCreatorSearch(ref);
  }
}

String _$cachedCreatorSearchHash() =>
    r'7af445b1ab2408b03c4e62fd147bb4d7118bc9d4';

/// Spotlight creators — early adopters with connected platforms

@ProviderFor(spotlightCreators)
const spotlightCreatorsProvider = SpotlightCreatorsProvider._();

/// Spotlight creators — early adopters with connected platforms

final class SpotlightCreatorsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<dynamic>>,
          List<dynamic>,
          FutureOr<List<dynamic>>
        >
    with $FutureModifier<List<dynamic>>, $FutureProvider<List<dynamic>> {
  /// Spotlight creators — early adopters with connected platforms
  const SpotlightCreatorsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'spotlightCreatorsProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$spotlightCreatorsHash();

  @$internal
  @override
  $FutureProviderElement<List<dynamic>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<dynamic>> create(Ref ref) {
    return spotlightCreators(ref);
  }
}

String _$spotlightCreatorsHash() =>
    r'a1b2c3d4e5f6a7b8c9d0e1f2a3b4c5d6e7f8a9b0';
