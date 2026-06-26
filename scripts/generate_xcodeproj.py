#!/usr/bin/env python3
"""Generate ROLA.xcodeproj/project.pbxproj"""

import os
import uuid

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))


def gen_id():
    return uuid.uuid4().hex[:24].upper()


swift_files = [
    "ROLA/App/ROLAApp.swift",
    "ROLA/App/AppState.swift",
    "ROLA/App/DependencyContainer.swift",
    "ROLA/Models/AppRoute.swift",
    "ROLA/Models/Conversation.swift",
    "ROLA/Models/ImportedMessage.swift",
    "ROLA/Models/StyleProfile.swift",
    "ROLA/Models/CalendarContext.swift",
    "ROLA/Models/ReplySuggestion.swift",
    "ROLA/Database/ChatDB/ChatDBError.swift",
    "ROLA/Database/ChatDB/AppleDateConverter.swift",
    "ROLA/Database/ChatDB/AttributedBodyDecoder.swift",
    "ROLA/Database/ChatDB/ChatDBReader.swift",
    "ROLA/Database/Local/ConversationStore.swift",
    "ROLA/Database/Local/StyleProfileStore.swift",
    "ROLA/Database/Local/CalendarContextStore.swift",
    "ROLA/Database/Local/SuggestionStore.swift",
    "ROLA/Utilities/Theme.swift",
    "ROLA/Utilities/KeychainHelper.swift",
    "ROLA/Utilities/PermissionStatusMapper.swift",
    "ROLA/Utilities/PermissionRefreshObserver.swift",
    "ROLA/Services/Protocols/ServiceProtocols.swift",
    "ROLA/Services/Mock/MockServices.swift",
    "ROLA/Services/MessageImport/MessageImportService.swift",
    "ROLA/Services/StyleAnalysis/StyleAnalyzer.swift",
    "ROLA/Services/StyleAnalysis/StyleEngine.swift",
    "ROLA/Services/Contacts/ContactsService.swift",
    "ROLA/Services/Calendar/CalendarService.swift",
    "ROLA/Services/Calendar/AvailabilityChecker.swift",
    "ROLA/Services/Notifications/NotificationService.swift",
    "ROLA/AI/Context/SchedulingDetector.swift",
    "ROLA/AI/Context/ContextAssembler.swift",
    "ROLA/AI/OpenAIClient.swift",
    "ROLA/AI/Safety/SafetyClassifier.swift",
    "ROLA/AI/Prompts/PromptBuilder.swift",
    "ROLA/AI/Pipeline/AIPipeline.swift",
    "ROLA/Permissions/FullDiskAccessChecker.swift",
    "ROLA/Permissions/SystemSettingsURLs.swift",
    "ROLA/ViewModels/OnboardingViewModel.swift",
    "ROLA/ViewModels/DashboardViewModel.swift",
    "ROLA/ViewModels/SuggestionViewModel.swift",
    "ROLA/Components/ROLAButton.swift",
    "ROLA/Components/PageIndicator.swift",
    "ROLA/Components/EmptyStateView.swift",
    "ROLA/Components/PermissionCard.swift",
    "ROLA/Components/FullDiskAccessGuideSheet.swift",
    "ROLA/Components/ConversationRow.swift",
    "ROLA/Components/ConversationDetailView.swift",
    "ROLA/Components/StyleProfileCard.swift",
    "ROLA/Components/CalendarViews.swift",
    "ROLA/Components/ConfidenceBadge.swift",
    "ROLA/Components/SuggestionCard.swift",
    "ROLA/Components/ROLALogoMark.swift",
    "ROLA/Views/Onboarding/OnboardingContainerView.swift",
    "ROLA/Views/Onboarding/WelcomeView.swift",
    "ROLA/Views/Onboarding/PrivacyView.swift",
    "ROLA/Views/Onboarding/PermissionsView.swift",
    "ROLA/Views/Dashboard/DashboardView.swift",
    "ROLA/Views/Dashboard/CommunicationProfileView.swift",
    "ROLA/Views/Settings/SettingsView.swift",
]

