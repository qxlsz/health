# Architecture Documentation

## System Architecture

### High-Level Architecture

```mermaid
graph TB
    subgraph "Client Layer"
        FlutterWeb[Flutter Web App]
        FlutterIOS[Flutter iOS App]
        FlutterAndroid[Flutter Android App]
    end
    
    subgraph "Data Sources"
        HealthKit[Apple HealthKit<br/>iOS Only]
        HealthConnect[Health Connect<br/>Android Only]
        WhoopAPI[Whoop API<br/>OAuth 2.0]
    end
    
    subgraph "Application Layer"
        AuthScreen[Auth Screen]
        Dashboard[Dashboard]
        Onboarding[Onboarding]
        Settings[Settings]
    end
    
    subgraph "Service Layer"
        HealthSync[Health Sync Service]
        HealthKitService[HealthKit Service]
        HealthConnectService[Health Connect Service]
        WhoopClient[Whoop API Client]
        SupabaseClient[Supabase Client]
        HiveService[Hive Service<br/>Local Cache]
    end
    
    subgraph "State Management"
        AuthProvider[Auth Provider]
        HealthProvider[Health Provider]
        IntegrationProvider[Integration Provider]
    end
    
    subgraph "Backend - Supabase"
        Postgres[(PostgreSQL<br/>Database)]
        Auth[GoTrue<br/>Auth Service]
        REST[PostgREST<br/>REST API]
        Realtime[Realtime Service]
        Storage[Storage Service]
    end
    
    subgraph "Analysis Layer"
        PythonService[Python Analysis Service<br/>Pandas/SciPy]
    end
    
    FlutterWeb --> AuthScreen
    FlutterIOS --> AuthScreen
    FlutterAndroid --> AuthScreen
    
    AuthScreen --> AuthProvider
    Dashboard --> HealthProvider
    Onboarding --> IntegrationProvider
    Settings --> AuthProvider
    
    AuthProvider --> SupabaseClient
    HealthProvider --> SupabaseClient
    IntegrationProvider --> HealthSync
    
    HealthSync --> HealthKitService
    HealthSync --> HealthConnectService
    HealthSync --> WhoopClient
    HealthSync --> SupabaseClient
    HealthSync --> HiveService
    
    HealthKitService --> HealthKit
    HealthConnectService --> HealthConnect
    WhoopClient --> WhoopAPI
    
    SupabaseClient --> REST
    SupabaseClient --> Auth
    SupabaseClient --> Realtime
    
    REST --> Postgres
    Auth --> Postgres
    
    Postgres --> PythonService
    
    HiveService -.-> FlutterWeb
    HiveService -.-> FlutterIOS
    HiveService -.-> FlutterAndroid
    
    style FlutterWeb fill:#42a5f5
    style FlutterIOS fill:#42a5f5
    style FlutterAndroid fill:#42a5f5
    style Postgres fill:#336791
    style Auth fill:#3ecf8e
    style REST fill:#3ecf8e
    style HealthKit fill:#fa7343
    style HealthConnect fill:#34a853
    style WhoopAPI fill:#fa7343
```

## Data Flow Architecture

```mermaid
sequenceDiagram
    participant User
    participant FlutterApp as Flutter App
    participant Onboarding as Onboarding Screen
    participant HealthKit as HealthKit/HealthConnect
    participant SyncService as Health Sync Service
    participant HiveCache as Hive Cache
    participant Supabase as Supabase Backend
    participant Postgres as PostgreSQL
    
    User->>FlutterApp: Open App
    FlutterApp->>Supabase: Check Auth Status
    Supabase-->>FlutterApp: User Authenticated
    
    User->>Onboarding: Connect Device
    Onboarding->>HealthKit: Request Permissions
    HealthKit-->>Onboarding: Permission Granted
    
    Onboarding->>SyncService: Sync Data
    SyncService->>HealthKit: Fetch Sleep Data
    HealthKit-->>SyncService: Sleep Sessions
    
    SyncService->>SyncService: Parse & Transform
    SyncService->>Supabase: Upsert Sleep Data
    Supabase->>Postgres: Store Data (JSONB)
    Postgres-->>Supabase: Success
    Supabase-->>SyncService: Confirmed
    
    SyncService->>HiveCache: Cache Locally
    HiveCache-->>SyncService: Cached
    
    SyncService-->>Onboarding: Sync Complete
    Onboarding-->>User: Device Connected
    
    User->>FlutterApp: View Dashboard
    FlutterApp->>Supabase: Fetch Sleep Data
    Supabase->>Postgres: Query with RLS
    Postgres-->>Supabase: Sleep Sessions
    Supabase-->>FlutterApp: JSON Response
    
    alt Network Offline
        FlutterApp->>HiveCache: Load Cached Data
        HiveCache-->>FlutterApp: Cached Sessions
    end
    
    FlutterApp->>FlutterApp: Render Charts
    FlutterApp-->>User: Display Dashboard
```

