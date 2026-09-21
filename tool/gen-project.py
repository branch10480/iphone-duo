#!/usr/bin/env python3
"""DuoLab.xcodeproj を生成する（sandbox 対応）。

xcodegen は Nix バイナリで temp を /var/folders 固定に使うため、seed の sandbox
（書き込みは cwd 配下のみ）内では失敗する。このスクリプトで pbxproj を直接書く。

    python3 tool/gen-project.py   # リポジトリルートから

pbxproj の UUID は 24 桁 hex（ファイル名などから決定論的に導出）。
再生成: ソース構成を変えたら `rm -rf DuoLab.xcodeproj && python3 tool/gen-project.py`
"""
import hashlib
import os

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SRC = "DuoLab"
FILES = sorted(
    f for f in os.listdir(os.path.join(ROOT, SRC))
    if f.endswith(".swift") and not f.startswith(".")
)


def uid(seed: str) -> str:
    return hashlib.sha256(seed.encode()).hexdigest()[:24].upper()


ID = {k: uid("duolab:" + k) for k in [
    "project", "mainGroup", "srcGroup", "productsGroup",
    "target", "appRef", "sources", "frameworks", "resources",
    "projCL", "targetCL", "projDebug", "projRelease", "targetDebug", "targetRelease",
    "projectYml", "readme",
]}
SRCID = {f: uid("duolab:file:" + f) for f in FILES}
BUILDID = {f: uid("duolab:build:" + f) for f in FILES}

T = "\t"


def cfg(cid: str, name: str, settings_lines: list) -> str:
    s = "\n".join(T * 3 + l for l in settings_lines)
    return (f"\t\t{cid} = {{\n"
            f"\t\t\tisa = XCBuildConfiguration;\n"
            f"\t\t\tname = {name};\n"
            f"\t\t\tbuildSettings = {{\n{s}\n\t\t\t}};\n"
            f"\t\t}};")


PROJ_DEBUG = [
    "ALWAYS_SEARCH_USER_PATHS = NO;",
    "CLANG_ENABLE_OBJC_ARC = YES;",
    "COPY_PHASE_STRIP = NO;",
    'DEBUG_INFORMATION_FORMAT = "dwarf-with-dsym";',
    "ENABLE_STRICT_OBJC_MSGSEND = YES;",
    "ENABLE_TESTABILITY = YES;",
    "GCC_C_LANGUAGE_STANDARD = gnu17;",
    "GCC_DYNAMIC_NO_PIC = NO;",
    "GCC_OPTIMIZATION_LEVEL = 0;",
    'GCC_PREPROCESSOR_DEFINITIONS = ("DEBUG=1","$(inherited)",);',
    "MTL_FAST_MATH = YES;",
    "ONLY_ACTIVE_ARCH = YES;",
    "SDKROOT = iphoneos;",
    'SWIFT_OPTIMIZATION_LEVEL = "-Onone";',
    "SWIFT_VERSION = 5.10;",
]
PROJ_RELEASE = [
    "ALWAYS_SEARCH_USER_PATHS = NO;",
    "CLANG_ENABLE_OBJC_ARC = YES;",
    "COPY_PHASE_STRIP = NO;",
    'DEBUG_INFORMATION_FORMAT = "dwarf-with-dsym";',
    "ENABLE_NS_ASSERTIONS = NO;",
    "ENABLE_STRICT_OBJC_MSGSEND = YES;",
    "GCC_C_LANGUAGE_STANDARD = gnu17;",
    "GCC_OPTIMIZATION_LEVEL = 2;",
    "MTL_FAST_MATH = YES;",
    "SDKROOT = iphoneos;",
    "SWIFT_COMPILATION_MODE = wholemodule;",
    "SWIFT_VERSION = 5.10;",
    "VALIDATE_PRODUCT = YES;",
]
TARGET_SETTINGS = [
    'CODE_SIGN_STYLE = Automatic;',
    'CURRENT_PROJECT_VERSION = 1;',
    'DEVELOPMENT_TEAM = "";',
    "GENERATE_INFOPLIST_FILE = YES;",
    'INFOPLIST_KEY_CFBundleDisplayName = "Duo Lab";',
    "INFOPLIST_KEY_UILaunchScreen_Generation = YES;",
    'INFOPLIST_KEY_UISupportedInterfaceOrientations = "UIInterfaceOrientationPortrait UIInterfaceOrientationLandscapeLeft UIInterfaceOrientationLandscapeRight";',
    'LD_RUNPATH_SEARCH_PATHS = ("$(inherited)","@executable_path/Frameworks",);',
    "MARKETING_VERSION = 0.1.0;",
    "IPHONEOS_DEPLOYMENT_TARGET = 27.1;",
    "PRODUCT_BUNDLE_IDENTIFIER = com.branch10480.duolab;",
    'PRODUCT_NAME = "$(TARGET_NAME)";',
    "SWIFT_EMIT_LOC_STRINGS = YES;",
    "SUPPORTS_MACCATALYST = NO;",
    "TARGETED_DEVICE_FAMILY = 1;",
]

