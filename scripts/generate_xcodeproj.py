#!/usr/bin/env python3
"""Generate LuluMusic.xcodeproj (LoveSong app + LoveSongTests) without Xcode."""

from __future__ import annotations

from pathlib import Path

ROOT = Path("/workspace/LuluMusic")
PROJ = ROOT / "LuluMusic.xcodeproj"


def hid(n: int) -> str:
    return f"7FFC{n:020X}"


FILES = [
    ("", "LuluMusicApp.swift", True),
    ("", "ContentView.swift", True),
    ("Theme", "L10n.swift", True),
    ("Theme", "AppTheme.swift", True),
    ("Theme", "LoveSongTheme.swift", True),
    ("Core", "ImportFormatAllowlist.swift", True),
    ("Core", "PairingAuth.swift", True),
    ("Core", "PlaybackMode.swift", True),
    ("Core", "ResumeState.swift", True),
    ("Core", "LibrarySearch.swift", True),
    ("Core", "DanmakuCore.swift", True),
    ("Core", "WebImportPolicy.swift", True),
    ("Core", "IncomingTransfer.swift", True),
    ("Core", "PlaybackClock.swift", True),
    ("Core", "WaveformPeaks.swift", True),
    ("Models", "ImportSource.swift", True),
    ("Models", "PlaybackItem.swift", True),
    ("Models", "Track.swift", True),
    ("Models", "DanmakuComment.swift", True),
    ("Services", "MetadataExtractor.swift", True),
    ("Services", "AudioSessionController.swift", True),
    ("Services", "LocalIPAddress.swift", True),
    ("Services", "LocalNetworkAccess.swift", True),
    ("Services", "LibraryService.swift", True),
    ("Services", "DanmakuService.swift", True),
    ("Services", "NowPlayingCenter.swift", True),
    ("Services", "PlayerEngine.swift", True),
    ("Services", "WebUploadServer.swift", True),
    ("Services", "AudioWaveformAnalyzer.swift", True),
    ("Representables", "AudioDocumentPicker.swift", True),
    ("Representables", "AppleMusicPicker.swift", True),
    ("Views", "ArtworkView.swift", True),
    ("Views", "CoverPalette.swift", True),
    ("Views", "StageComponents.swift", True),
    ("Views", "PlayerChrome.swift", True),
    ("Views", "MiniPlayerBar.swift", True),
    ("Views", "PlayerView.swift", True),
    ("Views", "LibraryView.swift", True),
    ("Views", "WebUploadView.swift", True),
]

TEST_FILES = [
    "ImportFormatAllowlistTests.swift",
    "PairingCodeTests.swift",
    "PlaybackModeTests.swift",
    "ResumeStateTests.swift",
    "LibrarySearchTests.swift",
    "DanmakuStoreAndSchedulerTests.swift",
    "WebImportPolicyTests.swift",
    "PlaybackClockTests.swift",
    "WaveformPeaksTests.swift",
]

ASSETS = "Assets.xcassets"
PREVIEW = "Preview Content"
PRIVACY = "PrivacyInfo.xcprivacy"
INFO = "Info.plist"
ENTITLEMENTS = "LuluMusic.entitlements"

project_id = hid(1)
target_id = hid(2)
sources_phase = hid(3)
resources_phase = hid(4)
frameworks_phase = hid(5)
target_config_list = hid(6)
project_config_list = hid(7)
debug_target = hid(8)
release_target = hid(9)
debug_project = hid(10)
release_project = hid(11)
main_group = hid(12)
products_group = hid(13)
src_group = hid(14)
product_ref = hid(15)
assets_ref = hid(16)
assets_build = hid(17)
preview_ref = hid(18)
privacy_ref = hid(19)
privacy_build = hid(20)
info_ref = hid(21)
entitlements_ref = hid(22)

test_target = hid(40)
test_product = hid(41)
test_sources = hid(42)
test_frameworks = hid(43)
test_resources = hid(44)
test_config_list = hid(45)
test_debug = hid(46)
test_release = hid(47)
proxy_id = hid(48)
dep_id = hid(49)
tests_group = hid(50)

groups = {
    "Theme": hid(30),
    "Core": hid(35),
    "Models": hid(31),
    "Services": hid(32),
    "Representables": hid(33),
    "Views": hid(34),
}

file_refs = {}
build_files = {}
n = 100
for folder, name, is_source in FILES:
    key = f"{folder}/{name}" if folder else name
    file_refs[key] = hid(n)
    if is_source:
        build_files[key] = hid(n + 500)
    n += 1

