#!/usr/bin/env python3
import re
import uuid

# Read the project file
project_path = "HoguMeter.xcodeproj/project.pbxproj"
with open(project_path, 'r') as f:
    content = f.read()

# Create a new Components group ID for RegionFare
regionfare_components_group_id = str(uuid.uuid4()).replace('-', '').upper()[:24]
print(f"New RegionFare Components group ID: {regionfare_components_group_id}")

# File UUIDs for RegionFare components
regionfare_component_files = {
    "ADB716A0A1F84630A677B9E8": "FareInputField.swift",
    "73F39646ECAC42FCB08E64F9": "TimePickerField.swift",
    "4C81A295E43547E1BF7D23A3": "RegionFareRowView.swift"
}

# 1. Remove RegionFare component files from the main Components group
components_group_pattern = r'(4D7A588F46822B6EE0C4C4CE /\* Components \*/ = \{[^}]*?children = \([^)]*?)(ADB716A0A1F84630A677B9E8 /\* FareInputField\.swift \*/,\s*73F39646ECAC42FCB08E64F9 /\* TimePickerField\.swift \*/,\s*4C81A295E43547E1BF7D23A3 /\* RegionFareRowView\.swift \*/,\);)'
match = re.search(components_group_pattern, content, re.DOTALL)
if match:
    # Remove the RegionFare files from Components group
    new_components = match.group(1) + ");"
    content = content.replace(match.group(0), new_components)
    print("✓ Removed RegionFare component files from main Components group")

# 2. Create new Components group definition for RegionFare
regionfare_components_def = f'''\t{regionfare_components_group_id} /* Components */ = {{
\t\tisa = PBXGroup;
\t\tchildren = (
\t\t\tADB716A0A1F84630A677B9E8 /* FareInputField.swift */,
\t\t\t73F39646ECAC42FCB08E64F9 /* TimePickerField.swift */,
\t\t\t4C81A295E43547E1BF7D23A3 /* RegionFareRowView.swift */,
\t\t);
\t\tpath = Components;
\t\tsourceTree = "<group>";
\t}};
'''

# Insert after RegionFare group definition
regionfare_def_pattern = r'(A764A5FB348A4CF08B97CE65 /\* RegionFare \*/ = \{[^}]*?\};)'
regionfare_match = re.search(regionfare_def_pattern, content, re.DOTALL)
if regionfare_match:
    insert_pos = regionfare_match.end()
    content = content[:insert_pos] + "\n" + regionfare_components_def + content[insert_pos:]
    print("✓ Created new Components group for RegionFare")

# 3. Add new Components group to RegionFare's children
regionfare_children_pattern = r'(A764A5FB348A4CF08B97CE65 /\* RegionFare \*/ = \{[^}]*?children = \([^)]*?)'
regionfare_children_match = re.search(regionfare_children_pattern, content, re.DOTALL)
if regionfare_children_match:
    children_section = regionfare_children_match.group(1)
    new_children = children_section + f"\n\t\t\t{regionfare_components_group_id} /* Components */,"
    content = content.replace(children_section, new_children)
    print("✓ Added new Components group to RegionFare")

# Write the updated content
with open(project_path, 'w') as f:
    f.write(content)

print("\n✅ Successfully fixed Components group structure!")