L = []
L.append("// !$*UTF8*$!")
L.append("{")
L.append("\tarchiveVersion = 1;")
L.append("\tclasses = {")
L.append("\t};")
L.append("\tobjectVersion = 77;")
L.append("\tobjects = {")

L.append("")
L.append("/* Begin PBXBuildFile section */")
for f in FILES:
    L.append(f"\t\t{BUILDID[f]} /* {f} in Sources */ = {{isa = PBXBuildFile; fileRef = {SRCID[f]} /* {f} */; }};")
L.append("/* End PBXBuildFile section */")

L.append("")
L.append("/* Begin PBXFileReference section */")
L.append(f"\t\t{ID['appRef']} /* DuoLab.app */ = {{isa = PBXFileReference; explicitFileType = wrapper.application; includeInIndex = 0; path = DuoLab.app; sourceTree = BUILT_PRODUCTS_DIR; }};")
L.append(f"\t\t{ID['projectYml']} /* project.yml */ = {{isa = PBXFileReference; lastKnownFileType = text.yaml; path = project.yml; sourceTree = \"<group>\"; }};")
L.append(f"\t\t{ID['readme']} /* README.md */ = {{isa = PBXFileReference; lastKnownFileType = net.daringfireball.markdown; path = README.md; sourceTree = \"<group>\"; }};")
for f in FILES:
    L.append(f"\t\t{SRCID[f]} /* {f} */ = {{isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = \"{f}\"; sourceTree = \"<group>\"; }};")
L.append("/* End PBXFileReference section */")

L.append("")
L.append("/* Begin PBXFrameworksBuildPhase section */")
L.append(f"\t\t{ID['frameworks']} /* Frameworks */ = {{")
L.append(f"\t\t\tisa = PBXFrameworksBuildPhase;")
L.append(f"\t\t\tbuildActionMask = 2147483647;")
L.append(f"\t\t\tfiles = (")
L.append(f"\t\t\t);")
L.append(f"\t\t\trunOnlyForDeploymentPostprocessing = 0;")
L.append(f"\t\t}};")
L.append("/* End PBXFrameworksBuildPhase section */")

L.append("")
L.append("/* Begin PBXGroup section */")
L.append(f"\t\t{ID['mainGroup']} = {{")
L.append(f"\t\t\tisa = PBXGroup;")
L.append(f"\t\t\tchildren = (")
L.append(f"\t\t\t\t{ID['srcGroup']} /* {SRC} */,")
L.append(f"\t\t\t\t{ID['projectYml']} /* project.yml */,")
L.append(f"\t\t\t\t{ID['readme']} /* README.md */,")
L.append(f"\t\t\t\t{ID['productsGroup']} /* Products */,")
L.append(f"\t\t\t);")
L.append(f"\t\t\tsourceTree = \"<group>\";")
L.append(f"\t\t}};")
L.append(f"\t\t{ID['srcGroup']} /* {SRC} */ = {{")
L.append(f"\t\t\tisa = PBXGroup;")
L.append(f"\t\t\tchildren = (")
for f in FILES:
    L.append(f"\t\t\t\t{SRCID[f]} /* {f} */,")
