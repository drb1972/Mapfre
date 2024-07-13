/*-----------------------------REXX----------------------------------*\
 *  Read a list of non Endevor controlled BASE 7 PGEV.P datasets     *
 *  and split them into datasets with a corresponding Endevor        *
 *  system and the rest.                                             *
 *                                                                   *
 *  Email new base dataset for checking                              *
 *                                                                   *
 *  Executed by : JOB EVGSHP%D                                       *
\*-------------------------------------------------------------------*/
trace n

parse source . . rexxname .
say rexxname':' Date() Time()

true      = 1
false     = 0
/* Table of base dataset prefixes that are excluded from the newly   */
/* created base dataset reporting.                                   */

excldsn.1 = 'PGEV.PRO4.RELEASE.NEW'
excldsn.2 = 'PGOS.BASE.BTP'
excldsn.3 = 'PGOS.BASE.PFIX.RBSINS'
excldsn.4 = 'PGSH.BASE.PRODFIX'
excldsn.5 = 'PGOS.BASE.SYSP'
excldsn.6 = 'PGSP.BASE.SSL.SSLCERT'
excldsn.7 = 'PGOS.BASE.PRODFIX'
excldsn.0 = 7

do i = 1 to excldsn.0
  x         = length(excldsn.i)
  excldsn.i = excldsn.i x
end /* i = 1 to excldsn.0 */

ecount    = 0 /* Count of DSNs with    an Endevor system             */
ncount    = 0 /* Count of DSNs without an Endevor system             */
ccount    = 0 /* Count of newly created BASE dsns                    */
scount    = 0 /* Count of datyasets newly suspressed from shipment   */
yesterday = date('S',date('B')-1,'B')
sysplex   = mvsvar('sysplex')
plexid    = substr(sysplex,5,1)

/* Read the Endevor system list                                      */
"execio * diskr SYSTEMS (stem sys. finis"
if rc ^= 0 then call exception rc 'DISKR of SYSTEMS failed'
/* Set up the system. stem variable                                  */
system. = false
do i = 1 to sys.0
  sys        = substr(sys.i,22,2)
  system.sys = true
end /* i = 1 to sys.0 */
drop sys.
system.RG = true /* Add the common system name                       */

/* Read yesterday's NDVR output file                                 */
"execio * diskr OLDNDVR (stem old. finis"
if rc ^= 0 then call exception rc 'DISKR of OLDNDVR failed'
/* Set up the already_known. stem variable                           */
already_known. = false
do i = 1 to old.0
  dsn_name               = word(old.i,1)
  already_known.dsn_name = true
end /* i = 1 to old.0 */
drop old.

/* Read the shipment rules                                           */
"execio * diskr RULES (stem rules. finis"
if rc ^= 0 then call exception rc 'DISKR of RULES failed'

/* Set up the rules. stem variable                                   */
rule. = true
do i = 1 to rules.0
  tgtdsn = strip(substr(rules.i,84,40))
  rule.tgtdsn = false
  if right(tgtdsn,7) = '.CMPARM' then do
    len    = length(tgtdsn)
    tgtdsn = substr(tgtdsn,1,len-7)
    rule.tgtdsn = false
  end /* right(tgtdsn,7) = '.CMPARM' */
end /* i = 1 to rules.0 */
drop rules.

/* Read the BASE & PGEV.P dataset list                               */
"execio * diskr BASEDSNS (stem base. finis"
if rc ^= 0 then call exception rc 'DISKR of BASEDSNS failed'
/* Split the DSNs and check for newly created base datasets          */
do i = 1 to base.0
  dsn = word(base.i,1)
  typ = word(base.i,2)
  sys = substr(dsn,3,2)
  cre = right(word(base.i,3),5)

  /* Check the creation date and report if it was yesterday          */
  if cre ^= '' then do
    cre = date('S',cre,'J')
    if cre             = yesterday & ,
       substr(dsn,6,4) = 'BASE'    then do
      do ii = 1 to excldsn.0
        excldsn = word(excldsn.ii,1)
        excllen = word(excldsn.ii,2)
        if left(dsn,excllen) = excldsn then iterate i
      end /* ii = 1 to excldsn.0 */
      ccount = ccount + 1
      dsncre.ccount = dsn
      say rexxname': Base DSN created yesterday:' dsn
    end /* cre = yesterday */
  end /* cre ^= '' */

  /* Check for datasets that are not Endevor controlled              */
  if rule.dsn then do     /* Not Endevor controlled                  */
    if system.sys then do /* With a corresponding Endevor system     */
      ecount = ecount + 1
      endevor.ecount = left(dsn,45) word(base.i,2)
      /* check for dsets not reported yesterday (something changed!) */
      if ^already_known.dsn then do
        if typ <> 'GDS' then do /* don't report GDG files            */
          scount = scount + 1
          suppressed.scount = left(dsn,45) word(base.i,2)
          already_known.dsn = true /* only report dataset once */
        end /* typ <> 'GDS' */
      end /* ^already_known.dsn */
    end /* system.sys */
    else do               /* Without a corresponding Endevor system  */
      ncount = ncount + 1
      non.ncount = left(dsn,45) word(base.i,2)
    end /* else */
  end /* rule.dsn */

end /* i = 1 to base.0 */

