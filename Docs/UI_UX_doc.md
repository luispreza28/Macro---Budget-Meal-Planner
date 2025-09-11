# UI/UX Documentation for Macro + Budget Meal Planner

## Design System Specifications

### Design Philosophy

The Macro + Budget Meal Planner follows **Material Design 3 (Material You)** principles with a focus on:

- **Clarity**: Information hierarchy that makes complex nutritional data easy to understand
- **Efficiency**: Streamlined workflows that minimize planning friction
- **Trust**: Professional appearance that builds confidence in nutritional calculations
- **Accessibility**: Inclusive design that works for users with diverse needs

### Color System

#### Primary Color Palette
Based on Material Design 3 dynamic theming:

```dart
// Primary Colors - Green theme (nutrition/health focused)
static const Color primaryColor = Color(0xFF4CAF50);      // Primary green
static const Color primaryVariant = Color(0xFF388E3C);    // Darker green
static const Color onPrimary = Color(0xFFFFFFFF);         // White text on primary

// Secondary Colors - Blue theme (budget/financial focused)
static const Color secondaryColor = Color(0xFF2196F3);    // Primary blue
static const Color secondaryVariant = Color(0xFF1976D2);  // Darker blue
static const Color onSecondary = Color(0xFFFFFFFF);       // White text on secondary

// Surface Colors
static const Color surface = Color(0xFFFAFAFA);           // Light background
static const Color surfaceVariant = Color(0xFFF5F5F5);   // Card backgrounds
static const Color onSurface = Color(0xFF1C1B1F);        // Primary text
static const Color onSurfaceVariant = Color(0xFF49454F); // Secondary text

// Error Colors
static const Color error = Color(0xFFBA1A1A);            // Error red
static const Color onError = Color(0xFFFFFFFF);          // White text on error

// Success Colors (custom)
static const Color success = Color(0xFF2E7D32);          // Success green
static const Color onSuccess = Color(0xFFFFFFFF);        // White text on success

// Warning Colors (custom)
static const Color warning = Color(0xFFF57C00);          // Warning orange
static const Color onWarning = Color(0xFFFFFFFF);        // White text on warning
```

#### Semantic Colors

```dart
// Macro-specific colors
static const Color proteinColor = Color(0xFFE53935);     // Red for protein
static const Color carbsColor = Color(0xFF1E88E5);       // Blue for carbs
static const Color fatColor = Color(0xFFFFB300);         // Orange for fat
static const Color caloriesColor = Color(0xFF43A047);    // Green for calories

// Budget-specific colors
static const Color budgetGreenColor = Color(0xFF2E7D32); // Under budget
static const Color budgetYellowColor = Color(0xFFF57C00); // Near budget
static const Color budgetRedColor = Color(0xFFD32F2F);   // Over budget

// Status colors
static const Color freeFeatureColor = Color(0xFF757575); // Gray for free features
static const Color proFeatureColor = Color(0xFF9C27B0);  // Purple for Pro features
```

### Typography System

Based on Material Design 3 type scale with custom adjustments for nutritional data:

```dart
// Display Text Styles
static const TextStyle displayLarge = TextStyle(
  fontSize: 57,
  fontWeight: FontWeight.w400,
  letterSpacing: -0.25,
  height: 1.12,
);

static const TextStyle displayMedium = TextStyle(
  fontSize: 45,
  fontWeight: FontWeight.w400,
  letterSpacing: 0,
  height: 1.16,
);

// Headline Text Styles
static const TextStyle headlineLarge = TextStyle(
  fontSize: 32,
  fontWeight: FontWeight.w400,
  letterSpacing: 0,
  height: 1.25,
);

static const TextStyle headlineMedium = TextStyle(
  fontSize: 28,
  fontWeight: FontWeight.w400,
  letterSpacing: 0,
  height: 1.29,
);

// Title Text Styles
static const TextStyle titleLarge = TextStyle(
  fontSize: 22,
  fontWeight: FontWeight.w500,
  letterSpacing: 0,
  height: 1.27,
);

static const TextStyle titleMedium = TextStyle(
  fontSize: 16,
  fontWeight: FontWeight.w500,
  letterSpacing: 0.15,
  height: 1.5,
);

// Body Text Styles
static const TextStyle bodyLarge = TextStyle(
  fontSize: 16,
  fontWeight: FontWeight.w400,
  letterSpacing: 0.5,
  height: 1.5,
);

static const TextStyle bodyMedium = TextStyle(
  fontSize: 14,
  fontWeight: FontWeight.w400,
  letterSpacing: 0.25,
  height: 1.43,
);

// Custom Styles for Nutritional Data
static const TextStyle macroValue = TextStyle(
  fontSize: 20,
  fontWeight: FontWeight.w600,
  letterSpacing: 0,
  height: 1.2,
);

static const TextStyle macroLabel = TextStyle(
  fontSize: 12,
  fontWeight: FontWeight.w500,
  letterSpacing: 0.5,
  height: 1.33,
);

static const TextStyle priceText = TextStyle(
  fontSize: 16,
  fontWeight: FontWeight.w600,
  letterSpacing: 0,
  height: 1.25,
  fontFeatures: [FontFeature.tabularFigures()], // Monospace numbers
);
```

