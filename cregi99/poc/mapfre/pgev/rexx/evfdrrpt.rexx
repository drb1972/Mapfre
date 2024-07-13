/*----------------------------------REXX----------------------------*\
 *  Read output from FDREPORTS and build condense, migrate           *
 *  and ALTERDIR for datasets that need it.                          *
 *                                                                   *
 *  This rexx is executed from job EVHSPCED.                         *
 *                                                                   *
\*-------------------------------------------------------------------*/
signal on syntax  name exception /* Required for ISPF batch only     */
signal on failure name exception /* Required for ISPF batch only     */

parse source . . rexxname . . . . addr .
if sysdsn("'TTEV.TRACE."rexxname"'") = 'OK' then trace i

arg autoos

say rexxname':' Date() Time()
say rexxname':'
say rexxname': AUTOOS....' autoos
say rexxname':'

if right(autoos,1) = '.' then
   autoos = left(autoos,(length(autoos) - 1))

return_code = 0 /* set initial return code to zero                   */
jc  = 0 /* set jc to false                                           */

address ispexec
/* Open output files with LM                                         */
"lminit  dataid(autodata) dataset('"autoos".data') enq(shrw)"
if rc ^= 0 then call exception rc 'LMINIT of AUTODATA failed'
"lminit  dataid(autojobs) dataset('"autoos".jobs') enq(shrw)"
if rc ^= 0 then call exception rc 'LMINIT of AUTOJOBS failed'

"lmopen  dataid("autodata")  option(output)"
if rc ^= 0 then call exception rc 'LMOPEN of AUTODATA failed'
"lmopen  dataid("autojobs")  option(output)"
if rc ^= 0 then call exception rc 'LMOPEN of AUTOJOBS failed'

/* Write the JCL for EVHSPACD                                        */
queue "//EVHSPACD JOB 1,CLASS=N,MSGCLASS=Y,USER=HKPGEND"
queue "//*"
queue "//STEP000  EXEC PGM=IEFBR14"
queue "//DD1      DD DSN=PREV.REPORTS.PDS.CONDENSE,DISP=(MOD,DELETE),"
queue "//             SPACE=(TRK,(0,0)),LRECL=80,RECFM=FB"
queue "//*"
queue "//DD2      DD DSN=PREV.REPORTS.PDS.CONDENSD,DISP=(MOD,DELETE),"
queue "//             SPACE=(TRK,(0,0)),LRECL=80,RECFM=FB"
queue "//*"
call lmput autojobs

/* read in file created by the FDREPORT program for multi extents    */
address tso
"execio * diskr repext (stem line. finis"
if rc ^= 0 then call exception rc 'DISKR of REPEXT failed'

jc  = 0 /* set jc to false                                           */

do a = 1 to line.0

  b = a - 1 /* set up a minus 1 counter                              */

  parse value line.a with dsn.a dsorg.a rest
  dsn.a = strip(dsn.a,l,'0') /* remove ascii print characters        */
  dsn.a = strip(dsn.a)       /* remove leading and trailing blanks   */

  if left(dsn.a,4) = 'PREV' then do
    if pos('EVHSPCED',dsn.a) > 0 then iterate /* stops abend         */
    if pos('.SMG',dsn.a) > 0 then iterate /* reorg dataset           */
    if pos('.INDEX',dsn.a) > 0 & dsorg = 'EF' then iterate

    x = pos('.DATA',dsn.a) /* Is it VSAM?                            */

    if x > 0 & dsorg.a = 'EF' then do /* If it is VSAM               */
      dsn.a = substr(dsn.a,1,(x-1)) /* remove .data part of the name */
    end /* x > 0 & dsorg.a = 'EF' */

    if dsn.a = dsn.b then iterate /* duplicate dataset name          */

    /* Build the top of the generated job                            */
    if jc = 0 then do
      queue "//CONDENSE EXEC PGM=ADRDSSU"
      queue "//********************************************"
      queue "//* CONSOLIDATE IN TO SINGLE EXTENT          *"
      queue "//********************************************"
      queue "//SYSPRINT DD DSN=PREV.REPORTS.PDS.CONDENSD,"
      queue "//             DISP=(NEW,CATLG),"
      queue "//             SPACE=(TRK,(15,15)),LRECL=134,"
      queue "//             RECFM=FBA"
      queue "//FILTERDS DD *"
      queue " INCLUDE(  -"
      jc = 1
    end /* jc = 0 */
    queue '     ' left(dsn.a,44) '-' /* queue dataset name           */
    say "EVFDRRPT:" dsn.a "will be condensed"

  end /* left(dsn,4) = 'PREV' */

end /* a = 1 to line.0 */