say rexxname':'
say rexxname': NON Endevor controlled datasets'
say rexxname':'
say rexxname':' left(ecount,4) 'datasets with    an Endevor system'
say rexxname':' left(ncount,4) 'datasets without an Endevor system'
say rexxname':' left(scount,4) 'newly suppressed datasets'
say rexxname':'
say rexxname': The DSN lists will be written to:'
x = listdsi('NDVR FILE')
say rexxname':' sysdsname
x = listdsi('NONNDVR FILE')
say rexxname':' sysdsname

if ecount > 0 then do
  queue '    Non Endevor Controlled Datasets with an Endevor System'
  queue '    ------------------------------------------------------'
  "execio 2 diskw NDVR"
  if rc ^= 0 then call exception rc 'DISKW to NDVR failed'
  "execio" ecount "diskw NDVR (stem endevor. finis"
  if rc ^= 0 then call exception rc 'DISKW to NDVR failed'
end /* ecount > 0 */

if ncount > 0 then do
  queue '    Non Endevor Controlled Datasets without an Endevor System'
  queue '    ---------------------------------------------------------'
  "execio 2 diskw NONNDVR"
  if rc ^= 0 then call exception rc 'DISKW to NONNDVR failed'
  "execio" ncount "diskw NONNDVR (stem non. finis"
  if rc ^= 0 then call exception rc 'DISKW to NONNDVR failed'
end /* ncount > 0 */

if ccount > 0 then
  call send_email

if scount > 0 then
  call send_email2

exit

/*---------------------- S U B R O U T I N E S ----------------------*/

/*-------------------------------------------------------------------*/
/* Send email with the newly created datasets                        */
/*-------------------------------------------------------------------*/
Send_email:

 say rexxname':'
 say rexxname': Sending email with the newly created datasets'
 say rexxname':'

 jobname = MVSVAR('SYMDEF','JOBNAME')
 if left(jobname,2) = 'TT' then
   jobname = '**TEST**' jobname
 "alloc f(SYSADDR) new space(2,2) tracks
 recfm(f,b) lrecl(120) blksize(0) dsorg(ps)"
 if rc ^= 0 then call exception rc 'ALLOC of SYSADDR failed'

 queue 'FROM: mapfre.endevor@rsmpartners.com'
 queue 'TO: VERTIZOS@kyndryl.com'


 queue 'SUBJECT:' jobname '- BASE datasets created on the' ,
       sysplex 'on' yesterday

 "execio" queued() "diskw SYSADDR (finis)"
 if rc ^= 0 then call exception rc 'DISKW to SYSADDR failed'

 "alloc f(SYSDATA) new space(5,15) tracks
  recfm(f,b) lrecl(800) blksize(0) dsorg(ps)"
 if rc ^= 0 then call exception rc 'ALLOC of SYSDATA failed'
 "execio" ccount "diskw SYSDATA (stem dsncre. finis"
 if rc ^= 0 then call exception rc 'DISKW to SYSDATA failed'

 "exec 'SYSTSO.BASE.EXEC(SENDMAIL)' 'DEFAULT LOG(YES)'" 'EXEC'
 if rc ^= 0 then call exception rc 'SENDMAIL failed'

 "free fi(SYSADDR SYSDATA)"

return /* Send_email */

/*-------------------------------------------------------------------*/
/* Send email with the newly suppressed datasets                     */
/*-------------------------------------------------------------------*/
Send_email2:

 say rexxname':'
 say rexxname': Sending email with the newly suppressed datasets'
 say rexxname':'

 jobname = MVSVAR('SYMDEF','JOBNAME')
 if left(jobname,2) = 'TT' then
   jobname = '**TEST**' jobname
 "alloc f(SYSADDR) new space(2,2) tracks
 recfm(f,b) lrecl(120) blksize(0) dsorg(ps)"
 if rc ^= 0 then call exception rc 'ALLOC of SYSADDR failed'

 queue 'FROM: mapfre.endevor@rsmpartners.com'
 queue 'TO: VERTIZOS@kyndryl.com'


 queue 'SUBJECT:' jobname '- Shipment Datasets suppressed since' ,
       'the last run of this job'

 "execio" queued() "diskw SYSADDR (finis)"
 if rc ^= 0 then call exception rc 'DISKW to SYSADDR failed'

 "alloc f(SYSDATA) new space(5,15) tracks
  recfm(f,b) lrecl(800) blksize(0) dsorg(ps)"
 if rc ^= 0 then call exception rc 'ALLOC of SYSDATA failed'
 "execio" scount "diskw SYSDATA (stem suppressed. finis"
 if rc ^= 0 then call exception rc 'DISKW to SYSDATA failed'

 "exec 'SYSTSO.BASE.EXEC(SENDMAIL)' 'DEFAULT LOG(YES)'" 'EXEC'
 if rc ^= 0 then call exception rc 'SENDMAIL failed'

 "free fi(SYSADDR SYSDATA)"

return /* Send_email */

/*-------------------------------------------------------------------*/
/* Error with line number displayed                                  */
/*-------------------------------------------------------------------*/
exception:
 parse arg return_code comment

 parse source . . rexxname . . . . addr .
 say rexxname':'
 say rexxname':' comment'. RC='return_code
 say rexxname': Exception called from line' sigl

 if addr ^= 'MVS' then do
   z = msg(off)
   address tso "free fi(SYSADDR SYSDATA)"
   address tso 'delstack'           /* Clear down the stack          */
   z = msg(on)
 end /* addr ^= 'MVS' */

 if return_code < 0 then return_code = 12 /* - RCs can be invalid    */

exit return_code
