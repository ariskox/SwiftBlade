//
//  Test.swift
//  SwiftBlade
//
//  Created by Aris Koxaras on 19/10/24.
//

import Testing
@testable import SwiftBlade
import Foundation

@MainActor
struct ParallerProcessorTests {

    @Test func testSuccessfulExecution() async throws {
        // Given
        let items = Array(1...1000)
        let job = MockJob(items: items)
        let processor = ParallelProcessor<MockJob>(job: job)
        var maxConcurrentTasks: Int = 0
        var currentTasks: Int = 0
        var signals = [JobStatus<Int>]()

        // When
        for await status in await processor.start() {
            switch status {
            case .processing:
                currentTasks += 1
                maxConcurrentTasks = max(maxConcurrentTasks, currentTasks)
            case .done:
                currentTasks -= 1
            default:
                break
            }
            signals.append(status)
        }

        // Then
        let expectedResult: [JobStatus<Int>] = items.flatMap { [.queued($0), .processing($0), .done($0) ] }

        #expect(Set(signals) == Set(expectedResult))
        #expect(await maxConcurrentTasks <= processor.parallelJobs)
    }

    @Test func testCancellation() async throws {
        // Given
        let items = Array(1...1000)
        let cancellationAfterDoneCount = 10
        let job = MockJob(items: items)
        let processor = ParallelProcessor<MockJob>(job: job)

        var queuedSignals = [JobStatus<Int>]()
        var processingSignals = [JobStatus<Int>]()
        var doneSignals = [JobStatus<Int>]()
        var errorSignals = [JobStatus<Int>]()

        // When
        for await status in await processor.start() {

            switch status {
            case .queued:
                queuedSignals.append(status)
            case .done:
                doneSignals.append(status)
            case .processing:
                processingSignals.append(status)
            case .error:
                errorSignals.append(status)
            }

            if doneSignals.count >= cancellationAfterDoneCount {
                await processor.cancel()
            }
        }

        // Then
        #expect(queuedSignals.count == items.count)
        #expect(doneSignals.count < items.count)
        #expect(doneSignals.count >= cancellationAfterDoneCount)
        #expect(processingSignals.count >= cancellationAfterDoneCount)
        #expect(errorSignals.count > 0)
    }
}

extension JobStatus<Int>: Equatable  {
    public static func == (lhs: JobStatus<Int>, rhs: JobStatus<Int>) -> Bool {
        switch (lhs, rhs) {
        case (.queued(let l), .queued(let r)):
            return l == r
        case (.processing(let l), .processing(let r)):
            return l == r
        case (.done(let l), .done(let r)):
            return l == r
        case (.error(let l, _), .error(let r, _)):
            return l == r
        default:
            return false
        }
    }
}

extension JobStatus<Int>: Hashable {
    public func hash(into hasher: inout Hasher) {
        switch self {
        case .queued(let items):
            hasher.combine(items)
        case .processing(let items):
            hasher.combine(items)
        case .done(let items):
            hasher.combine(items)
        case .error(let items, _):
            hasher.combine(items)
        }
    }
}
