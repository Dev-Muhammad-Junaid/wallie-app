#!/usr/bin/env python3
"""Generate ParentsHealth.xcodeproj/project.pbxproj"""
import uuid
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "ParentsHealth.xcodeproj/project.pbxproj"

def uid():
    return uuid.uuid4().hex[:24].upper()

class G:
    def __init__(self):
        self.m = {}
    def id(self, k):
        if k not in self.m:
            self.m[k] = uid()
        return self.m[k]

g = G()

app_files = [
    ("App", "App/ParentsHealthApp.swift", "ParentsHealthApp.swift"),
    ("App", "App/AppDelegate.swift", "AppDelegate.swift"),
    ("Models", "Models/MetricType.swift", "MetricType.swift"),
    ("Models", "Models/ParentProfile.swift", "ParentProfile.swift"),
    ("Models", "Models/HealthMetric.swift", "HealthMetric.swift"),
    ("Models", "Models/Medication.swift", "Medication.swift"),
    ("Models", "Models/MedicationFrequency.swift", "MedicationFrequency.swift"),
    ("Models", "Models/LabReport.swift", "LabReport.swift"),
    ("Models", "Models/LabTestKey.swift", "LabTestKey.swift"),
    ("Models", "Models/HealthAlert.swift", "HealthAlert.swift"),
    ("Models", "Models/CareProvider.swift", "CareProvider.swift"),
    ("Models", "Models/Appointment.swift", "Appointment.swift"),
    ("Design", "Design/AppTheme.swift", "AppTheme.swift"),
    ("Design", "Design/LiquidGlassComponents.swift", "LiquidGlassComponents.swift"),
    ("Design", "Design/SharedComponents.swift", "SharedComponents.swift"),
    ("Views", "Views/MainTabView.swift", "MainTabView.swift"),
    ("Onboarding", "Views/Onboarding/OnboardingView.swift", "OnboardingView.swift"),
    ("Dashboard", "Views/Dashboard/DashboardView.swift", "DashboardView.swift"),
    ("Alerts", "Views/Alerts/HealthAlertsView.swift", "HealthAlertsView.swift"),
    ("Parents", "Views/Parents/ParentsListView.swift", "ParentsListView.swift"),
    ("Parents", "Views/Parents/ParentDetailView.swift", "ParentDetailView.swift"),
    ("Parents", "Views/Parents/ParentFormView.swift", "ParentFormView.swift"),
    ("Care", "Views/Care/CareProvidersView.swift", "CareProvidersView.swift"),
    ("Care", "Views/Care/AddCareProviderView.swift", "AddCareProviderView.swift"),
    ("Care", "Views/Care/AddAppointmentView.swift", "AddAppointmentView.swift"),
    ("Charts", "Views/Charts/ChartsView.swift", "ChartsView.swift"),
    ("Medications", "Views/Medications/MedicationsView.swift", "MedicationsView.swift"),
    ("Medications", "Views/Medications/AddMedicationView.swift", "AddMedicationView.swift"),
    ("Log", "Views/Log/QuickLogView.swift", "QuickLogView.swift"),
    ("Labs", "Views/Labs/LabReportsView.swift", "LabReportsView.swift"),
    ("Labs", "Views/Labs/LabReportDetailView.swift", "LabReportDetailView.swift"),
    ("Labs", "Views/Labs/ImportLabReportView.swift", "ImportLabReportView.swift"),
    ("Settings", "Views/Settings/SettingsView.swift", "SettingsView.swift"),
    ("Services", "Services/SampleData.swift", "SampleData.swift"),
    ("Services", "Services/HealthScoreCalculator.swift", "HealthScoreCalculator.swift"),
    ("Services", "Services/MedicationAdherenceCalculator.swift", "MedicationAdherenceCalculator.swift"),
    ("Services", "Services/LabReportParser.swift", "LabReportParser.swift"),
    ("Services", "Services/LabReportOCRService.swift", "LabReportOCRService.swift"),
    ("Services", "Services/MedicationOCRService.swift", "MedicationOCRService.swift"),
    ("Services", "Services/NotificationService.swift", "NotificationService.swift"),
    ("Services", "Services/HealthKitService.swift", "HealthKitService.swift"),
    ("Services", "Services/ReportExportService.swift", "ReportExportService.swift"),
    ("Services", "Services/AppSettings.swift", "AppSettings.swift"),
    ("Services", "Services/LabTrendService.swift", "LabTrendService.swift"),
    ("Services", "Services/HealthAlertService.swift", "HealthAlertService.swift"),
    ("Services", "Services/LabAnalysisService.swift", "LabAnalysisService.swift"),
    ("Services", "Services/LabReportRepository.swift", "LabReportRepository.swift"),
    ("Services", "Services/SelectedParentStore.swift", "SelectedParentStore.swift"),
    ("Services", "Services/FeedbackService.swift", "FeedbackService.swift"),
    ("Services", "Services/AppNavigationStore.swift", "AppNavigationStore.swift"),
]

