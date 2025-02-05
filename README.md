# Smart Ticketing System

## Overview

Smart Ticketing is a comprehensive ticketing management system designed to streamline support and service desk operations. The application provides a robust platform for tracking, managing, and resolving tickets across different departments and roles.

## Features

### Backend (Node.js/Express)

- User Authentication & Authorization
- Ticket Management
- Agent Management
- Service Level Agreement (SLA) Tracking
- Real-time Notifications
- WebSocket Integration
- Automated Ticket Queue Processing
- Role-based Access Control

### Frontend (Flutter)

- Responsive Mobile Application
- State Management with Riverpod
- Role-based Dashboards (Admin, Agent, User)
- Ticket Creation and Tracking
- Real-time Notifications
- SLA Monitoring
- Agent Status Management

## Technology Stack

### Backend

- Node.js
- Express.js
- MongoDB
- Mongoose
- Socket.IO
- JSON Web Token (JWT)
- WebSocket

### Frontend

- Flutter
- Dart
- Riverpod (State Management)
- Dio (HTTP Requests)
- Socket.IO Client
- Go Router

## Prerequisites

### Backend

- Node.js (v16+)
- MongoDB (v4.4+)
- npm or yarn

### Frontend

- Flutter SDK (v3.10+)
- Dart SDK
- Android Studio or VS Code
- Xcode (for iOS development)

## Setup Instructions

### Backend Setup

1. Clone the repository

```bash
git clone https://github.com/default-007/smart-ticket-queue.git
cd smart-ticketing/backend
```

2. Install dependencies

```bash
npm install
```

3. Create a `.env` file in the root directory with the following variables:

```
MONGODB_URI=mongodb://localhost:27017/smart_ticketing
JWT_SECRET=your_jwt_secret
PORT=5000
CLIENT_URL=http://localhost:3000
```

4. Start the development server

```bash
npm run dev
```

### Frontend Setup

1. Navigate to the frontend directory

```bash
cd ../frontend
```

2. Get Flutter dependencies

```bash
flutter pub get
```

3. Configure API Endpoint

- Open `lib/config/api_config.dart`
- Update base URLs for Android, iOS, and other platforms

4. Run the application

```bash
# For Android
flutter run -d android

# For iOS
flutter run -d ios
```

## Environment Configuration

### Development

- Use `10.0.2.2` for Android Emulator
- Use `localhost` for iOS Simulator
- Use your local IP for physical devices

### Production

- Configure appropriate base URLs in `api_config.dart`
- Set up environment-specific `.env` files

## Testing

### Backend Tests

```bash
npm test
```

### Frontend Tests

```bash
flutter test
```

## Deployment

### Backend Deployment

- Deploy to cloud platforms like Heroku, AWS, or DigitalOcean
- Ensure MongoDB is configured
- Set environment variables

### Frontend Deployment

- Generate release builds for Android and iOS
- Publish to Google Play Store and Apple App Store

## Contributing

1. Fork the repository
2. Create a new branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add some amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## License

Distributed under the MIT License. See `LICENSE` for more information.

## Contact

Brian Otieno - brianokola@gmail.com

Project Link: [https://github.com/default-007/smart-ticket-queue](https://github.com/yourusername/smart-ticket-queue)