## Component Architecture

```mermaid
graph LR
    subgraph "Flutter App Structure"
        Main[main.dart<br/>Entry Point]
        
        subgraph "Screens"
            Auth[Auth Screen]
            Dashboard[Dashboard Screen]
            Onboarding[Onboarding Screen]
            Settings[Settings Screen]
        end
        
        subgraph "Providers - State Management"
            AuthProv[Auth Provider<br/>Riverpod]
            HealthProv[Health Provider<br/>Riverpod]
            IntegrationProv[Integration Provider<br/>Riverpod]
        end
        
        subgraph "Services"
            SupabaseSvc[Supabase Client<br/>Backend Connection]
            HealthSyncSvc[Health Sync Service<br/>Data Synchronization]
            HealthKitSvc[HealthKit Service<br/>iOS Health Data]
            HealthConnectSvc[Health Connect Service<br/>Android Health Data]
            WhoopSvc[Whoop API Client<br/>OAuth & API]
            HiveSvc[Hive Service<br/>Local Storage]
        end
        
        subgraph "Models"
            SleepSession[Sleep Session Model]
            SleepStage[Sleep Stage Model]
            Device[Device Model]
        end
        
        subgraph "Widgets"
            PieChart[Sleep Stages Pie Chart]
            TrendChart[Sleep Trends Chart]
        end
        
        subgraph "Routing"
            Router[GoRouter<br/>Navigation]
        end
    end
    
    Main --> Router
    Router --> Auth
    Router --> Dashboard
    Router --> Onboarding
    Router --> Settings
    
    Auth --> AuthProv
    Dashboard --> HealthProv
    Onboarding --> IntegrationProv
    
    AuthProv --> SupabaseSvc
    HealthProv --> SupabaseSvc
    IntegrationProv --> HealthSyncSvc
    
    HealthSyncSvc --> HealthKitSvc
    HealthSyncSvc --> HealthConnectSvc
    HealthSyncSvc --> WhoopSvc
    HealthSyncSvc --> SupabaseSvc
    HealthSyncSvc --> HiveSvc
    
    HealthProv --> SleepSession
    SleepSession --> SleepStage
    
    Dashboard --> PieChart
    Dashboard --> TrendChart
    PieChart --> SleepSession
    TrendChart --> SleepSession
    
    style Main fill:#42a5f5
    style Auth fill:#66bb6a
    style Dashboard fill:#66bb6a
    style Onboarding fill:#66bb6a
    style Settings fill:#66bb6a
    style SupabaseSvc fill:#3ecf8e
    style HealthSyncSvc fill:#ffa726
```

## Database Schema

```mermaid
erDiagram
    AUTH_USERS ||--o{ PROFILES : extends
    PROFILES ||--o{ DEVICES : owns
    DEVICES ||--o{ HEALTH_METRICS : generates
    
    AUTH_USERS {
        uuid id PK
        string email
        timestamp created_at
    }
    
    PROFILES {
        uuid id PK,FK
        string email
        timestamp created_at
        timestamp updated_at
    }
    
    DEVICES {
        uuid id PK
        uuid user_id FK
        string type
        string name
        string token
        timestamp last_sync_at
        timestamp created_at
        timestamp updated_at
    }
    
    HEALTH_METRICS {
        uuid id PK
        uuid device_id FK
        uuid user_id FK
        timestamp timestamp
        string type
        jsonb data
        timestamp created_at
        timestamp updated_at
    }
```

## Deployment Architecture

