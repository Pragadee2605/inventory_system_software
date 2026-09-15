// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sales_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(salesRepository)
final salesRepositoryProvider = SalesRepositoryProvider._();

final class SalesRepositoryProvider extends $FunctionalProvider<SalesRepository,
    SalesRepository, SalesRepository> with $Provider<SalesRepository> {
  SalesRepositoryProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'salesRepositoryProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$salesRepositoryHash();

  @$internal
  @override
  $ProviderElement<SalesRepository> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  SalesRepository create(Ref ref) {
    return salesRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SalesRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SalesRepository>(value),
    );
  }
}

String _$salesRepositoryHash() => r'42707bacf1eddc73a471b244c10f794247b288ee';

@ProviderFor(SalesList)
final salesListProvider = SalesListProvider._();

final class SalesListProvider
    extends $AsyncNotifierProvider<SalesList, List<SalesOrder>> {
  SalesListProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'salesListProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$salesListHash();

  @$internal
  @override
  SalesList create() => SalesList();
}

String _$salesListHash() => r'48ec1ea5f2cf793575b3474de952c64c9d1b6c87';

abstract class _$SalesList extends $AsyncNotifier<List<SalesOrder>> {
  FutureOr<List<SalesOrder>> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref =
        this.ref as $Ref<AsyncValue<List<SalesOrder>>, List<SalesOrder>>;
    final element = ref.element as $ClassProviderElement<
        AnyNotifier<AsyncValue<List<SalesOrder>>, List<SalesOrder>>,
        AsyncValue<List<SalesOrder>>,
        Object?,
        Object?>;
    return element.handleCreate(ref, build);
  }
}
