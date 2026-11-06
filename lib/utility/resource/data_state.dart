/// Sealed class representing the result of a local or async operation.
sealed class DataState<T> {
  final T? data;
  final String? message;
  final Exception? exception;
  final int? statusCode;

  const DataState({
    this.data,
    this.message,
    this.exception,
    this.statusCode,
  });

  /// True if the operation succeeded.
  bool get isSuccess => this is DataStateSuccess<T>;

  /// True if the operation failed.
  bool get isError => this is DataStateError<T>;
}

/// Represents a successful data state holding data of type [T].
class DataStateSuccess<T> extends DataState<T> {
  const DataStateSuccess(T data) : super(data: data);

  @override
  T get data => super.data as T;
}

/// Represents an error state holding a user-friendly [message],
/// optional underlying [exception], and optional [statusCode].
class DataStateError<T> extends DataState<T> {
  const DataStateError(
    String message, {
    super.exception,
    super.statusCode,
  }) : super(
          message: message,
        );

  @override
  String get message => super.message ?? 'Terjadi kesalahan';
}