test_files = ["ROLATests/ROLATests.swift"]

# IDs
project_id = gen_id()
target_id = gen_id()
test_target_id = gen_id()
sources_phase_id = gen_id()
frameworks_phase_id = gen_id()
resources_phase_id = gen_id()
test_sources_phase_id = gen_id()
assets_id = gen_id()
assets_build_id = gen_id()
entitlements_id = gen_id()
product_id = gen_id()
test_product_id = gen_id()
main_group_id = gen_id()
rola_group_id = gen_id()
products_group_id = gen_id()
tests_group_id = gen_id()
config_list_project = gen_id()
config_list_target = gen_id()
config_list_test = gen_id()
debug_project = gen_id()
release_project = gen_id()
debug_target = gen_id()
release_target = gen_id()
debug_test = gen_id()
release_test = gen_id()
test_dep_id = gen_id()
target_proxy_id = gen_id()
container_proxy_id = gen_id()

file_refs = {f: gen_id() for f in swift_files + test_files}
build_files = {f: gen_id() for f in swift_files + test_files}

# Sub-groups
subgroups = {
    "App": gen_id(),
    "Models": gen_id(),
    "Utilities": gen_id(),
    "Services": gen_id(),
    "Protocols": gen_id(),
    "Mock": gen_id(),
    "MessageImport": gen_id(),
    "StyleAnalysis": gen_id(),
    "Database": gen_id(),
    "ChatDB": gen_id(),
    "Local": gen_id(),
    "Context": gen_id(),
    "Pipeline": gen_id(),
    "Prompts": gen_id(),
    "Safety": gen_id(),
    "AI": gen_id(),
    "Contacts": gen_id(),
    "Calendar": gen_id(),
    "Notifications": gen_id(),
    "Permissions": gen_id(),
    "ViewModels": gen_id(),
    "Components": gen_id(),
    "Views": gen_id(),
    "Onboarding": gen_id(),
    "Dashboard": gen_id(),
    "Settings": gen_id(),
}

file_to_subgroup = {
    "ROLA/App/ROLAApp.swift": "App",
    "ROLA/App/AppState.swift": "App",
    "ROLA/App/DependencyContainer.swift": "App",
    "ROLA/Models/AppRoute.swift": "Models",
    "ROLA/Utilities/Theme.swift": "Utilities",
    "ROLA/Utilities/KeychainHelper.swift": "Utilities",
    "ROLA/Services/Protocols/ServiceProtocols.swift": "Protocols",
    "ROLA/Services/Mock/MockServices.swift": "Mock",
    "ROLA/Permissions/PermissionManager.swift": "Permissions",
    "ROLA/ViewModels/OnboardingViewModel.swift": "ViewModels",
    "ROLA/Components/ROLAButton.swift": "Components",
    "ROLA/Components/PageIndicator.swift": "Components",
    "ROLA/Components/EmptyStateView.swift": "Components",
    "ROLA/Components/PermissionCard.swift": "Components",
    "ROLA/Components/ROLALogoMark.swift": "Components",
    "ROLA/Views/Onboarding/OnboardingContainerView.swift": "Onboarding",
    "ROLA/Views/Onboarding/WelcomeView.swift": "Onboarding",
    "ROLA/Views/Onboarding/PrivacyView.swift": "Onboarding",
    "ROLA/Views/Onboarding/PermissionsView.swift": "Onboarding",
    "ROLA/Views/Dashboard/DashboardView.swift": "Dashboard",
    "ROLA/Views/Settings/SettingsView.swift": "Settings",
}

out = []
out.append("// !$*UTF8*$!")
out.append("{")
out.append("\tarchiveVersion = 1;")
out.append("\tclasses = {};")
out.append("\tobjectVersion = 56;")
out.append("\tobjects = {")