test_files = [
    ("ParentsHealthTests/HealthScoreCalculatorTests.swift", "HealthScoreCalculatorTests.swift"),
    ("ParentsHealthTests/LabReportParserTests.swift", "LabReportParserTests.swift"),
    ("ParentsHealthTests/MetricTypeTests.swift", "MetricTypeTests.swift"),
    ("ParentsHealthTests/MedicationAdherenceTests.swift", "MedicationAdherenceTests.swift"),
    ("ParentsHealthTests/MedicationScheduleTests.swift", "MedicationScheduleTests.swift"),
    ("ParentsHealthTests/MedicationOCRServiceTests.swift", "MedicationOCRServiceTests.swift"),
    ("ParentsHealthTests/ReportExportServiceTests.swift", "ReportExportServiceTests.swift"),
    ("ParentsHealthTests/LabTrendServiceTests.swift", "LabTrendServiceTests.swift"),
    ("ParentsHealthTests/LabAnalysisServiceTests.swift", "LabAnalysisServiceTests.swift"),
    ("ParentsHealthTests/HealthAlertServiceTests.swift", "HealthAlertServiceTests.swift"),
]
uitest_files = [("ParentsHealthUITests/ParentsHealthUITests.swift", "ParentsHealthUITests.swift")]

def fid(path):
    return g.id(f"fr_{path}"), g.id(f"bf_{path}")

# structural ids
P = {k: g.id(k) for k in [
    'PROJECT','APP_TARGET','TEST_TARGET','UITEST_TARGET','APP_SOURCES','TEST_SOURCES','UITEST_SOURCES',
    'APP_FRAMEWORKS','TEST_FRAMEWORKS','UITEST_FRAMEWORKS','APP_RESOURCES','ROOT','PRODUCTS','PH',
    'TESTS_GRP','UITESTS_GRP','ASSETS_FR','ASSETS_BF','INFO_FR','ENT_FR','APP_PROD','TEST_PROD','UITEST_PROD',
    'PROJ_CL','APP_CL','TEST_CL','UITEST_CL','DBG_PROJ','REL_PROJ','DBG_APP','REL_APP','DBG_TEST','REL_TEST',
    'DBG_UITEST','REL_UITEST','TEST_DEP','UITEST_DEP','PROXY_TEST','PROXY_UITEST'
]}
GIDS = {k: g.id(f'grp_{k}') for k in ['App','Models','Design','Views','Services','Dashboard','Parents','Care','Charts','Medications','Log','Labs','Settings','Alerts','Onboarding']}

lines = []
L = lines.append
L('// !$*UTF8*$!')
L('{')
L('\tarchiveVersion = 1;')
L('\tclasses = {};')
L('\tobjectVersion = 56;')
L('\tobjects = {')

L('\n/* Begin PBXBuildFile section */')
for _, path, name in app_files:
    fr, bf = fid(path)
    L(f'\t\t{bf} /* {name} in Sources */ = {{isa = PBXBuildFile; fileRef = {fr} /* {name} */; }};')
L(f'\t\t{P["ASSETS_BF"]} /* Assets.xcassets in Resources */ = {{isa = PBXBuildFile; fileRef = {P["ASSETS_FR"]} /* Assets.xcassets */; }};')
for path, name in test_files + uitest_files:
    fr, bf = fid(path)
    L(f'\t\t{bf} /* {name} in Sources */ = {{isa = PBXBuildFile; fileRef = {fr} /* {name} */; }};')
L('/* End PBXBuildFile section */')

L('\n/* Begin PBXContainerItemProxy section */')
for key, remote in [('PROXY_TEST', P['APP_TARGET']), ('PROXY_UITEST', P['APP_TARGET'])]:
    L(f'\t\t{P[key]} /* PBXContainerItemProxy */ = {{isa = PBXContainerItemProxy; containerPortal = {P["PROJECT"]} /* Project object */; proxyType = 1; remoteGlobalIDString = {remote}; remoteInfo = ParentsHealth; }};')
