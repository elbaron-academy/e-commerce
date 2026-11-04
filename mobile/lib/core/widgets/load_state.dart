import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'common.dart';

enum LoadStatus { loading, ready, failure }

class LoadState<T> extends Equatable {
  const LoadState({this.status = LoadStatus.loading, this.data, this.error});

  final LoadStatus status;
  final T? data;
  final Object? error;

  @override
  List<Object?> get props => [status, data, error];
}

/// Loads one thing (a page's data) and keeps the last good result on refresh errors.
class LoadCubit<T> extends Cubit<LoadState<T>> {
  LoadCubit(this._loader) : super(LoadState<T>());

  final Future<T> Function() _loader;

  Future<void> load({bool silent = false}) async {
    if (!silent && state.data == null) emit(LoadState<T>());
    try {
      final data = await _loader();
      if (!isClosed) emit(LoadState<T>(status: LoadStatus.ready, data: data));
    } catch (error) {
      if (isClosed) return;
      if (state.data != null) {
        emit(LoadState<T>(status: LoadStatus.ready, data: state.data, error: error));
      } else {
        emit(LoadState<T>(status: LoadStatus.failure, error: error));
      }
    }
  }
}

/// Builds loading / error / data states for a [LoadCubit].
class LoadView<C extends LoadCubit<T>, T> extends StatelessWidget {
  const LoadView({required this.builder, this.loading, super.key});

  final Widget Function(BuildContext context, T data) builder;
  final Widget? loading;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<C, LoadState<T>>(
      builder: (context, state) => switch (state.status) {
        LoadStatus.loading => loading ?? const Center(child: CircularProgressIndicator()),
        LoadStatus.failure => ErrorView(error: state.error!, onRetry: () => context.read<C>().load()),
        LoadStatus.ready => builder(context, state.data as T),
      },
    );
  }
}
