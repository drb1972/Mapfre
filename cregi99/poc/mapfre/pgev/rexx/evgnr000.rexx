/**********************************************************************/
/* Rexx Name    : EVGNR000                                            */
/* Rexx Library : PGEV.BASE.REXX                                      */
/* Rexx Function: Close/Disable & Open/Enable SGTLIB files for        */
/*              : Gener/ol Change Records.                            */
/* Author       : Dean Cherry                                         */
/* Support      : Automated Operations                                */
/* Related Execs: None                                                */
/* Related Glvs : GLVTEMP1.PRCIY#D1.*                                 */
/* Related Rules: EVGNR001                                            */
/* History      : 04/05/2005 Gener/OL Code Migration.                 */
/**********************************************************************/
Signal On Syntax name ERROR
Signal On Error
/* Trace R */
Arg ACTION

Do Lock = 1 to 13
   EXC = Opsenq('E','AUTO_OPS','GENEROL','E','SYSTEMS','USE')
   If EXC = 0 Then Leave
   Pause = Opswait(5)
End
If EXC ^= 0 Then Exit 16

Del = Opsvalue('GLVTEMP1.PRCIY#D1','R')
FILES = 'SGTLIB8 SGTLIB9'
Do Loop = 1 to Words(FILES)
   FILE = Word(FILES,loop)
   FILE_CMD = "MODIFY PRCIY#D1,CEMT SET FILE("FILE")" ACTION
   Address TSO "OPSCMD C("FILE_CMD")"
End
Do Check = 1 to 12
   SUCCESS = ''
   Pause = Opswait(5)
   Do Check1 = 1 to 2
      CLEARQ = Opscledq()
      FILE = Word(FILES,Check1)
      If Opsvalue('GLVTEMP1.PRCIY#D1.'FILE,'F') = 'I' Then Do
         Pull DATA
         If Words(DATA) ^= 2 Then Leave
         If ACTION = 'OPE ENA' Then Do
            If Wordpos('OPEN',DATA) > 0 & ,
               Wordpos('ENABLED',DATA) > 0 Then SUCCESS = SUCCESS'YES'
         End
         If ACTION = 'CLO DIS' Then Do
            If Wordpos('CLOSED',DATA) > 0 & ,
               Wordpos('DISABLED',DATA) > 0 Then SUCCESS = SUCCESS'YES'
         End
      End
   End
   If SUCCESS = 'YESYES' Then Leave Check
End

CLEARQ = Opscledq()
FREE = Opsenq('D','AUTO_OPS','GENEROL','E','SYSTEMS','NONE')
If FREE ^= 0 Then Exit 16
If SUCCESS ^= 'YESYES' Then Exit 12

Exit

ERROR:
FREE = Opsenq('D','AUTO_OPS','GENEROL','E','SYSTEMS','NONE')
say 'RC = 'RC' at line = 'SIGL
exit RC