L('/* End PBXContainerItemProxy section */')

L('\n/* Begin PBXFileReference section */')
for _, path, name in app_files:
    fr, _ = fid(path)
    L(f'\t\t{fr} /* {name} */ = {{isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = {name}; sourceTree = "<group>"; }};')
L(f'\t\t{P["ASSETS_FR"]} /* Assets.xcassets */ = {{isa = PBXFileReference; lastKnownFileType = folder.assetcatalog; path = Assets.xcassets; sourceTree = "<group>"; }};')
L(f'\t\t{P["INFO_FR"]} /* Info.plist */ = {{isa = PBXFileReference; lastKnownFileType = text.plist.xml; path = Info.plist; sourceTree = "<group>"; }};')
L(f'\t\t{P["ENT_FR"]} /* ParentsHealth.entitlements */ = {{isa = PBXFileReference; lastKnownFileType = text.plist.entitlements; path = ParentsHealth.entitlements; sourceTree = "<group>"; }};')
L(f'\t\t{P["APP_PROD"]} /* ParentsHealth.app */ = {{isa = PBXFileReference; explicitFileType = wrapper.application; includeInIndex = 0; path = ParentsHealth.app; sourceTree = BUILT_PRODUCTS_DIR; }};')
for path, name in test_files:
    fr, _ = fid(path)
    L(f'\t\t{fr} /* {name} */ = {{isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = {name}; sourceTree = "<group>"; }};')
L(f'\t\t{P["TEST_PROD"]} /* ParentsHealthTests.xctest */ = {{isa = PBXFileReference; explicitFileType = wrapper.cfbundle; includeInIndex = 0; path = ParentsHealthTests.xctest; sourceTree = BUILT_PRODUCTS_DIR; }};')
for path, name in uitest_files:
    fr, _ = fid(path)
    L(f'\t\t{fr} /* {name} */ = {{isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = {name}; sourceTree = "<group>"; }};')
L(f'\t\t{P["UITEST_PROD"]} /* ParentsHealthUITests.xctest */ = {{isa = PBXFileReference; explicitFileType = wrapper.cfbundle; includeInIndex = 0; path = ParentsHealthUITests.xctest; sourceTree = BUILT_PRODUCTS_DIR; }};')
L('/* End PBXFileReference section */')

for label, pk in [('APP', 'APP_FRAMEWORKS'), ('TEST', 'TEST_FRAMEWORKS'), ('UITEST', 'UITEST_FRAMEWORKS')]:
    L(f'\n/* Begin PBXFrameworksBuildPhase section */' if label == 'APP' else '')
    L(f'\t\t{P[pk]} /* Frameworks */ = {{isa = PBXFrameworksBuildPhase; buildActionMask = 2147483647; files = (); runOnlyForDeploymentPostprocessing = 0; }};')
L('/* End PBXFrameworksBuildPhase section */')

L('\n/* Begin PBXGroup section */')
L(f'\t\t{P["ROOT"]} = {{isa = PBXGroup; children = ({P["PH"]} /* ParentsHealth */, {P["TESTS_GRP"]} /* ParentsHealthTests */, {P["UITESTS_GRP"]} /* ParentsHealthUITests */, {P["PRODUCTS"]} /* Products */); sourceTree = "<group>"; }};')
L(f'\t\t{P["PRODUCTS"]} = {{isa = PBXGroup; children = ({P["APP_PROD"]} /* ParentsHealth.app */, {P["TEST_PROD"]} /* ParentsHealthTests.xctest */, {P["UITEST_PROD"]} /* ParentsHealthUITests.xctest */); name = Products; sourceTree = "<group>"; }};')
L(f'\t\t{P["PH"]} = {{isa = PBXGroup; children = ({GIDS["App"]} /* App */, {GIDS["Models"]} /* Models */, {GIDS["Design"]} /* Design */, {GIDS["Views"]} /* Views */, {GIDS["Services"]} /* Services */, {P["ASSETS_FR"]} /* Assets.xcassets */, {P["INFO_FR"]} /* Info.plist */, {P["ENT_FR"]} /* ParentsHealth.entitlements */); path = ParentsHealth; sourceTree = "<group>"; }};')

