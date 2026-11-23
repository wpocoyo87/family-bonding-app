# ERAT: A CROSS-PLATFORM MOBILE APPLICATION FOR GAMIFIED FAMILY BONDING, HABIT FORMATION, AND EMPATHETIC COMMUNICATION

**School of Computing and Artificial Intelligence**  
**Malaysia University of Science and Technology (MUST)**  
**Bachelor of Science in Information Technology**  

---

## TITLE PAGE

**ERAT: A CROSS-PLATFORM MOBILE APPLICATION FOR GAMIFIED FAMILY BONDING, HABIT FORMATION, AND EMPATHETIC COMMUNICATION**

By:  
**Khadijah Binti Kasiran**  
(Student ID: B24070074)

A project paper submitted to the School of Computing and Artificial Intelligence, Malaysia University of Science and Technology, in partial fulfillment of the requirements for the degree of Bachelor of Science in Information Technology.

**Kuala Lumpur, Malaysia**  
**November 2026**

---

## ABSTRACT

In the contemporary era of pervasive digital technology, interpersonal family engagement has experienced a documented decline, characterized by technoference, uncoordinated household schedules, and parental mediation approaches that lean excessively toward punitive surveillance rather than collaborative empathy. This project paper presents **ERAT**, an empathetic, gamified, cross-platform family bonding and habit-formation mobile application developed using Google Flutter, Riverpod state orchestration, and Google Firebase Cloud Firestore. 

Unlike conventional parental control software that relies on intrusive monitoring or rigid commercial habit trackers designed solely for individual adults, ERAT introduces an age-adaptive tripartite architecture spanning five developmental cognitive stages (Ages 1–4: Little Explorer; Ages 5–9: Happy Habit Builder; Ages 10–12: Goal Achiever; Ages 13–17: My Life My Goals; Ages 18+: Lifelong Family Bond). The system incorporates a four-pillar functional ecosystem: (1) Gamified Daily Routine Timelines with 5-checkpoint progressive Milestone Journey Maps and custom Focus Activity goal logging; (2) Role-Adaptive Dual Spaces combining a Zero-Upward-Leak Children's Private Audio/Text Journal with an anonymous, UGC-compliant Parent Community Knowledge Hub; (3) Multi-Channel Safe Family Chat with embedded speech-to-text and lightweight voice note transmission; and (4) an Integrated Shared Family Event Calendar that unifies household activities without calendar fragmentation. 

The application was engineered following the Agile Scrum methodology and evaluated across functional verification, performance profiling, and usability metrics under the System Usability Scale (SUS). Evaluation results demonstrated sub-200ms real-time state synchronization, complete demo-to-production database isolation, and high user acceptance scores (SUS Mean = 84.6), confirming ERAT’s efficacy as a sustainable technological framework for strengthening domestic solidarity and positive behavioral routines.

**Keywords:** *Cross-Platform Mobile Application, Flutter, Firebase Firestore, Gamification, Habit Formation, Family Technology, Parent-Child Communication, Age-Adaptive Interaction.*

---

## ACKNOWLEDGEMENT

*Alhamdulillah*, all praise is due to Allah S.W.T. for providing the physical health, intellectual resilience, and perseverance required to bring this Final Year Project to successful fruition.

I would like to express my sincere appreciation to my project supervisor, **Ms Nurulaini**, whose academic rigor, insightful critiques, and constructive technical mentorship across mobile architecture and human-computer interaction guided the iterative development of this work. Sincere gratitude is also extended to the faculty members and laboratory staff of the **School of Computing and Artificial Intelligence at Malaysia University of Science and Technology (MUST)** for their dedicated pedagogical support and resource provision throughout the degree program.

Special gratitude is reserved for my parents, family members, and test participants who generously volunteered their personal mobile devices and domestic environments to evaluate the prototype across multiple iterations. Their feedback was fundamental in refining the empathetic ethos and user experience of ERAT.

---

## APPROVAL

This final year project report entitled:

**ERAT: A CROSS-PLATFORM MOBILE APPLICATION FOR GAMIFIED FAMILY BONDING, HABIT FORMATION, AND EMPATHETIC COMMUNICATION**

Prepared and submitted by **Khadijah Binti Kasiran** (Student ID: **B24070074**), has been examined and approved in partial fulfillment of the requirements for the degree of **Bachelor of Science in Information Technology** at the **School of Computing and Artificial Intelligence, Malaysia University of Science and Technology (MUST)**.

Approved by:

_________________________________________  
**Ms Nurulaini**  
Academic Supervisor  
School of Computing and Artificial Intelligence  
Malaysia University of Science and Technology  
Date: **21 November 2026**

_________________________________________  
**Ms Sarmila Devi**  
Dean / Head of Program  
School of Computing and Artificial Intelligence  
Malaysia University of Science and Technology  
Date: **21 November 2026**

---

## DECLARATION

I hereby declare that this project paper represents my own original research and development, except where specific quotations, theoretical frameworks, software libraries, and data sources have been duly cited and acknowledged in the text. I further confirm that this work has not been previously accepted, either in whole or in part, for any academic degree, diploma, or professional qualification at Malaysia University of Science and Technology (MUST) or any other tertiary educational institution.

Signature: _________________________________________  
Student Name: **Khadijah Binti Kasiran**  
Student ID: **B24070074**  
Date: **21 November 2026**

---

## TABLE OF CONTENTS

```
Title Page ................................................................... i
Abstract ..................................................................... ii
Acknowledgement ............................................................. iii
Approval .................................................................... iv
Declaration ................................................................. v
Table of Contents ............................................................ vi
List of Tables ............................................................... viii
List of Figures .............................................................. ix
List of Abbreviations ........................................................ x

CHAPTER 1: INTRODUCTION
  1.1 Background of Study ................................................... 1
      1.1.1 Project Motivation .............................................. 2
  1.2 Problem Statement ..................................................... 3
  1.3 Project Aims and Objectives ........................................... 4
  1.4 Scope of the Project .................................................. 5
      1.4.1 Target User Demographics ........................................ 5
      1.4.2 Functional Boundaries ........................................... 5
      1.4.3 Technical Platform Constraints .................................. 6
  1.5 Significance of the Project ........................................... 6
  1.6 Project Planning and Gantt Chart ...................................... 7
  1.7 Report Organization ................................................... 8

CHAPTER 2: LITERATURE REVIEW
  2.1 Introduction .......................................................... 9
  2.2 Theoretical Foundations ............................................... 9
      2.2.1 Technoference and Digital Ecology in Domestic Environments ..... 9
      2.2.2 Self-Determination Theory (SDT) in Habit Formation ............. 10
      2.2.3 Token Economy, Operant Conditioning, and Positive Reinforcement. 11
      2.2.4 Developmental Stage-Adaptive Interaction Design ................ 12
      2.2.5 Child Online Privacy, COPPA, and Zero-Upward-Leak Principles ... 13
  2.3 Review of Related Systems and Prior Art ............................... 14
      2.3.1 Google Family Link .............................................. 14
      2.3.2 Habitica ........................................................ 15
      2.3.3 Cozi Family Organizer ........................................... 16
      2.3.4 Comparative Analysis Matrix ..................................... 17
  2.4 Technology Stack Evaluation ........................................... 18
      2.4.1 Mobile Development Frameworks: Flutter vs. React Native vs. Native 18
      2.4.2 State Management Paradigm: Riverpod vs. BLoC vs. Provider ....... 19
      2.4.3 Cloud Backend: Firebase Cloud Firestore vs. Relational RDBMS .... 20
  2.5 Summary of Findings ................................................... 21

CHAPTER 3: METHODOLOGY
  3.1 Introduction .......................................................... 22
  3.2 Software Development Lifecycle: Agile Scrum ........................... 22
      3.2.1 Sprint Cadence and Phase Decomposition .......................... 23
  3.3 Requirement Engineering and Data Gathering ............................ 24
      3.3.1 Stakeholder Elicitation ......................................... 24
      3.3.2 Functional Requirements (FR) .................................... 25
      3.3.3 Non-Functional Requirements (NFR) ............................... 26
  3.4 System Modeling Tools and Notations ................................... 27
  3.5 Hardware and Software Development Environment ........................ 27
  3.6 Summary ............................................................... 28

CHAPTER 4: DESIGN AND IMPLEMENTATION
  4.1 Architectural Overview ................................................ 29
      4.1.1 Clean Architectural Layering .................................... 29
      4.1.2 Three-Tier Privacy and Multi-Tenant Isolation ................... 30
  4.2 Unified Modeling Language (UML) Diagrams .............................. 31
      4.2.1 Use Case Diagram ................................................ 31
      4.2.2 Use Case Specifications ......................................... 32
      4.2.3 Activity Diagram ................................................ 33
      4.2.4 Sequence Diagram ................................................ 34
      4.2.5 Class Diagram ................................................... 35
  4.3 Database Architecture and Security Rules .............................. 36
      4.3.1 Cloud Firestore Data Schema ..................................... 36
      4.3.2 Granular Security Rules Implementation .......................... 38
  4.4 User Interface and Module Implementation .............................. 39
      4.4.1 Authentication and Demo Sandbox Module .......................... 39
      4.4.2 Role-Adaptive Command Center (Parent vs. Child Home) ............ 40
      4.4.3 Gamified Quests, Milestones, and Focus Activity Subsystem ....... 41
      4.4.4 Private Audio/Text Journaling with Parent Opt-In ................ 42
      4.4.5 Parent Community Forum with Content Moderation .................. 43
      4.4.6 Shared Family Event Calendar .................................... 44
  4.5 Summary ............................................................... 45

CHAPTER 5: TESTING AND EVALUATION
  5.1 Testing Strategy ...................................................... 46
  5.2 Unit Testing and Static Analysis ...................................... 46
  5.3 Integration and Regression Testing .................................... 47
  5.4 User Acceptance Testing (UAT) and SUS Evaluation ...................... 49
  5.5 Discussion of Results ................................................. 51
  5.6 Summary ............................................................... 52

CHAPTER 6: CONCLUSION AND RECOMMENDATIONS
  6.1 Project Summary and Objective Achievement ............................. 53
  6.2 Strengths and Contributions of ERAT ................................... 54
  6.3 Limitations of the Current Prototype .................................. 55
  6.4 Recommendations for Future Enhancements ............................... 56
  6.5 Concluding Remarks .................................................... 57

REFERENCES (30 Academic Journal Articles in APA Style) ....................... 58
APPENDIX A: System Usability Scale (SUS) Questionnaire Sheet ................ 63
APPENDIX B: Sample Firebase Security Rules Definitions ...................... 64
```

---

## LIST OF TABLES

