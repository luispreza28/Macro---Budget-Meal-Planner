# Macro + Budget Meal Planner — Product Requirements Document (PRD)
_Last updated: 2025-09-09_

---

## 0) Document Purpose & Audience
This PRD defines the end-to-end requirements for the **Macro + Budget Meal Planner** app. It is intended for product, engineering, design, QA, marketing, and compliance. The scope covers **v1 launch** and **near-term v1.x** iterations. This document is source-of-truth for acceptance, test planning, and store submissions.

---

## 1) Vision & Strategy
**Vision:** Make it effortless to eat within your **macro targets** *and* your **grocery budget**, without spreadsheets or guesswork.

**Strategy:**  
- **Local-first**: fast, private, deterministic calculations.  
- **Clear value**: weekly plan, one-tap swaps, consolidated shopping list with cost.  
- **Modular**: a planning engine that accepts constraints (diet flags, time, equipment, pantry-first, budget/no-budget modes).  
- **Sustainable**: own all recipe IP; allow user data entry; optional public databases with caching.

**North-star outcome:** Users hit their macros and budget ≥4 weeks in a row with <10 minutes of weekly adjustments.

---

## 2) Problem Statement
People want to eat for a goal (cut, bulk, maintain) but face three blockers:  
1) **Planning friction** (macro math is tedious).  
2) **Budget uncertainty** (prices are variable, overspend happens easily).  
3) **Inflexibility** (all-or-nothing plans break when reality changes).

**Opportunity:** A planner that optimizes both **macros** and **money**, adapts to constraints, and stays simple.

---

## 3) Objectives & Key Results (OKRs)
**O1: Drive consistent planning.**  
- KR1: ≥ 55% of new users complete onboarding and generate a plan in day 1.  
- KR2: ≥ 35% of new users regenerate/adjust a plan in week 2.

**O2: Deliver measurable savings.**  
- KR3: 70% of Pro users report “met budget” at least 3 of 4 weeks (in-app pulse).

**O3: Monetize without ads.**  
- KR4: Free→Pro conversion ≥ 5% by day 14; annual plan share ≥ 60% of Pro.

---

## 4) In-Scope vs Out-of-Scope
**In-scope (v1):**  
- Onboarding: targets (kcal, P/C/F), **weekly budget**, meals/day, time cap, diet flags, equipment.  
- Planner (7-day) + **swap engine**.  
- **Shopping list** with aisle groups, pack rounding, cost estimate, and inline price edits.  
- **Pantry-first** (Pro): use on-hand items first.  
- Modes: **Cutting**; **Bulking (Budget & No-Budget)**; **Solo-on-a-Budget** preset.  
- Local-first storage; seed ingredient table + recipe library (we own).  
- Optional external data (v1.1+): USDA FDC, OpenFoodFacts.
- **Platforms (v1.0): Android only — Google Play**
- **iOS (App Store) targeted for v1.1+ (post-PMF)**


**Out-of-scope (v1):**  
- Barcode scanning live price, coupons, or retailer integrations.  
- Medical guidance or clinical features.  
- Multi-user collaboration.
- iOS launch (StoreKit, ATT, iOS assets) — planned for v1.1+

---

## 5) Personas (v1 focus)
1) **Student Saver — “Sam” (22)**  
   - **Goal:** 2,000 kcal; P130 C220 F60; **$40/wk**; 2 meals + 1 snack; dorm gear only.  
   - **Win:** Plan ≤ $40; prep ≤ 2.5 hrs; repeats OK.

2) **Cutter — “Jules” (31)**  
   - **Goal:** 1,700 kcal; **Protein ≥150g**; **Fat ≈45g**; **$55/wk**; 3 meals + 2 snacks.  
   - **Win:** Fullness/high-volume; hit protein; ≤ budget.

3) **Bulker — “Rae” (28)**  
   - **Goal:** 3,000 kcal; P180 C400 F90; 4 meals/day.  
   - **Variants:** **Budget $85/wk** vs **No-budget** (time-optimized).  
   - **Win:** Calories met; cheap calories (budget) OR minimal prep time (no-budget).

---

## 6) User Stories & Acceptance Criteria