test_refs = {}
test_builds = {}
n = 800
for name in TEST_FILES:
    test_refs[name] = hid(n)
    test_builds[name] = hid(n + 100)
    n += 1


def fileref_entry(fid: str, name: str, path: str, ftype: str, extra: str = "") -> str:
    more = f" {extra}" if extra else ""
    return (
        f"\t\t{fid} /* {name} */ = {{isa = PBXFileReference; lastKnownFileType = {ftype}; "
        f"path = {path}; sourceTree = \"<group>\";{more} }};\n"
    )


pbx_build = ""
pbx_build += f"\t\t{assets_build} /* Assets.xcassets in Resources */ = {{isa = PBXBuildFile; fileRef = {assets_ref} /* Assets.xcassets */; }};\n"
pbx_build += f"\t\t{privacy_build} /* PrivacyInfo.xcprivacy in Resources */ = {{isa = PBXBuildFile; fileRef = {privacy_ref} /* PrivacyInfo.xcprivacy */; }};\n"
for folder, name, is_source in FILES:
    key = f"{folder}/{name}" if folder else name
    if is_source:
        pbx_build += (
            f"\t\t{build_files[key]} /* {name} in Sources */ = {{isa = PBXBuildFile; "
            f"fileRef = {file_refs[key]} /* {name} */; }};\n"
        )
for name in TEST_FILES:
    pbx_build += (
        f"\t\t{test_builds[name]} /* {name} in Sources */ = {{isa = PBXBuildFile; "
        f"fileRef = {test_refs[name]} /* {name} */; }};\n"
    )

pbx_file_refs = ""
pbx_file_refs += (
    f"\t\t{product_ref} /* LuluMusic.app */ = {{isa = PBXFileReference; explicitFileType = wrapper.application; "
    f"includeInIndex = 0; path = LuluMusic.app; sourceTree = BUILT_PRODUCTS_DIR; }};\n"
)
pbx_file_refs += (
    f"\t\t{test_product} /* LoveSongTests.xctest */ = {{isa = PBXFileReference; explicitFileType = wrapper.cfbundle; "
    f"includeInIndex = 0; path = LoveSongTests.xctest; sourceTree = BUILT_PRODUCTS_DIR; }};\n"
)
pbx_file_refs += (
    f"\t\t{assets_ref} /* Assets.xcassets */ = {{isa = PBXFileReference; lastKnownFileType = folder.assetcatalog; "
    f"path = Assets.xcassets; sourceTree = \"<group>\"; }};\n"
)
pbx_file_refs += (
    f"\t\t{preview_ref} /* Preview Content */ = {{isa = PBXFileReference; lastKnownFileType = folder; "
    f"path = \"Preview Content\"; sourceTree = \"<group>\"; }};\n"
)
pbx_file_refs += (
    f"\t\t{privacy_ref} /* PrivacyInfo.xcprivacy */ = {{isa = PBXFileReference; lastKnownFileType = text.xml; "
    f"path = PrivacyInfo.xcprivacy; sourceTree = \"<group>\"; }};\n"
)
pbx_file_refs += fileref_entry(info_ref, "Info.plist", "Info.plist", "text.plist.xml")
pbx_file_refs += fileref_entry(entitlements_ref, "LuluMusic.entitlements", "LuluMusic.entitlements", "text.plist.entitlements")
for folder, name, _ in FILES:
    key = f"{folder}/{name}" if folder else name
    pbx_file_refs += fileref_entry(file_refs[key], name, name, "sourcecode.swift")
for name in TEST_FILES:
    pbx_file_refs += fileref_entry(test_refs[name], name, name, "sourcecode.swift")


def group_children(folder: str) -> str:
    items = []
    for f, name, _ in FILES:
        if f == folder:
            key = f"{folder}/{name}" if folder else name
            items.append(f"\t\t\t\t{file_refs[key]} /* {name} */,\n")
    return "".join(items)


root_children = ""
root_children += f"\t\t\t\t{info_ref} /* Info.plist */,\n"
root_children += f"\t\t\t\t{entitlements_ref} /* LuluMusic.entitlements */,\n"
root_children += f"\t\t\t\t{privacy_ref} /* PrivacyInfo.xcprivacy */,\n"
root_children += f"\t\t\t\t{assets_ref} /* Assets.xcassets */,\n"
root_children += f"\t\t\t\t{preview_ref} /* Preview Content */,\n"
for name in ("Theme", "Core", "Models", "Services", "Representables", "Views"):
    root_children += f"\t\t\t\t{groups[name]} /* {name} */,\n"
