#!/usr/bin/env python3
import re
import uuid

# Read the project file
project_path = "HoguMeter.xcodeproj/project.pbxproj"
with open(project_path, 'r') as f:
    content = f.read()

# Files to add with their groups
files_to_add = [
    {
        "name": "DisclaimerManager.swift",
        "path": "HoguMeter/Core/Managers/DisclaimerManager.swift",
        "group": "Managers",
        "is_source": True
    },
    {
        "name": "DisclaimerText.swift",
        "path": "HoguMeter/Core/Constants/DisclaimerText.swift",
        "group": "Constants",
        "is_source": True
    },
    {
        "name": "DisclaimerViewModel.swift",
        "path": "HoguMeter/Presentation/ViewModels/DisclaimerViewModel.swift",
        "group": "ViewModels",
        "is_source": True
    },
    {
        "name": "DisclaimerDialogView.swift",
        "path": "HoguMeter/Presentation/Views/Onboarding/DisclaimerDialogView.swift",
        "group": "Onboarding",
        "is_source": True
    },
    {
        "name": "AppInfoView.swift",
        "path": "HoguMeter/Presentation/Views/Settings/AppInfo/AppInfoView.swift",
        "group": "AppInfo",
        "is_source": True
    }
]

# Generate UUIDs for new files
file_refs = {}
build_files = {}
for file_info in files_to_add:
    file_refs[file_info["name"]] = str(uuid.uuid4()).replace('-', '').upper()[:24]
    if file_info["is_source"]:
        build_files[file_info["name"]] = str(uuid.uuid4()).replace('-', '').upper()[:24]

# Generate group UUIDs for new groups
onboarding_group_id = str(uuid.uuid4()).replace('-', '').upper()[:24]
appinfo_group_id = str(uuid.uuid4()).replace('-', '').upper()[:24]
managers_group_id = str(uuid.uuid4()).replace('-', '').upper()[:24]
constants_group_id = str(uuid.uuid4()).replace('-', '').upper()[:24]

print("Generated UUIDs:")
for name, ref_id in file_refs.items():
    print(f"  {name}: {ref_id}")
    if name in build_files:
        print(f"    Build: {build_files[name]}")

print(f"\nOnboarding group: {onboarding_group_id}")
print(f"AppInfo group: {appinfo_group_id}")
print(f"Managers group: {managers_group_id}")
print(f"Constants group: {constants_group_id}")

# Find the PBXBuildFile section
build_file_section = re.search(r'/\* Begin PBXBuildFile section \*/\n(.*?)\n/\* End PBXBuildFile section \*/', content, re.DOTALL)
if build_file_section:
    build_file_content = build_file_section.group(1)
    new_build_files = []

    for file_info in files_to_add:
        if file_info["is_source"]:
            name = file_info["name"]
            new_entry = f"\t\t{build_files[name]} /* {name} in Sources */ = {{isa = PBXBuildFile; fileRef = {file_refs[name]} /* {name} */; }};"
            new_build_files.append(new_entry)

    updated_build_section = build_file_content + "\n" + "\n".join(new_build_files)
    content = content.replace(build_file_content, updated_build_section)
    print("\n✓ Added PBXBuildFile entries")

# Find the PBXFileReference section
file_ref_section = re.search(r'/\* Begin PBXFileReference section \*/\n(.*?)\n/\* End PBXFileReference section \*/', content, re.DOTALL)
if file_ref_section:
    file_ref_content = file_ref_section.group(1)
    new_file_refs = []

    for file_info in files_to_add:
        name = file_info["name"]
        new_entry = f'\t\t{file_refs[name]} /* {name} */ = {{isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = {name}; sourceTree = "<group>"; }};'
        new_file_refs.append(new_entry)

    updated_ref_section = file_ref_content + "\n" + "\n".join(new_file_refs)
    content = content.replace(file_ref_content, updated_ref_section)
    print("✓ Added PBXFileReference entries")

# Helper function to find and add to a group
def add_to_group(content, group_name, file_entries):
    pattern = rf'(/\* {re.escape(group_name)} \*/ = {{[^}}]*?children = \([^)]*?)(\);)'
    match = re.search(pattern, content, re.DOTALL)

    if match:
        children_section = match.group(1)
        closing = match.group(2)

        new_children = children_section
        for name, ref_id in file_entries.items():
            entry = f"\n\t\t\t\t{ref_id} /* {name} */,"
            new_children += entry

        new_children += closing
        content = content.replace(match.group(0), new_children)
        print(f"✓ Added to {group_name} group")
    else:
        print(f"⚠ Could not find {group_name} group")

    return content

# Add Managers group to Core
core_pattern = r'(6DFEDA5D62F3D700A0F29910 /\* Core \*/ = \{[^}]*?children = \([^)]*?)'
core_match = re.search(core_pattern, content, re.DOTALL)
if core_match:
    core_section = core_match.group(1)
    new_core = core_section + f"\n\t\t\t\t{managers_group_id} /* Managers */,"
    content = content.replace(core_section, new_core)
    print("✓ Added Managers to Core group")

