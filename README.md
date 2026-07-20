# Hostel Management System

A production-ready **Offline-First Hostel Management System** built with **Flutter** using **Feature-First Clean Architecture**, **Cubit State Management**, **SQLite**, **GetIt**, and **GoRouter**.

The application is designed to simplify hostel administration by providing an efficient solution for managing hostels, rooms, beds, tenants, rent collection, expenses, reports, and daily operations while functioning completely offline.

Unlike many hostel management applications that rely on continuous internet connectivity, this project follows an **Offline-First Architecture**, allowing hostel owners and managers to continue working seamlessly even without an active network connection.

The project has been developed with scalability, maintainability, and clean software engineering principles in mind, making it suitable for both small hostels and large accommodation facilities.

---

# Table of Contents

- Overview
- Why This Project?
- Key Features
- Application Modules
- Technology Stack
- Project Architecture
- Folder Structure
- Clean Architecture
- Application Startup Flow
- Authentication Flow
- Hostel Setup Flow
- Dashboard Flow
- Room Management
- Bed Management
- Tenant Management
- Rent Management
- Expense Management
- Reports
- Backup & Restore
- Export System
- SQLite Database
- Repository Pattern
- Cubit State Management
- Dependency Injection
- Navigation
- Offline First Strategy
- Validation Strategy
- Error Handling
- Security
- Performance Optimizations
- Packages Used
- Build Instructions
- Testing
- CI/CD
- Future Improvements
- Contributing
- License
- Author

---

# Overview

Hostel Management System is a Flutter application developed to automate the day-to-day operations of a hostel.

Instead of maintaining registers and spreadsheets, the application provides a centralized platform where hostel owners and managers can efficiently manage every aspect of their business.

The application stores all information locally using SQLite, ensuring uninterrupted functionality even without internet access.

Every feature has been designed following Feature-First Clean Architecture, making the codebase modular, scalable, testable, and easy to maintain.

---

# Why This Project?

Managing a hostel involves handling multiple responsibilities simultaneously:

- Registering tenants
- Managing rooms
- Tracking bed availability
- Collecting monthly rent
- Recording expenses
- Monitoring occupancy
- Viewing financial reports
- Managing hostel information

Traditional methods are slow, error-prone, and difficult to maintain.

This application digitizes the complete workflow while keeping the system lightweight, fast, and fully functional offline.

---

# Key Features

## Authentication

- Owner Login
- Manager Login
- Secure Session Storage
- Persistent Login
- Role Based Access

## Dashboard

- Total Rooms
- Occupied Rooms
- Vacant Rooms
- Total Beds
- Available Beds
- Total Tenants
- Monthly Rent Collection
- Pending Rent
- Monthly Expenses
- Monthly Profit
- Recent Activities

## Hostel Management

- Create Hostel
- Update Hostel Details
- Hostel Settings
- Contact Information
- Address Management

## Room Management

- Create Room
- Edit Room
- Delete Room
- Room Availability
- Occupancy Status

## Bed Management

- Create Beds
- Assign Beds
- Vacant Beds
- Occupied Beds

## Tenant Management

- Add Tenant
- Edit Tenant
- Remove Tenant
- Check In
- Check Out
- Tenant History

## Rent Management

- Monthly Rent
- Rent Status
- Pending Payments
- Payment History

## Expense Management

- Add Expense
- Expense Categories
- Expense Reports
- Monthly Summary

## Reports

- Occupancy Report
- Income Report
- Expense Report
- Profit Report

## Backup & Restore

- Backup SQLite Database
- Restore Database
- Import Data
- Export Data

## Export

- PDF Export
- CSV Export
- Local Backup

---

# Technology Stack

| Technology | Purpose |
|------------|---------|
| Flutter | Cross Platform UI Framework |
| Dart | Programming Language |
| SQLite | Offline Database |
| flutter_bloc | State Management |
| GetIt | Dependency Injection |
| GoRouter | Navigation |
| flutter_secure_storage | Secure Authentication |
| Material 3 | User Interface |
| flutter_native_splash | Native Splash Screen |

---

# Project Goals

The project has been designed with the following engineering goals:

- Offline First
- Feature First Architecture
- High Performance
- Easy Maintenance
- Scalable Codebase
- Clean UI
- Reusable Components
- Testable Architecture
- SOLID Principles
- Repository Pattern
- Dependency Injection
- Predictable State Management
# Project Architecture

The Hostel Management System follows a **Feature-First Clean Architecture** to ensure scalability, maintainability, testability, and separation of concerns.

Unlike traditional Flutter projects where business logic, UI, and database code become tightly coupled, this application organizes every feature into independent modules with clearly defined responsibilities.

The architecture emphasizes:

- Separation of Concerns
- Single Responsibility Principle
- Dependency Injection
- Repository Pattern
- Predictable State Management
- Offline-First Design
- Modular Development

Each feature is completely isolated from other features, allowing independent development, testing, and future expansion.

---

# Architecture Overview

```text
Presentation Layer
        │
        ▼
     Cubit Layer
        │
        ▼
   Repository Layer
        │
        ▼
   Local Data Source
        │
        ▼
      SQLite
```

The Presentation Layer never communicates directly with the database.

Every database operation must pass through the Repository layer, ensuring loose coupling and maintainable code.

---

# Folder Structure

```
lib
│
├── core
│   ├── constants
│   ├── database
│   ├── di
│   ├── router
│   ├── services
│   ├── theme
│   ├── utils
│   ├── widgets
│   └── extensions
│
├── features
│   │
│   ├── splash
│   │
│   ├── authentication
│   │
│   ├── dashboard
│   │
│   ├── hostel
│   │
│   ├── room
│   │
│   ├── bed
│   │
│   ├── tenant
│   │
│   ├── rent
│   │
│   ├── expense
│   │
│   ├── reports
│   │
│   ├── settings
│   │
│   ├── backup
│   │
│   └── export
│
├── shared
│
└── main.dart
```

