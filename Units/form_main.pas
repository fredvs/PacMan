unit form_main;

{$mode objfpc}{$H+}
{$I project_config.cfg}

{$I pacman_define.inc}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, OpenGLContext, LCLType,
  ExtCtrls;

type

  { TFormMain }

  TFormMain = class(TForm)
    OpenGLControl1: TOpenGLControl;
    Timer1: TTimer;
    procedure FormClose(Sender: TObject; var CloseAction: TCloseAction);
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure FormKeyDown(Sender: TObject; var Key: word; Shift: TShiftState);
    procedure FormKeyUp(Sender: TObject; var Key: word; Shift: TShiftState);
    procedure FormShow(Sender: TObject);
    procedure FormUTF8KeyPress(Sender: TObject; var UTF8Key: TUTF8Char);
    procedure Timer1Timer(Sender: TObject);
  private
    procedure ConstructAtlas;
    procedure LoadCommonData;
    procedure FreeCommonData;
    procedure ProcessApplicationIdle(Sender: TObject; var Done: boolean);
  public

  end;

var
  FormMain: TFormMain;

implementation

uses OGLCScene, u_common, screen_game {$ifndef WINDOWED_MODE},LCLIntf{$endif},
  BGRABitmap, BGRABitmapTypes, u_sprite_def, u_game_manager, u_audio,
  screen_mainmenu, screen_intermission, u_sprite_presentation,
  u_sprite_ghostworm, u_panel_baseoptions {$IF NOT DEFINED (useuos)}, ALSound{$endif};

  {$R *.lfm}

  { TFormMain }

procedure TFormMain.FormCreate(Sender: TObject);
var
  BoundsRect_client: TRect;
begin
  {$ifdef MAXIMIZE_SCENE_ON_MONITOR}
  FScene := TOGLCScene.Create(OpenGLControl1,
    SCREEN_WIDTH_AT_DESIGN_TIME / SCREEN_HEIGHT_AT_DESIGN_TIME);
  {$ifdef WINDOWED_MODE}
  BoundsRect_client := Monitor.BoundsRect;
  BoundsRect_client.Width := Monitor.BoundsRect.Width - 100;
  BoundsRect_client.left := 50;
  BoundsRect_client.Height := Monitor.BoundsRect.Height - 100;
  BoundsRect_client.top := 50;
  BoundsRect := BoundsRect_client;
  WindowState := wsNormal;
  {$else}
  BorderIcons := [];
  BorderStyle := bsNone;
  WindowState := wsFullScreen;
  ShowWindow(Handle, SW_SHOWFULLSCREEN);
  BoundsRect := Monitor.BoundsRect;
  {$endif}
  {$else}
  ClientWidth := Trunc(SCREEN_WIDTH_AT_DESIGN_TIME);
  ClientHeight := Trunc(SCREEN_HEIGHT_AT_DESIGN_TIME);
  FScene := TOGLCScene.Create(OpenGLControl1, -1);
  BorderIcons := [biSystemMenu];
  BorderStyle := bsSingle;
  WindowState := wsNormal;
  {$endif}
  FScene.DesignPPI := SCREEN_PPI_AT_DESIGN_TIME;
  FScene.LayerCount := LAYER_COUNT;
  FScene.ScreenFadeTime := 0.5;
  FScene.OnLoadCommonData := @LoadCommonData;
  FScene.OnFreeCommonData := @FreeCommonData;
  FScene.FontManager.ScanProjectFont(FontsFolder);

  Audio := TAudioManager.Create;

  {$IF DEFINED (useuos)}
  if reslib <> 0 then ShowMessage(
      'Audio is not ready, the game will run without sound.');
  {$endif}

  Application.OnIdle := @ProcessApplicationIdle;
end;

procedure TFormMain.FormClose(Sender: TObject; var CloseAction: TCloseAction);
begin
  if Assigned(GameManager) then
    GameManager.Save;
end;

procedure TFormMain.FormDestroy(Sender: TObject);
begin
  FScene.Free;
  FScene := nil;
end;

procedure TFormMain.FormKeyDown(Sender: TObject; var Key: word; Shift: TShiftState);
begin
  FScene.ProcessOnKeyDown(Key, Shift);
end;

procedure TFormMain.FormKeyUp(Sender: TObject; var Key: word; Shift: TShiftState);
begin
  FScene.ProcessOnKeyUp(Key, Shift);
end;

procedure TFormMain.FormShow(Sender: TObject);
var
  s: string;
  ordir, PA_FileName, SF_FileName: string;
  res: integer;
begin

  if not FScene.OpenGLLibLoaded then
    ShowMessage('ERROR: OpenGL library could not be loaded...' + LineEnding +
      'Check if your system is compatible with OpenGL 3.3 core' + LineEnding +
      'and if the library is well installed on your computer');

  {$IF NOT DEFINED (useuos)}
  s := '';
  if not ALSManager.OpenALSoftLibraryLoaded then
    s := 'OpenALSoft not found';
  if not ALSManager.LibSndFileLibraryLoaded then begin
    if s <> '' then s := s + LineEnding;
    s := s + 'LibSndFile not found';
  end;
  if s <> '' then
    ShowMessage(s+LineEnding+'ALSound is not ready, the game will run without sound.');
  {$endif}

