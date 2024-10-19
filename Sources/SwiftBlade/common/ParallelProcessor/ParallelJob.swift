//
//  ParallelJob.swift
//  SwiftBlade
//
//  Created by Aris Koxaras on 19/10/24.
//

/**
 A protocol that represents a parallelizable job that operates on items of a specific type in an actor-safe environment.

 Types conforming to this protocol define the lifecycle of items through various stages of parallel job execution, including preparation, queueing, starting, processing, and handling failure scenarios.

 The `ParallelJob` protocol is generic over an associated type `Item` which must conform to `Sendable`, ensuring thread safety when used in concurrent environments.

 - Note: Since `ParallelJob` inherits from `Actor`, all methods and properties are automatically actor-isolated, ensuring safety in concurrent executions.

 ### Associated Types
 - `Item`: The type of items processed by this job, which must conform to `Sendable`.

 ### Properties
 - `canStart`: A computed property that indicates whether the job can start processing items. Typically used as a gatekeeper to check preconditions before the job begins.
 - `items`: The items processed by this job

 ### Methods
 - `process(_:)`: The core processing function that operates asynchronously on an item and may throw errors.
*/

protocol ParallelJob: Actor {
    associatedtype Item: Sendable

    var canStart: Bool { get }
    var items: [Item] { get }
    func process(_ item: Item) async throws
}