subgroups = {
    'App': [('App/ParentsHealthApp.swift','ParentsHealthApp.swift'),('App/AppDelegate.swift','AppDelegate.swift')],
    'Models': [(f'Models/{n}',n) for n in ['MetricType.swift','ParentProfile.swift','HealthMetric.swift','Medication.swift','MedicationFrequency.swift','LabReport.swift','LabTestKey.swift','HealthAlert.swift','CareProvider.swift','Appointment.swift']],
    'Design': [('Design/AppTheme.swift','AppTheme.swift'),('Design/LiquidGlassComponents.swift','LiquidGlassComponents.swift'),('Design/SharedComponents.swift','SharedComponents.swift')],
    'Services': [(f'Services/{n}',n) for n in ['SampleData.swift','HealthScoreCalculator.swift','MedicationAdherenceCalculator.swift','LabReportParser.swift','LabReportOCRService.swift','MedicationOCRService.swift','NotificationService.swift','HealthKitService.swift','ReportExportService.swift','AppSettings.swift','LabTrendService.swift','HealthAlertService.swift','LabAnalysisService.swift','LabReportRepository.swift','SelectedParentStore.swift','FeedbackService.swift','AppNavigationStore.swift']],
    'Dashboard': [('Views/Dashboard/DashboardView.swift','DashboardView.swift')],
    'Alerts': [('Views/Alerts/HealthAlertsView.swift','HealthAlertsView.swift')],
    'Parents': [('Views/Parents/ParentsListView.swift','ParentsListView.swift'),('Views/Parents/ParentDetailView.swift','ParentDetailView.swift'),('Views/Parents/ParentFormView.swift','ParentFormView.swift')],
    'Care': [('Views/Care/CareProvidersView.swift','CareProvidersView.swift'),('Views/Care/AddCareProviderView.swift','AddCareProviderView.swift'),('Views/Care/AddAppointmentView.swift','AddAppointmentView.swift')],
    'Charts': [('Views/Charts/ChartsView.swift','ChartsView.swift')],
    'Medications': [('Views/Medications/MedicationsView.swift','MedicationsView.swift'),('Views/Medications/AddMedicationView.swift','AddMedicationView.swift')],
    'Log': [('Views/Log/QuickLogView.swift','QuickLogView.swift')],
    'Labs': [('Views/Labs/LabReportsView.swift','LabReportsView.swift'),('Views/Labs/LabReportDetailView.swift','LabReportDetailView.swift'),('Views/Labs/ImportLabReportView.swift','ImportLabReportView.swift')],
    'Settings': [('Views/Settings/SettingsView.swift','SettingsView.swift')],
    'Onboarding': [('Views/Onboarding/OnboardingView.swift','OnboardingView.swift')],
}

L(f'\t\t{GIDS["Views"]} = {{isa = PBXGroup; children = ({fid("Views/MainTabView.swift")[0]} /* MainTabView.swift */, {GIDS["Onboarding"]} /* Onboarding */, {GIDS["Dashboard"]} /* Dashboard */, {GIDS["Alerts"]} /* Alerts */, {GIDS["Parents"]} /* Parents */, {GIDS["Care"]} /* Care */, {GIDS["Charts"]} /* Charts */, {GIDS["Medications"]} /* Medications */, {GIDS["Log"]} /* Log */, {GIDS["Labs"]} /* Labs */, {GIDS["Settings"]} /* Settings */); path = Views; sourceTree = "<group>"; }};')
for gn, items in subgroups.items():
    kids = ', '.join(f'{fid(p)[0]} /* {n} */' for p,n in items)
    L(f'\t\t{GIDS[gn]} = {{isa = PBXGroup; children = ({kids}); path = {gn}; sourceTree = "<group>"; }};')

L(f'\t\t{P["TESTS_GRP"]} = {{isa = PBXGroup; children = ({", ".join(f"{fid(p)[0]} /* {n} */" for p,n in test_files)}); path = ParentsHealthTests; sourceTree = "<group>"; }};')
L(f'\t\t{P["UITESTS_GRP"]} = {{isa = PBXGroup; children = ({", ".join(f"{fid(p)[0]} /* {n} */" for p,n in uitest_files)}); path = ParentsHealthUITests; sourceTree = "<group>"; }};')
L('/* End PBXGroup section */')

