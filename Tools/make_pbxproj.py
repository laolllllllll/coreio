#!/usr/bin/env python3
"""Regenerate PayFlowDemo.xcodeproj from the files that currently exist on disk.

    python3 Tools/make_pbxproj.py

The project file is written by hand (no Xcode, no xcodegen needed) so that the
repository stays self contained. Re-run this after adding or removing a source
file and Xcode will see it.
"""

from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
SRC_NAME = "PayFlowDemo"
SRC_DIR = ROOT / SRC_NAME
XCODEPROJ = ROOT / "PayFlowDemo.xcodeproj"
SCHEME_DIR = XCODEPROJ / "xcshareddata" / "xcschemes"

TARGET_NAME = "PayFlowDemo"
BUNDLE_ID = "com.example.paydemo"
DEPLOYMENT_TARGET = "16.0"

_counter = {"value": 0x100000}


def new_id() -> str:
    _counter["value"] += 1
    return f"{_counter['value']:024X}"


def quote(value: str) -> str:
    if value and all(ch.isalnum() or ch in "._/$" for ch in value):
        return value
    return '"' + value.replace("\\", "\\\\").replace('"', '\\"') + '"'


def file_type(name: str) -> str:
    suffix = Path(name).suffix.lower()
    if suffix == ".swift":
        return "sourcecode.swift"
    if suffix == ".xcassets":
        return "folder.assetcatalog"
    if suffix == ".plist":
        return "text.plist.xml"
    if suffix == ".md":
        return "net.daringfireball.markdown"
    if suffix == ".png":
        return "image.png"
    return "file"


class Group:
    def __init__(self, name: str, path: str):
        self.id = new_id()
        self.name = name
        self.path = path
        self.children = []


class FileRef:
    def __init__(self, name: str, path: str, kind: str):
        self.id = new_id()
        self.name = name
        self.path = path
        self.kind = kind
        self.build_id = None


sources = []
resources = []


def walk(directory: Path, group: Group) -> None:
    entries = sorted(directory.iterdir(), key=lambda p: (p.name.lower()))
    for entry in entries:
        if entry.name.startswith("."):
            continue
        if entry.is_dir() and entry.suffix.lower() != ".xcassets":
            child = Group(entry.name, entry.name)
            walk(entry, child)
            group.children.append(child)
            continue

        ref = FileRef(entry.name, entry.name, file_type(entry.name))
        if entry.suffix.lower() == ".swift":
            ref.build_id = new_id()
            sources.append(ref)
        elif entry.suffix.lower() == ".xcassets":
            ref.build_id = new_id()
            resources.append(ref)
        group.children.append(ref)


source_group = Group(SRC_NAME, SRC_NAME)
walk(SRC_DIR, source_group)

products_group = Group("Products", "")
app_ref = FileRef(f"{TARGET_NAME}.app", f"{TARGET_NAME}.app", "wrapper.application")
products_group.children.append(app_ref)

main_group = Group("", "")
main_group.children.extend([source_group, products_group])

target_id = new_id()
project_id = new_id()
sources_phase = new_id()
frameworks_phase = new_id()
resources_phase = new_id()
target_config_list = new_id()
project_config_list = new_id()
target_debug = new_id()
target_release = new_id()
project_debug = new_id()
project_release = new_id()

