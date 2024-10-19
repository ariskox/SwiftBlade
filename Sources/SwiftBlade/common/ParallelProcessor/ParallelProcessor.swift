//
//  ParallelProcessor.swift
//  SwiftBlade
//
//  Created by Aris Koxaras on 19/10/24.
//

import Foundation
import SwiftUI

/**
 An actor responsible for managing and processing jobs concurrently. This class uses Swift's concurrency features to run multiple jobs in parallel. It listens for system termination events and handles job cancellation accordingly.

 ### Type Parameters:
 - `Job`: A type conforming to `ParallelJob` protocol that defines the units of work to be processed concurrently.

 ### Inheritance:
 `ParallelProcessor` inherits from `NSObject`.

 ### Properties:
 - `task`: A `Task` that handles the concurrent execution of jobs. It can be canceled if necessary.
 - `job`: The job to be processed, which conforms to the `ParallelJob` protocol.
 - `parallelCompressions`: The number of parallel jobs allowed to run simultaneously. Defaults to the number of available processors minus one, or 2 if fewer processors are available.

 ### Initializer:
 - `init(concurrency: Int? = nil, job: Job)`: Initializes the `ParallelProcessor` with a specific concurrency level (number of parallel jobs). If `concurrency` is not specified, it defaults to the number of available processor cores minus one or 2, whichever is greater. The job to be processed is passed as the `job` parameter.

   - Parameters:
     - `concurrency`: An optional integer specifying the number of concurrent tasks to be processed. Defaults to system processor count - 1 or 2 if fewer processors are available.
     - `job`: An instance of a type conforming to `ParallelJob`, representing the work to be processed.

 ### Methods:

 - `cancel()`: Cancels the currently running task, if any.

   Cancels the job processing task if it is running. This method is useful for stopping the processing in case of a cancellation request from the user or the system.

 - `start() -> AsyncStream<JobStatus<Job.Element>>`: Starts processing the jobs concurrently and returns an `AsyncStream` that emits `JobStatus` events as the job elements are queued, processed, and completed.

   - Returns: An `AsyncStream` that emits updates on the status of each job element during execution.

   This method initializes a task that processes job elements concurrently based on the specified concurrency level. It creates a `TaskGroup` to manage parallel processing and ensures the task is only started once. The method yields different statuses (`queued`, `processing`, `done`) as the job progresses.
*/

actor ParallelProcessor<Job: ParallelJob>: NSObject {
    private var task: Task<Void, Error>?
    private var job: Job
    private let parallelCompressions: Int

    #if os(macOS)
    private let willTerminateNotificationName = NSApplication.willTerminateNotification
    #endif

    #if os(iOS)
    private let willTerminateNotificationName = UIApplication.willTerminateNotification
    #endif

    init(concurrency: Int? = nil, job: Job) {
        // Calculate number of parallel compressions
        parallelCompressions = concurrency ?? max(ProcessInfo.processInfo.activeProcessorCount - 1, 2)

        self.job = job

        super.init()

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(applicationWillTerminate),
            name: willTerminateNotificationName,
            object: nil
        )
    }

    func cancel() {
        task?.cancel()
    }

    func start() -> AsyncStream<JobStatus<Job.Element>> {
        assert(self.task == nil, "Cannot start task twice")

        return AsyncStream { continuation in
            self.task = Task(priority: .utility) {

                defer { continuation.finish() }

                guard await job.canStart else {
                    return
                }

                try await withThrowingTaskGroup(of: Void.self) { group in

                    var j = 0
                    while let element = await job.getElement(at: j) {
                        continuation.yield(.queued(await job.willQueue(element)))
                        j += 1
                        await Task.yield()
                    }

                    var i = 0
                    while i < parallelCompressions, let element = await job.getElement(at: i) {
                        try Task.checkCancellation()

                        group.addTask {
                            try Task.checkCancellation()
                            continuation.yield(.processing(await self.job.willStart(element)))

                            let new = try await self.job.process(element)
                            continuation.yield(.done(new))
                        }

                        i += 1
                    }

                    while let element = await job.getElement(at: i), let _ = try await group.next() {
                        try Task.checkCancellation()

                        group.addTask {
                            try Task.checkCancellation()
                            continuation.yield(.processing(await self.job.willStart(element)))

                            let new = try await self.job.process(element)
                            continuation.yield(.done(new))
                        }

                        i += 1
                    }
                }
            }
        }
    }

    @objc nonisolated private func applicationWillTerminate() {
        Task {
            await cancel()
        }
    }
}
