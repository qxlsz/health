# Health Data Aggregator

An open-source, privacy-focused health data app for aggregating and analyzing sleep data from wearables like Apple Watch (via HealthKit), Pixel Watch (via Health Connect), and Whoop API. Users self-host data on their cloud to avoid paid apps and data selling.

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Flutter](https://img.shields.io/badge/Flutter-3.0+-blue.svg)](https://flutter.dev)
[![Supabase](https://img.shields.io/badge/Supabase-Self--hosted-green.svg)](https://supabase.com)

## Features

- 🔒 **Privacy-First**: Self-host your data with Supabase
- 📱 **Cross-Platform**: Flutter app for Web, Android, and iOS
- ⌚ **Multi-Device Support**: Apple Watch, Android Wear, Whoop
- 📊 **Sleep Analysis**: Track and analyze sleep patterns
- 🌙 **Dark Mode**: Beautiful Material 3 UI
- 🚀 **Scalable**: Kubernetes-ready architecture

## Tech Stack

- **Frontend**: Flutter (Dart) with Riverpod, Material 3
- **Backend**: Self-hosted Supabase (PostgreSQL, Auth, Storage)
- **Analysis**: Python microservice (Pandas/SciPy)
- **Containerization**: Docker & Docker Compose
- **Orchestration**: Kubernetes (for scaling)

## Architecture

For detailed architecture documentation, see [ARCHITECTURE.md](./ARCHITECTURE.md).

The app follows a layered architecture:
- **Presentation Layer**: Flutter UI (Screens, Widgets)
- **State Management**: Riverpod providers
- **Service Layer**: Health sync, API clients, Supabase client
- **Data Layer**: Supabase (PostgreSQL), Hive (local cache)
- **Integration Layer**: HealthKit, Health Connect, Whoop API

## Project Structure

```
health_app/
├── lib/
│   ├── main.dart                    # App entry point
│   └── src/
│       ├── screens/                 # UI screens
│       ├── providers/               # Riverpod state management
│       ├── services/                # API clients and sync services
│       ├── models/                  # Data models
│       ├── widgets/                 # Reusable widgets
│       └── routing/                 # Navigation with GoRouter
├── supabase/
│   ├── migrations/                  # Database schema migrations
│   ├── functions/                   # Edge functions (TypeScript)
│   └── docker-compose.yml           # Self-hosted Supabase setup
├── analysis/
│   └── sleep_analyzer.py            # Python sleep analysis
├── pubspec.yaml                     # Flutter dependencies
└── README.md                        # This file
```

## Prerequisites

- Flutter SDK (3.0+)
- Docker & Docker Compose
- Node.js (for edge functions)
- Python 3.8+ (for analysis service)

## Quick Start

### Automated Setup (Recommended)

Run the setup script to automate everything:

```bash
# Make script executable (first time only)
chmod +x setup.sh

# Run setup script
./setup.sh
```

This script will:
- Check prerequisites (Flutter, Docker)
- Create environment files
- Start Supabase services
- Install Flutter dependencies
- Run code generation

Then run the app:
```bash
flutter run -d chrome
```

### Option 1: Docker (All-in-One)

Run everything with Docker Compose:

```bash
# Start Supabase and Flutter app
docker-compose up -d

# Access app at http://localhost:8080
# Supabase Studio at http://localhost:54323
```

### Option 2: Local Development

See [LOCAL_SETUP.md](./LOCAL_SETUP.md) or [DEPLOYMENT.md](./DEPLOYMENT.md) for detailed setup instructions.

## Local Setup

### 1. Clone the Repository

```bash
git clone <repository-url>
cd health
```

### 2. Set Up Supabase (Localhost)

Navigate to the `supabase` directory and start Supabase using Docker Compose:

```bash
cd supabase
cp .env.example .env
# Edit .env with your desired passwords
docker-compose up -d
```

This will start Supabase services on:
- **API URL**: `http://localhost:54321`
- **Studio**: `http://localhost:54323` (Database admin UI)
- **Auth**: `http://localhost:54324`
- **REST API**: `http://localhost:54325`
- **Realtime**: `http://localhost:54326`
- **Storage**: `http://localhost:54327`

Wait for all services to be healthy (check with `docker-compose ps`).

### 3. Run Database Migrations

The migrations in `supabase/migrations/` will automatically run on first startup. To verify, check the Supabase Studio at `http://localhost:54323`.

### 4. Configure Flutter App

Create a `.env` file in the project root:

```bash
cp env.template .env
```

Update the `.env` file with your Supabase credentials:

```bash
SUPABASE_URL=http://localhost:54321
SUPABASE_ANON_KEY=your_anon_key_here
```

**Note**: For local development, use the default keys from `supabase/.env.example`. For production, generate secure keys.

### 5. Install Flutter Dependencies

```bash
flutter pub get
```

### 6. Run Code Generation

Generate the required code for JSON serialization:

```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

This will generate the necessary files for `health_data.dart` model serialization.

### 7. Run the App

```bash
# Web
flutter run -d chrome

# Android
flutter run

# iOS
flutter run
```

## Environment Variables

Copy `env.template` to `.env` and fill in your values:

```bash
# Supabase Configuration (Localhost for Development)
SUPABASE_URL=http://localhost:54321
SUPABASE_ANON_KEY=your_anon_key_here
SUPABASE_SERVICE_ROLE_KEY=your_service_role_key_here

# Whoop OAuth (Optional - Add when implementing)
WHOOP_CLIENT_ID=your_whoop_client_id
WHOOP_CLIENT_SECRET=your_whoop_client_secret
WHOOP_REDIRECT_URI=http://localhost:8080/callback

# App Configuration
APP_ENV=development
```

**Important**: 
- **Local Development**: Use `localhost:54321` for Supabase
- **Production**: Update `.env` with your cloud Supabase URL

## Database Schema

The app uses the following main tables:

- **profiles**: User profiles (extends Supabase auth)
- **devices**: Connected wearable devices (Apple Watch, Android, Whoop)
- **health_metrics**: Sleep and activity data (stored as JSONB)

All tables have Row Level Security (RLS) enabled, ensuring users can only access their own data.

## Development Roadmap

- [x] **Phase 1**: Setup & Scaffold (Auth, Basic UI, Database)
- [x] **Phase 2**: UI/UX Basics (Dashboard, Settings, Charts)
- [x] **Phase 3**: Integrations (HealthKit, Health Connect, Whoop)
- [ ] **Phase 4**: Analysis Module (Python sleep analysis)
- [ ] **Phase 5**: Self-Hosting & Scaling (Kubernetes, CI/CD)

## App Store Deployment

- **iOS**: See [APP_STORE_GUIDE.md](./APP_STORE_GUIDE.md) for complete App Store submission guide
- **Android**: See [DEPLOYMENT.md](./DEPLOYMENT.md) for Play Store instructions
- **Web**: Deploy to Netlify, Vercel, or self-hosted server

## Contributing

Contributions are welcome! Please read [CONTRIBUTING.md](CONTRIBUTING.md) for details on our code of conduct and the process for submitting pull requests.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Privacy

This app is designed with privacy as a core principle:
- All data is stored in your self-hosted Supabase instance
- No analytics or tracking
- Device tokens are encrypted
- Row-level security ensures data isolation

## Support

For issues and questions, please open an issue on GitHub.

