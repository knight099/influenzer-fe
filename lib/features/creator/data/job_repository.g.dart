// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'job_repository.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(jobRepository)
const jobRepositoryProvider = JobRepositoryProvider._();

final class JobRepositoryProvider
    extends $FunctionalProvider<JobRepository, JobRepository, JobRepository>
    with $Provider<JobRepository> {
  const JobRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'jobRepositoryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$jobRepositoryHash();

  @$internal
  @override
  $ProviderElement<JobRepository> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  JobRepository create(Ref ref) {
    return jobRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(JobRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<JobRepository>(value),
    );
  }
}

String _$jobRepositoryHash() => r'a22cd1ab6c02d184335d180a1e424cf013c89e13';
