#!/usr/bin/env python3
"""
ERAT FYP MUST-Compliant DOCX Generator
Converts ERAT_FYP_Full_Documentation.md into a fully formatted Word document (.docx)
adhering to MUST (Malaysia University of Science and Technology) thesis formatting guidelines:
- Times New Roman 12 pt
- Single line spacing within paragraphs, double line spacing (12 pt after) between paragraphs
- Left margin 3.8 cm (for binding), Right/Top/Bottom 2.5 cm
- Footer page numbers centered 1.25 cm from bottom
- Bold table titles at top-left
- Bold figure titles at bottom-left
- High-res diagrams embedded directly from docs/figures/
"""

import os
import re
import docx
from docx.shared import Inches, Pt, RGBColor, Cm
from docx.enum.text import WD_ALIGN_PARAGRAPH
from docx.enum.table import WD_TABLE_ALIGNMENT, WD_ALIGN_VERTICAL
from docx.oxml import OxmlElement, parse_xml
from docx.oxml.ns import nsdecls, qn

DOC_MD_PATH = "ERAT_FYP_Full_Documentation.md"
OUTPUT_DOCX_PATH = "ERAT_Final_Year_Project_Report.docx"
FIGURES_DIR = "docs/figures"

def set_cell_margins(cell, top=100, bottom=100, left=150, right=150):
    tcPr = cell._tc.get_or_add_tcPr()
    tcMar = OxmlElement('w:tcMar')
    for m, val in [('w:top', top), ('w:bottom', bottom), ('w:left', left), ('w:right', right)]:
        node = OxmlElement(m)
        node.set(qn('w:w'), str(val))
        node.set(qn('w:type'), 'dxa')
        tcMar.append(node)
    tcPr.append(tcMar)

def set_cell_shading(cell, color_hex):
    shading_elm = parse_xml(f'<w:shd {nsdecls("w")} w:fill="{color_hex}"/>')
    cell._tc.get_or_add_tcPr().append(shading_elm)

def add_page_number_to_section(section):
    footer = section.footer
    p = footer.paragraphs[0]
    p.alignment = WD_ALIGN_PARAGRAPH.CENTER
    p.paragraph_format.space_before = Pt(0)
    p.paragraph_format.space_after = Pt(0)
    run = p.add_run()
    run.font.name = "Times New Roman"
    run.font.size = Pt(10)
    fldSimple = OxmlElement('w:fldSimple')
    fldSimple.set(qn('w:instr'), 'PAGE')
    run._r.append(fldSimple)

