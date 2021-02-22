unit UnitHookDll;

interface

uses
  Windows, SysUtils, Classes, math, messages, vcl.dialogs,
  UnitNt2000Hook, AnsiStrings;

const
  fTextOutA = 0;
  fExtTextOutA = 1;
  fDrawTextA = 2;
  fSetDlgItemTextA = 3;
  fSetWindowTextA = 4;
  fTabbedTextOutA = 5;
  fMessageBoxA = 6;

const
  excludeStr: array [0 .. 3] of Ansistring = ('三國志Ⅷ', '', '', '');

var
  Hook: array [fTextOutA .. fMessageBoxA] of THookClass; { API HOOK类 }

procedure InitHook;
procedure UnInitHook;

implementation

function BIG5ToGB(BIG5Str: Ansistring; CHT: boolean = true): Ansistring;
var
  Len: Integer;
  PBIG5Char: PAnsiChar;
  PGBCHSChar: PAnsiChar;
  PGBCHTChar: PAnsiChar;
  PUniCodeChar: PWideChar;
begin
  // String -> PChar
  PBIG5Char := PAnsiChar(BIG5Str);
  Len := MultiByteToWideChar(950, 0, PBIG5Char, -1, nil, 0);
  GetMem(PUniCodeChar, Len * 2);
  ZeroMemory(PUniCodeChar, Len * 2);
  // Big5 -> UniCode
  MultiByteToWideChar(950, 0, PBIG5Char, -1, PUniCodeChar, Len);
  Len := WideCharToMultiByte(936, 0, PUniCodeChar, -1, nil, 0, nil, nil);
  GetMem(PGBCHTChar, Len * 2);
  GetMem(PGBCHSChar, Len * 2);
  ZeroMemory(PGBCHTChar, Len * 2);
  ZeroMemory(PGBCHSChar, Len * 2);
  // UniCode->GB CHT
  WideCharToMultiByte(936, 0, PUniCodeChar, -1, PGBCHTChar, Len, nil, nil);
  // GB CHT -> GB CHS
  LCMapStringA($804, LCMAP_SIMPLIFIED_CHINESE, PGBCHTChar, -1, PGBCHSChar, Len);

  // 保留繁體字還是轉換爲簡體字
  if CHT then
    Result := PGBCHTChar
  else
    Result := PGBCHSChar;
  // San8专用，将转换失败的字符改为点字符
  Result := AnsiReplacetext(Result, '?', '·');

  FreeMem(PGBCHTChar);
  FreeMem(PGBCHSChar);
  FreeMem(PUniCodeChar);
end;

function NewTextOutA(theDC: HDC; nXStart, nYStart: Integer; str: PAnsiChar; count: Integer): bool; stdcall;
type
  TTextOutA = function(theDC: HDC; nXStart, nYStart: Integer; str: PAnsiChar; count: Integer): bool; stdcall;
begin
  Hook[fTextOutA].UnHook; { 暂停截取API，恢复被截的函数 }
  try
    str := PAnsiChar(BIG5ToGB(Ansistring(str)));
    count := -1;
  finally
    { 调用被截的函数 }
    Result := TTextOutA(Hook[fTextOutA].OldFunction)(theDC, nXStart, nYStart, str, count);
  end;
  Hook[fTextOutA].Hook; { 重新截取API }
end;

function NewExtTextOutA(theDC: HDC; nXStart, nYStart: Integer; toOptions: Longint; rect: PRect; str: PAnsiChar;
  count: Longint; Dx: PInteger): bool; stdcall;
type
  TExtTextOutA = function(theDC: HDC; nXStart, nYStart: Integer; toOptions: Longint; rect: PRect; str: PAnsiChar;
    count: Longint; Dx: PInteger): bool; stdcall;
begin
  Hook[fExtTextOutA].UnHook; { 暂停截取API，恢复被截的函数 }
  try
    str := PAnsiChar(BIG5ToGB(Ansistring(str)));
    count := -1;
  finally
    { 调用被截的函数 }
    Result := TExtTextOutA(Hook[fExtTextOutA].OldFunction)(theDC, nXStart, nYStart, toOptions, rect, str, count, Dx);
  end;
  Hook[fExtTextOutA].Hook; { 重新截取API }
end;

function NewDrawTextA(theDC: HDC; lpString: PAnsiChar; nCount: Integer; var lpRect: TRect; uFormat: UINT)
  : Integer; stdcall;
type
  TDrawTextA = function(theDC: HDC; lpString: PAnsiChar; nCount: Integer; var lpRect: TRect; uFormat: UINT)
    : Integer; stdcall;
