{
  This file is part of Chess 256.

  Copyright © 2016, 2018 Alexander Kernozhitsky <sh200105@mail.ru>

  Chess 256 is free software: you can redistribute it and/or modify
  it under the terms of the GNU General Public License as published by
  the Free Software Foundation, either version 3 of the License, or
  (at your option) any later version.

  Chess 256 is distributed in the hope that it will be useful,
  but WITHOUT ANY WARRANTY; without even the implied warranty of
  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
  GNU General Public License for more details.

  You should have received a copy of the GNU General Public License
  along with Chess 256.  If not, see <http://www.gnu.org/licenses/>.

  Abstract:
    This file is included from ChessEngines.pas. It contains the largest routine
    from there - an UCI message processor. It processes the UCI messages received
    from the chess engine.
}

procedure TUCIChessEngine.MsgReceiver(Sender: TObject; AMessage: TEngineMessage);
// Receives messages from the engine.

// Process... functions processes a particular kind of messages.

  procedure ProcessEngineID(AMessage: TEngineIDMessage);
  begin
    if FEngineInited then
      Exit;
    case AMessage.Kind of
      idAuthor: FAuthor := AMessage.Value;
      idName: FName := AMessage.Value;
    end;
  end;

  procedure ProcessUCIInitedMessage;
  begin
    FEngineInited := True;
  end;

  procedure ProcessUCIReadyMessage;
  begin
    FEngineReady := True;
  end;

  procedure ProcessBestMoveMessage(AMessage: TBestMoveMessage);
  var
    Res: RAnalysisResult;
  begin
    AMessage.ExtractMoves(FMoveChain.Boards[FMoveChain.Count - 1]);
    Res.BestMove := AMessage.BestMove;
    Res.PonderMove := AMessage.PonderMove;
    DoStop(Res);
  end;

  procedure ProcessInfoMessage(AMessage: TInfoMessage);
  var
    LineTime: TClockValue;
    ALine: TAnalysisLine;

    procedure CreateLine;
    // Creates an analysis line.
    begin
      ALine := TAnalysisLine.Create;
      ALine.FTime := LineTime;
    end;

    // Info submessages processing methods.

    // For main line

    procedure ProcessTime(ATime: int64);
    begin
      if ALine = nil then
        LineTime := MilliSecondsToClockValue(ATime)
      else
        ALine.FTime := MilliSecondsToClockValue(ATime);
    end;

    procedure ProcessScore(AScore: RPositionScore);
    begin
      if FMoveChain.Boards[FMoveChain.Count - 1].MoveSide = pcBlack then
        InvertScore(AScore);
      if ALine = nil then
        CreateLine;
      ALine.FScore := AScore;
      if AScore.Kind = skNormal // only exact mark goes to the state
      then
        State.Score := AScore;
    end;

    procedure ProcessPV(AChain: TMoveChain);
    begin
      if ALine = nil then
        CreateLine;
      ALine.MoveChain.Assign(AChain);
    end;

    // For analysis state

    procedure ProcessDepth(ADepth: integer);
    begin
      State.Depth := ADepth;
    end;

    procedure ProcessNodes(ANodes: int64);
    begin
      State.Nodes := ANodes;
    end;

    procedure ProcessNPS(ANPS: int64);
    begin
      State.NPS := ANPS;
    end;

    procedure ProcessMoveNumber(AMoveNumber: integer);
    begin
      State.MoveNumber := AMoveNumber;
    end;

    procedure ProcessCurMove(const ACurMove: RChessMove);
    begin
      State.CurMove := ACurMove;
    end;

    // For sending a string

    procedure ProcessString(const AValue: string);
    begin
      SendAnalysisMessage(TEngineString.Create(AValue));
    end;

  var
    AName: string;
    I: integer;
  begin
    if not FState.Active then
      Exit;
    State.Changing;
    // prepare to process
    LineTime := State.Time;
    ALine := nil;
    for I := 0 to AMessage.List.Count - 1 do
    begin
      AName := AMessage.List[I].Name;
      // process different kinds of info submessages
      if AName = 'time' then
        ProcessTime((AMessage.List[I] as TIntegerMessageInfo).Value);
      if AName = 'score' then
        ProcessScore((AMessage.List[I] as TScoreMessageInfo).PositionScore);
      if AName = 'pv' then
        with AMessage.List[I] as TMoveChainMessageInfo do
        begin
          ExtractMoveChain(Self.FMoveChain.Boards[Self.FMoveChain.Count - 1]);
          ProcessPV(MoveChain);
        end;
      if AName = 'depth' then
        ProcessDepth((AMessage.List[I] as TIntegerMessageInfo).Value);
      if AName = 'nodes' then
        ProcessNodes((AMessage.List[I] as TIntegerMessageInfo).Value);
      if AName = 'nps' then
        ProcessNPS((AMessage.List[I] as TIntegerMessageInfo).Value);
      if AName = 'currmovenumber' then
        ProcessMoveNumber((AMessage.List[I] as TIntegerMessageInfo).Value);
      if AName = 'currmove' then
        with AMessage.List[I] as TMoveChainMessageInfo do
        begin
          ExtractMoveChain(Self.FMoveChain.Boards[FMoveChain.Count - 1]);
          if MoveChain.Count <> 0 then
            ProcessCurMove(MoveChain.Moves[0]);
        end;
      if AName = 'string' then
        ProcessString((AMessage.List[I] as TStringMessageInfo).Value);
    end;
    // send analysis line (if nessesary)
    if ALine <> nil then
      SendAnalysisMessage(ALine);
    State.Changed;
  end;

  procedure ProcessOptionMessage(AMessage: TOptionMessage);
  var
    Option: TEngineOption;
  begin
    if FEngineInited then
      Exit;
    Option := TEngineOptionClass(AMessage.Option.ClassType).Create;
    Option.Assign(AMessage.Option);
    FOptions.Add(Option);
  end;

begin
  // process different kinds of messages
  if AMessage is TEngineIDMessage then
    ProcessEngineID(AMessage as TEngineIDMessage)
  else
  if AMessage is TUCIInitedMessage then
    ProcessUCIInitedMessage
  else if AMessage is TUCIReadyMessage then
    ProcessUCIReadyMessage
  else if AMessage is TBestMoveMessage then
    ProcessBestMoveMessage(AMessage as TBestMoveMessage)
  else if AMessage is TInfoMessage then
    ProcessInfoMessage(AMessage as TInfoMessage)
  else if AMessage is TOptionMessage then
    ProcessOptionMessage(AMessage as TOptionMessage);
end;
