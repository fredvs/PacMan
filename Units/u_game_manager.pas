unit u_game_manager;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils,
  OGLCScene;

type

{ TGameManager }

TGameManager = class(TOGLCSaveDirectory)
private // saved data
  FHighScore: integer;
  FKeyLeft, FKeyRight, FKeyUp, FKeyDown, FKeyPause: word;
  procedure InitDefaultSavedData;
private // volatile data
  FCurrentLevel: integer;
  FDotEaten: integer;
  FElroyLevel: integer;
  FPlayerLife: integer;
  FPlayerScore: integer;
  FGhostEatenBonusIndex: integer;
  FRetroMode: boolean;
  FScoreThresholdForExtraLife: array of integer;
  FExtraLifeThresholdIndex, FGameDifficulty: integer;
  FNeedToAddExtraLife: boolean;
  function GetNeedToAddExtraLife: boolean;
  procedure SetPlayerScore(AValue: integer);
  procedure InitFScoreThresholdForExtraLife;
  procedure SetRetroMode(AValue: boolean);
public
  constructor Create;

public // saved data
  property HighScore: integer read FHighScore write FHighScore;
  property KeyLeft: word read FKeyLeft write FKeyLeft;
  property KeyRight: word read FKeyRight write FKeyRight;
  property KeyUp: word read FKeyUp write FKeyUp;
  property KeyDown: word read FKeyDown write FKeyDown;
  property KeyPause: word read FKeyPause write FKeyPause;
  procedure Save;
  procedure Load;

public // volatile data
  procedure InitForNewGame;
  procedure InitForNextStage;
  procedure InitAfterLoseLife;

  property PlayerScore: integer read FPlayerScore write SetPlayerScore;
  property PlayerLife: integer read FPlayerLife write FPlayerLife;
  // True when an extra life is winned. Reset to False when read
  property NeedToAddExtraLife: boolean read GetNeedToAddExtraLife;
  // 0 = 1 extra life (original)  1 = 2 extra life
  property GameDifficulty: integer read FGameDifficulty write FGameDifficulty;
  // 1 based
  property CurrentLevel: integer read FCurrentLevel write FCurrentLevel;
  property DotEaten: integer read FDotEaten write FDotEaten;
  // 0 or 1 or 2
  property ElroyLevel: integer read FElroyLevel write FElroyLevel;

  procedure ApplyRetroModeIfNeeded;
  // True to pixelize the game
  property RetroMode: boolean read FRetroMode write SetRetroMode;

public // game parameters
  function GetScoreForExtraLife: integer;
  function GetFruitTextureIndex: integer;
  function GetFruitBonusPoint: integer;
  function GetPacmanSpeedValue: single;
  function GetGhostSpeedValue: single;
  function GetGhostHomeSpeedValue: single;
  function GetGhostTunnelSpeedValue: single;
  function GetGhostScatterDuration(aCounter: integer): single;
  function GetGhostChaseDuration(aCounter: integer): single;
  function GetElroy1DotsLeft: integer;
  function GetElroy1Speed: single;
  function GetElroy2DotsLeft: integer;
  function GetElroy2Speed: single;

  function CanFright: boolean;
  function GetFrightPacmanSpeedValue: single;
  function GetFrightGhostSpeedValue: single;
  function GetFrightDuration: single;
  function GetFlashCount: integer;
  function GetRetreatGhostSpeedValue: single;
  function GetBonusGhostEaten: integer;
  procedure ResetBonusGhostEaten; // call when player eat a super dot

end;

var GameManager: TGameManager=NIL;

function LeftKeyPressed: boolean;
function RightKeyPressed: boolean;
function UpKeyPressed: boolean;
function DownKeyPressed: boolean;
function PauseKeyPressed: boolean;

function MaxSpeed: single;

implementation
uses LCLType, u_common, u_audio, Math, LazFileutils;

function LeftKeyPressed: boolean;
begin
  Result := FScene.KeyState[GameManager.KeyLeft];
end;

function RightKeyPressed: boolean;
begin
  Result := FScene.KeyState[GameManager.KeyRight];
end;

function UpKeyPressed: boolean;
begin
  Result := FScene.KeyState[GameManager.KeyUp];