```mermaid
graph TB
    subgraph "Development"
        DevUser[Developer]
        DevMachine[Local Machine]
        DevDocker[Docker Compose<br/>localhost]
    end
    
    subgraph "Production - Self-Hosted"
        User[End Users]
        
        subgraph "CDN / Load Balancer"
            LB[Load Balancer<br/>Nginx/Cloudflare]
        end
        
        subgraph "Application Servers"
            WebApp1[Flutter Web App<br/>Container]
            WebApp2[Flutter Web App<br/>Container]
        end
        
        subgraph "Mobile Apps"
            iOSApp[iOS App<br/>App Store]
            AndroidApp[Android App<br/>Play Store]
        end
        
        subgraph "Backend Cluster"
            Supabase1[Supabase Instance 1]
            Supabase2[Supabase Instance 2<br/>Replica]
        end
        
        subgraph "Database Cluster"
            PostgresPrimary[(PostgreSQL<br/>Primary)]
            PostgresReplica[(PostgreSQL<br/>Replica)]
        end
        
        subgraph "Analysis Service"
            PythonWorker[Python Analysis<br/>Worker Container]
        end
        
        subgraph "Storage"
            ObjectStorage[Object Storage<br/>Supabase Storage]
        end
    end
    
    DevUser --> DevMachine
    DevMachine --> DevDocker
    
    User --> LB
    User --> iOSApp
    User --> AndroidApp
    
    LB --> WebApp1
    LB --> WebApp2
    
    iOSApp --> LB
    AndroidApp --> LB
    WebApp1 --> Supabase1
    WebApp2 --> Supabase2
    
    Supabase1 --> PostgresPrimary
    Supabase2 --> PostgresReplica
    
    PostgresPrimary --> PostgresReplica
    
    Supabase1 --> ObjectStorage
    Supabase2 --> ObjectStorage
    
    PostgresPrimary --> PythonWorker
    PythonWorker --> PostgresPrimary
    
    style DevDocker fill:#90caf9
    style LB fill:#42a5f5
    style WebApp1 fill:#66bb6a
    style WebApp2 fill:#66bb6a
    style iOSApp fill:#fa7343
    style AndroidApp fill:#34a853
    style PostgresPrimary fill:#336791
    style PythonWorker fill:#ffa726
```

## Security Architecture

```mermaid
graph TB
    subgraph "Client Security"
        FlutterApp[Flutter App]
        HiveEncryption[Hive Encrypted Storage]
        EnvVars[Environment Variables<br/>.env file]
    end
    
    subgraph "Transport Security"
        HTTPS[HTTPS/TLS<br/>Encrypted Connection]
        JWT[JWT Tokens<br/>Auth Tokens]
    end
    
    subgraph "Backend Security"
        SupabaseAuth[Supabase Auth<br/>GoTrue]
        RLSPolicies[Row Level Security<br/>RLS Policies]
        APIKeys[API Keys<br/>Anon & Service]
    end
    
    subgraph "Database Security"
        PostgresAuth[PostgreSQL<br/>User Auth]
        EncryptionAtRest[Encryption at Rest]
        BackupEncryption[Encrypted Backups]
    end
    
    FlutterApp --> HiveEncryption
    FlutterApp --> EnvVars
    FlutterApp --> HTTPS
    HTTPS --> JWT
    JWT --> SupabaseAuth
    SupabaseAuth --> RLSPolicies
    RLSPolicies --> PostgresAuth
    PostgresAuth --> EncryptionAtRest
    EncryptionAtRest --> BackupEncryption
    
    APIKeys -.-> SupabaseAuth
    
    style HTTPS fill:#4caf50
    style RLSPolicies fill:#ff9800
    style EncryptionAtRest fill:#f44336
```

## Technology Stack

```mermaid
graph LR
    subgraph "Frontend"
        Flutter[Flutter/Dart]
        Riverpod[Riverpod<br/>State Management]
        GoRouter[GoRouter<br/>Navigation]
        Charts[charts_flutter<br/>Data Visualization]
        Material[Material Design 3]
    end
    
    subgraph "Backend"
        Supabase[Supabase<br/>BaaS Platform]
        PostgreSQL[PostgreSQL 15<br/>Database]
        GoTrue[GoTrue<br/>Auth Service]
        PostgREST[PostgREST<br/>REST API]
    end
    
    subgraph "Data Sources"
        HealthKit[HealthKit<br/>Apple Framework]
        HealthConnect[Health Connect<br/>Google API]
        WhoopAPI[Whoop API<br/>OAuth 2.0]
    end
    
    subgraph "Storage"
        Hive[Hive<br/>Local Database]
        SupabaseStorage[Supabase Storage<br/>File Storage]
    end
    
    subgraph "Analysis"
        Python[Python 3.8+]
        Pandas[Pandas]
        SciPy[SciPy]
    end
    
    subgraph "DevOps"
        Docker[Docker]
        DockerCompose[Docker Compose]
        Kubernetes[Kubernetes<br/>Future]
    end
    
    Flutter --> Riverpod
    Flutter --> GoRouter
    Flutter --> Charts
    Flutter --> Material
    Flutter --> Hive
    
    Supabase --> PostgreSQL
    Supabase --> GoTrue
    Supabase --> PostgREST
    Supabase --> SupabaseStorage
    
    Docker --> DockerCompose
    
    style Flutter fill:#42a5f5
    style Supabase fill:#3ecf8e
    style PostgreSQL fill:#336791
    style Docker fill:#0db7ed
```

