# Project Structure for Macro + Budget Meal Planner

## Root Directory Structure

```
macro_budget_meal_planner/
├── android/                    # Android-specific configuration and build files
│   ├── app/
│   │   ├── src/main/
│   │   │   ├── kotlin/         # Android native code (if needed)
│   │   │   └── AndroidManifest.xml
│   │   └── build.gradle
│   ├── gradle/
│   └── build.gradle
├── assets/                     # Static assets and resources
│   ├── images/                 # App icons, illustrations, and graphics
│   │   ├── icons/              # UI icons and navigation icons
│   │   ├── illustrations/      # Onboarding and empty state illustrations
│   │   └── food/               # Food category and ingredient images
│   ├── data/                   # Seed data files
│   │   ├── ingredients.json    # Seed ingredient database
│   │   ├── recipes.json        # Seed recipe library
│   │   └── nutritional_data/   # Additional nutritional reference data
│   └── fonts/                  # Custom fonts (if any)
├── lib/                        # Main Flutter application code
│   ├── main.dart               # Application entry point
│   ├── app/                    # App-level configuration
│   │   ├── app.dart            # Main app widget and theme configuration
│   │   ├── routes.dart         # App routing configuration
│   │   └── constants/          # App-wide constants
│   ├── core/                   # Core utilities and shared functionality
│   │   ├── database/           # Database configuration and setup
│   │   │   ├── database.dart   # Drift database definition
│   │   │   ├── tables/         # Database table definitions
│   │   │   └── migrations/     # Database migration files
│   │   ├── services/           # Core services and utilities
│   │   │   ├── storage_service.dart      # Local storage abstraction
│   │   │   ├── billing_service.dart      # Google Play Billing service
│   │   │   ├── analytics_service.dart    # Privacy-respecting analytics
│   │   │   └── export_service.dart       # Data export functionality
│   │   ├── models/             # Core data models and entities
│   │   │   ├── ingredient.dart           # Ingredient model
│   │   │   ├── recipe.dart              # Recipe model
│   │   │   ├── plan.dart                # Meal plan model
│   │   │   ├── user_targets.dart        # User preferences model
│   │   │   └── pantry_item.dart         # Pantry item model
│   │   ├── repositories/       # Data access layer
│   │   │   ├── ingredient_repository.dart
│   │   │   ├── recipe_repository.dart
│   │   │   ├── plan_repository.dart
│   │   │   └── user_repository.dart
│   │   ├── providers/          # Riverpod state management providers
│   │   │   ├── app_providers.dart        # App-level providers
│   │   │   ├── user_providers.dart       # User data providers
│   │   │   └── plan_providers.dart       # Planning engine providers
│   │   ├── utils/              # Utility functions and helpers
│   │   │   ├── macro_calculator.dart     # Nutritional calculations
│   │   │   ├── cost_calculator.dart      # Cost estimation utilities
│   │   │   ├── unit_converter.dart       # Unit conversion utilities
│   │   │   └── validators.dart           # Input validation utilities
│   │   └── extensions/         # Dart extension methods
│   │       ├── string_extensions.dart
│   │       ├── datetime_extensions.dart
│   │       └── number_extensions.dart
│   ├── features/               # Feature-based modules
│   │   ├── onboarding/         # User onboarding flow
│   │   │   ├── screens/        # Onboarding screens
│   │   │   │   ├── welcome_screen.dart
│   │   │   │   ├── goals_screen.dart
│   │   │   │   ├── budget_screen.dart
│   │   │   │   ├── preferences_screen.dart
│   │   │   │   └── summary_screen.dart
│   │   │   ├── widgets/        # Onboarding-specific widgets
│   │   │   └── providers/      # Onboarding state providers
│   │   ├── planning/           # Meal planning functionality
│   │   │   ├── screens/        # Planning screens
│   │   │   │   ├── plan_overview_screen.dart
│   │   │   │   ├── plan_detail_screen.dart
│   │   │   │   └── swap_screen.dart
│   │   │   ├── widgets/        # Planning-specific widgets
│   │   │   │   ├── meal_card.dart
│   │   │   │   ├── macro_summary.dart
│   │   │   │   ├── swap_drawer.dart
│   │   │   │   └── plan_grid.dart
│   │   │   ├── services/       # Planning engine services
│   │   │   │   ├── plan_generator.dart
│   │   │   │   ├── swap_engine.dart
│   │   │   │   └── optimization_engine.dart
│   │   │   └── providers/      # Planning state providers
│   │   ├── shopping/           # Shopping list functionality
│   │   │   ├── screens/        # Shopping screens
│   │   │   │   ├── shopping_list_screen.dart
│   │   │   │   └── price_edit_screen.dart
│   │   │   ├── widgets/        # Shopping-specific widgets
│   │   │   │   ├── shopping_item_card.dart
│   │   │   │   ├── aisle_section.dart
│   │   │   │   └── cost_summary.dart
│   │   │   ├── services/       # Shopping list services
│   │   │   │   ├── list_generator.dart
│   │   │   │   └── pack_calculator.dart
│   │   │   └── providers/      # Shopping state providers
│   │   ├── pantry/             # Pantry management (Pro feature)
│   │   │   ├── screens/        # Pantry screens
│   │   │   │   ├── pantry_screen.dart
│   │   │   │   └── add_pantry_item_screen.dart
│   │   │   ├── widgets/        # Pantry-specific widgets
│   │   │   └── providers/      # Pantry state providers
│   │   ├── recipes/            # Recipe management
│   │   │   ├── screens/        # Recipe screens
│   │   │   │   ├── recipe_list_screen.dart
│   │   │   │   ├── recipe_detail_screen.dart
│   │   │   │   └── add_recipe_screen.dart
│   │   │   ├── widgets/        # Recipe-specific widgets
│   │   │   └── providers/      # Recipe state providers
│   │   ├── settings/           # App settings and preferences
│   │   │   ├── screens/        # Settings screens
│   │   │   │   ├── settings_screen.dart
│   │   │   │   ├── profile_screen.dart
│   │   │   │   ├── subscription_screen.dart
│   │   │   │   └── about_screen.dart
│   │   │   ├── widgets/        # Settings-specific widgets
│   │   │   └── providers/      # Settings state providers
│   │   └── auth/               # Pro subscription and billing
│   │       ├── screens/        # Billing screens
│   │       │   ├── paywall_screen.dart
│   │       │   └── trial_screen.dart
│   │       ├── widgets/        # Billing-specific widgets
│   │       └── providers/      # Billing state providers
│   └── shared/                 # Shared UI components and utilities
│       ├── widgets/            # Reusable widgets
│       │   ├── buttons/        # Custom button components
│       │   ├── cards/          # Card components
│       │   ├── inputs/         # Input field components
│       │   ├── navigation/     # Navigation components
│       │   ├── dialogs/        # Dialog and modal components
│       │   └── loading/        # Loading and progress indicators
│       ├── theme/              # App theming and design system
│       │   ├── app_theme.dart  # Material Design 3 theme definition
│       │   ├── colors.dart     # Color palette
│       │   ├── typography.dart # Text styles
│       │   └── dimensions.dart # Spacing and sizing constants
│       └── constants/          # Shared constants
│           ├── app_constants.dart
│           ├── api_constants.dart
│           └── asset_constants.dart
├── test/                       # Test files
│   ├── unit/                   # Unit tests
│   │   ├── core/               # Core functionality tests
│   │   │   ├── models/         # Model tests
│   │   │   ├── repositories/   # Repository tests
│   │   │   ├── services/       # Service tests
│   │   │   └── utils/          # Utility tests
│   │   └── features/           # Feature-specific unit tests
│   │       ├── planning/       # Planning engine tests
│   │       ├── shopping/       # Shopping list tests
│   │       └── onboarding/     # Onboarding tests
│   ├── integration/            # Integration tests
│   │   ├── app_test.dart       # Full app integration tests
│   │   ├── planning_flow_test.dart
│   │   └── billing_flow_test.dart
│   ├── widget/                 # Widget tests
│   │   ├── screens/            # Screen widget tests
│   │   └── widgets/            # Component widget tests
│   └── test_utils/             # Test utilities and mocks
│       ├── mock_data.dart      # Mock data for testing
│       ├── mock_services.dart  # Mock service implementations
│       └── test_helpers.dart   # Test helper functions
├── docs/                       # Project documentation
│   ├── Implementation.md       # This implementation plan
│   ├── project_structure.md    # This project structure document
│   ├── UI_UX_doc.md           # UI/UX design documentation
│   └── api_documentation/      # API documentation (for v1.1+ external APIs)
├── tools/                      # Development tools and scripts
│   ├── build_runner.dart       # Code generation scripts
│   ├── seed_data_generator.dart # Tool to generate/update seed data
│   └── asset_optimizer.dart    # Asset optimization scripts
├── .github/                    # GitHub Actions and workflows (if using GitHub)
│   └── workflows/
│       ├── ci.yml              # Continuous integration
│       └── release.yml         # Release automation
├── pubspec.yaml                # Flutter dependencies and configuration
├── pubspec.lock                # Dependency lock file
├── analysis_options.yaml       # Dart/Flutter linting rules
├── .gitignore                  # Git ignore rules
├── README.md                   # Project README
└── CHANGELOG.md                # Version changelog
```

