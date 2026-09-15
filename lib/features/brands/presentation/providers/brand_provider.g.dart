// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'brand_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(brandRepository)
final brandRepositoryProvider = BrandRepositoryProvider._();

final class BrandRepositoryProvider extends $FunctionalProvider<BrandRepository,
    BrandRepository, BrandRepository> with $Provider<BrandRepository> {
  BrandRepositoryProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'brandRepositoryProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$brandRepositoryHash();

  @$internal
  @override
  $ProviderElement<BrandRepository> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  BrandRepository create(Ref ref) {
    return brandRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(BrandRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<BrandRepository>(value),
    );
  }
}

String _$brandRepositoryHash() => r'093fa2ca2c6881e2ec49727e84c4cf4b06686ef8';

@ProviderFor(BrandList)
final brandListProvider = BrandListProvider._();

final class BrandListProvider
    extends $AsyncNotifierProvider<BrandList, List<Brand>> {
  BrandListProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'brandListProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$brandListHash();

  @$internal
  @override
  BrandList create() => BrandList();
}

String _$brandListHash() => r'c2dc8bba8a485a5ba7049601ede4207483251556';

abstract class _$BrandList extends $AsyncNotifier<List<Brand>> {
  FutureOr<List<Brand>> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<AsyncValue<List<Brand>>, List<Brand>>;
    final element = ref.element as $ClassProviderElement<
        AnyNotifier<AsyncValue<List<Brand>>, List<Brand>>,
        AsyncValue<List<Brand>>,
        Object?,
        Object?>;
    return element.handleCreate(ref, build);
  }
}