end;

function DownKeyPressed: boolean;
begin
  Result := FScene.KeyState[GameManager.KeyDown];
end;

function PauseKeyPressed: boolean;
begin
 Result := FScene.KeyState[GameManager.KeyPause];
end;

function MaxSpeed: single;
const MAX_SPEED = 75.75;
      NATIVE_HRESOLUTION = 224;
begin
  Result := MAX_SPEED * FScene.Width / NATIVE_HRESOLUTION;
  //Result := MAX_SPEED*2;
end;

{ TGameManager }

procedure TGameManager.SetPlayerScore(AValue: integer);
begin
  if FPlayerScore = AValue then Exit;
  FPlayerScore := AValue;

  if FPlayerScore > HighScore then
    HighScore := FPlayerScore;

  if FPlayerScore >= FScoreThresholdForExtraLife[FExtraLifeThresholdIndex] then begin
    FNeedToAddExtraLife := True;
    inc(FExtraLifeThresholdIndex);
  end;
end;

function TGameManager.GetNeedToAddExtraLife: boolean;
begin
  Result := FNeedToAddExtraLife;
  FNeedToAddExtraLife := False;
end;

procedure TGameManager.InitFScoreThresholdForExtraLife;
begin
  FScoreThresholdForExtraLife := NIL;
  case GameDifficulty of
    0: begin
      SetLength(FScoreThresholdForExtraLife, 2);
      FScoreThresholdForExtraLife[0] := 10000;
      FScoreThresholdForExtraLife[1] := MaxInt;
    end;
    1: begin
      SetLength(FScoreThresholdForExtraLife, 3);
      FScoreThresholdForExtraLife[0] := 10000;
      FScoreThresholdForExtraLife[1] := 20000;
      FScoreThresholdForExtraLife[2] := MaxInt;
    end;
    2: begin
      SetLength(FScoreThresholdForExtraLife, 4);
      FScoreThresholdForExtraLife[0] := 10000;
      FScoreThresholdForExtraLife[1] := 20000;
      FScoreThresholdForExtraLife[1] := 30000;
      FScoreThresholdForExtraLife[3] := MaxInt;
    end;
  end;

  FExtraLifeThresholdIndex := 0;
  FNeedToAddExtraLife := False;
end;

procedure TGameManager.SetRetroMode(AValue: boolean);
begin
  if FRetroMode = AValue then Exit;
  FRetroMode := AValue;
  ApplyRetroModeIfNeeded;
end;

constructor TGameManager.Create;
begin
  inherited CreateFolder('LuluGame');
  InitDefaultSavedData;

  FCurrentLevel := 1;
  FPlayerLife := 3;
  FGhostEatenBonusIndex := 0;
  FGameDifficulty := 0;
end;

procedure TGameManager.InitDefaultSavedData;
begin
  FHighScore := 0;
  FKeyLeft := VK_LEFT;
  FKeyRight := VK_RIGHT;
  FKeyUp := VK_UP;
  FKeyDown := VK_DOWN;
  FKeyPause := VK_ESCAPE;
end;

procedure TGameManager.Save;
var prop: TProperties;
  t: TStringList;
begin
  prop.Init('|');
  prop.Add('HighScore', HighScore);
  prop.Add('KeyLeft', KeyLeft);
  prop.Add('KeyRight', KeyRight);
  prop.Add('KeyUp', KeyUp);
  prop.Add('KeyDown', KeyDown);
  prop.Add('KeyPause', KeyPause);

  t := TStringList.Create;
  try
    t.Add('[PACMAN]');
    t.Add(prop.PackedProperty);
    t.SaveToFile(SaveFolder+'pacman.cfg');
  finally
    t.Free;
  end;
end;

procedure TGameManager.Load;
var prop: TProperties;
  t: TStringList;
  f: string;
