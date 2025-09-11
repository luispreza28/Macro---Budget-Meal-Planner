# Implementation Plan for Macro + Budget Meal Planner

## Feature Analysis

### Identified Features:

**Core Planning Features:**
- User onboarding with macro targets, budget, meals/day, time constraints, diet flags, and equipment
- 7-day meal plan generation with macro optimization and budget constraints
- Real-time swap engine for meal alternatives with delta impact display
- Shopping list generation with aisle grouping, pack rounding, and cost estimation
- Pantry-first planning (Pro feature) to reduce costs by using on-hand items
- Multiple planning modes: Cutting, Bulking (Budget & No-Budget), Solo-on-a-Budget preset

**Data Management Features:**
- Local-first storage with seed ingredient database (~300 items)
- Seed recipe library (~100 recipes) with owned IP
- User recipe creation with automatic macro/cost calculation
- Price override system for ingredient costs
- Optional external data integration (USDA FDC, OpenFoodFacts) for v1.1+

**User Experience Features:**
- Settings management for targets, preferences, and dietary restrictions
- Dynamic Type support and accessibility features
- Export functionality (text/Markdown for free, CSV/PDF for Pro)
- Offline-first functionality with full feature access without network

**Monetization Features:**
- Free vs Pro feature gating
- Google Play Billing integration for subscriptions ($3.99/mo or $24/yr)
- 7-day trial with annual plan pre-selection

### Feature Categorization:

**Must-Have Features (v1.0):**
- User onboarding and settings
- Plan generation engine with macro optimization
- Swap functionality
- Shopping list with cost estimation
- Local storage and offline functionality
- Free vs Pro gating
- Google Play Billing integration
- Seed data (ingredients and recipes)
- Material Design 3 UI implementation

**Should-Have Features (v1.0):**
- Pantry-first planning (Pro)
- Multiple planning modes
- Export functionality (basic text/Markdown)
- Price override system
- Accessibility features
- Performance optimization

**Nice-to-Have Features (v1.1+):**
- External data integration (USDA FDC, OpenFoodFacts)
- Advanced export formats (CSV/PDF)
- iOS version
- Cloud sync capabilities
- Meal prep mode
- Family scaling features

## Recommended Tech Stack

### Frontend:
- **Framework:** Flutter 3.16+ - Cross-platform framework with excellent performance, Material Design 3 support, and strong community
- **Documentation:** https://docs.flutter.dev/

### State Management:
- **Framework:** Riverpod 2.4+ - Modern, compile-safe state management with excellent testing support and dependency injection
- **Documentation:** https://riverpod.dev/

### Database:
- **Database:** Drift (formerly Moor) 2.14+ - Type-safe SQLite wrapper with excellent offline support, migrations, and reactive queries
- **Documentation:** https://drift.simonbinder.eu/

### Local Storage:
- **Framework:** SharedPreferences + Hive 4.0+ - SharedPreferences for simple settings, Hive for complex object storage and caching
- **Documentation:** 
  - SharedPreferences: https://pub.dev/packages/shared_preferences
  - Hive: https://docs.hivedb.dev/

### Billing & Monetization:
- **Framework:** in_app_purchase 3.1+ - Official Flutter plugin for Google Play Billing with subscription support
- **Documentation:** https://pub.dev/packages/in_app_purchase

### UI/UX:
- **Framework:** Material Design 3 (Flutter Material library) - Modern design system with dynamic theming and accessibility
- **Documentation:** https://docs.flutter.dev/ui/design/material

### Additional Tools:
- **HTTP Client:** dio 5.3+ - Powerful HTTP client for external API integration (v1.1+)
- **Documentation:** https://pub.dev/packages/dio

- **JSON Serialization:** json_annotation + json_serializable 6.7+ - Code generation for type-safe JSON handling
- **Documentation:** https://pub.dev/packages/json_annotation

- **Routing:** go_router 12.0+ - Declarative routing with deep linking support
- **Documentation:** https://pub.dev/packages/go_router

