/*--------------------------REXX---------------------------------*\
 *  Read a list of select statements for PDSM37 checksum         *
 *  and check that the dataset exists, if not then email         *
 *  Endevor.                                                     *
 *---------------------------------------------------------------*
 *---------------------------------------------------------------*
 *  Executed by : JOB EVGCMP%W                                   *
\*---------------------------------------------------------------*/
trace n

uid = sysvar('sysuid')

say 'SHIPDSCK: Checking datasets exist from the SELECT list in'
x = listdsi(SELECTS file)
selects_dsn = sysdsname
say 'SHIPDSCK:' sysdsname

exit_rc = 0

plexid  = mvsvar(sysplex)          /* Plex id */
plex    = substr(plexid,5,1)
jobname = mvsvar('SYMDEF',jobname)

/* Read the select statements produced by EVGCMP1W on the Qplex */
"execio * diskr SELECTS (stem sel.  finis" /* CMR list        */
if rc ^= 0 then call exception 20 'DISKR from SELECTS failed RC='rc

/* Write out the email header */
queue "  FROM: VERTIZOS@kyndryl.com"
queue "  TO: VERTIZOS@kyndryl.com"
queue "  SUBJECT:" jobname "- Missing datasets on the" plexid
"execio 3 diskw EADDR"
if rc ^= 0 then call exception 20 'DISKW to ADDR failed RC='rc

/* Check the dsn exists                   */
do i = 1 to sel.0
  parse value sel.i with 'SELECT DSN='tgtdsn rest
  /* Dont check the composites because they are created in EVGCMP4W */
  if right(tgtdsn,16) = 'COMPOSIT.BASELIB' then iterate

  /* Exclude some cloned dataset that are excluded by NDVEDIT */
  if ((plex = 'P' & left(tgtdsn,11) = 'PGAO.BASE.M') | ,
      (plex = 'M' & left(tgtdsn,11) = 'PGAO.BASE.P') | ,
      (plex = 'F' & left(tgtdsn,11) = 'PGAO.BASE.E')) & ,
     (right(tgtdsn,6) = '.RULES' | ,
      right(tgtdsn,5) = '.REXX' ) then
    iterate

  if left(tgtdsn,17) = 'PGSY.BASE.APPPROC' & plex ^= right(tgtdsn,1) then
    tgtdsn = overlay('PGEV.PSY1',tgtdsn)

  tgtdsnq = "'"tgtdsn"'"
  x = listdsi(tgtdsnq norecall)
  if x > 4               & ,            /* Failed           */
     sysreason ^= '0009' then do        /* and not migrated */
    queue tgtdsn            /* write to the email data */
    "execio 1 diskw MISSING"
    if rc ^= 0 then call exception 20 'DISKW to MISSING failed RC='rc
    exit_rc = 1
  end /* x > 4 & sysreason ^= '0009' */

  /* Do a RACF check to make sure we've got read access */
  /* regardless of whether the dataset exists or not.   */
  a = outtrap("racchk.",'*',concat)
  "LD DA('"tgtdsn"') GEN ALL"
  if racchk.0 < 2 then do
    queue left(tgtdsn,40) '-' uid 'does not have access'
    "execio 1 diskw MISSING"
    exit_rc = 1
  end /* racchk.0 < 2 */

end /* i = 1 to sel.0 */

"execio 0 diskw MISSING (finis"     /* Close the file */

if exit_rc > 0 then do
  say 'SHIPDSCK:'
  say 'SHIPDSCK: There are missing datatsets or' ,
                 uid 'has insufficient access.'
  say 'SHIPDSCK: An email will be sent to ¯ endevor'
end /* exit_rc > 0 */

exit exit_rc

/*---------------------- S U B R O U T I N E S -----------------------*/

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
