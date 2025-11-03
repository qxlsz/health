# Deployment Guide

This guide covers different ways to run and deploy the Health Data Aggregator app.

## Table of Contents

1. [Local Development](#local-development)
2. [Docker Deployment](#docker-deployment)
3. [iOS App Store](#ios-app-store)
4. [Android Play Store](#android-play-store)
5. [Web Deployment](#web-deployment)
6. [Production Checklist](#production-checklist)

## Local Development

### Prerequisites

- Flutter SDK 3.0+
- Dart SDK 3.0+
- Node.js (for edge functions)
- Python 3.8+ (for analysis service)
- Docker & Docker Compose (for Supabase)

### Setup Steps

1. **Clone and Install**

```bash
git clone <repository-url>
cd health
flutter pub get
```

2. **Start Supabase**

```bash
cd supabase
cp .env.example .env
# Edit .env with your passwords
docker-compose up -d
```

3. **Configure App**

```bash
cp env.template .env
# Edit .env with Supabase URL and keys
```

4. **Run Code Generation**

```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

5. **Run App**

```bash
# Web
flutter run -d chrome

# iOS Simulator
flutter run -d ios

# Android Emulator
flutter run -d android
```

## Docker Deployment

### Quick Start with Docker Compose

The project includes a `docker-compose.yml` that runs both Supabase and the Flutter web app:

```bash
# Start everything
docker-compose up -d

# Check logs
docker-compose logs -f

# Stop everything
docker-compose down
```

Services will be available at:
- **Flutter App**: http://localhost:8080
- **Supabase Studio**: http://localhost:54323
- **PostgreSQL**: localhost:54322
- **REST API**: http://localhost:54325

### Building Docker Image

```bash
# Build Flutter web app image
docker build -t health-app:latest .

# Run container
docker run -p 8080:80 health-app:latest
```

### Production Docker Setup

For production, update environment variables:

```bash
# Create .env for production
cat > .env << EOF
POSTGRES_PASSWORD=<strong-password>
JWT_SECRET=<strong-jwt-secret>
SUPABASE_URL=https://your-domain.com
SUPABASE_ANON_KEY=<your-anon-key>
EOF

# Run with production config
docker-compose -f docker-compose.yml --env-file .env up -d
```

### Using External Supabase

If using Supabase Cloud instead of self-hosted:

```yaml
# docker-compose.yml - Comment out Supabase services
# Only run the Flutter app container
services:
  health-app:
    build: .
    ports:
      - '8080:80'
    environment:
      SUPABASE_URL: https://your-project.supabase.co
      SUPABASE_ANON_KEY: your-key
```

## iOS App Store

### Build iOS App

```bash
# Build for release
flutter build ios --release

# Or build IPA
flutter build ipa --release
```

### Using Xcode

1. Open `ios/Runner.xcworkspace`
2. Configure signing in Xcode
3. Product → Archive
4. Distribute to App Store Connect

### Detailed Guide

See [APP_STORE_GUIDE.md](./APP_STORE_GUIDE.md) for complete instructions.

### Requirements

- Apple Developer Account ($99/year)
- Xcode (latest version)
- HealthKit capability enabled
- Privacy policy URL
- App Store Connect account

### HealthKit Configuration

1. Enable HealthKit in Xcode
2. Configure Info.plist with usage descriptions
3. Add entitlements file
4. Request permissions at runtime

## Android Play Store

### Build Android App

```bash
# Build APK
flutter build apk --release

# Build App Bundle (recommended for Play Store)
flutter build appbundle --release
```

### Signing Configuration

Create `android/key.properties`:

```properties
storePassword=<password>
keyPassword=<password>
keyAlias=upload
storeFile=<path-to-keystore>
```

Create keystore:

```bash
keytool -genkey -v -keystore ~/upload-keystore.jks \
  -keyalg RSA -keysize 2048 -validity 10000 \
  -alias upload
```

Update `android/app/build.gradle`:

```gradle
def keystoreProperties = new Properties()
def keystorePropertiesFile = rootProject.file('key.properties')
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(new FileInputStream(keystorePropertiesFile))
}

android {
    signingConfigs {
        release {
            keyAlias keystoreProperties['keyAlias']
            keyPassword keystoreProperties['keyPassword']
            storeFile keystoreProperties['storeFile'] ? file(keystoreProperties['storeFile']) : null
            storePassword keystoreProperties['storePassword']
        }
    }
    buildTypes {
        release {
            signingConfig signingConfigs.release
        }
    }
}
```

### Play Store Submission

1. Create app in Google Play Console
2. Upload AAB file
3. Fill in store listing
4. Set up privacy policy
5. Configure Health Connect permissions
6. Submit for review

### Health Connect Requirements

- Declare permissions in AndroidManifest.xml
- Request runtime permissions
- Handle Health Connect availability
- Provide privacy policy

## Web Deployment

### Build for Web

```bash
# Build release
flutter build web --release

# Output: build/web/
```

### Deploy Options

#### Netlify

```bash
# Install Netlify CLI
npm install -g netlify-cli

# Deploy
netlify deploy --prod --dir=build/web
```

#### Vercel

```bash
# Install Vercel CLI
npm install -g vercel

# Deploy
vercel --prod build/web
```

#### Firebase Hosting

```bash
# Install Firebase CLI
npm install -g firebase-tools

# Initialize
firebase init hosting

# Deploy
firebase deploy --only hosting
```

#### Nginx (Self-hosted)

```bash
# Copy build output
cp -r build/web/* /var/www/html/

# Configure nginx (see docker/nginx.conf for example)
```

### Environment Variables for Web

Update `build/web/index.html` or use environment-specific builds:

```bash
# Build with production URL
flutter build web --release \
  --dart-define=SUPABASE_URL=https://your-domain.com \
  --dart-define=SUPABASE_ANON_KEY=your-key
```

## Production Checklist

### Before Going Live

- [ ] Update environment variables for production
- [ ] Configure production Supabase instance
- [ ] Enable SSL/TLS certificates
- [ ] Set up monitoring and logging
- [ ] Configure backup strategy
- [ ] Test on all target platforms
- [ ] Review privacy policy
- [ ] Set up error tracking (Sentry, etc.)
- [ ] Configure analytics (if applicable)
- [ ] Test HealthKit/Health Connect permissions
- [ ] Verify data encryption
- [ ] Test offline functionality
- [ ] Load testing
- [ ] Security audit

### Security Considerations

- Use HTTPS everywhere
- Encrypt sensitive data at rest
- Use strong passwords for databases
- Rotate API keys regularly
- Implement rate limiting
- Monitor for suspicious activity
- Keep dependencies updated
- Regular security audits

### Performance Optimization

- Enable code minification
- Optimize images
- Use CDN for static assets
- Implement caching strategies
- Monitor API response times
- Optimize database queries
- Use connection pooling

## Troubleshooting

### Common Issues

**Docker: Port conflicts**
```bash
# Check what's using ports
lsof -i :8080
# Kill process or change port in docker-compose.yml
```

**Flutter: Build errors**
```bash
flutter clean
flutter pub get
flutter pub run build_runner build --delete-conflicting-outputs
```

**iOS: Signing issues**
- Check certificates in Keychain
- Verify provisioning profiles
- Ensure Bundle ID matches

**Android: Build failures**
```bash
cd android
./gradlew clean
cd ..
flutter clean
flutter pub get
```

## Support

For deployment issues:
- Check Flutter documentation
- Review platform-specific guides
- Open an issue on GitHub

