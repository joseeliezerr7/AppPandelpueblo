# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

"App Pan del Pueblo" is a full-stack mobile application for managing a bakery distribution business. It consists of:
- **Flutter mobile app** (frontend) - Cross-platform app for Android, iOS, web, and desktop
- **Laravel 11 API** (backend) - RESTful API with Sanctum authentication

## Common Commands

### Flutter (Frontend)
```bash
# Run the app (default server: http://10.0.2.2:8000 for Android emulator)
flutter run

# Run on specific device
flutter run -d chrome
flutter run -d macos

# Build for production
flutter build apk
flutter build ios
flutter build web
```

### Laravel (Backend)
```bash
cd backend-laravel

# Install dependencies
composer install

# Run development server (port 5007 by default)
php artisan serve --host=0.0.0.0 --port=5007

# Database operations
php artisan migrate                    # Run migrations
php artisan migrate:fresh --seed       # Reset DB with seed data
php artisan db:seed                    # Run seeders only

# Clear caches
php artisan cache:clear && php artisan config:clear && php artisan route:clear

# View API routes
php artisan route:list

# Run tests
php artisan test
./vendor/bin/phpunit

# Code formatting
./vendor/bin/pint
```

## Architecture

### Flutter App Structure (`lib/`)
The app uses **Provider** for state management with a layered architecture:

- **`services/`** - Core services
  - `api_service.dart` - Dio-based HTTP client with Sanctum token auth
  - `database_helper.dart` - SQLite local database for offline support
  - `connectivity_service.dart` - Network status monitoring
  - `sync_service.dart` - Online/offline data synchronization

- **`repositories/`** - Data access layer bridging API and local storage

- **`providers/`** - State management (ChangeNotifier classes)

- **`models/`** - Data models with `fromJson`/`toJson` serialization

- **`screens/`** - UI organized by feature module (Auth, Categorias, Productos, Rutas, Pulperias, Pedidos, Usuarios, Empleados)

### Laravel API Structure (`backend-laravel/`)
Standard Laravel 11 structure with API resources:

- **`app/Http/Controllers/Api/`** - REST controllers for each entity
- **`app/Models/`** - Eloquent models with soft deletes
- **Routes** - All API routes defined in `routes/api.php`

### Key Domain Entities
- **Users/Usuarios** - System users with roles (admin, vendedor, usuario)
- **Categorias** - Product categories
- **Productos** - Bakery products with stock tracking
- **Rutas** - Distribution routes
- **Pulperias** - Small stores/shops on routes
- **Clientes** - Customers linked to routes
- **Pedidos/DetallePedido** - Orders with line items
- **CronogramaVisitas/VisitasClientes** - Visit schedules and logs

## API Configuration

The API provides dual-case endpoints for Flutter compatibility:
- Lowercase: `/api/productos`, `/api/categorias`
- PascalCase: `/api/Productos`, `/api/Categorias`

Authentication uses Laravel Sanctum Bearer tokens.

## Test Credentials (after seeding)
| Email | Password | Role |
|-------|----------|------|
| admin@pandelpueblo.com | admin123 | admin |
| vendedor@pandelpueblo.com | vendedor123 | vendedor |
| usuario@pandelpueblo.com | usuario123 | usuario |

## Tech Stack
- **Flutter** >= 3.0.0, Dart SDK >= 3.0.0
- **Laravel** 11, PHP >= 8.2
- **Database**: MySQL 8.0+ (production), SQLite (mobile offline)
- **Key packages**: Dio, Provider, Hive, sqflite (Flutter); Sanctum (Laravel)
