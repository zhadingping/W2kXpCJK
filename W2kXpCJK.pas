unit W2kXpCJK;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, PsAPI, Vcl.ExtCtrls, TLhelp32;

type
  TMainFrm = class(TForm)
    GameExe: TLabeledEdit;
    SelectGame: TButton;
    StartGame: TButton;
    SelectGMdlg: TOpenDialog;
    procedure SelectGameClick(Sender: TObject);
    procedure StartGameClick(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  MainFrm: TMainFrm;
  dwProcessId, hProcess: DWORD;

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

procedure TMainFrm.SelectGameClick(Sender: TObject);
begin
  SelectGMdlg.FileName := GameExe.Text;
  if SelectGMdlg.Execute then
    GameExe.Text := SelectGMdlg.FileName;
end;

procedure TMainFrm.StartGameClick(Sender: TObject);
var
  h, ExitCode: longword; // �ž��,�м�˳���ݷ���PID
  iHWnd: HWND;
  DllName: string;
  len, num: size_t; // ���ַ�������
  Parameter, StartAddress: pointer; // ���Ǹ�������ָ��(λ����Ŀ�������)

  StartupInfo: TStartupInfo;
  ProcessInfo: TProcessInformation;

begin
  DllName := GetCurrentDir + '\APIHook.dll';
  len := length(DllName) * 2 + 1;

  FillChar(StartupInfo, sizeof(StartupInfo), #0);
  StartupInfo.cb := sizeof(StartupInfo);
  StartupInfo.dwFlags := STARTF_USEPOSITION;
  if createProcess(PChar(GameExe.Text), nil, nil, nil, False,
    Create_New_Console or Normal_Priority_Class, nil,
    PChar(ExtractFilePath(GameExe.Text)), StartupInfo, ProcessInfo) then
  begin
    dwProcessId := ProcessInfo.dwProcessId;
    hProcess := ProcessInfo.hProcess;
  end
  else
  begin
    showmessage('������Ϸʧ�ܣ���ȷ��ѡ������ȷ����Ϸ������');
    Exit;
  end;

  h := OpenProcess(PROCESS_ALL_ACCESS, False, dwProcessId);
  Parameter := VirtualAllocEx(h, nil, len, MEM_COMMIT, PAGE_READWRITE);
  if (not WriteProcessMemory(h, Parameter, pointer(PChar(DllName)), len, num))
    or (len <> num) then
  begin
    VirtualFreeEx(h, Parameter, len + 1, MEM_RELEASE);
    CloseHandle(h);
    Exit;
  end;

  StartAddress := GetProcAddress(GetModuleHandle('Kernel32'), 'LoadLibraryW');
  iHWnd := CreateRemoteThread(h, nil, 0, StartAddress, Parameter, 0,
    DWORD(num));
  if iHWnd = 0 then
  begin
    VirtualFreeEx(h, Parameter, len + 1, MEM_RELEASE);
    CloseHandle(h);
    self.caption := '����Զ���߳�ʧ�ܣ�';
    Exit;
  end;

  TCheckGM.Create(False);

  // �Ⱥ��߳̽���
  WaitForSingleObject(iHWnd, INFINITE);
  GetExitCodeThread(iHWnd, ExitCode);
  if ExitCode <> 0 then
  begin
    self.caption := '��Ϸ����Ϊ�� - ' + GetProcessNameById(dwProcessId);
  end
  else
  begin
    self.caption := 'ע��ʧ��';
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
    MainFrm.caption := '��Ϸ������ת����ʦ';
  end;
end;

end.
