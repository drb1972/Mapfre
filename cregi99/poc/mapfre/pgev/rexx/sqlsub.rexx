/*-----------------------------REXX----------------------------------*\
 *  Build DB2 JCL for executing SQL at implementation time.          *
 *  Executed in %%%SQL%I jobs, JCL built by NDVEDIT.                 *
\*-------------------------------------------------------------------*/
parse source . . rexxname .
if sysdsn("'TTEV.TRACE."rexxname"'") = 'OK' then trace i

parse arg changeid

say rexxname':' Date() Time()
say rexxname':'
say rexxname': Changeid......:' changeid
say rexxname':'

sysplex  = MVSVAR(SYSPLEX)

/*  Read DB2PARMS and set the owners                                 */
"execio * diskr DB2PARMS (stem db2parms. finis"
if rc ^= 0 then call exception rc 'DISKR of DB2PARMS failed'

do i = 1 to db2parms.0
  if left(word(db2parms.i,1),8) = 'prodown.' & ,
     word(db2parms.i,2)         = '='        then do
    tmpparm = word(db2parms.i,1) word(db2parms.i,2) ,
              word(db2parms.i,3)
    interpret tmpparm
  end /* left(word(db2parms.i,1),8) = 'prodown.' & ... */
end /* do i = 1 to db2parms.0 */

/*  Read the CONTROL file                                            */
/*  Contains the target DB2 subsystems and actions to be performed.  */
/*   1st char of target is the DB2 subsystem                         */
/*   2nd char is 0 for implementation SQL or B for backout           */
/*   3rd char is the instance                                        */
/*   E.g. TARGET A0G SYSTEM EK                                       */
/*    A0G = DPA0, implementation SQL, instance G                     */
/*    ABG = DPA0, backout        SQL, instance G                     */
/*  N.B. Backout SQL is not automatically executed.                  */

"execio * diskr CONTROL (stem card. finis"
if rc ^= 0 then call exception rc 'DISKR of CONTROL failed'

