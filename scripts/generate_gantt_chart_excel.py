#!/usr/bin/env python3
"""
ERAT Final Year Project — 14-Week Agile Development Gantt Chart Generator
Creates a publication-grade, professionally styled Microsoft Excel spreadsheet (.xlsx)
for Figure 1.1: Project Timeline and Sprint Milestones Gantt Chart.
"""

import os
import openpyxl
from openpyxl.styles import Font, PatternFill, Alignment, Border, Side
from openpyxl.utils import get_column_letter

OUTPUT_PATH = "docs/ERAT_Project_Timeline_Gantt_Chart.xlsx"

def create_gantt_chart():
    wb = openpyxl.Workbook()
    ws = wb.active
    ws.title = "Gantt Chart (14 Weeks)"

    # Ensure grid lines are visible
    ws.views.sheetView[0].showGridLines = True

    # Color Palette
    PRIMARY_COLOR = "4A2E2B"      # Deep Mocha/Burgundy (ERAT Theme)
    ACCENT_COLOR = "8D6E63"       # Warm Mocha
    PHASE_FILL = "F2EAE6"         # Light Blush Tint
    BAR_COLOR = "5C768D"          # Slate Teal for Gantt Bars
    MILESTONE_BAR = "D97724"      # Amber Orange for Milestones
    ZEBRA_FILL = "FAF7F5"         # Very subtle warm background
    HEADER_TEXT = "FFFFFF"

    # Border definitions
    thin_border_side = Side(style='thin', color='D3C5BC')
    grid_border = Border(left=thin_border_side, right=thin_border_side, top=thin_border_side, bottom=thin_border_side)
    thick_bottom_side = Side(style='medium', color='4A2E2B')
    header_border = Border(left=thin_border_side, right=thin_border_side, top=thin_border_side, bottom=thick_bottom_side)

    # 1. Project Title Block
    ws.merge_cells("A1:T1")
    title_cell = ws["A1"]
    title_cell.value = "ERAT: A Gamified Mobile Application for Family Bonding and Habit Formation"
    title_cell.font = Font(name="Calibri", size=14, bold=True, color=HEADER_TEXT)
    title_cell.fill = PatternFill(start_color=PRIMARY_COLOR, end_color=PRIMARY_COLOR, fill_type="solid")
    title_cell.alignment = Alignment(horizontal="center", vertical="center")
    ws.row_dimensions[1].height = 32

    ws.merge_cells("A2:T2")
    sub_cell = ws["A2"]
    sub_cell.value = "FIGURE 1.1: PROJECT TIMELINE & AGILE SPRINT MILESTONES GANTT CHART (14-WEEK ACADEMIC SCHEDULE)"
    sub_cell.font = Font(name="Calibri", size=10, bold=True, color="D7CCC8")
    sub_cell.fill = PatternFill(start_color=PRIMARY_COLOR, end_color=PRIMARY_COLOR, fill_type="solid")
    sub_cell.alignment = Alignment(horizontal="center", vertical="center")
    ws.row_dimensions[2].height = 20

    ws.merge_cells("A3:T3")
    meta_cell = ws["A3"]
    meta_cell.value = "Author: Khadijah Binti Kasiran (ID: B24070074)  |  Supervisor: Ms Nurulaini  |  Degree: B.Sc. in IT (MUST)  |  Dates: 15 Aug 2026 – 21 Nov 2026"
    meta_cell.font = Font(name="Calibri", size=9.5, italic=True, color="5D4037")
    meta_cell.fill = PatternFill(start_color="EFEBE9", end_color="EFEBE9", fill_type="solid")
    meta_cell.alignment = Alignment(horizontal="center", vertical="center")
    ws.row_dimensions[3].height = 22

    # Blank Row 4
    ws.row_dimensions[4].height = 8

    # 2. Table Headers (Row 5 & 6)
    headers = [
        ("WBS", 6),
        ("Project Phase / Activity Description", 38),
        ("Primary Deliverable / Artifact", 28),
        ("Start Date", 12),
        ("End Date", 12),
        ("Duration", 10),
    ]

    for col_idx, (h_name, width) in enumerate(headers, 1):
        col_letter = get_column_letter(col_idx)
        ws.column_dimensions[col_letter].width = width
        ws.merge_cells(start_row=5, start_column=col_idx, end_row=6, end_column=col_idx)
        cell = ws.cell(row=5, column=col_idx)
        cell.value = h_name
        cell.font = Font(name="Calibri", size=10, bold=True, color=HEADER_TEXT)
        cell.fill = PatternFill(start_color=PRIMARY_COLOR, end_color=PRIMARY_COLOR, fill_type="solid")
        cell.alignment = Alignment(horizontal="center", vertical="center", wrap_text=True)
        cell.border = header_border
        ws.cell(row=6, column=col_idx).border = header_border

    # Weeks 1 to 14 Headers
    week_dates = [
        "15/8 - 21/8", "22/8 - 28/8", "29/8 - 04/9",
        "05/9 - 11/9", "12/9 - 18/9", "19/9 - 25/9",
        "26/9 - 02/10", "03/10 - 09/10", "10/10 - 16/10", "17/10 - 23/10",
        "24/10 - 30/10", "31/10 - 06/11", "07/11 - 13/11", "14/11 - 21/11"
    ]

    for w_idx in range(14):
        col_idx = 7 + w_idx
        col_letter = get_column_letter(col_idx)
        ws.column_dimensions[col_letter].width = 6.5
        
        # Row 5: W1..W14
        top_cell = ws.cell(row=5, column=col_idx)
        top_cell.value = f"W{w_idx+1}"
        top_cell.font = Font(name="Calibri", size=10, bold=True, color=HEADER_TEXT)
        top_cell.fill = PatternFill(start_color=ACCENT_COLOR, end_color=ACCENT_COLOR, fill_type="solid")
        top_cell.alignment = Alignment(horizontal="center", vertical="center")
        top_cell.border = grid_border
        
        # Row 6: Date Range
        bot_cell = ws.cell(row=6, column=col_idx)
        bot_cell.value = week_dates[w_idx]
        bot_cell.font = Font(name="Calibri", size=7.5, bold=False, color=HEADER_TEXT)
        bot_cell.fill = PatternFill(start_color=ACCENT_COLOR, end_color=ACCENT_COLOR, fill_type="solid")
        bot_cell.alignment = Alignment(horizontal="center", vertical="center", wrap_text=True)
        bot_cell.border = header_border

    ws.row_dimensions[5].height = 20
    ws.row_dimensions[6].height = 20

    # 3. Task Rows Data
    # Format: (Type, WBS, Activity, Deliverable, Start, End, Duration, StartWeek, EndWeek, IsMilestone)
    # StartWeek & EndWeek are 1-based (1..14)
    tasks = [
        # Phase 1
        ("PHASE", "1.0", "PHASE 1: PROJECT INITIATION & REQUIREMENTS ELICITATION", "", "", "", "", None, None, False),
        ("TASK", "1.1", "Problem Formulation & Literature Review", "Problem Statement & Lit Review", "15/08/2026", "28/08/2026", "14 days", 1, 2, False),
        ("TASK", "1.2", "Theoretical Foundations (SDT, Technoference, Habit)", "Theoretical Synthesis Matrix", "22/08/2026", "04/09/2026", "14 days", 2, 3, False),
        ("TASK", "1.3", "Empirical Stakeholder Interviews (5 Households)", "Interview Transcripts & Field Notes", "22/08/2026", "04/09/2026", "14 days", 2, 3, False),
        ("TASK", "1.4", "Requirements Engineering (12 FRs & 6 NFRs)", "Traceability Matrix (Tables 3.1 & 3.2)", "29/08/2026", "05/09/2026", "8 days", 3, 3, False),
        ("MILESTONE", "M1", "★ Milestone 1: Requirements & Scope Baseline Sign-off", "Signed Proposal & Scope Matrix", "05/09/2026", "05/09/2026", "—", 3, 3, True),

        # Phase 2
        ("PHASE", "2.0", "PHASE 2: SYSTEM ARCHITECTURE & DOMAIN MODELING", "", "", "", "", None, None, False),
        ("TASK", "2.1", "Clean Architecture 3-Tier Layering Design", "Architecture Diagram (Figure 4.1)", "06/09/2026", "18/09/2026", "13 days", 4, 5, False),
        ("TASK", "2.2", "UML Modeling (Use Case, Activity, Sequence, Class)", "UML Specs & Diagrams (Figs 4.2–4.5)", "06/09/2026", "25/09/2026", "20 days", 4, 6, False),
        ("TASK", "2.3", "Cloud Firestore Multi-Tier Schema & ERD Design", "Firestore ERD (Figure 4.6)", "13/09/2026", "25/09/2026", "13 days", 5, 6, False),
        ("TASK", "2.4", "Zero-Upward-Leak Security Policy Authoring", "Security Rules Draft (firestore.rules)", "13/09/2026", "25/09/2026", "13 days", 5, 6, False),
        ("TASK", "2.5", "High-Fidelity Wireframing & Cozy Theme Tokens", "Figma Interactive Mockups", "19/09/2026", "26/09/2026", "8 days", 6, 6, False),
        ("MILESTONE", "M2", "★ Milestone 2: Technical Architecture & UML Sign-off", "Validated UML & ERD Models", "26/09/2026", "26/09/2026", "—", 6, 6, True),

        # Phase 3
        ("PHASE", "3.0", "PHASE 3: AGILE SPRINT IMPLEMENTATION & CLOUD INTEGRATION", "", "", "", "", None, None, False),
        ("TASK", "3.1", "Sprint 1: Project Setup, Riverpod Architecture & Demo Switcher", "Core Auth & Demo Sandbox Module", "15/08/2026", "05/09/2026", "21 days", 1, 3, False),
        ("TASK", "3.2", "Sprint 2: Daily Routine Timelines & Photo Proof Engine", "Adaptive Routine Engine (FR-04/05)", "06/09/2026", "26/09/2026", "21 days", 4, 6, False),
        ("TASK", "3.3", "Sprint 3: 5-Node Milestone Adventure & Focus Activity Tracker", "Gamified Trail & Wish Goals (FR-06/07)", "27/09/2026", "24/10/2026", "28 days", 7, 10, False),
        ("TASK", "3.4", "Sprint 4: Private Voice Journaling (AAC-LC 64kbps) & Chat", "Zero-Upward-Leak Journal (FR-08/10)", "25/10/2026", "14/11/2026", "21 days", 11, 13, False),
        ("TASK", "3.5", "Sprint 4b: Shared Family Calendar & Dining Prompt Cards", "Collaborative Calendar Hub (FR-11)", "01/11/2026", "14/11/2026", "14 days", 12, 13, False),
        ("TASK", "3.6", "Sprint 4c: Parent Community Knowledge Hub & Moderation", "Peer Community Forum (FR-09)", "07/11/2026", "14/11/2026", "8 days", 13, 13, False),
        ("MILESTONE", "M3", "★ Milestone 3: Full Feature-Complete Prototype Complete", "Working Prototype on Android/iOS", "14/11/2026", "14/11/2026", "—", 13, 13, True),

        # Phase 4
        ("PHASE", "4.0", "PHASE 4: TESTING, VERIFICATION & EMPIRICAL EVALUATION", "", "", "", "", None, None, False),
        ("TASK", "4.1", "Automated Unit Testing (AgeBand & Progress Clamping)", "10/10 Passing Unit/Widget Tests", "25/10/2026", "14/11/2026", "21 days", 11, 13, False),
        ("TASK", "4.2", "Static Code Analysis & Strict Linting (flutter analyze)", "0 Errors, 0 Warnings Compliance", "07/11/2026", "21/11/2026", "14 days", 13, 14, False),
        ("TASK", "4.3", "Real-Time Cloud Integration Test Execution (TC-01 to TC-08)", "Integration Matrix Table 5.2 (100% Pass)", "07/11/2026", "21/11/2026", "14 days", 13, 14, False),
        ("TASK", "4.4", "User Acceptance Testing & SUS Evaluation (24 Participants)", "SUS Survey Dataset (Mean 84.5, Grade A+)", "15/11/2026", "21/11/2026", "7 days", 14, 14, False),
        ("MILESTONE", "M4", "★ Milestone 4: Verification & Usability Sign-off (SUS 84.5)", "Empirical Evaluation Approval", "21/11/2026", "21/11/2026", "—", 14, 14, True),

        # Phase 5
        ("PHASE", "5.0", "PHASE 5: DOCUMENTATION, POLISH & FINAL SUBMISSION", "", "", "", "", None, None, False),
        ("TASK", "5.1", "Drafting Chapters 1–3 (Intro, Literature, Methodology)", "Preliminary Chapters Draft", "25/10/2026", "07/11/2026", "14 days", 11, 12, False),
        ("TASK", "5.2", "Drafting Chapter 4 (Design & Implementation Architecture)", "Chapter 4 Complete Draft", "01/11/2026", "14/11/2026", "14 days", 12, 13, False),
        ("TASK", "5.3", "Drafting Chapter 5 & 6 (Testing, Evaluation, Conclusion)", "Chapters 5 & 6 Final Draft", "15/11/2026", "21/11/2026", "7 days", 14, 14, False),
        ("TASK", "5.4", "Academic Formatting, APA 7th References & Word/PDF Polish", "MUST-Compliant Thesis Report", "15/11/2026", "21/11/2026", "7 days", 14, 14, False),
        ("MILESTONE", "M5", "★ Milestone 5: Final FYP Report & Source Code Submission", "Final Hardcover & GitHub Repository", "21/11/2026", "21/11/2026", "—", 14, 14, True),
    ]

    current_row = 7
    for row_data in tasks:
        r_type, wbs, act, deliv, start, end, dur, s_wk, e_wk, is_milestone = row_data
        ws.row_dimensions[current_row].height = 20

        if r_type == "PHASE":
            # Merge Phase title across columns A to F
            ws.merge_cells(start_row=current_row, start_column=1, end_row=current_row, end_column=6)
            p_cell = ws.cell(row=current_row, column=1)
            p_cell.value = f"{wbs}  {act}"
            p_cell.font = Font(name="Calibri", size=10, bold=True, color=PRIMARY_COLOR)
            p_cell.fill = PatternFill(start_color=PHASE_FILL, end_color=PHASE_FILL, fill_type="solid")
            p_cell.alignment = Alignment(horizontal="left", vertical="center", indent=1)
            for c in range(1, 7):
                ws.cell(row=current_row, column=c).border = grid_border

            # Blank out the week columns for the phase header
            for w in range(14):
                col_c = ws.cell(row=current_row, column=7 + w)
                col_c.fill = PatternFill(start_color=PHASE_FILL, end_color=PHASE_FILL, fill_type="solid")
                col_c.border = grid_border

        else:
            # Regular Task or Milestone
            is_zebra = (current_row % 2 == 0)
            row_fill_color = ZEBRA_FILL if is_zebra else "FFFFFF"

            # Fill columns A to F
            cell_vals = [wbs, act, deliv, start, end, dur]
            for c_idx, val in enumerate(cell_vals, 1):
                cell = ws.cell(row=current_row, column=c_idx)
                cell.value = val
                cell.font = Font(name="Calibri", size=9.5, bold=is_milestone, color="B71C1C" if is_milestone else "212121")
                cell.fill = PatternFill(start_color=row_fill_color, end_color=row_fill_color, fill_type="solid")
                cell.border = grid_border
                
                if c_idx == 1:
                    cell.alignment = Alignment(horizontal="center", vertical="center")
                elif c_idx == 2:
                    cell.alignment = Alignment(horizontal="left", vertical="center", indent=1 if not is_milestone else 0)
                elif c_idx in [4, 5, 6]:
                    cell.alignment = Alignment(horizontal="center", vertical="center")
                else:
                    cell.alignment = Alignment(horizontal="left", vertical="center")

            # Fill Gantt Bars in Week columns (7..20)
            for w in range(1, 15):
                col_idx = 6 + w
                bar_cell = ws.cell(row=current_row, column=col_idx)
                bar_cell.border = grid_border
                
                if s_wk and e_wk and (s_wk <= w <= e_wk):
                    if is_milestone:
                        bar_cell.value = "◆"
                        bar_cell.font = Font(name="Calibri", size=12, bold=True, color="FFFFFF")
                        bar_cell.fill = PatternFill(start_color=MILESTONE_BAR, end_color=MILESTONE_BAR, fill_type="solid")
                        bar_cell.alignment = Alignment(horizontal="center", vertical="center")
                    else:
                        bar_cell.value = "■"
                        bar_cell.font = Font(name="Calibri", size=11, bold=True, color="FFFFFF")
                        bar_cell.fill = PatternFill(start_color=BAR_COLOR, end_color=BAR_COLOR, fill_type="solid")
                        bar_cell.alignment = Alignment(horizontal="center", vertical="center")
                else:
                    bar_cell.fill = PatternFill(start_color=row_fill_color, end_color=row_fill_color, fill_type="solid")

        current_row += 1

    # Add Legend at bottom
    current_row += 1
    ws.merge_cells(start_row=current_row, start_column=2, end_row=current_row, end_column=6)
    leg_title = ws.cell(row=current_row, column=2)
    leg_title.value = "Legend / Key:"
    leg_title.font = Font(name="Calibri", size=9.5, bold=True)
    leg_title.alignment = Alignment(horizontal="left", vertical="center")

    # Legend items
    ws.cell(row=current_row, column=7).fill = PatternFill(start_color=BAR_COLOR, end_color=BAR_COLOR, fill_type="solid")
    ws.cell(row=current_row, column=7).value = "■"
    ws.cell(row=current_row, column=7).font = Font(color="FFFFFF", bold=True)
    ws.cell(row=current_row, column=7).alignment = Alignment(horizontal="center", vertical="center")
    ws.merge_cells(start_row=current_row, start_column=8, end_row=current_row, end_column=11)
    ws.cell(row=current_row, column=8).value = "Sprint / Task Activity"
    ws.cell(row=current_row, column=8).font = Font(name="Calibri", size=9)

    ws.cell(row=current_row, column=12).fill = PatternFill(start_color=MILESTONE_BAR, end_color=MILESTONE_BAR, fill_type="solid")
    ws.cell(row=current_row, column=12).value = "◆"
    ws.cell(row=current_row, column=12).font = Font(color="FFFFFF", bold=True)
    ws.cell(row=current_row, column=12).alignment = Alignment(horizontal="center", vertical="center")
    ws.merge_cells(start_row=current_row, start_column=13, end_row=current_row, end_column=16)
    ws.cell(row=current_row, column=13).value = "Key Sprint Milestone (M1–M5)"
    ws.cell(row=current_row, column=13).font = Font(name="Calibri", size=9)

    os.makedirs(os.path.dirname(OUTPUT_PATH), exist_ok=True)
    wb.save(OUTPUT_PATH)
    print(f"Gantt Chart Excel successfully created at: {OUTPUT_PATH}")

if __name__ == "__main__":
    create_gantt_chart()