# PBXBuildFile
out.append("\n/* Begin PBXBuildFile section */")
for f in swift_files:
    name = os.path.basename(f)
    out.append(f"\t\t{build_files[f]} /* {name} in Sources */ = {{isa = PBXBuildFile; fileRef = {file_refs[f]} /* {name} */; }};")
for f in test_files:
    name = os.path.basename(f)
    out.append(f"\t\t{build_files[f]} /* {name} in Sources */ = {{isa = PBXBuildFile; fileRef = {file_refs[f]} /* {name} */; }};")
out.append(f"\t\t{assets_build_id} /* Assets.xcassets in Resources */ = {{isa = PBXBuildFile; fileRef = {assets_id} /* Assets.xcassets */; }};")
out.append("/* End PBXBuildFile section */")

# PBXContainerItemProxy
out.append("\n/* Begin PBXContainerItemProxy section */")
out.append(f"\t\t{container_proxy_id} /* PBXContainerItemProxy */ = {{")
out.append("\t\t\tisa = PBXContainerItemProxy;")
out.append(f"\t\t\tcontainerPortal = {project_id} /* Project object */;")
out.append("\t\t\tproxyType = 1;")
out.append(f"\t\t\tremoteGlobalIDString = {target_id};")
out.append("\t\t\tremoteInfo = ROLA;")
out.append("\t\t};")
out.append("/* End PBXContainerItemProxy section */")

# PBXFileReference
out.append("\n/* Begin PBXFileReference section */")
for f in swift_files + test_files:
    name = os.path.basename(f)
    out.append(f"\t\t{file_refs[f]} /* {name} */ = {{isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = {name}; sourceTree = \"<group>\"; }};")
out.append(f"\t\t{assets_id} /* Assets.xcassets */ = {{isa = PBXFileReference; lastKnownFileType = folder.assetcatalog; path = Assets.xcassets; sourceTree = \"<group>\"; }};")
out.append(f"\t\t{entitlements_id} /* ROLA.entitlements */ = {{isa = PBXFileReference; lastKnownFileType = text.plist.entitlements; path = ROLA.entitlements; sourceTree = \"<group>\"; }};")
out.append(f"\t\t{product_id} /* ROLA.app */ = {{isa = PBXFileReference; explicitFileType = wrapper.application; includeInIndex = 0; path = ROLA.app; sourceTree = BUILT_PRODUCTS_DIR; }};")
out.append(f"\t\t{test_product_id} /* ROLATests.xctest */ = {{isa = PBXFileReference; explicitFileType = wrapper.cfbundle; includeInIndex = 0; path = ROLATests.xctest; sourceTree = BUILT_PRODUCTS_DIR; }};")
out.append("/* End PBXFileReference section */")

# PBXFrameworksBuildPhase
out.append("\n/* Begin PBXFrameworksBuildPhase section */")
out.append(f"\t\t{frameworks_phase_id} /* Frameworks */ = {{")
out.append("\t\t\tisa = PBXFrameworksBuildPhase;")
out.append("\t\t\tbuildActionMask = 2147483647;")
out.append("\t\t\tfiles = (")
out.append("\t\t\t);")
out.append("\t\t\trunOnlyForDeploymentPostprocessing = 0;")
out.append("\t\t};")
out.append("/* End PBXFrameworksBuildPhase section */")

# PBXGroup helpers
def group_block(gid, name, children, path=None):
    lines = [f"\t\t{gid} /* {name} */ = {{"]
    lines.append("\t\t\tisa = PBXGroup;")
    lines.append("\t\t\tchildren = (")
    for c in children:
        lines.append(f"\t\t\t\t{c},")
    lines.append("\t\t\t);")
    if path:
        lines.append(f"\t\t\tpath = {path};")
    lines.append("\t\t\tsourceTree = \"<group>\";")
    lines.append("\t\t};")
    return lines

out.append("\n/* Begin PBXGroup section */")

