unit Canvas;

interface

uses
  Windows;

type
  TS_BGRT = record
    case Integer of
    0: (B, G , R, T: Byte);
    1: (Value: Cardinal);
  end;
  PS_BGRT = ^TS_BGRT;

  TS_Canvas = class
  private
    bdc: HDC;
    bih: BITMAPINFOHEADER;
    hbm: HBITMAP;
    pbd: Pointer;

    procedure GetDataPointer;
    
    function GetWidth: Longint;
    procedure SetWidth(Value: Integer);
    function GetHeight: Longint;
    procedure SetHeight(Value: Integer);

    function GetPixel(x, y: Integer): PS_BGRT;
    function GetScanline(Line: Integer): PS_BGRT;
  public
    constructor Create;
    destructor Destroy; override;

    property Handle: HDC read bdc;

    property Width: Longint read GetWidth write SetWidth;
    property Height: Longint read GetHeight write SetHeight;

    property Pixel[x, y: Integer]: PS_BGRT read GetPixel;
    property Scanline[Line: Integer]: PS_BGRT read GetScanline; 

    procedure SetSize(x, y: Longint);
    procedure Fill(Color: TS_BGRT);
    procedure Transfer(Destination: HDC; x, y: Longint);
    procedure StretchOnto(Destination: HDC; x, y, width, height: Longint);
  end;

function ToBGRT(B, G, R, T: Byte): TS_BGRT; Overload;
function ToBGRT(Value: Cardinal): TS_BGRT; Overload;

const
  CS_Transparent: TS_BGRT =    (B:  0;G:  0;R:  0;T:  0);

  CS_Black: TS_BGRT =          (B:  0;G:  0;R:  0;T:255);

  CS_DarkGray: TS_BGRT =       (B: 24;G: 24;R: 24;T:255);

  CS_Blue: TS_BGRT =           (B:255;G:  0;R:  0;T:255);
  CS_Green: TS_BGRT =          (B:  0;G:255;R:  0;T:255);
  CS_Red: TS_BGRT =            (B:  0;G:  0;R:255;T:255);

  CS_Yellow: TS_BGRT =         (B:  0;G:255;R:255;T:255);
  CS_Purple: TS_BGRT =         (B:255;G:  0;R:255;T:255);
  CS_Aqua: TS_BGRT =           (B:255;G:255;R:  0;T:255);

  CS_White: TS_BGRT =          (B:255;G:255;R:255;T:255);

implementation

function ToBGRT(B, G, R, T: Byte): TS_BGRT; 
begin
  Result.B := B;
  Result.G := G;
  Result.R := R;
  Result.T := T;
end;

function ToBGRT(Value: Cardinal): TS_BGRT;
begin
  Result.Value := Value;
end;

constructor TS_Canvas.Create;
begin
  inherited Create;
  with bih do begin
    biSize := SizeOf(BITMAPINFOHEADER);
    biWidth := 0;
    biHeight := 0;
    biPlanes := 1;
    biBitCount := 32;
    biCompression := BI_RGB;
    biSizeImage := 0;
    biXPelsPerMeter := 0;
    biYPelsPerMeter := 0;
    biClrUsed := 0;
    biClrImportant := 0;
  end;
end;

destructor TS_Canvas.Destroy;
begin
  DeleteDC(bdc);
  DeleteObject(hbm);
  inherited Destroy;
end;

procedure TS_Canvas.GetDataPointer;
var
  tbi: BITMAPINFO;
begin
  DeleteDC(bdc);
  DeleteObject(hbm);
  tbi.bmiHeader := bih;
  bdc := CreateCompatibleDC(0);
  hbm := CreateDIBSection(bdc, tbi, DIB_RGB_COLORS, pbd, 0, 0);
  Inc(PS_BGRT(pbd), bih.biWidth * (bih.biHeight - 1));
  SelectObject(bdc, hbm);
end;

function TS_Canvas.GetWidth: Longint;
begin
  Result := bih.biWidth;
end;

procedure TS_Canvas.SetWidth(Value: Integer);
begin
  bih.biWidth := Value;
  GetDataPointer;
end;

function TS_Canvas.GetHeight: Longint;
begin
  Result := bih.biHeight;
end;

procedure TS_Canvas.SetHeight(Value: Integer);
begin
  bih.biHeight := Value;
  GetDataPointer;
end;

