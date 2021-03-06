//
//  Task.swift
//  Deferred
//
//  Created by Zachary Waldowski on 9/16/18.
//  Copyright © 2018-2019 Big Nerd Ranch. Licensed under MIT.
//

#if SWIFT_PACKAGE
import Deferred
#endif

/// An interface describing a thread-safe way for interacting with the result
/// of some work that may either succeed or fail at some point in the future.
///
/// A "task" is a superset of a future where the asynchronously-determined value
/// represents 1 or more exclusive states. These states can be abstracted over
/// by extensions on the task protocol. The future value is almost always the
/// `TaskResult` type, but many types conforming to `TaskProtocol` may exist.
///
/// - seealso: `FutureProtocol`
public protocol TaskProtocol: FutureProtocol where Value: Either {
    /// A type that represents the success of some asynchronous work.
    typealias Success = Value.Right

    /// A type that represents the failure of some asynchronous work.
    typealias Failure = Error

    /// Call some `body` closure if the task successfully completes.
    ///
    /// - parameter executor: A context for handling the `body`.
    /// - parameter body: A closure to be invoked when the result is determined.
    ///  * parameter value: The determined success value.
    /// - seealso: `FutureProtocol.upon(_:execute:)`
    func uponSuccess(on executor: Executor, execute body: @escaping(_ value: Success) -> Void)

    /// Call some `body` closure if the task fails.
    ///
    /// - parameter executor: A context for handling the `body`.
    /// - parameter body: A closure to be invoked when the result is determined.
    ///  * parameter error: The determined failure value.
    /// - seealso: `FutureProtocol.upon(_:execute:)`
    func uponFailure(on executor: Executor, execute body: @escaping(_ error: Failure) -> Void)

    /// Attempt to cancel the underlying work.
    ///
    /// An implementation should be a "best effort". By default, no cancellation
    /// is supported, and this method does nothing.
    ///
    /// There are several situations in which a valid implementation may not
    /// actually cancel:
    /// * The work has already completed.
    /// * The work has entered an uncancelable state.
    /// * An underlying task is not cancellable.
    func cancel()
}

// MARK: - Default implementation

public extension TaskProtocol {
    func cancel() {}
}

// MARK: - Conditional conformances

extension Future: TaskProtocol where Value: Either {
    /// Create a future having the same underlying task as `other`.
    public init<Wrapped: TaskProtocol>(resultFrom wrapped: Wrapped) where Wrapped.Success == Success {
        self = wrapped as? Future<Value> ?? wrapped.every(per: Value.init)
    }

    /// Create a future having the same underlying task as `other`.
    public init<Wrapped: FutureProtocol>(succeedsFrom wrapped: Wrapped) where Wrapped.Value == Success {
        self = wrapped.every(per: Value.init(right:))
    }

    /// Creates a future that is immediately filled with the result of calling `body` in the current context.
    @inlinable
    public init(catching body: () throws -> Success) {
        self.init(value: Value(catching: body))
    }

    /// Creates an future having already filled successfully with `value`.
    @inlinable
    public init(success value: Success) {
        self.init(value: Value(right: value))
    }

    /// Creates an future having already failed with `error`.
    @inlinable
    public init(failure error: Failure) {
        self.init(value: Value(left: error))
    }
}