Every feature follows the same internal structure.

```
feature
│
├── cubit
│
├── data
│
├── presentation
│
└── repository
```

This consistency improves navigation throughout the project and allows new features to be added without affecting existing modules.

---

# Layer Responsibilities

## Presentation Layer

The Presentation Layer contains everything related to the user interface.

Responsibilities include:

- Screens
- Pages
- Widgets
- Dialogs
- Forms
- UI Validation
- User Interaction

The Presentation Layer never accesses SQLite directly.

Instead, it communicates with Cubits.

---

## Cubit Layer

Cubit is responsible for managing the application's business state.

Responsibilities include:

- Loading data
- Form validation
- Error handling
- State transitions
- UI updates
- Calling repositories

Each feature owns its own Cubit.

Examples:

```
AuthCubit
DashboardCubit
HostelCubit
RoomCubit
BedCubit
TenantCubit
RentCubit
ExpenseCubit
SettingsCubit
BackupCubit
```

Every Cubit exposes immutable states.

Example state flow:

```
Initial

↓

Loading

↓

Success

↓

Error
```

This predictable flow makes the application easier to debug and maintain.

---

## Repository Layer

Repositories act as the single source of truth.

Instead of allowing widgets to access SQLite directly, every operation passes through repositories.

Example:

```
UI

↓

RoomCubit

↓

RoomRepository

↓

SQLite
```

Responsibilities:

- CRUD Operations
- Business Logic
- Data Transformation
- Validation
- Error Handling

Benefits:

- Easy Testing
- Easy Refactoring
- Replaceable Data Source
- Cleaner UI

---

## Data Layer

The Data Layer communicates directly with SQLite.

Responsibilities:

- Database Queries
- Insert
- Update
- Delete
- Transactions
- Database Migrations

Only repositories communicate with the data layer.

No UI component accesses the database directly.

---

# Dependency Injection

The application uses **GetIt** as the Dependency Injection container.

Every repository, service, and Cubit is registered during application startup.

Benefits include:

- Loose Coupling
- Easy Unit Testing
- Faster Object Resolution
- Reusable Services
- Cleaner Constructors

Example:

```
GetIt

├── DatabaseService

├── SecureStorageService

├── AuthRepository

├── HostelRepository

├── RoomRepository

├── TenantRepository

├── ExpenseRepository

└── RentRepository
```

Every dependency is injected instead of being manually created throughout the application.

---

# State Management

State management is implemented using **flutter_bloc** with the **Cubit** pattern.

Why Cubit?

- Lightweight
- Predictable
- Easy to Debug
- Less Boilerplate
- Excellent Performance
- Feature Isolation

Each feature owns its own state.

Example:

```
Room State

Initial

↓

Loading

↓

Rooms Loaded

↓

Room Added

↓

Room Updated

↓

Room Deleted

↓

Error
```

The UI rebuilds only when necessary, improving rendering performance.

---

# Navigation

Navigation is handled using **GoRouter**.

Benefits:

- Named Routes
- Deep Linking
- Route Guards
- Authentication Redirects
- Clean Navigation Structure

Application routes include:

```
Splash

↓

Authentication

↓

Hostel Setup

↓

Dashboard

├── Rooms

├── Beds

├── Tenants

├── Rent

├── Expenses

├── Reports

└── Settings
```

The router ensures that unauthorized users cannot access protected pages.

---

# Repository Pattern

Every feature owns an independent repository.

Example:

```
Room Screen

↓

RoomCubit

↓

RoomRepository

↓

SQLite
```

Advantages:

- Single Source of Truth
- Easier Testing
- Cleaner UI
- Better Scalability
- Reusable Business Logic

---

# Offline-First Design

The application has been built with an Offline-First philosophy.

All critical operations are performed locally.

```
User Action

↓

Cubit

↓

Repository

↓

SQLite

↓

UI Updated
```

No internet connection is required for:

- Login Session
- Room Management
- Tenant Management
- Rent Collection
- Expense Tracking
- Reports
- Backup
- Restore

This makes the application reliable in environments with limited or unstable connectivity.

---

# Design Principles

The project follows several modern software engineering principles.

## SOLID Principles

- Single Responsibility Principle
- Open/Closed Principle
- Liskov Substitution Principle
- Interface Segregation Principle
- Dependency Inversion Principle

---

## Additional Principles

