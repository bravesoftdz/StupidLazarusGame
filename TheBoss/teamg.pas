unit teamg;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, FileUtil, Forms, Controls, Graphics, Dialogs, ExtCtrls,
  LCLType, ComCtrls, StdCtrls;

type

  { TMainForm }

  TMainForm = class(TForm)
    BonusClicker: TImage;
    Hero: TImage;
    Ground: TPanel;
    EventTimer: TTimer;
    AnimationTimer: TTimer;
    LabStat: TLabel;
    Sea: TPanel;
    procedure AnimationTimerTimer(Sender: TObject);
    procedure BonusClickerClick(Sender: TObject);
    procedure FormClose(Sender: TObject; var CloseAction: TCloseAction);
    procedure FormCreate(Sender: TObject);
    procedure FormKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure EventTimerTimer(Sender: TObject);
    procedure HeroClick(Sender: TObject);
    procedure MidTimerTimer(Sender: TObject);
  private
    { private declarations }
  public
    { public declarations }
  end;

var
  MainForm: TMainForm;
  Map: array [1..20] of TImage;
  Bonus: TImage;
  Dragger, Floor, ProgressBar: TImage;

implementation

{$R *.lfm}

{ TMainForm }

type
//Класс работник
  TObj = object
    name: string;
    anim: byte;
    pressure: integer;
    procedure init(n: string; a, p: shortint);
  end;

procedure TObj.init(n: string; a, p: shortint);
begin
  name := n;
  anim := a;
  pressure := p;
end;

var
  Map_TObj: array [1..20] of TObj;
  progress, goal: integer;
  free_tables, plants, workers, empty, machines: byte;
  level: byte;
  coffee, leaf: boolean;
  waterdown: byte;
  difficulty: byte;

procedure TMainForm.EventTimerTimer(Sender: TObject);
var i: integer;
begin
  //Обработка событий
  //Прогрессирование проекта
  for i := 1 to 20 do begin
    if Map_TObj[i].name = 'Worker' then begin
      //Если работник в нормальном состоянии, то он может и уставать, и входить в раж
      if (Map_TObj[i].pressure <= 15) and (Map_TObj[i].pressure >= -15) then begin
        progress := progress + 2;
        Map_TObj[i].pressure := Map_TObj[i].pressure + (random(3) - 1) * (8 - plants);
      end;
      //Если работник устает, то он постепенно засыпает
      if (Map_TObj[i].pressure <= -16) and (Map_TObj[i].pressure >= -25) then begin
        progress := progress + 1;
        Map_TObj[i].pressure := Map_TObj[i].pressure - 1;
      end;
      //Если работник входит в раж, то он становится агрессивным
      if (Map_TObj[i].pressure >= 16) and (Map_TObj[i].pressure <= 25) then begin
        progress := progress + 3;
        Map_TObj[i].pressure := Map_TObj[i].pressure + 1;
      end;
      //Работник уснул и бесполезен
      if Map_TObj[i].pressure < -25 then begin
        //
      end;
      //Работник в бешенстве и бесполезен, если не предпринят действий, то он взорвется
      if (Map_TObj[i].pressure > 25) and (Map_TObj[i].pressure < 40) then begin
        Map_TObj[i].pressure := Map_TObj[i].pressure + random(2);
      end;
      //Работник взрывается
      if Map_TObj[i].pressure >= 40 then begin
        Map_TObj[i].init('Blowup', 1, 0);
      end;
    end;
  end;
  //Приближение дедлайна
  if waterdown = 0 then begin
    Sea.Top := Sea.Top - 1;
    Sea.Height := Sea.Height + 1;
    if Sea.Top = ProgressBar.Top then begin
      //Конец игры
      EventTimer.Enabled := False;
      AnimationTimer.Enabled := False;
      MainForm.Color := clBlack;
      LabStat.Color := clWhite;
      LabStat.Caption := LabStat.Caption + sLineBreak + 'GAME OVER!';
    end;
  end;
end;

procedure TMainForm.HeroClick(Sender: TObject);
var i: integer;
begin
  //Обработка клика по объектам
  i := StrToInt((Sender as TImage).Hint);
  //Обработка стимулирования работников тычком
  if coffee = false then begin
    if (Map_TObj[i].name = 'Worker') and (Map_TObj[i].pressure < -15)
      then Map_TObj[i].pressure := Map_TObj[i].pressure + 2;
    if (Map_TObj[i].name = 'Worker') and (Map_TObj[i].pressure > 15)
      then Map_TObj[i].pressure := Map_TObj[i].pressure - 2;
  end;
  //Обработка стимулирования при помощи кофе
  if (Map_TObj[i].name = 'Worker') and (coffee = true) then begin
    Map_TObj[i].pressure := Map_TObj[i].pressure + 20;
    coffee := false;
    Dragger.Visible := False;
  end;
  //Обработка успокоения при помощи цветов
  if (Map_TObj[i].name = 'Worker') and (leaf = true) then begin
    Map_TObj[i].pressure := Map_TObj[i].pressure - 10;
    leaf := false;
    Dragger.Visible := False;
  end;
  //Обработка обращения к кофемашине
  if (Map_TObj[i].name = 'Coffee') and (leaf = false) then begin
    coffee := true;
    Dragger.Visible := True;
    Dragger.Picture.LoadFromFile('Cup.png');
  end;
  //Обработка обращения к горшку
  if (Map_TObj[i].name = 'Plant') and (coffee = false) then begin
    leaf := true;
    Dragger.Visible := True;
    Dragger.Picture.LoadFromFile('Leaf.png');
  end;
