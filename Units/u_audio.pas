unit u_audio;

{$mode ObjFPC}{$H+}

{$I pacman_define.inc}

interface

uses
  Classes, SysUtils,
  {$IF NOT DEFINED (useuos)}
  ALSound;
  {$else}
  uos_flat;
  {$endif}

type

  {$IF NOT DEFINED (useuos)}
TALSSound = ALSound.TALSSound;
  {$endif}

  { TAudioManager }

  TAudioManager = class
  private
    {$IF NOT DEFINED (useuos)}
  FPlayback: TALSPlaybackContext;
  {$endif}

    FsndChomp23, FsndChomp25, FsndChomp27, FsndEatGhost, FsndSirenLoop,
    FsndFrightmode, FsndGhostRetreat:
    {$IF NOT DEFINED (useuos)} TALSSound {$else} integer {$endif};

    function AddSound(const aFilenameWithoutPath: string):
    {$IF NOT DEFINED (useuos)} TALSSound {$else} integer {$endif}; overload;
    {$IF DEFINED (useuos)}
    procedure LoadLibraries;
  {$endif}
    procedure LoadSounds;
  public
    constructor Create;
    destructor Destroy; override;

    procedure PlayMusicBeginning;
    procedure PlayMusicIntermission;
    // take in acount GameManager.ElroyLevel [0..2]
    procedure PlaySirenLoop;
    procedure StopSirenLoop;
    procedure PlaySoundChomp;
    procedure PlaySoundDeath;
    procedure PlayEatFruit;
    procedure PlayEatGhost;
    procedure PlayExtraLife;
    procedure PlayFrightMode;
    procedure StopFrightMode;
    procedure PlayGhostRetreat;
    procedure StopGhostRetreat;

    procedure StopAllLoopedSounds;
    procedure PauseAllPlayingSounds;
    procedure ResumeAllPausedSounds;
  end;

var
  Audio: TAudioManager;
  {$IF DEFINED (useuos)}
  reslib: integer;
  {$endif}

implementation

uses Forms, u_common, u_game_manager, OGLCScene, ctypes;

var
  AudioLogFile: TLog = nil;

procedure ProcessLogMessageFromALSoft({%H-}aUserPtr: pointer; aLevel: char;
  aMessage: pchar; {%H-}aMessageLength: cint);
begin
  if AudioLogFile <> nil then
    case aLevel of
      'I': AudioLogFile.Info(StrPas(aMessage));
      'W': AudioLogFile.Warning(StrPas(aMessage));
      'E': AudioLogFile.Error(StrPas(aMessage));
      else
        AudioLogFile.Warning(StrPas(aMessage));
    end;
end;

{ TAudioManager }

function TAudioManager.AddSound(const aFilenameWithoutPath:
  string):{$IF NOT DEFINED (useuos)} TALSSound {$else} integer {$endif};
begin
  {$IF NOT DEFINED (useuos)}
   Result := FPlayback.AddSound(AudioFolder + aFilenameWithoutPath);
  {$endif}
end;

