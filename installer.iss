[Setup]
AppId={{7B39A6F2-65C7-4CC8-9E3F-8E841B0810A2}
AppName=OpenCode
AppVersion=1.19.3
AppVerName=OpenCode 1.19.3
UninstallDisplayName=OpenCode
DefaultDirName={localappdata}\Programs\OpenCode
DefaultGroupName=OpenCode
PrivilegesRequired=lowest
Compression=lzma2/max
SolidCompression=yes
ArchitecturesInstallIn64BitMode=x64compatible
DisableProgramGroupPage=yes
WizardStyle=modern
OutputDir=out
OutputBaseFilename=opencode-1.19.3-setup-windows-x64
Uninstallable=yes
CloseApplications=no

[Tasks]
Name: "addpath"; Description: "Add opencode to your user PATH (lets you run 'opencode' from any terminal)"; GroupDescription: "Optional:"; Flags: checkedonce
Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"; GroupDescription: "{cm:AdditionalIcons}"; Flags: unchecked

[Files]
Source: "work\opencode-windows-x64\bin\opencode.exe"; DestDir: "{app}"; Flags: ignoreversion

[Icons]
Name: "{group}\OpenCode"; Filename: "{app}\opencode.exe"
Name: "{userdesktop}\OpenCode"; Filename: "{app}\opencode.exe"; Tasks: desktopicon

[Code]
const
  OC_WM_SETTINGCHANGE = $001A;
  OC_SMTO_ABORTIFHUNG = $0002;

procedure SendMessageTimeout(hWnd: HWND; Msg, wParam: LongInt;
  lParam: Cardinal; fuFlags, uTimeout: UINT;
  var lpdwResult: DWORD); external 'SendMessageTimeoutW@user32.dll stdcall';

procedure BroadcastSettingChange();
var
  Res: DWORD;
begin
  SendMessageTimeout(HWND_BROADCAST, OC_WM_SETTINGCHANGE, 0, 0,
    OC_SMTO_ABORTIFHUNG, 2000, Res);
end;

function PathContains(Paths, Path: string): Boolean;
begin
  Result := Pos(';' + Uppercase(Trim(Path)) + ';', ';' + Uppercase(Trim(Paths)) + ';') > 0;
end;

procedure EnvAddPath(Path: string);
var
  Paths: string;
begin
  if not RegQueryStringValue(HKEY_CURRENT_USER, 'Environment', 'Path', Paths) then
    Paths := '';
  if PathContains(Paths, Path) then
    Exit;
  if Paths <> '' then
    Paths := Trim(Paths) + ';';
  RegWriteStringValue(HKEY_CURRENT_USER, 'Environment', 'Path', Paths + Trim(Path));
  BroadcastSettingChange();
end;

procedure EnvRemovePath(Path: string);
var
  Paths: string;
  Entries: TStringList;
  Entry: string;
  I, Start, P: Integer;
  NewPaths: string;
begin
  if not RegQueryStringValue(HKEY_CURRENT_USER, 'Environment', 'Path', Paths) then
    Exit;
  Entries := TStringList.Create;
  try
    Start := 1;
    for I := 1 to Length(Paths) + 1 do
      if (I > Length(Paths)) or (Paths[I] = ';') then
      begin
        Entry := Trim(Copy(Paths, Start, I - Start));
        if (Entry <> '') then
          Entries.Add(Entry);
        Start := I + 1;
      end;
    NewPaths := '';
    for I := 0 to Entries.Count - 1 do
      if Uppercase(Entries[I]) <> Uppercase(Trim(Path)) then
      begin
        if NewPaths <> '' then
          NewPaths := NewPaths + ';';
        NewPaths := NewPaths + Entries[I];
      end;
    RegWriteStringValue(HKEY_CURRENT_USER, 'Environment', 'Path', NewPaths);
    BroadcastSettingChange();
  finally
    Entries.Free;
  end;
end;

procedure CurStepChanged(CurStep: TSetupStep);
begin
  if CurStep = ssPostInstall then
    if IsTaskSelected('addpath') then
      EnvAddPath(ExpandConstant('{app}'));
end;

procedure CurUninstallStepChanged(CurUninstallStep: TUninstallStep);
begin
  if CurUninstallStep = usPostUninstall then
  begin
    EnvRemovePath(ExpandConstant('{app}'));
    DeleteFile(ExpandConstant('{userdesktop}\OpenCode') + '.lnk');
  end;
end;