- **Testing:** flutter_test + mocktail - Built-in testing framework with modern mocking
- **Documentation:** https://docs.flutter.dev/testing

## Ii nmplementation Stages

### Stage 1: Foundation & Setup

**Duration:** 1-2 weeks

**Dependencies:** None

#### Sub-steps:

- [ ] Set up Flutter development environment with latest stable version (3.16+)
- [ ] Initialize Flutter project with proper package name and configuration
- [ ] Configure build tools and CI/CD pipeline for Android
- [ ] Set up project structure following clean architecture principles
- [ ] Configure Riverpod for state management
- [ ] Set up Drift database with initial schema design
- [ ] Implement basic app routing with go_router
- [ ] Create base theme using Material Design 3
- [ ] Set up testing infrastructure and basic unit tests
- [ ] Configure code generation tools (json_serializable, Drift)

### Stage 2: Core Data Layer

**Duration:** 2-3 weeks

**Dependencies:** Stage 1 completion

#### Sub-steps:

- [ ] Design and implement complete database schema for ingredients, recipes, plans, and user data
- [ ] Create data models for all entities (Ingredient, Recipe, Plan, UserTargets, etc.)
- [ ] Implement repository pattern for data access
- [ ] Create seed data service for ingredients (~300 items) and recipes (~100 items)
- [ ] Implement local storage for user preferences and settings
- [ ] Create database migration system for future updates
- [ ] Implement data validation and error handling
- [ ] Set up reactive data streams with Riverpod providers
- [ ] Create comprehensive unit tests for data layer
- [ ] Implement backup and restore functionality for user data

### Stage 3: Planning Engine

**Duration:** 3-4 weeks

**Dependencies:** Stage 2 completion

#### Sub-steps:

- [ ] Implement macro calculation engine with accurate nutritional math
- [ ] Create plan generation algorithm with multi-objective optimization
- [ ] Implement mode-specific planning logic (Cutting, Bulking Budget/No-Budget)
- [ ] Create swap engine with delta impact calculation
- [ ] Implement pantry-first planning algorithm for Pro users
- [ ] Create cost calculation engine with pack rounding
- [ ] Implement variety penalty and prep time constraints
- [ ] Add performance optimization for plan generation (<2s requirement)
- [ ] Create comprehensive testing for planning algorithms
- [ ] Implement plan validation and error recovery

### Stage 4: User Interface & Experience

**Duration:** 2-3 weeks

**Dependencies:** Stage 3 completion

#### Sub-steps:

- [ ] Implement onboarding flow with macro targets and preferences setup
- [ ] Create main plan view with 7-day grid and totals bar
- [ ] Implement swap drawer with reason badges and impact display
- [ ] Create shopping list UI with aisle grouping and price editing
- [ ] Implement pantry management interface for Pro users
- [ ] Create settings screens for all user preferences
- [ ] Implement responsive design for different screen sizes
- [ ] Add accessibility features (Dynamic Type, VoiceOver labels, high contrast)
- [ ] Create loading states and error handling UI
- [ ] Implement smooth animations and transitions

### Stage 5: Monetization & Pro Features

**Duration:** 1-2 weeks

**Dependencies:** Stage 4 completion

#### Sub-steps:

- [ ] Integrate Google Play Billing with in_app_purchase package
- [ ] Implement subscription management (monthly/annual plans)
- [ ] Create paywall UI with feature comparison
- [ ] Implement Pro feature gating throughout the app
- [ ] Add 7-day trial functionality with proper trial tracking
- [ ] Create subscription status management and restoration
- [ ] Implement export functionality (text/Markdown for free, CSV/PDF for Pro)
- [ ] Add "Manage Subscription" deep linking to Google Play
- [ ] Test billing flows thoroughly including edge cases
- [ ] Implement analytics for conversion tracking (privacy-respecting)

### Stage 6: Polish & Optimization

**Duration:** 2-3 weeks

**Dependencies:** Stage 5 completion

#### Sub-steps:

