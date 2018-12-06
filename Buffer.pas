unit Buffer;

interface

uses
  Windows;

type
  TS_Buffer = class
  private
    ect: Longint;
    esv: Longint;
    hph: Cardinal;
    bdp: Pointer;

    function GetSize: Longint;
    function GetElement(Index: Longint): Pointer;
  public
    constructor Create;
    destructor Destroy; Override;

    property Size: Longint read GetSize;

    property Element[Index: Integer]: Pointer read GetElement; 

    procedure SetSize(Elements, UnitSize: Longint; Retain: Boolean);
  end;

implementation

const
  HEAP_GENERATE_EXCEPTIONS = $000004;
  HEAP_ZERO_MEMORY = $000008;
  HEAP_REALLOC_IN_PLACE_ONLY = $000010;

constructor TS_Buffer.Create;
begin
  inherited Create;
  hph := HeapCreate(HEAP_GENERATE_EXCEPTIONS, 0, 0);
  SetSize(0, 0, False);
end;

destructor TS_Buffer.Destroy;
begin
  HeapDestroy(hph);
  inherited Destroy;
end;

function TS_Buffer.GetSize: Longint;
begin
  Result := ect;
end;

function TS_Buffer.GetElement(Index: Longint): Pointer;
begin
  if (Index < 0) or (Index >= ect) then
    Result := nil
  else begin
    Result := bdp;
    Inc(PByte(Result), Index * esv);
  end;
end;

procedure TS_Buffer.SetSize(Elements, UnitSize: Longint; Retain: Boolean);
begin
  ect := Elements;
  esv := UnitSize;
  
  if Retain then
    bdp := HeapReAlloc(hph, HEAP_GENERATE_EXCEPTIONS or HEAP_ZERO_MEMORY, bdp, ect * esv)
  else begin
    HeapFree(hph, 0, bdp);
    bdp := HeapAlloc(hph, HEAP_GENERATE_EXCEPTIONS or HEAP_ZERO_MEMORY, ect * esv);
  end;
end;

end.
