//
//  JobStatus.swift
//  SwiftBlade
//
//  Created by Aris Koxaras on 19/10/24.
//

/// A generic enum representing the status of a job, which holds an associated value of type `Element`.
/// The `Element` type is constrained to be `Sendable`, ensuring thread safety.
///
/// The enum provides four possible states for a job:
/// - `queued`: The job is waiting to be processed.
/// - `processing`: The job is currently being processed.
/// - `done`: The job has completed successfully.
/// - `error`: The job encountered an error.
///
/// - Note: The `element` property allows access to the associated `Element` value in any of the states.

enum JobStatus<Element: Sendable> {
    case queued(Element)
    case processing(Element)
    case done(Element)
    case error(Element)

    var element: Element {
        switch self {
        case .queued(let element),
             .processing(let element),
             .done(let element),
             .error(let element):
            return element
        }
    }
}