end;

procedure TMainForm.MidTimerTimer(Sender: TObject);
begin
end;

procedure TMainForm.FormKeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
  //Управление действиями игрока через клавиатуру
  {case key of
    VK_LEFT: Hero.Left:=Hero.Left-20;
    VK_RIGHT: Hero.Left:=Hero.Left+20;
  end;   }
end;

procedure TMainForm.FormCreate(Sender: TObject);
var what, i, k: shortint;
begin
  difficulty := 80;
  progress := 0;
  goal := 150;
  level := 0;
  free_tables := 0;
  workers := 0;
  plants := 0;
  empty := 0;
  machines := 0;
  randomize;
  //Генерация карты
  //Создание пола
  Floor := TImage.Create(Self);
  Floor.Parent := Self;
  Floor.Top := Ground.Top;
  Floor.Left := Ground.Left;
  Floor.Height := 35;
  Floor.Width := Ground.Width;
  Floor.Picture.LoadFromFile('Ground.png');
  //Создание полосы загрузки
  ProgressBar := TImage.Create(Self);
  ProgressBar.Parent := Self;
  ProgressBar.Top := Ground.Top + 35;
  ProgressBar.Left := Ground.Left;
  ProgressBar.Height := 35;
  ProgressBar.Width := 0;
  ProgressBar.Picture.LoadFromFile('ProgressBar.png');
  //Создание объектов: работников, пустых столов, кофемашин, горшков
  for i := 1 to 10 do begin
    what := random(30);
    Map[i] := TImage.Create(Self);
    Map[i].Parent := Self;
    Map[i].Left := Ground.Left + (i - 1) * 70;
    Map[i].Width := 70;
    Map[i].Top := Ground.Top - 70;
    Map[i].Height := 70;
    Map[i].Stretch := True;
    Map[i].Hint := IntToStr(i);
    Map[i].OnClick := Hero.OnClick;
    if not (what in [0..4]) then begin
      Map[i].Visible := True;
      if what in [5..8] then begin
        Map[i].Picture.LoadFromFile('Plant.png');
        Map_TObj[i].init('Plant', 0, 0);
        inc(plants);
      end;
      if what in [13..18] then begin
        Map[i].Picture.LoadFromFile('Table.png');
        Map_TObj[i].init('Table', 0, 0);
        inc(free_tables);
      end;
      if what in [19..29] then begin
        k := random(5) + 1;
        Map[i].Picture.LoadFromFile('Worker' + IntToStr(k) + '.png');
        Map_TObj[i].init('Worker', k, random(11) - 5);
        inc(workers);
      end;
      if what in [9..12] then begin
        Map[i].Picture.LoadFromFile('Coffee.png');
        Map_TObj[i].init('Coffee', 0, 0);
        inc(machines);
      end;
    end
    else begin
      Map_TObj[i].init('None', 0, 0);
      inc(empty);
    end;
  end;
  //Создание иконки кофе
  Dragger := TImage.Create(Self);
  Dragger.Parent := Self;
  Dragger.Width := 50;
  Dragger.Height := 50;
  Dragger.Stretch := True;
  Dragger.Visible := False;
  //Прегенерация бонусов
  for i := 1 to 3 do begin
    Bonus := TImage.Create(Self);
    Bonus.Parent := Self;
    Bonus.Width := 70;
    Bonus.Height := 70;
    Bonus.Left := 70;
    Bonus.Top := 0;
    Bonus.Stretch := True;
    Bonus.Visible := False;
    Bonus.OnClick := BonusClicker.OnClick;
  end;
end;

procedure TMainForm.AnimationTimerTimer(Sender: TObject);
var i: shortint;
    s: string;
