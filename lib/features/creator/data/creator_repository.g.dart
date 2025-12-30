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
