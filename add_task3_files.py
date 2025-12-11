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
        "name": "DefaultFares.json",
        "path": "HoguMeter/Data/Resources/DefaultFares.json",
        "group": "Resources",
        "is_source": False
    },
    {
        "name": "FareValidation.swift",
        "path": "HoguMeter/Domain/UseCases/FareValidation.swift",
        "group": "UseCases",
        "is_source": True
    },
    {
        "name": "RegionFareViewModel.swift",
        "path": "HoguMeter/Presentation/ViewModels/RegionFareViewModel.swift",
        "group": "ViewModels",
        "is_source": True
    },
    {
        "name": "FareInputField.swift",
        "path": "HoguMeter/Presentation/Views/Settings/RegionFare/Components/FareInputField.swift",
        "group": "Components",
        "is_source": True
    },
    {
        "name": "TimePickerField.swift",
        "path": "HoguMeter/Presentation/Views/Settings/RegionFare/Components/TimePickerField.swift",
        "group": "Components",
        "is_source": True
    },
    {
        "name": "RegionFareRowView.swift",
        "path": "HoguMeter/Presentation/Views/Settings/RegionFare/Components/RegionFareRowView.swift",
        "group": "Components",
        "is_source": True
    },
    {
        "name": "RegionFareListView.swift",
        "path": "HoguMeter/Presentation/Views/Settings/RegionFare/RegionFareListView.swift",
        "group": "RegionFare",
        "is_source": True
    },
    {
        "name": "RegionFareEditView.swift",
        "path": "HoguMeter/Presentation/Views/Settings/RegionFare/RegionFareEditView.swift",
        "group": "RegionFare",
        "is_source": True
    },
    {
        "name": "RegionFareAddView.swift",
        "path": "HoguMeter/Presentation/Views/Settings/RegionFare/RegionFareAddView.swift",
        "group": "RegionFare",
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

print("Generated UUIDs:")
for name, ref_id in file_refs.items():
    print(f"  {name}: {ref_id}")
    if name in build_files:
        print(f"    Build: {build_files[name]}")

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
        path = file_info["path"]
        file_type = "text.json" if name.endswith(".json") else "sourcecode.swift"
        new_entry = f'\t\t{file_refs[name]} /* {name} */ = {{isa = PBXFileReference; lastKnownFileType = {file_type}; path = {name}; sourceTree = "<group>"; }};'
        new_file_refs.append(new_entry)

    updated_ref_section = file_ref_content + "\n" + "\n".join(new_file_refs)
    content = content.replace(file_ref_content, updated_ref_section)
    print("✓ Added PBXFileReference entries")

# Helper function to find and add to a group
def add_to_group(content, group_name, file_entries):
    # Find the group by searching for /* group_name */ = {
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

# Add files to appropriate groups
resources_files = {f["name"]: file_refs[f["name"]] for f in files_to_add if f["group"] == "Resources"}
if resources_files:
    content = add_to_group(content, "Resources", resources_files)

usecases_files = {f["name"]: file_refs[f["name"]] for f in files_to_add if f["group"] == "UseCases"}
if usecases_files:
    content = add_to_group(content, "UseCases", usecases_files)

viewmodels_files = {f["name"]: file_refs[f["name"]] for f in files_to_add if f["group"] == "ViewModels"}
if viewmodels_files:
    content = add_to_group(content, "ViewModels", viewmodels_files)

# For RegionFare Components group
components_files = {f["name"]: file_refs[f["name"]] for f in files_to_add if f["group"] == "Components"}
if components_files:
    content = add_to_group(content, "Components", components_files)

# For RegionFare views
regionfare_files = {f["name"]: file_refs[f["name"]] for f in files_to_add if f["group"] == "RegionFare"}
if regionfare_files:
    content = add_to_group(content, "RegionFare", regionfare_files)

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
