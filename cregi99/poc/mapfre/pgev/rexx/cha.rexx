/* REXX */
/* author - Gavin Smith                          */
/* date   - 14/10/99                             */
/* Description - Reoprt on changes to element    */
/* Usage  - Type 'TSO changed ss element         */
/*        - e.g.  TSO CHANGED OS DWU9030D        */
TRACE n
do blank=1 to 10;say;end
CCIDSEARCH = 0
CCIDPARM = ' '
type = '*'
address tso
TEST=MSG(off)
 "FREE F(BSTIPT01)";
 "FREE F(C1MSGS1)";
 "FREE F(SYSTERM)";
 "FREE F(SYSABEND)";
 "FREE F(SYSOUT)";
 "FREE F(C1PRINT)";
 "DELETE "SYSVAR(SYSUID)".C1PRINT"
 "DELETE "SYSVAR(SYSUID)".TRAPDD"
 "DELETE "SYSVAR(SYSUID)".TEMP"
 "DELETE "sysvar(SYSUID)"";

say 'Welcome to Change Checker - type  QUIT  at any time to quit'

say 'Please input Element name or Package ID...'
     PULL ELEMENT
     IF ELEMENT = 'QUIT' THEN EXIT
say 'Please input Endevor System...'
     PULL SS
     IF SS = 'QUIT' THEN EXIT
say 'Please input Endevor stage...'
     PULL S_ID
     IF S_ID = 'QUIT' THEN EXIT
say 'Do want a brief summary of the previous changes ? y/n'
     PULL SUMMARY
     IF SUMMARY = 'QUIT' THEN EXIT

     DO WHILE LENGTH(ELEMENT) > 9 | LENGTH(ELEMENT)< 1
     SAY 'ELEMENT NAME MUST BE BETWEEN 1 & 8 CHARS, PLEASE RE-ENTER'
     PULL ELEMENT
     IF ELEMENT = 'QUIT' THEN EXIT
     say 'Thank you '
     END

     DO WHILE LENGTH(SS) ^=2
     SAY 'System ID must be 2 characters - please reenter'
     PULL SS
     IF SS = 'QUIT' THEN EXIT
     say 'Thank you '
     END

     DO WHILE POS(S_ID,'ABCDEFOP',1) = 0
     SAY 'STAGE MUST BE A,B,C,D,E,F,O OR P - PLEASE RE-ENTER'
     PULL S_ID
     IF S_ID = 'QUIT' THEN EXIT
     say 'Thank you '
     end

     IF SUBSTR(ELEMENT,9,1,X) = 'P' THEN DO
        CCID = SUBSTR(ELEMENT,1,8,X)||'001'
        CCIDSEARCH = 1
     END

     SELECT
          WHEN S_ID = 'A'|S_ID='C'|S_ID='E'|S_ID ='O' THEN S_NO = 1
          WHEN S_ID = 'B'|S_ID='D'|S_ID='F'|S_ID ='P' THEN S_NO = 2
     END

     SELECT
          WHEN S_ID = 'A'|S_ID='B' THEN ENV = 'UNIT'
          WHEN S_ID = 'C'|S_ID='D' THEN ENV = 'SYST'
          WHEN S_ID = 'E'|S_ID='F' THEN ENV = 'ACPT'
          WHEN S_ID = 'O'|S_ID='P' THEN ENV = 'PROD'
     END

     say 'Please wait....preparing change report'
     say 'Summary for ' element ' in system ' ss ' at stage ' ,
         S_ID 'type 'type

 TEST=MSG(off)
