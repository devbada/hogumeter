#!/usr/bin/env python3
import re
import uuid

# Read the project file
project_path = "HoguMeter.xcodeproj/project.pbxproj"
with open(project_path, 'r') as f:
    content = f.read()

# Known file UUIDs from previous run
file_refs = {
    "FareValidation.swift": "C213CAB5415840C487A7EC9C",
    "RegionFareListView.swift": "107C1A3E791C481DA0D3CF03",
    "RegionFareEditView.swift": "F7EBF170FCBB4048B1EF5C8F",
    "RegionFareAddView.swift": "3E4B71F5BFB242D5B2184BFF"
}

# Create group UUIDs
usecases_group_id = str(uuid.uuid4()).replace('-', '').upper()[:24]
regionfare_group_id = str(uuid.uuid4()).replace('-', '').upper()[:24]

print(f"UseCases group ID: {usecases_group_id}")
print(f"RegionFare group ID: {regionfare_group_id}")

# 1. Add UseCases group to Domain
domain_pattern = r'(513BA7EC6CCA7959C4002F6D /\* Domain \*/ = \{[^}]*?children = \([^)]*?)'
domain_match = re.search(domain_pattern, content, re.DOTALL)
if domain_match:
    domain_section = domain_match.group(1)
    new_domain = domain_section + f"\n\t\t\t\t{usecases_group_id} /* UseCases */,"
    content = content.replace(domain_section, new_domain)
    print("✓ Added UseCases to Domain group")

# 2. Create UseCases group definition
# Find where to insert (after Domain definition, before next group)
usecases_def = f'''\t{usecases_group_id} /* UseCases */ = {{
\t\tisa = PBXGroup;
\t\tchildren = (
\t\t\t{file_refs["FareValidation.swift"]} /* FareValidation.swift */,
\t\t);
\t\tpath = UseCases;
\t\tsourceTree = "<group>";
\t}};
'''

# Insert after Domain definition
domain_def_end = re.search(r'(513BA7EC6CCA7959C4002F6D /\* Domain \*/ = \{[^}]*?\};)', content, re.DOTALL)
if domain_def_end:
    insert_pos = domain_def_end.end()
    content = content[:insert_pos] + "\n" + usecases_def + content[insert_pos:]
    print("✓ Created UseCases group definition")

# 3. Add RegionFare group to Settings
settings_pattern = r'(3500C9519EFBE8E7CF847E29 /\* Settings \*/ = \{[^}]*?children = \([^)]*?)'
settings_match = re.search(settings_pattern, content, re.DOTALL)
if settings_match:
    settings_section = settings_match.group(1)
    new_settings = settings_section + f"\n\t\t\t\t{regionfare_group_id} /* RegionFare */,"
    content = content.replace(settings_section, new_settings)
    print("✓ Added RegionFare to Settings group")

# 4. Create RegionFare group definition with Components subgroup
# We need to find the Components group ID first
components_match = re.search(r'([A-F0-9]{24}) /\* Components \*/ = \{[^}]*?children = \(', content, re.DOTALL)
components_group_id = components_match.group(1) if components_match else None

regionfare_def = f'''\t{regionfare_group_id} /* RegionFare */ = {{
\t\tisa = PBXGroup;
\t\tchildren = (
\t\t\t{file_refs["RegionFareListView.swift"]} /* RegionFareListView.swift */,
\t\t\t{file_refs["RegionFareEditView.swift"]} /* RegionFareEditView.swift */,
\t\t\t{file_refs["RegionFareAddView.swift"]} /* RegionFareAddView.swift */,'''

if components_group_id:
    regionfare_def += f"\n\t\t\t{components_group_id} /* Components */,"

regionfare_def += '''
\t\t);
\t\tpath = RegionFare;
\t\tsourceTree = "<group>";
\t}};
'''

# Insert after Settings definition
settings_def_end = re.search(r'(3500C9519EFBE8E7CF847E29 /\* Settings \*/ = \{[^}]*?\};)', content, re.DOTALL)
if settings_def_end:
    insert_pos = settings_def_end.end()
    content = content[:insert_pos] + "\n" + regionfare_def + content[insert_pos:]
    print("✓ Created RegionFare group definition")

# 5. Move Components group to be a child of RegionFare by removing it from its current parent
# First, find where Components is currently referenced
if components_group_id:
    # Remove Components from wherever it currently is (likely in Views or Settings)
    components_ref_pattern = rf'\n\s*{components_group_id} /\* Components \*/,'
    content = re.sub(components_ref_pattern, '', content)
    print("✓ Moved Components group under RegionFare")

# Write the updated content
with open(project_path, 'w') as f:
    f.write(content)

print("\n✅ Successfully fixed group structure!")
