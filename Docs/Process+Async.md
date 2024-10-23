# Process+Async

The easy way to spawn processes on macOS.

## Usage 

```swift
let url = URL(fileURLWithPath: "/usr/bin/env")
let result = try await Process.runAsync(url: url, arguments: ["echo", "Hello, world!"])
print(result.standardOutput) // Outputs "Hello, world!"
print(result.standardError) // No errors, hopefully

```

## Cancellation

The process will be killed in the active task that runs it, is cancelled