# Leaf groups with files
onboarding_children = [file_refs[f] for f in swift_files if "Onboarding" in f]
dashboard_children = [file_refs[f] for f in swift_files if "Dashboard" in f]
settings_children = [file_refs[f] for f in swift_files if "Settings" in f]
app_children = [file_refs[f] for f in swift_files if "/App/" in f]
models_children = [file_refs[f] for f in swift_files if "/Models/" in f]
utils_children = [file_refs[f] for f in swift_files if "/Utilities/" in f]
chatdb_children = [file_refs[f] for f in swift_files if "/Database/ChatDB/" in f]
local_children = [file_refs[f] for f in swift_files if "/Database/Local/" in f]
protocols_children = [file_refs["ROLA/Services/Protocols/ServiceProtocols.swift"]]
mock_children = [file_refs["ROLA/Services/Mock/MockServices.swift"]]
message_import_children = [file_refs["ROLA/Services/MessageImport/MessageImportService.swift"]]
style_analysis_children = [
    file_refs["ROLA/Services/StyleAnalysis/StyleAnalyzer.swift"],
    file_refs["ROLA/Services/StyleAnalysis/StyleEngine.swift"],
]
perms_children = [file_refs[f] for f in swift_files if "/Permissions/" in f]
vm_children = [file_refs[f] for f in swift_files if "/ViewModels/" in f]
comp_children = [file_refs[f] for f in swift_files if "/Components/" in f]

contacts_children = [file_refs["ROLA/Services/Contacts/ContactsService.swift"]]
calendar_children = [
    file_refs["ROLA/Services/Calendar/CalendarService.swift"],
    file_refs["ROLA/Services/Calendar/AvailabilityChecker.swift"],
]
context_children = [
    file_refs["ROLA/AI/Context/SchedulingDetector.swift"],
    file_refs["ROLA/AI/Context/ContextAssembler.swift"],
]
pipeline_children = [file_refs["ROLA/AI/Pipeline/AIPipeline.swift"]]
prompts_children = [file_refs["ROLA/AI/Prompts/PromptBuilder.swift"]]
safety_children = [file_refs["ROLA/AI/Safety/SafetyClassifier.swift"]]
openai_children = [file_refs["ROLA/AI/OpenAIClient.swift"]]
notifications_children = [file_refs["ROLA/Services/Notifications/NotificationService.swift"]]

for name, gid, children, path in [
    ("Contacts", subgroups["Contacts"], contacts_children, "Contacts"),
    ("Calendar", subgroups["Calendar"], calendar_children, "Calendar"),
    ("Notifications", subgroups["Notifications"], notifications_children, "Notifications"),
    ("MessageImport", subgroups["MessageImport"], message_import_children, "MessageImport"),
    ("StyleAnalysis", subgroups["StyleAnalysis"], style_analysis_children, "StyleAnalysis"),
]:
    out.extend(group_block(gid, name, children, path))

for name, gid, children, path in [
    ("Context", subgroups["Context"], context_children, "Context"),
    ("Pipeline", subgroups["Pipeline"], pipeline_children, "Pipeline"),
    ("Prompts", subgroups["Prompts"], prompts_children, "Prompts"),
    ("Safety", subgroups["Safety"], safety_children, "Safety"),
]:
    out.extend(group_block(gid, name, children, path))

ai_leaf_children = openai_children + [
    subgroups["Context"],
    subgroups["Pipeline"],
    subgroups["Prompts"],
    subgroups["Safety"],
]
out.extend(group_block(subgroups["AI"], "AI", ai_leaf_children, "AI"))

for name, gid, children, path in [
    ("ChatDB", subgroups["ChatDB"], chatdb_children, "ChatDB"),
    ("Local", subgroups["Local"], local_children, "Local"),
]:
    out.extend(group_block(gid, name, children, path))

database_children = [subgroups["ChatDB"], subgroups["Local"]]
out.extend(group_block(subgroups["Database"], "Database", database_children, "Database"))