### 6.1 Onboarding
- **Story:** As a new user, I set macros, budget, meals/day, time cap, diet flags.  
- **AC:** Saving shows a **preview day** in <300 ms; values editable later in Settings.

### 6.2 Plan Generation
- **Story:** As a user, I generate a **7-day plan** that hits macros and respects budget.  
- **AC:**  
  - Daily kcal error ≤ **±5%**; protein ≥ 100% of target.  
  - Weekly cost ≤ budget (if set), else estimate shown.  
  - Generation (warm) completes in **<2 s** on mid-range.

### 6.3 Swaps
- **Story:** I can fix cost or macros via **one-tap swaps**.  
- **AC:** Suggested alternatives display **delta impact** (e.g., “- $3/week”, “+12 g protein/day”). Apply in **≤300 ms**.

### 6.4 Shopping List
- **Story:** I get a consolidated list with grouped aisles and an **estimated total** I can adjust.  
- **AC:** Inline price edits instantly update totals. Pack rounding shows leftovers.

### 6.5 Pantry-First (Pro)
- **Story:** I mark what I have; planner uses those first to reduce cost.  
- **AC:** Estimated spend drops accordingly; pantry deduction visible per item.

### 6.6 Modes
- **Story:** I switch between Cutting and Bulking modes; for Bulking, choose Budget vs No-budget.  
- **AC:** Recipe choices and labels change (cost/time emphasis).

---

## 7) Functional Requirements

### 7.1 Recipe & Ingredient Data
- **Seed ingredient table** (~300 items): per-100 g/mL macros; default price per unit; aisle; purchase pack size; tags.  
- **Seed recipe library** (~100 recipes): we own IP; each recipe has servings, time, diet flags, items (ingredient_id, qty, unit), steps.  
- **User recipes**: paste ingredients; app calculates macros & cost; users can edit.

**Normalization:** Internally store in grams (g) / milliliters (mL) / piece. Display using locale prefs (imperial/metric). Densities optional; avoid risky cup↔gram conversions unless known.

### 7.2 External Data (v1.1+)
- **USDA FDC** (generic foods): `dataType=Foundation, SR Legacy`; map nutrients **208 kcal**, **203 protein_g**, **204 fat_g**, **205 carbs_g**.  
- **OpenFoodFacts** (barcodes): `energy-kcal_100g`, `proteins_100g`, `fat_100g`, `carbohydrates_100g`.  
- **Caching:** Selected items cached locally with source badges (FDC/OFF/Manual). Planner must work offline.

### 7.3 Planner Engine
- **Inputs:** Targets (kcal, P/C/F), budget (nullable), meals/day, time cap, diet flags, equipment, pantry list, mode (Cut/Bulk-Budget/Bulk-NoBudget).  
- **Objective function:**  
  ```
  S = w1·macro_error + w2·budget_error + w3·variety_penalty
      + w4·prep_time_penalty + w5·pantry_bonus
  ```
  - `macro_error`: L1 of (kcal,P,C,F) vs targets; **under-protein penalized 2×**.  
  - `budget_error`: max(0, cost - budget).  
  - `variety_penalty`: repeat dinner >2× penalized.  
  - `prep_time_penalty`: total recipe time vs cap.  
  - `pantry_bonus`: negative term for using pantry items.

- **Algorithm:**  
  1) **Seed** meal slots with cheap macro-appropriate templates by mode.  
  2) **Greedy refine** to hit protein/kcal.  
  3) **Local search**: evaluate N candidate swaps per slot (cheaper, macro-closer, pantry-using).  
  4) **Stop** at no improvement or time budget (≤ 300 ms/iteration, total ≤ 2 s).

- **Mode tuning:**  
  - **Cutting:** higher w1 (macro) + prep_time_penalty low; emphasize high-volume recipes.  
  - **Bulk—Budget:** include **$/1000 kcal** term; prefer calorie-dense cheap staples.  
  - **Bulk—No-budget:** reduce budget weight; increase prep_time_penalty (favor quick meals).

### 7.4 Swap Engine
- For a selected meal, surface top-5 alternatives ranked by **Δscore**.  
- Show **reason badges**: “- $3/week”, “+12 g protein/day”, “uses pantry rice”.  
- Apply swap → recompute totals and list instantly.