end;

procedure TFormMain.FormUTF8KeyPress(Sender: TObject; var UTF8Key: TUTF8Char);
begin
  FScene.ProcessOnUTF8KeyPress(UTF8Key);
end;

procedure TFormMain.Timer1Timer(Sender: TObject);
begin
  if FScene <> nil then
  begin
    Caption := 'scene ' + FScene.Width.ToString + ',' + FScene.Height.ToString +
      '  TileSize ' + FTileSize.cx.ToString + ',' + FTileSize.cy.ToString;
  end;
end;

procedure TFormMain.ConstructAtlas;
var
  ima: TBGRABitmap;
  A: TStringArray;
  i: integer;
  path: string;
{  xx, yy: integer;
  til: TBGRABitmap;
  f: string; }
begin
  FAtlas := FScene.CreateAtlas;
  FAtlas.Spacing := 2;

  // compute the tile size according the scene size
  FTileSize.cx := FScene.Width div TOTAL_H_TILE_COUNT;
  FTileSize.cy := FScene.Height div TOTAL_V_TILE_COUNT;
  FHalfTileSize.cx := FTileSize.cx div 2;
  FHalfTileSize.cy := FTileSize.cy div 2;

  // construct the tileset
  path := TexturesFolder;
  A := nil;
  SetLength(A, 38);
  for i := 0 to High(A) do
    if i < 9 then A[i] := path + 'Tile0' + (i + 1).ToString + '.svg'
    else
      A[i] := path + 'Tile' + (i + 1).ToString + '.svg';
  texMazeTileSet := FAtlas.AddTileSetFromSVG('MazeTileSet', FTileSize.cx, 3, 16, A);

  // ghost dress
  texGhostDressStretched := FAtlas.AddFromSVG(path + 'GhostDressStretched.svg',
    ScaleW(64), -1);

{  // construct the tileset for TileMap Designer
  ima := TBGRABitmap.Create(32*16, 32*3, BGRAPixelTransparent);
  yy := 0;
  xx := 0;
  for i:=0 to 38 do begin
    if i < 9 then f := path+'Tile0'+(i+1).ToString+'.svg'
      else f := path+'Tile'+(i+1).ToString+'.svg';
    til := LoadBitmapFromSVG(f, 32, 32);
    ima.PutImage(xx, yy, til, dmSet);
    til.Free;
    xx := xx + 32;
    if xx = 32*16 then begin
      xx := 0;
      yy := yy + 32;
    end;
  end;
  ima.SaveToFile(Application.Location+'TileSet.png');
  ima.Free;  }

  TPanelBaseOptions.LoadTexture(FAtlas);
  TPacMan.LoadTexture(FAtlas);
  TGhost.LoadTexture(FAtlas);
  TLives.LoadTexture(FAtlas);
  TPresentation.LoadTexture(FAtlas);
  TGhostWorm.LoadTexture(FAtlas);

  for i := 0 to High(texFruits) do
    texFruits[i] := FAtlas.AddFromSVG(TexturesFolder + 'Fruit' +
      (i + 1).ToString + '.svg', Round(FTileSize.cx * 1.5),
      Round(FTileSize.cy * 1.5));

  texturedfontTitle := FAtlas.AddTexturedFont(fontdescriptorTitle, charsetTitle, nil);
  //  fontdescriptorMenu.FontHeight := Round(fontdescriptorMenu.FontHeight/SCREEN_HEIGHT_AT_DESIGN_TIME*FScene.Height);
  texturedfontMenu := FAtlas.AddTexturedFont(fontdescriptorMenu, charsetMenu, nil);
  //  fontdescriptorText.FontHeight := Round(FTileSize.cy*1.2); // adjust the font height
  texturedfontText := FAtlas.AddTexturedFont(fontdescriptorText, charsetText, nil);
  texturedfontBonus := FAtlas.AddTexturedFont(fontdescriptorBonus, charsetBonus, nil);

  FAtlas.TryToPack;
  FAtlas.Build;

  // for debug purpose, we save the packed image just to see if all is fine.
  ima := FAtlas.GetPackedImage(False, False);
  ima.SaveToFile(Application.Location + 'atlas.png');
  ima.Free;
  FAtlas.FreeItemImages; // free some memory because we no longer need individual images
end;

procedure TFormMain.LoadCommonData;
begin
  FScene.CreateLogFile(Application.Location + 'scene.log', True, nil, nil);
  InitializeGlobalVariables;

  GameManager := TGameManager.Create;
  GameManager.Load;

  ConstructAtlas;

  ScreenMainMenu := TScreenMainMenu.Create;
  ScreenGame := TScreenGame.Create;
  ScreenIntermission := TScreenIntermission.Create;

  FScene.RunScreen(ScreenMainMenu);
end;

procedure TFormMain.FreeCommonData;
begin
  FreeAndNil(ScreenMainMenu);
  FreeAndNil(ScreenGame);
  FreeAndNil(ScreenIntermission);
  FreeAndNil(FAtlas);
  FreeAndNil(GameManager);
  FreeAndNil(Audio);
end;

procedure TFormMain.ProcessApplicationIdle(Sender: TObject; var Done: boolean);
begin
  FScene.DoLoop;
  Done := False;
end;

end.
