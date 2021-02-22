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
    FuncAddr: DWORD; { 函数地址 }
    JMPCode: Word; { 指令，用$E9来代替系统的指令 }
    dwReserved: Byte;
  end;

  THookClass = class
  private
    hProcess: Cardinal; { 进程句柄 }
    AlreadyHook: boolean; { 是否已安装Hook }
    Oldcode: array [0 .. sizeof(TLongJMP) - 1] of Byte; { 系统函数原来的前5个字节 }
    Newcode: TLongJMP; { 将要写在系统函数的前5个字节 }
  public
    OldFunction, NewFunction: Pointer; { 被截函数、自定义函数 }
    constructor Create(OldFun, NewFun: Pointer);
    destructor Destroy; override;
    procedure UnHook;
    procedure Hook;
  end;

function FinalFunctionAddress(Code: Pointer): Pointer; stdcall;

implementation

{ 取函数的实际地址。如果函数的第一个指令是JMP，则取出它的跳转地址（实际地址），这往往是由于程序中含有Debug调试信息引起的 }
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
      { 指令二进制码FF 25  汇编指令jmp [...] }
      func := func.AddressOfPointerToFunction^;
    Result := func;
  except
    Result := nil;
  end;
end;

{ HOOK的入口 }
constructor THookClass.Create(OldFun, NewFun: Pointer);
begin
  { 求被截函数、自定义函数的实际地址 }
  OldFunction := FinalFunctionAddress(OldFun);
  NewFunction := FinalFunctionAddress(NewFun);

  { 以特权的方式来打开当前进程 }
  hProcess := OpenProcess(PROCESS_ALL_ACCESS, FALSE, GetCurrentProcessID);
  { 生成jmp xxxx的代码，共8字节 }
  Newcode.MovEax := $B8;
  Newcode.JMPCode := $E0FF;
  Newcode.FuncAddr := DWORD(NewFunction);
  { 保存被截函数的前5个字节 }
  move(OldFunction^, Oldcode, sizeof(TLongJMP));
  { 设置为还没有开始HOOK }
  AlreadyHook := FALSE;
  Hook;
end;

{ HOOK的出口 }
destructor THookClass.Destroy;
begin
  UnHook; { 停止HOOK }
  CloseHandle(hProcess);
  inherited;
end;

{ 开始HOOK }
procedure THookClass.Hook;
var
  nCount: SIZE_T;
begin
  if (AlreadyHook) or (hProcess = 0) or (OldFunction = nil) or
    (NewFunction = nil) then
    exit;
  AlreadyHook := true; { 表示已经HOOK }
  WriteProcessMemory(hProcess, OldFunction, @(Newcode),
    sizeof(TLongJMP), nCount);
end;

{ 恢复系统函数的调用 }
procedure THookClass.UnHook;
var
  nCount: SIZE_T;
begin
  if (not AlreadyHook) or (hProcess = 0) or (OldFunction = nil) or
    (NewFunction = nil) then
    exit;
  WriteProcessMemory(hProcess, OldFunction, @(Oldcode),
    sizeof(TLongJMP), nCount);
  AlreadyHook := FALSE; { 表示退出HOOK }
end;

end.