### Component Library

#### Core Components

##### 1. Macro Display Component
```dart
// MacroCard widget for displaying nutritional information
Widget MacroCard({
  required String label,
  required double value,
  required double target,
  required Color color,
  String unit = 'g',
  bool showProgress = true,
}) {
  return Card(
    child: Padding(
      padding: EdgeInsets.all(16),
      child: Column(
        children: [
          Text(label, style: macroLabel),
          Text('${value.toInt()}$unit', style: macroValue.copyWith(color: color)),
          if (showProgress) 
            LinearProgressIndicator(
              value: value / target,
              backgroundColor: color.withOpacity(0.2),
              valueColor: AlwaysStoppedAnimation(color),
            ),
          Text('of ${target.toInt()}$unit target', style: bodySmall),
        ],
      ),
    ),
  );
}
```

##### 2. Budget Display Component
```dart
// BudgetSummary widget for cost tracking
Widget BudgetSummary({
  required double currentCost,
  required double budgetLimit,
  bool showDetails = true,
}) {
  final percentage = currentCost / budgetLimit;
  final isOverBudget = percentage > 1.0;
  final isNearBudget = percentage > 0.85;
  
  Color statusColor = budgetGreenColor;
  if (isOverBudget) statusColor = budgetRedColor;
  else if (isNearBudget) statusColor = budgetYellowColor;
  
  return Card(
    child: Padding(
      padding: EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Weekly Budget', style: titleMedium),
              Text('\$${currentCost.toStringAsFixed(2)}', 
                   style: priceText.copyWith(color: statusColor)),
            ],
          ),
          LinearProgressIndicator(
            value: percentage.clamp(0.0, 1.0),
            backgroundColor: statusColor.withOpacity(0.2),
            valueColor: AlwaysStoppedAnimation(statusColor),
          ),
          Text('of \$${budgetLimit.toStringAsFixed(2)} budget', 
               style: bodySmall),
        ],
      ),
    ),
  );
}
```

##### 3. Meal Card Component
```dart
// MealCard widget for displaying individual meals
Widget MealCard({
  required Recipe recipe,
  required VoidCallback onTap,
  required VoidCallback onSwap,
  bool showSwapButton = true,
  bool isPro = false,
}) {
  return Card(
    margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Row(
          children: [
            // Recipe image or placeholder
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Container(
                width: 60,
                height: 60,
                color: surfaceVariant,
                child: Icon(Icons.restaurant, color: onSurfaceVariant),
              ),
            ),
            SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(recipe.name, style: titleMedium),
                  Text('${recipe.timeMinutes} min • \$${recipe.costPerServing.toStringAsFixed(2)}',
                       style: bodySmall.copyWith(color: onSurfaceVariant)),
                  Row(
                    children: [
                      MacroChip(label: '${recipe.macrosPerServing.protein}P', 
                               color: proteinColor),
                      MacroChip(label: '${recipe.macrosPerServing.carbs}C', 
                               color: carbsColor),
                      MacroChip(label: '${recipe.macrosPerServing.fat}F', 
                               color: fatColor),
                    ],
                  ),
                ],
              ),
            ),
            if (showSwapButton)
              IconButton(
                onPressed: onSwap,
                icon: Icon(Icons.swap_horiz),
                tooltip: 'Swap meal',
              ),
          ],
        ),
      ),
    ),
  );
}
```

#### Navigation Components

##### Bottom Navigation
```dart
// Custom bottom navigation with 4 main tabs
Widget AppBottomNavigation({
  required int currentIndex,
  required Function(int) onTap,
}) {
  return NavigationBar(
    selectedIndex: currentIndex,
    onDestinationSelected: onTap,
    destinations: [
      NavigationDestination(
        icon: Icon(Icons.calendar_view_week),
        selectedIcon: Icon(Icons.calendar_view_week),
        label: 'Plan',
      ),
      NavigationDestination(
        icon: Icon(Icons.shopping_cart_outlined),
        selectedIcon: Icon(Icons.shopping_cart),
        label: 'Shopping',
      ),
      NavigationDestination(
        icon: Icon(Icons.kitchen_outlined),
        selectedIcon: Icon(Icons.kitchen),
        label: 'Pantry',
      ),
      NavigationDestination(
        icon: Icon(Icons.settings_outlined),
        selectedIcon: Icon(Icons.settings),
        label: 'Settings',
      ),
    ],
  );
}
```