function TS_Canvas.GetPixel(x, y: Integer): PS_BGRT;
begin
  if (x < 0) or (x >= bih.biWidth) or (y < 0) or (y >= bih.biHeight) then
    Result := nil
  else begin
    Result := PS_BGRT(pbd);
    Dec(Result, bih.biWidth * y - x);
  end;
end;

function TS_Canvas.GetScanline(Line: Integer): PS_BGRT;
begin
  if (Line < 0) or (Line >= bih.biHeight) then
    Result := nil
  else begin
    Result := PS_BGRT(pbd);
    Dec(Result, bih.biWidth * Line);
  end;
end;

procedure TS_Canvas.SetSize(x, y: Longint);
begin
  bih.biWidth := x;
  bih.biHeight := y;
  GetDataPointer;
end;

procedure TS_Canvas.Fill(Color: TS_BGRT);
var
  x, y: Integer;
  ColorAt: PS_BGRT;
begin
  for y := 0 to bih.biHeight - 1 do begin
    ColorAt := GetScanline(y);
    for x := 0 to bih.biWidth - 1 do begin
      ColorAt^ := Color;
      Inc(ColorAt);
    end;
  end;
end;

procedure TS_Canvas.Transfer(Destination: HDC; x, y: Longint);
begin
  // Don't check for errors
  BitBlt(Destination, x, y, bih.biWidth, bih.biHeight, bdc, 0, 0, SRCCOPY);
end;

procedure TS_Canvas.StretchOnto(Destination: HDC; x, y, width, height: Longint);
begin
  StretchBlt(Destination, x, y, width, height, bdc, 0, 0, bih.biWidth, bih.biHeight, SRCCOPY);
end;

{procedure TS_ExtendedCanvas.Line(Color: TS_BGRT; a, b: Vector2D);
var
  dx, dy, e, err, sx, sy: Integer;
  p: PS_BGRT;
begin
  dx := b.x - a.x;
  sx := Sign(dx);
  dx := Abs(dx);

  dy := b.y - a.y;
  sy := Sign(dy);
  dy := -Abs(dy);

  err := dx + dy;

  while True do begin
    p := Pixel[a.x, a.y];
    if p <> nil then
      p^ := Color;

    if (a.x = b.x) and (a.y = b.y) then
      Break;

    e := 2 * err;
    if e >= dy then begin
      Inc(err, dy);
      Inc(a.x, sx);
    end;
    if e <= dx then begin
      Inc(err, dx);
      Inc(a.y, sy);
    end;
  end;
end;

function AlphaBlend(Background, Foreground: TS_BGRT; Opacity: Byte): TS_BGRT;
var
  AdjustedOpacity: Integer;
begin
  AdjustedOpacity := Opacity + 1;                            // sar is being used by compiler, yay 
  Result.B := ((Foreground.B - Background.B) * AdjustedOpacity) div 256 + Background.B;
  Result.G := ((Foreground.G - Background.G) * AdjustedOpacity) div 256 + Background.G;
  Result.R := ((Foreground.R - Background.R) * AdjustedOpacity) div 256 + Background.R;
end;

procedure TS_ExtendedCanvas.LineAA(Color: TS_BGRT; a, b: Vector2D);
var
  dx, dy, e, err, sx, sy, ed, xc: Integer;
  p: PS_BGRT;
begin
  dx := b.x - a.x;
  sx := Sign(dx);
  dx := Abs(dx);

  dy := b.y - a.y;
  sy := Sign(dy);
  dy := Abs(dy);

  err := dx - dy;

  if dx + dy = 0 then
    ed := 1
  else
    ed := Floor(Sqrt((dx * dx) + (dy * dy)));

  while True do begin
    p := Pixel[a.x, a.y];
    if p <> nil then
      p^ := AlphaBlend(Color, p^, 255 * Abs(err - dx + dy) div ed);

    e := err;
    xc := a.x;

    if 2 * e >= -dx then begin
      if a.x = b.x then
        Break;
      if e + dy < ed then begin
        p := Pixel[a.x, a.y + sy];
        if p <> nil then
          p^ := AlphaBlend(Color, p^, 255 * (e + dy) div ed);
      end;
      Dec(err, dy);
      Inc(a.x, sx);
    end;

    if 2 * e <= dy then begin
      if a.y = b.y then
        Break;
      if dx - e < ed then begin
        p := Pixel[xc + sx, a.y];
        if p <> nil then
          p^ := AlphaBlend(Color, p^, 255 * (dx - e) div ed);
      end;
      Inc(err, dx);
      Inc(a.y, sy);
    end;
  end;
end;   }

end.
