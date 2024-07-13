  Description = ProcgrpDescription
  ProcOutputClause = "PROCESSOR OUTPUT TYPE IS "EXECUTABLE""
  MoveActionClause = "MOVE ACTION USE &MoveAction PROCESSOR"
  TranActionClause = "TRANSFER ACTION USE &TranAction PROCESSOR"
  If Type = PROCESS  then GenPRC = GPPROCSS
  If Type = PROCESS  then MovePRC = GPPROCSS
  If Type = PROCESS  then DelPRC = DPPROCSS
  If Type = PROCESS  then MoveActionClause = " "
  If Type = PROCESS  then TranActionClause = " "
  If GenPRC = '*NOPROC*' then ProcOutputClause = " "