"DELETE "sysvar(SYSUID)".BSTIPT01";
"ALLOC F(BSTIPT01) DA("SYSVAR(SYSUID)".BSTIPT01) NEW" ,
    " UNIT(WORK) SPACE(2  2) CYLINDERS RECFM(F B) LRECL(80)" ,
    " BLKSIZE(0)"

 if ccidsearch = 1 then do
    element = '*'
    type = '*'
    ccidparm = ' where CCid of all ' CCID
 END

 QUEUE " SET OPTIONS CHANGES.                    "
 QUEUE "                PRINT ELEMENT '"element"'"
 QUEUE "             FROM ENVIRONMENT '"ENV"'    "
 QUEUE "                       SYSTEM '"SS"'     "
 QUEUE "                    SUBSYSTEM '"SS"1'    "
 QUEUE "                         TYPE '"type"'   "
 QUEUE "                  STAGE NUMBER "S_NO"    "
 QUEUE CCIDPARM
 QUEUE ".                                        "

 "FREE F("trapdd")"
 "alloc fi("trapdd") DA( "SYSVAR(SYSUID)".TEMP ) new",
 "unit(vio) space(1 1) track lrecl(133) new reus",
 "blksize(0),recfm (f B)"

 "ALLOC F(C1PRINT) DA("SYSVAR(SYSUID)".C1PRINT) NEW" ,
   " UNIT(WORK) SPACE(2  2) CYLINDERS RECFM(F B) LRECL(80)" ,
   " BLKSIZE(0)"

 "EXECIO "QUEUED()" DISKW BSTIPT01 (FINIS)"
 "ALLOC F(C1MSGS1) SYSOUT(A)";
 "ALLOC F(SYSTERM) SYSOUT(A)";
 "ALLOC F(SYSABEND) SYSOUT(A)";
 "ALLOC F(SYSOUT) SYSOUT(A)";
 "CALL 'SYSENDEV.V3R7M2.CONLIB(NDVRC1)' 'C1BM3000'"
 "EXECIO * DISKR C1PRINT (STEM CHA. FINIS)"
 do blank=1 to 10;say;end

 if cha.0 = 0 then do
                   say 'Nothing found.......'
                   exit
                   end

    DO I=1 TO CHA.0
      IF POS('Computer Associates',CHA.I,1)      > 0 then iterate
      IF POS('*******************',CHA.I,1)      > 0 then iterate
      IF POS('NO CHANGES EXIST AT',CHA.I,1)      > 0 then iterate
      IF POS('PRINT ELEMENT',CHA.I,1)            > 0 then iterate
      IF POS(' **       ',CHA.I,1)               = 1 then iterate
      IF POS('                   ',CHA.I,1)      = 1 then iterate
      IF POS('SOURCE LEVEL INFORMATION',CHA.I,1) > 0 then iterate
      IF POS('-----',CHA.I,1)                    > 0 then iterate
      IF POS('GENERATED',CHA.I,1)                = 2 then DO
 QUEUE '             _________________________________________________'
      QUEUE '           '||substr(CHA.I,12,50,' ')
      queue ' '
      iterate
      END
      IF POS('VV.LL',CHA.I,1)                    > 0 then DO
 QUEUE ' '
 QUEUE '             USER     DATE    TIME        CCID         COMMENT'
      ITERATE
      END
      IF POS('ELEMENT CHANGES',CHA.I,1) > 0 then do
      QUEUE '===========================================',
          ||'===========================================',
          ||'================================='
      QUEUE ' '
      QUEUE ' '
      ITERATE
         END
      IF POS('  01',CHA.I,1) = 1 THEN DO
         IF SUMMARY = 'N' THEN ITERATE
         END
      QUEUE CHA.I
    END

 N = QUEUED() -1
 'EXECIO' N 'DISKW 'TRAPDD' (FINIS'

 address ispexec
 did = did
 "lminit dataid(did) ddname("trapdd") enq(shr)"
 "browse dataid("did")"
 'lmfree dataid('did')'
 address tso
 TEST=MSG(off)
 'free f('trapdd')'

 "FREE F(BSTIPT01)";
 "FREE F(C1MSGS1)";
 "FREE F(SYSTERM)";
 "FREE F(SYSABEND)";
 "FREE F(SYSOUT)";
 "FREE F(C1PRINT)";

 say 'This is the end'
 EXIT 0
