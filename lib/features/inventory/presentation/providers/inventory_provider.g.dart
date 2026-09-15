// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'inventory_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(inventoryRepository)
final inventoryRepositoryProvider = InventoryRepositoryProvider._();

final class InventoryRepositoryProvider extends $FunctionalProvider<
    InventoryRepository,
    InventoryRepository,
    InventoryRepository> with $Provider<InventoryRepository> {
  InventoryRepositoryProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'inventoryRepositoryProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$inventoryRepositoryHash();

  @$internal
  @override
  $ProviderElement<InventoryRepository> $createElement(
          $ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  InventoryRepository create(Ref ref) {
    return inventoryRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(InventoryRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<InventoryRepository>(value),
    );
  }
}

String _$inventoryRepositoryHash() =>
    r'2960045571f4cedcb324a59154010ec0a53781f2';

@ProviderFor(StockTransactionList)
final stockTransactionListProvider = StockTransactionListProvider._();

final class StockTransactionListProvider extends $AsyncNotifierProvider<
    StockTransactionList, List<StockTransaction>> {
  StockTransactionListProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'stockTransactionListProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$stockTransactionListHash();

  @$internal
  @override
  StockTransactionList create() => StockTransactionList();
}

String _$stockTransactionListHash() =>
    r'4b3434152c1dde277bfa2ed88d6a23edf19fdf3b';

abstract class _$StockTransactionList
    extends $AsyncNotifier<List<StockTransaction>> {
  FutureOr<List<StockTransaction>> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref
        as $Ref<AsyncValue<List<StockTransaction>>, List<StockTransaction>>;
    final element = ref.element as $ClassProviderElement<
        AnyNotifier<AsyncValue<List<StockTransaction>>, List<StockTransaction>>,
        AsyncValue<List<StockTransaction>>,
        Object?,
        Object?>;
    return element.handleCreate(ref, build);
  }
}
