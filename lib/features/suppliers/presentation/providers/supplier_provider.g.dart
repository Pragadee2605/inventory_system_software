// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'supplier_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(supplierRepository)
final supplierRepositoryProvider = SupplierRepositoryProvider._();

final class SupplierRepositoryProvider extends $FunctionalProvider<
    SupplierRepository,
    SupplierRepository,
    SupplierRepository> with $Provider<SupplierRepository> {
  SupplierRepositoryProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'supplierRepositoryProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$supplierRepositoryHash();

  @$internal
  @override
  $ProviderElement<SupplierRepository> $createElement(
          $ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  SupplierRepository create(Ref ref) {
    return supplierRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SupplierRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SupplierRepository>(value),
    );
  }
}

String _$supplierRepositoryHash() =>
    r'e297f55e2fc72ea4e5720b5a5ad5bcfe7506c179';

@ProviderFor(SupplierList)
final supplierListProvider = SupplierListProvider._();

final class SupplierListProvider
    extends $AsyncNotifierProvider<SupplierList, List<Supplier>> {
  SupplierListProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'supplierListProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$supplierListHash();

  @$internal
  @override
  SupplierList create() => SupplierList();
}

String _$supplierListHash() => r'2bfe5b1f1b7cab440376a2705a13c352fe1d952f';

abstract class _$SupplierList extends $AsyncNotifier<List<Supplier>> {
  FutureOr<List<Supplier>> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<AsyncValue<List<Supplier>>, List<Supplier>>;
    final element = ref.element as $ClassProviderElement<
        AnyNotifier<AsyncValue<List<Supplier>>, List<Supplier>>,
        AsyncValue<List<Supplier>>,
        Object?,
        Object?>;
    return element.handleCreate(ref, build);
  }
}
