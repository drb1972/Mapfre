/*--------------------------REXX---------------------------------*\
 *  Read a list of PREV datasets and build PDSM37 SELECT         *
 *  statements for GENERATE & COMPARE.                           *
 *  Also build a job to create temp composite datasets from the  *
 *  PREV.P datasets.                                             *
 *                                                               *
 *  Executed by : JOB EVGCMP1W                                   *
\*---------------------------------------------------------------*/
trace n
arg id      /* TT or PG for output DSN prefix */

say 'CMPBUILD: ' DATE() TIME()
say 'CMPBUILD:'
say 'CMPBUILD: Build PDSM37 SELECT statements'
say 'CMPBUILD:'
say 'CMPBUILD:  *** Input parameters ***'
say 'CMPBUILD: id.....' id
say

/* These are the only valid composite DSNs, all new ones should be   */
/* handled by PREV.P aliases to a composite PREV.P dataset.          */
compo_dsns = 'PGBT.BASE.LOAD PGOS.BASE.GPRXLIB PGRG.BASE.DATA' ,
             'PGSP.BASE.P#11CICS'
d = 0 /* Number of new composite DSNs                                */

/* Read the excluded hlqs member and apply the data to this rexx */
exclude_selects = ''
"execio * diskr EXCLUDES (stem exclude. finis" /* DSN list */
if rc ^= 0 then call exception 20 'DISKR from EXCLUDES failed RC='rc
do i = 1 to exclude.0
  exclude_selects = exclude_selects strip(exclude.i)
end /* i = 1 to exclude.0 */
say 'CMPBUILD: The following HLQs will be excluded...'
say exclude_selects

/* Read the merged shipment rules dataset */
"execio * diskr RULES (stem rule. finis" /* DSN list */
if rc ^= 0 then call exception 20 'DISKR from RULES failed RC='rc

/* Read the composite dataset list        */
"execio * diskr COMPOSIT (stem compo. finis"
if rc ^= 0 then call exception 20 'DISKR from COMPOSIT failedRC ='rc

/* Build stem varaibles for the composite datasets */
c = 0 /* number of composite source datasets */
do i = 1 to compo.0
  prev_dsn = word(compo.i,2)
  tgt_dsn  = word(compo.i,7)
  /* This next line is temporary because PREV.PSP1.CICS maps to      */
  /* PGSP.BASE.CICS on the C&D plexes. On other plexes its mapped to */
  /* PGSP.BASE.P#11CICS which is composite so would be excluded.     */
  if prev_dsn ^= 'PREV.PSP1.CICS' then
    x = value(prev_dsn,'compo')
  if tgt_dsn ^= prev_tgt then do /* Build 1 variable for each compo  */
    if substr(tgt_dsn,6,4) = 'BASE' then
      sys = substr(tgt_dsn,3,2)
    else
      sys = substr(tgt_dsn,7,2)
    composite_dsn = 'PREV.P'sys'1.'substr(tgt_dsn,11)'.COMPOSIT.BASELIB'
    c = c + 1
    compo_dsn.c = tgt_dsn composite_dsn
  end /* tgt_dsn ^= prev_tgt */
  compo_dsn.c = compo_dsn.c prev_dsn /* Add PREV DSN to the variable */
  prev_tgt = tgt_dsn
  if wordpos(tgt_dsn,compo_dsns) = 0 then do
    d = d + 1
    new_compo.d = prev_dsn tgt_dsn
  end /* wordpos(tgt_dsn,compo_dsns) = 0 */
end /* i = 1 to compo.0 */

/* Build PDSM37 SELECT statements for Qplex PREV GENERATE */
do i = 1 to rule.0
  prev_dsn = word(rule.i,2)
  if value(prev_dsn)   ^= 'compo'   & ,
     right(prev_dsn,7) ^= '.CMPARM' & ,
     pos(substr(prev_dsn,3,7),exclude_selects) = 0 then
    queue ' SELECT DSN='prev_dsn
end /* i = 1 to rule.0 */
do i = 1 to c   /* add composite libraries */
  tgt_dsn       = word(compo_dsn.i,1)
  composite_dsn = word(compo_dsn.i,2)
  if wordpos(left(tgt_dsn,9),exclude_selects) = 0 then
    queue ' SELECT DSN='composite_dsn
end /* i = 1 to c */
say
say 'CMPBUILD:  Writing' queued() 'lines to QSELECTS'
"execio * diskw QSELECTS (finis"
if rc ^= 0 then call exception 20 'DISKW to QSELECTS failed RC='rc

/* Build SELECT statements for the COMPARE   */
do i = 1 to rule.0
  prev_dsn = word(rule.i,2)
  if value(prev_dsn)   ^= 'compo'   & ,
     right(prev_dsn,7) ^= '.CMPARM' & ,
     pos(substr(prev_dsn,3,7),exclude_selects) = 0 then do
    tgtdsn = word(rule.i,7)
    dsnlen = length(tgtdsn)
    queue ' SELECT DSN='tgtdsn
    if prev_dsn ^= tgtdsn then
      if dsnlen > 25 then do
        queue ' SELECT DSN='prev_dsn','
        queue '        ALTNAME='tgtdsn
      end /* dsnlen > 26 */
      else
        queue ' SELECT DSN='prev_dsn',ALTNAME='tgtdsn
  end /* value(prev_dsn) ^= 'compo' & .. not excluded */
