/* REXX */

mainbit:
ADDRESS ISPEXEC
'DISPLAY PANEL(DB2PR)'
DO WHILE RC>0
exit
END

 PROC1 = DB2SP03||'_'||DB2SP02

numbers:
ADDRESS ISPEXEC
'DISPLAY PANEL(PROCS)'
DO WHILE RC>0
SIGNAL MAINBIT
END
TOTAL=DB2SPX01+DB2SPX02+DB2SPX03+DB2SPX04+DB2SPX05            ,
     +DB2SPX06+DB2SPX07+DB2SPX08+DB2SPX09+DB2SPX10
ADDRESS TSO

/* INITIALISE ARRAY */

INSERT:
ARRAY.=' '
COUNT = 1
/*************DONE************************************************/
A=1 ; type = 'SMALLINT'
DO while A <=  DB2SPX01
  ADDRESS ISPEXEC
  'DISPLAY PANEL(PROC1)'
DO WHILE RC>0
signal numbers
END
CALL TESTEXISTS
  IF ERROR = ' ' THEN DO
  ARRAY.COUNT = ""VARNAMES" SMALLINT            "INOUT" "
  COUNT = COUNT +1
  END
end
/*****************************************************************/
A=1 ; type = 'INTEGER'
DO while A <= DB2SPX02
  ADDRESS ISPEXEC
  'DISPLAY PANEL(PROC1)'
DO WHILE RC>0
signal numbers
END
CALL TESTEXISTS
  IF ERROR = ' ' THEN DO
  ARRAY.COUNT = ""VARNAMES" INTEGER             "INOUT" "
  COUNT = COUNT +1
  END
END
/*****************************************************************/
A=1 ; type = 'REAL'
DO while A <=  DB2SPX03
  ADDRESS ISPEXEC
  'DISPLAY PANEL(PROC1)'
DO WHILE RC>0
signal numbers
END
CALL TESTEXISTS
  IF ERROR = ' ' THEN DO
  ARRAY.COUNT = ""VARNAMES" REAL                "INOUT" "
  COUNT = COUNT +1
  END
END
/*****************************************************************/
A=1 ; type = 'FLOAT'
DO while A <=  DB2SPX04
  ADDRESS ISPEXEC
  'DISPLAY PANEL(PROC1)'
DO WHILE RC>0
signal numbers
END
CALL TESTEXISTS
  IF ERROR = ' ' THEN DO
  ARRAY.COUNT = ""VARNAMES" FLOAT               "INOUT" "
  COUNT = COUNT +1
  END
END
/*****************************************************************/
A=1 ; type = 'DOUBLE PRECISION'
DO while A <=  DB2SPX05
  ADDRESS ISPEXEC
  'DISPLAY PANEL(PROC1)'
DO WHILE RC>0
signal numbers
END
CALL TESTEXISTS
  IF ERROR = ' ' THEN DO
  ARRAY.COUNT = ""VARNAMES" DOUBLE PRECISION    "INOUT" "
  COUNT = COUNT +1
  END
END
/*****************************************************************/
A=1 ; type = 'DECIMAL'
DO while A <=  DB2SPX06
  ADDRESS ISPEXEC
  'DISPLAY PANEL(PROC2)'
DO WHILE RC>0
signal numbers
END
CALL TESTEXISTS
  IF ERROR = ' ' THEN DO
  ARRAY.COUNT = ""VARNAMES" DECIMAL("PP","SS")      "INOUT" "
  COUNT = COUNT +1
  END
END
/*****************************************************************/
A=1 ; type = 'CHARACTER'
DO while A <=  DB2SPX07
  ADDRESS ISPEXEC
  'DISPLAY PANEL(PROC3)'
DO WHILE RC>0
signal numbers
END
CALL TESTEXISTS
  IF ERROR = ' ' THEN DO
  ARRAY.COUNT = ""VARNAMES" CHARACTER("NNN")      "INOUT" "
  COUNT = COUNT +1
  END
END
/*****************************************************************/
A=1 ; type = 'VARCHAR'
DO while A <=  DB2SPX08
  ADDRESS ISPEXEC
  'DISPLAY PANEL(PROC4)'
DO WHILE RC>0
signal numbers
END
CALL TESTEXISTS
  IF ERROR = ' ' THEN DO
  ARRAY.COUNT = ""VARNAMES" VARCHAR("NNNNN")      "INOUT" "
  COUNT = COUNT +1
  END
END
/*****************************************************************/
A=1 ; type = 'GRAPHIC'
DO while A <=  DB2SPX09
  ADDRESS ISPEXEC
  'DISPLAY PANEL(PROC5)'