## Detailed Structure Explanation

### `/lib` Directory Organization

The main application code follows a **feature-based architecture** combined with **clean architecture principles**:

#### **Core Layer (`/lib/core/`)**
Contains shared functionality and business logic that's used across multiple features:

- **Database**: Drift database configuration, table definitions, and migrations
- **Models**: Core data entities that represent the business domain
- **Repositories**: Data access layer that abstracts database operations
- **Services**: Business logic services (billing, analytics, export)
- **Providers**: Riverpod providers for state management
- **Utils**: Pure utility functions for calculations and conversions

#### **Features Layer (`/lib/features/`)**
Each feature is organized as a self-contained module:

- **Screens**: UI screens and pages for the feature
- **Widgets**: Feature-specific reusable widgets
- **Services**: Feature-specific business logic
- **Providers**: Feature-specific state management

#### **Shared Layer (`/lib/shared/`)**
Contains reusable UI components and design system elements:

- **Widgets**: Generic, reusable widgets used across features
- **Theme**: Material Design 3 implementation and design tokens
- **Constants**: App-wide constants and configuration

### **Asset Organization (`/assets/`)**

Assets are organized by type and usage:

```
assets/
├── images/
│   ├── icons/                  # 24x24, 48x48 UI icons (SVG preferred)
│   │   ├── navigation/         # Bottom navigation icons
│   │   ├── actions/            # Action button icons
│   │   └── categories/         # Food category icons
│   ├── illustrations/          # Larger graphics and illustrations
│   │   ├── onboarding/         # Welcome and tutorial illustrations
│   │   ├── empty_states/       # Empty state illustrations
│   │   └── success/            # Success state illustrations
│   └── food/                   # Food and ingredient images
│       ├── categories/         # Food category images
│       └── ingredients/        # Specific ingredient photos
├── data/                       # Seed data and reference files
│   ├── ingredients.json        # ~300 seed ingredients with nutrition data
│   ├── recipes.json           # ~100 seed recipes with instructions
│   ├── food_categories.json   # Food category definitions
│   └── nutritional_reference/ # Additional nutrition reference data
└── fonts/                     # Custom fonts (if needed)
    └── inter/                 # Inter font family (example)
```

