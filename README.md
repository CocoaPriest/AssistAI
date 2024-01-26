# AssistAI

AssistAI is a macOS application designed to enhance your productivity by indexing your files in background and enabling you to interact with them through a chat interface. It leverages the Retrieval-Augmented Generation (RAG) model to provide informative and context-aware responses. The backend functionality is powered by [BubbleAI](https://github.com/CocoaPriest/bubbleai/) endpoints.

## Features

-   **File Indexing:** AssistAI continuously monitors selected folders for changes, indexing new or modified files to keep the search database up-to-date.
-   **Chat Interface:** Interact with your indexed files through a chat interface, asking questions or retrieving information directly related to your documents.
-   **Settings Customization:** Configure which folders to index and manage other preferences through a user-friendly settings interface.

## How It Works

### Indexing Process

The core of AssistAI is the `Ingester` class, which is responsible for indexing the files. It watches for file changes in specified directories using a `FileWatcher` and processes files based on their extensions. When a new or modified file is detected, it's queued for uploading to the [BubbleAI](https://github.com/CocoaPriest/bubbleai/) backend, where it's indexed for future retrieval. The application supports indexing for PDF files by default, but this can be extended to include other file types.

### Chat Interface

The chat functionality is implemented in the `ChatView` SwiftUI view. Users can type messages or questions, which are then processed by the `ChatController`. The controller interacts with the BubbleAI backend to fetch relevant information or answers based on the indexed content.

### Backend Communication

AssistAI communicates with the [BubbleAI](https://github.com/CocoaPriest/bubbleai/) backend through the `NetworkService` class, which handles various network requests, including file ingestion, deletion, and chat queries. The backend endpoints are defined in the `BubbleEndpoint` enum, ensuring a structured and maintainable approach to API requests.

### User Interface

The application's user interface is designed to be minimalistic and intuitive. The main window, implemented in `AssistWindow`, provides a transparent, draggable interface for the chat functionality. Settings and logs can be accessed through the status bar menu, constructed in the `AppDelegate` class.

## Getting Started

To use AssistAI, clone the repository and open the project in Xcode. Before running the application, ensure you have access to the [BubbleAI backend](https://github.com/CocoaPriest/bubbleai/) and configure the necessary endpoints and authorization tokens in the `BubbleEndpoint` class.

### Prerequisites

-   macOS 10.15 or later
-   Xcode 12.0 or later

### Installation

1. Clone the repository:
    ```sh
    git clone https://github.com/CocoaPriest/AssistAI.git
    ```
2. Open `AssistAI.xcodeproj` in Xcode.
3. Build and run the application.

## Configuration

To customize which folders are indexed by AssistAI, navigate to the settings menu accessible from the status bar icon. Here, you can add or remove folders from the indexing process. Changes take effect immediately, with the application starting to index the new content or stopping the indexing of removed folders.

## Contributing

Contributions to AssistAI are welcome. Please feel free to fork the repository, make changes, and submit pull requests. For major changes, please open an issue first to discuss what you would like to change.

## License

Distributed under the MIT License. See `LICENSE` for more information.
