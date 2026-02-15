# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

Rails 7.2 API-only backend for a property management app. PostgreSQL database, JWT auth, Anthropic AI integration for chat/summarization.

## Commands

- `bin/rails server` — start dev server
- `bin/rails db:create db:migrate` — set up database
- `bin/rails db:migrate` — run pending migrations
- `bin/rails console` — interactive Rails console
- `bundle exec rubocop` — lint (rubocop-rails-omakase style)
- `bundle exec brakeman` — security analysis

## Architecture

**API-only Rails app** — no views, JSON responses throughout.

**Auth**: JWT-based via `Api::BaseController#authenticate_user!`. Tokens issued by `JwtService` (`app/services/jwt_service.rb`). Auth endpoints (register/login/me) are in `Api::AuthController` and skip authentication.

**User roles** (enum): `tenant` (0), `property_manager` (1), `super_admin` (2). Uses `bcrypt` / `has_secure_password`.

**Core domain models**:
- `User` → belongs_to `Unit` (optional, tenants only), has_many `Property` (via `property_manager_id`), has_many `MaintenanceRequest` (via `tenant_id`)
- `Property` → belongs_to `User` (as `property_manager`), has_many `Unit`. Enum `property_type`: `house` (0), `building` (1)
- `Unit` → belongs_to `Property`, has_one `User` (as `tenant`)
- `MaintenanceRequest` → belongs_to `Vendor` (optional, `assigned_vendor_id`), has_many `Quote`, has_many_attached `images` (Active Storage)
- `Vendor` → has_many `Quote`
- `Quote` → belongs_to `Vendor` + `MaintenanceRequest`

**Admin**: Web admin dashboard at `/web/admin/` and API admin at `/api/admin/`. Both require `super_admin` role. CRUD for users, properties, units, and maintenance requests.

**Maintenance request lifecycle** (status enum): `submitted` → `vendor_quote_requested` → `quote_received` → `quote_accepted`/`quote_rejected` → `in_progress` → `completed`

**All API controllers** inherit from `Api::BaseController` (namespaced under `/api`). The `VendorPortalController` is outside the API namespace and serves the public vendor quote submission page.

**AI integration**: `Api::ChatController` uses the `anthropic` gem for chat and summarization endpoints.

**Environment**: uses `dotenv-rails` for env vars in development.