root_children += group_children("")

test_children = "".join(f"\t\t\t\t{test_refs[name]} /* {name} */,\n" for name in TEST_FILES)

pbx_groups = f"""
		{main_group} = {{
			isa = PBXGroup;
			children = (
				{src_group} /* LuluMusic */,
				{tests_group} /* LoveSongTests */,
				{products_group} /* Products */,
			);
			sourceTree = "<group>";
		}};
		{products_group} /* Products */ = {{
			isa = PBXGroup;
			children = (
				{product_ref} /* LuluMusic.app */,
				{test_product} /* LoveSongTests.xctest */,
			);
			name = Products;
			sourceTree = "<group>";
		}};
		{src_group} /* LuluMusic */ = {{
			isa = PBXGroup;
			children = (
{root_children}			);
			path = LuluMusic;
			sourceTree = "<group>";
		}};
		{tests_group} /* LoveSongTests */ = {{
			isa = PBXGroup;
			children = (
{test_children}			);
			path = LoveSongTests;
			sourceTree = "<group>";
		}};
"""

for name, gid in groups.items():
    pbx_groups += f"""		{gid} /* {name} */ = {{
			isa = PBXGroup;
			children = (
{group_children(name)}			);
			path = {name};
			sourceTree = "<group>";
		}};
"""

source_list = "".join(
    f"\t\t\t\t{build_files[f'{folder}/{name}' if folder else name]} /* {name} in Sources */,\n"
    for folder, name, is_source in FILES
    if is_source
)
test_source_list = "".join(
    f"\t\t\t\t{test_builds[name]} /* {name} in Sources */,\n" for name in TEST_FILES
)

common_target_settings = """
				ASSETCATALOG_COMPILER_APPICON_NAME = AppIcon;
				ASSETCATALOG_COMPILER_GLOBAL_ACCENT_COLOR_NAME = AccentColor;
				CODE_SIGN_ENTITLEMENTS = LuluMusic/LuluMusic.entitlements;
				CODE_SIGN_STYLE = Automatic;
				CURRENT_PROJECT_VERSION = 1;
				DEVELOPMENT_ASSET_PATHS = "\\"LuluMusic/Preview Content\\"";
				ENABLE_PREVIEWS = YES;
				GENERATE_INFOPLIST_FILE = YES;
				INFOPLIST_FILE = LuluMusic/Info.plist;
				INFOPLIST_KEY_CFBundleDisplayName = LoveSong;
				INFOPLIST_KEY_LSApplicationCategoryType = "public.app-category.music";
				INFOPLIST_KEY_UIApplicationSupportsIndirectInputEvents = YES;
				IPHONEOS_DEPLOYMENT_TARGET = 17.0;
				LD_RUNPATH_SEARCH_PATHS = (
					"$(inherited)",
					"@executable_path/Frameworks",
				);
				MARKETING_VERSION = 1.0;
				PRODUCT_BUNDLE_IDENTIFIER = com.lulumusic.app;
				PRODUCT_NAME = "$(TARGET_NAME)";
				SDKROOT = iphoneos;
				SUPPORTED_PLATFORMS = "iphoneos iphonesimulator";
				SUPPORTS_MACCATALYST = NO;
				SUPPORTS_MAC_DESIGNED_FOR_IPHONE_IPAD = NO;
				SUPPORTS_XR_DESIGNED_FOR_IPHONE_IPAD = NO;
				SWIFT_EMIT_LOC_STRINGS = YES;
				SWIFT_VERSION = 5.0;
				TARGETED_DEVICE_FAMILY = 1;
"""

test_settings = """
				BUNDLE_LOADER = "$(TEST_HOST)";
				CODE_SIGN_STYLE = Automatic;
				CURRENT_PROJECT_VERSION = 1;
				GENERATE_INFOPLIST_FILE = YES;
				IPHONEOS_DEPLOYMENT_TARGET = 17.0;
				MARKETING_VERSION = 1.0;
				PRODUCT_BUNDLE_IDENTIFIER = com.lulumusic.tests;
				PRODUCT_NAME = "$(TARGET_NAME)";
				SDKROOT = iphoneos;
				SUPPORTED_PLATFORMS = "iphoneos iphonesimulator";
				SWIFT_EMIT_LOC_STRINGS = NO;
				SWIFT_VERSION = 5.0;
				TARGETED_DEVICE_FAMILY = 1;
				TEST_HOST = "$(BUILT_PRODUCTS_DIR)/LuluMusic.app/$(BUNDLE_EXECUTABLE_FOLDER_PATH)/LuluMusic";
"""

