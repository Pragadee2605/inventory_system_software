// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'product_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(productRepository)
final productRepositoryProvider = ProductRepositoryProvider._();

final class ProductRepositoryProvider extends $FunctionalProvider<
    ProductRepository,
    ProductRepository,
    ProductRepository> with $Provider<ProductRepository> {
  ProductRepositoryProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'productRepositoryProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$productRepositoryHash();

  @$internal
  @override
  $ProviderElement<ProductRepository> $createElement(
          $ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  ProductRepository create(Ref ref) {
    return productRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ProductRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ProductRepository>(value),
    );
  }
}

String _$productRepositoryHash() => r'14973738a9a4d9261a101e7ab9d64b0714327570';

@ProviderFor(ProductList)
final productListProvider = ProductListProvider._();

final class ProductListProvider
    extends $AsyncNotifierProvider<ProductList, List<Product>> {
  ProductListProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'productListProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$productListHash();

  @$internal
  @override
  ProductList create() => ProductList();
}

String _$productListHash() => r'b57975692ca263bf2a272ed9f63691fb118fb5fc';

abstract class _$ProductList extends $AsyncNotifier<List<Product>> {
  FutureOr<List<Product>> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<AsyncValue<List<Product>>, List<Product>>;
    final element = ref.element as $ClassProviderElement<
        AnyNotifier<AsyncValue<List<Product>>, List<Product>>,
        AsyncValue<List<Product>>,
        Object?,
        Object?>;
    return element.handleCreate(ref, build);
  }
}
