//
//  JobStatus.swift
//  SwiftBlade
//
//  Created by Aris Koxaras on 19/10/24.
//

/// A generic enum representing the status of a job, which holds an associated value of type `Item`.
/// The `Item` type is constrained to be `Sendable`, ensuring thread safety.
///
/// The enum provides four possible states for a job:
/// - `queued`: The job is waiting to be processed.
/// - `processing`: The job is currently being processed.
/// - `done`: The job has completed successfully.
/// - `error`: The job encountered an error.
///
/// - Note: The `item` property allows access to the associated `Item` value in any of the states.

enum JobStatus<Item: Sendable> {
    case queued(Item)
    case processing(Item)
    case done(Item)
    case error(Item, Error)

    var element: Item {
        switch self {
        case .queued(let item),
             .processing(let item),
             .done(let item):
            return item
        case .error(let item, _):
            return item
        }
    }
}