# Add Constants group to Core
core_pattern = r'(6DFEDA5D62F3D700A0F29910 /\* Core \*/ = \{[^}]*?children = \([^)]*?)'
core_match = re.search(core_pattern, content, re.DOTALL)
if core_match:
    core_section = core_match.group(1)
    new_core = core_section + f"\n\t\t\t\t{constants_group_id} /* Constants */,"
    content = content.replace(core_section, new_core)
    print("✓ Added Constants to Core group")

# Add Onboarding group to Views
views_pattern = r'(5E2DEB05780C5F0FE5E36E09 /\* Views \*/ = \{[^}]*?children = \([^)]*?)'
views_match = re.search(views_pattern, content, re.DOTALL)
if views_match:
    views_section = views_match.group(1)
    new_views = views_section + f"\n\t\t\t\t{onboarding_group_id} /* Onboarding */,"
    content = content.replace(views_section, new_views)
    print("✓ Added Onboarding to Views group")

# Add AppInfo group to Settings
settings_pattern = r'(3500C9519EFBE8E7CF847E29 /\* Settings \*/ = \{[^}]*?children = \([^)]*?)'
settings_match = re.search(settings_pattern, content, re.DOTALL)
if settings_match:
    settings_section = settings_match.group(1)
    new_settings = settings_section + f"\n\t\t\t\t{appinfo_group_id} /* AppInfo */,"
    content = content.replace(settings_section, new_settings)
    print("✓ Added AppInfo to Settings group")

# Create group definitions
managers_def = f'''\t{managers_group_id} /* Managers */ = {{
\t\tisa = PBXGroup;
\t\tchildren = (
\t\t\t{file_refs["DisclaimerManager.swift"]} /* DisclaimerManager.swift */,
\t\t);
\t\tpath = Managers;
\t\tsourceTree = "<group>";
\t}};
'''

constants_def = f'''\t{constants_group_id} /* Constants */ = {{
\t\tisa = PBXGroup;
\t\tchildren = (
\t\t\t{file_refs["DisclaimerText.swift"]} /* DisclaimerText.swift */,
\t\t);
\t\tpath = Constants;
\t\tsourceTree = "<group>";
\t}};
'''

onboarding_def = f'''\t{onboarding_group_id} /* Onboarding */ = {{
\t\tisa = PBXGroup;
\t\tchildren = (
\t\t\t{file_refs["DisclaimerDialogView.swift"]} /* DisclaimerDialogView.swift */,
\t\t);
\t\tpath = Onboarding;
\t\tsourceTree = "<group>";
\t}};
'''

appinfo_def = f'''\t{appinfo_group_id} /* AppInfo */ = {{
\t\tisa = PBXGroup;
\t\tchildren = (
\t\t\t{file_refs["AppInfoView.swift"]} /* AppInfoView.swift */,
\t\t);
\t\tpath = AppInfo;
\t\tsourceTree = "<group>";
\t}};
'''

# Insert group definitions after Core group
core_def_end = re.search(r'(6DFEDA5D62F3D700A0F29910 /\* Core \*/ = \{[^}]*?\};)', content, re.DOTALL)
if core_def_end:
    insert_pos = core_def_end.end()
    content = content[:insert_pos] + "\n" + managers_def + constants_def + content[insert_pos:]
    print("✓ Created Managers and Constants group definitions")

# Insert Onboarding after Views group
views_def_end = re.search(r'(5E2DEB05780C5F0FE5E36E09 /\* Views \*/ = \{[^}]*?\};)', content, re.DOTALL)
if views_def_end:
    insert_pos = views_def_end.end()
    content = content[:insert_pos] + "\n" + onboarding_def + content[insert_pos:]
    print("✓ Created Onboarding group definition")

# Insert AppInfo after Settings group
settings_def_end = re.search(r'(3500C9519EFBE8E7CF847E29 /\* Settings \*/ = \{[^}]*?\};)', content, re.DOTALL)
if settings_def_end:
    insert_pos = settings_def_end.end()
    content = content[:insert_pos] + "\n" + appinfo_def + content[insert_pos:]
    print("✓ Created AppInfo group definition")

# Add DisclaimerViewModel to ViewModels group
viewmodels_files = {"DisclaimerViewModel.swift": file_refs["DisclaimerViewModel.swift"]}
content = add_to_group(content, "ViewModels", viewmodels_files)

# Find the PBXSourcesBuildPhase section and add source files
sources_phase = re.search(r'(/\* Sources \*/ = {[^}]*?files = \([^)]*?)(\);)', content, re.DOTALL)
if sources_phase:
    files_section = sources_phase.group(1)
    closing = sources_phase.group(2)

    new_files_section = files_section
    for file_info in files_to_add:
        if file_info["is_source"]:
            name = file_info["name"]
            entry = f"\n\t\t\t\t{build_files[name]} /* {name} in Sources */,"
            new_files_section += entry

    new_files_section += closing
    content = content.replace(sources_phase.group(0), new_files_section)
    print("✓ Added to PBXSourcesBuildPhase")

# Write the updated content
with open(project_path, 'w') as f:
    f.write(content)

print("\n✅ Successfully updated project.pbxproj!")
print(f"Added {len(files_to_add)} files to the Xcode project.")
