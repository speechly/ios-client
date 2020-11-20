import NIO

/// A protocol that defines methods for making succeeded and failed futures.
public protocol Promisable {
    /// Creates a new succeeded future with value `value`.
    ///
    /// - Parameter value: The value to wrap in the future
    /// - Returns: An `EventLoopFuture` that always succeeds with `value`.
    func makeSucceededFuture<T>(_ value: T) -> EventLoopFuture<T>

    /// Creates a new failed future with error `error`.
    ///
    /// - Parameter error: The error to wrap in the future
    /// - Returns: An `EventLoopFuture` that always fails with `error`.
    func makeFailedFuture<T>(_ error: Error) -> EventLoopFuture<T>
}