procedure TAudioManager.LoadSounds;
{$IF DEFINED (useuos)}
var
  indexin: integer;
{$endif}
begin
  {$IF NOT DEFINED (useuos)}
  FsndSirenLoop := FPlayback.AddSound(AudioFolder+'pacman_sirenloop.ogg');
  FsndSirenLoop.Loop := True;
  FsndSirenLoop.Volume.Value := 0.6;

  FsndChomp23 := FPlayback.AddSound(AudioFolder+'pacman_chomp23.ogg');
  FsndChomp25 := FPlayback.AddSound(AudioFolder+'pacman_chomp25.ogg');
  FsndChomp27 := FPlayback.AddSound(AudioFolder+'pacman_chomp27.ogg');

  FsndEatGhost := FPlayback.AddSound(AudioFolder+'pacman_eatghost.ogg');

  FsndFrightmode := FPlayback.AddSound(AudioFolder+'Fright.ogg');
  FsndFrightmode.Loop := True;

  FsndGhostRetreat := FPlayback.AddSound(AudioFolder+'ghost_retreat.ogg');
  FsndGhostRetreat.Loop := True;
  {$else}
  if reslib = 0 then
  begin
    if uos_CreatePlayer(FsndChomp23) then
    begin
      indexin := uos_AddFromFile(FsndChomp23, PChar(AudioFolder + 'pacman_chomp23.ogg'),
        -1, -1, -1);
      uos_AddIntoDevOut(FsndChomp23, -1, -1, uos_InputGetSampleRate(
        FsndChomp23, indexin),
        uos_InputGetChannels(FsndChomp23, indexin), -1, -1, -1);
    end;
    if uos_CreatePlayer(FsndChomp25) then
    begin
      indexin := uos_AddFromFile(FsndChomp25, PChar(AudioFolder + 'pacman_chomp25.ogg'),
        -1, -1, -1);
      uos_AddIntoDevOut(FsndChomp25, -1, -1, uos_InputGetSampleRate(
        FsndChomp25, indexin),
        uos_InputGetChannels(FsndChomp25, indexin), -1, -1, -1);
    end;
    if uos_CreatePlayer(FsndChomp27) then
    begin
      indexin := uos_AddFromFile(FsndChomp27, PChar(AudioFolder + 'pacman_chomp27.ogg'),
        -1, -1, -1);
      uos_AddIntoDevOut(FsndChomp27, -1, -1, uos_InputGetSampleRate(
        FsndChomp27, indexin),
        uos_InputGetChannels(FsndChomp27, indexin), -1, -1, -1);
    end;
    if uos_CreatePlayer(FsndEatGhost) then
    begin
      indexin := uos_AddFromFile(FsndEatGhost, PChar(AudioFolder +
        'pacman_eatghost.ogg'), -1, -1, -1);
      uos_AddIntoDevOut(FsndEatGhost, -1, -1, uos_InputGetSampleRate(
        FsndEatGhost, indexin), uos_InputGetChannels(FsndEatGhost, indexin), -1, -1, -1);
    end;
    if uos_CreatePlayer(FsndFrightmode) then
    begin
      indexin := uos_AddFromFile(FsndFrightmode, PChar(AudioFolder + 'Fright.ogg'),
        -1, -1, -1);
      uos_AddIntoDevOut(FsndFrightmode, -1, -1,
        uos_InputGetSampleRate(FsndFrightmode, indexin),
        uos_InputGetChannels(FsndFrightmode, indexin), -1, -1, -1);
      //FsndFrightmode.Loop := True;
    end;
    if uos_CreatePlayer(FsndGhostRetreat) then
    begin
      indexin := uos_AddFromFile(FsndGhostRetreat,
        PChar(AudioFolder + 'ghost_retreat.ogg'), -1, -1, -1);
      uos_AddIntoDevOut(FsndGhostRetreat, -1, -1,
        uos_InputGetSampleRate(FsndGhostRetreat, indexin),
        uos_InputGetChannels(FsndGhostRetreat, indexin), -1, -1, -1);
      //FsndGhostRetreat.Loop := True;
    end;
  end;
  {$endif}

end;

{$IF DEFINED (useuos)}
procedure TAudioManager.LoadLibraries;
var
  {$IFDEF Darwin}
opath,
  {$endif}
  ordir, PA_FileName, SF_FileName: string;
