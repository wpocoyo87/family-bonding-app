# ERAT: A Gamified Mobile Application for Family Bonding and Habit Formation

[![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?logo=flutter&logoColor=white)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.x-0175C2?logo=dart&logoColor=white)](https://dart.dev)
[![State Management](https://img.shields.io/badge/Riverpod-2.6.1-3B82F6)](https://riverpod.dev)
[![Backend](https://img.shields.io/badge/Firebase-Firestore%20%7C%20Auth-FFCA28?logo=firebase&logoColor=black)](https://firebase.google.com)
[![License](https://img.shields.io/badge/License-Academic%20%2F%20MIT-brightgreen.svg)](LICENSE)
[![SUS Score](https://img.shields.io/badge/SUS%20Score-84.5%20(Grade%20A%2B)-success)](#evaluation--usability)

> **Academic Final Year Project (FYP)**  
> **Degree Program:** Bachelor of Science in Information Technology  
> **Student Name:** Khadijah Binti Kasiran (`B24070074`)  
> **Supervisor:** Ms Nurulaini  
> **Coordinator / Dean:** Ms Sarmila Devi  
> **Submission Date:** 21 November 2026  

---

## 📖 Table of Contents
1. [Project Overview](#-project-overview)
2. [Problem Statement & Core Philosophy](#-problem-statement--core-philosophy)
3. [Key Architectural Highlights](#-key-architectural-highlights)
4. [The 5 Developmental Age Bands](#-the-5-developmental-age-bands)
5. [Core Feature Modules](#-core-feature-modules)
6. [Technology Stack](#-technology-stack)
7. [System Architecture & Folder Structure](#-system-architecture--folder-structure)
8. [Getting Started & Installation](#-getting-started--installation)
9. [Running in Offline Demo Sandbox Mode](#-running-in-offline-demo-sandbox-mode)
10. [Security, Privacy & Firestore Rules](#-security-privacy--firestore-rules)
11. [Evaluation & Usability Results](#-evaluation--usability-results)
12. [Full FYP Academic Documentation](#-full-fyp-academic-documentation)

---

## 🌟 Project Overview

**ERAT** is an age-adaptive, privacy-respecting cross-platform mobile ecosystem developed with **Flutter** and **Google Firebase**. Designed specifically for modern multi-child households, ERAT bridges the generational divide by transforming daily responsibilities, emotional reflections, and shared routines into meaningful opportunities for connection rather than punitive oversight.

Unlike commercial parental-control software that relies on intrusive screen surveillance and unilateral coercion, ERAT implements **self-determination theory (SDT)** and **gamified positive reinforcement**. It adapts dynamically across five distinct developmental stages—from toddlers learning foundational hygiene to adolescents seeking emotional autonomy.

---

## 💡 Problem Statement & Core Philosophy

### The Dilemma
Modern parenting apps are predominantly split into two polarized categories:
1. **Intrusive Spyware / Surveillance:** Geofencing, screen capture, and keylogging that erode filial trust and trigger adversarial teen workarounds.
2. **Transactional Chore Checklists:** Monotonous tick-boxes with no emotional resonance, quickly abandoned once extrinsic rewards fade.

### The ERAT Approach
- **Empowerment over Surveillance:** Children actively log routines, document self-paced achievements with photo/voice proofs, and curate personal milestones.
- **Zero-Upward-Leak Confidentiality:** A cryptographic and rule-enforced privacy boundary where children's introspective journals remain strictly private unless explicitly shared by the child.
- **Family-Centric Economy:** Star points are accumulated individually and contributed toward collective **Family Star Goals** (e.g., family trips, shared outings).
- **Developmental Plasticity:** The UI and interaction paradigms adjust automatically according to each family member's computed developmental stage.

---

## 🎯 Key Architectural Highlights

| Pillar | Implementation | Technical Advantage |
|---|---|---|
| **Dynamic Age-Adaptive UI** | Runtime chronological derivation from `birthMonth` & `birthYear` | Zero metadata drift; UI density and typography morph seamlessly between ages 3 and 18+. |
| **Zero-Upward-Leak Privacy** | Cloud Firestore declarative rules on `isSharedWithParents` | Parent reads on private journals return permission denied at the database kernel level unless explicitly permitted. |
| **Reactive Unidirectional State** | Riverpod `StateNotifier` (`EratController` + `EratAppState`) | Predictable mutations, zero state duplication, reactive real-time UI synchronisation. |
| **Dual-Mode Sandbox & Live Engine** | In-memory seeded demo state with offline fallback | Evaluators and examiners can fully test every feature instantly without configuring Firebase keys. |

---

## 👶 The 5 Developmental Age Bands

ERAT categorizes child profiles into five developmentally grounded bands:

```
[Age 3–5]  Little Explorer     ➔ Sensory cues, massive touch targets, audio prompts, minimal text
[Age 6–9]  Junior Adventurer   ➔ Vivid gamification, milestone maps, badge collections, audio feedback
[Age 10–12] Young Cadet         ➔ Structured checklists, streak trackers, collaborative family projects
[Age 13–15] Senior Pathfinder   ➔ Analytical dashboards, private reflective journals, peer accountability
[Age 16+]  Lifelong Family Bond➔ Minimalist productivity, family calendar, mutual schedule coordination
```

---

## 🚀 Core Feature Modules

### 1. 📅 Daily Quests & Routine Verification
- Morning, afternoon, and evening routine cadences tailored to child age groups.
- Children complete routines and submit **photo proof** or **voice notes**.
- Parents review submissions in the **Parent Command Center** before awarding Star Points.

### 2. 🗺️ Gamified Milestone Map & Wish Goals
- Visual interactive journey map with milestone checkpoints.
- Children allocate hard-earned stars toward personal **Wish Goals** (e.g., bicycle, books, art supplies).
- Real-time progress bars provide immediate visual feedback.

### 3. 🔒 Cozy Personal Journal (Zero-Upward-Leak Privacy)
- Reflective journaling interface supporting emotional mood check-ins, text, audio recordings, and photo attachments.
- By default, entries are marked `isSharedWithParents: false` and are cryptographically inaccessible to parents.
- Children can voluntarily toggle sharing when they feel ready to discuss their thoughts with parents.

### 4. 📆 Shared Family Calendar & Events
- Centralized scheduling for school holidays, medical checkups, exams, and family outings.
- Color-coded member tags and conflict detection.

### 5. 💬 Safe Family Chat & Cozy Voice Notes
- Whitelisted, closed-loop intra-family messaging.
- Integrated voice recording and playback with AAC (Augmentative and Alternative Communication) support for non-verbal or early-stage children.

### 6. 🤝 Parent Community Hub & Wisdom Exchange
- Moderated forum for parents to discuss parenting strategies, share routine templates, and exchange advice.
- Complete with category tags, engagement counters, and inspirational community stories.

### 7. ⭐ Family Star Goal Hub
- Collective family milestones where parents and children pool star points toward mutual rewards (e.g., weekend picnic, theme park outing).

---

## 🛠️ Technology Stack

- **Frontend Framework:** Flutter 3.x (Dart 3)
- **Design System:** Material 3 with custom warm/cozy palette (`CozyTheme`)
- **State Management:** Riverpod 2.x (`StateNotifierProvider`, unidirectional reactive flow)
- **Backend Infrastructure:** Google Firebase
  - **Firebase Authentication:** Anonymous auth, email/password, and role-based family invite codes.
  - **Cloud Firestore:** Real-time multi-tenant NoSQL database with declarative security rules.
  - **Firebase Storage:** Cloud media storage for routine proofs, journal attachments, and avatars.
- **Audio & Media:** `record` & `audioplayers` for voice notes and AAC features.
- **Localization:** Bilingual support (English & Bahasa Melayu).

---

## 📂 System Architecture & Folder Structure

ERAT follows a scalable Feature-Driven Clean Architecture:

```
lib/
├── core/
│   ├── config/             # Theme tokens, palette constants, asset bindings
│   ├── models/             # Domain entities (FamilyMember, Quest, Journal, WishGoal)
│   ├── providers/          # Riverpod state notifiers, EratController, app state
│   ├── services/           # Firestore service, Voice/Audio service, Local cache
│   └── utils/              # AgeBand extensions, formatters, validation
├── features/
│   ├── auth/               # Family setup, onboarding, invite codes, PIN entry
│   ├── calendar/           # Shared family calendar & event agenda cards
│   ├── community/          # Parent community hub, wisdom feeds, tips
│   ├── gamification/       # Milestone map, star ledger, wish goal dialogs
│   ├── journal/            # Private journal tab, mood selector, voice recorder
│   ├── navigation/         # Adaptive bottom navigation & shell scaffolds
│   ├── parent/             # Parent Command Center, approval queue, star adjustments
│   ├── personal/           # Child adaptive home view, routine check-ins, quests
│   └── shared/             # Safe family chat, voice notes, media viewers
├── main.dart               # App entry point, Firebase init & Riverpod ProviderScope
└── firebase_options.dart   # Auto-generated Firebase configurations
```

---

## 💻 Getting Started & Installation

### Prerequisites
- **Flutter SDK:** Version `3.19.0` or higher ([Install Flutter](https://docs.flutter.dev/get-started/install))
- **Dart SDK:** Version `3.3.0` or higher
- **Android Studio / Xcode:** For mobile simulation or physical device USB debugging.
- **Git**

### Installation Steps

1. **Clone the repository:**
   ```bash
   git clone https://github.com/wpocoyo87/family-bonding-app.git
   cd family-bonding-app
   ```

2. **Install dependencies:**
   ```bash
   flutter pub get
   ```

3. **Verify Flutter environment:**
   ```bash
   flutter doctor
   ```

4. **Run the application:**
   ```bash
   flutter run
   ```

---

## 🧪 Running in Offline Demo Sandbox Mode

ERAT includes a built-in **Zero-Config Sandbox Mode** specifically designed for FYP evaluators, examiners, and offline demonstrations:

1. Launch the app on your emulator or physical Android/iOS device.
2. On the welcome screen, select **"Try Demo Mode"** or toggle the offline sandbox.
3. The app loads an isolated in-memory family workspace with pre-configured personas across different age bands:
   - **Parent Profile:** Command Center, quest approval queue, star adjustments.
   - **Child Profile (Adolescent):** Private reflective journal, custom wish goals.
   - **Child Profile (Junior):** Interactive milestone map, daily routine checklists.
4. **No Firebase configuration or active internet connection is required** to test core interactions, state switches, or PIN validations.

---

## 🛡️ Security, Privacy & Firestore Rules

ERAT enforces security directly at the database tier using Cloud Firestore Security Rules:
- **Tenant Isolation:** Users can only query data matching their verified `familyId`.
- **Parent PIN Gate:** Sensitive administrative actions (approving stars, adjusting goals, community posting) require PIN validation (`member_pin_login_screen.dart`).
- **Zero-Upward-Leak Journal Confidentiality:** Child journal entries cannot be read by parents unless `isSharedWithParents == true`.

Excerpt from `firestore.rules`:
```javascript
match /families/{familyId}/journals/{journalId} {
  allow read: if isFamilyMember(familyId) && (
    resource.data.authorId == request.auth.uid ||
    (isParent(familyId) && resource.data.isSharedWithParents == true)
  );
  allow write: if isFamilyMember(familyId) && request.auth.uid == resource.data.authorId;
}
```

---

## 📊 Evaluation & Usability Results

ERAT underwent rigorous empirical usability testing across five multi-child households in the Klang Valley (Selangor) utilizing the standardized **System Usability Scale (SUS)**:

| Participant ID | Role | Household Profile | SUS Score | Grade |
|---|---|---|:---:|:---:|
| **H01-P / H01-C** | Parent & Child (10) | 2 Parents, 2 Children (Ages 7, 10) | **82.5** | A (Excellent) |
| **H02-P / H02-C** | Parent & Teen (14) | 2 Parents, 3 Children (Ages 4, 8, 14) | **87.5** | A+ (Superior) |
| **H03-P / H03-C** | Parent & Child (12) | 2 Parents, 2 Children (Ages 9, 12) | **80.0** | A- / B+ (Good) |
| **H04-P / H04-C** | Parent & Teen (16) | 2 Parents, 4 Children (Ages 5, 8, 11, 16) | **90.0** | A+ (Best Imaginable) |
| **H05-P / H05-C** | Parent & Teen (13) | 2 Parents, 3 Children (Ages 6, 13, 17) | **82.5** | A (Excellent) |
| **Overall Mean** | — | **5 Multi-Child Households (24 Users)** | **84.5 / 100** | **Grade A+ (Superior Usability)** |

---

## 📚 Full FYP Academic Documentation

The complete 5-chapter academic dissertation documentation, complete with system design models, requirement matrices, test logs, and appendices, is available in the repository root:
📄 **[`ERAT_FYP_Full_Documentation.md`](./ERAT_FYP_Full_Documentation.md)**

### Contents of Documentation:
- **Chapter 1: Introduction** — Project background, problem statement, research questions, objectives, and scope.
- **Chapter 2: Literature Review** — Comparative analysis of parental control vs. positive habit gamification apps, Self-Determination Theory (SDT), and technology stack justification.
- **Chapter 3: Methodology & Analysis** — Agile Scrum framework, 5-household stakeholder elicitation (Klang Valley), functional (FR-01 to FR-12) and non-functional requirements.
- **Chapter 4: System Design & Implementation** — Class diagrams, sequence diagrams, Use Case diagrams, runtime AgeBand derivation, zero-upward-leak security model, and Riverpod controller pattern.
- **Chapter 5: Testing, Results & Evaluation** — Unit, widget, and integration test cases (TC-01 through TC-08 with Pass logs), SUS evaluation analysis, and future enhancement roadmap.
- **Appendix A:** Standard 10-Item SUS Questionnaire & Individual Participant Responses.
- **Appendix B:** Complete Declarative Cloud Firestore Security Rules.

---

## 👩‍💻 Author & Academic Attribution

- **Candidate:** Khadijah Binti Kasiran
- **Student ID:** `B24070074`
- **Degree:** Bachelor of Information Technology (Hons)
- **Supervisor:** Ms Nurulaini
- **Program Coordinator:** Ms Sarmila Devi
- **Institution:** Faculty of Information Technology

*Developed with ❤️ as an academic contribution toward healthier family dynamics in the digital era.*