targets = [
    ('ParentsHealth', 'APP_TARGET', 'APP_SOURCES', 'APP_FRAMEWORKS', 'APP_RESOURCES', 'APP_PROD', 'com.apple.product-type.application', 'APP_CL', None),
    ('ParentsHealthTests', 'TEST_TARGET', 'TEST_SOURCES', 'TEST_FRAMEWORKS', None, 'TEST_PROD', 'com.apple.product-type.bundle.unit-test', 'TEST_CL', 'TEST_DEP'),
    ('ParentsHealthUITests', 'UITEST_TARGET', 'UITEST_SOURCES', 'UITEST_FRAMEWORKS', None, 'UITEST_PROD', 'com.apple.product-type.bundle.ui-testing', 'UITEST_CL', 'UITEST_DEP'),
]
L('\n/* Begin PBXNativeTarget section */')
for name, tk, sk, fk, rk, prod, ptype, cl, dep in targets:
    L(f'\t\t{P[tk]} /* {name} */ = {{')
    L(f'\t\t\tisa = PBXNativeTarget; buildConfigurationList = {P[cl]} /* Build configuration list for PBXNativeTarget "{name}" */;')
    L(f'\t\t\tbuildPhases = ({P[sk]} /* Sources */, {P[fk]} /* Frameworks */' + (f', {P[rk]} /* Resources */' if rk else '') + ');')
    L('\t\t\tbuildRules = ();')
    if dep:
        L(f'\t\t\tdependencies = ({P[dep]} /* PBXTargetDependency */);')
    else:
        L('\t\t\tdependencies = ();')
    L(f'\t\t\tname = {name}; productName = {name if "Tests" in name else "ParentsHealth"};')
    L(f'\t\t\tproductReference = {P[prod]} /* {name}{".app" if name=="ParentsHealth" else ".xctest"} */; productType = "{ptype}"; }};')
L('/* End PBXNativeTarget section */')

L(f'\n/* Begin PBXProject section */')
L(f'\t\t{P["PROJECT"]} /* Project object */ = {{isa = PBXProject; attributes = {{BuildIndependentTargetsInParallel = 1; LastSwiftUpdateCheck = 1600; LastUpgradeCheck = 1600; TargetAttributes = {{')
for tk in ['APP_TARGET','TEST_TARGET','UITEST_TARGET']:
    extra = f'TestTargetID = {P["APP_TARGET"]}; ' if tk != 'APP_TARGET' else ''
    L(f'\t\t\t\t{P[tk]} = {{CreatedOnToolsVersion = 16.0; {extra}}};')
L(f'\t\t\t}};}}; buildConfigurationList = {P["PROJ_CL"]}; compatibilityVersion = "Xcode 14.0"; developmentRegion = en; hasScannedForEncodings = 0; knownRegions = (en, Base); mainGroup = {P["ROOT"]}; productRefGroup = {P["PRODUCTS"]}; projectDirPath = ""; projectRoot = ""; targets = ({P["APP_TARGET"]}, {P["TEST_TARGET"]}, {P["UITEST_TARGET"]}); }};')
L('/* End PBXProject section */')

L(f'\n/* Begin PBXResourcesBuildPhase section */')
L(f'\t\t{P["APP_RESOURCES"]} /* Resources */ = {{isa = PBXResourcesBuildPhase; buildActionMask = 2147483647; files = ({P["ASSETS_BF"]} /* Assets.xcassets in Resources */); runOnlyForDeploymentPostprocessing = 0; }};')
L('/* End PBXResourcesBuildPhase section */')

L('\n/* Begin PBXSourcesBuildPhase section */')
for sk, files in [(P['APP_SOURCES'], app_files), (P['TEST_SOURCES'], test_files), (P['UITEST_SOURCES'], uitest_files)]:
    L(f'\t\t{sk} /* Sources */ = {{isa = PBXSourcesBuildPhase; buildActionMask = 2147483647; files = (')
    if sk == P['APP_SOURCES']:
        for _, path, name in app_files:
            L(f'\t\t\t{fid(path)[1]} /* {name} in Sources */,')
    elif sk == P['TEST_SOURCES']:
        for path, name in test_files:
            L(f'\t\t\t{fid(path)[1]} /* {name} in Sources */,')
    else:
        for path, name in uitest_files:
            L(f'\t\t\t{fid(path)[1]} /* {name} in Sources */,')
    L('\t\t); runOnlyForDeploymentPostprocessing = 0; };')
L('/* End PBXSourcesBuildPhase section */')