### Responsive Design Requirements

#### Breakpoints
```dart
class ScreenBreakpoints {
  static const double mobile = 600;      // 0-600px: Mobile phones
  static const double tablet = 840;      // 600-840px: Small tablets
  static const double desktop = 1200;    // 840-1200px: Large tablets
  static const double widescreen = 1600; // 1200px+: Desktop/wide screens
}
```

#### Adaptive Layouts

##### Mobile Layout (Primary target)
- **Single column layout** for all screens
- **Bottom navigation** for primary navigation
- **Floating action buttons** for primary actions
- **Card-based design** for content organization
- **Swipe gestures** for secondary actions

##### Tablet Layout (Future consideration)
- **Two-column layout** for plan view (days on left, details on right)
- **Side navigation rail** instead of bottom navigation
- **Larger cards** with more information density
- **Split-screen modals** for detailed views

#### Responsive Grid System
```dart
// Responsive grid for meal planning view
Widget ResponsivePlanGrid({required List<Day> days}) {
  return LayoutBuilder(
    builder: (context, constraints) {
      if (constraints.maxWidth < ScreenBreakpoints.tablet) {
        // Mobile: Vertical scrolling list
        return ListView.builder(
          itemCount: days.length,
          itemBuilder: (context, index) => DayCard(day: days[index]),
        );
      } else {
        // Tablet+: Grid layout
        return GridView.builder(
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: constraints.maxWidth > ScreenBreakpoints.desktop ? 4 : 2,
            childAspectRatio: 1.2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
          ),
          itemCount: days.length,
          itemBuilder: (context, index) => DayCard(day: days[index]),
        );
      }
    },
  );
}
```

### Accessibility Standards

#### WCAG 2.1 AA Compliance

##### Color and Contrast
- **Minimum contrast ratio**: 4.5:1 for normal text, 3:1 for large text
- **Color independence**: Information never conveyed by color alone
- **Focus indicators**: Visible focus states for all interactive elements

##### Typography and Readability
- **Dynamic Type support**: Respects user's system font size preferences
- **Minimum touch targets**: 44x44dp minimum for all interactive elements
- **Text scaling**: Supports up to 200% text scaling without horizontal scrolling

##### Screen Reader Support
```dart
// Semantic labels for complex widgets
Widget MacroSummaryCard() {
  return Semantics(
    label: 'Daily macro summary',
    child: Card(
      child: Column(
        children: [
          Semantics(
            label: 'Protein: 120 grams of 150 gram target, 80 percent complete',
            child: MacroProgressBar(
              label: 'Protein',
              value: 120,
              target: 150,
              color: proteinColor,
            ),
          ),
          // ... other macros
        ],
      ),
    ),
  );
}
```

##### Keyboard Navigation
- **Tab order**: Logical tab sequence through interactive elements
- **Keyboard shortcuts**: Common shortcuts for power users
- **Focus management**: Proper focus handling in modals and navigation

#### Voice Control Support
```dart
// Voice control hints for common actions
Widget SwapButton() {
  return Semantics(
    hint: 'Double tap to see meal alternatives',
    child: IconButton(
      onPressed: () => showSwapOptions(),
      icon: Icon(Icons.swap_horiz),
    ),
  );
}
```

### User Experience Flow Diagrams

#### Onboarding Flow
```
Start App → Welcome Screen → Goals Setup → Budget Setup → 
Preferences → Equipment → Summary → Generate First Plan → Main App
```

**Onboarding Screens:**
1. **Welcome**: App introduction and value proposition
2. **Goals**: Macro targets (calories, protein, carbs, fat)
3. **Budget**: Weekly grocery budget (optional)
4. **Preferences**: Meals per day, time constraints, dietary restrictions
5. **Equipment**: Available cooking equipment
6. **Summary**: Review and confirm settings
7. **First Plan**: Generate and preview initial meal plan

#### Main App Flow
```
Plan Overview → Meal Detail → Swap Options → Apply Swap → 
Updated Plan → Shopping List → Pantry Check → Export List
```

#### Pro Upgrade Flow
```
Free Feature Limit → Paywall → Trial Offer → Payment → 
Pro Features Unlocked → Enhanced Experience
```

### User Journey Maps

#### Primary User Journey: Weekly Meal Planning

**Persona**: Jules (Cutter) - 31 years old, wants to hit protein targets while staying under budget