for name, gid, children, path in [
    ("Onboarding", subgroups["Onboarding"], onboarding_children, "Onboarding"),
    ("Dashboard", subgroups["Dashboard"], dashboard_children, "Dashboard"),
    ("Settings", subgroups["Settings"], settings_children, "Settings"),
    ("App", subgroups["App"], app_children, "App"),
    ("Models", subgroups["Models"], models_children, "Models"),
    ("Utilities", subgroups["Utilities"], utils_children, "Utilities"),
    ("Protocols", subgroups["Protocols"], protocols_children, "Protocols"),
    ("Mock", subgroups["Mock"], mock_children, "Mock"),
    ("Permissions", subgroups["Permissions"], perms_children, "Permissions"),
    ("ViewModels", subgroups["ViewModels"], vm_children, "ViewModels"),
    ("Components", subgroups["Components"], comp_children, "Components"),
]:
    out.extend(group_block(gid, name, children, path))

services_children = [
    subgroups["Protocols"],
    subgroups["Mock"],
    subgroups["MessageImport"],
    subgroups["StyleAnalysis"],
    subgroups["Contacts"],
    subgroups["Calendar"],
    subgroups["Notifications"],
]
out.extend(group_block(subgroups["Services"], "Services", services_children, "Services"))

views_children = [subgroups["Onboarding"], subgroups["Dashboard"], subgroups["Settings"]]
out.extend(group_block(subgroups["Views"], "Views", views_children, "Views"))

rola_children = [
    subgroups["App"],
    subgroups["Models"],
    subgroups["Database"],
    subgroups["AI"],
    subgroups["Utilities"],
    subgroups["Services"],
    subgroups["Permissions"],
    subgroups["ViewModels"],
    subgroups["Components"],
    subgroups["Views"],
    assets_id,
    entitlements_id,
]
out.extend(group_block(rola_group_id, "ROLA", rola_children, "ROLA"))

test_children = [file_refs["ROLATests/ROLATests.swift"]]
out.extend(group_block(tests_group_id, "ROLATests", test_children, "ROLATests"))

out.extend(group_block(products_group_id, "Products", [product_id, test_product_id]))

out.extend(group_block(main_group_id, "", [rola_group_id, tests_group_id, products_group_id]))

out.append("/* End PBXGroup section */")

# PBXNativeTarget
out.append("\n/* Begin PBXNativeTarget section */")
out.append(f"\t\t{target_id} /* ROLA */ = {{")
out.append("\t\t\tisa = PBXNativeTarget;")
out.append(f"\t\t\tbuildConfigurationList = {config_list_target} /* Build configuration list for PBXNativeTarget \"ROLA\" */;")
out.append("\t\t\tbuildPhases = (")
out.append(f"\t\t\t\t{sources_phase_id} /* Sources */,")
out.append(f"\t\t\t\t{frameworks_phase_id} /* Frameworks */,")
out.append(f"\t\t\t\t{resources_phase_id} /* Resources */,")
out.append("\t\t\t);")
out.append("\t\t\tbuildRules = (")
out.append("\t\t\t);")
out.append("\t\t\tdependencies = (")
out.append("\t\t\t);")
out.append("\t\t\tname = ROLA;")
out.append(f"\t\t\tproductName = ROLA;")
out.append(f"\t\t\tproductReference = {product_id} /* ROLA.app */;")
out.append("\t\t\tproductType = \"com.apple.product-type.application\";")
out.append("\t\t};")

out.append(f"\t\t{test_target_id} /* ROLATests */ = {{")
out.append("\t\t\tisa = PBXNativeTarget;")
out.append(f"\t\t\tbuildConfigurationList = {config_list_test} /* Build configuration list for PBXNativeTarget \"ROLATests\" */;")
out.append("\t\t\tbuildPhases = (")
out.append(f"\t\t\t\t{test_sources_phase_id} /* Sources */,")
out.append("\t\t\t);")
out.append("\t\t\tbuildRules = (")
out.append("\t\t\t);")
out.append("\t\t\tdependencies = (")
out.append(f"\t\t\t\t{test_dep_id} /* PBXTargetDependency */,")
out.append("\t\t\t);")
out.append("\t\t\tname = ROLATests;")
out.append(f"\t\t\tproductName = ROLATests;")
out.append(f"\t\t\tproductReference = {test_product_id} /* ROLATests.xctest */;")
out.append("\t\t\tproductType = \"com.apple.product-type.bundle.unit-test\";")
out.append("\t\t};")
out.append("/* End PBXNativeTarget section */")

