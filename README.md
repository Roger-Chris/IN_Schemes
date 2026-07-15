# IN Schemes: AI-Powered Government Scheme Recommendation Platform

An intelligent, self-contained Flutter application designed to bridge the awareness gap and simplify the discovery, eligibility matching, and documentation requirements of Central and State Government schemes for Indian entrepreneurs, women, and students. Developed for launch on **National Entrepreneurs' Day**.

---

## 🚀 Key Features

- **Language Support:** English & Hindi localization.
- **Onboarding:** Quick login via mobile number + OTP verification or guest entry.
- **Collapsible Profile Setup:** Collateral fields (Personal, Location, Community, Education, Income) to build a robust eligibility profile.
- **Bottom Navigation Hub:** Seamless routing across 5 persistent tabs (Home, Categories, Search, Find Schemes, Profile).
- **Horizontal Wide Categories Layout:** 22 customized focus area cards (MSME, Startup, Finance, Agriculture, Education, and more).
- **Smart Filtering & Search:** Real-time text search, popular query tags, voice-command simulation, and detailed multi-criteria filter sheet.
- **Guided Eligibility Matcher (Find My Schemes):** An interactive 3-step wizard that reviews and commits user answers to recalculate matches.
- **Ranked Match Engine:** Visual circular percentage badges (e.g. NEEDS 96%) showing compatibility.
- **Explainability Feed:** Clear, natural language bullet points detailing *why* the applicant is qualified for each scheme.
- **Required Documents Checklist:** Visual check/warning marks mapping scheme prerequisites (e.g. Aadhaar, Nativity) against user inputs.
- **Missing Document Assistant:** Directional buttons (e.g., "Get Document") that open deep links directly to official government portals (e.g., NSDL, UIDAI, e-Sevai).

---

## 🛠️ File Structure

The project code is fully localized within the `frontend/` directory:

```
frontend/
├── assets/
│   └── images/
│       └── splash_screen.png           # Visual brand logo
├── lib/
│   ├── main.dart                       # Entry point, theme definitions, and tabs shell
│   ├── models/
│   │   ├── scheme_model.dart            # Scheme data structures and Phase 1 seed data
│   │   └── user_profile.dart            # User profile answers and age computation logic
│   ├── engine/
│   │   └── recommendation_engine.dart   # Rules-based eligibility scoring and matching engine
│   ├── providers/
│   │   └── app_state_provider.dart      # SharedPreferences persistence and state manager
│   ├── widgets/                         # Reusable UI components
│   │   ├── custom_button.dart           # Loading and gradient-supported action buttons
│   │   ├── category_card.dart           # Wide category cards with emoji icons
│   │   ├── scheme_card.dart             # Match score gauges and explainability previews
│   │   ├── filter_panel.dart            # Multi-parameter bottom search sheet
│   │   └── gradient_scaffold.dart       # Thematic indigo-gradient background layout
│   └── screens/                         # The 17 core pages of the application
│       ├── splash_screen.dart           # Brand intro and launch animations
│       ├── language_selection_screen.dart # English/Hindi locale selector
│       ├── login_screen.dart            # Phone authentication and guest entry
│       ├── profile_setup_screen.dart    # Collapsible profile creator
│       ├── home_screen.dart             # Greeting dashboard, banner, announcements
│       ├── categories_screen.dart       # List of 22 horizontal category cards
│       ├── search_screen.dart           # Bar with mic, history, and suggestions
│       ├── search_results_screen.dart   # List view sorted by score or name
│       ├── find_my_schemes_screen.dart  # Multi-step guided wizard
│       ├── eligibility_results_screen.dart # Match results success page
│       ├── scheme_details_screen.dart   # Tabbed view: overview, checklist, FAQ
│       ├── saved_schemes_screen.dart    # Bookmarked and recently viewed tabs
│       ├── notifications_screen.dart    # Deadline and alert cards
│       ├── profile_screen.dart          # Edit profile, saved schemes, settings navigation
│       ├── settings_screen.dart         # Preferences toggles, delete account
│       └── help_support_screen.dart     # General FAQs and ticket feedback submission
```

---

## 🏛️ Sponsoring Schemes Seeded (Phase 1)

1. **NEEDS (New Entrepreneur cum Enterprise Development Scheme - TN):** Supports first-generation graduates starting manufacturing/service projects in Tamil Nadu with up to ₹75 Lakhs (25%) subsidy and 3% interest subvention.
2. **PMEGP (Prime Minister's Employment Generation Programme - Central):** Micro-enterprise credit-linked subsidies (15-35%) for new units costing up to ₹50 Lakhs.
3. **Stand-Up India (Central):** Collateral-free greenfield loans between ₹10 Lakhs and ₹1 Crore for women and SC/ST entrepreneurs.
4. **Mudra Yojana (Central):** Collateral-free micro loans up to ₹10 Lakhs categorized under Shishu, Kishor, and Tarun.
5. **WEP (Women Entrepreneurship Platform - NITI Aayog):** Aggregator services for mentoring, funding, and incubation networks.
6. **TREAD (Trade Related Entrepreneurship Assistance - Central):** 30% Government grants routed through NGOs to assist women self-employment.
7. **Kalaignar Kaivinai Thittam (Tamil Nadu):** Free modern toolkits, training, and welfare benefits for local artisans.
8. **StartupTN (TANSIM - Tamil Nadu):** TANSEED grants (equity-free, up to ₹15 Lakhs) for innovative, DPIIT-registered startups.

---

## 🧮 Recommendation Engine Scoring Rules

The matching score (0-100%) in `recommendation_engine.dart` is computed on-the-fly:
- **Residency checks:** A score of 0% is assigned to NEEDS, StartupTN, and Kalaignar Kaivinai Thittam if the user's state is not "Tamil Nadu".
- **Category restrictions:** A score of 0% is assigned to Stand-Up India and TREAD if the user gender is male and community is not SC/ST.
- **Education thresholds:** A penalty is applied to NEEDS if the user does not hold a college degree/diploma.
- **Age compliance:** Rules check boundary boxes (e.g. 21-35 for General and 21-45 for Special category in NEEDS).
- **First-Gen Graduate bonus:** Adds a priority matching increment to the score.
- **Documentation index:** The matching score is adjusted by the ratio of available documents to required documents to reward users with complete profiles.

---

## 💻 How to Compile and Run

### Prerequisites
- Flutter SDK (stable channel) installed on your machine.
- Google Chrome browser (for Web target) or Windows Desktop compilation tools.

### Setup and Launch Commands
Open your terminal in the `frontend/` directory and execute:

1. **Install and verify dependencies:**
   ```bash
   flutter pub get
   ```

2. **Verify available target devices:**
   ```bash
   flutter devices
   ```

3. **Run the application on Web (Google Chrome):**
   ```bash
   flutter run -d chrome
   ```

4. **Build a production web bundle (optional):**
   ```bash
   flutter build web --release
   ```
