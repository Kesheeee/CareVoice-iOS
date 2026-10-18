#!/usr/bin/env python3
"""Deterministic, dependency-free Xcode project generation. Run after adding Swift files."""
from pathlib import Path
import hashlib, json
root=Path(__file__).resolve().parent.parent
objects={}
def uid(s): return hashlib.sha1(s.encode()).hexdigest()[:24].upper()
def obj(key, body): objects[uid(key)] = body; return uid(key)
def q(s): return json.dumps(str(s))
def refs(xs): return '(' + ', '.join(xs) + (',)' if xs else ')')
appfiles=sorted((root/'CareVoice').rglob('*.swift'))
uitests=sorted((root/'CareVoiceUITests').glob('*.swift'))
resources=[root/'CareVoice/Resources/Assets.xcassets',root/'CareVoice/Resources/PrivacyInfo.xcprivacy']+sorted(p for p in (root/'CareVoice/Resources').rglob('*.json') if not any(part.endswith('.xcassets') for part in p.parts))
fileids=[]
builds={'app':[],'ui':[],'resources':[]}
for f in appfiles+uitests+resources:
 rel=f.relative_to(root).as_posix(); kind='sourcecode.swift' if f.suffix=='.swift' else 'folder.assetcatalog' if f.suffix=='.xcassets' else 'text.xml' if f.suffix=='.xcprivacy' else 'text.json'
 fid=obj(rel, f'isa = PBXFileReference; lastKnownFileType = {kind}; path = {q(rel)}; sourceTree = "<group>";')
 fileids.append(fid)
 bid=obj('build:'+rel, f'isa = PBXBuildFile; fileRef = {fid};')
 builds['ui' if 'CareVoiceUITests' in rel else 'app' if f.suffix=='.swift' else 'resources'].append(bid)
appProduct=obj('appProduct','isa = PBXFileReference; explicitFileType = wrapper.application; path = CareVoice.app; sourceTree = BUILT_PRODUCTS_DIR;')
uiProduct=obj('uiProduct','isa = PBXFileReference; explicitFileType = wrapper.cfbundle; path = CareVoiceUITests.xctest; sourceTree = BUILT_PRODUCTS_DIR;')
products=obj('products',f'isa = PBXGroup; children = {refs([appProduct,uiProduct])}; name = Products; sourceTree = "<group>";')
main=obj('main',f'isa = PBXGroup; children = {refs(fileids+[products])}; sourceTree = "<group>";')
for key,isa,files in [('sources','PBXSourcesBuildPhase',builds['app']),('resources','PBXResourcesBuildPhase',builds['resources']),('frameworks','PBXFrameworksBuildPhase',[]),('uiSources','PBXSourcesBuildPhase',builds['ui']),('uiFrameworks','PBXFrameworksBuildPhase',[])]:
 obj(key,f'isa = {isa}; buildActionMask = 2147483647; files = {refs(files)}; runOnlyForDeploymentPostprocessing = 0;')
common={'SWIFT_VERSION':'5.0','IPHONEOS_DEPLOYMENT_TARGET':'17.0','SDKROOT':'iphoneos','CLANG_ENABLE_MODULES':'YES','TARGETED_DEVICE_FAMILY':'1,2','CODE_SIGN_STYLE':'Automatic','ENABLE_USER_SCRIPT_SANDBOXING':'YES'}
app={**common,'PRODUCT_BUNDLE_IDENTIFIER':'com.carevoice.app','PRODUCT_NAME':'$(TARGET_NAME)','GENERATE_INFOPLIST_FILE':'YES','INFOPLIST_KEY_CFBundleDisplayName':'CareVoice','INFOPLIST_KEY_LSApplicationCategoryType':'public.app-category.lifestyle','INFOPLIST_KEY_NSMicrophoneUsageDescription':'Use your microphone to transcribe an observation on your device. Audio is not saved.','INFOPLIST_KEY_NSSpeechRecognitionUsageDescription':'Convert your voice into an editable observation using on-device speech recognition.','INFOPLIST_KEY_UIApplicationSceneManifest_Generation':'YES','INFOPLIST_KEY_UILaunchScreen_Generation':'YES','INFOPLIST_KEY_UISupportedInterfaceOrientations_iPhone':'UIInterfaceOrientationPortrait','INFOPLIST_KEY_UISupportedInterfaceOrientations_iPad':'UIInterfaceOrientationPortrait UIInterfaceOrientationPortraitUpsideDown UIInterfaceOrientationLandscapeLeft UIInterfaceOrientationLandscapeRight','ASSETCATALOG_COMPILER_APPICON_NAME':'AppIcon','MARKETING_VERSION':'1.0','CURRENT_PROJECT_VERSION':'1','SWIFT_EMIT_LOC_STRINGS':'YES','SUPPORTS_MACCATALYST':'NO'}
ui={**common,'PRODUCT_BUNDLE_IDENTIFIER':'com.carevoice.app.uitests','PRODUCT_NAME':'$(TARGET_NAME)','GENERATE_INFOPLIST_FILE':'YES','TEST_TARGET_NAME':'CareVoice'}
for group,settings in [('project',common),('app',app),('ui',ui)]:
 ids=[]
 for name in ['Debug','Release']:
  vals={**settings,'SWIFT_OPTIMIZATION_LEVEL':'-Onone' if name=='Debug' else '-O','DEBUG_INFORMATION_FORMAT':'dwarf' if name=='Debug' else 'dwarf-with-dsym'}
  if name=='Debug': vals['SWIFT_ACTIVE_COMPILATION_CONDITIONS']='DEBUG'; vals['ENABLE_TESTABILITY']='YES'
  body=' '.join(f'{k} = {q(v)};' for k,v in vals.items())
  ids.append(obj(group+name,f'isa = XCBuildConfiguration; buildSettings = {{ {body} }}; name = {name};'))
 obj(group+'Configs',f'isa = XCConfigurationList; buildConfigurations = {refs(ids)}; defaultConfigurationIsVisible = 0; defaultConfigurationName = Release;')
