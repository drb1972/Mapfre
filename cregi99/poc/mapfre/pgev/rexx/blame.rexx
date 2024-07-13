/* REXX */
/* author - Gavin Smith                          */
/* date   - 14/10/99                             */
/* Description - Report on changes to elements   */
/* Usage       - Type TSO CHA                    */
TEST=MSG(off)
cha.0 = none
FOUND=NO
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

     ARG ELEMENT SS
say 'Searching Endevor for latest change....please wait'

 TEST=MSG(off)
"DELETE "sysvar(SYSUID)".BSTIPT01";
"ALLOC F(BSTIPT01) DA("SYSVAR(SYSUID)".BSTIPT01) NEW" ,
    " UNIT(WORK) SPACE(2  2) CYLINDERS RECFM(F B) LRECL(80)" ,
    " BLKSIZE(0)"


 QUEUE " SET OPTIONS CHANGES.                    "
 QUEUE "                PRINT ELEMENT '"element"'"
 QUEUE "             FROM ENVIRONMENT 'PROD'     "
 QUEUE "                       SYSTEM '"SS"'     "
 QUEUE "                    SUBSYSTEM '"SS"1'    "
 QUEUE "                         TYPE '*'        "
 QUEUE "                  STAGE NUMBER '2'       "
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
 "DELSTACK"
 if 'cha.0' = 'none' then do
 SAY
 SAY
 SAY
 SAY
 SAY
 SAY
 SAY
 SAY
 SAY
 SAY
 say 'No changes ever made'
 exit
 end
 if cha.0 = 0 then do
                   SAY
                   SAY
                   SAY
                   SAY
                   SAY
                   SAY
                   SAY
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
      FOUND=YES
    END
  QUEUE ""

 'EXECIO * DISKW 'TRAPDD' (FINIS'

 IF FOUND = NO THEN DO
 SAY 'This Element has never been amended whilst in Endevor'
 EXIT
 END

 ADDRESS ISPEXEC
 'DISPLAY PANEL(blame)'
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