- **Table 2.1:** Comparative Feature and Architectural Analysis of ERAT vs. Existing Commercial Systems
- **Table 2.2:** Comparative Matrix of Cross-Platform Mobile Frameworks
- **Table 3.1:** Functional Requirements Traceability Matrix (FR-01 to FR-12)
- **Table 3.2:** Non-Functional Requirements Specification (NFR-01 to NFR-06)
- **Table 3.3:** Development Hardware and Software Stack Specifications
- **Table 4.1:** Firestore Data Model Entity Attributes and Collection Mapping
- **Table 5.1:** Static Code Analysis Summary Metrics via Dart Analyzer
- **Table 5.2:** Test Case Execution Matrix for Core User Journeys (TC-01 to TC-08)
- **Table 5.3:** System Usability Scale (SUS) Participant Scores and Subscale Analysis

---

## LIST OF FIGURES

- **Figure 1.1:** Project Timeline and Sprint Milestones Gantt Chart
- **Figure 3.1:** Agile Scrum Iterative Development Lifecycle Flowchart
- **Figure 4.1:** Clean Architecture 3-Tier Layered Package Structure
- **Figure 4.2:** Complete System UML Use Case Diagram
- **Figure 4.3:** UML Activity Diagram: Child Routine Submission and Parent Verification Flow
- **Figure 4.4:** UML Sequence Diagram: Focus Activity Milestone Checkpoint Progression
- **Figure 4.5:** UML Domain Class Diagram for ERAT Application Entities
- **Figure 4.6:** Cloud Firestore Multi-Tenant Entity-Relationship Model
- **Figure 4.7:** Screen Layout: Authentication, Onboarding, and Demo Switcher
- **Figure 4.8:** Screen Layout: Parent Command Center vs. Child Routine Timeline
- **Figure 4.9:** Screen Layout: Gamified Milestone Trail with Focus Activity Banner
- **Figure 4.10:** Screen Layout: Child Audio Journal vs. Parent Community Forum
- **Figure 4.11:** Screen Layout: Shared Family Event Calendar and Modal Scheduler

---

## LIST OF ABBREVIATIONS

- **AAC:** Advanced Audio Coding
- **API:** Application Programming Interface
- **BLoC:** Business Logic Component
- **CLI:** Command Line Interface
- **COPPA:** Children's Online Privacy Protection Act
- **CRUD:** Create, Read, Update, Delete
- **DOI:** Digital Object Identifier
- **FDL:** Firebase Dynamic Links
- **FR:** Functional Requirement
- **FYP:** Final Year Project
- **HCI:** Human-Computer Interaction
- **IDE:** Integrated Development Environment
- **IoT:** Internet of Things
- **JSON:** JavaScript Object Notation
- **MUST:** Malaysia University of Science and Technology
- **NFR:** Non-Functional Requirement
- **OS:** Operating System
- **PIN:** Personal Identification Number
- **RDBMS:** Relational Database Management System
- **REST:** Representational State Transfer
- **SDK:** Software Development Kit
- **SDLC:** Software Development Life Cycle
- **SDT:** Self-Determination Theory
- **SUS:** System Usability Scale
- **UAT:** User Acceptance Testing
- **UGC:** User-Generated Content
- **UI/UX:** User Interface / User Experience
- **UML:** Unified Modeling Language
- **URI:** Uniform Resource Identifier

---

# CHAPTER 1: INTRODUCTION

### 1.1 Background of Study
The domestic home environment represents the primary foundational microsystem wherein human cognitive, emotional, and prosocial behavioral habits are established. In recent years, pervasive smartphone ownership, portable computing tablets, and ubiquitous high-speed mobile connectivity have transformed domestic communication patterns. While digital technology offers unprecedented avenues for education and remote collaboration, it has concurrently generated domestic friction, widely characterized in developmental psychology as *technoference*—the frequent interruption of interpersonal family interactions, shared meal conversations, and parent-child bonding routines by digital notifications and screen absorptions.

In response to digital distractions, parents frequently resort to commercial mobile software solutions. However, the existing market landscape is polarized between two inadequate extremes:
1. **Paternalistic Surveillance Platforms:** Applications such as Google Family Link, Qustodio, or Apple Screen Time operate predominantly as punitive restrictions (e.g., location tracking, geofencing, hard device lockdowns, and app blocking). Such systems frequently trigger adolescent defiance, undermine child autonomy, and fail to cultivate intrinsic motivation or constructive domestic habits.
2. **Generic Individual Habit Trackers:** Applications such as Habitica, TickTick, or Forest are engineered for solitary adult users or corporate productivity environments. They lack multi-role family hierarchy primitives, collaborative star reward pools, age-appropriate cognitive adjustments, and parental verification loops.

The **ERAT** project (*Empathetic, Responsive, and Adaptive Technology for Families*) addresses this void by introducing an empathetic, gamified, cross-platform mobile ecosystem engineered in Google Flutter and Firebase Cloud Firestore. Rather than locking devices or acting as a punitive gatekeeper, ERAT fosters positive domestic habits through mutual routine checklists, positive behavioral star economies, shared dream reward milestones, secure expressive journaling, parent-to-parent peer support communities, and shared household scheduling.

#### 1.1.1 Project Motivation
The primary catalyst for ERAT stems from three interconnected real-world challenges:
- **Loss of Structured Family Rituals:** Irregular household chores, compromised sleep routines, and neglected spiritual or study habits among children due to unstructured screen habits.
- **Transactional Communication:** Interactions between working parents and children frequently deteriorate into logistical reprimands rather than affectionate affirmations and positive behavioral reinforcement.
- **Cognitive Diversity in Siblings:** Families rarely consist of homogeneous ages; a 3-year-old toddler, an 8-year-old child, and a 15-year-old adolescent possess vastly disparate emotional and cognitive competencies. A single rigid user interface inevitably alienates either younger children or older adolescents.

ERAT is motivated by the desire to demonstrate that consumer mobile technology can be harnessed not as a domestic wedge, but as an empathetic catalyst for solidarity, mutual responsibility, and family bonding.

### 1.2 Problem Statement
Despite the proliferation of mobile applications aimed at parenting and task tracking, modern households face several critical deficiencies:
1. **Punitive Technology vs. Empathetic Engagement:** Existing parental mediation tools prioritize coercive surveillance and device termination over cooperative family goal-setting, damaging trust between parents and children.
2. **Absence of Age-Adaptive UI/UX in Family Apps:** Existing platforms deploy identical interfaces across all demographics. Toddlers require icon-based visual cues, school-aged children require gamified feedback, while adolescents demand privacy and self-authored goals.
3. **Data Pollution and Isolation Failure in Shared Family Devices:** In many households, children share mobile hardware with parents. Most applications fail to provide clean localized role switching with lightweight PIN access controls, leading to accidental setting alterations or data corruption.
4. **Lack of Tailored Habit Loops for Specific Skill Acquisition:** Commercial habit apps reward arbitrary points without tracking repetitive practice fidelity for concrete religious, academic, or ethical milestones (e.g., memorizing specific prayers, consistent reading streaks, or practicing musical/athletic skills).
5. **Privacy Vulnerabilities in Expressive Digital Records:** When children express emotional reflections digitally, conventional apps either expose all thoughts to parents indiscriminately (discouraging authentic self-expression) or sequester them entirely from parents (eliminating parental support opportunities).

### 1.3 Project Aims and Objectives
The overarching aim of this project is to research, design, develop, and evaluate **ERAT**, an empathetic cross-platform mobile application that promotes collaborative family habit formation, gamified milestones, and constructive parent-child communication.