L.append(f"\t\t\t);")
L.append(f"\t\t\tpath = {SRC};")
L.append(f"\t\t\tsourceTree = \"<group>\";")
L.append(f"\t\t}};")
L.append(f"\t\t{ID['productsGroup']} /* Products */ = {{")
L.append(f"\t\t\tisa = PBXGroup;")
L.append(f"\t\t\tchildren = (")
L.append(f"\t\t\t\t{ID['appRef']} /* DuoLab.app */,")
L.append(f"\t\t\t);")
L.append(f"\t\t\tname = Products;")
L.append(f"\t\t\tsourceTree = \"<group>\";")
L.append(f"\t\t}};")
L.append("/* End PBXGroup section */")

L.append("")
L.append("/* Begin PBXNativeTarget section */")
L.append(f"\t\t{ID['target']} /* DuoLab */ = {{")
L.append(f"\t\t\tisa = PBXNativeTarget;")
L.append(f"\t\t\tbuildConfigurationList = {ID['targetCL']} /* Build configuration list for target \"DuoLab\" */;")
L.append(f"\t\t\tbuildPhases = (")
L.append(f"\t\t\t\t{ID['sources']} /* Sources */,")
L.append(f"\t\t\t\t{ID['frameworks']} /* Frameworks */,")
L.append(f"\t\t\t\t{ID['resources']} /* Resources */,")
L.append(f"\t\t\t);")
L.append(f"\t\t\tbuildRules = (")
L.append(f"\t\t\t);")
L.append(f"\t\t\tdependencies = (")
L.append(f"\t\t\t);")
L.append(f"\t\t\tname = DuoLab;")
L.append(f"\t\t\tproductName = DuoLab;")
L.append(f"\t\t\tproductReference = {ID['appRef']} /* DuoLab.app */;")
L.append(f"\t\t\tproductType = \"com.apple.product-type.application\";")
L.append(f"\t\t}};")
L.append("/* End PBXNativeTarget section */")

L.append("")
L.append("/* Begin PBXProject section */")
L.append(f"\t\t{ID['project']} /* Project object */ = {{")
L.append(f"\t\t\tisa = PBXProject;")
L.append(f"\t\t\tattributes = {{")
L.append(f"\t\t\t\tBuildIndependentTargetsInParallel = 1;")
L.append(f"\t\t\t\tLastSwiftUpdateCheck = 2710;")
L.append(f"\t\t\t\tLastUpgradeCheck = 2710;")
L.append(f"\t\t\t}};")
L.append(f"\t\t\tbuildConfigurationList = {ID['projCL']} /* Build configuration list for build target \"DuoLab\" */;")
L.append(f"\t\t\tcompatibilityVersion = \"Xcode 15.0\";")
L.append(f"\t\t\tdevelopmentRegion = en;")
L.append(f"\t\t\thasScannedForEncodings = 0;")
L.append(f"\t\t\tknownRegions = (")
L.append(f"\t\t\t\ten,")
L.append(f"\t\t\t\tBase,")
L.append(f"\t\t\t);")
L.append(f"\t\t\tmainGroup = {ID['mainGroup']};")
L.append(f"\t\t\tproductRefGroup = {ID['productsGroup']} /* Products */;")
L.append(f"\t\t\tprojectDirPath = \"\";")
L.append(f"\t\t\tprojectRoot = \"\";")
L.append(f"\t\t\ttargets = (")
L.append(f"\t\t\t\t{ID['target']} /* DuoLab */,")
L.append(f"\t\t\t);")
L.append(f"\t\t}};")
L.append("/* End PBXProject section */")

