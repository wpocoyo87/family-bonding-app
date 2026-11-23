import base64
import urllib.request
import os
import json
import time

DIAGRAMS = {
    "figure_1_1_gantt_chart": """gantt
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
    Report Writing & Final Polish    :active, p12, 2026-11-10, 2026-11-28""",

    "figure_3_1_agile_scrum": """flowchart TD
    A[Product Backlog Creation] --> B[Sprint Planning: 2-Week Iteration]
    B --> C[Daily Implementation & Test-Driven Development]
    C --> D[Sprint Review: Parent & Child Stakeholder Testing]
    D --> E[Sprint Retrospective & Refactoring]
    E --> F{Backlog Items Remaining?}
    F -- Yes --> B
    F -- No --> G[Final System Integration, Hardening & Deployment]""",

    "figure_4_1_clean_architecture": """flowchart TD
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
    LogicLayer --> DataLayer""",

    "figure_4_2_use_case": """flowchart LR
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
    Child --> UC10""",

    "figure_4_3_activity_diagram": """flowchart TD
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
    UpdateMap --> End([Routine Verification Cycle Complete])""",

    "figure_4_4_sequence_diagram": """sequenceDiagram
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
    Note over UI: Checkpoint unlocks (e.g. 8/20x active -> completed)""",

    "figure_4_5_class_diagram": """classDiagram
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
    FamilySpace "1" *-- "*" FamilyCalendarEvent : organizes""",

    "figure_4_6_firestore_erd": """erDiagram
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
    }"""
}

output_dir = "/Users/wpocoyo87/FYP/docs/figures"
os.makedirs(output_dir, exist_ok=True)

headers = {"User-Agent": "Mozilla/5.0"}

for name, code in DIAGRAMS.items():
    print(f"Rendering {name}...")
    state = json.dumps({"code": code, "mermaid": {"theme": "default"}})
    b64 = base64.urlsafe_b64encode(state.encode('utf-8')).decode('utf-8').rstrip("=")
    
    # Download PNG
    png_url = f"https://mermaid.ink/img/{b64}?bgColor=!white"
    req = urllib.request.Request(png_url, headers=headers)
    try:
        with urllib.request.urlopen(req, timeout=30) as response:
            png_data = response.read()
            with open(os.path.join(output_dir, f"{name}.png"), "wb") as f:
                f.write(png_data)
        print(f"  ✓ Saved {name}.png ({len(png_data)} bytes)")
    except Exception as e:
        print(f"  ✗ Failed PNG for {name}: {e}")
        # Fallback to SVG
        svg_url = f"https://mermaid.ink/svg/{b64}"
        try:
            req_svg = urllib.request.Request(svg_url, headers=headers)
            with urllib.request.urlopen(req_svg, timeout=30) as response:
                svg_data = response.read()
                with open(os.path.join(output_dir, f"{name}.svg"), "wb") as f:
                    f.write(svg_data)
            print(f"  ✓ Saved {name}.svg as fallback ({len(svg_data)} bytes)")
        except Exception as e2:
            print(f"  ✗ Failed SVG for {name}: {e2}")

    time.sleep(0.5)

print("\nDone rendering diagrams!")
