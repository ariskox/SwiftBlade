//
//  Process+RunAsync.swift
//  SwiftBlade
//
//  Created by Aris Koxaras on 18/10/24.
//

import Foundation

#if os(macOS)
public extension Process {

    /// Asynchronously runs a command-line process with the specified executable URL and arguments, returning the process outputs (standard, error).
    /// If the process terminates with a non-zero status code, it throws an error.
    ///
    /// - Parameters:
    ///   - url: The `URL` of the executable to run.
    ///   - arguments: An optional array of `String` arguments to pass to the executable. Defaults to `nil`.
    /// - Returns: An `Outputs` struct containing the standard output and error output of the process.
    /// - Throws:
    ///   - `ProcessError.abnormalTermination(code:outputs:)` if the process terminates with a non-zero status code.
    ///   - Any other error encountered during the process execution.
    /// - Important: If the task is cancelled, the process is immediately terminated.
    /// - Note: The function uses a `TaskCancellationHandler` to handle process termination on cancellation.
    ///
    /// - Example:
    /// ```swift
    /// let url = URL(fileURLWithPath: "/usr/bin/env")
    /// let result = try await runAsync(url: url, arguments: ["echo", "Hello, world!"])
    /// print(result.standard) // Outputs "Hello, world!"
    /// ```
    ///
    static func runAsync(url: URL, arguments: [String]? = nil) async throws -> Outputs {
        let outputPipe = Pipe()
        let errorPipe = Pipe()

        let process = Process()
        process.executableURL = url
        process.arguments = arguments
        process.standardOutput = outputPipe
        process.standardError = errorPipe

        return try await withTaskCancellationHandler {
            do {
                try process.run()
                process.waitUntilExit()
                let status = process.terminationStatus
                let result = Outputs(
                    standard: outputPipe.outputString,
                    error: errorPipe.outputString
                )
                guard status == 0 else {
                    throw ProcessError.abnormalTermination(code: Int(status), outputs: result)
                }
                return result

            } catch {
                process.terminate()
                throw error
            }

        } onCancel: {
            process.terminate()
        }
    }

    /// An enumeration that represents errors that can occur during process execution.
    enum ProcessError: Error {
        /// Indicates that the process terminated abnormally.
        ///
        /// - Parameters:
        ///   - code: The exit code of the process.
        ///   - outputs: The outputs captured from the process, including standard output and error output.
        case abnormalTermination(code: Int, outputs: Outputs)
    }

    /// A struct that encapsulates the outputs of a process execution.
    ///
    /// - Properties:
    ///   - standard: A `String` containing the standard output from the process.
    ///   - error: A `String` containing the error output from the process.
    /// - Conformance: This struct conforms to the `Sendable` protocol, allowing it to be safely used in concurrent contexts.
    struct Outputs: Sendable {
        let standard: String
        let error: String
    }
}

fileprivate extension Pipe {
    var outputString: String {
        let outputData = self.fileHandleForReading.readDataToEndOfFile()
        let output = String(decoding: outputData, as: UTF8.self).trimmingCharacters(in: .whitespacesAndNewlines)
        return output
    }
}

#endif