## Data Synchronization Flow

```mermaid
flowchart TD
    Start([User Opens App]) --> CheckAuth{User<br/>Authenticated?}
    CheckAuth -->|No| ShowAuth[Show Auth Screen]
    CheckAuth -->|Yes| CheckDevices{Devices<br/>Connected?}
    
    ShowAuth --> SignIn[Sign In/Sign Up]
    SignIn --> CheckAuth
    
    CheckDevices -->|No| ShowOnboarding[Show Onboarding]
    CheckDevices -->|Yes| CheckSync{Data<br/>Sync Needed?}
    
    ShowOnboarding --> SelectDevice[Select Device Type]
    
    SelectDevice -->|iOS| RequestHealthKit[Request HealthKit<br/>Permissions]
    SelectDevice -->|Android| RequestHealthConnect[Request Health<br/>Connect Permissions]
    SelectDevice -->|Whoop| StartOAuth[Start Whoop<br/>OAuth Flow]
    
    RequestHealthKit --> FetchHealthKit[Fetch Sleep Data<br/>from HealthKit]
    RequestHealthConnect --> FetchHealthConnect[Fetch Sleep Data<br/>from Health Connect]
    StartOAuth --> CompleteOAuth[Complete OAuth<br/>Get Token]
    CompleteOAuth --> FetchWhoop[Fetch Sleep Data<br/>from Whoop API]
    
    FetchHealthKit --> TransformData[Transform Data<br/>to SleepSession]
    FetchHealthConnect --> TransformData
    FetchWhoop --> TransformData
    
    TransformData --> RegisterDevice[Register Device<br/>in Supabase]
    RegisterDevice --> SyncToSupabase[Sync Data to<br/>Supabase]
    SyncToSupabase --> CacheLocally[Cache Data<br/>Locally with Hive]
    CacheLocally --> ShowDashboard[Show Dashboard]
    
    CheckSync -->|Yes| BackgroundSync[Background Sync]
    CheckSync -->|No| ShowDashboard
    BackgroundSync --> SyncToSupabase
    
    ShowDashboard --> LoadData[Load Data from<br/>Supabase]
    LoadData --> CheckNetwork{Network<br/>Available?}
    CheckNetwork -->|Yes| FetchRemote[Fetch from<br/>Supabase API]
    CheckNetwork -->|No| LoadCache[Load from<br/>Hive Cache]
    FetchRemote --> DisplayCharts[Display Charts<br/>& Statistics]
    LoadCache --> DisplayCharts
    
    style Start fill:#4caf50
    style ShowDashboard fill:#2196f3
    style SyncToSupabase fill:#ff9800
    style DisplayCharts fill:#9c27b0
```

## Key Design Decisions

1. **Self-Hosted Supabase**: Users control their data, no reliance on third-party services
2. **Row Level Security (RLS)**: Database-level security ensures data isolation
3. **Offline-First**: Hive caching allows app to work without network
4. **Cross-Platform**: Single Flutter codebase for Web, iOS, and Android
5. **Privacy-First**: No analytics, no data selling, encryption at rest
6. **Extensible**: Easy to add new data sources (Fitbit, Garmin, etc.)

## Performance Considerations

- **Client-Side Caching**: Hive reduces API calls
- **Batch Syncing**: Multiple sleep sessions synced in batches
- **Lazy Loading**: Data loaded on-demand in providers
- **Database Indexing**: Optimized queries with proper indexes
- **Connection Pooling**: Supabase handles connection management
- **CDN Ready**: Static assets can be served via CDN for web