# PBXProject
out.append("\n/* Begin PBXProject section */")
out.append(f"\t\t{project_id} /* Project object */ = {{")
out.append("\t\t\tisa = PBXProject;")
out.append("\t\t\tattributes = {")
out.append("\t\t\t\tBuildIndependentTargetsInParallel = 1;")
out.append("\t\t\t\tLastSwiftUpdateCheck = 1500;")
out.append("\t\t\t\tLastUpgradeCheck = 1500;")
out.append("\t\t\t\tTargetAttributes = {")
out.append(f"\t\t\t\t\t{target_id} = {{")
out.append("\t\t\t\t\t\tCreatedOnToolsVersion = 15.0;")
out.append("\t\t\t\t\t};")
out.append(f"\t\t\t\t\t{test_target_id} = {{")
out.append("\t\t\t\t\t\tCreatedOnToolsVersion = 15.0;")
out.append(f"\t\t\t\t\t\tTestTargetID = {target_id};")
out.append("\t\t\t\t\t};")
out.append("\t\t\t\t};")
out.append("\t\t\t};")
out.append(f"\t\t\tbuildConfigurationList = {config_list_project} /* Build configuration list for PBXProject \"ROLA\" */;")
out.append("\t\t\tcompatibilityVersion = \"Xcode 14.0\";")
out.append("\t\t\tdevelopmentRegion = en;")
out.append("\t\t\thasScannedForEncodings = 0;")
out.append("\t\t\tknownRegions = (")
out.append("\t\t\t\ten,")
out.append("\t\t\t\tBase,")
out.append("\t\t\t);")
out.append(f"\t\t\tmainGroup = {main_group_id};")
out.append(f"\t\t\tproductRefGroup = {products_group_id} /* Products */;")
out.append("\t\t\tprojectDirPath = \"\";")
out.append("\t\t\tprojectRoot = \"\";")
out.append("\t\t\ttargets = (")
out.append(f"\t\t\t\t{target_id} /* ROLA */,")
out.append(f"\t\t\t\t{test_target_id} /* ROLATests */,")
out.append("\t\t\t);")
out.append("\t\t};")
out.append("/* End PBXProject section */")

# PBXResourcesBuildPhase
out.append("\n/* Begin PBXResourcesBuildPhase section */")
out.append(f"\t\t{resources_phase_id} /* Resources */ = {{")
out.append("\t\t\tisa = PBXResourcesBuildPhase;")
out.append("\t\t\tbuildActionMask = 2147483647;")
out.append("\t\t\tfiles = (")
out.append(f"\t\t\t\t{assets_build_id} /* Assets.xcassets in Resources */,")
out.append("\t\t\t);")
out.append("\t\t\trunOnlyForDeploymentPostprocessing = 0;")
out.append("\t\t};")
out.append("/* End PBXResourcesBuildPhase section */")

# PBXSourcesBuildPhase
out.append("\n/* Begin PBXSourcesBuildPhase section */")
out.append(f"\t\t{sources_phase_id} /* Sources */ = {{")
out.append("\t\t\tisa = PBXSourcesBuildPhase;")
out.append("\t\t\tbuildActionMask = 2147483647;")
out.append("\t\t\tfiles = (")
for f in swift_files:
    name = os.path.basename(f)
    out.append(f"\t\t\t\t{build_files[f]} /* {name} in Sources */,")
out.append("\t\t\t);")
out.append("\t\t\trunOnlyForDeploymentPostprocessing = 0;")
out.append("\t\t};")