begin
  ordir := IncludeTrailingBackslash(ExtractFilePath(ParamStr(0)));

  {$if defined(CPUAMD64) and defined(linux) }
  SF_FileName := ordir + 'libuos/Linux/64bit/LibSndFile-64.so';
  PA_FileName := ordir + 'libuos/Linux/64bit/LibPortaudio-64.so';
  // For Linux amd64, check libsndfile.so
  if uos_TestLoadLibrary(PChar(SF_FileName)) = false then
   SF_FileName := SF_FileName + '.2';
  {$endif}

  {$IFDEF Windows}
     {$if defined(cpu64)}
  PA_FileName := ordir + 'libuos\Windows\64bit\LibPortaudio-64.dll';
  SF_FileName := ordir + 'libuos\Windows\64bit\LibSndFile-64.dll';
     {$else}
  PA_FileName := ordir + 'libuos\Windows\32bit\LibPortaudio-32.dll';
  SF_FileName := ordir + 'libuos\Windows\32bit\LibSndFile-32.dll';
     {$endif}
  {$ENDIF}

  {$if defined(CPUAMD64) and defined(openbsd) }
  SF_FileName := ordir + 'libuos/OpenBSD/64bit/LibSndFile-64.so';
  PA_FileName := ordir + 'libuos/OpenBSD/64bit/LibPortaudio-64.so';
  {$ENDIF}

  {$if defined(CPUAMD64) and defined(netbsd) }
  SF_FileName := ordir + 'libuos/NetBSD/64bit/LibSndFile-64.so';
  PA_FileName := ordir + 'libuos/NetBSD/64bit/LibPortaudio-64.so';
  {$ENDIF}

  {$if defined(CPUAMD64) and defined(dragonflybsd) }
  SF_FileName := ordir + 'libuos/DragonFlyBSD/64bit/LibSndFile-64.so';
  PA_FileName := ordir + 'libuos/DragonFlyBSD/64bit/LibPortaudio-64.so';
  {$ENDIF}

  {$if defined(cpu86) and defined(linux)}
  PA_FileName := ordir + 'libuos/Linux/32bit/LibPortaudio-32.so';
  SF_FileName := ordir + 'libuos/Linux/32bit/LibSndFile-32.so';
  {$ENDIF}

  {$if defined(linux) and defined(cpuaarch64)}
  PA_FileName := ordir + 'libuos/Linux/aarch64_raspberrypi/libportaudio_aarch64.so';
  SF_FileName := ordir + 'libuos/Linux/aarch64_raspberrypi/libsndfile_aarch64.so';
  {$ENDIF}

  {$if defined(linux) and defined(cpuarm)}
  PA_FileName := ordir + 'libuos/Linux/arm_raspberrypi/libportaudio-arm.so';
  SF_FileName := ordir + 'libuos/Linux/arm_raspberrypi/libsndfile-arm.so';
  {$ENDIF}

  {$IFDEF freebsd}
    {$if defined(cpu64)}
  PA_FileName := ordir + 'libuos/FreeBSD/64bit/libportaudio-64.so';
  SF_FileName := ordir + 'libuos/FreeBSD/64bit/libsndfile-64.so';
    {$else}
  PA_FileName := ordir + 'libuos/FreeBSD/32bit/libportaudio-32.so';
  SF_FileName := ordir + 'libuos/FreeBSD/32bit/libsndfile-32.so';
    {$endif}
  {$ENDIF}

  {$IFDEF Darwin}
  opath := IncludeTrailingBackslash(ExtractFilePath(ParamStr(0)));
  ordir := copy(opath, 1, length(opath) -6) + 'Resources/';
  {$IFDEF CPU32}
  PA_FileName := ordir + 'libuos/Mac/32bit/LibPortaudio-32.dylib';
  SF_FileName := ordir + 'libuos/Mac/32bit/LibSndFile-32.dylib';
 {$ENDIF}
  {$IFDEF CPU64}
  PA_FileName := ordir + 'libuos/Mac/64bit/LibPortaudio-64.dylib';
  SF_FileName := ordir + 'libuos/Mac/64bit/LibSndFile-64.dylib';
  {$ENDIF}
  {$ENDIF}

  reslib := uos_LoadLib(PChar(PA_FileName), PChar(SF_FileName), nil,
    nil, nil, nil, nil);
end;
{$endif}