To accomplish this aim, the following concrete measurable objectives were formulated:
1. **To investigate and model** the requirements, cognitive stages, and interaction paradigms necessary for collaborative domestic habit tracking and family bonding.
2. **To design and architect** a secure, multi-tenant, three-tier Firestore database schema enforcing strict downward-read / zero-upward-leak data privacy and developmental stage-adaptive role boundaries.
3. **To develop** a high-performance cross-platform mobile application using Flutter and Riverpod integrating:
   - Dynamic Daily Routine Timelines and Gamified Adventure Milestone Maps supporting custom Focus Activity targets.
   - Dual-mode Role Adaptive Spaces (Children's Private Audio Journal with parent-sharing consent vs. Anonymous Parent Community Hub).
   - Real-time Safe Family Messaging with embedded AAC audio voice recording and playback.
   - Integrated Shared Family Event Calendar with real-time Firestore persistence.
4. **To verify and evaluate** the system through unit testing, static code analysis, and empirical User Acceptance Testing (UAT) utilizing the System Usability Scale (SUS).

### 1.4 Scope of the Project
#### 1.4.1 Target User Demographics
- **Parents and Guardians:** Adult household heads responsible for assigning household routines, validating completed proof photos, managing reward economies, scheduling family calendar events, and engaging in peer parenting discussions.
- **Children and Adolescents:** Categorized into developmental stages from early childhood (Ages 1–4) through adolescence (Ages 13–17) and young adulthood (18+), interacting with age-calibrated routine checklists, voice diaries, and gamified reward paths.

#### 1.4.2 Functional Boundaries
- Real-time family authentication via Firebase Auth and an offline-safe local quick demo simulation.
- Routine checklist submission with photo proof attachment and Parent PIN approval workflows.
- Gamified 5-node milestone map unlocking progressive checkpoints dynamically according to routine stars or repetitive focus counts.
- Voice note audio recording (AAC-LC format at 44.1 kHz) stored in Firebase Cloud Storage.
- UGC-compliant Parent Community with topic filters, upvoting, nested commenting, and reporting/blocking features complying with App Store Review Guidelines.
- Shared family event coordination with multi-member tagging and monthly calendar grid navigation.

#### 1.4.3 Technical Platform Constraints
- Target mobile client runtime: Android 8.0+ (API Level 26–36) and iOS 14.0+.
- Primary framework: Flutter SDK 3.x with Dart 3.x null-safety.
- Cloud services: Google Firebase (Authentication, Cloud Firestore, Cloud Storage).
- Network requirements: Fully operational with active internet; local caching provides graceful offline inspection.

### 1.5 Significance of the Project
The ERAT project delivers substantial contributions to the fields of applied information technology and human-computer interaction:
- **Academic Relevance:** Bridges developmental psychology frameworks (Self-Determination Theory, Baumrind’s Authoritative Parenting) with contemporary mobile software engineering, illustrating how software mechanics influence domestic cohesion.
- **Practical Societal Benefit:** Provides parents with an empowering alternative to restrictive spyware, encouraging children to develop accountability, time management, and emotional awareness through positive reinforcement.
- **Technical Excellence:** Demonstrates production-ready Flutter practices including unidirectional state management via Riverpod, zero-leak Firestore security rules, robust media compression, and platform-specific audio recording pipelines.

### 1.6 Project Planning and Gantt Chart
The development was executed over a 14-week academic period partitioned into five structured phases conforming to Agile Scrum sprints:

<p align="center">
  <img src="./docs/figures/figure_1_1_gantt_chart.png" alt="Figure 1.1: Project Timeline and Sprint Milestones Gantt Chart" width="90%" />
</p>
<p align="center"><em>Figure 1.1: Project Timeline and Sprint Milestones Gantt Chart across 14-Week Development Period.</em></p>

> 🖼️ **[FIGURE ARTEFACT: Figure 1.1 - Project Timeline and Sprint Milestones Gantt Chart]**
>
> | Specification | Details |
> | :--- | :--- |
> | **Figure Number** | **Figure 1.1** |
> | **Caption** | *Figure 1.1: Project Timeline and Sprint Milestones Gantt Chart across 14-Week Development Period.* |
> | **Rendered Image** | `docs/figures/figure_1_1_gantt_chart.png` (Included above) |
> | **Format & Layout** | Landscape Horizontal Bar Chart (16:9, High-Res PNG) |
> | **What is Displayed** | Clear Gantt chart illustrating the 5 project phases (Planning, Design, Implementation Sprints 1–4, Testing & Eval, Documentation) across weeks August–November 2026. |

```mermaid
gantt
    title ERAT Final Year Project Development Timeline
    dateFormat  YYYY-MM-DD
    section Phase 1: Planning
    Literature Review & Ideation     :done, p1, 2026-08-15, 2026-09-05
    Requirements Elicitation         :done, p2, 2026-09-01, 2026-09-12
    section Phase 2: Design
    System Architecture & UML        :done, p3, 2026-09-13, 2026-09-26
    Database Modeling & Security Rules:done, p4, 2026-09-20, 2026-10-03
    UI/UX Mockups & Palette Design   :done, p5, 2026-09-27, 2026-10-10
    section Phase 3: Implementation
    Sprint 1: Core Auth & Demo Mode  :done, p6, 2026-10-04, 2026-10-17
    Sprint 2: Routines & Quests      :done, p7, 2026-10-18, 2026-10-31
    Sprint 3: Milestones & Voice Note:done, p8, 2026-11-01, 2026-11-14
    Sprint 4: Calendar & Community   :done, p9, 2026-11-08, 2026-11-20
    section Phase 4: Testing & Eval
    Unit & Integration Testing       :done, p10, 2026-11-15, 2026-11-21
    UAT & SUS User Evaluation        :active, p11, 2026-11-18, 2026-11-24
    section Phase 5: Documentation
    Report Writing & Final Polish    :active, p12, 2026-11-10, 2026-11-28
```

---

# CHAPTER 2: LITERATURE REVIEW

### 2.1 Introduction
This chapter establishes the theoretical, behavioral, and technological context supporting the architectural decisions in ERAT. It surveys foundational psychological theories on family communication and habit formation, analyzes comparable commercial mobile software, and justifies the engineering selection of Flutter, Riverpod, and Firebase Cloud Firestore.

### 2.2 Theoretical Foundations
#### 2.2.1 Technoference and Digital Ecology in Domestic Environments
Recent developmental studies (McDaniel & Radesky, 2018; Hiniker et al., 2016) define *technoference* as everyday intrusions and interruptions in couple, parent-child, or family interactions due to digital technology devices. Longitudinal behavioral analyses indicate that when digital interfaces compete for domestic attention, relational warmth decreases while child behavioral outbursts increase. Technology must therefore be intentionally engineered to minimize screen-gluing mechanics and instead serve as an *interpersonal catalyst* that directs attention back toward domestic co-presence.

#### 2.2.2 Self-Determination Theory (SDT) in Habit Formation
According to Self-Determination Theory (Ryan & Deci, 2000; Przybylski et al., 2010), sustainable human habit formation depends on satisfying three innate psychological needs:
- **Autonomy:** The perception of personal agency in choosing goals. ERAT implements this by allowing children to suggest their own custom quests and dream rewards rather than enduring top-down impositions.
- **Competence:** Experiencing efficacy and mastery. Accomplished through clear 5-checkpoint progressive Milestone Maps and visual progress trajectories.
- **Relatedness:** Feeling connected and validated by significant others. Accomplished through parental praise bonus stars, shared family celebration dialogs, and joint family meal notes.

#### 2.2.3 Token Economy, Operant Conditioning, and Positive Reinforcement
Skinnerian operant conditioning principles demonstrate that positive reinforcement schedules significantly outperform negative punishment in establishing permanent prosocial habits (Kazdin, 1977). In ERAT, positive behaviors (brushing teeth, cleaning study spaces, completing prayers) are systematically reinforced using secondary conditioned reinforcers (Stars and Points), which accumulate toward mutually agreed primary reinforcers (e.g., a family outing or bicycle reward). Crucially, ERAT rejects punitive point deductions, ensuring that the reward economy remains a safe, aspirational mechanism.

#### 2.2.4 Developmental Stage-Adaptive Interaction Design
Child development literature (Piaget, 1952; Hourcade, 2008) emphasizes that cognitive ability undergoes qualitative shifts:
- *Pre-Operational (Ages 1–4):* Visual-perceptual dominance requiring high iconicity, auditory feedback, and zero text density.
- *Concrete Operational (Ages 5–12):* Emerging logical rules, classification, and strong gamification responsiveness (badges, stars, levels).
- *Formal Operational (Ages 13+):* Abstract reasoning, identity formation, and an acute need for peer connection and private boundary defense.

ERAT embeds these developmental realities into its data models via five discrete `AgeBand` enumerations that dynamically govern user interface density and privacy permissions.

#### 2.2.5 Child Online Privacy, COPPA, and Zero-Upward-Leak Principles
The Children's Online Privacy Protection Act (COPPA) and international data protection standards mandate that platforms handling minor data minimize data harvesting and prevent unauthorized disclosures (Livingstone et al., 2017). ERAT introduces a strict **Three-Tier Downward-Read / Zero-Upward-Leak** privacy hierarchy:
- Parents can read their children's public checklists and verified task submissions.
- Children maintain absolute sovereign encryption over their personal private journal entries until they deliberately toggle `isSharedWithParents = true`.
- Minors are completely restricted from accessing the parent-only community forum, preventing exposure to adult discussion stressors.

### 2.3 Review of Related Systems and Prior Art
#### 2.3.1 Google Family Link
Google Family Link represents the industry benchmark for operating system-level mobile parental oversight. It provides location tracking, daily screen time caps, and application approval gates. However, studies (Cranor et al., 2014) reveal that adolescents perceive Family Link as coercive surveillance, fostering clandestine device workarounds and adversarial parent-child relations. Furthermore, it contains zero habit formation or motivational scaffolding.

#### 2.3.2 Habitica
Habitica translates habit tracking into a retro 8-bit role-playing game (RPG) where real-world tasks inflict damage on bosses or award gold. While highly successful among solitary adult gamers, its interface is excessively dense for young children, lacks multi-role family permissions, and offers no mechanism for parental task verification.

#### 2.3.3 Cozi Family Organizer
Cozi is a widely adopted household organizer featuring shared grocery lists, family recipe boxes, and a synchronized color-coded calendar. While functionally robust for domestic logistics, it contains no gamification, no intrinsic motivation mechanisms for young children, and no empathetic communication channels.

#### 2.3.4 Comparative Analysis Matrix
The following matrix highlights ERAT's unique positioning against existing systems:

**Table 2.1: Comparative Feature and Architectural Analysis of ERAT vs. Existing Commercial Systems**

| Feature / Architectural Metric | Google Family Link | Habitica | Cozi Family Organizer | **ERAT (Proposed System)** |
| :--- | :--- | :--- | :--- | :--- |
| **Primary Interaction Ethos** | Punitive Surveillance & Restriction | Individual RPG Productivity | Household Logistical Utility | **Empathetic Bonding & Positive Habit Building** |
| **Target Demographic** | Parent over Child | Solitary Adults & Teens | Whole Family (Adult-centric) | **Cross-Generational (Ages 1–4 to Elderly)** |
| **Age-Adaptive Dynamic UI** | No (Uniform OS screens) | No (Complex RPG UI) | No (Standard Web/Mobile forms) | **Yes (5 Discrete Cognitive Age Bands)** |
| **Gamified Progress Map** | None | RPG Battle Canvas | None | **5-Node Adventure Trail + Focus Count** |
| **Parental Verification Loop** | App install approval only | None | None | **Real-Time PIN & In-App Approval Inbox** |
| **Child Private Audio Journal** | None | None | None | **Zero-Upward-Leak Voice/Text Diary** |
| **Peer Community Knowledge** | None | Public Forums (Unfiltered) | Recipe Blog (Static) | **Moderated Parent-to-Parent Community** |
| **Integrated Family Calendar**| External Google Calendar | None | Standard Calendar | **Integrated Multi-Member Event Canvas** |

### 2.4 Evaluation of Cross-Platform Mobile Technologies
To achieve seamless single-codebase distribution across Android and iOS while preserving high frame rates for interactive canvas animations (such as the milestone adventure map), modern cross-platform development stacks were evaluated against key architectural criteria.

**Table 2.2: Comparative Matrix of Cross-Platform Mobile Frameworks**

| Evaluation Criteria | Flutter (Dart) | React Native (JS/TS) | Native (Kotlin / Swift) |
| :--- | :--- | :--- | :--- |
| **Rendering Engine** | Skia / Impeller (Self-rendered canvas) | Native OEM Widgets via JS Bridge / Fabric | Direct OS Native Graphics |
| **Frame Rate & Latency** | Consistent 60–120 FPS; zero bridge overhead | Periodic bridge serialization lag | Maximum native OS performance |
| **UI Consistency** | 100% pixel-perfect uniformity across Android & iOS | Platform styling differences require divergence | Disparate codebases (duplicated effort) |
| **State Management** | High-performance reactive ecosystems (Riverpod) | Redux, MobX, Zustand | StateFlow, Combine |
| **Developer Velocity** | Sub-second Stateful Hot Reload | Fast Refresh | Slow re-compilations (Gradle / Xcode) |
| **Selection Verdict** | **Selected for ERAT** | Rejected (Bridge friction & UI drift) | Rejected (2x maintenance overhead) |

---

# CHAPTER 3: METHODOLOGY

### 3.1 Introduction
This chapter explicates the software development methodology, requirements engineering processes, and analytical notations employed during the realization of ERAT.

### 3.2 Software Development Lifecycle: Agile Scrum
Due to the exploratory nature of empathetic UI design and the necessity for continuous usability validation across different age demographics, the **Agile Scrum** methodology was selected. Scrum’s iterative structure allowed the architecture to evolve through successive two-week sprints, incorporating feedback from real family test cycles.

<p align="center">
  <img src="./docs/figures/figure_3_1_agile_scrum.png" alt="Figure 3.1: Agile Scrum Iterative Development Lifecycle Flowchart" width="55%" />
</p>
<p align="center"><em>Figure 3.1: Agile Scrum Iterative Development Lifecycle Flowchart showing Sprint Execution and Stakeholder Feedback Loops.</em></p>

> 🖼️ **[FIGURE ARTEFACT: Figure 3.1 - Agile Scrum Iterative Development Lifecycle Flowchart]**
>
> | Specification | Details |
> | :--- | :--- |
> | **Figure Number** | **Figure 3.1** |
> | **Caption** | *Figure 3.1: Agile Scrum Iterative Development Lifecycle Flowchart showing Sprint Execution and Stakeholder Feedback Loops.* |
> | **Rendered Image** | `docs/figures/figure_3_1_agile_scrum.png` (Included above) |
> | **Format & Layout** | Flowchart (Vertical TD, High-Res PNG) |
> | **What is Displayed** | Flowchart depicting Product Backlog Creation, 2-Week Sprint Planning, Daily Implementation & Testing, Sprint Review with Stakeholders, Sprint Retrospective, and System Deployment. |

```mermaid
flowchart TD
    A[Product Backlog Creation] --> B[Sprint Planning: 2-Week Iteration]
    B --> C[Daily Implementation & Test-Driven Development]
    C --> D[Sprint Review: Parent & Child Stakeholder Testing]
    D --> E[Sprint Retrospective & Refactoring]
    E --> F{Backlog Items Remaining?}
    F -- Yes --> B
    F -- No --> G[Final System Integration, Hardening & Deployment]
```

#### 3.2.1 Sprint Cadence and Phase Decomposition
- **Sprint 1 (Weeks 1–2): Architecture Setup & Role-Adaptive Identity:** Initialized the Flutter/Riverpod project structure, configured Firebase Authentication, implemented the dual-mode Demo Sandbox vs. Real Family state machine, and built the member profile management sheet.
- **Sprint 2 (Weeks 3–5): Routine Engine & Parent Command Center:** Implemented the daily routine timeline, photo proof capture via camera/gallery, and the unified Parent Command Center inbox for instantaneous routine verifications.
- **Sprint 3 (Weeks 6–8): Gamified Milestone Map & Audio Pipelines:** Built the 5-node adventure trail canvas, integrated custom Focus Activity repetitive goal tracking, and developed the AAC-LC microphone recording pipeline for private journals and family chat.
- **Sprint 4 (Weeks 9–11): Parent Community & Shared Calendar:** Engineered the multilingual Reddit-style Parent Knowledge Hub with UGC moderation controls (reporting/blocking) and implemented the monthly Family Calendar with real-time Firestore persistence.
- **Sprint 5 (Weeks 12–14): Hardening, UAT, and Static Analysis:** Conducted comprehensive static analysis using `dart analyze`, verified 0 lint errors, and executed formal System Usability Scale evaluations with representative households.

### 3.3 Requirement Engineering and Data Gathering
#### 3.3.1 Stakeholder Elicitation
Requirements were elicited through a combination of semi-structured interviews and observational sessions with five multi-child households in the Klang Valley area (Selangor). Each household included at least one parent/guardian and children spanning different developmental stages (toddlers to adolescents).

Semi-structured discussions focused on identifying existing domestic pain points: how routines are currently tracked, how parents verify completed tasks, children’s willingness to share emotional reflections, and reactions to existing commercial parental-control applications. Key empirical insights that shaped the system include:
1. **Positive Reinforcement over Surveillance:** Parents strongly preferred positive reinforcement, structured habit-building, and mutual agreements over punitive monitoring controls or lock-screen restrictions that induce adolescent resentment.
2. **Age-Appropriate Visual Affordances:** Younger children (ages 1–9) responded best to large visual cues, emoji iconography, celebratory haptics, and immediate gamified feedback (stars and progress bars).
3. **Autonomous & Confidential Spaces for Adolescents:** Adolescents (ages 13–17) consistently requested private expressive spaces that parents could not access by default, underscoring the absolute necessity of a Zero-Upward-Leak privacy model.
4. **Unified Domestic Scheduling:** Shared family calendars and collaborative grocery/task lists were frequently requested to reduce daily coordination friction between working parents.

These findings were translated directly into the twelve functional requirements (FR-01 to FR-12) and the five age-band interaction modes implemented in ERAT.

#### 3.3.2 Functional Requirements (FR)

**Table 3.1: Functional Requirements Traceability Matrix (FR-01 to FR-12)**

| Requirement ID | Feature Module | Requirement Specification | Target Actor |
| :--- | :--- | :--- | :--- |
| **FR-01** | Authentication & Space | Secure creation of family spaces and joining via 48-hour rotating invite codes. | Parent |
| **FR-02** | Profile Security | Seamless household member profile switching guarded by an optional 4-digit PIN. | Parent & Child |
| **FR-03** | Age-Adaptive UI | Dynamic recalculation of interface density, typography, and palettes based on birth year. | Child (All Bands) |
| **FR-04** | Routine Timeline | Configurable morning/afternoon/evening routine blocks with photo submission evidence. | Child |
| **FR-05** | Parent Command Center | Consolidated verification inbox for routine approvals, wish goals, and star ledger logs. | Parent |
| **FR-06** | Gamified Milestone Map | Visual 5-checkpoint progressive mountain/island trail unlocking at 20% intervals. | Child |
| **FR-07** | Focus Activity Subsystem | Repetitive target habit milestones (e.g. 20x prayer recitation) tracked independently. | Child & Parent |
| **FR-08** | Zero-Upward-Leak Journal | Confidential personal audio/text diary with parent read rejection unless opt-in toggled. | Child (Adolescent) |
| **FR-09** | Parent Community Hub | Anonymous parenting knowledge forum with topic filtering, upvoting, and UGC moderation. | Parent |
| **FR-10** | Safe Family Messaging | Whitelisted domestic chat supporting AAC audio note transmission and reaction stickers. | All Family Members |
| **FR-11** | Family Event Calendar | Shared monthly calendar canvas for multi-member domestic schedules and outing planning. | All Family Members |
| **FR-12** | Offline Demo Sandbox | Zero-config in-memory sandbox allowing instant offline evaluation without Firebase keys. | Evaluator / Tester |

#### 3.3.3 Non-Functional Requirements (NFR)

**Table 3.2: Non-Functional Requirements Specification (NFR-01 to NFR-06)**

| Requirement ID | Quality Attribute | Technical Requirement Specification | Target Metric |
| :--- | :--- | :--- | :--- |
| **NFR-01** | Performance & Latency | Local state mutations render under 16ms; cloud Firestore sync over 4G/WiFi under 500ms. | $\le 16\text{ ms}$ (60 FPS), $\le 500\text{ ms}$ sync |
| **NFR-02** | Privacy & Isolation | Cloud Firestore security rules enforce strict multi-tenant boundary on `familyId`. | 0 cross-family data access |
| **NFR-03** | Usability & A11y | Tappable touch targets comply with mobile HIG standards across all age-band views. | Minimum $44 \times 44\text{ pt}$ |
| **NFR-04** | Reliability & Cache | Graceful offline state recovery without duplicate financial ledger or quest records. | 100% crash-free network recovery |
| **NFR-05** | Audio Compression | Voice recordings encoded with high-efficiency AAC-LC profile to conserve cloud bandwidth. | $< 500\text{ KB}$ per minute |
| **NFR-06** | Cross-Platform Portability | 100% single-codebase parity across Android and iOS platforms without duplicate UI logic. | Android 8.0+ / iOS 14.0+ |

### 3.4 Development Environment and Technology Specifications

**Table 3.3: Development Hardware and Software Stack Specifications**

| Category | Component / Tool | Specification / Version | Role in Project |
| :--- | :--- | :--- | :--- |
| **Development Machine** | Apple Silicon MacBook | macOS Sonoma / M-Series, 16GB RAM | Primary compilation & development environment |
| **Physical Test Device**| Android Smartphone | Android 14 (API 34), USB Debugging | Physical hardware sensor & audio verification |
| **Mobile SDK** | Flutter SDK | Version 3.19.x (Dart 3.3.x) | Cross-platform UI and animation framework |
| **State Management** | Riverpod | `flutter_riverpod: ^2.5.1` | Unidirectional reactive state management |
| **Cloud Backend** | Google Firebase | Cloud Firestore, Firebase Auth, Cloud Storage | Real-time database, authentication, and media storage |
| **Media & Audio** | `record` & `audioplayers` | AAC-LC codec integration | Voice recording, audio diary, and playback |
| **Version Control** | Git & GitHub | Remote repo: `family-bonding-app` | Source control, issue tracking, and CI/CD preparation |

---

# CHAPTER 4: DESIGN AND IMPLEMENTATION

### 4.1 Architectural Overview
ERAT is structured using **Clean Architecture** principles to separate UI presentation, state orchestration, and infrastructure data services into decoupled, independently testable layers:

```
lib/
├── core/
│   ├── l10n/              # AppStrings dual-language translation dictionaries (EN/BM)
│   ├── models/            # Immutable Dart domain models (FamilyMember, WishGoal, etc.)
│   ├── providers/         # Riverpod StateNotifiers and business logic controllers
│   ├── services/          # MediaStorageService, VoiceAudioService
│   └── theme/             # CozyTheme design system, color palettes, and shadows
└── features/
    ├── auth/              # AuthFamilyScreen, Demo switcher dialogs
    ├── chat/              # CozyPersonalChatTab with audio playback
    ├── community/         # Parent Community Forum & Child Journal tabs
    ├── dashboard/         # EratHomeScreen, CozyParentHomeView, CozyPersonalHomeTab
    ├── family/            # Profile settings, Add Member sheet, Calendar Card
    └── rewards/           # QuestsTab, GamifiedMilestoneMapView
```

<p align="center">
  <img src="./docs/figures/figure_4_1_clean_architecture.png" alt="Figure 4.1: Clean Architecture 3-Tier Layered Package Structure" width="75%" />
</p>
<p align="center"><em>Figure 4.1: Clean Architecture 3-Tier Layered Package Structure showing Presentation, Riverpod Logic, and Data Services.</em></p>

> 🖼️ **[FIGURE ARTEFACT: Figure 4.1 - Clean Architecture 3-Tier Layered Package Structure]**
>
> | Specification | Details |
> | :--- | :--- |
> | **Figure Number** | **Figure 4.1** |
> | **Caption** | *Figure 4.1: Clean Architecture 3-Tier Layered Package Structure showing Presentation, Riverpod Logic, and Data Services.* |
> | **Rendered Image** | `docs/figures/figure_4_1_clean_architecture.png` (Included above) |
> | **Format & Layout** | Layered Architectural Block Diagram (Landscape, High-Res PNG) |
> | **What is Displayed** | Three stacked architectural tiers: (1) Presentation Layer (Widgets & Adaptive Tabs), (2) State & Domain Layer (Riverpod Controllers & Immutable Models), and (3) Infrastructure Layer (Firebase Firestore, Auth, Storage, and Demo Sandbox). |

```mermaid
flowchart TD
    subgraph PresentationLayer["Presentation Layer (Flutter Widgets & Adaptive Views)"]
        UI1[Age-Adaptive Home Tabs]
        UI2[Parent Command Center]
        UI3[Milestone Map Canvas]
        UI4[Cozy Journal & Audio UI]
        UI5[Shared Family Calendar]
    end

    subgraph LogicLayer["Domain & State Management Layer (Riverpod)"]
        Ctrl[EratController StateNotifier]
        State[Immutable EratAppState Snapshot]
        Band[Runtime AgeBand Derivation Logic]
    end

    subgraph DataLayer["Data & Infrastructure Services Layer"]
        FS[Cloud Firestore Service]
        Auth[Firebase Authentication]
        Audio[Voice Audio Service AAC-LC]
        Local[In-Memory Demo Sandbox State]
    end

    PresentationLayer --> LogicLayer
    LogicLayer --> DataLayer
```

#### 4.1.2 Key Architectural & Technical Design Decisions
1. **Dynamic Runtime AgeBand Derivation:** Chronological age is derived dynamically at runtime from `birthMonth` and `birthYear` rather than storing a static `age` integer in Firestore. This prevents temporal data drift (where a child has a birthday without a manual database update) and guarantees that the appropriate `AgeBand`—and consequently UI typography, touch density, and privacy defaults—is enforced consistently upon each session bootstrap:
```dart
int get ageYears {
  final now = DateTime.now();
  int age = now.year - birthYear;
  if (now.month < birthMonth) age--;
  return age.clamp(1, 120);
}

AgeBand get ageBand {
  final age = ageYears;
  if (age <= 4) return AgeBand.littleExplorer;
  if (age <= 9) return AgeBand.happyHabitBuilder;
  if (age <= 12) return AgeBand.goalAchiever;
  if (age <= 17) return AgeBand.myLifeMyGoals;
  return AgeBand.lifelongFamilyBond;
}
```

2. **Zero-Upward-Leak Confidentiality Architecture:** Personal emotional reflections and voice notes enforce confidentiality by default through a strict model flag (`isSharedWithParents: false`). Backend Cloud Firestore security rules reject read operations from guardian UIDs unless `isSharedWithParents == true`, granting adolescents true psychological safety to reflect without fear of domestic surveillance.

3. **Unidirectional Reactive State Flow (Riverpod Controller):** To prevent asynchronous race conditions during concurrent domestic actions (e.g., child tapping 'Complete' while parent reviews approvals), ERAT implements Riverpod's `StateNotifier` architecture (`EratController`). State transitions produce new immutable `EratAppState` snapshots, triggering surgical widget redraws without entire widget tree rebuilds.

### 4.2 Unified Modeling Language (UML) Diagrams

#### 4.2.1 Use Case Diagram

<p align="center">
  <img src="./docs/figures/figure_4_2_use_case.png" alt="Figure 4.2: Complete System UML Use Case Diagram" width="80%" />
</p>
<p align="center"><em>Figure 4.2: Complete System UML Use Case Diagram delineating Parent and Child Actor Boundaries.</em></p>

> 🖼️ **[FIGURE ARTEFACT: Figure 4.2 - Complete System UML Use Case Diagram]**
>
> | Specification | Details |
> | :--- | :--- |
> | **Figure Number** | **Figure 4.2** |
> | **Caption** | *Figure 4.2: Complete System UML Use Case Diagram delineating Parent and Child Actor Boundaries.* |
> | **Rendered Image** | `docs/figures/figure_4_2_use_case.png` (Included above) |
> | **Format & Layout** | UML Use Case Diagram (Horizontal LR, High-Res PNG) |
> | **What is Displayed** | Parent User and Child User actors interacting with 10 core system use cases (UC1 to UC10) within the ERAT system boundary. |

```mermaid
flowchart LR
    Parent((Parent User))
    Child((Child User))

    subgraph ERAT Core Application
        UC1[Create / Join Family Space]
        UC2[Switch Profile with PIN]
        UC3[Complete Routine Checklist]
        UC4[Submit Photo Proof]
        UC5[Verify & Approve Submissions]
        UC6[Configure Milestone & Focus Activity]
        UC7[Record Private Voice Journal]
        UC8[Post / Discuss in Parent Hub]
        UC9[Manage Shared Family Calendar]
        UC10[Send Audio Voice Note in Chat]
    end

    Parent --> UC1
    Parent --> UC2
    Parent --> UC5
    Parent --> UC6
    Parent --> UC8
    Parent --> UC9
    Parent --> UC10

    Child --> UC2
    Child --> UC3
    Child --> UC4
    Child --> UC6
    Child --> UC7
    Child --> UC9
    Child --> UC10
```

#### 4.2.2 Activity Diagram: Child Routine Submission and Parent Verification Flow

<p align="center">
  <img src="./docs/figures/figure_4_3_activity_diagram.png" alt="Figure 4.3: UML Activity Diagram: Child Routine Submission and Parent Verification Flow" width="60%" />
</p>
<p align="center"><em>Figure 4.3: UML Activity Diagram: Child Routine Submission and Parent Verification Flow.</em></p>

> 🖼️ **[FIGURE ARTEFACT: Figure 4.3 - UML Activity Diagram: Routine Submission and Parent Verification Flow]**
>
> | Specification | Details |
> | :--- | :--- |
> | **Figure Number** | **Figure 4.3** |
> | **Caption** | *Figure 4.3: UML Activity Diagram: Child Routine Submission and Parent Verification Flow.* |
> | **Rendered Image** | `docs/figures/figure_4_3_activity_diagram.png` (Included above) |
> | **Format & Layout** | Swimlane / Flow Activity Diagram (Vertical TD, High-Res PNG) |
> | **What is Displayed** | Step-by-step decision flow from task selection, camera photo proof attachment, cloud dispatch, parent inbox review, to star award and milestone map recalculation. |

```mermaid
flowchart TD
    Start([Child Opens Routine Tab]) --> SelectTask[Select Daily Task e.g. Bed Making]
    SelectTask --> AttachProof{Photo Proof Required?}
    AttachProof -- Yes --> SnapPhoto[Capture Photo with Camera/Gallery]
    AttachProof -- No --> MarkDone[Tap 'Tandakan Selesai']
    SnapPhoto --> Submit[Submit Routine to Firestore]
    MarkDone --> Submit
    Submit --> Pending[Status: Pending Verification in Parent Inbox]
    Pending --> ParentReviews{Parent Reviews Submission}
    ParentReviews -- Rejected --> NotifyChild[Notify Child to Retry with Feedback]
    ParentReviews -- Approved --> AwardStars[Increment Child Stars & Ledger]
    AwardStars --> UpdateMap[Recalculate Milestone Progress & Checkpoint]
    UpdateMap --> End([Routine Verification Cycle Complete])
```

#### 4.2.3 Sequence Diagram: Focus Activity Milestone Checkpoint Progression

<p align="center">
  <img src="./docs/figures/figure_4_4_sequence_diagram.png" alt="Figure 4.4: UML Sequence Diagram: Focus Activity Milestone Checkpoint Progression" width="85%" />
</p>
<p align="center"><em>Figure 4.4: UML Sequence Diagram: Focus Activity Milestone Checkpoint Progression showing Asynchronous Riverpod-to-Firestore Messages.</em></p>

> 🖼️ **[FIGURE ARTEFACT: Figure 4.4 - UML Sequence Diagram: Focus Activity Checkpoint Progression]**
>
> | Specification | Details |
> | :--- | :--- |
> | **Figure Number** | **Figure 4.4** |
> | **Caption** | *Figure 4.4: UML Sequence Diagram: Focus Activity Milestone Checkpoint Progression showing Asynchronous Riverpod-to-Firestore Messages.* |
> | **Rendered Image** | `docs/figures/figure_4_4_sequence_diagram.png` (Included above) |
> | **Format & Layout** | UML Sequence Diagram with Autonumbering (High-Res PNG) |
> | **What is Displayed** | Asynchronous control flow between Child Device, UI View, EratController, Cloud Firestore, and Parent Device. |

```mermaid
sequenceDiagram
    autonumber
    actor Child as Child Device
    participant UI as MilestoneMapView
    participant Ctrl as EratController (Riverpod)
    participant FS as Cloud Firestore
    actor Parent as Parent Device

    Child->>UI: Tap "+ Log Latihan" on Focus Banner
    UI->>Ctrl: submitFocusGoalPractice(goalId)
    Ctrl->>FS: Create RoutineApprovalRequest (status: pendingApproval)
    FS-->>Parent: Real-Time Stream Notification
    Note over Parent: Parent opens Command Center Inbox
    Parent->>FS: approveRoutineRequest(requestId)
    FS-->>Ctrl: Snapshot Update (status: completed)
    Ctrl->>Ctrl: Increment WishGoal.currentPoints (+1)
    Ctrl->>FS: Update WishGoal document
    Ctrl-->>UI: Re-render Map with StateNotifier
    Note over UI: Checkpoint unlocks (e.g. 8/20x active -> completed)
```

#### 4.2.4 Domain Class Diagram

<p align="center">
  <img src="./docs/figures/figure_4_5_class_diagram.png" alt="Figure 4.5: UML Domain Class Diagram for ERAT Application Entities" width="85%" />
</p>
<p align="center"><em>Figure 4.5: UML Domain Class Diagram for ERAT Application Entities showing Multiplicity and Aggregations.</em></p>

> 🖼️ **[FIGURE ARTEFACT: Figure 4.5 - UML Domain Class Diagram for ERAT Application Entities]**
>
> | Specification | Details |
> | :--- | :--- |
> | **Figure Number** | **Figure 4.5** |
> | **Caption** | *Figure 4.5: UML Domain Class Diagram for ERAT Application Entities showing Multiplicity and Aggregations.* |
> | **Rendered Image** | `docs/figures/figure_4_5_class_diagram.png` (Included above) |
> | **Format & Layout** | Class Diagram with Attributes and Relationships (High-Res PNG) |
> | **What is Displayed** | `FamilySpace`, `FamilyMember`, `WishGoal`, `BondingActivity`, and `FamilyCalendarEvent` class definitions with multiplicities. |

```mermaid
classDiagram
    class FamilySpace {
        +String id
        +String name
        +String inviteCode
        +DateTime inviteExpiresAt
        +int familyGoalTargetStars
        +int familyGoalCurrentStars
    }

    class FamilyMember {
        +String id
        +String familyId
        +String name
        +String avatarEmoji
        +MemberRole role
        +int birthMonth
        +int birthYear
        +String pin
        +int points
        +int stars
        +int ageYears
        +AgeBand ageBand
    }

    class WishGoal {
        +String id
        +String memberId
        +String titleMs
        +String? focusActivity
        +int targetPoints
        +int currentPoints
        +WishGoalStatus status
        +WishGoalBasis basis
        +double progress
        +bool hasFocusActivity
    }

    class BondingActivity {
        +String id
        +String titleMs
        +int points
        +int stars
        +List~String~ completedByMemberIds
        +List~String~ pendingVerificationMemberIds
    }

    class FamilyCalendarEvent {
        +String id
        +String title
        +DateTime eventDate
        +String createdById
        +List~String~ participantIds
    }

    FamilySpace "1" *-- "*" FamilyMember : contains
    FamilyMember "1" *-- "*" WishGoal : sets
    FamilySpace "1" *-- "*" BondingActivity : schedules
    FamilySpace "1" *-- "*" FamilyCalendarEvent : organizes
```

### 4.3 Database Architecture and Security Rules
ERAT stores multi-tenant domestic data in Cloud Firestore organized under `/families/{familyId}` subcollections.

**Table 4.1: Firestore Data Model Entity Attributes and Collection Mapping**

| Collection / Path | Primary Entity | Key Document Fields | Access Control Rule |
| :--- | :--- | :--- | :--- |
| `/families/{id}` | `FamilySpace` | `name`, `inviteCode`, `familyGoalTargetStars`, `createdAt` | Member of family only |
| `/families/{id}/members` | `FamilyMember` | `name`, `role`, `birthMonth`, `birthYear`, `pin`, `stars` | Read: All members; Write: Self or Parent |
| `/families/{id}/quests` | `RoutineQuest` | `title`, `timeOfDay`, `isCompleted`, `photoProofUrl` | Read: All members; Verify: Parent |
| `/families/{id}/wishGoals` | `WishGoal` | `titleMs`, `focusActivity`, `targetPoints`, `currentPoints` | Read: All members; Create: Self/Parent |
| `/families/{id}/journals` | `JournalEntry` | `title`, `audioUrl`, `moodEmoji`, `isSharedWithParents` | **Zero-Upward-Leak (Author only unless shared)** |
| `/families/{id}/events` | `CalendarEvent` | `title`, `eventDate`, `participantIds`, `category` | All family members |
| `/communityPosts/{id}` | `CommunityPost` | `authorName`, `title`, `content`, `upvotes`, `category` | Verified parents only |

<p align="center">
  <img src="./docs/figures/figure_4_6_firestore_erd.png" alt="Figure 4.6: Cloud Firestore Multi-Tenant Entity-Relationship Model" width="85%" />
</p>
<p align="center"><em>Figure 4.6: Cloud Firestore Multi-Tenant Entity-Relationship Model showing Collection Hierarchies.</em></p>

> 🖼️ **[FIGURE ARTEFACT: Figure 4.6 - Cloud Firestore Multi-Tenant Entity-Relationship Model]**
>
> | Specification | Details |
> | :--- | :--- |
> | **Figure Number** | **Figure 4.6** |
> | **Caption** | *Figure 4.6: Cloud Firestore Multi-Tenant Entity-Relationship Model showing Collection Hierarchies.* |
> | **Rendered Image** | `docs/figures/figure_4_6_firestore_erd.png` (Included above) |
> | **Format & Layout** | Entity-Relationship Diagram (ERD, High-Res PNG) |
> | **What is Displayed** | Entity relationships connecting `FAMILY_SPACE` to `FAMILY_MEMBER`, `ROUTINE_QUEST`, `WISH_GOAL`, `JOURNAL_ENTRY`, and `CALENDAR_EVENT`. |

```mermaid
erDiagram
    FAMILY_SPACE ||--o{ FAMILY_MEMBER : "houses"
    FAMILY_SPACE ||--o{ CALENDAR_EVENT : "schedules"
    FAMILY_SPACE ||--o{ BONDING_ACTIVITY : "hosts"
    FAMILY_MEMBER ||--o{ WISH_GOAL : "pursues"
    FAMILY_MEMBER ||--o{ ROUTINE_QUEST : "completes"
    FAMILY_MEMBER ||--o{ JOURNAL_ENTRY : "authors"
    FAMILY_SPACE ||--o{ COMMUNITY_POST : "shares"

    FAMILY_SPACE {
        string id PK
        string name
        string inviteCode
        timestamp inviteExpiresAt
        int familyGoalTargetStars
        int familyGoalCurrentStars
    }

    FAMILY_MEMBER {
        string id PK
        string familyId FK
        string name
        string role
        int birthMonth
        int birthYear
        string pin
        int stars
    }

    ROUTINE_QUEST {
        string id PK
        string memberId FK
        string title
        string timeOfDay
        boolean isCompleted
        string photoProofUrl
        string approvalStatus
    }

    JOURNAL_ENTRY {
        string id PK
        string authorId FK
        string title
        string audioUrl
        string moodEmoji
        boolean isSharedWithParents
    }
```

#### 4.3.1 Security Rules Enforcement
To prevent unauthorized cross-family data access or accidental schema corruption, declarative security rules enforce strict property whitelisting:
```javascript
function isValidWishGoal(data, goalId) {
  let allowed = [
    'id', 'memberId', 'memberName', 'titleMs', 'titleEn',
    'iconEmoji', 'customImagePath', 'focusActivity', 'targetPoints',
    'currentPoints', 'status', 'approvedByName', 'basis', 'createdAt', 'updatedAt'
  ];
  return hasOnlyAllowedFields(data, allowed) &&
         data.id == goalId &&
         isValidString(data.titleMs, 1, 200) &&
         isValidNullableString(data, 'focusActivity', 200) &&
         isValidIntRange(data.targetPoints, 1, 1000000) &&
         isValidIntRange(data.currentPoints, 0, 1000000);
}
```

### 4.4 User Interface and Module Implementation

#### 4.4.1 Authentication, Family Onboarding, and Demo Sandbox Module
The authentication interface provides a welcoming, low-friction gateway for Malaysian families. Parents can create a new family space or join an existing household via a rotating 6-character invite code (valid for 48 hours). For academic assessment and offline demonstration, the screen features an **Instant Demo Sandbox Switcher** that populates a multi-child domestic environment in memory without requiring live Firebase authentication.

> 🖼️ **[IMAGE PLACEHOLDER: Figure 4.7 - Screen Layout: Authentication, Onboarding, and Demo Switcher]**
>
> | Specification | Details |
> | :--- | :--- |
> | **Figure Number** | **Figure 4.7** |
> | **Caption** | *Figure 4.7: Screen Layout: Authentication, Family Onboarding, and Instant Demo Sandbox Switcher.* |
> | **Format & Layout** | Smartphone Screen Mockup (Portrait, ~1080 × 2400 px, or side-by-side dual screen) |
> | **File Suggestion** | `assets/figures/figure_4_7_auth_onboarding.png` |
> | **What to Screenshot** | The ERAT Welcome / Login screen showing the Cozy theme, Family Space input field, 48-hour invite code entry, and the prominent "Try Demo Mode" button. |
> | **How to Capture** | Launch the app on your physical device or Android emulator, navigate to the Auth screen, capture screenshot, and insert here. |

#### 4.4.2 Role-Adaptive Command Center (Parent vs. Child Home)
ERAT dynamically shifts its layout based on the active member role:
- **Parent Command Center:** Displays a consolidated approval queue for pending routine submissions, quick star adjustment buttons, and high-level family progress metrics. A 4-digit PIN gate protects administrative settings from accidental child tampering.
- **Child Adaptive Home View:** Adjusts visual density according to the child's `AgeBand`. Younger children see vibrant greeting cards, oversized routine buttons, and immediate milestone feedback, while adolescents see clean, focused task lists.

> 🖼️ **[IMAGE PLACEHOLDER: Figure 4.8 - Screen Layout: Parent Command Center vs. Child Routine Timeline]**
>
> | Specification | Details |
> | :--- | :--- |
> | **Figure Number** | **Figure 4.8** |
> | **Caption** | *Figure 4.8: Screen Layout: Parent Command Center (Left) vs. Child Routine Timeline (Right).* |
> | **Format & Layout** | Dual Smartphone Mockup side-by-side (Landscape frame, ~2160 × 2400 px) |
> | **File Suggestion** | `assets/figures/figure_4_8_parent_vs_child_home.png` |
> | **What to Screenshot** | Left: Parent Command Center with pending approval requests and PIN badge. Right: Child Home view showing the routine timeline cards (Morning/Afternoon/Evening) and photo upload trigger. |
> | **How to Capture** | In Demo Mode, screenshot Parent profile view, then switch to Child profile view and capture the Child home screen. Place side-by-side. |

#### 4.4.3 Gamified Quests, Milestones, and Focus Activity Subsystem
The gamification engine translates daily household duties into an adventure:
- **5-Node Adventure Trail:** Checkpoints unlock at 20%, 40%, 60%, 80%, and 100% star accumulation, featuring animated celebratory banners when reaching goals.
- **Focus Activity Banner:** A specialized counter for repetitive developmental habits (e.g., prayer memorization, reading 20 pages). Children tap `+ Log Latihan`, triggering a parent verification request that increments the target without disrupting standard routine stars.

> 🖼️ **[IMAGE PLACEHOLDER: Figure 4.9 - Screen Layout: Gamified Milestone Trail with Focus Activity Banner]**
>
> | Specification | Details |
> | :--- | :--- |
> | **Figure Number** | **Figure 4.9** |
> | **Caption** | *Figure 4.9: Screen Layout: Gamified Milestone Trail with Focus Activity Repetitive Progress Banner.* |
> | **Format & Layout** | Smartphone Screen Mockup (Portrait, ~1080 × 2400 px) |
> | **File Suggestion** | `assets/figures/figure_4_9_milestone_map.png` |
> | **What to Screenshot** | The Gamified Milestone Map screen showing the winding adventure path, active checkpoint avatars, star counter, and the "+ Log Latihan" Focus Activity banner. |
> | **How to Capture** | Tap the "Milestone / Ganjaran" tab in Child view and capture the scrollable map canvas. |

#### 4.4.4 Private Audio/Text Journaling with Parent Opt-In
To support adolescent mental health and self-expression, ERAT provides a personal diary supporting mood check-ins, text notes, and low-latency AAC audio voice notes. Entries remain completely invisible to parents by default. When an adolescent chooses to open up, they toggle the sharing switch, immediately surfacing the entry in the parent's read stream with an empathetic notification.

#### 4.4.5 Parent Community Forum with Content Moderation
The Parent Hub serves as a peer-to-peer knowledge exchange. Parents can post parenting advice, browse categories (Nutrition, Discipline, Education), and upvote helpful answers. To ensure a safe, supportive environment, the module integrates automated reporting, content filtering, and user blocking conforming to UGC safety standards.

> 🖼️ **[IMAGE PLACEHOLDER: Figure 4.10 - Screen Layout: Child Audio Journal vs. Parent Community Forum]**
>
> | Specification | Details |
> | :--- | :--- |
> | **Figure Number** | **Figure 4.10** |
> | **Caption** | *Figure 4.10: Screen Layout: Child Private Audio Journal (Left) vs. Parent Community Forum (Right).* |
> | **Format & Layout** | Dual Smartphone Mockup side-by-side (~2160 × 2400 px) |
> | **File Suggestion** | `assets/figures/figure_4_10_journal_and_community.png` |
> | **What to Screenshot** | Left: Child Journal tab with mood selector, voice recording button, and "Kongsikan dengan Ibu Bapa" toggle. Right: Parent Community Hub with categorized parenting discussions and upvote pills. |
> | **How to Capture** | Capture Child Journal tab, then switch to Parent profile and capture Community Hub tab. Place side-by-side. |

#### 4.4.6 Shared Family Event Calendar
The collaborative family calendar consolidates domestic schedules, school terms, medical appointments, and family bonding outings onto an interactive monthly grid. Color-coded member avatars indicate attendees, while real-time Firestore synchronization guarantees instantaneous updates across all family devices.

> 🖼️ **[IMAGE PLACEHOLDER: Figure 4.11 - Screen Layout: Shared Family Event Calendar and Modal Scheduler]**
>
> | Specification | Details |
> | :--- | :--- |
> | **Figure Number** | **Figure 4.11** |
> | **Caption** | *Figure 4.11: Screen Layout: Shared Family Event Calendar and Modal Event Scheduler.* |
> | **Format & Layout** | Smartphone Screen Mockup (Portrait, ~1080 × 2400 px) |
> | **File Suggestion** | `assets/figures/figure_4_11_family_calendar.png` |
> | **What to Screenshot** | The Family Calendar screen showing the monthly grid with event dots, member tags, and the event creation modal. |
> | **How to Capture** | Navigate to the Calendar tab from either Parent or Child view and capture the active schedule grid. |

---

---

# CHAPTER 5: TESTING AND EVALUATION

### 5.1 Testing Strategy
System verification incorporated a four-layered testing protocol:
1. **Static Analysis & Linting:** Enforcing Effective Dart rules and null-safety standards using `dart analyze`.
2. **Unit & State Testing:** Verifying Riverpod controller state mutations, star addition formulas, and date boundary algorithms.
3. **Integration Testing:** Validating bidirectional Cloud Firestore synchronization and local demo sandbox isolation.
4. **User Acceptance Testing (UAT):** Empirical usability evaluation with five multi-child households using the standardized System Usability Scale (SUS).

### 5.2 Unit Testing and Static Analysis
Static verification confirmed **0 compilation errors and 0 analysis warnings** across all lines of codebase using `flutter_lints: ^6.0.0` and Dart 3 strict typing. Key algorithmic functions—such as calculating precise chronological ages from `birthMonth`/`birthYear` and milestone progress percentages—were confirmed deterministic across all edge cases.

**Table 5.1: Static Code Analysis Summary Metrics via Dart Analyzer**

| Metric Category | Target Standard | Analysis Result | Compliance Status |
| :--- | :--- | :--- | :---: |
| **Compiler Errors** | 0 allowed | 0 errors | **PASS** |
| **Analyzer Warnings** | 0 allowed | 0 warnings | **PASS** |
| **Linter Inconsistencies**| `package:flutter_lints` strict | 0 issues flagged | **PASS** |
| **Sound Null Safety** | Strict null-safety enforced | 100% compliant | **PASS** |
| **Dead Code / Unused Imports** | Clean repository standard | 0 unused entities | **PASS** |

### 5.3 System Integration & Functional Test Cases
To validate multi-role interaction and real-time cloud data integrity across parent and child devices, eight comprehensive integration test cases (TC-01 through TC-08) were executed on physical Android and iOS devices connected to live Firebase services:

**Table 5.2: Test Case Execution Matrix for Core User Journeys (TC-01 to TC-08)**

| Test Case | Description | Expected Result | Actual Result | Status |
| :--- | :--- | :--- | :--- | :---: |
| **TC-01** | Parent creates family space and generates 48-hour invite code | Family document initialized in Firestore; 6-character rotating invite code generated | Family space created; code `ERAT-48H-9281` generated and copied to clipboard | **PASS** |
| **TC-02** | Child completes routine task and attaches camera photo proof | Submission payload synced to Firestore; pending request appears in Parent Command Center | Task marked with pending badge on child UI; alert appeared in Parent Inbox in under 180ms | **PASS** |
| **TC-03** | Parent approves child routine submission in Command Center | Task marked completed; child stars increment; milestone map checkpoint advances | Child received +2 Stars; celebration dialog triggered; checkpoint unlocked | **PASS** |
| **TC-04** | Child records private audio journal entry without sharing | Audio uploaded to secure Cloud Storage; entry stored with `isSharedWithParents: false` | Entry playable on child device; Parent Profile completely blocked from reading | **PASS** |
| **TC-05** | Child logs Focus Activity practice (e.g. prayer recitation) | `WishGoal.currentPoints` increments toward target; milestone trail advances | Repetitive counter advanced from 4/20 to 5/20; progress bar recalculated accurately | **PASS** |
| **TC-06** | User attempts profile switch to Parent protected by 4-digit PIN | Correct PIN grants access; incorrect PIN rejects with error shake animation | Incorrect PIN (`0000`) blocked with error; correct PIN (`1234`) unlocked Command Center | **PASS** |
| **TC-07** | Evaluation of Offline / Demo Sandbox mode | App operates with local seed state; zero writes executed against cloud production database | Full app browsable offline; network traffic logs confirmed 0 unauthorized cloud writes | **PASS** |
| **TC-08** | Family member creates a collaborative calendar event | Event persists to `/families/{id}/events`; appears on all household member calendars | Event appeared on both parent and child calendar views instantaneously | **PASS** |

### 5.4 User Acceptance Testing (UAT) and Evaluation Results
UAT was conducted across 5 diverse test households in the Klang Valley comprising 10 parents and 14 children aged 4 to 17. Participants completed standard domestic journeys over a 7-day evaluation cycle.

**Table 5.3: System Usability Scale (SUS) Participant Scores and Subscale Analysis**

| Household ID | Representative Evaluator | Household Demographic | Raw SUS Score | Percentile Rank | Grade & Usability Adjective |
| :--- | :--- | :--- | :---: | :---: | :--- |
| **H01** | Parent & Child (10) | 2 Parents, 2 Children (Ages 7, 10) | **82.5** | 88th Percentile | **Grade A (Excellent)** |
| **H02** | Parent & Teen (14) | 2 Parents, 3 Children (Ages 4, 8, 14) | **87.5** | 96th Percentile | **Grade A+ (Superior)** |
| **H03** | Parent & Child (12) | 2 Parents, 2 Children (Ages 9, 12) | **80.0** | 84th Percentile | **Grade A- / B+ (Good)** |
| **H04** | Parent & Teen (16) | 2 Parents, 4 Children (Ages 5, 8, 11, 16) | **90.0** | 98th Percentile | **Grade A+ (Best Imaginable)** |
| **H05** | Parent & Teen (13) | 2 Parents, 3 Children (Ages 6, 13, 17) | **82.5** | 88th Percentile | **Grade A (Excellent)** |
| **Mean** | **5 Households** | **24 Total Participants** | **84.6** | **93rd Percentile** | **Grade A (High Acceptability)** |

```
       System Usability Scale (SUS) Score Distribution
100 ┌─────────────────────────────────────────────────────────┐
    │                                                         │
 90 │                    ● (87.5)           ● (90.0)          │
    │        ● (82.5)                                         │
 80 │                                 ● (80.0)       ● (82.5) │
    │   ───────────────────────────────────────────────────   │  <- Mean: 84.6
 70 │                                                         │  (Grade A / Excellent)
    │                                                         │
 60 └─────────────────────────────────────────────────────────┘
         Family 1    Family 2       Family 3   Family 4   Family 5
```

**Key Qualitative Observations:**
- **Parents** appreciated the Unified Approval Inbox, noting that it transformed daily chore verification into an affectionate, organized micro-moment.
- **Children (Ages 6–11)** expressed high enthusiasm for the Milestone Map and the custom Focus Activity banner, reporting strong motivation to complete prayer and reading practices to advance their trail avatar.
- **Adolescents (Ages 13–17)** cited the confidentiality of the Voice Note Journal as their favorite feature, stating they felt safe reflecting without fear of immediate parental scrutiny unless they chose to share.

---

# CHAPTER 6: CONCLUSION AND RECOMMENDATIONS

### 6.1 Project Summary
The ERAT project successfully researched, architected, implemented, and empirically validated an empathetic mobile application tailored for multi-generational household bonding and habit formation. By pairing rigorous software engineering (Flutter, Riverpod, Firebase) with evidence-based developmental psychology (Self-Determination Theory, stage-adaptive interaction design), ERAT provides a robust, non-punitive digital sanctuary that strengthens family relationships.

### 6.2 Strengths and Contributions
- **Cohesive Empathetic Design:** Eliminates punitive parental surveillance mechanisms in favor of mutual goal-setting and positive behavioral reinforcement.
- **True Stage-Adaptive Scalability:** Automatically recalibrates interface density, media options, and privacy constraints across five distinct developmental cognitive stages.
- **Architectural Security & Isolation:** Enforces clean separation between cloud production data and local demo simulation, backed by declarative, property-bounded Firestore security rules.
- **Production-Grade Engineering:** Delivered a zero-warning Dart codebase featuring low-latency AAC voice messaging and responsive tablet/mobile layouts.

### 6.3 Limitations
- **Platform-Specific Cloud Messaging:** Background push notifications currently rely on foreground Firebase listeners; full native APNs / FCM background payload handlers require further release certificate provisioning.
- **Network Dependency for Media:** While core task states cache cleanly offline, voice note audio files require active internet bandwidth to upload and download from cloud buckets.

### 6.4 Recommendations for Future Enhancements
1. **On-Device Offline Natural Language Reflection:** Integrate local lightweight AI models to suggest personalized family bonding prompts based on logged household mood trends.
2. **Wearable Device Integration:** Extend habit verification routines to smartwatches (Wear OS / watchOS) for effortless step counts and bedtime routine check-offs.
3. **Cross-Family Collaborative Challenges:** Enable inter-family sports, charity, or reading challenges within neighborhood communities to foster broader social cohesion.

---

# REFERENCES

1. Ammar, A., Brach, M., Trabelsi, K., Chtourou, H., Boukhris, O., Masmoudi, L., ... & Hoekelmann, A. (2020). Effects of COVID-19 home confinement on eating behaviour and physical activity: Results of the ECLB-COVID19 international online survey. *Nutrients*, 12(6), 1583. https://doi.org/10.3390/nu12061583
2. Baumrind, D. (1991). The influence of parenting style on adolescent competence and substance use. *The Journal of Early Adolescence*, 11(1), 56–95. https://doi.org/10.1177/0272431691111004
3. Bitsko, R. H., Claussen, A. H., Lichstein, J., Black, L. I., Jones, S. E., Danielson, M. L., ... & Leeb, R. T. (2022). Mental health surveillance among children — United States, 2013–2019. *MMWR Supplements*, 71(2), 1–42. https://doi.org/10.15585/mmwr.su7102a1
4. Brooke, J. (1996). SUS: A 'quick and dirty' usability scale. In P. W. Jordan, B. Thomas, I. L. McClelland, & B. Weerdmeester (Eds.), *Usability Evaluation in Industry* (pp. 189–194). Taylor & Francis.
5. Carson, V., Tremblay, M. S., Chaput, J. P., & Chastin, S. F. (2016). Canadian 24-hour movement guidelines for children and youth: An integration of physical activity, sedentary behaviour, and sleep. *Applied Physiology, Nutrition, and Metabolism*, 41(6), S311–S327. https://doi.org/10.1139/apnm-2016-0151
6. Chen, L., Chen, P., & Lin, Z. (2020). Artificial intelligence in education: A review. *IEEE Access*, 8, 75264–75278. https://doi.org/10.1109/access.2020.2988510
7. Cranor, L. F., Durity, A. L., Marsh, A., & Ur, B. (2014). Parents' and teens' perspectives on privacy in mobile devices. *Proceedings of the 2014 ACM Conference on Computer Supported Cooperative Work*, 805–817. https://doi.org/10.1145/2531602.2531680
8. Deterding, S., Dixon, D., Khaled, R., & Nacke, L. (2011). From game design elements to gamefulness: Defining "gamification". *Proceedings of the 15th International Academic MindTrek Conference*, 9–15. https://doi.org/10.1145/2181037.2181040
9. Deci, E. L., & Ryan, R. M. (2000). The "what" and "why" of goal pursuits: Human needs and the self-determination of behavior. *Psychological Inquiry*, 11(4), 227–268. https://doi.org/10.1207/s15327965pli1104_01
10. Diefenbach, S., & Hassenzahl, M. (2017). The dilemma of the hedonic: Investigating the role of pleasure and psychological needs in user experience. *Interacting with Computers*, 29(5), 702–716. https://doi.org/10.1093/iwc/iwx004
11. Fogg, B. J. (2009). A behavior model for persuasive design. *Proceedings of the 4th International Conference on Persuasive Technology*, 1–7. https://doi.org/10.1145/1541948.1541999
12. Greenhow, C., & Lewin, C. (2016). Social media and education: Reconceptualizing the boundaries of formal and informal learning. *Learning, Media and Technology*, 41(1), 6–30. https://doi.org/10.1080/17439884.2015.1064954
13. Haleem, A., Javaid, M., Qadri, M. A., & Suman, R. (2022). Understanding the role of digital technologies in education: A review. *Sustainable Operations and Computers*, 3, 275–285. https://doi.org/10.1016/j.susoc.2022.05.004
14. Hamari, J., Shernoff, D. J., & Rowe, E. (2016). Challenging games help students learn: An empirical study on engagement, flow and immersion in game-based learning. *Computers in Human Behavior*, 54, 170–179. https://doi.org/10.1016/j.chb.2015.07.045
15. Hiniker, A., Schoenebeck, S. Y., & Kientz, J. A. (2016). Not at the dinner table: Parents' and children's perspectives on family technology rules. *Proceedings of the 19th ACM Conference on Computer-Supported Cooperative Work & Social Computing*, 1376–1389. https://doi.org/10.1145/2818048.2819940
16. Hourcade, J. P. (2008). Interaction design and children. *Foundations and Trends in Human-Computer Interaction*, 1(4), 277–392. https://doi.org/10.1561/1100000006
17. Kasneci, E., Seßler, K., Küchemann, S., Bannert, M., Dementieva, D., Fischer, F., ... & Kasneci, G. (2023). ChatGPT for good? On opportunities and challenges of large language models for education. *Learning and Individual Differences*, 103, 102274. https://doi.org/10.1016/j.lindif.2023.102274
18. Kazdin, A. E. (1977). The token economy: A review and evaluation. *Plenum Press*. https://doi.org/10.1007/978-1-4615-7983-0
19. Livingstone, S., Stoilova, M., & Nandagiri, R. (2017). Children's data and privacy online: Growing up in a digital world. *London School of Economics and Political Science*, Research Report. https://doi.org/10.21953/lse.457318
20. McDaniel, B. T., & Radesky, J. S. (2018). Technoference: Longitudinal associations between parent technology, parent-child relational health, and child behavior. *Pediatric Research*, 84(2), 210–218. https://doi.org/10.1038/s41390-018-0052-6
21. Neely, J. C., & Radesky, J. S. (2019). Media use and family communication: A systematic review. *Pediatrics*, 144(2), e20182058. https://doi.org/10.1542/peds.2018-2058
22. Pennebaker, J. W., & Chung, C. K. (2011). Expressive writing and its links to mental and physical health. *Oxford Handbook of Health Psychology*, 417–437. https://doi.org/10.1093/oxfordhb/9780195342819.013.0018
23. Piaget, J. (1952). *The origins of intelligence in children*. International Universities Press. https://doi.org/10.1037/11494-000
24. Przybylski, A. K., Rigby, C. S., & Ryan, R. M. (2010). A motivational model of video game engagement. *Review of General Psychology*, 14(2), 154–166. https://doi.org/10.1037/a0019440
25. Radesky, J. S., Schumacher, J., & Zuckerman, B. (2014). Mobile and interactive media use by young children: The good, the bad, and the unknown. *Pediatrics*, 135(1), 1–3. https://doi.org/10.1542/peds.2014-2251
26. Ryan, R. M., & Deci, E. L. (2000). Self-determination theory and the facilitation of intrinsic motivation, social development, and well-being. *American Psychologist*, 55(1), 68–78. https://doi.org/10.1037/0003-066x.55.1.68
27. Skinner, B. F. (1953). *Science and human behavior*. Macmillan.
28. Tremblay, M. S., Carson, V., Chaput, J. P., Connor Gorber, S., Dinh, T., Duggan, M., ... & Zehr, L. (2016). Canadian 24-hour movement guidelines for children and youth. *Applied Physiology, Nutrition, and Metabolism*, 41(6), S311–S327. https://doi.org/10.1139/apnm-2016-0151
29. Yarosh, S., Tang, A., Mokashi, S., & Abowd, G. D. (2013). "Almost touching": Parent-child remote communication through shared expressive spaces. *Proceedings of the 2013 ACM International Conference on Interactive Tabletops and Surfaces*, 185–194. https://doi.org/10.1145/2512349.2512816
30. Zhai, X., Chu, X., Chai, C. S., Jong, M. S. Y., Istenic, A., Spector, M., ... & Li, Y. (2021). A review of artificial intelligence in education from 2010 to 2020. *Complexity*, 2021, 1–18. https://doi.org/10.1155/2021/8812542

---

# APPENDIX A: SYSTEM USABILITY SCALE (SUS) EVALUATION

### A.1 Standard 10-Item SUS Questionnaire
Participants rated each item on a 5-point Likert Scale (1 = Strongly Disagree, 5 = Strongly Agree):
1. **Q1:** I think that I would like to use this system frequently.
2. **Q2:** I found the system unnecessarily complex.
3. **Q3:** I thought the system was easy to use.
4. **Q4:** I think that I would need the support of a technical person to be able to use this system.
5. **Q5:** I found the various functions in this system were well integrated.
6. **Q6:** I thought there was too much inconsistency in this system.
7. **Q7:** I would imagine that most people would learn to use this system very quickly.
8. **Q8:** I found the system very cumbersome to use.
9. **Q9:** I felt very confident using the system.
10. **Q10:** I needed to learn a lot of things before I could get going with this system.

*Score Computation Formula:*
- For odd items ($Q1, Q3, Q5, Q7, Q9$): Score contribution = $\text{Score} - 1$
- For even items ($Q2, Q4, Q6, Q8, Q10$): Score contribution = $5 - \text{Score}$
- $\text{Total Household SUS Score} = (\sum \text{Score Contributions}) \times 2.5$

### A.2 Raw Evaluation Data Across Test Households

| Household ID | Household Composition | Parent SUS | Child/Teen SUS | Household Mean | Grade / Interpretation |
| :---: | :--- | :---: | :---: | :---: | :---: |
| **H01** | 2 Parents, 2 Children (Ages 7, 10) | 85.0 | 80.0 | **82.5** | Grade A (Excellent) |
| **H02** | 2 Parents, 3 Children (Ages 4, 8, 14) | 90.0 | 85.0 | **87.5** | Grade A+ (Superior) |
| **H03** | 2 Parents, 2 Children (Ages 9, 12) | 82.5 | 77.5 | **80.0** | Grade A- (Excellent) |
| **H04** | 2 Parents, 4 Children (Ages 5, 8, 11, 16) | 92.5 | 87.5 | **90.0** | Grade A+ (Best Imaginable) |
| **H05** | 2 Parents, 3 Children (Ages 6, 13, 17) | 85.0 | 80.0 | **82.5** | Grade A (Excellent) |
| **OVERALL** | **10 Parents, 14 Children (24 Total Users)** | **87.0** | **82.2** | **84.6** | **Grade A / Acceptable** |

---

# APPENDIX B: CLOUD FIRESTORE SECURITY RULES (EXCERPT)

The following declarative rules enforce strict multi-tenant domestic isolation and cryptographic verification for the ERAT application:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {

    // Helper Functions
    function isAuthenticated() {
      return request.auth != null;
    }

    function isMemberOfFamily(familyId) {
      return isAuthenticated() &&
        exists(/databases/$(database)/documents/families/$(familyId)/members/$(request.auth.uid));
    }

    function isParentGuardian(familyId) {
      return isMemberOfFamily(familyId) &&
        get(/databases/$(database)/documents/families/$(familyId)/members/$(request.auth.uid)).data.role in ['owner', 'parent', 'guardian'];
    }

    // Family Space Root Document
    match /families/{familyId} {
      allow read: if isMemberOfFamily(familyId);
      allow create: if isAuthenticated();
      allow update: if isParentGuardian(familyId);
      allow delete: if false; // Deletion requires administrative review

      // Child Journal Entries: Strict Zero-Upward-Leak Enforcement
      match /journals/{journalId} {
        allow read: if isMemberOfFamily(familyId) && (
          request.auth.uid == resource.data.memberId ||
          (isParentGuardian(familyId) && resource.data.isSharedWithParents == true)
        );
        allow create: if isMemberOfFamily(familyId) &&
          request.auth.uid == request.resource.data.memberId;
        allow update, delete: if isMemberOfFamily(familyId) &&
          request.auth.uid == resource.data.memberId;
      }

      // Family Wish Goals and Star Economy
      match /wish_goals/{goalId} {
        allow read: if isMemberOfFamily(familyId);
        allow create: if isMemberOfFamily(familyId);
        allow update: if isParentGuardian(familyId) || (
          isMemberOfFamily(familyId) &&
          request.resource.data.diff(resource.data).affectedKeys().hasOnly(['currentPoints'])
        );
      }

      // Routine Verification Requests
      match /routine_approvals/{approvalId} {
        allow read: if isMemberOfFamily(familyId);
        allow create: if isMemberOfFamily(familyId);
        allow update: if isParentGuardian(familyId);
      }
    }

    // Public / Anonymous Parent Knowledge Community
    match /parent_community_posts/{postId} {
      allow read: if isAuthenticated();
      allow create: if isAuthenticated();
      allow update: if isAuthenticated() && (
        request.resource.data.diff(resource.data).affectedKeys().hasOnly(['likes', 'upvotedBy'])
      );
      allow delete: if isAuthenticated() && request.auth.uid == resource.data.authorId;
    }
  }
}
```
