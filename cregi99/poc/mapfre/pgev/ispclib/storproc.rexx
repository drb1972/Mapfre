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

IF DB2SP06 = 'G' THEN PARAM = 'GENERAL'
IF DB2SP06 = 'N' THEN PARAM = 'GENERAL WITH NULLS'
IF DB2SP05 = 'N' THEN COR = 'NO'
IF DB2SP05 = 'Y' THEN COR = 'YES'

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
  ARRAY.COUNT = ""inout" "varnames" SMALLINT "
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
  ARRAY.COUNT = ""inout" "varnames" INTEGER  "
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
  ARRAY.COUNT = ""inout" "varnames" REAL     "
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
  ARRAY.COUNT = ""inout" "varnames" FLOAT    "
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
  ARRAY.COUNT = ""inout" "varnames" DOUBLE PRECISION  "
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
  ARRAY.COUNT = ""inout" "varnames" DECIMAL("PP","SS") "
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
  ARRAY.COUNT = ""inout" "varnames" CHARACTER("NNN")   "
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
  ARRAY.COUNT = ""inout" "varnames" VARCHAR("NNNNN") "
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
  ARRAY.COUNT = ""inout" "varnames" GRAPHIC("NNN")  "
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
  ARRAY.COUNT = ""inout" "varnames" VARGRAPHIC("NNNNN")  "
  COUNT = COUNT +1
  END
END
/*****************************************************************/
 QUEUE "DROP PROCEDURE #DB2QUAL."PROC1" RESTRICT;                 "
 QUEUE "CREATE PROCEDURE #DB2QUAL."PROC1"                         "
 DO A=1 TO TOTAL
 INSERT=""ARRAY.A","
 IF A=1 THEN INSERT = "("ARRAY.A","
 IF A=TOTAL THEN INSERT = ""ARRAY.A")"
 IF TOTAL=1 THEN INSERT = "("ARRAY.A")"
 QUEUE ""INSERT"                                                  "
 END
 QUEUE "DYNAMIC RESULT SETS "DB2SP04"                                  "
 QUEUE "EXTERNAL NAME #LOADMOD                                         "
 QUEUE "PARAMETER STYLE "PARAM"                                        "
 QUEUE "LANGUAGE COBOL                                                 "
 QUEUE "COLLID #COLLID                                                 "
 QUEUE "NO WLM ENVIRONMENT                                             "
 QUEUE "STAY RESIDENT YES                                              "
 QUEUE "PROGRAM TYPE MAIN                                              "
 QUEUE "RUN OPTIONS                                                    "
 QUEUE "'H(,,ANY),STAC(,,ANY,),STO(,,,4K),BE(4K,,),LIBS(4K,,)          "
 QUEUE ",RPTOPTS(OFF),ALL31(ON)'                                       "
 QUEUE "COMMIT ON RETURN "COR";                                        "
 QUEUE "GRANT EXECUTE ON PROCEDURE #DB2QUAL."PROC1" TO #SPPARM;     "


address tso

TEST=MSG(off)
 "FREE F(SYSOUT)";
 "DELETE "SYSVAR(SYSUID)"."db2sp03""

 TEST=MSG(OFF)
"free fi(db2pr)"
"ALLOC F(DB2PR) DA("SYSVAR(SYSUID)"."DB2SP03") NEW" ,
    " SPACE(2,2) TRACKS RECFM(F B) LRECL(80)" ,
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