begin
  Hook[fDrawTextA].UnHook; { 暂停截取API，恢复被截的函数 }
  try
    lpString := PAnsiChar(BIG5ToGB(Ansistring(lpString)));
    nCount := -1;
  finally
    { 调用被截的函数 }
    Result := TDrawTextA(Hook[fDrawTextA].OldFunction)(theDC, lpString, nCount, lpRect, uFormat);
  end;
  Hook[fDrawTextA].Hook; { 重新截取API }
end;

function newSetDlgItemTextA(hDlg: HWND; nIDDlgItem: Integer; lpString: LPCSTR): bool; stdcall;
type
  TSetDlgItemTextA = function(hDlg: HWND; nIDDlgItem: Integer; lpString: LPCSTR): bool; stdcall;
begin
  Hook[fSetDlgItemTextA].UnHook; { 暂停截取API，恢复被截的函数 }
  try
    lpString := PAnsiChar(BIG5ToGB(Ansistring(lpString)));
  finally
    { 调用被截的函数 }
    Result := TSetDlgItemTextA(Hook[fDrawTextA].OldFunction)(hDlg, nIDDlgItem, lpString);
  end;
  Hook[fSetDlgItemTextA].Hook; { 重新截取API }
end;

function newSetWindowTextA(iHWND: HWND; lpString: LPCSTR): bool; stdcall;
type
  TSetWindowTextA = function(iHWND: HWND; lpString: LPCSTR): bool; stdcall;
begin
  Hook[fSetWindowTextA].UnHook; { 暂停截取API，恢复被截的函数 }
  try
    if not ContainsText(lpString, excludeStr[0]) then
      lpString := PAnsiChar(BIG5ToGB(Ansistring(lpString)));
  finally
    { 调用被截的函数 }
    Result := TSetWindowTextA(Hook[fSetWindowTextA].OldFunction)(iHWND, lpString);
  end;
  Hook[fSetWindowTextA].Hook; { 重新截取API }
end;

function newTabbedTextOutA(iHDC: HDC; X, Y: Integer; lpString: LPCSTR; nCount, nTabPositions: Integer;
  var lpnTabStopPositions; nTabOrigin: Integer): Longint; stdcall;
type
  TTabbedTextOutA = function(iHDC: HDC; X, Y: Integer; lpString: LPCSTR; nCount, nTabPositions: Integer;
    var lpnTabStopPositions; nTabOrigin: Integer): Longint; stdcall;
begin
  Hook[fTabbedTextOutA].UnHook; { 暂停截取API，恢复被截的函数 }
  try
    lpString := PAnsiChar(BIG5ToGB(Ansistring(lpString)));
  finally
    { 调用被截的函数 }
    Result := TTabbedTextOutA(Hook[fTabbedTextOutA].OldFunction)(iHDC, X, Y, lpString, nCount, nTabPositions,
      lpnTabStopPositions, nTabOrigin);
  end;
  Hook[fTabbedTextOutA].Hook; { 重新截取API }
end;

function newMessageBoxA(iHWND: HWND; lpText, lpCaption: LPCSTR; uType: UINT): Integer; stdcall;
type
  TMessageBoxA = function(iHWND: HWND; lpText, lpCaption: LPCSTR; uType: UINT): Integer; stdcall;
begin
  Hook[fMessageBoxA].UnHook; { 暂停截取API，恢复被截的函数 }
  try
    lpText := PAnsiChar(BIG5ToGB(Ansistring(lpText)));
    lpCaption := PAnsiChar(BIG5ToGB(Ansistring(lpCaption)));
  finally
    { 调用被截的函数 }
    Result := TMessageBoxA(Hook[fMessageBoxA].OldFunction)(iHWND, lpText, lpCaption, uType);
  end;
  Hook[fMessageBoxA].Hook; { 重新截取API }
end;

procedure InitHook;
begin
  Hook[fTextOutA] := THookClass.Create(@TextOutA, @NewTextOutA);
  Hook[fExtTextOutA] := THookClass.Create(@ExtTextOutA, @NewExtTextOutA);
  Hook[fDrawTextA] := THookClass.Create(@DrawTextA, @NewDrawTextA);

  Hook[fSetDlgItemTextA] := THookClass.Create(@SetDlgItemTextA, @newSetDlgItemTextA);
  Hook[fSetWindowTextA] := THookClass.Create(@SetWindowTextA, @newSetWindowTextA);
  Hook[fTabbedTextOutA] := THookClass.Create(@TabbedTextOutA, @newTabbedTextOutA);

  Hook[fMessageBoxA] := THookClass.Create(@MessageBoxA, @newMessageBoxA);
end;

procedure UnInitHook;
var
  I: Integer;
begin
  for I := Low(Hook) to High(Hook) do
  begin
    if assigned(Hook[I]) then
      FreeAndNil(Hook[I]);
  end;
end;

end.