do i = 1 to card.0
  if word(card.i,1) <> 'TARGET' then
    call exception rc 'Word 1 not TARGET:' i card.i
  if word(card.i,3) <> 'SYSTEM' then
    call exception rc 'Word 3 not SYSTEM:' i card.i
  target   = word(card.i,2)
  system   = word(card.i,4)
  dbsubchr = left(target,1)
  db2sub   = 'DP'dbsubchr'0'
  instance = substr(target,3,1)
  select
    when substr(target,2,1) = '0' then do
      sqlmem  = 'C'substr(changeid,3,6) || instance
      runtype = 'Implementation'
      jobpref = system
    end /* substr(target,2,1) = '0' */
    when substr(target,2,1) = 'A' then do
      sqlmem  = 'A'substr(changeid,3,6) || instance
      runtype = 'Auto Backout'
      jobpref = system
    end /* substr(target,2,1) = 'A' */
    when substr(target,2,1) = 'B' then do
      sqlmem  = 'B'substr(changeid,3,6) || instance
      runtype = 'Manual Backout'
      jobpref = 'DF'
    end /* substr(target,2,1) = 'B' */
    otherwise
      call exception rc 'SQLSUB: Invalid target:' target
  end /* select */

  /* Set schenv for CA7P02/DB2 special resources                    */
  if wordpos(db2sub,'DPA0 DPB0 DPG0 DPK0 DPL0') > 0 then
    schenv = 'P2'db2sub
  else
    schenv = db2sub

  say "SQLSUB: SQL TARGET      :" target
  say "SQLSUB: DB2 SUBSYSTEM   :" db2sub
  say "SQLSUB: RUN TYPE        :" runtype
  say "SQLSUB: INSTANCE        :" instance
  say "SQLSUB: ENDEVOR SYSTEM  :" system
  say "SQLSUB: SCHENV          :" schenv
  say "SQLSUB: OWNER           :" prodown.instance
  if instance = 'I' | instance = 'L' then do
    prodown.instance = 'GRP'
    say "SQLSUB: WARNING: OWNER TEMPORARILY OVERRIDDEN"
    say "SQLSUB: NEW OWNER       :" prodown.instance
  end
  say "SQLSUB: Staging DDNAME  : SQL"target

  jobname  = jobpref || instance"SQL"dbsubchr"I"
  jcllines = 0

  call addline "//"jobname "JOB CLASS=N,MSGCLASS=Y,SCHENV=" || ,
               schenv",USER="prodown.instance
  call addline "/*JOBPARM SYSAFF=ANY"
  call addline "//SETVAR   SET ID=P"instance",BNK="instance",TLQ= "
  call addline "//JCLLIB   JCLLIB ORDER=PGOS.&TLQ.BASE.PROCLIB "
  call addline "//*"
  call addline "//*   Change" changeid "DB2 SQL processing"
  call addline "//*"
  call addline "//*   JCL built by SQLSUB"
  call addline "//*   JCL stored in PGEV.AUTO.SQLJCL"dbsubchr || ,
               "("sqlmem")"
  call addline "//*"
  call addline "//*   "runtype "SQL JCL for" db2sub "instance" ,
               instance 'system' system

  /* Set the SQL type - LN has a suffix on the type                 */
  if system = 'LN' then
    if instance = 'P' then type = "SQLZ" /* DLPUK uses SQLZ         */
                      else type = "SQL"instance
  else
    type = "SQL"

  /* Set the SQL DSN - BASE for implementation, STAGE for backout   */
  if substr(target,2,1) = '0' then
    sqllib = "PG"system".BASE."type
  else do /* Its a backout                                          */
    dsirc = listdsi(type file)
    if dsirc = 0 then
      sqllib = sysdsname
    else
      sqllib = "PG"system".BASE."type
  end /* else */

  call readmems
  do ji = 1 to members
    call addline "//*"
    call addline "//SQLEX"right(ji,3,'0')" EXEC @DB2SQL,"
    call addline "//             SYSIN="sqllib"("mem.ji"),"
    call addline "//             SYSTEM="db2sub
  end /* ji = 1 to members */

  jcl_ddn = 'SUBMT'target
  say 'SQLSUB:'
  say 'SQLSUB:   Writing JCL to ddname :' jcl_ddn
  dsirc = listdsi(jcl_ddn file)
  if dsirc ^= 0 then call exception dsirc 'LISTDSI failed for' jcl_ddn
  say 'SQLSUB:   JCL DSNAME            :' sysdsname'('sqlmem')'

  say ' '
  do si = 1 to jcllines
    say jclline.si
  end /* si = 1 to jcllines */
  say ' '
  /* write out JCL for this target                                   */
  "execio" jcllines "diskw" jcl_ddn "(stem jclline. finis"
  if rc ^= 0 then call exception rc 'DISKW to' jcl_ddn 'failed'

end /* i = 1 to card.0 */

exit

/*---------------------- S U B R O U T I N E S ----------------------*/

/*-------------------------------------------------------------------*/
/* Readmems - Read members from staging dataset                      */
/*-------------------------------------------------------------------*/
readmems:

 ddname = 'SQL'target
 dsirc  = listdsi(ddname file)
 if dsirc ^= 0 then do
   say 'SQLSUB:'
   say 'SQLSUB: SYSREASON=' sysreason
   say 'SQLSUB:'   sysmsglvl1
   say 'SQLSUB:'   sysmsglvl2
   call exception dsirc 'LISTDSI failed for' ddname
 end /* dsirc ^= 0 */

 stg_dsn = sysdsname
 say 'SQLSUB: Staging DSNAME  :' stg_dsn

 tout = outtrap('TSOOUT.')
 "listds '"stg_dsn"' members"
 if rc ^= 0 then call exception rc 'LISTDS failed for' stg_dsn

 members = 0
 do ti = 7 to tsoout.0
   if strip(tsoout.ti) = "$$$SPACE" then iterate
   members     = members + 1
   mem.members = strip(tsoout.ti)
   say 'SQLSUB:   Will add step for member:' mem.members
 end /* ti = 7 to tsoout.0 */

return /* readmems: */

/*-------------------------------------------------------------------*/
/* Addline - Add JCL line to queue                                   */
/*-------------------------------------------------------------------*/
addline:
 parse arg text

 jcllines         = jcllines + 1
 jclline.jcllines = text

return /* addline: */

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
   address tso 'delstack'           /* Clear down the stack          */
   z = msg(on)
 end /* addr ^= 'MVS' */

 if return_code < 0 then return_code = 12 /* - RCs can be invalid    */

exit return_code
