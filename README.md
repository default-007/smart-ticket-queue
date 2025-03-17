# Smart Ticketing Flutter Frontend

## Overview

The frontend component of the Smart Ticketing System is a cross-platform mobile application built with Flutter. It provides intuitive interfaces for tickets, agent management, SLA monitoring, and more.

## Key Features

- 🔐 **User Authentication**: Secure login and registration with JWT authentication
- 📱 **Role-specific Dashboards**: Customized experiences for admins, agents, and users
- 🎫 **Ticket Management**: Create, view, and manage tickets with comprehensive filters
- 📊 **Performance Analytics**: Dashboards for monitoring SLA compliance and workload
- 👥 **Agent Management**: Status tracking and workload visualization
- 🔄 **Real-time Updates**: Live notifications via WebSockets
- 📆 **Shift Management**: Schedule and manage agent shifts and breaks

## Project Structure

```
lib/
│
├── config/                     # Configuration files
│   ├── api_config.dart         # API endpoint configuration
│   └── theme.dart              # Application theme
│
├── models/                     # Data models
│   ├── agent.dart              # Agent model
│   ├── ticket.dart             # Ticket model
│   ├── notification_item.dart  # Notification model
│   ├── shift.dart              # Shift model
│   ├── sla.dart                # SLA model
│   ├── user.dart               # User model
│   └── workload.dart           # Workload model
│
├── providers/                  # State management
│   ├── auth_provider.dart      # Authentication state
│   ├── ticket_provider.dart    # Ticket management state
│   ├── agent_provider.dart     # Agent management state
│   ├── notification_provider.dart # Notification state
│   ├── shift_provider.dart     # Shift management state
│   ├── sla_provider.dart       # SLA monitoring state
│   └── workload_provider.dart  # Workload analysis state
│
├── screens/                    # UI Screens
│   ├── auth/                   # Authentication screens
│   ├── dashboard/              # Dashboard screens
│   ├── tickets/                # Ticket management screens
│   ├── agents/                 # Agent management screens
│   ├── profile/                # User profile screens
│   ├── shifts/                 # Shift management screens
│   ├── sla/                    # SLA monitoring screens
│   └── workload/               # Workload analysis screens
│
├── services/                   # API and service layer
│   ├── api_service.dart        # Base API service
│   ├── auth_service.dart       # Authentication service
│   ├── ticket_service.dart     # Ticket service
│   ├── agent_service.dart      # Agent service
│   ├── notification_service.dart # Notification service
│   └── shift_service.dart      # Shift management service
│
├── utils/                      # Helper utilities
│   ├── logger.dart             # Logging utility
│   └── validators.dart         # Form validation
│
└── widgets/                    # Reusable UI components
    ├── agents/                 # Agent-related widgets
    ├── tickets/                # Ticket-related widgets
    ├── common/                 # Shared widgets
    ├── notifications/          # Notification widgets
    └── sla/                    # SLA-related widgets
```

## Key Screens

### Authentication

- Login Screen
- Registration Screen

### Dashboards

- Admin Dashboard: Overview of system performance, recent activity
- Agent Dashboard: Current workload, assigned tickets, shift status

### Ticket Management

- Ticket List: Filterable list of tickets with status indicators
- Ticket Detail: Comprehensive view of ticket information
- Create Ticket: Form for creating new support tickets

### Agent Management

- Agent List: Overview of all agents with status indicators
- Agent Form: Create/edit agent details and skills

### SLA Monitoring

- SLA Dashboard: Performance metrics and compliance rates
- SLA Configuration: Customize SLA parameters by priority and category

### Workload Management

- Workload Dashboard: Visualization of agent workloads and team capacities
- Workload Optimization: Tools for balancing and optimizing assignments

### Shift Management

- Shift Calendar: Schedule view of agent shifts
- Shift Detail: Current shift status with break management
- Break Scheduling: Interface for planning agent breaks

## State Management with Riverpod

The application uses Riverpod for state management, which provides:

- Predictable state updates
- Separation of business logic from UI
- Efficient rebuilds for optimal performance
- Testable and maintainable code structure

Examples of providers include:

- `authProvider`: Manages authentication state
- `ticketProvider`: Handles ticket data and operations
- `agentProvider`: Manages agent information
- `slaProvider`: Tracks SLA metrics and configurations
- `workloadProvider`: Analyzes and optimizes workload distribution

## API Integration

The frontend communicates with the backend through a comprehensive API layer:

- `ApiService`: Base service with interceptors for authentication and error handling
- Service-specific classes for domain operations (tickets, agents, etc.)
- WebSocket integration for real-time updates

## Real-time Features

The application includes real-time capabilities through Socket.IO:

- Instant notifications for ticket updates
- Live status changes for agents
- Real-time SLA breach alerts
- Immediate workload rebalancing notifications

## Local Storage

Secure local data persistence for:

- Authentication tokens
- User preferences
- Offline operation support

## Charts and Visualizations

The application uses FL Chart for data visualization:

- SLA compliance trends
- Workload distribution charts
- Team capacity visualizations
- Performance metrics graphs

## Setup and Development

### Prerequisites

- Flutter SDK (v3.10+)
- Dart SDK
- Android Studio or VS Code
- Xcode (for iOS development)

### Installation

1. Install Flutter dependencies

```bash
flutter pub get
```

2. Generate JSON serialization code

```bash
dart run build_runner build --delete-conflicting-outputs
```

3. Configure API endpoints in `lib/config/api_config.dart`

4. Run the application

```bash
flutter run
```

### Environment Configuration

Configure environment-specific settings for development, staging, and production:

- Android: Use `10.0.2.2` for emulator, local IP for physical devices
- iOS: Use `localhost` for simulator, local IP for physical devices

## Performance Optimization

- Lazy loading for list screens
- Caching strategies for API responses
- Debounced API calls for search/filter
- Efficient widget rebuilds with Riverpod selectors
- Image optimization and caching

## Future Improvements

- Offline support with local database
- Biometric authentication
- Push notifications
- Dark mode theme
- Localization and internationalization
- Advanced filtering and searching
- More comprehensive analytics dashboards
- Enhanced visualization components

## License

MIT License