if jc = 1 then do
  queue "//SYSIN    DD *                    "
  queue " COPY DATASET(FILTERDD(FILTERDS)) -"
  queue "     ALLDATA(*) -                  "
  queue "     ALLEXCP -                     "
  queue "     CANCELERROR -                 "
  queue "     CATALOG -                     "
  queue "     DELETE -                      "
  queue "     PURGE -                       "
  queue "     TGTALLOC(TRK) -               "
  queue "     TGTGDS(SOURCE) -              "
  queue "     WAIT(2,2)                     "
  queue "/*                                 "
  queue "//CHECKIT  IF CONDENSE.RC GT 8 THEN"
  queue "//@SPWARN  EXEC @SPWARN       "
  queue "//CHECKIT  ENDIF"
  queue "//*"
  queue "//CHECK2   IF CONDENSE.RC GT 4 THEN"
  queue "//*"
  queue "//FILEAID  EXEC PGM=FILEAID"
  queue "//SYSPRINT DD SYSOUT=*"
  queue "//SYSLIST  DD SYSOUT=*"
  queue "//DD01     DD DISP=SHR,DSN=PREV.REPORTS.PDS.CONDENSD"
  queue "//DD01O    DD DSN=PREV.REPORTS.PDS.CONDENSE,"
  queue "//             DISP=(NEW,CATLG),"
  queue "//             SPACE=(TRK,(15,15),RLSE),LRECL=134,"
  queue "//             RECFM=FBA"
  queue "//SYSIN    DD *"
  queue "$$DD01 SPACE STOP=(1,0,C'ADR455W')"
  queue "$$DD01 USER  IF=(32,NE,C'DFSMSDSS'),"
  queue "             STOP=(1,0,C'ADR454I'),WRITE=DD01O"
  queue "//*"
  queue "//CHECKIT  IF FILEAID.RC GT 8 THEN"
  queue "//@SPWARN  EXEC @SPWARN       "
  queue "//CHECKIT  ENDIF"
  queue "//*"
  queue "//CHECK3   IF FILEAID.RC EQ 0 THEN"
  queue "//SENDMAIL EXEC PGM=IKJEFT1B,DYNAMNBR=256, "
  queue "//             PARM='%SENDMAIL DEFAULT LOG(YES)'"
  queue "//SYSEXEC  DD DSN=SYSTSO.BASE.EXEC,DISP=SHR"
  queue "//SYSTSPRT DD SYSOUT=*                     "
  queue "//SYSTSIN  DD DUMMY                        "
  queue "//SYSADDR  DD *                            "
  queue "  FROM: mapfre.endevor@rsmpartners.com"
  queue "  TO: VERTIZOS@kyndryl.com"
  queue "  SUBJECT: EPLEX - EVHSPACD - CONDENSE OUTPUT FOR REVIEW"
  queue "/*                                         "
  queue "//SYSDATA  DD DSN=PREV.REPORTS.PDS.CONDENSE,DISP=SHR "
  queue "//CHECK3   ENDIF"
  queue "//CHECK2   ENDIF"
  queue "//*                                               "
  queue "//EMAILC   IF SENDMAIL.RC NE 0 THEN              "
  queue "//@SPWARN  EXEC @SPWARN                           "
  queue "//EMAILC   ENDIF                                  "
  queue "//*                                               "
  call lmput autojobs
end /* jc = 1 */
say "EVFDRRPT:"

/* read in the file created by FDREPORT for directory blocks         */
"execio * diskr repdir (stem line. finis"
if rc ^= 0 then call exception rc 'DISKR of REPDIR failed'

jc  = 0 /* set jc to false                                           */
do a = 1 to line.0
  parse var line.a  1 .  2 dsn 45 . ,
                        47 dsorg    ,
                        50 dirused  ,
                        56 diral    ,
                        62 dirfr    ,
                        68 rest
  dsn = strip(dsn)

  if left(dsn,4) = 'PREV' then do
    if pos('EVHSPCED',dsn) > 0 then iterate /* stops abend           */

    if dirused = 0 then iterate /* bad input from FDR report         */

    /* Build the JCL step                                            */
    if jc = 0 then do
      queue "//ALTERDIR EXEC PGM=IEBCOPY"
      queue "//SYSPRINT DD SYSOUT=*"
      jc = 1
    end /* jc = 0 */

    /* Work out new total of directory blocks required               */
    dirreq = trunc(dirused * 1.3)
    dirreq = (dirreq % 45) * 45 + 44
    say "EVFDRRPT: Dataset" dsn "will be resized by EVHSPACD"
    say "EVFDRRPT: The original number of directory blocks was" diral
    say "EVFDRRPT: The original free directory blocks was" dirfr
    say "EVFDRRPT: The new number of directory blocks is" dirreq
    say "EVFDRRPT:"
    z = left(a,5,' ')
    queue "//PDS"z" DD DSN="dsn",DISP=SHR"
    call lmput autojobs
    queue " ALTERDIR  OUTDD=PDS"a",BLOCKS="dirreq
    call lmput autodata

  end /* left(dsn,4) = 'PREV' */

end /* a = 1 to line.0 */

if jc = 1 then do /* if alterdir created, then finish the JCL off    */
  queue "//SYSIN    DD DSN="autoos".DATA(EVHSPACD),DISP=SHR"
  queue "//*                           "
  queue "//CHECKIT  IF ALTERDIR.RC GT 0 THEN"
  queue "//@SPWARN  EXEC @SPWARN       "
  queue "//CHECKIT  ENDIF"
  queue "//*"
  call lmput autojobs
