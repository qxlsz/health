# Local Setup Guide

Step-by-step instructions to run the Health Data Aggregator app locally.

## Prerequisites

1. **Flutter SDK** (3.0+)
   - Install from https://flutter.dev/docs/get-started/install
   - Or via Homebrew: `brew install flutter`
   - Verify: `flutter --version`

2. **Docker & Docker Compose**
   - Already installed ✅

3. **Git** (for cloning, if needed)

## Step 1: Install Flutter (if not installed)

```bash
# Check if Flutter is installed
flutter --version

# If not installed, install via Homebrew (macOS)
brew install flutter

# Or download from https://flutter.dev/docs/get-started/install
# Extract and add to PATH:
export PATH="$PATH:/path/to/flutter/bin"

# Verify installation
flutter doctor
```

## Step 2: Start Supabase Backend

Supabase needs to run first so the app can connect to it.

```bash
# Navigate to supabase directory
cd /Users/qxlsz/projects/health/supabase

# Copy environment template (if not exists)
cp .env.example .env

# Start Supabase services
docker-compose up -d

# Wait for services to be ready (about 30 seconds)
# Check status
docker-compose ps

# You should see all services as "Up" and healthy
```

**Supabase will be available at:**
- **API URL**: http://localhost:54321
- **Studio (Admin UI)**: http://localhost:54323
- **Auth**: http://localhost:54324
- **REST API**: http://localhost:54325

**Default keys** (for localhost development):
- `SUPABASE_ANON_KEY`: `eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZS1kZW1vIiwicm9sZSI6ImFub24iLCJleHAiOjE5ODM4MTI5OTZ9.CRXP1A7WOeoJeXxjNni43kdQwgnWNReilDMblYTn_I0`
- `SUPABASE_SERVICE_ROLE_KEY`: `eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZS1kZW1vIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImV4cCI6MTk4MzgxMjk5Nn0.EGIM96RAZx35lJzdJsyH-qQwv8Hdp7fsn3W0YpN81IU`

## Step 3: Configure Flutter App

```bash
# Navigate back to project root
cd /Users/qxlsz/projects/health

# Create .env file from template
cp env.template .env

# Edit .env file (you can use nano, vim, or any text editor)
# Update with Supabase keys from Step 2
nano .env
```

**Update `.env` file with:**
```bash
SUPABASE_URL=http://localhost:54321
SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZS1kZW1vIiwicm9sZSI6ImFub24iLCJleHAiOjE5ODM4MTI5OTZ9.CRXP1A7WOeoJeXxjNni43kdQwgnWNReilDMblYTn_I0
SUPABASE_SERVICE_ROLE_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZS1kZW1vIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImV4cCI6MTk4MzgxMjk5Nn0.EGIM96RAZx35lJzdJsyH-qQwv8Hdp7fsn3W0YpN81IU

# Whoop OAuth (Optional - can leave as placeholders for now)
WHOOP_CLIENT_ID=your_whoop_client_id
WHOOP_CLIENT_SECRET=your_whoop_client_secret
WHOOP_REDIRECT_URI=http://localhost:8080/callback

APP_ENV=development
```

## Step 4: Install Flutter Dependencies

```bash
# Make sure you're in the project root
cd /Users/qxlsz/projects/health

# Get all Flutter packages
flutter pub get
```

## Step 5: Run Code Generation

This generates JSON serialization code for the models.

```bash
# Generate code
flutter pub run build_runner build --delete-conflicting-outputs

# This will create health_data.g.dart with serialization code
```

**Note:** If you see errors about missing files, it's okay - `build_runner` will create them.

## Step 6: Verify Supabase is Running

Before running the app, verify Supabase is healthy:

```bash
# Check Supabase services
cd supabase
docker-compose ps

# Check logs if needed
docker-compose logs postgres

# Verify database is accessible
# Open http://localhost:54323 in browser (Supabase Studio)
```

## Step 7: Run the App

Now you can run the Flutter app!

### Option A: Run on Web (Easiest to start)

```bash
# From project root
cd /Users/qxlsz/projects/health

# Run on Chrome
flutter run -d chrome

# Or run on any available browser
flutter run -d web-server --web-port=3000
```

The app will open in your browser, typically at `http://localhost:3000` or similar.

### Option B: Run on iOS Simulator

```bash
# List available devices
flutter devices

# Run on iOS simulator (requires Xcode)
flutter run -d ios

# Or specify a simulator
flutter run -d "iPhone 15 Pro"
```

### Option C: Run on Android Emulator

```bash
# Start Android emulator first (via Android Studio)
# Then run:
flutter run -d android
```

## Step 8: Test the App

1. **Sign Up**: Create a new account with email/password
2. **Sign In**: Log in with your credentials
3. **Dashboard**: You'll see the dashboard (empty until you connect devices)
4. **Onboarding**: Click "Connect Device" or navigate to `/onboarding`
5. **Settings**: Access settings from the dashboard

## Troubleshooting

### Issue: Flutter not found

```bash
# Add Flutter to PATH (add to ~/.zshrc or ~/.bash_profile)
export PATH="$PATH:$HOME/flutter/bin"

# Or use Homebrew
brew install flutter
```

### Issue: Supabase not starting

```bash
# Check if ports are already in use
lsof -i :54321
lsof -i :54323

# Stop conflicting services or change ports in docker-compose.yml

# Check Docker logs
cd supabase
docker-compose logs
```

### Issue: Database migrations not running

```bash
# Manually run migrations
cd supabase
docker-compose exec postgres psql -U postgres -d postgres -f /docker-entrypoint-initdb.d/001_initial_schema.sql

# Or restart Supabase
docker-compose restart postgres
```

### Issue: Code generation errors

```bash
# Clean and regenerate
flutter clean
flutter pub get
flutter pub run build_runner clean
flutter pub run build_runner build --delete-conflicting-outputs
```

### Issue: App can't connect to Supabase

1. Verify Supabase is running: `docker-compose ps` in `supabase/`
2. Check `.env` file has correct URL and keys
3. Try opening Supabase Studio: http://localhost:54323
4. Check browser console for errors (F12)

### Issue: Missing dependencies

```bash
# Clean and reinstall
flutter clean
flutter pub get
flutter pub upgrade
```

## Quick Start Commands Summary

```bash
# Terminal 1: Start Supabase
cd /Users/qxlsz/projects/health/supabase
docker-compose up -d

# Terminal 2: Run Flutter app
cd /Users/qxlsz/projects/health
flutter pub get
flutter pub run build_runner build --delete-conflicting-outputs
flutter run -d chrome
```

## What to Expect

1. **First Run**: App will take a moment to compile
2. **Browser Opens**: Chrome will open with the app
3. **Auth Screen**: You'll see the sign-in/sign-up screen
4. **Create Account**: Use any email (verification disabled in dev mode)
5. **Dashboard**: After login, you'll see the dashboard

## Next Steps

- Connect devices via the Onboarding screen
- Explore the dashboard and charts
- Check Supabase Studio at http://localhost:54323 to see your data
- Read [DEPLOYMENT.md](./DEPLOYMENT.md) for production deployment

## Stopping Services

```bash
# Stop Supabase
cd supabase
docker-compose down

# Or stop all Docker containers
docker-compose down
```

