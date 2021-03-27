<h1 align="center">
<a href="https://www.speechly.com/?utm_source=github&utm_medium=ios-client&utm_campaign=header"><img src="https://www.speechly.com/images/logo.png" height="100" alt="Speechly"></a>
</h1>
<h2 align="center">
Complete your touch user interface with voice
</h2>

[Speechly website](https://www.speechly.com/?utm_source=github&utm_medium=ios-client&utm_campaign=header)&nbsp;&nbsp;&nbsp;|&nbsp;&nbsp;&nbsp;[Docs](https://www.speechly.com/docs/?utm_source=github&utm_medium=ios-client&utm_campaign=header)&nbsp;&nbsp;&nbsp;|&nbsp;&nbsp;&nbsp;[Blog](https://www.speechly.com/blog/?utm_source=github&utm_medium=ios-client&utm_campaign=header)

# iOS client for Speechly SLU API

![Release build](https://github.com/speechly/ios-client/workflows/Release%20build/badge.svg)
[![License](http://img.shields.io/:license-mit-blue.svg)](LICENSE)

This repository contains the source code for the iOS client for [Speechly](https://www.speechly.com/?utm_source=github&utm_medium=ios-client&utm_campaign=text) SLU API. Speechly allows you to easily build applications with voice-enabled UIs.

## Usage

### Swift package dependency

The client is distributed using [Swift Package Manager](https://swift.org/package-manager/), so you can use it by adding it as a dependency to your `Package.swift`:

```swift
// swift-tools-version:5.3

import PackageDescription

let package = Package(
    name: "MySpeechlyApp",
    dependencies: [
        .package(name: "speechly-ios-client", url: "https://github.com/speechly/ios-client.git", from: "0.1.0"),
    ],
    targets: [
        .target(
            name: "MySpeechlyApp",
            dependencies: []),
        .testTarget(
            name: "MySpeechlyAppTests",
            dependencies: ["MySpeechlyApp"]),
    ]
)
```

And then running `swift package resolve`.

### Xcode package dependency

If you are using Xcode, check out the [official tutorial for adding package dependencies to your app](https://developer.apple.com/documentation/xcode/adding_package_dependencies_to_your_app).

### Client usage

The client exposes methods for starting and stopping the recognition, as well as a delegate protocol to implement for receiving recognition results:

```swift
import Foundation
import Speechly

class SpeechlyManager {
    let client: SpeechClient

    public init() {
        client = try! SpeechClient(
            // Specify your Speechly application's identifier here.
            appId: UUID(uuidString: "your-speechly-app-id")!,

            // Specify your Speechly application's language here.
            language: .enUS
        )

        client.delegate = self
    }

    public func start() {
        // Use this to unmute the microphone and start recognising user's voice input.
        // You can call this when e.g. a button is pressed.
        client.start()
    }

    public func stop() {
        // Use this to mute the microphone and stop recognising user's voice input.
        // You can call this when e.g. a button is depressed.
        client.stop()
    }
}

// Implement the `Speechly.SpeechClientDelegate` for reacting to recognition results.
extension SpeechlyManager: SpeechClientDelegate {
    // (Optional) Use this method for telling the user that recognition has started.
    func speechlyClientDidStart(_: SpeechClientProtocol) {
        print("Speechly client has started an audio stream!")
    }

    // (Optional) Use this method for telling the user that recognition has finished.
    func speechlyClientDidStop(_: SpeechClientProtocol) {
        print("Speechly client has finished an audio stream!")
    }

    // Use this method for receiving recognition results.
    func speechlyClientDidUpdateSegment(_ client: SpeechClientProtocol, segment: SpeechSegment) {
        print("Received a new recognition result from Speechly!")

        // What the user wants the app to do, (e.g. "book" a hotel).
        print("Intent:", segment.intent)

        // How the user wants the action to be taken, (e.g. "in New York", "for tomorrow").
        print("Entities:", segment.entities)

        // The text transcript of what the user has said.
        // Use this to communicate to the user that your app understands them.
        print("Transcripts:", segment.transcripts)
    }
}
```

Check out the [ios-repo-filtering](https://github.com/speechly/ios-repo-filtering) repository for a demo app built using this client.

## Documentation

Check out [official Speechly documentation](https://docs.speechly.com/client-libraries/ios/) for tutorials and guides on how to use this client.

You can also find the [API documentation in the repo](docs/Home.md).

## Contributing

If you want to fix a bug or add new functionality, feel free to open an issue and start the discussion. Generally it's much better to have a discussion first, before submitting a PR, since it eliminates potential design problems further on.

### Requirements

- Swift 5.3+
- Xcode 12+
- Make
- swift-doc

Make sure you have Xcode and command-line tools installed. The rest of tools can be installed using e.g. Homebrew:

```sh
brew install swift make swiftdocorg/formulae/swift-doc
```

### Building the project

You can use various Make targets for building the project. Feel free to check out [the Makefile](./Makefile), but most commonly used tasks are:

```sh
# Install dependencies, run tests, build release version and generate docs.
# Won't do anything if everything worked fine and nothing was changed in source code / package manifest.
make all

# Cleans the build directory, will cause `make all` to run stuff again.
make clean
```

## About Speechly

Speechly is a developer tool for building real-time multimodal voice user interfaces. It enables developers and designers to enhance their current touch user interface with voice functionalities for better user experience. Speechly key features:

#### Speechly key features

- Fully streaming API
- Multi modal from the ground up
- Easy to configure for any use case
- Fast to integrate to any touch screen application
- Supports natural corrections such as "Show me red – i mean blue t-shirts"
- Real time visual feedback encourages users to go on with their voice
