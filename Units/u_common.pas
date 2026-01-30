unit u_common;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils,
  OGLCScene, BGRABitmaptypes;

const

 TOTAL_H_TILE_COUNT = 28;
 TOTAL_V_TILE_COUNT = 36;
 MAZE_H_TILE_COUNT = 28;
 MAZE_V_TILE_COUNT = 31;

 TOTAL_DOT_TO_EAT = 244;
 FIRST_FRUIT_DOT_TRIGGER = 70;    // in dot eaten
 LAST_FRUIT_DOT_TRIGGER = 170;    // in dot eaten
 FRUIT_TIME_LIFE = 10.0;

 FRIGHT_MODE_FLASH_DURATION = 0.25;


{LAYERS}
LAYER_COUNT = 2;
  LAYER_UI   = 0;
  LAYER_MAZE = 1;
{/LAYERS}

{DESIGN}
  SCREEN_WIDTH_AT_DESIGN_TIME: single = 896;
  SCREEN_HEIGHT_AT_DESIGN_TIME: single = 1152;
  SCREEN_PPI_AT_DESIGN_TIME: integer = 96;
{/DESIGN}

// Tileset Ground type
  GROUND_HOLE     = 0;
  GROUND_NEUTRAL  = 1;
  GROUND_WALL     = 2;
  GROUND_DOT      = 3;
  GROUND_SUPERDOT = 4;
  GROUND_DOOR     = 5;
function GroundtypeToString(aGT: integer): string;

var

  AdditionnalScale: single = 1.0;
  FScene: TOGLCScene;
  FAtlas: TAtlas;
  texFruits: array[0..7] of PTexture;
  texGhostDressStretched: PTexture;


  texMazeTileSet: PTexture;
  FTileSize,
  FHalfTileSize: TSize;

{VAR}
  gradientTitle: TFontGradient;
  fontdescriptorTitle: TFontDescriptor;
  charsetTitle: string;
  texturedfontTitle: TTexturedFont;
  fontdescriptorText: TFontDescriptor;
  charsetText: string;
  texturedfontText: TTexturedFont;
  fontdescriptorBonus: TFontDescriptor;
  charsetBonus: string;
  texturedfontBonus: TTexturedFont;
  scenarioPanelZoomIN: string;
  scenarioPanelZoomOUT: string;
  fontdescriptorMenu: TFontDescriptor;
  charsetMenu: string;
  texturedfontMenu: TTexturedFont;
{/VAR}
procedure InitializeGlobalVariables;

// Path utils
function DataFolder: string;
function TexturesFolder: string;
function FontsFolder: string;
function AudioFolder: string;

// Scaling utils
function PPIScale(AValue: integer): integer;
function ScaleW(AValue: integer): integer;
function ScaleH(AValue: integer): integer;
function ScaleWF(AValue: single): single;
function ScaleHF(AValue: single): single;

implementation
{$I project_config.cfg}function GroundtypeToString(aGT: integer): string;
begin
  case aGT of
    GROUND_HOLE: Result := 'HOLE';
    GROUND_NEUTRAL: Result := 'NEUTRAL';
    GROUND_WALL: Result := 'WALL';
    GROUND_DOT: Result := 'DOT';
    GROUND_SUPERDOT: Result := 'SUPER DOT';
    GROUND_DOOR: Result := 'DOOR';
  end;
end;

procedure InitializeGlobalVariables;
begin
{VARS_INIT}
  scenarioPanelZoomIN := 'Visible True'#10'Scale 0.1'#10'ScaleChange 1.0 0.3 idcLinear'#10'Wait 0.3';
  scenarioPanelZoomOUT := 'ScaleChange 0.1 0.3 idcLinear'#10'Wait 0.3';
  fontdescriptorText.Create('Bungee', Round(32/SCREEN_HEIGHT_AT_DESIGN_TIME*FScene.Height), [], BGRA(255,255,255));
  charsetText := FScene.Charsets.NUMBER+FScene.Charsets.ASCII_SYMBOL+FScene.Charsets.ASCII_SPACE+FScene.Charsets.ASCII_LETTER;
  gradientTitle.Create(BGRA(255,255,0), BGRA(255,255,255), gtLinear, PointF(73.85, 64.62), PointF(73.85, 129.23), False, False);
  fontdescriptorTitle.Create('CrackMan', Round(150/SCREEN_HEIGHT_AT_DESIGN_TIME*FScene.Height), [], gradientTitle);
  charsetTitle := 'PAC-MN';
  fontdescriptorBonus.Create('DynaPuff Medium', Round(30/SCREEN_HEIGHT_AT_DESIGN_TIME*FScene.Height), [], BGRA(255,255,255));
  charsetBonus := FScene.Charsets.NUMBER+FScene.Charsets.ASCII_SYMBOL+FScene.Charsets.ASCII_SPACE+FScene.Charsets.ASCII_LETTER;
  fontdescriptorMenu.Create('Bungee', Round(40/SCREEN_HEIGHT_AT_DESIGN_TIME*FScene.Height), [], BGRA(255,255,255));
  charsetMenu := 'PLAYOTINSQUREM GK';
{/VARS_INIT}
end;

function DataFolder: string;
begin
  Result := FScene.App.DataFolder;
end;

function TexturesFolder: string;
begin
  Result := DataFolder+'Textures'+DirectorySeparator;
end;

function FontsFolder: string;
begin
 Result := DataFolder+'Fonts'+DirectorySeparator;
end;

function AudioFolder: string;
begin
  Result := DataFolder+'Audio'+DirectorySeparator;
end;

function PPIScale(AValue: integer): integer;
begin
  Result := FScene.ScaleDesignToScene(AValue);
end;

function ScaleW(AValue: integer): integer;
begin
{$ifdef MAXIMIZE_SCENE_ON_MONITOR}
  Result := Trunc(FScene.Width*AValue/SCREEN_WIDTH_AT_DESIGN_TIME*AdditionnalScale);
{$else}
  Result := Trunc(AValue*AdditionnalScale);
{$endif}
end;

function ScaleH(AValue: integer): integer;
begin
{$ifdef MAXIMIZE_SCENE_ON_MONITOR}
  Result := Trunc(FScene.Height*AValue/SCREEN_HEIGHT_AT_DESIGN_TIME*AdditionnalScale);
{$else}
  Result := Trunc(AValue*AdditionnalScale);
{$endif}
end;

function ScaleWF(AValue: single): single;
begin
{$ifdef MAXIMIZE_SCENE_ON_MONITOR}
  Result := FScene.Width*AValue/SCREEN_WIDTH_AT_DESIGN_TIME*AdditionnalScale;
{$else}
  Result := AValue*AdditionnalScale;
{$endif}
end;

function ScaleHF(AValue: single): single;
begin
{$ifdef MAXIMIZE_SCENE_ON_MONITOR}
  Result := FScene.Height*AValue/SCREEN_HEIGHT_AT_DESIGN_TIME*AdditionnalScale;
{$else}
  Result := AValue*AdditionnalScale;
{$endif}
end;

end.