out.append(f"\t\t{test_sources_phase_id} /* Sources */ = {{")
out.append("\t\t\tisa = PBXSourcesBuildPhase;")
out.append("\t\t\tbuildActionMask = 2147483647;")
out.append("\t\t\tfiles = (")
for f in test_files:
    name = os.path.basename(f)
    out.append(f"\t\t\t\t{build_files[f]} /* {name} in Sources */,")
out.append("\t\t\t);")
out.append("\t\t\trunOnlyForDeploymentPostprocessing = 0;")
out.append("\t\t};")
out.append("/* End PBXSourcesBuildPhase section */")

# PBXTargetDependency
out.append("\n/* Begin PBXTargetDependency section */")
out.append(f"\t\t{test_dep_id} /* PBXTargetDependency */ = {{")
out.append("\t\t\tisa = PBXTargetDependency;")
out.append(f"\t\t\ttarget = {target_id} /* ROLA */;")
out.append(f"\t\t\ttargetProxy = {container_proxy_id} /* PBXContainerItemProxy */;")
out.append("\t\t};")
out.append("/* End PBXTargetDependency section */")

# XCBuildConfiguration
common_debug = [
    "ALWAYS_SEARCH_USER_PATHS = NO;",
    "CLANG_ENABLE_MODULES = YES;",
    "COPY_PHASE_STRIP = NO;",
    "DEBUG_INFORMATION_FORMAT = dwarf;",
    "ENABLE_STRICT_OBJC_MSGSEND = YES;",
    "GCC_DYNAMIC_NO_PIC = NO;",
    "GCC_OPTIMIZATION_LEVEL = 0;",
    "GCC_PREPROCESSOR_DEFINITIONS = (\"DEBUG=1\", \"$(inherited)\",);",
    "MTL_ENABLE_DEBUG_INFO = INCLUDE_SOURCE;",
    "ONLY_ACTIVE_ARCH = YES;",
    "SWIFT_ACTIVE_COMPILATION_CONDITIONS = DEBUG;",
    "SWIFT_OPTIMIZATION_LEVEL = \"-Onone\";",
]
common_release = [
    "ALWAYS_SEARCH_USER_PATHS = NO;",
    "CLANG_ENABLE_MODULES = YES;",
    "COPY_PHASE_STRIP = NO;",
    "DEBUG_INFORMATION_FORMAT = \"dwarf-with-dsym\";",
    "ENABLE_NS_ASSERTIONS = NO;",
    "ENABLE_STRICT_OBJC_MSGSEND = YES;",
    "MTL_ENABLE_DEBUG_INFO = NO;",
    "SWIFT_COMPILATION_MODE = wholemodule;",
]

def config_block(cid, name, settings):
    lines = [f"\t\t{cid} /* {name} */ = {{"]
    lines.append("\t\t\tisa = XCBuildConfiguration;")
    lines.append("\t\t\tbuildSettings = {")
    for s in settings:
        lines.append(f"\t\t\t\t{s}")
    lines.append("\t\t\t};")
    lines.append(f"\t\t\tname = {name};")
    lines.append("\t\t};")
    return lines

out.append("\n/* Begin XCBuildConfiguration section */")

project_debug = common_debug + [
    "MACOSX_DEPLOYMENT_TARGET = 14.0;",
    "SDKROOT = macosx;",
    "SWIFT_VERSION = 6.0;",
]
project_release = common_release + [
    "MACOSX_DEPLOYMENT_TARGET = 14.0;",
    "SDKROOT = macosx;",
    "SWIFT_VERSION = 6.0;",
]
out.extend(config_block(debug_project, "Debug", project_debug))
out.extend(config_block(release_project, "Release", project_release))