begin
  f := SaveFolder+'pacman.cfg';
  if not FileExistsUTF8(f) then begin
    InitDefaultSavedData;
    exit;
  end;

  t := TStringList.Create;
  try
    t.LoadFromFile(f);
    prop.SplitFrom(t, '[PACMAN]', '|');
    prop.IntegerValueOf('HighScore', FHighScore, 0);
    prop.WordValueOf('KeyLeft', FKeyLeft, VK_LEFT);
    prop.WordValueOf('KeyRight', FKeyRight, VK_RIGHT);
    prop.WordValueOf('KeyUp', FKeyUp, VK_UP);
    prop.WordValueOf('KeyDown', FKeyDown, VK_DOWN);
    prop.WordValueOf('KeyPause', FKeyPause, VK_ESCAPE);
  finally
    t.Free;
  end;
end;

procedure TGameManager.InitForNewGame;
begin
  PlayerScore := 0;
  PlayerLife := 3;
  CurrentLevel := 1;
  InitFScoreThresholdForExtraLife;
  InitForNextStage;
end;

procedure TGameManager.InitForNextStage;
begin
  DotEaten := 0;
  ElroyLevel := 0;
  FGhostEatenBonusIndex := 0;
end;

procedure TGameManager.InitAfterLoseLife;
begin
  FGhostEatenBonusIndex := 0;
end;

procedure TGameManager.ApplyRetroModeIfNeeded;
begin
  case FRetroMode of
    True: begin
      FScene.PostProcessing.EnableFXOnAllLayers([ppPixelize]);
      FScene.Layer[LAYER_UI].PostProcessing.SetPixelizeParams(0.01);
      FScene.Layer[LAYER_MAZE].PostProcessing.SetPixelizeParams(0.01);
      FScene.PostProcessing.StartEngine;
    end;
    False: begin
      FScene.PostProcessing.StopEngine;
    end;
  end;
end;

function TGameManager.GetScoreForExtraLife: integer;
begin
  Result := 10000;
end;

function TGameManager.GetFruitTextureIndex: integer;
begin
  case Currentlevel of
    1: Result := 0;
    2: Result := 1;
    3,4: Result := 2;
    5,6: Result := 3;
    7,8: Result := 4;
    9,10: Result := 5;
    11,12: Result := 6;
    else Result := 7;
  end;
end;

function TGameManager.GetFruitBonusPoint: integer;
begin
  case Currentlevel of
    1: Result := 100;
    2: Result := 300;
    3,4: Result := 500;
    5,6: Result := 700;
    7,8: Result := 1000;
    9,10: Result := 2000;
    11,12: Result := 3000;
    else Result := 5000;
  end;
end;

function TGameManager.GetPacmanSpeedValue: single;
begin
  case Currentlevel of
    1: Result := MaxSpeed*0.8;
    2,3,4: Result := MaxSpeed*0.9;
    5..20: Result := MaxSpeed;
    else Result := MaxSpeed*0.9;
  end;
end;

function TGameManager.GetGhostSpeedValue: single;
begin
  case Currentlevel of
    1: Result := MaxSpeed*0.75;
    2,3,4: Result := MaxSpeed*0.85;
    else Result := MaxSpeed*0.95;
  end;

  case FGameDifficulty of
    0: Result := Result;
    1: Result := Result*0.9;
    2: Result := Result*0.8;
  end;
end;

function TGameManager.GetGhostHomeSpeedValue: single;
begin
  Result := GetGhostSpeedValue*0.3;
end;

function TGameManager.GetGhostTunnelSpeedValue: single;
begin
  case Currentlevel of
    1: Result := MaxSpeed*0.4;
    2,3,4: Result := MaxSpeed*0.45;
    else Result := MaxSpeed*0.5;
  end;
end;

function TGameManager.GetGhostScatterDuration(aCounter: integer): single;
const VALUES: array[0..3, 0..2] of single = ((7.0, 7.0, 5.0), (7.0, 7.0, 5.0),
                                             (5.0, 5.0, 5.0), (5.0, 1/60, 1/60));
var i: integer;
begin
  case CurrentLevel of
    1: i := 0;
    2..4: i := 1;
    else i := 2;
  end;
  Result := VALUES[aCounter, i];

  case FGameDifficulty of
    0: Result := Result;
    1: Result := Result*1.5;
    2: Result := Result*2.0;
  end;

end;

function TGameManager.GetGhostChaseDuration(aCounter: integer): single;
const VALUES: array[0..3, 0..2] of single = ((20.0, 20.0, 20.0), (20.0, 20.0, 20.0),
                                             (20.0, 1033.0, 1037.0), (100000.0, 100000.0, 100000.0));