L('\n/* Begin PBXTargetDependency section */')
L(f'\t\t{P["TEST_DEP"]} = {{isa = PBXTargetDependency; target = {P["APP_TARGET"]}; targetProxy = {P["PROXY_TEST"]}; }};')
L(f'\t\t{P["UITEST_DEP"]} = {{isa = PBXTargetDependency; target = {P["APP_TARGET"]}; targetProxy = {P["PROXY_UITEST"]}; }};')
L('/* End PBXTargetDependency section */')

# configs abbreviated
L('\n/* Begin XCBuildConfiguration section */')
for cid, name in [(P['DBG_PROJ'],'Debug'),(P['REL_PROJ'],'Release')]:
    L(f'\t\t{cid} /* {name} */ = {{isa = XCBuildConfiguration; buildSettings = {{IPHONEOS_DEPLOYMENT_TARGET = 17.0; SDKROOT = iphoneos; ENABLE_TESTABILITY = YES;}}; name = {name}; }};')
for cid, name in [(P['DBG_APP'],'Debug'),(P['REL_APP'],'Release')]:
    L(f'\t\t{cid} /* {name} */ = {{isa = XCBuildConfiguration; buildSettings = {{PRODUCT_NAME = ParentsHealth; PRODUCT_BUNDLE_IDENTIFIER = com.widgetsflow.parentshealth; INFOPLIST_FILE = ParentsHealth/Info.plist; CODE_SIGN_ENTITLEMENTS = ParentsHealth/ParentsHealth.entitlements; CODE_SIGN_STYLE = Automatic; DEVELOPMENT_TEAM = VCBDYB22D9; ASSETCATALOG_COMPILER_APPICON_NAME = AppIcon; CURRENT_PROJECT_VERSION = 2; MARKETING_VERSION = 1.0.1; SWIFT_VERSION = 5.0; TARGETED_DEVICE_FAMILY = "1,2";}}; name = {name}; }};')
for cid, name in [(P['DBG_TEST'],'Debug'),(P['REL_TEST'],'Release')]:
    L(f'\t\t{cid} /* {name} */ = {{isa = XCBuildConfiguration; buildSettings = {{BUNDLE_LOADER = "$(TEST_HOST)"; TEST_HOST = "$(BUILT_PRODUCTS_DIR)/ParentsHealth.app/$(BUNDLE_EXECUTABLE_FOLDER_PATH)/ParentsHealth"; PRODUCT_NAME = ParentsHealthTests; PRODUCT_BUNDLE_IDENTIFIER = com.widgetsflow.parentshealth.tests; SWIFT_VERSION = 5.0; IPHONEOS_DEPLOYMENT_TARGET = 17.0; GENERATE_INFOPLIST_FILE = YES;}}; name = {name}; }};')
for cid, name in [(P['DBG_UITEST'],'Debug'),(P['REL_UITEST'],'Release')]:
    L(f'\t\t{cid} /* {name} */ = {{isa = XCBuildConfiguration; buildSettings = {{TEST_TARGET_NAME = ParentsHealth; PRODUCT_NAME = ParentsHealthUITests; PRODUCT_BUNDLE_IDENTIFIER = com.widgetsflow.parentshealth.uitests; SWIFT_VERSION = 5.0; IPHONEOS_DEPLOYMENT_TARGET = 17.0; GENERATE_INFOPLIST_FILE = YES;}}; name = {name}; }};')
L('/* End XCBuildConfiguration section */')

L('\n/* Begin XCConfigurationList section */')
for cl, dbg, rel, label in [(P['PROJ_CL'],P['DBG_PROJ'],P['REL_PROJ'],'PBXProject "ParentsHealth"'),(P['APP_CL'],P['DBG_APP'],P['REL_APP'],'PBXNativeTarget "ParentsHealth"'),(P['TEST_CL'],P['DBG_TEST'],P['REL_TEST'],'PBXNativeTarget "ParentsHealthTests"'),(P['UITEST_CL'],P['DBG_UITEST'],P['REL_UITEST'],'PBXNativeTarget "ParentsHealthUITests"')]:
    L(f'\t\t{cl} /* Build configuration list for {label} */ = {{isa = XCConfigurationList; buildConfigurations = ({dbg} /* Debug */, {rel} /* Release */); defaultConfigurationIsVisible = 0; defaultConfigurationName = Release; }};')
L('/* End XCConfigurationList section */')
L('\t};')
L(f'\trootObject = {P["PROJECT"]} /* Project object */;')
L('}')

OUT.write_text('\n'.join(lines) + '\n')
print(f'Wrote {OUT} ({len(lines)} lines)')