end /* i = 1 to rule.0 */
do i = 1 to c   /* add composite libraries */
  tgt_dsn       = word(compo_dsn.i,1)
  composite_dsn = word(compo_dsn.i,2)
  queue ' SELECT DSN='tgt_dsn
  queue ' SELECT DSN='composite_dsn','
  queue '  ALTNAME='tgt_dsn
end /* i = 1 to c */
say
say 'CMPBUILD:  Writing' queued() 'lines to COMPARE'
"execio * diskw COMPARE (finis"
if rc ^= 0 then call exception 20 'DISKW to COMPARE failed RC='rc

/* Create a job to build composite PREV DSNs */
if c > 0 then
  call buildjob

exit

/*---------------------- S U B R O U T I N E S -----------------------*/

/*---------------------------------------------------------------*/
/* Build job for creating composite datasets                     */
/*---------------------------------------------------------------*/
Buildjob:

 say
 say 'CMPBUILD: Building JCL for creating composite datasets'
 say 'CMPBUILD:'

 if id = 'TT' then do
   jpref    = 'TT'
   class    = 'C'
   msgclass = '0'
   baseev   = 'TTEV.COMPARE'
 end
 else do /* id = 'TT' */
   jpref    = 'EV'
   class    = 'P'
   msgclass = 'Y'
   baseev   = 'PGEV.BASE'
 end /* else */
 queue '//'jpref'GCMP4W JOB CLASS='class',MSGCLASS='msgclass
 queue '//*                                               '
 do i = 1 to c
   tgt_dsn       = word(compo_dsn.i,1)
   composite_dsn = word(compo_dsn.i,2)
   sysprint_dsn  = id'EV.NENDEVOR.COMPARE.COMPOSIT.BUILD'
   say 'CMPBUILD: Will create' composite_dsn 'from'

   queue '//*                                                      '
   queue '//* DELETE EXISTING FILES                                '
   queue '//STEP000  EXEC PGM=IEFBR14                              '
   queue '//DD1      DD DSN='composite_dsn','
   queue '//             DISP=(MOD,DELETE),SPACE=(TRK,(0,0))       '
   if i = 1 then do
     queue '//DD2      DD DSN='sysprint_dsn','
     queue '//             DISP=(MOD,DELETE),SPACE=(TRK,(0,0))     '
     queue '//DD3      DD DSN='sysprint_dsn'.SUMMARY,              '
     queue '//             DISP=(MOD,DELETE),SPACE=(TRK,(0,0))     '
   end /* i = 1 */
   queue '//*                                                      '
   queue '//* CREATE COMPOSITE DATASETS                            '
   queue '//STEP'right(i,3,'0') ' EXEC PGM=IEBCOPY                 '
   queue '//FCOPYON  DD DUMMY                                      '
   if i = 1 then do
     queue '//SYSPRINT DD DSN='sysprint_dsn','
     queue '//           DISP=(,CATLG,DELETE),SPACE=(TRK,(45,15)), '
     queue '//           RECFM=FBA,LRECL=122,BLKSIZE=0             '
   end /* i = 1 */
   else
     queue '//SYSPRINT DD DISP=MOD,DSN='sysprint_dsn
   /* Add a DD statement for each PREV dsn */
   do ii = 3 to words(compo_dsn.i)
     prev_dsn = word(compo_dsn.i,ii)
     queue '//PDSIN'right(ii,3,'0') 'DD DSN='prev_dsn',DISP=SHR'
     say 'CMPBUILD:  ' prev_dsn
   end /* ii = 3 to words(compo_dsn.i) */
   /* Add a DD statement for the output composite dsn */
   queue '//PDSOUT   DD DISP=(NEW,CATLG),DSN='composite_dsn','
   if tgt_dsn = 'PGSP.BASE.P#11CICS' then
     queue '//            SPACE=(CYL,(900,95,7000)),BLKSIZE=20000, '
   if left(tgt_dsn,6) = 'PGEV.P' then
     tgt_dsn = overlay('R',tgt_dsn,2)
   queue '//            DSNTYPE=PDS,LIKE='tgt_dsn
   queue '//SYSIN    DD *                                          '
   /* Add a IEBCOPY control cards                     */
   do ii = 3 to words(compo_dsn.i)
     queue ' COPY OUTDD=PDSOUT,INDD=((PDSIN'right(ii,3,'0')'))'
   end /* ii = 3 to words(compo_dsn.i) */
   queue '  EXCLUDE  MEMBER=$$$SPACE                               '
   queue '/*                                                       '
   queue '//*                                                      '
   queue '//CHECKIT  IF STEP'right(i,3,'0')'.RC GT 4 THEN'
   queue '//STEP'right(i,3,'0')'C EXEC @SPWARN'
   queue '//CHECKIT  ENDIF                                         '
 end /* i = 1 to c */

 /* Add JCL to build SUMMARY dataset and email */
 queue '//*                                                        '
 queue '//SUMMARY  EXEC PGM=ICETOOL                                '
 queue '//SYSOUT   DD SYSOUT=*                                     '
 queue '//SORTIN   DD DISP=SHR,DSN='sysprint_dsn
 queue '//SORTOUT  DD DSN='sysprint_dsn'.SUMMARY,'
 queue '//           DISP=(,CATLG,DELETE),SPACE=(TRK,(45,15)),     '
 queue '//           RECFM=FBA,LRECL=122,BLKSIZE=0                 '
 queue '//SORTDUM  DD DUMMY                                        '
 queue '//DFSMSG   DD SYSOUT=*                                     '
 queue '//TOOLMSG  DD SYSOUT=*                                     '
 queue '//CMP1CNTL DD DISP=SHR,DSN='baseev'.DATA(CMPCMPO1)'
 queue '//CMP2CNTL DD DISP=SHR,DSN='baseev'.DATA(CMPCMPO2)'
 queue '//TOOLIN   DD DISP=SHR,DSN='baseev'.DATA(CMPCMPOT)'
 queue '//*                                                        '
 queue '//CHECKIT  IF SUMMARY.RC GT 4 THEN                         '
 queue '//SUMMARYC EXEC @SPWARN                                    '
 queue '//CHECKIT  ENDIF                                           '
 queue '//*                                                        '
 queue '//@00200   IF SUMMARY.RC = 4 THEN                          '
 queue '//SENDMAIL EXEC PGM=IKJEFT1A,DYNAMNBR=256,                 '
 queue "// PARM='%SENDMAIL REMLVEURGW06.SERVER.RBSGRP.NET LOG(YES)",
       "DEBUG'"
 queue '//SYSPROC  DD DSN=SYSTSO.BASE.EXEC,DISP=SHR                '
 queue '//SYSTSPRT DD SYSOUT=*                                     '
 queue '//SYSTSIN  DD DUMMY                                        '
 queue '//SYSADDR  DD DISP=SHR,DSN='baseev'.DATA(CMPCMPO4)'
 queue '//SYSDATA  DD DSN='sysprint_dsn'.SUMMARY,'
 queue '//            DISP=SHR                                     '
 queue '//*                                                        '
 queue '//EMAILC   IF SENDMAIL.RC GT 0 THEN                        '
 queue '//SENDMAIC EXEC @SPWARN                                    '
 queue '//EMAILC   ENDIF                                           '
 queue '//@00200   ENDIF                                           '

 if d > 0 then do /* Invalid new composite DSNs                      */
   queue '//*                                                        '
   queue '//SENDMAI2 EXEC PGM=IKJEFT1A,DYNAMNBR=256,                 '
   queue "// PARM='%SENDMAIL REMLVEURGW06.SERVER.RBSGRP.NET LOG(YES)",
         "DEBUG'"
   queue '//SYSPROC  DD DSN=SYSTSO.BASE.EXEC,DISP=SHR                '
   queue '//SYSTSPRT DD SYSOUT=*                                     '
   queue '//SYSTSIN  DD DUMMY                                        '
   queue '//SYSADDR  DD *                                            '
   queue '    FROM: mapfre.endevor@rsmpartners.com       '
   queue '    TO:   VERTIZOS@kyndryl.com                  '
   queue ' SUBJECT: EPLEX - EVGCMP4W - Invalid new composite datasets'
   queue '/*                                                         '
   queue '//SYSDATA  DD *                                            '
   queue ' The following stage P datasets ship to the same target' ,
         'BASE dataset.'
   queue ' These should be converted to PREV.P aliases to a' ,
         'composite stage P dataset.'
   queue ' The datasets are...                                       '
   do i = 1 to d
     queue '  ' new_compo.i
   end /* i = 1 to d */
   queue '/*                                                         '
   queue '//*                                                        '
   queue '//* Always fail until the new composite datasets are sorted'
   queue '//NEWCOMPO EXEC @SPWARN                                    '
 end /* d > 0 */

 say 'CMPBUILD:  Writing' queued() 'lines to COMPJCL'
 "execio * diskw COMPJCL (finis"
 if rc ^= 0 then call exception 20 'DISKW to COMPJCL failed RC='rc

return /* Buildjob */

/*---------------------------------------------------------------*/
/* Error with line number displayed                              */
/*---------------------------------------------------------------*/
exception:
 parse arg return_code comment

 do i = 1 to queued() /* Clear down the stack */
   pull
 end

 parse source . . rexxname . /* Get the rexx name (generic subroutine)*/
 say rexxname':'
 say rexxname':' comment
 say rexxname': Exception called from line' sigl

exit return_code
