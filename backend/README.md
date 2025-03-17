# Smart Ticketing Backend

## Overview

The backend component of the Smart Ticketing System provides a comprehensive API and service layer for ticket management, user authentication, SLA tracking, and real-time communication.

## Key Features

- 🔐 **Authentication & Authorization**: Secure JWT-based authentication with role-based permissions
- 📋 **Ticket Management**: Full lifecycle handling from creation to resolution
- ⏱️ **SLA Tracking**: Automated monitoring of response and resolution time commitments
- 🔔 **Real-time Notifications**: WebSocket-based instant notifications
- 👥 **Agent Management**: Status tracking, workload balancing, and skill matching
- 📊 **Analytics**: Performance metrics for tickets, agents, and SLAs
- 📅 **Shift Management**: Agent shift scheduling and break management

## Project Structure

```
src/
│
├── config/                     # Configuration files
│   ├── database.js             # Database connection setup
│   └── permissions.js          # Role-based permissions
│
├── controllers/                # Request handlers
│   ├── authController.js       # Authentication endpoints
│   ├── ticketController.js     # Ticket management endpoints
│   ├── agentController.js      # Agent management endpoints
│   ├── slaController.js        # SLA configuration endpoints
│   ├── workloadController.js   # Workload management endpoints
│   └── notificationController.js # Notification endpoints
│
├── middleware/                 # Express middleware
│   ├── auth.js                 # Authentication middleware
│   ├── checkPermission.js      # Permission validation
│   └── errorHandler.js         # Centralized error handling
│
├── models/                     # Mongoose models
│   ├── User.js                 # User model
│   ├── Ticket.js               # Ticket model
│   ├── Agent.js                # Agent model
│   ├── SLAConfig.js            # SLA configuration model
│   └── Notification.js         # Notification model
│
├── routes/                     # API route definitions
│   ├── authRoutes.js           # Authentication routes
│   ├── ticketRoutes.js         # Ticket management routes
│   ├── agentRoutes.js          # Agent management routes
│   └── slaRoutes.js            # SLA management routes
│
├── services/                   # Business logic services
│   ├── ticketService.js        # Ticket processing logic
│   ├── agentService.js         # Agent management logic
│   ├── slaService.js           # SLA monitoring and reporting
│   ├── notificationService.js  # Notification dispatch
│   ├── websocketService.js     # Real-time communication
│   └── schedulerService.js     # Automated tasks and scheduling
│
└── utils/                      # Helper functions
    ├── asyncHandler.js         # Async error handling
    └── logger.js               # Logging utility
```

## API Endpoints

### Authentication

- `POST /api/auth/register` - Register a new user
- `POST /api/auth/login` - User login
- `GET /api/auth/me` - Get current user info
- `PUT /api/auth/profile` - Update user profile
- `PUT /api/auth/change-password` - Change password

### Tickets

- `GET /api/tickets` - Get all tickets (filtered by various parameters)
- `POST /api/tickets` - Create a new ticket
- `GET /api/tickets/:id` - Get a specific ticket
- `PUT /api/tickets/:id/status` - Update ticket status
- `GET /api/tickets/queue` - Get tickets in queue
- `POST /api/tickets/process-queue` - Process the ticket queue
- `PUT /api/tickets/:id/resolve-escalation` - Resolve ticket escalation

### Agents

- `GET /api/agents` - Get all agents
- `GET /api/agents/available` - Get available agents
- `GET /api/agents/user/:userId` - Get agent by user ID
- `PUT /api/agents/:id/status` - Update agent status
- `PUT /api/agents/:id/shift` - Update agent shift
- `POST /api/agents/:agentId/claim/:ticketId` - Agent claims a ticket

### SLA Management

- `GET /api/sla/metrics` - Get SLA performance metrics
- `GET /api/sla/config` - Get SLA configurations
- `PUT /api/sla/config/:priority/:category` - Update SLA configuration
- `GET /api/sla/check/:ticketId` - Check SLA status for a ticket

### Workload Management

- `GET /api/workload/metrics` - Get workload metrics
- `GET /api/workload/agents` - Get agent workloads
- `GET /api/workload/teams` - Get team capacities
- `POST /api/workload/rebalance` - Rebalance workload
- `GET /api/workload/predictions` - Get workload predictions
- `POST /api/workload/optimize` - Optimize ticket assignments

### Notifications

- `GET /api/notifications/unread` - Get unread notifications
- `PUT /api/notifications/:notificationId/read` - Mark notification as read
- `PUT /api/notifications/mark-all-read` - Mark all notifications as read

### Shifts

- `POST /api/shifts/start` - Start a shift
- `POST /api/shifts/:shiftId/end` - End a shift
- `POST /api/shifts/:shiftId/breaks` - Schedule a break
- `GET /api/shifts/agent/:agentId` - Get agent shifts

## Setup & Development

### Prerequisites

- Node.js (v16+)
- MongoDB (v4.4+)
- npm or yarn

### Installation

1. Install dependencies

```bash
npm install
```

2. Set up environment variables

```
MONGODB_URI=mongodb://localhost:27017/smart_ticketing
JWT_SECRET=your_jwt_secret_key
PORT=5000
CLIENT_URL=http://localhost:3000
```

3. Start development server

```bash
npm run dev
```

### Error Handling

The backend implements a centralized error handling system that:

- Formats error responses consistently
- Logs errors with appropriate severity levels
- Handles common error types (validation, authentication, etc.)
- Provides detailed debugging info in development mode

### Security Features

- JWT authentication with token refresh mechanism
- Password hashing with bcrypt
- Role-based access control
- Input validation and sanitization
- Rate limiting for API endpoints
- HTTP security headers

## Performance Optimizations

- Efficient MongoDB queries with proper indexing
- Connection pooling for database operations
- Targeted data selection to minimize payload size
- Pagination for list endpoints
- Caching strategies for frequently accessed data
- Bulk operations for batch processing

## Deployment Considerations

- Use environment-specific configurations
- Implement proper error handling and logging
- Containerize the application for consistent deployment
- Set up health checks and monitoring
- Implement CI/CD pipelines

## Future Improvements

1. Microservices architecture for better scalability
2. Advanced caching strategies
3. Enhanced analytics and reporting capabilities
4. Machine learning for ticket classification and routing
5. Third-party integrations (email, chat, etc.)

## License

MIT License