PROJECT_DEBUG = {
    "ALWAYS_SEARCH_USER_PATHS": "NO",
    "CLANG_ANALYZER_NONNULL": "YES",
    "CLANG_ANALYZER_NUMBER_OBJECT_CONVERSION": "YES_AGGRESSIVE",
    "CLANG_CXX_LANGUAGE_STANDARD": "gnu++20",
    "CLANG_ENABLE_MODULES": "YES",
    "CLANG_ENABLE_OBJC_ARC": "YES",
    "CLANG_ENABLE_OBJC_WEAK": "YES",
    "CLANG_WARN_BLOCK_CAPTURE_AUTORELEASING": "YES",
    "CLANG_WARN_BOOL_CONVERSION": "YES",
    "CLANG_WARN_COMMA": "YES",
    "CLANG_WARN_CONSTANT_CONVERSION": "YES",
    "CLANG_WARN_DEPRECATED_OBJC_IMPLEMENTATIONS": "YES",
    "CLANG_WARN_DIRECT_OBJC_ISA_USAGE": "YES_ERROR",
    "CLANG_WARN_DOCUMENTATION_COMMENTS": "YES",
    "CLANG_WARN_EMPTY_BODY": "YES",
    "CLANG_WARN_ENUM_CONVERSION": "YES",
    "CLANG_WARN_INFINITE_RECURSION": "YES",
    "CLANG_WARN_INT_CONVERSION": "YES",
    "CLANG_WARN_NON_LITERAL_NULL_CONVERSION": "YES",
    "CLANG_WARN_OBJC_IMPLICIT_RETAIN_SELF": "YES",
    "CLANG_WARN_OBJC_LITERAL_CONVERSION": "YES",
    "CLANG_WARN_OBJC_ROOT_CLASS": "YES_ERROR",
    "CLANG_WARN_QUOTED_INCLUDE_IN_FRAMEWORK_HEADER": "YES",
    "CLANG_WARN_RANGE_LOOP_ANALYSIS": "YES",
    "CLANG_WARN_STRICT_PROTOTYPES": "YES",
    "CLANG_WARN_SUSPICIOUS_MOVE": "YES",
    "CLANG_WARN_UNGUARDED_AVAILABILITY": "YES_AGGRESSIVE",
    "CLANG_WARN_UNREACHABLE_CODE": "YES",
    "CLANG_WARN__DUPLICATE_METHOD_MATCH": "YES",
    "COPY_PHASE_STRIP": "NO",
    "DEBUG_INFORMATION_FORMAT": "dwarf",
    "ENABLE_STRICT_OBJC_MSGSEND": "YES",
    "ENABLE_TESTABILITY": "YES",
    "ENABLE_USER_SCRIPT_SANDBOXING": "YES",
    "GCC_C_LANGUAGE_STANDARD": "gnu17",
    "GCC_DYNAMIC_NO_PIC": "NO",
    "GCC_NO_COMMON_BLOCKS": "YES",
    "GCC_OPTIMIZATION_LEVEL": "0",
    "GCC_PREPROCESSOR_DEFINITIONS": '("DEBUG=1", "$(inherited)")',
    "IPHONEOS_DEPLOYMENT_TARGET": DEPLOYMENT_TARGET,
    "MTL_ENABLE_DEBUG_INFO": "INCLUDE_SOURCE",
    "MTL_FAST_MATH": "YES",
    "ONLY_ACTIVE_ARCH": "YES",
    "SDKROOT": "iphoneos",
    "SWIFT_ACTIVE_COMPILATION_CONDITIONS": '"DEBUG $(inherited)"',
    "SWIFT_OPTIMIZATION_LEVEL": '"-Onone"',
    "SWIFT_VERSION": "5.0",
}

PROJECT_RELEASE = {
    "ALWAYS_SEARCH_USER_PATHS": "NO",
    "CLANG_ANALYZER_NONNULL": "YES",
    "CLANG_ANALYZER_NUMBER_OBJECT_CONVERSION": "YES_AGGRESSIVE",
    "CLANG_CXX_LANGUAGE_STANDARD": "gnu++20",
    "CLANG_ENABLE_MODULES": "YES",
    "CLANG_ENABLE_OBJC_ARC": "YES",
    "CLANG_ENABLE_OBJC_WEAK": "YES",
    "CLANG_WARN_BLOCK_CAPTURE_AUTORELEASING": "YES",
    "CLANG_WARN_BOOL_CONVERSION": "YES",
    "CLANG_WARN_COMMA": "YES",
    "CLANG_WARN_CONSTANT_CONVERSION": "YES",
    "CLANG_WARN_DEPRECATED_OBJC_IMPLEMENTATIONS": "YES",
    "CLANG_WARN_DIRECT_OBJC_ISA_USAGE": "YES_ERROR",
    "CLANG_WARN_DOCUMENTATION_COMMENTS": "YES",
    "CLANG_WARN_EMPTY_BODY": "YES",
    "CLANG_WARN_ENUM_CONVERSION": "YES",
    "CLANG_WARN_INFINITE_RECURSION": "YES",
    "CLANG_WARN_INT_CONVERSION": "YES",
    "CLANG_WARN_NON_LITERAL_NULL_CONVERSION": "YES",
    "CLANG_WARN_OBJC_IMPLICIT_RETAIN_SELF": "YES",
    "CLANG_WARN_OBJC_LITERAL_CONVERSION": "YES",
    "CLANG_WARN_OBJC_ROOT_CLASS": "YES_ERROR",
    "CLANG_WARN_QUOTED_INCLUDE_IN_FRAMEWORK_HEADER": "YES",
    "CLANG_WARN_RANGE_LOOP_ANALYSIS": "YES",
    "CLANG_WARN_STRICT_PROTOTYPES": "YES",
    "CLANG_WARN_SUSPICIOUS_MOVE": "YES",
    "CLANG_WARN_UNGUARDED_AVAILABILITY": "YES_AGGRESSIVE",
    "CLANG_WARN_UNREACHABLE_CODE": "YES",
    "CLANG_WARN__DUPLICATE_METHOD_MATCH": "YES",
    "COPY_PHASE_STRIP": "NO",
    "DEBUG_INFORMATION_FORMAT": '"dwarf-with-dsym"',
    "ENABLE_NS_ASSERTIONS": "NO",
    "ENABLE_STRICT_OBJC_MSGSEND": "YES",
    "ENABLE_USER_SCRIPT_SANDBOXING": "YES",
    "GCC_C_LANGUAGE_STANDARD": "gnu17",
    "GCC_NO_COMMON_BLOCKS": "YES",
    "IPHONEOS_DEPLOYMENT_TARGET": DEPLOYMENT_TARGET,
    "MTL_ENABLE_DEBUG_INFO": "NO",
    "MTL_FAST_MATH": "YES",
    "SDKROOT": "iphoneos",
    "SWIFT_COMPILATION_MODE": "wholemodule",
    "SWIFT_OPTIMIZATION_LEVEL": '"-O"',
    "SWIFT_VERSION": "5.0",
    "VALIDATE_PRODUCT": "YES",
}