target_debug = [
    "ASSETCATALOG_COMPILER_APPICON_NAME = AppIcon;",
    "ASSETCATALOG_COMPILER_GLOBAL_ACCENT_COLOR_NAME = AccentColor;",
    "CODE_SIGN_ENTITLEMENTS = ROLA/ROLA.entitlements;",
    "CODE_SIGN_STYLE = Automatic;",
    "COMBINE_HIDPI_IMAGES = YES;",
    "CURRENT_PROJECT_VERSION = 1;",
    "ENABLE_PREVIEWS = YES;",
    "GENERATE_INFOPLIST_FILE = YES;",
    "INFOPLIST_KEY_CFBundleDisplayName = ROLA;",
    "INFOPLIST_KEY_LSApplicationCategoryType = \"public.app-category.productivity\";",
    "INFOPLIST_KEY_NSHumanReadableCopyright = \"Copyright © 2026 ROLA. All rights reserved.\";",
    "INFOPLIST_KEY_NSContactsUsageDescription = \"ROLA uses your contacts to match messages with people you know.\";",
    "INFOPLIST_KEY_NSCalendarsFullAccessUsageDescription = \"ROLA reads your calendar to suggest replies based on your availability.\";",
    "LD_RUNPATH_SEARCH_PATHS = (\"$(inherited)\", \"@executable_path/../Frameworks\");",
    "MARKETING_VERSION = 0.6.0;",
    "PRODUCT_BUNDLE_IDENTIFIER = com.rola.app;",
    "PRODUCT_NAME = \"$(TARGET_NAME)\";",
    "SWIFT_EMIT_LOC_STRINGS = YES;",
    "SWIFT_VERSION = 6.0;",
    "OTHER_LDFLAGS = (\"$(inherited)\", \"-lsqlite3\");",
]
target_release = target_debug.copy()
out.extend(config_block(debug_target, "Debug", target_debug))
out.extend(config_block(release_target, "Release", target_release))

test_debug = [
    "BUNDLE_LOADER = \"$(TEST_HOST)\";",
    "CODE_SIGN_STYLE = Automatic;",
    "CURRENT_PROJECT_VERSION = 1;",
    "GENERATE_INFOPLIST_FILE = YES;",
    "MARKETING_VERSION = 0.6.0;",
    "PRODUCT_BUNDLE_IDENTIFIER = com.rola.app.tests;",
    "PRODUCT_NAME = \"$(TARGET_NAME)\";",
    "SWIFT_VERSION = 6.0;",
    "TEST_HOST = \"$(BUILT_PRODUCTS_DIR)/ROLA.app/$(BUNDLE_EXECUTABLE_FOLDER_PATH)/ROLA\";",
]
test_release = test_debug.copy()
out.extend(config_block(debug_test, "Debug", test_debug))
out.extend(config_block(release_test, "Release", test_release))

out.append("/* End XCBuildConfiguration section */")

# XCConfigurationList
out.append("\n/* Begin XCConfigurationList section */")
for clid, name, configs in [
    (config_list_project, "Project", [(debug_project, "Debug"), (release_project, "Release")]),
    (config_list_target, "ROLA", [(debug_target, "Debug"), (release_target, "Release")]),
    (config_list_test, "ROLATests", [(debug_test, "Debug"), (release_test, "Release")]),
]:
    out.append(f"\t\t{clid} /* Build configuration list for PBXNativeTarget \"{name}\" */ = {{")
    out.append("\t\t\tisa = XCConfigurationList;")
    out.append("\t\t\tbuildConfigurations = (")
    for cid, cname in configs:
        out.append(f"\t\t\t\t{cid} /* {cname} */,")
    out.append("\t\t\t);")
    out.append("\t\t\tdefaultConfigurationIsVisible = 0;")
    out.append("\t\t\tdefaultConfigurationName = Release;")
    out.append("\t\t};")
out.append("/* End XCConfigurationList section */")

out.append("\t};")
out.append(f"\trootObject = {project_id} /* Project object */;")
out.append("}")

pbxproj_path = os.path.join(ROOT, "ROLA.xcodeproj", "project.pbxproj")
os.makedirs(os.path.dirname(pbxproj_path), exist_ok=True)
with open(pbxproj_path, "w") as f:
    f.write("\n".join(out) + "\n")

print(f"Generated {pbxproj_path}")