DO WHILE RC>0
signal numbers
END
CALL TESTEXISTS
  IF ERROR = ' ' THEN DO
  ARRAY.COUNT = ""VARNAMES" GRAPHIC("NNN")        "INOUT" "
  COUNT = COUNT +1
  END
END
/*****************************************************************/
A=1 ; type = 'VARGRAPHIC'
DO while A <=  DB2SPX10
  ADDRESS ISPEXEC
  'DISPLAY PANEL(PROC6)'
DO WHILE RC>0
signal numbers
END
CALL TESTEXISTS
  IF ERROR = ' ' THEN DO
  ARRAY.COUNT = ""VARNAMES" VARGRAPHIC("NNNNN")   "INOUT" "
  COUNT = COUNT +1
  END
END
/*****************************************************************/
 queue "                                                          "
 QUEUE "DELETE FROM SYSIBM.SYSPROCEDURES                          "
 QUEUE "       WHERE PROCEDURE = '"PROC1"'                        "
 QUEUE "       AND AUTHID = '##AUTHID'                     ;      "
 queue "                                                          "
 QUEUE "INSERT INTO SYSIBM.SYSPROCEDURES                          "
 QUEUE "  (PROCEDURE, AUTHID, LUNAME, LOADMOD, LINKAGE, COLLID,   "
 QUEUE "   LANGUAGE, ASUTIME, STAYRESIDENT, IBMREQD, RUNOPTS,     "
 QUEUE "   PARMLIST, RESULT_SETS, WLM_ENV, PGM_TYPE,              "
 QUEUE "   EXTERNAL_SECURITY, COMMIT_ON_RETURN)                   "
 queue "                                                          "
 QUEUE "VALUES                                                    "
 QUEUE "  ('"PROC1"', '##AUTHID', ' ', '##LOADMOD', ' ',          "
 QUEUE "'##COLLID',                                               "
 QUEUE "'COBOL', 0, 'Y', 'N', '                                   "
/*****************************************************************/
/*   DO FIRST 3 LINES IN ONE INSERT STATEMENT , AFTER THAT, LINES*/
/*   MUST BE UPDATED DUE TO A LIMITATION WITH DB2                */
 QUEUE ""DB2SP07"                                                "
 QUEUE ""DB2SP08"                                                 "
 QUEUE ""DB2SP09"',                                               "
 QUEUE "'"ARRAY.1" "ARRAY.2" "
 QUEUE ""ARRAY.3" "ARRAY.4" "
 QUEUE ""ARRAY.5" "ARRAY.6" '"


 QUEUE "  ,0, ' ', 'M', 'N', 'Y');                                 "
 QUEUE "                                                          "

 IF TOTAL > 6 THEN
 DO A = 7 TO TOTAL

 QUEUE "UPDATE SYSIBM.SYSPROCEDURES                             "
 QUEUE "SET                                                     "
 QUEUE "PARMLIST   = PARMLIST||'"ARRAY.A"'                      "
 QUEUE "WHERE                                                   "
 QUEUE "PROCEDURE='"PROC1"' AND                                 "
 QUEUE "AUTHID='##AUTHID' AND                                   "
 QUEUE "LUNAME=' ';                                             "
 END

address tso

TEST=MSG(off)
 "FREE F(SYSOUT)";
 "DELETE "SYSVAR(SYSUID)"."db2sp03""

 TEST=MSG(OFF)
"free fi(db2pr)"
"ALLOC F(DB2PR) DA("SYSVAR(SYSUID)"."DB2SP03") NEW" ,
    " UNIT(WORK) SPACE(2  2) TRACKS RECFM(F B) LRECL(80)" ,
    " BLKSIZE(0)"

 ADDRESS TSO
 "EXECIO "QUEUED()" DISKW DB2PR (FINIS)"

 ADDRESS ISPEXEC
 DID = DID
 "LMINIT DATAID(DID) DDNAME("DB2PR") ENQ(SHR)"
 "BROWSE DATAID("DID") "
 'LMFREE DATAID('DID')'
 ADDRESS TSO
 TEST=MSG(OFF)
 'FREE F('TRAPDD')'

 EXIT

 TESTEXISTS: PROCEDURE EXPOSE A VARNAMES ALLVARS ERROR
 if pos(varnames,allvars,1) > 0 then do
    Error = 'Duplicate variable name, please re-enter'
    end
 else do
 ERROR=' '
 ALLVARS = ALLVARS||VARNAMES
 A=A+1
 end
 RETURN 0