TARGET_COMMON = {
    "ASSETCATALOG_COMPILER_APPICON_NAME": "AppIcon",
    "ASSETCATALOG_COMPILER_GLOBAL_ACCENT_COLOR_NAME": "AccentColor",
    "CODE_SIGN_STYLE": "Automatic",
    "CURRENT_PROJECT_VERSION": "1",
    "ENABLE_PREVIEWS": "YES",
    "GENERATE_INFOPLIST_FILE": "NO",
    "INFOPLIST_FILE": f"{SRC_NAME}/Info.plist",
    "IPHONEOS_DEPLOYMENT_TARGET": DEPLOYMENT_TARGET,
    "LD_RUNPATH_SEARCH_PATHS": '("$(inherited)", "@executable_path/Frameworks")',
    "MARKETING_VERSION": "1.0",
    "PRODUCT_BUNDLE_IDENTIFIER": BUNDLE_ID,
    "PRODUCT_NAME": '"$(TARGET_NAME)"',
    "SUPPORTED_PLATFORMS": '"iphoneos iphonesimulator"',
    "SWIFT_EMIT_LOC_STRINGS": "YES",
    "SWIFT_VERSION": "5.0",
    "TARGETED_DEVICE_FAMILY": "1",
}


def format_value(value: str) -> str:
    value = value.strip()
    if value.startswith("(") or value.startswith('"'):
        return value
    return quote(value)


def settings_block(settings: dict) -> str:
    lines = ["\t\t\t\tbuildSettings = {"]
    for key in sorted(settings):
        lines.append(f"\t\t\t\t\t{key} = {format_value(settings[key])};")
    lines.append("\t\t\t\t};")
    return "\n".join(lines)


def emit_group(group: Group, depth: int = 0) -> str:
    if group.name:
        comment = f" /* {group.name} */"
        lines = [f"\t\t{group.id}{comment} = {{", "\t\t\tisa = PBXGroup;", "\t\t\tchildren = ("]
    else:
        lines = [f"\t\t{group.id} = {{", "\t\t\tisa = PBXGroup;", "\t\t\tchildren = ("]

    for child in group.children:
        if isinstance(child, Group):
            lines.append(f"\t\t\t\t{child.id} /* {child.name} */,")
        else:
            lines.append(f"\t\t\t\t{child.id} /* {child.name} */,")
    lines.append("\t\t\t);")

    if group.name and group.path:
        lines.append(f"\t\t\tpath = {quote(group.path)};")
    lines.append('\t\t\tsourceTree = "<group>";')
    lines.append("\t\t};")
    return "\n".join(lines)


def emit_file_ref(ref: FileRef) -> str:
    if ref.kind == "wrapper.application":
        return (
            f"\t\t{ref.id} /* {ref.name} */ = {{isa = PBXFileReference; "
            f"explicitFileType = wrapper.application; includeInIndex = 0; "
            f"path = {quote(ref.path)}; sourceTree = BUILT_PRODUCTS_DIR; }};"
        )
    return (
        f"\t\t{ref.id} /* {ref.name} */ = {{isa = PBXFileReference; "
        f"lastKnownFileType = {ref.kind}; path = {quote(ref.path)}; "
        f'sourceTree = "<group>"; }};'
    )