1. **Entry Point**: Opens app on Sunday evening
2. **Goal Setting**: Reviews/adjusts macro targets (1,700 kcal, 150g protein)
3. **Plan Generation**: Generates new 7-day plan with budget constraint
4. **Plan Review**: Reviews generated meals, checks macro totals
5. **Meal Swapping**: Swaps 2-3 meals for variety/preference
6. **Shopping List**: Reviews shopping list, adjusts prices
7. **Pantry Check**: Marks items already available (Pro feature)
8. **Export**: Exports final shopping list to grocery app
9. **Weekly Execution**: Follows plan throughout week

**Pain Points Addressed**:
- Quick plan generation (<2 seconds)
- Clear macro progress visualization
- Easy meal swapping with impact preview
- Accurate cost estimation with price editing
- Seamless export to external apps

#### Secondary Journey: Recipe Discovery

**Persona**: Rae (Bulker) - 28 years old, wants high-calorie meals with minimal prep time

1. **Browse Recipes**: Explores recipe library filtered by calories/time
2. **Recipe Details**: Views ingredients, instructions, macro breakdown
3. **Add to Plan**: Adds recipe to current meal plan
4. **Plan Adjustment**: System rebalances other meals for macro targets
5. **Save Favorite**: Saves recipe for future use
6. **Share Recipe**: Shares recipe with friends (future feature)

### Wireframe References

#### Key Screen Wireframes

##### Plan Overview Screen
```
┌─────────────────────────────┐
│ ☰ Plan Overview        ⚙️  │
├─────────────────────────────┤
│ [Macro Summary Cards]       │
│ Calories: 1,650/1,700       │
│ Protein: 145g/150g          │
│ Budget: $48/$55             │
├─────────────────────────────┤
│ Week of March 11-17         │
├─────────────────────────────┤
│ Monday                      │
│ [Breakfast Card] [Swap]     │
│ [Lunch Card] [Swap]         │
│ [Dinner Card] [Swap]        │
├─────────────────────────────┤
│ Tuesday                     │
│ [Breakfast Card] [Swap]     │
│ [Lunch Card] [Swap]         │
│ [Dinner Card] [Swap]        │
├─────────────────────────────┤
│ [Generate New Plan] [FAB]   │
└─────────────────────────────┘
```

##### Shopping List Screen
```
┌─────────────────────────────┐
│ ☰ Shopping List        📤   │
├─────────────────────────────┤
│ Total: $47.85 of $55.00     │
│ [Progress Bar]              │
├─────────────────────────────┤
│ 🥬 Produce                  │
│ ☐ Spinach (1 bag) - $2.99  │
│ ☐ Bananas (2 lbs) - $1.58  │
│ ☐ Chicken breast (2 lbs)    │
│     - $8.99 [Edit Price]    │
├─────────────────────────────┤
│ 🥛 Dairy                    │
│ ☐ Greek yogurt (32oz) - $4.99│
│ ☐ Eggs (12 count) - $2.49  │
├─────────────────────────────┤
│ 🍞 Pantry                   │
│ ☐ Rice (2 lb bag) - $3.99  │
│ ☐ Olive oil (16oz) - $4.99 │
└─────────────────────────────┘
```

### Design Tool Integration

#### Figma Integration
- **Design System Library**: Shared component library in Figma
- **Token Sync**: Design tokens synced between Figma and Flutter
- **Prototype Handoff**: Interactive prototypes for user testing
- **Asset Export**: Automated asset export from Figma to Flutter

#### Development Handoff
- **Design Specs**: Detailed specifications for each component
- **Asset Delivery**: SVG icons and illustrations optimized for Flutter
- **Animation Specs**: Motion design specifications for transitions
- **Responsive Specs**: Breakpoint-specific layout specifications

### Animation and Motion Design

#### Micro-interactions
```dart
// Smooth transitions for macro progress updates
AnimatedContainer(
  duration: Duration(milliseconds: 300),
  curve: Curves.easeInOut,
  width: progressWidth,
  height: 8,
  decoration: BoxDecoration(
    color: macroColor,
    borderRadius: BorderRadius.circular(4),
  ),
)

// Satisfying swap animation
SlideTransition(
  position: Tween<Offset>(
    begin: Offset.zero,
    end: Offset(1.0, 0.0),
  ).animate(CurvedAnimation(
    parent: animationController,
    curve: Curves.elasticOut,
  )),
  child: MealCard(),
)
```

#### Page Transitions
- **Hero animations** for meal cards to detail views
- **Shared element transitions** between plan and shopping list
- **Slide transitions** for navigation between main sections
- **Fade transitions** for modal overlays and dialogs

#### Loading States
- **Shimmer effects** for loading meal cards
- **Progress indicators** for plan generation
- **Skeleton screens** for data-heavy views
- **Smooth state transitions** between loading, success, and error states

This comprehensive UI/UX documentation ensures consistent, accessible, and user-friendly design throughout the Macro + Budget Meal Planner application, following Material Design 3 principles while addressing the specific needs of nutrition and budget planning users.