begin
  //Заполнение полосы загрузки
  if progress >= goal then begin
    progress := 0;
    goal := goal + 25;
    inc(level);
    s := '';
    LabStat.Caption := 'Уровень: ' + IntToStr(level);
    //Выдача бонуса
      i := random(4);
      if (i = 0) and ((free_tables > 0) or (empty > 0)) then begin
         s := 'Worker';
         Bonus.Hint := '1';
      end;
      if (i = 1) and (empty > 0) then begin
         s := 'Coffee';
         Bonus.Hint := '2';
      end;
      if (i = 2) and (empty > 0) then begin
         s := 'Plant';
         Bonus.Hint := '3';
      end;
      if (s <> '') then begin
        Bonus.Visible := True;
        Bonus.Picture.LoadFromFile('Bonus' + s + '.png');
      end
      else begin
        Bonus.Visible := False;
      end;
      //При достижении нового уровня уровень воды опускается
      waterdown := trunc((125 - difficulty) / level);
  end;
  if waterdown > 0 then begin
      dec(waterdown);
      Sea.Top := Sea.Top + 1;
      Sea.Height := Sea.Height - 1;
  end;
  ProgressBar.Width := trunc(progress / goal * 700);
  //Обработка перетаскивания кофе или цветов
  Dragger.Left := Mouse.CursorPos.X - MainForm.Left - 20;
  Dragger.Top := Mouse.CursorPos.Y - MainForm.Top - 20;
  for i := 1 to 20 do begin
    if Map_TObj[i].name = 'Worker' then begin
      s := '';
      //Если работник устает, то он постепенно засыпает
      if (Map_TObj[i].pressure <= -16) and (Map_TObj[i].pressure >= -25) then s := 'Sleepy';
      //Если работник входит в раж, то он становится агрессивным
      if (Map_TObj[i].pressure >= 16) and (Map_TObj[i].pressure <= 25) then s := 'Angry';
      //Работник уснул и бесполезен
      if Map_TObj[i].pressure < -25 then s := 'Asleep';
      //Работник в бешенстве
      if Map_TObj[i].pressure > 25 then s := 'Mad';
      //Анимация работников
      Map_TObj[i].anim := Map_TObj[i].anim + 1;
      if Map_TObj[i].anim > 5 then Map_TObj[i].anim := 1;
      Map[i].Picture.LoadFromFile('Worker' + s + IntToStr(Map_TObj[i].anim) + '.png');
    end;
    //Работник начал взрываться
    if (Map_TObj[i].name = 'Blowup') and (Map_TObj[i].anim = 1) then begin
      Map[i].Picture.LoadFromFile('WorkerBlowup' + IntToStr(Map_TObj[i].anim) + '.png');
      Map_TObj[i].anim := Map_TObj[i].anim + 1;
      Map[i].Top := Map[i].Top - 70;
      Map[i].Height := Map[i].Height + 70;
    end;
    //Работник уже взорвался
    if (Map_TObj[i].name = 'Blowup') and (Map_TObj[i].anim > 5) then begin
      Map_TObj[i].init('Table', 0, 0);
      Map[i].Picture.LoadFromFile('Table.png');
      Map[i].Top := Map[i].Top + 70;
      Map[i].Height := Map[i].Height - 70;
      inc(free_tables);
      dec(workers);
    end;
    //Работник взрывается
    if (Map_TObj[i].name = 'Blowup') and (Map_TObj[i].anim <= 5) then begin
      Map[i].Picture.LoadFromFile('WorkerBlowup' + IntToStr(Map_TObj[i].anim) + '.png');
      Map_TObj[i].anim := Map_TObj[i].anim + 1;
    end;
  end;
  //Если не осталось работников, то игра заканчивается
  if workers = 0 then begin
      EventTimer.Enabled := False;
      AnimationTimer.Enabled := False;
      MainForm.Color := clBlack;
      LabStat.Color := clWhite;
      LabStat.Caption := LabStat.Caption + sLineBreak + 'GAME OVER!';
  end;
end;

procedure TMainForm.BonusClickerClick(Sender: TObject);
var i, k: integer;
    s: string;
begin
  //Бонус работник
  if (Sender as TImage).Hint = '1' then begin
    if free_tables > 0 then s := 'Table' //Сначала стараемся назначить рабочих за свободные столы
    else s := 'None'; //Если свободных столов нет, то будем искать пустые места
    for i := 1 to 20 do
      if (Map_TObj[i].name = s) then begin
          k := random(5) + 1;
          Map[i].Picture.LoadFromFile('Worker' + IntToStr(k) + '.png');
          Map_TObj[i].init('Worker', k, random(11) - 5);
          inc(workers);
          if s = 'Table' then dec(free_tables);
          if s = 'None' then dec(empty);
          (Sender as TImage).Visible := False;
          break;
      end
  end;
  //Бонус кофемашина
  if (Sender as TImage).Hint = '2' then begin
    for i := 1 to 20 do
      if Map_TObj[i].name = 'None' then begin
        Map[i].Picture.LoadFromFile('Coffee.png');
        Map_TObj[i].init('Coffee', 0, 0);
        inc(machines);
        dec(empty);
        (Sender as TImage).Visible := False;
        break;
      end;
  end;
  //Бонус растение
  if (Sender as TImage).Hint = '3' then begin
    for i := 1 to 20 do
      if Map_TObj[i].name = 'None' then begin
        Map[i].Picture.LoadFromFile('Plant.png');
        Map_TObj[i].init('Plant', 0, 0);
        inc(plants);
        dec(empty);
        (Sender as TImage).Visible := False;
        break;
      end;
  end;
end;

procedure TMainForm.FormClose(Sender: TObject; var CloseAction: TCloseAction);
begin
  //
end;

end.

