part of 'framework.dart';

@immutable
abstract class BaseProvider<T> {
  ProviderOverride<T> overrideForSubtree(BaseProvider<T> provider) {
    return ProviderOverride._(provider, this);
  }

  Iterable<BaseProvider<Object>> _allDependencies() sync* {}

  @visibleForOverriding
  BaseProviderState<T, BaseProvider<T>> createState();
}

@visibleForOverriding
abstract class BaseProviderState<Res, T extends BaseProvider<Res>>
    implements ProviderListenerState<Res>, ProviderState {
  T _provider;

  var _mounted = true;
  @override
  bool get mounted => _mounted;

  Res _$state;
  @override
  Res get $state => _$state;
  set $state(Res $state) {
    _$state = $state;
    if (_stateListeners != null) {
      for (final listener in _stateListeners) {
        listener.value($state);
      }
    }
  }

  @protected
  @visibleForTesting
  T get provider => _provider;

  ProviderStateOwner _owner;
  ProviderStateOwner get owner => _owner;

  /// Keep track of this provider's dependencies on mount to assert that they
  /// never change.
  List<BaseProviderState<Object, BaseProvider<Object>>>
      _debugInitialDependenciesState;

  DoubleLinkedQueue<VoidCallback> _onDisposeCallbacks;
  LinkedList<_LinkedListEntry<void Function(Res)>> _stateListeners;

  @mustCallSuper
  void _initDependencies(
    List<BaseProviderState<Object, BaseProvider<Object>>> dependenciesState,
  ) {
    assert(() {
      _debugInitialDependenciesState = dependenciesState;
      return true;
    }(), '');
  }

  @protected
  Res initState();

  @mustCallSuper
  @protected
  void didUpdateProvider(T oldProvider) {}

  @override
  void onDispose(VoidCallback cb) {
    _onDisposeCallbacks ??= DoubleLinkedQueue();
    _onDisposeCallbacks.add(cb);
  }

  VoidCallback $addStateListener(
    void Function(Res) listener, {
    bool fireImmediately = true,
  }) {
    if (fireImmediately) {
      listener($state);
    }
    _stateListeners ??= LinkedList();
    final entry = _LinkedListEntry(listener);
    _stateListeners.add(entry);
    return entry.unlink;
  }

  bool get $hasListeners => _stateListeners?.isNotEmpty ?? false;

  void dispose() {
    if (_onDisposeCallbacks != null) {
      for (final disposeCb in _onDisposeCallbacks) {
        try {
          disposeCb();
        } catch (err, stack) {
          owner._onError?.call(err, stack);
        }
      }
    }
    _mounted = false;
  }
}

class _LinkedListEntry<T> extends LinkedListEntry<_LinkedListEntry<T>> {
  _LinkedListEntry(this.value);
  final T value;
}

abstract class BaseProvider1<First, Res> extends BaseProvider<Res> {
  BaseProvider1(this._first);

  final BaseProvider<First> _first;

  @override
  Iterable<BaseProvider<Object>> _allDependencies() sync* {
    yield _first;
  }

  @override
  BaseProvider1State<First, Res, BaseProvider1<First, Res>> createState();
}

abstract class BaseProvider1State<First, Res,
    T extends BaseProvider1<First, Res>> extends BaseProviderState<Res, T> {
  ProviderListenerState<First> _firstDependencyState;
  ProviderListenerState<First> get firstDependencyState {
    return _firstDependencyState;
  }

  @override
  void _initDependencies(
    List<BaseProviderState<Object, BaseProvider<Object>>> dependenciesState,
  ) {
    super._initDependencies(dependenciesState);
    _firstDependencyState =
        dependenciesState.first as ProviderListenerState<First>;
  }
}