def collect_refs(group: Group):
    refs = []
    for child in group.children:
        if isinstance(child, Group):
            refs.extend(collect_refs(child))
        else:
            refs.append(child)
    return refs


all_refs = collect_refs(source_group) + [app_ref]

parts = []
parts.append("// !$*UTF8*$!")
parts.append("{")
parts.append("\tarchiveVersion = 1;")
parts.append("\tclasses = {")
parts.append("\t};")
parts.append("\tobjectVersion = 56;")
parts.append("\tobjects = {")

# PBXBuildFile
parts.append("\n/* Begin PBXBuildFile section */")
for ref in sources:
    parts.append(
        f"\t\t{ref.build_id} /* {ref.name} in Sources */ = {{isa = PBXBuildFile; "
        f"fileRef = {ref.id} /* {ref.name} */; }};"
    )
for ref in resources:
    parts.append(
        f"\t\t{ref.build_id} /* {ref.name} in Resources */ = {{isa = PBXBuildFile; "
        f"fileRef = {ref.id} /* {ref.name} */; }};"
    )
parts.append("/* End PBXBuildFile section */")

# PBXFileReference
parts.append("\n/* Begin PBXFileReference section */")
for ref in all_refs:
    parts.append(emit_file_ref(ref))
parts.append("/* End PBXFileReference section */")

# PBXFrameworksBuildPhase
parts.append("\n/* Begin PBXFrameworksBuildPhase section */")
parts.append(f"\t\t{frameworks_phase} /* Frameworks */ = {{")
parts.append("\t\t\tisa = PBXFrameworksBuildPhase;")
parts.append("\t\t\tbuildActionMask = 2147483647;")
parts.append("\t\t\tfiles = (")
parts.append("\t\t\t);")
parts.append("\t\t\trunOnlyForDeploymentPostprocessing = 0;")
parts.append("\t\t};")
parts.append("/* End PBXFrameworksBuildPhase section */")

# PBXGroup
parts.append("\n/* Begin PBXGroup section */")
parts.append(emit_group(main_group))
parts.append(emit_group(source_group))
for child in source_group.children:
    if isinstance(child, Group):
        parts.append(emit_group(child))

# nested groups (Views/App/... have files only, but support one more depth)
for child in source_group.children:
    if isinstance(child, Group):
        for sub in child.children:
            if isinstance(sub, Group):
                parts.append(emit_group(sub))

parts.append(emit_group(products_group))
parts.append("/* End PBXGroup section */")

# PBXNativeTarget
parts.append("\n/* Begin PBXNativeTarget section */")
parts.append(f"\t\t{target_id} /* {TARGET_NAME} */ = {{")
parts.append("\t\t\tisa = PBXNativeTarget;")
parts.append(f'\t\t\tbuildConfigurationList = {target_config_list} /* Build configuration list for PBXNativeTarget "{TARGET_NAME}" */;')
parts.append("\t\t\tbuildPhases = (")
parts.append(f"\t\t\t\t{sources_phase} /* Sources */,")
parts.append(f"\t\t\t\t{frameworks_phase} /* Frameworks */,")
parts.append(f"\t\t\t\t{resources_phase} /* Resources */,")
parts.append("\t\t\t);")
parts.append("\t\t\tbuildRules = (")
parts.append("\t\t\t);")
parts.append("\t\t\tdependencies = (")
parts.append("\t\t\t);")
parts.append(f"\t\t\tname = {TARGET_NAME};")
parts.append(f"\t\t\tproductName = {TARGET_NAME};")
parts.append(f"\t\t\tproductReference = {app_ref.id} /* {app_ref.name} */;")
parts.append('\t\t\tproductType = "com.apple.product-type.application";')
parts.append("\t\t};")
parts.append("/* End PBXNativeTarget section */")