project_debug = """
				ALWAYS_SEARCH_USER_PATHS = NO;
				CLANG_ENABLE_MODULES = YES;
				CLANG_ENABLE_OBJC_ARC = YES;
				COPY_PHASE_STRIP = NO;
				DEBUG_INFORMATION_FORMAT = dwarf;
				ENABLE_STRICT_OBJC_MSGSEND = YES;
				ENABLE_TESTABILITY = YES;
				ENABLE_USER_SCRIPT_SANDBOXING = YES;
				GCC_DYNAMIC_NO_PIC = NO;
				GCC_OPTIMIZATION_LEVEL = 0;
				GCC_PREPROCESSOR_DEFINITIONS = (
					"DEBUG=1",
					"$(inherited)",
				);
				IPHONEOS_DEPLOYMENT_TARGET = 17.0;
				ONLY_ACTIVE_ARCH = YES;
				SDKROOT = iphoneos;
				SWIFT_ACTIVE_COMPILATION_CONDITIONS = "DEBUG $(inherited)";
				SWIFT_OPTIMIZATION_LEVEL = "-Onone";
				SWIFT_VERSION = 5.0;
"""

project_release = """
				ALWAYS_SEARCH_USER_PATHS = NO;
				CLANG_ENABLE_MODULES = YES;
				CLANG_ENABLE_OBJC_ARC = YES;
				COPY_PHASE_STRIP = NO;
				DEBUG_INFORMATION_FORMAT = "dwarf-with-dsym";
				ENABLE_NS_ASSERTIONS = NO;
				ENABLE_STRICT_OBJC_MSGSEND = YES;
				ENABLE_USER_SCRIPT_SANDBOXING = YES;
				IPHONEOS_DEPLOYMENT_TARGET = 17.0;
				SDKROOT = iphoneos;
				SWIFT_COMPILATION_MODE = wholemodule;
				SWIFT_VERSION = 5.0;
				VALIDATE_PRODUCT = YES;
"""