### **Configuration Files**

#### **`pubspec.yaml` Structure**
```yaml
name: macro_budget_meal_planner
description: Make it effortless to eat within your macro targets and grocery budget
version: 1.0.0+1

environment:
  sdk: '>=3.0.0 <4.0.0'
  flutter: ">=3.16.0"

dependencies:
  flutter:
    sdk: flutter
  
  # State Management
  flutter_riverpod: ^2.4.0
  riverpod_annotation: ^2.3.0
  
  # Database & Storage
  drift: ^2.14.0
  sqlite3_flutter_libs: ^0.5.0
  path_provider: ^2.1.0
  shared_preferences: ^2.2.0
  hive: ^4.0.0
  hive_flutter: ^1.1.0
  
  # Billing & Monetization
  in_app_purchase: ^3.1.0
  
  # UI & Navigation
  go_router: ^12.0.0
  
  # HTTP & Serialization (for v1.1+)
  dio: ^5.3.0
  json_annotation: ^4.8.0
  
  # Utilities
  intl: ^0.18.0
  collection: ^1.17.0

dev_dependencies:
  flutter_test:
    sdk: flutter
  
  # Code Generation
  build_runner: ^2.4.0
  riverpod_generator: ^2.3.0
  drift_dev: ^2.14.0
  json_serializable: ^6.7.0
  
  # Testing
  mocktail: ^1.0.0
  
  # Linting
  flutter_lints: ^3.0.0

flutter:
  uses-material-design: true
  assets:
    - assets/images/
    - assets/data/
  fonts:
    - family: Inter
      fonts:
        - asset: assets/fonts/inter/Inter-Regular.ttf
        - asset: assets/fonts/inter/Inter-Medium.ttf
          weight: 500
        - asset: assets/fonts/inter/Inter-SemiBold.ttf
          weight: 600
```