constructor TAudioManager.Create;
begin
  AudioLogFile := OGLCScene.TLog.Create(IncludeTrailingPathdelimiter(
    Application.Location) + 'alsound.log', nil, nil);
  AudioLogFile.DeleteLogFile;

  {$IF NOT DEFINED (useuos)}
  ALSManager.SetOpenALSoftLogCallback(@ProcessLogMessageFromALSoft, NIL);
  ALSManager.SetLibrariesSubFolder(FScene.App.ALSoundLibrariesSubFolder);
  ALSManager.LoadLibraries;
  FPlayback := ALSManager.CreateDefaultPlaybackContext;
  {$else}
  FsndChomp23 := 0;
  FsndChomp25 := 1;
  FsndChomp27 := 2;
  FsndEatGhost := 3;
  FsndSirenLoop := 4;
  FsndFrightmode := 5;
  FsndGhostRetreat := 6;
  LoadLibraries;
  {$endif}

  LoadSounds;
end;

destructor TAudioManager.Destroy;
begin
  {$IF NOT DEFINED (useuos)}
  FreeAndNil(FPlayback);
  FreeAndNil(AudioLogFile);
  {$else}
  FreeAndNil(AudioLogFile);
  uos_Free();
  {$endif}
  inherited Destroy;
end;

procedure TAudioManager.PlayMusicBeginning;
{$IF DEFINED (useuos)}
var
  indexin: integer;
{$endif}
begin
  {$IF NOT DEFINED (useuos)}
 with FPlayback.AddSound(AudioFolder+'pacman_beginning.ogg') do PlayThenKill(True);
  {$else}
  if reslib = 0 then
  begin
    if uos_CreatePlayer(7) then
    begin
      indexin := uos_AddFromFile(7, PChar(AudioFolder + 'pacman_beginning.ogg'),
        -1, -1, -1);
      uos_AddIntoDevOut(7, -1, -1, uos_InputGetSampleRate(7, indexin),
        uos_InputGetChannels(7, indexin), -1, -1, -1);
      uos_Play(7);
    end;
  end;
  {$endif}
end;

procedure TAudioManager.PlayMusicIntermission;
{$IF DEFINED (useuos)}
var
  indexin: integer;
{$endif}
begin
  {$IF NOT DEFINED (useuos)}
 with FPlayback.AddSound(AudioFolder+'pacman_intermission.ogg') do PlayThenKill(True);
  {$else}
  if reslib = 0 then
  begin
    if uos_CreatePlayer(7) then
    begin
      indexin := uos_AddFromFile(7, PChar(AudioFolder + 'pacman_intermission.ogg'),
        -1, -1, -1);
      uos_AddIntoDevOut(7, -1, -1, uos_InputGetSampleRate(7, indexin),
        uos_InputGetChannels(7, indexin), -1, -1, -1);
      uos_Play(7);
    end;
  end;
  {$endif}
end;

procedure TAudioManager.PlaySirenLoop;
{$IF DEFINED (useuos)}
var
  ratio: single;
  indexin, indexout: integer;
{$endif}
begin
  {$IF NOT DEFINED (useuos)}
  case GameManager.ElroyLevel of
    0: FsndSirenLoop.Pitch.Value := 1.0;
    1: FsndSirenLoop.Pitch.Value := 1.2;
    2: FsndSirenLoop.Pitch.Value := 1.4;
  end;
  FsndSirenLoop.Play(False);
  {$else}
  if reslib = 0 then
  begin
    case GameManager.ElroyLevel of
      0: ratio := 1.0;
      1: ratio := 1.2;
      2: ratio := 1.4;
    end;
    uos_stop(FsndSirenLoop);
    if uos_CreatePlayer(FsndSirenLoop) then
    begin
      indexin := uos_AddFromFile(FsndSirenLoop, PChar(AudioFolder +
        'pacman_sirenloop.ogg'), -1, -1, -1);
      indexout := uos_AddIntoDevOut(FsndSirenLoop, -1, -1,
        uos_InputGetSampleRate(FsndSirenLoop, indexin) * ratio,
        uos_InputGetChannels(FsndSirenLoop, indexin), -1, -1, -1);
      uos_OutputAddDSPVolume(FsndSirenLoop, indexout, 0.6, 0.6);
      uos_PlayNoFree(FsndSirenLoop, -1);
    end;
  end;
  {$endif}
