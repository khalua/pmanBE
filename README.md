# Property Management API

Rails 7.2 API-only backend for a property management application. Handles maintenance requests, vendor quoting, and tenant/manager workflows with JWT authentication and AI-powered chat.

## Tech Stack

- **Ruby on Rails 7.2** (API-only mode)
- **PostgreSQL**
- **JWT** authentication via `bcrypt`
- **Active Storage** for image attachments
- **Anthropic Claude API** for AI chat and summarization
- **Puma** web server

## Getting Started

### Prerequisites

- Ruby 3.x
- PostgreSQL
- Bundler

### Setup

```bash
bundle install
bin/rails db:create db:migrate
```

### Environment Variables

Create a `.env` file in the project root:

```
ANTHROPIC_API_KEY=your_key_here
JWT_SECRET=your_secret_here
```

### Run the Server

```bash
bin/rails server
```

## API Endpoints

### Authentication

| Method | Endpoint | Description |
|--------|----------|-------------|
| POST | `/api/register` | Register a new user |
| POST | `/api/login` | Log in and receive JWT |
| GET | `/api/me` | Get current user info |

### Maintenance Requests

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/api/maintenance_requests` | List all requests |
| GET | `/api/maintenance_requests/:id` | Get a single request |
| POST | `/api/maintenance_requests` | Create a request |
| PATCH | `/api/maintenance_requests/:id` | Update a request |
| POST | `/api/maintenance_requests/:id/assign_vendor` | Assign a vendor |

### Vendors & Quotes

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/api/vendors` | List vendors |
| GET | `/api/vendors/:id` | Get vendor details |
| POST | `/api/quotes` | Submit a quote |
| POST | `/api/quotes/:id/approve` | Approve a quote |
| POST | `/api/quotes/:id/reject` | Reject a quote |

### AI Chat

| Method | Endpoint | Description |
|--------|----------|-------------|
| POST | `/api/chat` | Chat with AI assistant |
| POST | `/api/summarize` | Summarize maintenance data |

### Other

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/health` | Health check |
| GET | `/quote` | Vendor portal (public) |

## User Roles

- **Tenant** — submits and tracks maintenance requests
- **Property Manager** — manages requests, assigns vendors, approves/rejects quotes

## Maintenance Request Lifecycle

```
submitted → vendor_quote_requested → quote_received → quote_accepted → in_progress → completed
                                                     → quote_rejected
```

## Development

```bash
bundle exec rubocop        # Lint
bundle exec brakeman       # Security analysis
```