### **Build and Deployment Structure**

#### **Android Configuration (`/android/`)**
- **`app/build.gradle`**: App-level build configuration, signing, and release settings
- **`app/src/main/AndroidManifest.xml`**: App permissions, activities, and metadata
- **`gradle/wrapper/`**: Gradle wrapper configuration
- **`app/src/main/res/`**: Android resources (app icons, splash screens)

#### **Environment-Specific Configuration**
```
config/
├── development.json           # Development environment settings
├── staging.json              # Staging environment settings
├── production.json           # Production environment settings
└── flavor_config.dart        # Flutter flavor configuration
```

### **Testing Structure**

The testing structure mirrors the main application structure:

- **Unit Tests**: Test individual functions, classes, and business logic
- **Widget Tests**: Test individual widgets and their behavior
- **Integration Tests**: Test complete user flows and feature interactions
- **Golden Tests**: Visual regression tests for UI components

### **Development Workflow Files**

#### **Code Generation**
- **`build.yaml`**: Build configuration for code generation
- **Code generation commands**: Used for Riverpod, Drift, and JSON serialization

#### **Linting and Analysis**
- **`analysis_options.yaml`**: Dart/Flutter linting rules and analysis configuration
- **Custom lint rules**: Enforce architectural patterns and code quality

### **Module Dependencies**

The architecture follows these dependency rules:

1. **Core** modules have no dependencies on feature modules
2. **Feature** modules can depend on core modules and shared modules
3. **Shared** modules can only depend on core modules
4. **Features** should not depend on other features directly

### **File Naming Conventions**

- **Screens**: `*_screen.dart` (e.g., `plan_overview_screen.dart`)
- **Widgets**: `*_widget.dart` or descriptive names (e.g., `meal_card.dart`)
- **Models**: Singular nouns (e.g., `ingredient.dart`, `recipe.dart`)
- **Services**: `*_service.dart` (e.g., `billing_service.dart`)
- **Repositories**: `*_repository.dart` (e.g., `plan_repository.dart`)
- **Providers**: `*_provider.dart` or `*_providers.dart` for multiple providers
- **Constants**: `*_constants.dart` (e.g., `app_constants.dart`)

### **Import Organization**

Follow this import order in all Dart files:

1. Dart SDK imports
2. Flutter framework imports
3. Third-party package imports
4. Local app imports (relative imports within the same feature)
5. Cross-feature imports (absolute imports)

Example:
```dart
import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:drift/drift.dart';

import '../widgets/meal_card.dart';
import '../services/plan_generator.dart';

import 'package:macro_budget_meal_planner/core/models/recipe.dart';
import 'package:macro_budget_meal_planner/shared/widgets/loading_indicator.dart';
```

This structure provides:
- **Scalability**: Easy to add new features without affecting existing code
- **Maintainability**: Clear separation of concerns and logical organization
- **Testability**: Each layer can be tested independently
- **Reusability**: Shared components can be easily reused across features
- **Team Collaboration**: Clear boundaries make it easier for multiple developers to work simultaneously