end;

procedure TAudioManager.StopSirenLoop;
begin
  {$IF NOT DEFINED (useuos)}
 FsndSirenLoop.Stop;
  {$else}
  if reslib = 0 then
    uos_stop(FsndSirenLoop);
  {$endif}
end;

procedure TAudioManager.PlaySoundChomp;
begin
  {$IF NOT DEFINED (useuos)}
  case GameManager.CurrentLevel of
    1: FsndChomp27.Play(False); // MaxSpeed*0.8;
    2,3,4: FsndChomp25.Play(False); // MaxSpeed*0.9;
    5..20: FsndChomp23.Play(False); // MaxSpeed;
    else FsndChomp25.Play(False); // MaxSpeed*0.9;
  end;
  {$else}
  if reslib = 0 then
    case GameManager.CurrentLevel of
      1: uos_PlayNoFree(FsndChomp27); // MaxSpeed*0.8;
      2, 3, 4: uos_PlayNoFree(FsndChomp25); // MaxSpeed*0.9;
      5..20: uos_PlayNoFree(FsndChomp23); // MaxSpeed;
      else
        uos_PlayNoFree(FsndChomp25); // MaxSpeed*0.9;
    end;
  {$endif}
end;

procedure TAudioManager.PlaySoundDeath;
{$IF DEFINED (useuos)}
var
  indexin: integer;
{$endif}
begin
  {$IF NOT DEFINED (useuos)}
 with FPlayback.AddSound(AudioFolder+'pacman_death.ogg') do PlayThenKill(True);
  {$else}
  if reslib = 0 then
  begin
    if uos_CreatePlayer(7) then
    begin
      indexin := uos_AddFromFile(7, PChar(AudioFolder + 'pacman_death.ogg'), -1, -1, -1);
      uos_AddIntoDevOut(7, -1, -1, uos_InputGetSampleRate(7, indexin),
        uos_InputGetChannels(7, indexin), -1, -1, -1);
      uos_Play(7);
    end;
  end;
  {$endif}
end;

procedure TAudioManager.PlayEatFruit;
{$IF DEFINED (useuos)}
var
  indexin: integer;
{$endif}
begin
  {$IF NOT DEFINED (useuos)}
 with FPlayback.AddSound(AudioFolder+'pacman_eatfruit.ogg') do PlayThenKill(True);
  {$else}
  if reslib = 0 then
  begin
    if uos_CreatePlayer(7) then
    begin
      indexin := uos_AddFromFile(7, PChar(AudioFolder + 'pacman_eatfruit.ogg'),
        -1, -1, -1);
      uos_AddIntoDevOut(7, -1, -1, uos_InputGetSampleRate(7, indexin),
        uos_InputGetChannels(7, indexin), -1, -1, -1);
      uos_Play(7);
    end;
  end;
  {$endif}
end;

procedure TAudioManager.PlayEatGhost;
begin
  {$IF NOT DEFINED (useuos)}
 FsndEatGhost.Play(True);
  {$else}
  if reslib = 0 then
    uos_PlayNoFree(FsndEatGhost);
  {$endif}
end;

procedure TAudioManager.PlayExtraLife;
{$IF DEFINED (useuos)}
var
  indexin: integer;
{$endif}
begin
  {$IF NOT DEFINED (useuos)}