# PBXProject
parts.append("\n/* Begin PBXProject section */")
parts.append(f"\t\t{project_id} /* Project object */ = {{")
parts.append("\t\t\tisa = PBXProject;")
parts.append("\t\t\tattributes = {")
parts.append("\t\t\t\tBuildIndependentTargetsInParallel = 1;")
parts.append("\t\t\t\tLastSwiftUpdateCheck = 1500;")
parts.append("\t\t\t\tLastUpgradeCheck = 1500;")
parts.append("\t\t\t\tTargetAttributes = {")
parts.append(f"\t\t\t\t\t{target_id} = {{")
parts.append("\t\t\t\t\t\tCreatedOnToolsVersion = 15.0;")
parts.append("\t\t\t\t\t};")
parts.append("\t\t\t\t};")
parts.append("\t\t\t};")
parts.append(f'\t\t\tbuildConfigurationList = {project_config_list} /* Build configuration list for PBXProject "{TARGET_NAME}" */;')
parts.append('\t\t\tcompatibilityVersion = "Xcode 14.0";')
parts.append("\t\t\tdevelopmentRegion = en;")
parts.append("\t\t\thasScannedForEncodings = 0;")
parts.append("\t\t\tknownRegions = (")
parts.append("\t\t\t\ten,")
parts.append("\t\t\t\tBase,")
parts.append('\t\t\t\t"zh-Hans",')
parts.append("\t\t\t);")
parts.append(f"\t\t\tmainGroup = {main_group.id};")
parts.append(f"\t\t\tproductRefGroup = {products_group.id} /* Products */;")
parts.append('\t\t\tprojectDirPath = "";')
parts.append('\t\t\tprojectRoot = "";')
parts.append("\t\t\ttargets = (")
parts.append(f"\t\t\t\t{target_id} /* {TARGET_NAME} */,")
parts.append("\t\t\t);")
parts.append("\t\t};")
parts.append("/* End PBXProject section */")

# PBXResourcesBuildPhase
parts.append("\n/* Begin PBXResourcesBuildPhase section */")
parts.append(f"\t\t{resources_phase} /* Resources */ = {{")
parts.append("\t\t\tisa = PBXResourcesBuildPhase;")
parts.append("\t\t\tbuildActionMask = 2147483647;")
parts.append("\t\t\tfiles = (")
for ref in resources:
    parts.append(f"\t\t\t\t{ref.build_id} /* {ref.name} in Resources */,")
parts.append("\t\t\t);")
parts.append("\t\t\trunOnlyForDeploymentPostprocessing = 0;")
parts.append("\t\t};")
parts.append("/* End PBXResourcesBuildPhase section */")

# PBXSourcesBuildPhase
parts.append("\n/* Begin PBXSourcesBuildPhase section */")
parts.append(f"\t\t{sources_phase} /* Sources */ = {{")
parts.append("\t\t\tisa = PBXSourcesBuildPhase;")
parts.append("\t\t\tbuildActionMask = 2147483647;")
parts.append("\t\t\tfiles = (")
for ref in sources:
    parts.append(f"\t\t\t\t{ref.build_id} /* {ref.name} in Sources */,")
parts.append("\t\t\t);")
parts.append("\t\t\trunOnlyForDeploymentPostprocessing = 0;")
parts.append("\t\t};")
parts.append("/* End PBXSourcesBuildPhase section */")

# XCBuildConfiguration
parts.append("\n/* Begin XCBuildConfiguration section */")
for name, settings in (("Debug", PROJECT_DEBUG), ("Release", PROJECT_RELEASE)):
    conf_id = project_debug if name == "Debug" else project_release
    parts.append(f"\t\t{conf_id} /* {name} */ = {{")
    parts.append("\t\t\tisa = XCBuildConfiguration;")
    parts.append(settings_block(settings))
    parts.append(f"\t\t\tname = {name};")
    parts.append("\t\t};")
for name in ("Debug", "Release"):
    conf_id = target_debug if name == "Debug" else target_release
    parts.append(f"\t\t{conf_id} /* {name} */ = {{")
    parts.append("\t\t\tisa = XCBuildConfiguration;")
    parts.append(settings_block(TARGET_COMMON))
    parts.append(f"\t\t\tname = {name};")
    parts.append("\t\t};")
parts.append("/* End XCBuildConfiguration section */")

# XCConfigurationList
parts.append("\n/* Begin XCConfigurationList section */")
parts.append(f"\t\t{project_config_list} /* Build configuration list for PBXProject \"{TARGET_NAME}\" */ = {{")
parts.append("\t\t\tisa = XCConfigurationList;")
parts.append("\t\t\tbuildConfigurations = (")
parts.append(f"\t\t\t\t{project_debug} /* Debug */,")
parts.append(f"\t\t\t\t{project_release} /* Release */,")
parts.append("\t\t\t);")
parts.append("\t\t\tdefaultConfigurationIsVisible = 0;")
parts.append("\t\t\tdefaultConfigurationName = Release;")
parts.append("\t\t};")
parts.append(f"\t\t{target_config_list} /* Build configuration list for PBXNativeTarget \"{TARGET_NAME}\" */ = {{")
parts.append("\t\t\tisa = XCConfigurationList;")
parts.append("\t\t\tbuildConfigurations = (")
parts.append(f"\t\t\t\t{target_debug} /* Debug */,")
parts.append(f"\t\t\t\t{target_release} /* Release */,")
parts.append("\t\t\t);")
parts.append("\t\t\tdefaultConfigurationIsVisible = 0;")
parts.append("\t\t\tdefaultConfigurationName = Release;")
parts.append("\t\t};")
parts.append("/* End XCConfigurationList section */")