def main():
    if not os.path.exists(DOC_MD_PATH):
        print(f"Error: {DOC_MD_PATH} not found.")
        return

    with open(DOC_MD_PATH, "r", encoding="utf-8") as f:
        md_text = f.read()

    doc = docx.Document()

    # 1. Page Margins & Dimensions (MUST: Left 3.8 cm, Top/Bottom/Right 2.5 cm)
    section = doc.sections[0]
    section.left_margin = Cm(3.8)
    section.right_margin = Cm(2.5)
    section.top_margin = Cm(2.5)
    section.bottom_margin = Cm(2.5)
    section.footer_distance = Cm(1.25)
    add_page_number_to_section(section)

    # Base Styles
    normal_style = doc.styles['Normal']
    normal_style.font.name = 'Times New Roman'
    normal_style.font.size = Pt(12)
    normal_style.font.color.rgb = RGBColor(0, 0, 0)
    normal_style.paragraph_format.line_spacing = 1.0
    normal_style.paragraph_format.space_after = Pt(10)

    # Split markdown into lines
    lines = md_text.splitlines()

    i = 0
    in_code_block = False
    code_lines = []
    in_table = False
    table_lines = []
    table_caption = None

    while i < len(lines):
        line = lines[i]

        # Code block handling
        if line.strip().startswith("```"):
            if in_code_block:
                in_code_block = False
                code_text = "\n".join(code_lines)
                tbl = doc.add_table(rows=1, cols=1)
                tbl.alignment = WD_TABLE_ALIGNMENT.CENTER
                cell = tbl.cell(0, 0)
                set_cell_shading(cell, "F8F9FA")
                set_cell_margins(cell, top=120, bottom=120, left=180, right=180)
                cp = cell.paragraphs[0]
                cp.paragraph_format.line_spacing = 1.0
                cp.paragraph_format.space_after = Pt(2)
                crun = cp.add_run(code_text)
                crun.font.name = "Consolas"
                crun.font.size = Pt(9.5)
                crun.font.color.rgb = RGBColor(40, 40, 40)
                doc.add_paragraph().paragraph_format.space_after = Pt(4)
                code_lines = []
            else:
                in_code_block = True
                code_lines = []
            i += 1
            continue

        if in_code_block:
            code_lines.append(line)
            i += 1
            continue

        # Markdown Table Detection
        if "|" in line and ("---" in line or (i + 1 < len(lines) and "---" in lines[i+1])):
            table_lines = [line]
            i += 1
            while i < len(lines) and "|" in lines[i]:
                table_lines.append(lines[i])
                i += 1
            
            # Render Table
            rows_data = []
            for tl in table_lines:
                if re.match(r'^\s*\|?\s*:?-+:?\s*\|', tl):
                    continue # Skip separator line
                cols = [c.strip() for c in tl.strip().strip('|').split('|')]
                if cols and any(cols):
                    rows_data.append(cols)
            
            if rows_data:
                num_cols = max(len(r) for r in rows_data)
                tbl = doc.add_table(rows=len(rows_data), cols=num_cols)
                tbl.alignment = WD_TABLE_ALIGNMENT.CENTER
                for r_idx, r_data in enumerate(rows_data):
                    for c_idx in range(num_cols):
                        val = r_data[c_idx] if c_idx < len(r_data) else ""
                        cell = tbl.cell(r_idx, c_idx)
                        set_cell_margins(cell, top=90, bottom=90, left=120, right=120)
                        p = cell.paragraphs[0]
                        p.paragraph_format.line_spacing = 1.0
                        p.paragraph_format.space_after = Pt(0)
                        
                        # Clean inline markdown
                        clean_val = re.sub(r'\*\*(.*?)\*\*', r'\1', val)
                        clean_val = re.sub(r'\*(.*?)\*', r'\1', clean_val)
                        clean_val = clean_val.replace('<br>', '\n')
                        
                        run = p.add_run(clean_val)
                        run.font.name = 'Times New Roman'
                        run.font.size = Pt(10)
                        
                        if r_idx == 0:
                            set_cell_shading(cell, "EAEAEA")
                            run.font.bold = True
                doc.add_paragraph().paragraph_format.space_after = Pt(6)
            continue

        stripped = line.strip()

        # Page breaks
        if stripped == "---":
            doc.add_page_break()
            i += 1
            continue

        # Headers
        if stripped.startswith("# CHAPTER") or stripped.startswith("# REFERENCES") or stripped.startswith("# APPENDIX"):
            title = stripped.lstrip('#').strip()
            p = doc.add_paragraph()
            p.alignment = WD_ALIGN_PARAGRAPH.CENTER
            p.paragraph_format.space_before = Pt(18)
            p.paragraph_format.space_after = Pt(14)
            run = p.add_run(title.upper())
            run.font.name = 'Times New Roman'
            run.font.size = Pt(14)
            run.font.bold = True
            i += 1
            continue

        if stripped.startswith("### "):
            title = stripped.replace("### ", "").strip()
            p = doc.add_paragraph()
            p.paragraph_format.space_before = Pt(14)
            p.paragraph_format.space_after = Pt(6)
            run = p.add_run(title)
            run.font.name = 'Times New Roman'
            run.font.size = Pt(13)
            run.font.bold = True
            i += 1
            continue

        if stripped.startswith("#### "):
            title = stripped.replace("#### ", "").strip()
            p = doc.add_paragraph()
            p.paragraph_format.space_before = Pt(10)
            p.paragraph_format.space_after = Pt(4)
            run = p.add_run(title)
            run.font.name = 'Times New Roman'
            run.font.size = Pt(12)
            run.font.bold = True
            i += 1
            continue

        # Table Caption (Bold Top-Left)
        if stripped.startswith('<p align="left"><strong>Table ') or stripped.startswith('**Table '):
            caption_text = re.sub(r'<.*?>', '', stripped).strip('*')
            p = doc.add_paragraph()
            p.paragraph_format.space_before = Pt(12)
            p.paragraph_format.space_after = Pt(4)
            run = p.add_run(caption_text)
            run.font.name = 'Times New Roman'
            run.font.size = Pt(11.5)
            run.font.bold = True
            i += 1
            continue

        # Image Tag Detection
        if '<img src="' in stripped:
            match = re.search(r'src="([^"]+)"', stripped)
            if match:
                img_rel_path = match.group(1).lstrip('./')
                if os.path.exists(img_rel_path):
                    p_img = doc.add_paragraph()
                    p_img.alignment = WD_ALIGN_PARAGRAPH.CENTER
                    p_img.paragraph_format.space_before = Pt(10)
                    p_img.paragraph_format.space_after = Pt(4)
                    run_img = p_img.add_run()
                    # Scale based on width
                    run_img.add_picture(img_rel_path, width=Inches(5.8))
            i += 1
            continue

        # Figure Caption (Bold Bottom-Left)
        if stripped.startswith('<p align="left"><strong>Figure ') or stripped.startswith('**Figure '):
            caption_text = re.sub(r'<.*?>', '', stripped).strip('*')
            p = doc.add_paragraph()
            p.paragraph_format.space_before = Pt(4)
            p.paragraph_format.space_after = Pt(14)
            run = p.add_run(caption_text)
            run.font.name = 'Times New Roman'
            run.font.size = Pt(11.5)
            run.font.bold = True
            i += 1
            continue

        # Screenshot Placeholders (Figures 4.7 to 4.11)
        if "> 🖼️ **[IMAGE PLACEHOLDER:" in stripped:
            box_text = stripped.lstrip('> ').strip()
            tbl = doc.add_table(rows=1, cols=1)
            tbl.alignment = WD_TABLE_ALIGNMENT.CENTER
            cell = tbl.cell(0, 0)
            set_cell_shading(cell, "FFF9F5")
            set_cell_margins(cell, top=200, bottom=200, left=240, right=240)
            p_box = cell.paragraphs[0]
            p_box.alignment = WD_ALIGN_PARAGRAPH.CENTER
            r_box = p_box.add_run(f"\n[ SCREENSHOT PLACEHOLDER ]\n{box_text}\n(Paste or Drop Screenshot Here)\n")
            r_box.font.name = 'Times New Roman'
            r_box.font.size = Pt(11)
            r_box.font.bold = True
            r_box.font.color.rgb = RGBColor(140, 80, 50)
            doc.add_paragraph().paragraph_format.space_after = Pt(4)
            i += 1
            continue

        # Standard Paragraphs
        if stripped:
            clean_p = re.sub(r'\*\*(.*?)\*\*', r'\1', stripped)
            clean_p = re.sub(r'\*(.*?)\*', r'\1', clean_p)
            clean_p = clean_p.replace('&le;', '≤').replace('&ge;', '≥')
            
            p = doc.add_paragraph()
            p.paragraph_format.line_spacing = 1.0
            p.paragraph_format.space_after = Pt(10)
            
            # Bullet items
            if stripped.startswith("- ") or stripped.startswith("* "):
                p.paragraph_format.left_indent = Inches(0.25)
                run = p.add_run("• " + clean_p[2:])
            else:
                run = p.add_run(clean_p)
            
            run.font.name = 'Times New Roman'
            run.font.size = Pt(12)

        i += 1

    doc.save(OUTPUT_DOCX_PATH)
    print(f"Successfully generated MUST-formatted Word document: {OUTPUT_DOCX_PATH}")

if __name__ == "__main__":
    main()