with FPlayback.AddSound(AudioFolder+'pacman_extrapac.ogg') do PlayThenKill(True);
  {$else}
  if reslib = 0 then
  begin
    if uos_CreatePlayer(7) then
    begin
      indexin := uos_AddFromFile(7, PChar(AudioFolder + 'pacman_extrapac.ogg'),
        -1, -1, -1);
      uos_AddIntoDevOut(7, -1, -1, uos_InputGetSampleRate(7, indexin),
        uos_InputGetChannels(7, indexin), -1, -1, -1);
      uos_Play(7);
    end;
  end;
  {$endif}
end;

procedure TAudioManager.PlayFrightMode;
begin
  {$IF NOT DEFINED (useuos)}
 FsndFrightmode.Play(True);
  {$else}
  if reslib = 0 then
    uos_PlayNoFree(FsndFrightmode);
  {$endif}
end;

procedure TAudioManager.StopFrightMode;
begin
  {$IF NOT DEFINED (useuos)}
 FsndFrightmode.Stop;
  {$else}
  if reslib = 0 then
    uos_stop(FsndFrightmode);
  {$endif}
end;

procedure TAudioManager.PlayGhostRetreat;
begin
  {$IF NOT DEFINED (useuos)}
 if FsndGhostRetreat.State = ALS_STOPPED then  FsndGhostRetreat.Play(True);
  {$else}
  if reslib = 0 then
    if uos_GetStatus(FsndGhostRetreat) = 0 then uos_PlayNoFree(FsndGhostRetreat);
  {$endif}
end;

procedure TAudioManager.StopGhostRetreat;
begin
  {$IF NOT DEFINED (useuos)}
 FsndGhostRetreat.Stop;
  {$else}
  if reslib = 0 then uos_stop(FsndGhostRetreat);
  {$endif}
end;

procedure TAudioManager.StopAllLoopedSounds;
begin
  StopSirenLoop;
  StopFrightMode;
  StopGhostRetreat;
end;

procedure TAudioManager.PauseAllPlayingSounds;
begin
  {$IF NOT DEFINED (useuos)}
  if FsndEatGhost.State = ALS_PLAYING  then FsndEatGhost.Pause;
  if FsndSirenLoop.State = ALS_PLAYING  then FsndSirenLoop.Pause;
  if FsndFrightmode.State = ALS_PLAYING  then FsndFrightmode.Pause;
  if FsndGhostRetreat.State = ALS_PLAYING  then FsndGhostRetreat.Pause;
  {$else}
  if reslib = 0 then
  begin
    if uos_GetStatus(FsndGhostRetreat) = 1 then uos_pause(FsndEatGhost);
    if uos_GetStatus(FsndSirenLoop) = 1 then uos_pause(FsndSirenLoop);
    if uos_GetStatus(FsndFrightmode) = 1 then uos_pause(FsndFrightmode);
    if uos_GetStatus(FsndGhostRetreat) = 1 then uos_pause(FsndGhostRetreat);
  end;
  {$endif}
end;

procedure TAudioManager.ResumeAllPausedSounds;
begin
  {$IF NOT DEFINED (useuos)}
  if FsndEatGhost.State = ALS_PAUSED  then FsndEatGhost.Play(False);
  if FsndSirenLoop.State = ALS_PAUSED  then FsndSirenLoop.Play(False);
  if FsndFrightmode.State = ALS_PAUSED  then FsndFrightmode.Play(False);
  if FsndGhostRetreat.State = ALS_PAUSED  then FsndGhostRetreat.Play(False);
  {$else}
  if reslib = 0 then
  begin
    if uos_GetStatus(FsndGhostRetreat) = 2 then uos_replay(FsndEatGhost);
    if uos_GetStatus(FsndSirenLoop) = 2 then uos_replay(FsndSirenLoop);
    if uos_GetStatus(FsndFrightmode) = 2 then uos_replay(FsndFrightmode);
    if uos_GetStatus(FsndGhostRetreat) = 2 then uos_replay(FsndGhostRetreat);
  end;
  {$endif}

end;

end.
