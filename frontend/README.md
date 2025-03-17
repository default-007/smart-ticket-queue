# Smart Ticketing System

## Overview

Smart Ticketing is a ticketing management system designed to streamline support and service desk operations. This full-stack application provides a robust platform for tracking, managing, and resolving tickets across different departments and roles.

![Smart Ticketing Logo](https://via.placeholder.com/150x50?text=SmartTicketing)

## Features

- **User Authentication & Authorization** with role-based access control
- **Comprehensive Ticket Management** with SLA tracking
- **Agent Workload Management** with optimized assignments
- **Real-time Notifications** via WebSockets
- **Service Level Agreement (SLA)** monitoring and compliance tracking
- **Shift Management** for agents with break scheduling
- **Performance Analytics** and reporting

## Technology Stack

### Backend

- **Server**: Node.js with Express.js
- **Database**: MongoDB with Mongoose
- **Authentication**: JWT (JSON Web Token)
- **Real-time**: Socket.IO for WebSockets
- **Task Scheduling**: Node-cron for automated tasks

### Frontend

- **Framework**: Flutter (cross-platform mobile application)
- **State Management**: Riverpod
- **Routing**: Go Router
- **HTTP Client**: Dio
- **Real-time**: Socket.IO Client
- **Charts & Visualization**: FL Chart

## Project Structure

The project is organized into two main components:

```
/
├── backend/                     # Node.js/Express backend
│   ├── src/                     # Backend source code
│   │   ├── config/              # Configuration files
│   │   ├── controllers/         # Request handlers
│   │   ├── middleware/          # Express middleware
│   │   ├── models/              # Mongoose models
│   │   ├── routes/              # API endpoints
│   │   ├── services/            # Business logic
│   │   └── utils/               # Helper functions
│   └── server.js                # Main entry point
│
└── frontend/                    # Flutter mobile application
    └── lib/                     # Frontend source code
        ├── config/              # App configuration
        ├── models/              # Data models
        ├── providers/           # State management
        ├── screens/             # UI screens
        ├── services/            # API services
        └── widgets/             # Reusable UI components
```

## Setup Instructions

### Prerequisites

- Node.js (v16+)
- MongoDB (v4.4+)
- Flutter SDK (v3.10+)
- Dart SDK
- Android Studio or VS Code
- Xcode (for iOS development)

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

3. Configure API Endpoint in `lib/config/api_config.dart`:

```dart
static String get baseUrl {
  if (Platform.isAndroid) {
    return 'http://10.0.2.2:5000/api';  // For Android Emulator
  } else if (Platform.isIOS) {
    return 'http://localhost:5000/api'; // For iOS Simulator
  }
  return 'http://your-local-ip:5000/api'; // For physical devices
}
```

4. Generate JSON serialization code

```bash
dart run build_runner build --delete-conflicting-outputs
```

5. Run the application

```bash
flutter run
```

## Key Features Explained

### Ticket Management

The system provides comprehensive ticket tracking from creation to resolution:

- **Ticket Creation**: Users can create tickets with priority, category, and due dates
- **Ticket Assignment**: Automatic or manual assignment to appropriate agents
- **SLA Tracking**: Automatic monitoring of response and resolution time commitments
- **Escalation**: Automatic escalation for SLA breaches
- **Status Updates**: Track ticket progress through the resolution lifecycle

### Agent Management

Efficiently manage agent workloads and availability:

- **Status Tracking**: Monitor agent availability (online, busy, offline)
- **Shift Management**: Schedule and track agent work hours
- **Break Management**: Plan and track agent breaks
- **Workload Balancing**: Evenly distribute tickets among available agents
- **Skills-based Assignment**: Route tickets to agents with appropriate skills

### Real-time Notifications

Stay informed with immediate updates:

- **SLA Alerts**: Get notified when tickets approach SLA breach
- **Assignment Notifications**: Agents are alerted when new tickets are assigned
- **Status Updates**: All relevant parties notified on ticket status changes
- **WebSocket Integration**: Real-time updates across devices

## API Documentation

The backend provides a RESTful API with the following main endpoints:

- **Authentication**: `/api/auth`
- **Tickets**: `/api/tickets`
- **Agents**: `/api/agents`
- **SLA**: `/api/sla`
- **Workload**: `/api/workload`
- **Notifications**: `/api/notifications`
- **Shifts**: `/api/shifts`

For detailed API documentation, please refer to the API docs (coming soon).

## Future Roadmap

- **AI-powered Ticket Routing**: Implement machine learning for optimal assignment
- **Advanced Analytics Dashboard**: Enhanced reporting and insights
- **External Integrations**: APIs for connecting with other systems
- **Comprehensive Mobile Apps**: Native mobile experiences

## Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add some amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## License

Distributed under the MIT License. See `LICENSE` for more information.

## Contact

Brian Otieno - brianokola@gmail.com

Project Link: [https://github.com/default-007/smart-ticket-queue](https://github.com/default-007/smart-ticket-queue)