end /* jc = 1 then */

/* read in the file created by FDREPORT for ds with 0 sec ext & full */
"execio * diskr repzero (stem line. finis"
if rc ^= 0 then call exception rc 'DISKR of REPZERO failed'

do a = 1 to line.0
  parse value line.a with dsn rest
  dsn = strip(dsn,l,'0')

  if left(dsn,4) = 'PREV' then do
    if pos('EVHSPCED',dsn) > 0 then iterate /* stops abend           */
    queue left(dsn,30) /* queue dataset name                         */
  end /* left(dsn,4) = 'PREV' */

end /* a = 1 to line.0 */

if queued() > 0 then do
  "execio * diskw email (finis"
  if rc ^= 0 then call exception rc 'DISKW to EMAIL failed'
  return_code = 1 /* set return code to trigger email                */
end /* queued() > 0 */

/* read in the file created by FDREPORT for datasets to migrate      */
"execio * diskr repmig (stem line. finis"
if rc ^= 0 then call exception rc 'DISKR of REPMIG failed'

do a = 1 to line.0
  parse value line.a with dsn dsorg rest
  dsn = strip(dsn,l,'0') /* remove ascii print characters            */
  dsn = strip(dsn) /* remove leading and trailing blanks             */

  if left(dsn,4) = 'PREV' then do
    if pos('EVHSPCED',dsn) > 0 then iterate /* stops abend           */
    if pos('.INDEX',dsn) > 0 & dsorg = 'EF' then iterate

    if pos('.DATA',dsn) > 0 & dsorg = 'EF' then do /* Is it VSAM     */
      x = pos('.DATA',dsn)
      dsn=substr(dsn,1,(x-1)) /* remove the .data part of the name   */
    end /* pos('.DATA',dsn) & dsorg = 'EF' */

    if pos('.SMG',dsn) > 0 then do /* Is it a .SMG file              */
      if pos('.DATA',dsn) > 0 & dsorg = 'EF' then do /* Is it VSAM   */
        x = pos('.DATA',dsn)
        dsn=substr(dsn,1,(x-1)) /* remove the .data part of the name */
      end /* pos('.DATA',dsn) > 0 & dsorg = 'EF' */

      /* Change the management class of .SMG datasets to SMGFILES    */
      "ALTER '"dsn"' MGMTCLAS(SMGFILES)"
      if rc ^= 0 then call exception rc 'ALTER of' dsn 'failed'
      say 'EVFDRRPT: Management class of' dsn 'changed to SMGFILES.'

    end /* pos('.SMG',dsn) > 0 */

    "HMIGRATE '"dsn"' ML2 NOWAIT EXTENDRC"
    if rc ^= 0 then call exception rc 'Migrate of' dsn 'failed'
    say 'EVFDRRPT: Dataset' dsn 'has been migrated.'

  end /* left(dsn,4) = 'PREV' */
end /* a = 1 to line.0 */

/* Write out the output cards to autoos libraries                    */
address ispexec
"lmmrep dataid("autojobs") member(EVHSPACD)"
if rc = 0 | rc = 8 then nop
else call exception rc 'LMMREP of AUTOJOBS failed'

if jc = 1 then do /* if alterdir step was created, then write data   */
  "lmmrep dataid("autodata") member(EVHSPACD)"
  if rc = 0 | rc = 8 then nop
  else call exception rc 'LMMREP of AUTODATA failed'
end /* jc = 1 */

"lmclose dataid("autojobs")"
"lmfree dataid("autojobs")"
"lmclose dataid("autodata")"
"lmfree dataid("autodata")"

zispfrc = return_code
'vput (zispfrc) shared'

exit return_code

/* +---------------------------------------------------------------+ */
/* | Write out the output cards to autoos library                  | */
/* +---------------------------------------------------------------+ */
lmput:
 arg lib
 did = value(value(lib))
 do lm = 1 to queued()
   pull datal
   address ispexec ,
    "lmput dataid("did") mode(invar) dataloc(datal) datalen(80)"
   if rc ^= 0 then call exception rc 'LMPUT to' did 'failed'
 end /* lm = 1 to queued() */
return /* lmput: */

/*-------------------------------------------------------------------*/
/* Error with line number displayed - for IKJEFT ISPF                */
/*-------------------------------------------------------------------*/
exception:
 parse arg return_code comment

 /* This if is for ISPF in batch only                                */
 if wordpos(condition('C'),'SYNTAX FAILURE') > 0 then do
   say 'Line' sigl':' left(sourceline(sigl),70)
   say 'Errortext:' errortext(rc)
   return_code = rc
   comment     = condition('C') 'failure at line' sigl
 end /* wordpos(condition('C'),'SYNTAX FAILURE') > 0 */

 say rexxname':'
 say rexxname':' comment'. RC='return_code
 say rexxname': Exception called from line' sigl

 z = msg(off)
 address tso 'delstack' /* Clear down the stack                      */
 z = msg(on)

 if return_code < 0 then return_code = 12 /* - RCs can be invalid    */

 zispfrc = return_code
 address ispexec "vput (zispfrc) shared"

exit return_code