### 7.5 Shopping List Algorithm
1) **Aggregate** ingredients across plan (servings applied).  
2) **Normalize** units to base (g/mL/piece).  
3) **Subtract Pantry** quantities.  
4) **Convert to purchase packs** (e.g., rice 1 kg bag): round **up**; show leftover.  
5) **Estimate cost**: packs × price_per_pack (editable).  
6) **Group by aisle**; add checkboxes.  
7) **Export**: share text/Markdown; **Pro**: CSV/PDF.

**Edge handling:** fractional cans/packs, spices/sauces assumed on hand (toggle), bulk-store “exact grams” mode.

### 7.6 Settings
- Units (imperial/metric), currency, macro targets, budget, meals/day, time cap, diet flags, equipment.  
- Presets: Free=1; Pro=multiple.  
- Privacy links; “Manage Subscription”; export data.

### 7.7 Accessibility
- Dynamic Type; sufficient contrast; VoiceOver labels for macros/cost; large tap targets.

---

## 8) Non-Functional Requirements
- **Performance:** warm plan gen < 2 s; swap apply < 300 ms.  
- **App size:** ≤ 40 MB.  
- **Reliability:** crash-free sessions ≥ 99.5%.  
- **Offline:** full functionality without network.  
- **Privacy:** no ads/trackers; all data local by default.  
- **Security:** scoped storage; encrypt backups if/when sync launches.

---

## 9) Data Model (Types)
```ts
type MoneyCents = number;
type Unit = 'g'|'ml'|'piece';

Ingredient {
  id: string;
  name: string;
  unit: Unit;                     // base unit to price in
  macros_per_100g: { kcal: number, protein_g: number, carbs_g: number, fat_g: number };
  price_per_unit_cents: MoneyCents;  // price per 'unit'
  purchase_pack: { qty: number, unit: Unit, price_cents?: MoneyCents };
  aisle: 'produce'|'meat'|'dairy'|'pantry'|'frozen'|'condiments'|'bakery'|'household';
  tags: string[];                 // 'cheap','veg','gf','df','bulk','high_volume'
  source: 'seed'|'fdc'|'off'|'manual';
  last_verified_at?: string;
}

Recipe {
  id: string;
  name: string;
  servings: number;
  time_mins: number;
  cuisine?: string;
  diet_flags: string[];
  items: Array<{ ingredient_id: string, qty: number, unit: Unit }>;
  steps: string[];
  macros_per_serv: { kcal: number, protein_g: number, carbs_g: number, fat_g: number };
  cost_per_serv_cents: MoneyCents;
  source: 'seed'|'manual';
}

UserTargets {
  kcal: number; protein_g: number; carbs_g: number; fat_g: number;
  budget_cents: MoneyCents | null;
  meals_per_day: number;
  time_cap_mins?: number;
  diet_flags: string[];
  equipment: string[];
}

PantryItem { ingredient_id: string, qty: number, unit: Unit }

Plan {
  id: string;
  days: Array<{ date: string, meals: Array<{ recipe_id: string, servings: number, notes?: string }> }>;
  totals: { kcal: number, protein_g: number, carbs_g: number, fat_g: number, cost_cents: MoneyCents };
}

PriceOverride { ingredient_id: string, price_per_unit_cents: MoneyCents, purchase_pack?: { qty: number, unit: Unit, price_cents: MoneyCents } }
```

---

## 10) UX Flows (text wireframes)

### 10.1 Onboarding
1) Goals → (kcal, P/C/F) with presets for Cutting/Bulking/Custom  
2) Budget → weekly $ (skip allowed)  
3) Meals/day & time cap → (2–5 meals; 10/20/30/45 min)  
4) Diet & equipment → toggles  
5) **Generate Plan** → lands on Plan screen with Totals Bar

### 10.2 Plan Screen
- 7-day grid → tap meal → **Swap Drawer** (reasons + impact).  
- Totals Bar: kcal/P/C/F vs target + **$ vs budget**.

### 10.3 Pantry
- Search ingredient → add qty; tap to mark as “on hand”.  
- “Use Pantry” toggle (Pro): planner re-generates with pantry bonus.

### 10.4 List
- Grouped by aisle; prices editable; “Buy X packs” with leftover note.  
- Share → system sheet (text/Markdown); Pro → CSV/PDF.

