# Jeoparty App

A dynamic and interactive Flutter application for the Jeoparty game. This app supports two roles: **Host** (primary display for the game board) and **Player** (controller for buzzing and answering).

## ✨ Features

- **Real-time Synchronization:** Game state is synced across devices using WebSockets.
- **Dynamic Game Board:** Interactive grid for category and question selection.
- **Buzzer System:** High-performance buzzing logic with sound effects.
- **QR Code Pairing:** Seamlessly connect players to a game room using QR codes.
- **Premium Design:** Jeopardy-inspired aesthetics with custom fonts (`Gyparody`, `ITC Korinna`) and smooth animations.
- **Sound System:** Immersive sound effects and theme music.

## 🚀 Tech Stack

- **Framework:** [Flutter](https://flutter.dev/)
- **State Management:** [Riverpod](https://riverpod.dev/)
- **Networking:** [Dio](https://pub.dev/packages/dio)
- **WebSockets:** [Socket.io Client](https://pub.dev/packages/socket_io_client)
- **Audio:** [AudioPlayers](https://pub.dev/packages/audioplayers)

## 🛠️ Getting Started

### Prerequisites

- [Flutter SDK](https://docs.flutter.dev/get-started/install)
- A running instance of the [Jeoparty API](https://github.com/gustavo-de-assis/jeopardy_api)

### Installation

1. **Clone the repository**
2. **Install dependencies:**
   ```bash
   flutter pub get
   ```
3. **Configuration:**
   Update the `baseUrl` in `lib/services/api_service.dart` to point to your local API instance (usually `http://localhost:3000`).

### Running the App

```bash
# Run in debug mode
flutter run
```

## 📂 Project Structure

- `lib/models/`: Data structures for game entities.
- `lib/providers/`: Riverpod providers for state management.
- `lib/screens/`: UI screens for game flow (Lobby, Board, Buzzer, etc.).
- `lib/services/`: API, Socket, and Sound logic.
- `lib/widgets/`: Reusable UI components.

## 🎨 Design

The app uses custom typography and colors to replicate the classic game show experience.
- **Title Font:** Gyparody
- **Content Font:** ITC Korinna
- **Main Colors:** Deep Blue, Gold, and Silver Gradients.