pbxproj = f"""// !$*UTF8*$!
{{
	archiveVersion = 1;
	classes = {{
	}};
	objectVersion = 56;
	objects = {{

/* Begin PBXBuildFile section */
{pbx_build}/* End PBXBuildFile section */

/* Begin PBXContainerItemProxy section */
		{proxy_id} /* PBXContainerItemProxy */ = {{
			isa = PBXContainerItemProxy;
			containerPortal = {project_id} /* Project object */;
			proxyType = 1;
			remoteGlobalIDString = {target_id};
			remoteInfo = LuluMusic;
		}};
/* End PBXContainerItemProxy section */

/* Begin PBXFileReference section */
{pbx_file_refs}/* End PBXFileReference section */

/* Begin PBXFrameworksBuildPhase section */
		{frameworks_phase} /* Frameworks */ = {{
			isa = PBXFrameworksBuildPhase;
			buildActionMask = 2147483647;
			files = (
			);
			runOnlyForDeploymentPostprocessing = 0;
		}};
		{test_frameworks} /* Frameworks */ = {{
			isa = PBXFrameworksBuildPhase;
			buildActionMask = 2147483647;
			files = (
			);
			runOnlyForDeploymentPostprocessing = 0;
		}};
/* End PBXFrameworksBuildPhase section */

/* Begin PBXGroup section */
{pbx_groups}/* End PBXGroup section */

/* Begin PBXNativeTarget section */
		{target_id} /* LuluMusic */ = {{
			isa = PBXNativeTarget;
			buildConfigurationList = {target_config_list} /* Build configuration list for PBXNativeTarget "LuluMusic" */;
			buildPhases = (
				{sources_phase} /* Sources */,
				{frameworks_phase} /* Frameworks */,
				{resources_phase} /* Resources */,
			);
			buildRules = (
			);
			dependencies = (
			);
			name = LuluMusic;
			productName = LuluMusic;
			productReference = {product_ref} /* LuluMusic.app */;
			productType = "com.apple.product-type.application";
		}};
		{test_target} /* LoveSongTests */ = {{
			isa = PBXNativeTarget;
			buildConfigurationList = {test_config_list} /* Build configuration list for PBXNativeTarget "LoveSongTests" */;
			buildPhases = (
				{test_sources} /* Sources */,
				{test_frameworks} /* Frameworks */,
				{test_resources} /* Resources */,
			);
			buildRules = (
			);
			dependencies = (
				{dep_id} /* PBXTargetDependency */,
			);
			name = LoveSongTests;
			productName = LoveSongTests;
			productReference = {test_product} /* LoveSongTests.xctest */;
			productType = "com.apple.product-type.bundle.unit-test";
		}};
/* End PBXNativeTarget section */

/* Begin PBXProject section */
		{project_id} /* Project object */ = {{
			isa = PBXProject;
			attributes = {{
				BuildIndependentTargetsInParallel = 1;
				LastSwiftUpdateCheck = 1540;
				LastUpgradeCheck = 1540;
				TargetAttributes = {{
					{target_id} = {{
						CreatedOnToolsVersion = 15.4;
					}};
					{test_target} = {{
						CreatedOnToolsVersion = 15.4;
						TestTargetID = {target_id};
					}};
				}};
			}};
			buildConfigurationList = {project_config_list} /* Build configuration list for PBXProject "LuluMusic" */;
			compatibilityVersion = "Xcode 14.0";
			developmentRegion = "zh-Hans";
			hasScannedForEncodings = 0;
			knownRegions = (
				en,
				"zh-Hans",
				Base,
			);
			mainGroup = {main_group};
			productRefGroup = {products_group} /* Products */;
			projectDirPath = "";
			projectRoot = "";
			targets = (
				{target_id} /* LuluMusic */,
				{test_target} /* LoveSongTests */,
			);
		}};
/* End PBXProject section */

/* Begin PBXResourcesBuildPhase section */
		{resources_phase} /* Resources */ = {{
			isa = PBXResourcesBuildPhase;
			buildActionMask = 2147483647;
			files = (
				{assets_build} /* Assets.xcassets in Resources */,
				{privacy_build} /* PrivacyInfo.xcprivacy in Resources */,
			);
			runOnlyForDeploymentPostprocessing = 0;
		}};
		{test_resources} /* Resources */ = {{
			isa = PBXResourcesBuildPhase;
			buildActionMask = 2147483647;
			files = (
			);
			runOnlyForDeploymentPostprocessing = 0;
		}};
/* End PBXResourcesBuildPhase section */

/* Begin PBXSourcesBuildPhase section */
		{sources_phase} /* Sources */ = {{
			isa = PBXSourcesBuildPhase;
			buildActionMask = 2147483647;
			files = (
{source_list}			);
			runOnlyForDeploymentPostprocessing = 0;
		}};
		{test_sources} /* Sources */ = {{
			isa = PBXSourcesBuildPhase;
			buildActionMask = 2147483647;
			files = (
{test_source_list}			);
			runOnlyForDeploymentPostprocessing = 0;
		}};
/* End PBXSourcesBuildPhase section */

/* Begin PBXTargetDependency section */
		{dep_id} /* PBXTargetDependency */ = {{
			isa = PBXTargetDependency;
			target = {target_id} /* LuluMusic */;
			targetProxy = {proxy_id} /* PBXContainerItemProxy */;
		}};
/* End PBXTargetDependency section */

/* Begin XCBuildConfiguration section */
		{debug_project} /* Debug */ = {{
			isa = XCBuildConfiguration;
			buildSettings = {{{project_debug}			}};
			name = Debug;
		}};
		{release_project} /* Release */ = {{
			isa = XCBuildConfiguration;
			buildSettings = {{{project_release}			}};
			name = Release;
		}};
		{debug_target} /* Debug */ = {{
			isa = XCBuildConfiguration;
			buildSettings = {{{common_target_settings}			}};
			name = Debug;
		}};
		{release_target} /* Release */ = {{
			isa = XCBuildConfiguration;
			buildSettings = {{{common_target_settings}			}};
			name = Release;
		}};
		{test_debug} /* Debug */ = {{
			isa = XCBuildConfiguration;
			buildSettings = {{{test_settings}			}};
			name = Debug;
		}};
		{test_release} /* Release */ = {{
			isa = XCBuildConfiguration;
			buildSettings = {{{test_settings}			}};
			name = Release;
		}};
/* End XCBuildConfiguration section */

/* Begin XCConfigurationList section */
		{project_config_list} /* Build configuration list for PBXProject "LuluMusic" */ = {{
			isa = XCConfigurationList;
			buildConfigurations = (
				{debug_project} /* Debug */,
				{release_project} /* Release */,
			);
			defaultConfigurationIsVisible = 0;
			defaultConfigurationName = Release;
		}};
		{target_config_list} /* Build configuration list for PBXNativeTarget "LuluMusic" */ = {{
			isa = XCConfigurationList;
			buildConfigurations = (
				{debug_target} /* Debug */,
				{release_target} /* Release */,
			);
			defaultConfigurationIsVisible = 0;
			defaultConfigurationName = Release;
		}};
		{test_config_list} /* Build configuration list for PBXNativeTarget "LoveSongTests" */ = {{
			isa = XCConfigurationList;
			buildConfigurations = (
				{test_debug} /* Debug */,
				{test_release} /* Release */,
			);
			defaultConfigurationIsVisible = 0;
			defaultConfigurationName = Release;
		}};
/* End XCConfigurationList section */
	}};
	rootObject = {project_id} /* Project object */;
}}
"""