- DRY (Don't Repeat Yourself)
- KISS (Keep It Simple)
- Feature Isolation
- Separation of Concerns
- Composition over Inheritance
- Immutable State Management
- Reusable Components

---

# Why This Architecture?

As the application grows, new modules can be introduced without modifying existing ones.

Examples of future modules include:

- Staff Management
- Visitor Management
- Inventory Management
- Notifications
- Online Payments
- Cloud Synchronization
- Multi Hostel Support
- Multi Tenant Support

Because each feature is isolated, these additions can be implemented with minimal impact on the existing codebase.
# Application Lifecycle

The Hostel Management System follows a structured startup sequence to ensure that every required dependency is initialized before the user interacts with the application.

Rather than navigating directly to the login page, the application performs several initialization steps including dependency injection, database initialization, secure storage setup, session validation, and hostel configuration checks.

This approach provides a fast, secure, and reliable startup experience.

---

# Startup Flow

```
Application Launch
        │
        ▼
WidgetsFlutterBinding.ensureInitialized()
        │
        ▼
Initialize Native Splash
        │
        ▼
Configure Dependency Injection
        │
        ▼
Initialize SQLite Database
        │
        ▼
Initialize Secure Storage
        │
        ▼
Run Application
        │
        ▼
Splash Screen
        │
        ▼
Session Validation
        │
        ├──────────────► Not Logged In
        │                     │
        │                     ▼
        │                  Login Screen
        │
        ▼
Logged In
        │
        ▼
Hostel Exists?
        │
        ├──────────────► No
        │                   │
        │                   ▼
        │            Hostel Setup
        │
        ▼
Dashboard
```

---

# Application Initialization

The application's entry point is `main.dart`.

During startup, several initialization steps are performed before the UI is rendered.

### Step 1 – Flutter Initialization

```dart
WidgetsFlutterBinding.ensureInitialized();
```

This ensures Flutter is fully initialized before asynchronous operations begin.

It is required before:

- Opening SQLite
- Registering dependencies
- Accessing secure storage
- Initializing plugins

---

### Step 2 – Native Splash

The native splash screen remains visible while the application performs initialization tasks.

Benefits:

- Prevents blank white screen
- Improves perceived performance
- Provides smoother startup

---

### Step 3 – Dependency Injection

All services are registered using GetIt.

Examples include:

- Database Service
- Secure Storage Service
- Authentication Repository
- Hostel Repository
- Room Repository
- Tenant Repository
- Rent Repository
- Expense Repository

After registration, dependencies are available throughout the application.

---

### Step 4 – SQLite Initialization

The database layer prepares:

- Database creation
- Table creation
- Database migrations
- Foreign key support
- Transactions

If the database does not exist, it is created automatically.

---

### Step 5 – Secure Storage

Secure Storage loads:

- Login Session
- Authentication Token
- User Preferences

Sensitive information is never stored in SQLite.

---

### Step 6 – Run Application

Finally,

```dart
runApp()
```

renders the application's widget tree.

The first visible screen is the Splash Screen.

---

# Splash Screen

The Splash Screen is responsible for deciding where the user should be navigated.

It performs several checks:

```
Splash Screen

↓

Check Login Session

↓

Check Authentication

↓

Check Hostel Setup

↓

Navigate
```

The Splash Screen itself contains very little UI.

Its main responsibility is application routing.

---

# Authentication Flow

Authentication determines whether the user has an active session.

```
Splash

↓

Read Secure Storage

↓

Session Exists?
```

If no session exists:

```
↓

Login Screen
```

If a valid session exists:

```
↓

Dashboard Flow
```

This avoids forcing users to log in every time the application starts.

---

# Login Flow

```
Login Screen

↓

Enter Credentials

↓

Validate Input

↓

Authenticate User

↓

Store Session Securely

↓

Navigate Dashboard
```

Validation includes:

- Empty fields
- Invalid credentials
- Error handling

Successful login stores session information securely using Flutter Secure Storage.

---

# Hostel Setup Flow

The application supports first-time onboarding.

If no hostel has been configured:

```
Splash

↓

Hostel Found?

↓

No

↓

Hostel Setup Screen

↓

Save Hostel Information

↓

Dashboard
```

This setup only occurs once.

Subsequent launches skip directly to the dashboard.

---

# Dashboard Flow

After authentication, users arrive at the Dashboard.

The Dashboard aggregates information from multiple modules.

```
Dashboard

├── Room Statistics
├── Bed Statistics
├── Tenant Statistics
├── Rent Summary
├── Expense Summary
├── Profit Summary
└── Quick Actions
```

Each section loads independently through its own Cubit, allowing partial updates without rebuilding the entire screen.

---

# Feature Navigation Flow

```
Dashboard

├── Hostel
│
├── Rooms
│
├── Beds
│
├── Tenants
│
├── Rent
│
├── Expenses
│
├── Reports
│
├── Backup
│
├── Export
│
└── Settings
```

Each feature is isolated and communicates only through its own repository and Cubit.

---

# User Interaction Flow

The following sequence illustrates how a typical action is processed.

```
User Tap

↓

Flutter Widget

↓

Cubit Method

↓

Repository

↓

SQLite Database

↓

Repository Response

↓

Cubit State

↓

UI Rebuild
```

This ensures that business logic never resides inside widgets.

---

# Data Flow

Every operation follows the same architecture.

```
Presentation Layer

↓

Cubit

↓

Repository

↓

SQLite

↓

Repository

↓

Cubit

↓

UI
```

This one-way data flow makes debugging easier and keeps state predictable.

---

# Logout Flow

When the user logs out:

```
Dashboard

↓

Logout

↓

Clear Secure Storage

↓

Clear Session

↓

Navigate Login
```

The SQLite database remains intact.

Only authentication data is removed.

---

# Error Handling During Startup

The startup sequence is designed to fail gracefully.

Possible failures include:

- Database initialization failure
- Corrupted session
- Missing hostel configuration
- Storage read errors

In each case, the application redirects the user to the safest recovery screen instead of crashing.

---

# Startup Design Goals

The startup architecture was designed to achieve:

- Fast initialization
- Secure authentication
- Offline functionality
- Modular startup process
- Reliable navigation
- Clean dependency resolution
- Easy future expansion

Each initialization step has a single responsibility, making the startup process easier to maintain and extend.
# Application Lifecycle

The Hostel Management System follows a structured startup sequence to ensure that every required dependency is initialized before the user interacts with the application.

Rather than navigating directly to the login page, the application performs several initialization steps including dependency injection, database initialization, secure storage setup, session validation, and hostel configuration checks.

This approach provides a fast, secure, and reliable startup experience.

---

# Startup Flow

```
Application Launch
        │
        ▼
WidgetsFlutterBinding.ensureInitialized()
        │
        ▼
Initialize Native Splash
        │
        ▼
Configure Dependency Injection
        │
        ▼
Initialize SQLite Database
        │
        ▼
Initialize Secure Storage
        │
        ▼
Run Application
        │
        ▼
Splash Screen
        │
        ▼
Session Validation
        │
        ├──────────────► Not Logged In
        │                     │
        │                     ▼
        │                  Login Screen
        │
        ▼
Logged In
        │
        ▼
Hostel Exists?
        │
        ├──────────────► No
        │                   │
        │                   ▼
        │            Hostel Setup
        │
        ▼
Dashboard
```

---

# Application Initialization

The application's entry point is `main.dart`.

During startup, several initialization steps are performed before the UI is rendered.

### Step 1 – Flutter Initialization

```dart
WidgetsFlutterBinding.ensureInitialized();
```

This ensures Flutter is fully initialized before asynchronous operations begin.

It is required before:

- Opening SQLite
- Registering dependencies
- Accessing secure storage
- Initializing plugins

---

### Step 2 – Native Splash

The native splash screen remains visible while the application performs initialization tasks.

Benefits:

- Prevents blank white screen
- Improves perceived performance
- Provides smoother startup

---

### Step 3 – Dependency Injection

All services are registered using GetIt.

Examples include:

- Database Service
- Secure Storage Service
- Authentication Repository
- Hostel Repository
- Room Repository
- Tenant Repository
- Rent Repository
- Expense Repository

After registration, dependencies are available throughout the application.

---

### Step 4 – SQLite Initialization

The database layer prepares:

- Database creation
- Table creation
- Database migrations
- Foreign key support
- Transactions

If the database does not exist, it is created automatically.

---

### Step 5 – Secure Storage

Secure Storage loads:

- Login Session
- Authentication Token
- User Preferences

Sensitive information is never stored in SQLite.

---

### Step 6 – Run Application

Finally,

```dart
runApp()
```

renders the application's widget tree.

The first visible screen is the Splash Screen.

---

# Splash Screen

The Splash Screen is responsible for deciding where the user should be navigated.

It performs several checks:

```
Splash Screen

↓

Check Login Session

↓

Check Authentication

↓

Check Hostel Setup

↓

Navigate
```

The Splash Screen itself contains very little UI.

Its main responsibility is application routing.

---

# Authentication Flow

Authentication determines whether the user has an active session.

```
Splash

↓

Read Secure Storage

↓

Session Exists?
```

If no session exists:

```
↓

Login Screen
```

If a valid session exists:

```
↓

Dashboard Flow
```

This avoids forcing users to log in every time the application starts.

---

# Login Flow

```
Login Screen

↓

Enter Credentials

↓

Validate Input

↓

Authenticate User

↓

Store Session Securely

↓

Navigate Dashboard
```

Validation includes:

- Empty fields
- Invalid credentials
- Error handling

Successful login stores session information securely using Flutter Secure Storage.

---

# Hostel Setup Flow

The application supports first-time onboarding.

If no hostel has been configured:

```
Splash

↓

Hostel Found?

↓

No

↓

Hostel Setup Screen

↓

Save Hostel Information

↓

Dashboard
```

This setup only occurs once.

Subsequent launches skip directly to the dashboard.

---

# Dashboard Flow

After authentication, users arrive at the Dashboard.

The Dashboard aggregates information from multiple modules.

```
Dashboard

├── Room Statistics
├── Bed Statistics
├── Tenant Statistics
├── Rent Summary
├── Expense Summary
├── Profit Summary
└── Quick Actions
```

Each section loads independently through its own Cubit, allowing partial updates without rebuilding the entire screen.

---

# Feature Navigation Flow

```
Dashboard

├── Hostel
│
├── Rooms
│
├── Beds
│
├── Tenants
│
├── Rent
│
├── Expenses
│
├── Reports
│
├── Backup
│
├── Export
│
└── Settings
```

Each feature is isolated and communicates only through its own repository and Cubit.

---

# User Interaction Flow

The following sequence illustrates how a typical action is processed.

```
User Tap

↓

Flutter Widget

↓

Cubit Method

↓

Repository

↓

SQLite Database

↓

Repository Response

↓

Cubit State

↓

UI Rebuild
```

This ensures that business logic never resides inside widgets.

---

# Data Flow

Every operation follows the same architecture.

```
Presentation Layer

↓

Cubit

↓

Repository

↓

SQLite

↓

Repository

↓

Cubit

↓

UI
```

This one-way data flow makes debugging easier and keeps state predictable.

---

# Logout Flow

When the user logs out:

```
Dashboard

↓

Logout

↓

Clear Secure Storage

↓

Clear Session

↓

Navigate Login
```

The SQLite database remains intact.

Only authentication data is removed.

---

# Error Handling During Startup

The startup sequence is designed to fail gracefully.

Possible failures include:

- Database initialization failure
- Corrupted session
- Missing hostel configuration
- Storage read errors

In each case, the application redirects the user to the safest recovery screen instead of crashing.

---

# Startup Design Goals

The startup architecture was designed to achieve:

- Fast initialization
- Secure authentication
- Offline functionality
- Modular startup process
- Reliable navigation
- Clean dependency resolution
- Easy future expansion

Each initialization step has a single responsibility, making the startup process easier to maintain and extend.
# SQLite Database Design

The Hostel Management System follows an **Offline-First Architecture**, where SQLite serves as the primary data source for the entire application.

Unlike cloud-dependent applications, every operation—including room management, tenant registration, rent collection, expense tracking, and reporting—is performed locally. This ensures uninterrupted functionality regardless of internet availability.

SQLite was selected because it is lightweight, reliable, ACID-compliant, and perfectly suited for applications that require structured relational data with high performance.

---

# Why SQLite?

Several local database solutions were evaluated during the project design.

| Database | Reason |
|----------|--------|
| SQLite ✅ | Relational database, transactions, foreign keys, excellent for structured business data |
| Hive | Excellent key-value store but not ideal for relational data |
| Isar | Very fast NoSQL database, but SQLite provides better relational capabilities for this project |
| Firebase Firestore | Requires internet connectivity and incurs cloud costs |

Hostel management involves many interconnected entities such as rooms, beds, tenants, rent records, and expenses. These relationships are naturally represented using a relational database, making SQLite the most appropriate choice.

---

# Database Design Principles

The database was designed with the following goals:

- Data integrity
- Fast read/write performance
- Minimal redundancy
- Scalable schema
- ACID transactions
- Offline reliability
- Easy backup and restoration

---

# Database Architecture

```
Flutter UI
      │
      ▼
Cubit
      │
      ▼
Repository
      │
      ▼
SQLite Service
      │
      ▼
SQLite Database
```

The user interface never interacts with the database directly. Every request passes through the Repository layer, ensuring a clean separation of concerns.

---

# Entity Relationships

The application organizes data into interconnected entities.

```
Hostel
   │
   ├──────────────┐
   │              │
   ▼              ▼
Rooms         Expenses
   │
   ▼
Beds
   │
   ▼
Tenants
   │
   ▼
Rent Payments
```

Each entity represents a specific business domain while maintaining clear relationships with others.

---

# Database Tables

## Hostel Table

Stores the basic information about the hostel.

Example fields:

- id
- hostelName
- ownerName
- phone
- email
- address
- createdAt
- updatedAt

Only one hostel record is expected in the current version of the application.

---

## Room Table

Stores all room-related information.

Fields include:

- id
- roomNumber
- roomType
- capacity
- occupiedBeds
- status
- createdAt

Responsibilities:

- Room identification
- Occupancy tracking
- Capacity management

---

## Bed Table

Each room can contain one or more beds.

Fields include:

- id
- roomId
- bedNumber
- status

Relationships:

```
One Room

↓

Many Beds
```

This allows the system to manage occupancy at the bed level instead of only the room level.

---

## Tenant Table

Stores complete tenant information.

Fields include:

- id
- name
- phone
- email
- address
- identityNumber
- roomId
- bedId
- joiningDate
- status

Relationships:

```
One Bed

↓

One Active Tenant
```

A bed cannot be assigned to multiple active tenants simultaneously.

---

## Rent Table

Stores rent payment history.

Fields include:

- id
- tenantId
- month
- amount
- paymentDate
- paymentStatus

Relationships:

```
Tenant

↓

Multiple Rent Records
```

Every monthly payment generates a separate rent record, allowing complete historical tracking.

---

## Expense Table

Stores hostel operational expenses.

Fields include:

- id
- category
- amount
- description
- expenseDate

Example categories:

- Food
- Electricity
- Water
- Internet
- Salary
- Maintenance
- Miscellaneous

---

# Primary Keys

Each table uses an auto-incrementing primary key.

Example:

```
id INTEGER PRIMARY KEY AUTOINCREMENT
```

Benefits:

- Unique identification
- Faster indexing
- Easier relationships
- Better query performance

---

# Foreign Key Relationships

SQLite foreign keys maintain referential integrity.

Examples:

```
Room
   │
   └── roomId

Bed
   │
   └── roomId

Tenant
   │
   ├── roomId
   └── bedId

Rent
   │
   └── tenantId
```

This ensures that related records remain consistent across the database.

---

# Transactions

Critical operations are executed using SQLite transactions to maintain data consistency.

Examples include:

- Tenant Check-In
- Tenant Check-Out
- Rent Collection
- Backup Restoration

Example transaction flow:

```
Begin Transaction

↓

Assign Bed

↓

Create Tenant

↓

Update Room Occupancy

↓

Commit

↓

Success
```

If any step fails, the transaction is rolled back automatically, preventing partial updates and preserving data integrity.

---

# Database Indexing

Indexes improve query performance for frequently accessed data.

Recommended indexes include:

- roomNumber
- tenantName
- paymentStatus
- expenseDate
- month

Benefits:

- Faster search
- Improved filtering
- Better reporting performance

---

# CRUD Operations

Every entity supports standard database operations.

```
Create

↓

Read

↓

Update

↓

Delete
```

These operations are handled exclusively through their respective repositories.

---

# Backup Strategy

The backup system creates a complete copy of the SQLite database.

```
SQLite Database

↓

Backup File

↓

Local Storage
```

Advantages:

- Full database recovery
- Easy migration to another device
- Protection against accidental data loss

---

# Restore Strategy

The restore process replaces the current database with a previously saved backup.

```
Backup File

↓

Validation

↓

Replace Database

↓

Restart Application
```

Validation is performed before restoration to ensure compatibility and prevent corrupted data from being imported.

---

# Data Integrity

To maintain consistency, the application enforces several validation rules:

- Unique room numbers
- One active tenant per bed
- Valid foreign key references
- Positive rent amounts
- Valid expense values
- Required mandatory fields

These validations are implemented at both the application and database levels.

---

# Offline-First Workflow

Every user action is processed locally.

```
User Action

↓

Cubit

↓

Repository

↓

SQLite

↓

Success

↓

UI Updated
```

No network request is required for daily operations, ensuring the application remains responsive in all environments.

---

# Future Database Enhancements

The database architecture is designed for future scalability.

Planned enhancements include:

- Cloud synchronization
- Automatic conflict resolution
- Incremental backups
- Data encryption
- Audit logging
- Multi-hostel support
- Multi-user permissions
- Database versioning and migrations
- Remote API synchronization

These additions can be integrated without significant architectural changes due to the modular design of the application.
# Repository Pattern

The Hostel Management System implements the **Repository Pattern** to decouple the Presentation Layer from the Data Layer.

Instead of allowing widgets or Cubits to communicate directly with SQLite, every database operation is routed through a dedicated repository.

This creates a clean abstraction between business logic and data access, making the application easier to maintain, test, and extend.

---

## Why Repository Pattern?

Without repositories:

```
UI
 │
 ▼
SQLite
```

Problems:

- Tight coupling
- Difficult testing
- Duplicate SQL queries
- Poor maintainability
- Difficult migration to another database

With repositories:

```
UI

↓

Cubit

↓

Repository

↓

SQLite
```

Benefits:

- Clean architecture
- Single source of truth
- Easy testing
- Better maintainability
- Easier migration to APIs or cloud databases
- Reusable business logic

---

# Repository Responsibilities

Each feature owns its own repository.

Example:

```
RoomRepository

Responsibilities

• Create Room
• Update Room
• Delete Room
• Get All Rooms
• Search Rooms
• Check Room Availability
```

Similarly,

```
TenantRepository

• Create Tenant
• Update Tenant
• Delete Tenant
• Assign Room
• Assign Bed
• Checkout Tenant
• Search Tenant
```

Every repository focuses only on its own business domain.

---

# Data Flow

Every user action follows the same path.

```
User Click

↓

Flutter Widget

↓

Cubit Method

↓

Repository

↓

SQLite

↓

Repository Response

↓

Cubit State

↓

UI Update
```

This one-way flow keeps application state predictable.

---

# Repository Communication

Repositories communicate only with the database service.

Example:

```
Room Screen

↓

RoomCubit

↓

RoomRepository

↓

DatabaseService

↓

SQLite
```

Widgets never execute SQL queries directly.

---

# State Management

The application uses **flutter_bloc** with the **Cubit** pattern.

Cubit was selected because it provides a lightweight and predictable approach to state management while reducing boilerplate compared to the traditional Bloc pattern.

Each feature owns an independent Cubit responsible for managing only its own state.

---

# Why Cubit?

Cubit offers several advantages for medium and large Flutter applications.

Benefits include:

- Predictable state changes
- Feature isolation
- Easy debugging
- Minimal boilerplate
- High performance
- Better scalability
- Easier testing

---

# Cubit Architecture

```
Presentation

↓

Cubit

↓

Repository

↓

SQLite
```

The Cubit acts as the bridge between the user interface and the repository.

It receives user actions, performs validation, calls the repository, and emits new UI states.

---

# Cubit Lifecycle

Every Cubit follows a predictable lifecycle.

```
Initial

↓

Loading

↓

Success

↓

Error
```

Example:

```
RoomInitial

↓

RoomLoading

↓

RoomLoaded

↓

RoomError
```

The UI listens for state changes and rebuilds automatically when a new state is emitted.

---

# Example Flow

Creating a new room.

```
User Presses Save

↓

RoomCubit.addRoom()

↓

Validate Input

↓

RoomRepository.addRoom()

↓

SQLite INSERT

↓

Success

↓

Emit RoomLoaded

↓

UI Refresh
```

---

# Feature Isolation

Each feature owns its own Cubit.

Examples:

```
AuthCubit

DashboardCubit

HostelCubit

RoomCubit

BedCubit

TenantCubit

RentCubit

ExpenseCubit

BackupCubit

SettingsCubit
```

This prevents unrelated parts of the application from affecting one another.

---

# State Rebuild Strategy

Only widgets that depend on a specific Cubit rebuild.

Example:

```
Dashboard

├── Room Card
├── Tenant Card
├── Expense Card
└── Profit Card
```

If only room data changes,

Only:

```
Room Card
```

is rebuilt.

The remaining widgets remain unchanged.

This minimizes unnecessary rendering and improves performance.

---

# Dependency Injection

Dependency Injection is implemented using **GetIt**.

Rather than creating objects manually throughout the application, every dependency is registered once during startup and injected wherever needed.

---

# Why Dependency Injection?

Without Dependency Injection:

```
RoomCubit()

↓

new RoomRepository()

↓

new DatabaseService()
```

Problems:

- Tight coupling
- Difficult testing
- Duplicate instances
- Harder maintenance

With GetIt:

```
GetIt

↓

RoomCubit

↓

RoomRepository

↓

DatabaseService
```

Benefits:

- Single instance management
- Loose coupling
- Easier testing
- Cleaner constructors
- Better scalability

---

# Dependency Registration

During application startup, all dependencies are registered.

Examples include:

```
DatabaseService

SecureStorageService

RoomRepository

TenantRepository

ExpenseRepository

RentRepository

DashboardRepository

BackupRepository

ExportRepository
```

Once registered, these services are available throughout the application.

---

# Object Lifetime

Most services are registered as lazy singletons.

Advantages:

- Created only when needed
- Reduced memory usage
- Shared instance throughout the application

This improves startup performance while avoiding duplicate object creation.

---

# Navigation

Navigation is handled using **GoRouter**.

GoRouter provides a modern declarative routing solution with excellent support for nested routes, redirects, and route guards.

---

# Navigation Structure

```
Splash

↓

Login

↓

Hostel Setup

↓

Dashboard

├── Rooms

├── Beds

├── Tenants

├── Rent

├── Expenses

├── Reports

├── Backup

├── Export

└── Settings
```

---

# Route Protection

The application prevents unauthorized access to protected pages.

Example:

```
User Opens App

↓

Session Exists?

↓

Yes

↓

Dashboard

No

↓

Login
```

Authentication checks occur before navigation is completed.

---

# Deep Linking

The routing architecture has been designed to support future deep linking if required.

Examples:

```
hostel://rooms

hostel://tenant/15

hostel://rent

hostel://reports
```

Although not currently implemented, the navigation structure allows this capability to be added with minimal changes.

---

# Error Handling

Every layer has clearly defined responsibilities for handling errors.

```
SQLite Error

↓

Repository

↓

Cubit

↓

UI Message
```

Errors are never exposed directly to the user.

Instead, repositories convert low-level exceptions into meaningful application-level responses.

Examples include:

- Database unavailable
- Duplicate room number
- Invalid tenant assignment
- Failed backup
- Invalid restore file

This keeps the user experience consistent and user-friendly.

---

# Why This Architecture?

This architecture was chosen to support long-term maintainability.

As the application grows, new modules can be added without affecting existing features.

For example:

```
Visitor Management

↓

VisitorCubit

↓

VisitorRepository

↓

SQLite
```

No changes are required in the Room, Tenant, or Expense modules.

This modular approach makes the application easier to understand, easier to maintain, and ready for future enhancements such as cloud synchronization, REST APIs, and multi-hostel support.
# Security

Security has been considered throughout the application to protect sensitive information and ensure reliable data management.

## Secure Storage

The application uses **flutter_secure_storage** to securely store sensitive data such as:

- Login session
- Authentication tokens
- User preferences

Sensitive information is **never stored in SQLite**.

Flutter Secure Storage uses:

- **Android:** Android Keystore
- **iOS:** Apple Keychain

This provides platform-level encryption for confidential information.

---

## Input Validation

Every user input is validated before being stored.

Examples include:

- Required fields
- Email validation
- Phone number validation
- Positive numeric values
- Duplicate room numbers
- Duplicate bed numbers
- Invalid rent amounts
- Empty tenant names

Validation occurs before any database operation is executed.

---

## Data Integrity

The application protects data integrity by enforcing business rules such as:

- One active tenant per bed
- One room number per room
- Positive rent values
- Positive expense amounts
- Valid foreign key relationships

These validations help prevent inconsistent or corrupted data.

---

# Performance Optimizations

The project has been designed with performance in mind.

## Efficient Widget Rebuilds

Cubit ensures that only the necessary widgets rebuild when state changes.

Instead of rebuilding the entire screen:

```
Dashboard

├── Room Statistics
├── Tenant Statistics
├── Expense Statistics
└── Profit Statistics
```

Only the affected section updates.

---

## Lazy Dependency Initialization

Services are registered as lazy singletons using GetIt.

Benefits:

- Faster startup
- Reduced memory usage
- Single shared instances

---

## SQLite Performance

SQLite offers excellent performance for local applications.

Optimizations include:

- Indexed columns
- Efficient queries
- Transactions
- Local storage
- Minimal memory footprint

---

## Modular Architecture

Feature isolation prevents unnecessary dependencies between modules.

Benefits include:

- Faster development
- Easier maintenance
- Better scalability
- Simpler debugging

---

# Offline-First Strategy

Offline capability is one of the core design principles of this application.

All essential operations are performed locally.

Supported offline operations include:

- Authentication session
- Hostel management
- Room management
- Bed management
- Tenant management
- Rent collection
- Expense tracking
- Reports
- Backup
- Restore
- Data export

No internet connection is required for daily hostel operations.

---

# Backup & Restore

The application includes a local backup system to protect user data.

## Backup Flow

```
SQLite Database

↓

Generate Backup

↓

Save to Device Storage
```

The backup contains the complete SQLite database, allowing full restoration if required.

---

## Restore Flow

```
Select Backup File

↓

Validate File

↓

Replace Database

↓

Restart Application
```

This enables easy migration to another device or recovery from accidental data loss.

---

# Export System

Users can export hostel data for reporting, printing, or external analysis.

Supported formats:

- PDF
- CSV

Exportable information includes:

- Room List
- Tenant List
- Rent Records
- Expense Reports
- Financial Reports

---

# Packages Used

| Package | Purpose |
|---------|---------|
| flutter_bloc | State Management |
| get_it | Dependency Injection |
| go_router | Navigation |
| sqflite | Local Database |
| flutter_secure_storage | Secure Storage |
| path_provider | File System Access |
| intl | Date & Number Formatting |
| flutter_native_splash | Native Splash Screen |
| share_plus | Share Exported Files |
| pdf | PDF Generation |
| csv | CSV Export |

---

# Testing Strategy

The project has been structured to simplify testing.

## Unit Testing

Repositories and utility classes can be tested independently.

Examples:

- Business logic
- Data validation
- Calculations

---

## Widget Testing

Widget tests verify:

- UI rendering
- User interactions
- Form validation
- Navigation

---

## Integration Testing

Integration tests validate complete user workflows such as:

- Login
- Add Room
- Add Tenant
- Assign Bed
- Record Rent
- Add Expense
- Generate Reports

---

# Build Instructions

## Clone Repository

```bash
git clone https://github.com/AflahShadilk/hostel-management-system.git
```

> Replace the repository URL with your actual project URL after publishing.

---

## Install Dependencies

```bash
flutter pub get
```

---

## Run Application

```bash
flutter run
```

---

## Analyze Project

```bash
flutter analyze
```

---

## Run Tests

```bash
flutter test
```

---

# Release Builds

## Android APK

```bash
flutter build apk --release
```

---

## Android App Bundle

```bash
flutter build appbundle
```

---

## Windows

```bash
flutter build windows
```

---

## Linux

```bash
flutter build linux
```

---

## macOS

```bash
flutter build macos
```

---

# Future Roadmap

The architecture has been designed to support future enhancements without major structural changes.

Planned improvements include:

- Cloud synchronization
- Firebase integration
- REST API support
- Multi-hostel management
- Multi-user roles
- Staff management
- Visitor management
- Inventory management
- Push notifications
- QR code check-in
- Barcode integration
- Online payment gateway
- Dark mode enhancements
- Multi-language support
- Web admin panel
- Dashboard analytics
- Automated database migration

---

# Contributing

Contributions are welcome.

If you would like to improve the project:

1. Fork the repository.
2. Create a new feature branch.
3. Make your changes.
4. Test your implementation.
5. Submit a Pull Request.

Please follow the existing architecture and coding standards when contributing.

---

# License

This project is licensed under the **MIT License**.

Feel free to use, modify, and distribute the project in accordance with the license terms.

---

# Author

## Aflah Shadil K

Flutter Developer passionate about building scalable, maintainable, and production-ready cross-platform applications using modern Flutter technologies and clean architecture principles.

### Connect with Me

- **GitHub:** https://github.com/AflahShadilk
- **LinkedIn:** https://www.linkedin.com/in/aflah-shadil-k-223814248/

---

# Acknowledgements

This project was built to demonstrate modern Flutter application architecture and best practices, including:

- Feature-First Clean Architecture
- Repository Pattern
- Cubit State Management
- Dependency Injection
- Offline-First Design
- SQLite Database Management
- Secure Local Storage
- Modular Development

The architecture has been carefully designed to be maintainable, scalable, and suitable for real-world production environments.


# Security

Security has been considered throughout the application to protect sensitive information and ensure reliable data management.

## Secure Storage

The application uses **flutter_secure_storage** to securely store sensitive data such as:

- Login session
- Authentication tokens
- User preferences

Sensitive information is **never stored in SQLite**.

Flutter Secure Storage uses:

- **Android:** Android Keystore
- **iOS:** Apple Keychain

This provides platform-level encryption for confidential information.

---

## Input Validation

Every user input is validated before being stored.

Examples include:

- Required fields
- Email validation
- Phone number validation
- Positive numeric values
- Duplicate room numbers
- Duplicate bed numbers
- Invalid rent amounts
- Empty tenant names

Validation occurs before any database operation is executed.

---

## Data Integrity

The application protects data integrity by enforcing business rules such as:

- One active tenant per bed
- One room number per room
- Positive rent values
- Positive expense amounts
- Valid foreign key relationships

These validations help prevent inconsistent or corrupted data.

---

# Performance Optimizations

The project has been designed with performance in mind.

## Efficient Widget Rebuilds

Cubit ensures that only the necessary widgets rebuild when state changes.

Instead of rebuilding the entire screen:

```
Dashboard

├── Room Statistics
├── Tenant Statistics
├── Expense Statistics
└── Profit Statistics
```

Only the affected section updates.

---

## Lazy Dependency Initialization

Services are registered as lazy singletons using GetIt.

Benefits:

- Faster startup
- Reduced memory usage
- Single shared instances

---

## SQLite Performance

SQLite offers excellent performance for local applications.

Optimizations include:

- Indexed columns
- Efficient queries
- Transactions
- Local storage
- Minimal memory footprint

---

## Modular Architecture

Feature isolation prevents unnecessary dependencies between modules.

Benefits include:

- Faster development
- Easier maintenance
- Better scalability
- Simpler debugging

---

# Offline-First Strategy

Offline capability is one of the core design principles of this application.

All essential operations are performed locally.

Supported offline operations include:

- Authentication session
- Hostel management
- Room management
- Bed management
- Tenant management
- Rent collection
- Expense tracking
- Reports
- Backup
- Restore
- Data export

No internet connection is required for daily hostel operations.

---

# Backup & Restore

The application includes a local backup system to protect user data.

## Backup Flow

```
SQLite Database

↓

Generate Backup

↓

Save to Device Storage
```

The backup contains the complete SQLite database, allowing full restoration if required.

---

## Restore Flow

```
Select Backup File

↓

Validate File

↓

Replace Database

↓

Restart Application
```

This enables easy migration to another device or recovery from accidental data loss.

---

# Export System

Users can export hostel data for reporting, printing, or external analysis.

Supported formats:

- PDF
- CSV

Exportable information includes:

- Room List
- Tenant List
- Rent Records
- Expense Reports
- Financial Reports

---

# Packages Used

| Package | Purpose |
|---------|---------|
| flutter_bloc | State Management |
| get_it | Dependency Injection |
| go_router | Navigation |
| sqflite | Local Database |
| flutter_secure_storage | Secure Storage |
| path_provider | File System Access |
| intl | Date & Number Formatting |
| flutter_native_splash | Native Splash Screen |
| share_plus | Share Exported Files |
| pdf | PDF Generation |
| csv | CSV Export |

---

# Testing Strategy

The project has been structured to simplify testing.

## Unit Testing

Repositories and utility classes can be tested independently.

Examples:

- Business logic
- Data validation
- Calculations

---

## Widget Testing

Widget tests verify:

- UI rendering
- User interactions
- Form validation
- Navigation

---

## Integration Testing

Integration tests validate complete user workflows such as:

- Login
- Add Room
- Add Tenant
- Assign Bed
- Record Rent
- Add Expense
- Generate Reports

---

# Build Instructions

## Clone Repository

```bash
git clone https://github.com/AflahShadilk/hostel-management-system.git
```

> Replace the repository URL with your actual project URL after publishing.

---

## Install Dependencies

```bash
flutter pub get
```

---

## Run Application

```bash
flutter run
```

---

## Analyze Project

```bash
flutter analyze
```

---

## Run Tests

```bash
flutter test
```

---

# Release Builds

## Android APK

```bash
flutter build apk --release
```

---

## Android App Bundle

```bash
flutter build appbundle
```

---

## Windows

```bash
flutter build windows
```

---

## Linux

```bash
flutter build linux
```

---

## macOS

```bash
flutter build macos
```

---

# Future Roadmap

The architecture has been designed to support future enhancements without major structural changes.

Planned improvements include:

- Cloud synchronization
- Firebase integration
- REST API support
- Multi-hostel management
- Multi-user roles
- Staff management
- Visitor management
- Inventory management
- Push notifications
- QR code check-in
- Barcode integration
- Online payment gateway
- Dark mode enhancements
- Multi-language support
- Web admin panel
- Dashboard analytics
- Automated database migration

---

# Contributing

Contributions are welcome.

If you would like to improve the project:

1. Fork the repository.
2. Create a new feature branch.
3. Make your changes.
4. Test your implementation.
5. Submit a Pull Request.

Please follow the existing architecture and coding standards when contributing.

---

# License

This project is licensed under the **MIT License**.

Feel free to use, modify, and distribute the project in accordance with the license terms.

---

# Author

## Aflah Shadil K

Flutter Developer passionate about building scalable, maintainable, and production-ready cross-platform applications using modern Flutter technologies and clean architecture principles.

### Connect with Me

- **GitHub:** https://github.com/AflahShadilk
- **LinkedIn:** https://www.linkedin.com/in/aflah-shadil-k-223814248/

---

# Acknowledgements

This project was built to demonstrate modern Flutter application architecture and best practices, including:

- Feature-First Clean Architecture
- Repository Pattern
- Cubit State Management
- Dependency Injection
- Offline-First Design
- SQLite Database Management
- Secure Local Storage
- Modular Development

The architecture has been carefully designed to be maintainable, scalable, and suitable for real-world production environments.