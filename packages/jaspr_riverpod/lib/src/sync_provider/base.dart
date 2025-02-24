// ignore_for_file: invalid_use_of_internal_member, subtype_of_sealed_class

part of '../sync_provider.dart';

/// {@macro riverpod.providerrefbase}
/// - [state], the value currently exposed by this provider.
abstract class SyncProviderRef<State> implements Ref<AsyncValue<State>> {
  /// Obtains the state currently exposed by this provider.
  ///
  /// Mutating this property will notify the provider listeners.
  ///
  /// Cannot be called while a provider is creating, unless the setter was called first.
  ///
  /// Will throw if the provider threw during creation.
  AsyncValue<State> get state;
  set state(AsyncValue<State> newState);
}

/// {@macro riverpod.syncprovider}
class SyncProvider<T> extends _SyncProviderBase<T>
    with AlwaysAliveProviderBase<AsyncValue<T>>, AlwaysAliveAsyncSelector<T> {
  /// {@macro riverpod.syncprovider}
  SyncProvider(
    this._createFn, {
    required this.id,
    this.codec,
    super.name,
    super.from,
    super.argument,
    super.dependencies,
    super.debugGetCreateSourceHash,
  });

  /// {@macro riverpod.family}
  static const family = SyncProviderFamilyBuilder();

  final FutureOr<T> Function(SyncProviderRef<T> ref) _createFn;

  /// The unique id to sync between server and client.
  final String id;

  final Codec<T, dynamic>? codec;

  @override
  late final AlwaysAliveRefreshable<Future<T>> future = _future(this);

  @override
  FutureOr<T> _create(SyncProviderElement<T> ref) {
    if (kIsWeb) {
      return ref.watch(_syncStateProvider.select((s) {
        if (!s.containsKey(id)) {
          return Completer<T>().future;
        }
        var value = s[id];
        return value != null ? (codec ?? CastCodec()).decode(value) : value;
      }));
    }
    return _createFn(ref);
  }

  @override
  SyncProviderElement<T> createElement() => SyncProviderElement._(this);

  /// {@macro riverpod.overridewith}
  Override overrideWith(Create<FutureOr<T>, SyncProviderRef<T>> create) {
    return ProviderOverride(
      origin: this,
      override: SyncProvider(
        create,
        id: id,
        codec: codec,
        from: from,
        argument: argument,
      ),
    );
  }
}

/// The element of a [SyncProvider]
class SyncProviderElement<T> extends ProviderElementBase<AsyncValue<T>>
    with FutureHandlerProviderElementMixin<T>
    implements SyncProviderRef<T> {
  SyncProviderElement._(_SyncProviderBase<T> super.provider);

  @override
  AsyncValue<T> get state => requireState;

  @override
  bool updateShouldNotify(AsyncValue<T> previous, AsyncValue<T> next) {
    return FutureHandlerProviderElementMixin.handleUpdateShouldNotify(
      previous,
      next,
    );
  }

  @override
  void create({required bool didChangeDependency}) {
    final provider = this.provider as _SyncProviderBase<T>;

    return handleFuture(
      () => provider._create(this),
      didChangeDependency: didChangeDependency,
    );
  }
}

/// The [Family] of a [SyncProvider]
class SyncProviderFamily<R, Arg>
    extends FamilyBase<SyncProviderRef<R>, AsyncValue<R>, Arg, FutureOr<R>, SyncProvider<R>> {
  /// The [Family] of a [SyncProvider]
  SyncProviderFamily(
    super.create, {
    required this.id,
    super.name,
    super.dependencies,
  }) : super(
            providerFactory: (
          Create<FutureOr<R>, SyncProviderRef<R>> create, {
          String? name,
          Family? from,
          Object? argument,
          List<ProviderOrFamily>? dependencies,
        }) =>
                SyncProvider<R>(create,
                    id: id, name: name, from: from, argument: argument, dependencies: dependencies));

  final String id;

  /// {@macro riverpod.overridewith}
  Override overrideWith(
    FutureOr<R> Function(SyncProviderRef<R> ref, Arg arg) create,
  ) {
    return FamilyOverrideImpl<AsyncValue<R>, Arg, SyncProvider<R>>(
      this,
      (arg) => SyncProvider<R>(
        (ref) => create(ref, arg),
        id: id,
        from: from,
        argument: arg,
      ),
    );
  }
}

/// Builds a [SyncProviderFamily].
class SyncProviderFamilyBuilder {
  /// Builds a [SyncProviderFamily].
  const SyncProviderFamilyBuilder();

  /// {@macro riverpod.family}
  SyncProviderFamily<State, Arg> call<State, Arg>(
    FamilyCreate<FutureOr<State>, SyncProviderRef<State>, Arg> create, {
    required String id,
    String? name,
    List<ProviderOrFamily>? dependencies,
  }) {
    return SyncProviderFamily<State, Arg>(
      create,
      id: id,
      name: name,
      dependencies: dependencies,
    );
  }
}