var i: integer;
begin
  case CurrentLevel of
    1: i := 0;
    2..4: i := 1;
    else i := 2;
  end;
  Result := VALUES[aCounter, i];
end;

function TGameManager.GetElroy1DotsLeft: integer;
begin
  case Currentlevel of
    1: Result := 20;
    2: Result := 30;
    3,4,5: Result := 40;
    6,7,8: Result := 50;
    9,10,11: Result := 60;
    12,13,14: Result := 80;
    15,16,17,18: Result := 100;
    else Result := 120;
  end;
end;

function TGameManager.GetElroy1Speed: single;
begin
  case Currentlevel of
    1: Result := MaxSpeed*0.8;
    2,3,4: Result := MaxSpeed*0.9;
    else Result := MaxSpeed;
  end;

  case FGameDifficulty of
    0: Result := Result;
    1: Result := Result*0.9;
    2: Result := Result*0.8;
  end;
end;

function TGameManager.GetElroy2DotsLeft: integer;
begin
  case Currentlevel of
    1: Result := 10;
    2: Result := 15;
    3,4,5: Result := 20;
    6,7,8: Result := 25;
    9,10,11: Result := 30;
    12,13,14: Result := 40;
    15,16,17,18: Result := 50;
    else Result := 60;
  end;
end;

function TGameManager.GetElroy2Speed: single;
begin
  case Currentlevel of
    1: Result := MaxSpeed*0.85;
    2,3,4: Result := MaxSpeed*0.95;
    else Result := MaxSpeed*1.05;
  end;

  case FGameDifficulty of
    0: Result := Result;
    1: Result := Result*0.9;
    2: Result := Result*0.8;
  end;
end;

function TGameManager.CanFright: boolean;
begin
  case Currentlevel of
    1..16,18: Result := True;
    else Result := False;
  end;
end;

function TGameManager.GetFrightPacmanSpeedValue: single;
begin
  case Currentlevel of
    1: Result := MaxSpeed*0.9;
    2,3,4: Result := MaxSpeed*0.95;
    else Result := MaxSpeed;
  end;
end;

function TGameManager.GetFrightGhostSpeedValue: single;
begin
  case Currentlevel of
    1: Result := MaxSpeed*0.5;
    2,3,4: Result := MaxSpeed*0.55;
    else Result := MaxSpeed*0.6;
  end;
end;

function TGameManager.GetFrightDuration: single;
begin
  case Currentlevel of
    1: Result := 6;
    2: Result := 5;
    3: Result := 4;
    4: Result := 3;
    5: Result := 2;
    6: Result := 5;
    7,8: Result := 2;
    9: Result := 1;
    10: Result := 5;
    11: Result := 2;
    12,13: Result := 1;
    14: Result := 3;
    15,16: Result := 1;
    17: Result := 0;
    18: Result := 1;
    else Result := 0;
  end;

  case FGameDifficulty of
    0: Result := Result;
    1: Result := Max(Result, 5);
    2: Result := 6;
  end;
end;

function TGameManager.GetFlashCount: integer;
begin
  case Currentlevel of
    1..8: Result := 5;
    9: Result := 3;
    10,11: Result := 5;
    12,13: Result := 3;
    14: Result := 5;
    15,16: Result := 3;
    18: Result := 3
    else Result := 0;
  end;

  case FGameDifficulty of
    0: Result := Result;
    1: Result := 5;
    2: Result := 5;
  end;
end;

function TGameManager.GetRetreatGhostSpeedValue: single;
begin
  Result := MaxSpeed*1.2;
end;

function TGameManager.GetBonusGhostEaten: integer;
const GHOST_BONUS: array[0..3] of integer=(200, 400, 800, 1600);
begin
  Result := GHOST_BONUS[FGhostEatenBonusIndex];
  if FGhostEatenBonusIndex < 3 then inc(FGhostEatenBonusIndex)
    else FGhostEatenBonusIndex := 0;
end;

procedure TGameManager.ResetBonusGhostEaten;
begin
  FGhostEatenBonusIndex := 0;
end;


end.

