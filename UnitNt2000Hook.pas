unit UnitNt2000Hook;

interface

uses
  Windows, PsAPI;

type
  TImportCode = packed record
    JumpInstruction: Word;
    AddressOfPointerToFunction: PPointer;
  end;

  PImportCode = ^TImportCode;

  TLongJMP = packed record
    MovEax: Byte;
    FuncAddr: DWORD; { ������ַ }
    JMPCode: Word; { ָ���$E9������ϵͳ��ָ�� }
    dwReserved: Byte;
  end;

  THookClass = class
  private
    hProcess: Cardinal; { ���̾�� }
    AlreadyHook: boolean; { �Ƿ��Ѱ�װHook }
    Oldcode: array [0 .. sizeof(TLongJMP) - 1] of Byte; { ϵͳ����ԭ����ǰ5���ֽ� }
    Newcode: TLongJMP; { ��Ҫд��ϵͳ������ǰ5���ֽ� }
  public
    OldFunction, NewFunction: Pointer; { ���غ������Զ��庯�� }
    constructor Create(OldFun, NewFun: Pointer);
    destructor Destroy; override;
    procedure UnHook;
    procedure Hook;
  end;

function FinalFunctionAddress(Code: Pointer): Pointer; stdcall;

implementation

{ ȡ������ʵ�ʵ�ַ����������ĵ�һ��ָ����JMP����ȡ��������ת��ַ��ʵ�ʵ�ַ���������������ڳ����к���Debug������Ϣ����� }
function FinalFunctionAddress(Code: Pointer): Pointer; stdcall;
Var
  func: PImportCode;
begin
  Result := Code;
  if Code = nil then
    exit;
  try
    func := Code;
    if (func.JumpInstruction = $25FF) then
      { ָ���������FF 25  ���ָ��jmp [...] }
      func := func.AddressOfPointerToFunction^;
    Result := func;
  except
    Result := nil;
  end;
end;

{ HOOK����� }
constructor THookClass.Create(OldFun, NewFun: Pointer);
begin
  { �󱻽غ������Զ��庯����ʵ�ʵ�ַ }
  OldFunction := FinalFunctionAddress(OldFun);
  NewFunction := FinalFunctionAddress(NewFun);

  { ����Ȩ�ķ�ʽ���򿪵�ǰ���� }
  hProcess := OpenProcess(PROCESS_ALL_ACCESS, FALSE, GetCurrentProcessID);
  { ����jmp xxxx�Ĵ��룬��8�ֽ� }
  Newcode.MovEax := $B8;
  Newcode.JMPCode := $E0FF;
  Newcode.FuncAddr := DWORD(NewFunction);
  { ���汻�غ�����ǰ5���ֽ� }
  move(OldFunction^, Oldcode, sizeof(TLongJMP));
  { ����Ϊ��û�п�ʼHOOK }
  AlreadyHook := FALSE;
  Hook;
end;

{ HOOK�ĳ��� }
destructor THookClass.Destroy;
begin
  UnHook; { ֹͣHOOK }
  CloseHandle(hProcess);
  inherited;
end;

{ ��ʼHOOK }
procedure THookClass.Hook;
var
  nCount: SIZE_T;
begin
  if (AlreadyHook) or (hProcess = 0) or (OldFunction = nil) or
    (NewFunction = nil) then
    exit;
  AlreadyHook := true; { ��ʾ�Ѿ�HOOK }
  WriteProcessMemory(hProcess, OldFunction, @(Newcode),
    sizeof(TLongJMP), nCount);
end;

{ �ָ�ϵͳ�����ĵ��� }
procedure THookClass.UnHook;
var
  nCount: SIZE_T;
begin
  if (not AlreadyHook) or (hProcess = 0) or (OldFunction = nil) or
    (NewFunction = nil) then
    exit;
  WriteProcessMemory(hProcess, OldFunction, @(Oldcode),
    sizeof(TLongJMP), nCount);
  AlreadyHook := FALSE; { ��ʾ�˳�HOOK }
end;

end.
