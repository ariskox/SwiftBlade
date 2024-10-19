//
//  ParallelJob.swift
//  SwiftBlade
//
//  Created by Aris Koxaras on 19/10/24.
//

/**
 A protocol that represents a parallelizable job that operates on elements of a specific type in an actor-safe environment.

 Types conforming to this protocol define the lifecycle of elements through various stages of parallel job execution, including preparation, queueing, starting, processing, and handling failure scenarios.

 The `ParallelJob` protocol is generic over an associated type `Element` which must conform to `Sendable`, ensuring thread safety when used in concurrent environments.

 - Note: Since `ParallelJob` inherits from `Actor`, all methods and properties are automatically actor-isolated, ensuring safety in concurrent executions.

 ### Associated Types
 - `Element`: The type of elements processed by this job, which must conform to `Sendable`.

 ### Properties
 - `canStart`: A computed property that indicates whether the job can start processing elements. Typically used as a gatekeeper to check preconditions before the job begins.

 ### Methods
 - `getElement(at:)`: Retrieves an element at a specified index. Return nil to to stop
 - `willQueue(_:)`: Prepares an element before it is queued for processing. This can be used to modify or validate the element.
 - `willStart(_:)`: Prepares an element right before it starts processing. This can be used to perform last-minute modifications or checks.
 - `process(_:)`: The core processing function that operates asynchronously on an element and may throw errors.
 - `failed(_:)`: Handles an element that failed to process, typically to log errors, retry, or perform corrective measures.
*/

protocol ParallelJob: Actor {
    associatedtype Element: Sendable
    
    var canStart: Bool { get }
    func getElement(at i: Int) -> Element?
    func willQueue(_ element: Element) -> Element
    func willStart(_ element: Element) -> Element
    func process(_ element: Element) async throws -> Element
    func failed(_ element: Element) -> Element
}
