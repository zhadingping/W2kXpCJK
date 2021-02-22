unit W2kXpCJKUnit;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, PsAPI, Vcl.ExtCtrls, TLhelp32, inifiles, Vcl.Grids;

type
  TMainFrm = class(TForm)
    GameExe: TLabeledEdit;
    SelectGame: TButton;
    StartGame: TButton;
    SelectGMdlg: TOpenDialog;
    procedure SelectGameClick(Sender: TObject);
    procedure StartGameClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  MainFrm: TMainFrm;
  dwProcessId, hProcess: DWORD;

  setinifile: TInifile; // 配制文件；

type
  TCheckGM = class(TThread)
  protected
    procedure Execute; override;
  end;

implementation

{$R *.dfm}

function GetProcessNameById(const AID: Integer): String;
var
  h: thandle;
  f: boolean;
  lppe: tprocessentry32;
begin
  Result := '';
  h := CreateToolhelp32Snapshot(TH32cs_SnapProcess, 0);
  lppe.dwSize := sizeof(lppe);
  f := Process32First(h, lppe);
  while Integer(f) <> 0 do
  begin
    if Integer(lppe.th32ProcessID) = AID then
    begin
      Result := StrPas(lppe.szExeFile);
      break;
    end;
    f := Process32Next(h, lppe);
  end;
end;

procedure TMainFrm.FormCreate(Sender: TObject);
var
  filename: string;
begin
  filename := ChangeFileExt(Application.ExeName, '.ini');
  setinifile := TInifile.Create(filename);
  try
    GameExe.Text := setinifile.ReadString('GameName', 'ExeFile', 'San8.exe');
  finally
    setinifile.Free;
  end;
end;

procedure TMainFrm.SelectGameClick(Sender: TObject);
begin
  SelectGMdlg.filename := GameExe.Text;
  if SelectGMdlg.Execute then
    GameExe.Text := SelectGMdlg.filename;
end;

procedure TMainFrm.StartGameClick(Sender: TObject);
var
  h, dwExitCode: longword; // 放句柄,中间顺便暂放下PID
  hThread: thandle;
  DllName: string;
  len, num: size_t; // 放字符串长度
  Parameter, StartAddress: pointer; // 放那个参数的指针(位置在目标进程内)

  StartupInfo: TStartupInfo;
  ProcessInfo: TProcessInformation;

  filename: string;

begin
  DllName := GetCurrentDir + '\APIHook.dll';
  len := length(DllName) * 2 + 1;

  FillChar(StartupInfo, sizeof(StartupInfo), #0);
  StartupInfo.cb := sizeof(StartupInfo);
  StartupInfo.dwFlags := STARTF_USEPOSITION;
  if createProcess(PChar(GameExe.Text), nil, nil, nil, False, Create_New_Console or Normal_Priority_Class, nil,
    PChar(ExtractFilePath(GameExe.Text)), StartupInfo, ProcessInfo) then
  begin
    // 进程ID
    dwProcessId := ProcessInfo.dwProcessId;
    // 进程句柄
    hProcess := ProcessInfo.hProcess;
  end
  else
  begin
    showmessage('启动游戏失败，请确认选择了正确的游戏主程序。');
    Exit;
  end;

  h := OpenProcess(PROCESS_ALL_ACCESS, False, dwProcessId);
  Parameter := VirtualAllocEx(h, nil, len, MEM_COMMIT, PAGE_READWRITE);
  if (not WriteProcessMemory(h, Parameter, pointer(PChar(DllName)), len, num)) or (len <> num) then
  begin
    VirtualFreeEx(h, Parameter, len + 1, MEM_RELEASE);
    CloseHandle(h);
    self.caption := '游戏空间写入参数失败，可能程序权限不够。';
    Exit;
  end;

  StartAddress := GetProcAddress(GetModuleHandle('Kernel32'), 'LoadLibraryW');
  hThread := CreateRemoteThread(h, nil, 0, StartAddress, Parameter, 0, DWORD(num));
  if hThread = 0 then
  begin
    VirtualFreeEx(h, Parameter, len + 1, MEM_RELEASE);
    CloseHandle(h);
    self.caption := '启动远程线程失败！';
    Exit;
  end;

  TCheckGM.Create(False);

  // 等候线程结束
  dwExitCode := WaitForSingleObject(hThread, INFINITE);
  if dwExitCode = WAIT_OBJECT_0 then
  begin
    dwExitCode := 0;
    GetExitCodeThread(hThread, dwExitCode);
    if dwExitCode <> 0 then
    begin
      self.caption := '游戏化繁为简 - ' + GetProcessNameById(dwProcessId);

      StartGame.Enabled := False;

      filename := ChangeFileExt(Application.ExeName, '.ini');
      setinifile := TInifile.Create(filename);
      try
        if not(GameExe.Text = setinifile.ReadString('GameName', 'ExeFile', 'San8.exe')) then
          setinifile.writeString('GameName', 'ExeFile', GameExe.Text);
      finally
        setinifile.Free;
      end;
    end
    else
    begin
      self.caption := '注入失败';
    end;
  end;

  VirtualFreeEx(h, Parameter, len + 1, MEM_RELEASE);
end;

procedure TCheckGM.Execute;
var
  status: DWORD;
begin
  FreeOnTerminate := true;
  status := WaitForSingleObject(hProcess, INFINITE);
  if (status = WAIT_OBJECT_0) or (status = WAIT_FAILED) then
  begin
    MainFrm.caption := '游戏繁简码转换大师';
    MainFrm.StartGame.Enabled := true;
  end;
end;

end.