- [ ] Conduct comprehensive testing across different Android devices
- [ ] Optimize app performance and reduce memory usage
- [ ] Implement proper error handling and crash reporting
- [ ] Enhance UI/UX based on internal testing feedback
- [ ] Add app size optimization and reduce bundle size (<40MB requirement)
- [ ] Implement proper app lifecycle management
- [ ] Create comprehensive integration tests
- [ ] Optimize database queries and implement proper indexing
- [ ] Add proper logging and debugging tools
- [ ] Prepare Google Play Store assets and descriptions

### Stage 7: Release Preparation

**Duration:** 1 week

**Dependencies:** Stage 6 completion

#### Sub-steps:

- [ ] Final testing on target devices (Pixel 5 equivalent and lower-end devices)
- [ ] Create Google Play Console listing with screenshots and descriptions
- [ ] Implement privacy policy and terms of service
- [ ] Set up crash reporting and analytics (opt-in)
- [ ] Configure app signing and release builds
- [ ] Create user documentation and support materials
- [ ] Set up customer support channels
- [ ] Plan soft launch strategy and rollout phases
- [ ] Prepare marketing materials and app store optimization
- [ ] Final security review and compliance check

## Resource Links

### Official Documentation:
- [Flutter Documentation](https://docs.flutter.dev/) - Complete Flutter development guide
- [Riverpod Documentation](https://riverpod.dev/) - State management best practices
- [Drift Database Documentation](https://drift.simonbinder.eu/) - SQLite integration and migrations
- [Material Design 3 for Flutter](https://docs.flutter.dev/ui/design/material) - UI design system
- [Google Play Billing](https://developer.android.com/google/play/billing) - Android billing integration
- [in_app_purchase Package](https://pub.dev/packages/in_app_purchase) - Flutter billing implementation

### Best Practices Guides:
- [Flutter Architecture Samples](https://github.com/brianegan/flutter_architecture_samples) - Clean architecture patterns
- [Flutter Performance Best Practices](https://docs.flutter.dev/perf/best-practices) - Performance optimization
- [Flutter Accessibility](https://docs.flutter.dev/development/accessibility-and-localization/accessibility) - Accessibility implementation
- [Android App Bundle Guide](https://developer.android.com/guide/app-bundle) - App size optimization

### Testing Resources:
- [Flutter Testing Documentation](https://docs.flutter.dev/testing) - Comprehensive testing guide
- [Mocktail Package](https://pub.dev/packages/mocktail) - Modern mocking for tests
- [Integration Testing](https://docs.flutter.dev/testing/integration-tests) - End-to-end testing

### External APIs (v1.1+):
- [USDA FoodData Central API](https://fdc.nal.usda.gov/api-guide.html) - Nutritional data integration
- [OpenFoodFacts API](https://openfoodfacts.github.io/openfoodfacts-server/api/) - Barcode and product data

## Timeline Summary

**Total Estimated Duration:** 12-16 weeks for v1.0 Android release

**Key Milestones:**
- Week 2: Foundation complete, development environment ready
- Week 5: Core data layer and database implementation complete
- Week 9: Planning engine with all optimization algorithms complete
- Week 12: Full UI/UX implementation with accessibility features
- Week 14: Monetization and Pro features integrated
- Week 17: Final polish, testing, and release preparation complete

**Critical Path Items:**
- Planning engine optimization (performance requirements)
- Google Play Billing integration and testing
- Comprehensive device testing and performance validation
- Store review process and approval timeline

## Risk Mitigation

**Technical Risks:**
- Performance on low-end devices: Implement progressive loading and caching strategies
- Complex planning algorithm: Break down into smaller, testable components
- Database migration issues: Comprehensive testing and rollback strategies

**Business Risks:**
- App store approval delays: Early submission for review and compliance check
- User adoption: Focus on core value proposition and smooth onboarding
- Monetization conversion: A/B testing of paywall placement and trial length

**Timeline Risks:**
- Feature creep: Strict adherence to v1.0 scope as defined in PRD
- External dependencies: Fallback plans for third-party service integration
- Testing bottlenecks: Parallel testing streams and automated test coverage