L.append("")
L.append("/* Begin PBXResourcesBuildPhase section */")
L.append(f"\t\t{ID['resources']} /* Resources */ = {{")
L.append(f"\t\t\tisa = PBXResourcesBuildPhase;")
L.append(f"\t\t\tbuildActionMask = 2147483647;")
L.append(f"\t\t\tfiles = (")
L.append(f"\t\t\t);")
L.append(f"\t\t\trunOnlyForDeploymentPostprocessing = 0;")
L.append(f"\t\t}};")
L.append("/* End PBXResourcesBuildPhase section */")

L.append("")
L.append("/* Begin PBXSourcesBuildPhase section */")
L.append(f"\t\t{ID['sources']} /* Sources */ = {{")
L.append(f"\t\t\tisa = PBXSourcesBuildPhase;")
L.append(f"\t\t\tbuildActionMask = 2147483647;")
L.append(f"\t\t\tfiles = (")
for f in FILES:
    L.append(f"\t\t\t\t{BUILDID[f]} /* {f} in Sources */,")
L.append(f"\t\t\t);")
L.append(f"\t\t\trunOnlyForDeploymentPostprocessing = 0;")
L.append(f"\t\t}};")
L.append("/* End PBXSourcesBuildPhase section */")

L.append("")
L.append("/* Begin XCBuildConfiguration section */")
L.append(cfg(ID['projDebug'], "Debug", PROJ_DEBUG))
L.append(cfg(ID['projRelease'], "Release", PROJ_RELEASE))
L.append(cfg(ID['targetDebug'], "Debug", TARGET_SETTINGS))
L.append(cfg(ID['targetRelease'], "Release", TARGET_SETTINGS))
L.append("/* End XCBuildConfiguration section */")

L.append("")
L.append("/* Begin XCConfigurationList section */")
L.append(f"\t\t{ID['projCL']} = {{")
L.append(f"\t\t\tisa = XCConfigurationList;")
L.append(f"\t\t\tbuildConfigurations = (")
L.append(f"\t\t\t\t{ID['projDebug']} /* Debug */,")
L.append(f"\t\t\t\t{ID['projRelease']} /* Release */,")
L.append(f"\t\t\t);")
L.append(f"\t\t\tdefaultConfigurationIsVisible = 0;")
L.append(f"\t\t\tdefaultConfigurationName = Release;")
L.append(f"\t\t}};")
L.append(f"\t\t{ID['targetCL']} = {{")
L.append(f"\t\t\tisa = XCConfigurationList;")
L.append(f"\t\t\tbuildConfigurations = (")
L.append(f"\t\t\t\t{ID['targetDebug']} /* Debug */,")
L.append(f"\t\t\t\t{ID['targetRelease']} /* Release */,")
L.append(f"\t\t\t);")
L.append(f"\t\t\tdefaultConfigurationIsVisible = 0;")
L.append(f"\t\t\tdefaultConfigurationName = Release;")
L.append(f"\t\t}};")
L.append("/* End XCConfigurationList section */")

L.append("\t};")
L.append(f"\trootObject = {ID['project']} /* Project object */;")
L.append("}")

content = "\n".join(L) + "\n"
out = os.path.join(ROOT, "DuoLab.xcodeproj", "project.pbxproj")
os.makedirs(os.path.dirname(out), exist_ok=True)
with open(out, "w") as f:
    f.write(content)

ws = os.path.join(ROOT, "DuoLab.xcodeproj", "project.xcworkspace", "contents.xcworkspacedata")
os.makedirs(os.path.dirname(ws), exist_ok=True)
with open(ws, "w") as f:
    f.write('<?xml version="1.0" encoding="UTF-8"?>\n'
            '<workspace version = "1.0">\n'
            '   <fileRef location = "self:">\n   </fileRef>\n'
            '</workspace>\n')

print("wrote", out, len(content), "bytes,", len(FILES), "sources")
