#define MyAppName "FocusTrack"
#define MyAppVersion "1.1.1"
#define MyAppPublisher "FocusTrack"
#define MyAppExeName "focustrack.exe"
#define MyAppId "{{2DB8EA54-4A0D-4415-B4FD-365A80333F0F}"

[Setup]
AppId={#MyAppId}
AppName={#MyAppName}
AppVersion={#MyAppVersion}
AppPublisher={#MyAppPublisher}
DefaultDirName={autopf}\{#MyAppName}
DefaultGroupName={#MyAppName}
DisableProgramGroupPage=no
ArchitecturesAllowed=x64compatible
ArchitecturesInstallIn64BitMode=x64compatible
LicenseFile=LICENSE.txt
InfoBeforeFile=PRIVACY_POLICY.txt
OutputDir=dist
OutputBaseFilename=FocusTrack-Setup-{#MyAppVersion}
SetupIconFile=..\windows\runner\resources\app_icon.ico
UninstallDisplayIcon={app}\{#MyAppExeName}
WizardStyle=modern
Compression=lzma2/ultra64
SolidCompression=yes
PrivilegesRequired=admin
VersionInfoCompany={#MyAppPublisher}
VersionInfoCopyright=Copyright (C) 2026 FocusTrack contributors
VersionInfoDescription=FocusTrack Setup
ChangesAssociations=no
ChangesEnvironment=no
DisableDirPage=no
DisableReadyMemo=no
CloseApplications=force
RestartApplications=no
SetupLogging=yes

[Languages]
Name: "english"; MessagesFile: "compiler:Default.isl"

[Tasks]
Name: "desktopicon"; Description: "Create a desktop icon"; GroupDescription: "Additional shortcuts:"; Flags: unchecked

[Files]
Source: "..\build\windows\x64\runner\Release\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs


[Icons]
Name: "{group}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"; IconFilename: "{app}\{#MyAppExeName}"
Name: "{group}\Uninstall {#MyAppName}"; Filename: "{uninstallexe}"
Name: "{autodesktop}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"; Tasks: desktopicon; IconFilename: "{app}\{#MyAppExeName}"

[Run]
Filename: "{app}\{#MyAppExeName}"; Description: "Launch {#MyAppName}"; Flags: nowait postinstall skipifsilent

[Messages]
WelcomeLabel1=Welcome to the FocusTrack Setup Wizard
WelcomeLabel2=This will install FocusTrack on your computer. FocusTrack is a privacy-first desktop time tracker with fully local analytics and export support.%n%nIt is recommended that you close other applications before continuing.
WizardLicense=Software License Agreement
InfoBeforeLabel=Please review this privacy notice before continuing with the installation.

[Code]
procedure InitializeWizard();
begin
  WizardForm.DirEdit.Text := ExpandConstant('{autopf}\FocusTrack');
end;