scheme = f"""<?xml version="1.0" encoding="UTF-8"?>
<Scheme
   LastUpgradeVersion = "1540"
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
               BuildableName = "LuluMusic.app"
               BlueprintName = "LuluMusic"
               ReferencedContainer = "container:LuluMusic.xcodeproj">
            </BuildableReference>
         </BuildActionEntry>
      </BuildActionEntries>
   </BuildAction>
   <TestAction
      buildConfiguration = "Debug"
      selectedDebuggerIdentifier = "Xcode.DebuggerFoundation.Debugger.LLDB"
      selectedLauncherIdentifier = "Xcode.DebuggerFoundation.Launcher.LLDB"
      shouldUseLaunchSchemeArgsEnv = "YES"
      shouldAutocreateTestPlan = "YES">
      <Testables>
         <TestableReference
            skipped = "NO"
            parallelizable = "YES">
            <BuildableReference
               BuildableIdentifier = "primary"
               BlueprintIdentifier = "{test_target}"
               BuildableName = "LoveSongTests.xctest"
               BlueprintName = "LoveSongTests"
               ReferencedContainer = "container:LuluMusic.xcodeproj">
            </BuildableReference>
         </TestableReference>
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
            BuildableName = "LuluMusic.app"
            BlueprintName = "LuluMusic"
            ReferencedContainer = "container:LuluMusic.xcodeproj">
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
            BuildableName = "LuluMusic.app"
            BlueprintName = "LuluMusic"
            ReferencedContainer = "container:LuluMusic.xcodeproj">
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
"""

workspace = """<?xml version="1.0" encoding="UTF-8"?>
<Workspace
   version = "1.0">
   <FileRef
      location = "self:">
   </FileRef>
</Workspace>
"""

workspace_settings = """<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>IDEWorkspaceSharedSettings_AutocreateContextsIfNeeded</key>
	<false/>
</dict>
</plist>
"""


def main() -> None:
    missing = []
    for folder, name, _ in FILES:
        path = ROOT / "LuluMusic" / folder / name if folder else ROOT / "LuluMusic" / name
        if not path.exists():
            missing.append(str(path))
    for name in TEST_FILES:
        path = ROOT / "LoveSongTests" / name
        if not path.exists():
            missing.append(str(path))
    extra = [
        ROOT / "LuluMusic" / ASSETS,
        ROOT / "LuluMusic" / PREVIEW,
        ROOT / "LuluMusic" / PRIVACY,
        ROOT / "LuluMusic" / INFO,
        ROOT / "LuluMusic" / ENTITLEMENTS,
    ]
    for path in extra:
        if not path.exists():
            missing.append(str(path))
    if missing:
        raise SystemExit("Missing files:\\n" + "\\n".join(missing))

    (PROJ / "project.pbxproj").write_text(pbxproj, encoding="utf-8")
    scheme_dir = PROJ / "xcshareddata" / "xcschemes"
    scheme_dir.mkdir(parents=True, exist_ok=True)
    (scheme_dir / "LoveSong.xcscheme").write_text(scheme, encoding="utf-8")
    (scheme_dir / "LuluMusic.xcscheme").write_text(scheme, encoding="utf-8")
    ws = PROJ / "project.xcworkspace"
    ws.mkdir(parents=True, exist_ok=True)
    (ws / "contents.xcworkspacedata").write_text(workspace, encoding="utf-8")
    (ws / "xcshareddata").mkdir(parents=True, exist_ok=True)
    (ws / "xcshareddata" / "IDEWorkspaceChecks.plist").write_text(workspace_settings, encoding="utf-8")
    print("Wrote", PROJ / "project.pbxproj")
    print("App sources:", len(FILES), "tests:", len(TEST_FILES))


if __name__ == "__main__":
    main()