proxy=obj('proxy',f'isa = PBXContainerItemProxy; containerPortal = {uid("project")}; proxyType = 1; remoteGlobalIDString = {uid("app")}; remoteInfo = CareVoice;')
dep=obj('dependency',f'isa = PBXTargetDependency; target = {uid("app")}; targetProxy = {proxy};')
obj('app',f'isa = PBXNativeTarget; buildConfigurationList = {uid("appConfigs")}; buildPhases = {refs([uid("sources"),uid("frameworks"),uid("resources")])}; buildRules = (); dependencies = (); name = CareVoice; productName = CareVoice; productReference = {appProduct}; productType = "com.apple.product-type.application";')
obj('ui',f'isa = PBXNativeTarget; buildConfigurationList = {uid("uiConfigs")}; buildPhases = {refs([uid("uiSources"),uid("uiFrameworks")])}; buildRules = (); dependencies = {refs([dep])}; name = CareVoiceUITests; productName = CareVoiceUITests; productReference = {uiProduct}; productType = "com.apple.product-type.bundle.ui-testing";')
obj('project',f'isa = PBXProject; attributes = {{ BuildIndependentTargetsInParallel = YES; LastUpgradeCheck = 1600; TargetAttributes = {{ {uid("app")} = {{ CreatedOnToolsVersion = 16.0; }}; {uid("ui")} = {{ CreatedOnToolsVersion = 16.0; TestTargetID = {uid("app")}; }}; }}; }}; buildConfigurationList = {uid("projectConfigs")}; compatibilityVersion = "Xcode 14.0"; developmentRegion = en; hasScannedForEncodings = 0; knownRegions = (en, Base, "zh-Hant"); mainGroup = {main}; productRefGroup = {products}; projectDirPath = ""; projectRoot = ""; targets = {refs([uid("app"),uid("ui")])};')
p=root/'CareVoice.xcodeproj';p.mkdir(exist_ok=True)
(p/'project.pbxproj').write_text('// !$*UTF8*$!\n{ archiveVersion = 1; classes = {}; objectVersion = 56; objects = {\n'+'\n'.join(f'{k} = {{ {v} }};' for k,v in objects.items())+f'\n}}; rootObject = {uid("project")}; }}\n')
s=p/'xcshareddata/xcschemes';s.mkdir(parents=True,exist_ok=True)
def buildref(key,name):return f'<BuildableReference BuildableIdentifier="primary" BlueprintIdentifier="{uid(key)}" BuildableName="{name}" BlueprintName="{name.split(".")[0]}" ReferencedContainer="container:CareVoice.xcodeproj"/>'
(s/'CareVoice.xcscheme').write_text(f'''<?xml version="1.0" encoding="UTF-8"?>
<Scheme LastUpgradeVersion="1600" version="1.3">
<BuildAction parallelizeBuildables="YES" buildImplicitDependencies="YES"><BuildActionEntries><BuildActionEntry buildForTesting="YES" buildForRunning="YES" buildForProfiling="YES" buildForArchiving="YES" buildForAnalyzing="YES">{buildref('app','CareVoice.app')}</BuildActionEntry></BuildActionEntries></BuildAction>
<TestAction buildConfiguration="Debug" selectedDebuggerIdentifier="Xcode.DebuggerFoundation.Debugger.LLDB" selectedLauncherIdentifier="Xcode.IDEFoundation.Launcher.LLDB" shouldUseLaunchSchemeArgsEnv="YES"><Testables><TestableReference skipped="NO">{buildref('ui','CareVoiceUITests.xctest')}</TestableReference></Testables></TestAction>
<LaunchAction buildConfiguration="Debug" selectedDebuggerIdentifier="Xcode.DebuggerFoundation.Debugger.LLDB" selectedLauncherIdentifier="Xcode.IDEFoundation.Launcher.LLDB" launchStyle="0" useCustomWorkingDirectory="NO" ignoresPersistentStateOnLaunch="NO" debugDocumentVersioning="YES" allowLocationSimulation="YES"><BuildableProductRunnable runnableDebuggingMode="0">{buildref('app','CareVoice.app')}</BuildableProductRunnable></LaunchAction>
<ProfileAction buildConfiguration="Release" shouldUseLaunchSchemeArgsEnv="YES" savedToolIdentifier="" useCustomWorkingDirectory="NO" debugDocumentVersioning="YES"><BuildableProductRunnable runnableDebuggingMode="0">{buildref('app','CareVoice.app')}</BuildableProductRunnable></ProfileAction>
<AnalyzeAction buildConfiguration="Debug"/><ArchiveAction buildConfiguration="Release" revealArchiveInOrganizer="YES"/>
</Scheme>''')
print('Generated CareVoice.xcodeproj')
