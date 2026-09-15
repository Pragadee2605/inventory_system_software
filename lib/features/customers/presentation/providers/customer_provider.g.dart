// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'customer_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(customerRepository)
final customerRepositoryProvider = CustomerRepositoryProvider._();

final class CustomerRepositoryProvider extends $FunctionalProvider<
    CustomerRepository,
    CustomerRepository,
    CustomerRepository> with $Provider<CustomerRepository> {
  CustomerRepositoryProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'customerRepositoryProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$customerRepositoryHash();

  @$internal
  @override
  $ProviderElement<CustomerRepository> $createElement(
          $ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  CustomerRepository create(Ref ref) {
    return customerRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(CustomerRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<CustomerRepository>(value),
    );
  }
}

String _$customerRepositoryHash() =>
    r'955e4c8a4bd1e35d0828cd95f0f24b55e4a74af5';

@ProviderFor(CustomerList)
final customerListProvider = CustomerListProvider._();

final class CustomerListProvider
    extends $AsyncNotifierProvider<CustomerList, List<Customer>> {
  CustomerListProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'customerListProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$customerListHash();

  @$internal
  @override
  CustomerList create() => CustomerList();
}

String _$customerListHash() => r'8dc7043a0aec10de9c7e11167fee239877ecbf2b';

abstract class _$CustomerList extends $AsyncNotifier<List<Customer>> {
  FutureOr<List<Customer>> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<AsyncValue<List<Customer>>, List<Customer>>;
    final element = ref.element as $ClassProviderElement<
        AnyNotifier<AsyncValue<List<Customer>>, List<Customer>>,
        AsyncValue<List<Customer>>,
        Object?,
        Object?>;
    return element.handleCreate(ref, build);
  }
}