---

## 11) Algorithms (pseudo)

**Plan seed (per day/meal)**  
```
for meal_slot in day:
  candidate_pool = recipes.filter(mode + diet flags + time cap)
  pick = argmin over candidates: cost_per_serv (budget mode) OR time_mins (no-budget)
  add pick
```

**Local search**
```
for iter in 1..N:
  slot = random_meal()
  alternatives = top_k_by_delta_score(slot, k=5)
  if best_alt improves S: apply
  else continue
stop if no improvement
```

**Shopping list**
```
need = sum(plan.items) by ingredient
need -= pantry
purchase = ceil_to_pack(need)
cost = sum(purchase.qty * price)
```

---

## 12) Test Plan

**Unit tests**
- Macro math: per-100 g to per-serving; rounding.  
- Budget math: totals after swaps & price edits.  
- Pack rounding & leftovers.  
- Pantry deduction.  
- Mode objective weights.

**Integration tests**
- Generate → Swap → List flow with sample personas (Student, Cutter, Bulker).  
- Offline cold start with cached data.

**E2E (golden tests)**
- Screens render with dynamic type; voiceover labels present.

**Performance**
- Seed → generate (<2 s) on Pixel 5 & iPhone 11.  
- Swap latency (<300 ms).

---

## 13) Analytics (privacy-respecting)
- **Opt-in** toggle during onboarding.  
- Minimal, aggregated events: plan_generated, swap_applied, list_exported, paywall_viewed, upgrade_clicked.  
- No user content or PII in telemetry.

---

## 14) Monetization & Gating

| Feature | Free | Pro |
|---|---|---|
| Active plans | 1 | Unlimited |
| Recipe library | Starter (~20) | Full (~100+) |
| Pantry-first | — | ✓ |
| Swap history | — | ✓ |
| Export CSV/PDF | — | ✓ |
| Presets | 1 | Multiple |
| Future packs & widgets | — | Included |

Pricing: **$3.99/mo or $24/yr**, 7-day trial, annual pre-selected. No ads.

---

## 15) Compliance, Legal, Privacy
- **Disclaimer:** Not a medical device; for general planning only.  
- **IP:** Seed recipes authored in-house; no scraping.  
- **Privacy:** Local-first; optional crash logs/analytics with explicit consent; data export available.

---

## 16) Release Plan

**v1.0 (Android-only, Google Play — 3–4 weeks)**
- Platform: **Android** (Flutter). Target latest SDK; min SDK to cover ≥95% of devices.
- Billing: **Google Play Billing** (subscriptions/one-time per PRD).
- Privacy: no ads/trackers; local-first.
- Permissions: camera (if needed for features), storage access as needed, notifications (if/when used).
- Deliverables: Onboarding, planner, swaps, shopping list, seed data, Free vs Pro gating, Play Store assets.

**v1.1 (Post-PMF — iOS App Store)**
- Platform: **iOS** (Flutter runner).
- Billing: **StoreKit 2** equivalents for paid features.
- Compliance: ATT prompt if any tracking added; Sign in with Apple if 3P login added.
- Deliverables: iOS-specific icons/screenshots, privacy nutrition labels, parity with Android v1.0.

**v1.2**
- Meal-prep mode; dining-out buffer; family scaling; widgets; CSV/PDF export; optional cloud sync.

---

## 17) Risks & Mitigations
- **Recipe/IP risk:** Own recipes; allow user input.  
- **Price accuracy:** Editable prices; show “estimate” badge.  
- **Complex UX creep:** One main flow; advanced settings tucked away.  
- **Performance on low-end devices:** cap candidate sets; lazy loading; caching.

---

## 18) Store Checklist
- App icons, screenshots (Plan → Swap → List), subtitle & descriptions.  
- Privacy Policy & Terms URLs.  
- Trial details; “Manage Subscription” link.  
- Review prompt after 3 successful plans (never block flow).

---

## 19) Glossary
- **Macro targets:** daily calories and grams of protein, carbs, fat.  
- **Pantry-first:** preferentially using ingredients already on hand.  
- **Pack rounding:** converting required grams/mL to store purchase sizes.  
- **$/1000 kcal:** cost efficiency metric, useful in bulking.

---

**End of PRD**
