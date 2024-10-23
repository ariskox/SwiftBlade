# ParallelProcessor

To use the parallel processor, first create an actor that will do the actual job. The 'Item' can be anything. E.g. a filename, some data, etc.


```swift
actor Compressor: ParallelJob {
    var items: [Item]
    let canStart = true // This task can start always

    init(items: [Item]) {
        self.items = items
    }

    func process(_ item: Item) async throws {
        // do some work.
        // e.g. compress files
      
        // save it
    }
}
```

Then, create a function that will run the job

```swift
func compress() async {
    let data: [Items] = // ..........

    let job = Compressor(items: data)
    // Initialize the processor that will run 4 jobs in parallel
    let processor = ParallelProcessor<Compressor>(concurrency: 4, job: job)

    for await update in await processor.start() {
        switch update {
        case .queued(let item):
            // Update the UI
        case .processing(let item):
            // Update the UI
        case .done(let item):
            // Update the UI
        case .error(let item, let error):
            // Update the UI
        }
    }

    // All operations have been completed or cancelled if 'cancel()' has been called on the processor.
    print("done")
}
```


The result:


https://github.com/user-attachments/assets/d9a3633d-ac69-4a2a-be2c-745e73e0d11d




