import Foundation
import os.log

private let logger = Logger(subsystem: "sh.saqoo.jjstats", category: "FileWatcher")

final class FileWatcher: @unchecked Sendable {
    private var stream: FSEventStreamRef?
    private let paths: [String]
    private let callback: @Sendable () -> Void
    private let queue: DispatchQueue
    private var debounceWorkItem: DispatchWorkItem?
    private let debounceInterval: TimeInterval

    init(paths: [String], debounceInterval: TimeInterval = 1.0, callback: @escaping @Sendable () -> Void) {
        self.paths = paths
        self.callback = callback
        self.debounceInterval = debounceInterval
        self.queue = DispatchQueue(label: "com.jjstats.filewatcher", qos: .utility)
    }

    func start() {
        logger.info("Starting file watcher for paths: \(self.paths)")
        let pathsToWatch = paths as CFArray

        var context = FSEventStreamContext(
            version: 0,
            info: Unmanaged.passUnretained(self).toOpaque(),
            retain: nil,
            release: nil,
            copyDescription: nil
        )

        let flags = UInt32(
            kFSEventStreamCreateFlagUseCFTypes |
            kFSEventStreamCreateFlagFileEvents |
            kFSEventStreamCreateFlagNoDefer
        )

        stream = FSEventStreamCreate(
            nil,
            { (_, info, numEvents, eventPaths, _, _) in
                guard let info = info else { return }
                let watcher = Unmanaged<FileWatcher>.fromOpaque(info).takeUnretainedValue()
                if let paths = unsafeBitCast(eventPaths, to: NSArray.self) as? [String] {
                    for path in paths {
                        logger.info("FSEvent: \(path, privacy: .public)")
                    }
                }
                watcher.debouncedCallback()
            },
            &context,
            pathsToWatch,
            FSEventStreamEventId(kFSEventStreamEventIdSinceNow),
            0.5,  // latency in seconds
            flags
        )

        if let stream = stream {
            FSEventStreamSetDispatchQueue(stream, queue)
            FSEventStreamStart(stream)
        }
    }

    private func debouncedCallback() {
        debounceWorkItem?.cancel()

        let workItem = DispatchWorkItem { [weak self] in
            logger.info("Debounce complete, triggering callback")
            self?.callback()
        }
        debounceWorkItem = workItem

        queue.asyncAfter(deadline: .now() + debounceInterval, execute: workItem)
    }

    func stop() {
        debounceWorkItem?.cancel()
        debounceWorkItem = nil

        if let stream = stream {
            FSEventStreamStop(stream)
            FSEventStreamInvalidate(stream)
            FSEventStreamRelease(stream)
            self.stream = nil
        }
    }

    deinit {
        stop()
    }
}
