// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'purchase_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(purchaseRepository)
final purchaseRepositoryProvider = PurchaseRepositoryProvider._();

final class PurchaseRepositoryProvider extends $FunctionalProvider<
    PurchaseRepository,
    PurchaseRepository,
    PurchaseRepository> with $Provider<PurchaseRepository> {
  PurchaseRepositoryProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'purchaseRepositoryProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$purchaseRepositoryHash();

  @$internal
  @override
  $ProviderElement<PurchaseRepository> $createElement(
          $ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  PurchaseRepository create(Ref ref) {
    return purchaseRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(PurchaseRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<PurchaseRepository>(value),
    );
  }
}

String _$purchaseRepositoryHash() =>
    r'17b0f4c22e3fd8449ac4c700a1b1f4a04e657e46';

@ProviderFor(PurchaseList)
final purchaseListProvider = PurchaseListProvider._();

final class PurchaseListProvider
    extends $AsyncNotifierProvider<PurchaseList, List<PurchaseOrder>> {
  PurchaseListProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'purchaseListProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$purchaseListHash();

  @$internal
  @override
  PurchaseList create() => PurchaseList();
}

String _$purchaseListHash() => r'86129ebe3c017f52aee721f81af058fc6dc7f696';

abstract class _$PurchaseList extends $AsyncNotifier<List<PurchaseOrder>> {
  FutureOr<List<PurchaseOrder>> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref =
        this.ref as $Ref<AsyncValue<List<PurchaseOrder>>, List<PurchaseOrder>>;
    final element = ref.element as $ClassProviderElement<
        AnyNotifier<AsyncValue<List<PurchaseOrder>>, List<PurchaseOrder>>,
        AsyncValue<List<PurchaseOrder>>,
        Object?,
        Object?>;
    return element.handleCreate(ref, build);
  }
}

@ProviderFor(purchaseDetails)
final purchaseDetailsProvider = PurchaseDetailsFamily._();

final class PurchaseDetailsProvider extends $FunctionalProvider<
        AsyncValue<PurchaseOrder?>, PurchaseOrder?, FutureOr<PurchaseOrder?>>
    with $FutureModifier<PurchaseOrder?>, $FutureProvider<PurchaseOrder?> {
  PurchaseDetailsProvider._(
      {required PurchaseDetailsFamily super.from, required int super.argument})
      : super(
          retry: null,
          name: r'purchaseDetailsProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$purchaseDetailsHash();

  @override
  String toString() {
    return r'purchaseDetailsProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<PurchaseOrder?> $createElement(
          $ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<PurchaseOrder?> create(Ref ref) {
    final argument = this.argument as int;
    return purchaseDetails(
      ref,
      argument,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is PurchaseDetailsProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$purchaseDetailsHash() => r'35ac2ea5a1f79b9cc20809c36e53607dd965198d';

final class PurchaseDetailsFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<PurchaseOrder?>, int> {
  PurchaseDetailsFamily._()
      : super(
          retry: null,
          name: r'purchaseDetailsProvider',
          dependencies: null,
          $allTransitiveDependencies: null,
          isAutoDispose: true,
        );

  PurchaseDetailsProvider call(
    int id,
  ) =>
      PurchaseDetailsProvider._(argument: id, from: this);

  @override
  String toString() => r'purchaseDetailsProvider';
}