parts.append("\t};")
parts.append(f"\trootObject = {project_id} /* Project object */;")
parts.append("}")
parts.append("")

XCODEPROJ.mkdir(parents=True, exist_ok=True)
(XCODEPROJ / "project.pbxproj").write_text("\n".join(parts), encoding="utf-8")

SCHEME_DIR.mkdir(parents=True, exist_ok=True)
scheme = f'''<?xml version="1.0" encoding="UTF-8"?>
<Scheme
   LastUpgradeVersion = "1500"
   version = "1.7">
   <BuildAction
      parallelizeBuildables = "YES"
      buildImplicitDependencies = "YES">
      <BuildActionEntries>
         <BuildActionEntry
            buildForTesting = "YES"
            buildForRunning = "YES"
            buildForProfiling = "YES"
            buildForArchiving = "YES"
            buildForAnalyzing = "YES">
            <BuildableReference
               BuildableIdentifier = "primary"
               BlueprintIdentifier = "{target_id}"
               BuildableName = "{TARGET_NAME}.app"
               BlueprintName = "{TARGET_NAME}"
               ReferencedContainer = "container:{XCODEPROJ.name}">
            </BuildableReference>
         </BuildActionEntry>
      </BuildActionEntries>
   </BuildAction>
   <TestAction
      buildConfiguration = "Debug"
      selectedDebuggerIdentifier = "Xcode.DebuggerFoundation.Debugger.LLDB"
      selectedLauncherIdentifier = "Xcode.DebuggerFoundation.Launcher.LLDB"
      shouldUseLaunchSchemeArgsEnv = "YES">
      <Testables>
      </Testables>
   </TestAction>
   <LaunchAction
      buildConfiguration = "Debug"
      selectedDebuggerIdentifier = "Xcode.DebuggerFoundation.Debugger.LLDB"
      selectedLauncherIdentifier = "Xcode.DebuggerFoundation.Launcher.LLDB"
      launchStyle = "0"
      useCustomWorkingDirectory = "NO"
      ignoresPersistentStateOnLaunch = "NO"
      debugDocumentVersioning = "YES"
      debugServiceExtension = "internal"
      allowLocationSimulation = "YES">
      <BuildableProductRunnable
         runnableDebuggingMode = "0">
         <BuildableReference
            BuildableIdentifier = "primary"
            BlueprintIdentifier = "{target_id}"
            BuildableName = "{TARGET_NAME}.app"
            BlueprintName = "{TARGET_NAME}"
            ReferencedContainer = "container:{XCODEPROJ.name}">
         </BuildableReference>
      </BuildableProductRunnable>
   </LaunchAction>
   <ProfileAction
      buildConfiguration = "Release"
      shouldUseLaunchSchemeArgsEnv = "YES"
      savedToolIdentifier = ""
      useCustomWorkingDirectory = "NO"
      debugDocumentVersioning = "YES">
      <BuildableProductRunnable
         runnableDebuggingMode = "0">
         <BuildableReference
            BuildableIdentifier = "primary"
            BlueprintIdentifier = "{target_id}"
            BuildableName = "{TARGET_NAME}.app"
            BlueprintName = "{TARGET_NAME}"
            ReferencedContainer = "container:{XCODEPROJ.name}">
         </BuildableReference>
      </BuildableProductRunnable>
   </ProfileAction>
   <AnalyzeAction
      buildConfiguration = "Debug">
   </AnalyzeAction>
   <ArchiveAction
      buildConfiguration = "Release"
      revealArchiveInOrganizer = "YES">
   </ArchiveAction>
</Scheme>
'''
(SCHEME_DIR / f"{TARGET_NAME}.xcscheme").write_text(scheme, encoding="utf-8")

print(f"Wrote {XCODEPROJ / 'project.pbxproj'}")
print(f"  swift files : {len(sources)}")
print(f"  resources   : {len(resources)}")
print(f"  target id   : {target_id}")
