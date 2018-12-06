unit DisplayForm;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, ExtCtrls, Math, Game_of_Life;

type
  TDisplay = class(TForm)
    DisplayBox: TPaintBox;
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure DisplayBoxPaint(Sender: TObject);
    procedure FormKeyPress(Sender: TObject; var Key: Char);
    procedure DisplayBoxMouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
    procedure DisplayBoxMouseUp(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
    procedure DisplayBoxMouseMove(Sender: TObject; Shift: TShiftState; X, Y: Integer);
    procedure FormKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
  private
    pGoL: TS_Game_of_Life;
    pGeneration, pX, pY: Integer;
    pDown, pLeft: Boolean;
    pF, pL: Int64;
  public

  end;

var
  Display: TDisplay;

var
  Factor: Integer = 3;

implementation

{$R *.dfm}

procedure TDisplay.FormCreate(Sender: TObject);
begin
  ControlStyle := ControlStyle + [csOpaque];
  DoubleBuffered := True;

  pGoL := TS_Game_of_Life.Create;
  pGoL.SetSize(ClientWidth div (1 shl Factor), ClientHeight div (1 shl Factor));
  pGoL.Clear;

  QueryPerformanceFrequency(pF);

  pGeneration := 0;

  Caption := 'Game of Life - [x: ' + IntToStr(pGoL.Width) + '; y: ' + IntToStr(pGoL.Height) + '; Generation: ' + IntToStr(pGeneration) + '; Zoom: ' + IntToStr(Factor);
  if pGoL.Wrap then
    Caption := Caption + '; Wrap';
  if (pL <> 0) then
    Caption := Caption + '; Time: ' + FormatFloat('###0.000', (pL * 1000) / pF);
  Caption := Caption + ']';
end;

procedure TDisplay.FormDestroy(Sender: TObject);
begin
  pGoL.Free;
end;

procedure TDisplay.DisplayBoxPaint(Sender: TObject);
begin
  pGoL.Canvas.StretchOnto(DisplayBox.Canvas.Handle, 0, 0, ClientWidth, ClientHeight);
end;

procedure TDisplay.FormKeyPress(Sender: TObject; var Key: Char);
var
  l1, l2: Int64;

  function FindHighestPowerOf2(Input: Integer): Integer;
  var
    i: Integer;
  begin
    Result := -1;
    i := Input;
    while (i > 0) do begin
      i := i shr 1;
      Inc(Result);
    end;
  end;
begin
  QueryPerformanceCounter(l1);

  case Key of
  Char(VK_RETURN):
    begin
      pGoL.Randomize(False, 0);
      DisplayBox.Invalidate;
      DisplayBox.Update;

      pGeneration := 0;
    end;

  Char(VK_SPACE):
    begin
      pGoL.Generate;
      DisplayBox.Invalidate;
      DisplayBox.Update;

      Inc(pGeneration);
    end;

  Char('+'):
    begin
      Factor := Min(Factor + 1, FindHighestPowerOf2(Min(ClientWidth, ClientHeight)));
      pGoL.SetSize(ClientWidth div (1 shl Factor), ClientHeight div (1 shl Factor));
      pGoL.Clear;
      DisplayBox.Invalidate;
      DisplayBox.Update;

      pGeneration := 0;
    end;

  Char('-'):
    begin
      Factor := Max(0, Factor - 1);
      pGoL.SetSize(ClientWidth div (1 shl Factor), ClientHeight div (1 shl Factor));
      pGoL.Clear;
      DisplayBox.Invalidate;
      DisplayBox.Update;

      pGeneration := 0;
    end;
  end;

  QueryPerformanceCounter(l2);

  Caption := 'Game of Life - [x: ' + IntToStr(pGoL.Width) + '; y: ' + IntToStr(pGoL.Height) + '; Generation: ' + IntToStr(pGeneration) + '; Zoom: ' + IntToStr(Factor);
  if pGoL.Wrap then
    Caption := Caption + '; Wrap';

  pL := l2 - l1;

  if (pL <> 0) then
    Caption := Caption + '; Time: ' + FormatFloat('###0.000', (pL * 1000) / pF);

  Caption := Caption + ']';
end;

procedure TDisplay.DisplayBoxMouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  pX := X * pGoL.Width div ClientWidth;
  pY := Y * pGoL.Height div ClientHeight;

  pLeft := Button = mbLeft;
  pGoL.Flip(pX, pY, pLeft);
  pDown := True;

  DisplayBox.Invalidate;
  DisplayBox.Update;
end;

procedure TDisplay.DisplayBoxMouseUp(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  pX := -1;
  pY := -1;

  pDown := False;
end;

procedure TDisplay.DisplayBoxMouseMove(Sender: TObject; Shift: TShiftState; X, Y: Integer);
begin
  if pDown and ((pX <> X * pGoL.Width div ClientWidth) or (pY <> Y * pGoL.Height div ClientHeight)) then begin
    pX := X * pGoL.Width div ClientWidth;
    pY := Y * pGoL.Height div ClientHeight;

    pGoL.Flip(pX, pY, pLeft);
    
    DisplayBox.Invalidate;
    DisplayBox.Update;
  end;
end;

procedure TDisplay.FormKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
begin
  case Char(Key) of
  Char('1')..Char('9'):
    begin
      if not (ssShift in Shift) then begin
        pGoL.LoadFromFile(Char(Key) + '.gol');
        pGoL.Load;
        DisplayBox.Invalidate;
        DisplayBox.Update;

        pGeneration := 0;
      end else begin
        pGoL.Save;
        pGoL.SaveToFile(Char(Key) + '.gol');
      end;
    end;

  Char('W'):
    begin
      pGoL.Wrap := not pGoL.Wrap;
    end;

  Char('S'):
    begin
      pGoL.Save;
    end;

  Char('L'):
    begin
      pGoL.Load;
      DisplayBox.Invalidate;
      DisplayBox.Update;

      pGeneration := 0;
    end;
  Char(VK_ESCAPE):
    begin
      pGoL.Clear;
      DisplayBox.Invalidate;
      DisplayBox.Update;

      pGeneration := 0;
    end;
  end;

  Caption := 'Game of Life - [x: ' + IntToStr(pGoL.Width) + '; y: ' + IntToStr(pGoL.Height) + '; Generation: ' + IntToStr(pGeneration) + '; Zoom: ' + IntToStr(Factor);
  if pGoL.Wrap then
    Caption := Caption + '; Wrap';
  if (pL <> 0) then
    Caption := Caption + '; Time: ' + FormatFloat('###0.000', (pL * 1000) / pF);
  Caption := Caption + ']';
end;

end.
