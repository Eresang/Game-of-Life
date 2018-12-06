program GoL;

uses
  Forms,
  DisplayForm in 'DisplayForm.pas' {Display};

{$R *.res}

begin
  Application.Initialize;
  Application.Title := 'Game of Life';
  Application.CreateForm(TDisplay, Display);
  Application.Run;
end.
