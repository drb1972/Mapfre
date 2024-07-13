/*-----------------------------------REXX----------------------------*\
 *  Create DB2 Stored Procedure definitions                          *
 *  Used for SPDEF & SQLP                                            *
 *  See GDB2SP and MDB2SP for sample JCL                             *
\*-------------------------------------------------------------------*/
trace n

parse arg ,
c1su      , /* Endevor Subsystem                                     */
c1ele     , /* Endevor Element                                       */
c1ty      , /* Endevor Type                                          */
c1en      , /* Endevor Environment                                   */
c1si      , /* Endevor Stage Id                                      */
c1prgrp   , /* Processor group                                       */
runtype     /* CREATE or CREATEBACK - used for report summary        */

say 'DB2SPCR:  *** TOP OF PARMS ***'
say 'DB2SPCR:'
say 'DB2SPCR:  C1SU.....'c1su
say 'DB2SPCR:  C1ELE....'c1ele
say 'DB2SPCR:  C1TY.....'c1ty
say 'DB2SPCR:  C1EN.....'c1en
say 'DB2SPCR:  C1SI.....'c1si
say 'DB2SPCR:  C1PRGRP..'c1prgrp
say 'DB2SPCR:  RUNTYPE..'runtype
say 'DB2SPCR:'
say 'DB2SPCR:  *** END OF PARMS ***'

lpar     = mvsvar(sysname)
r        = 0            /* summary line counter                      */
q        = 0            /* sqlout line counter                       */
worked   = 0            /* number of successful commands             */
commands = 0            /* number of commands for the datasharinggrp */
maxrc    = 0

call summary 'DB2SPCR: -----' runtype 'element' c1ele ,
            '-' c1en c1su c1prgrp '-----'

if c1ty = 'SQLP' then do
  sqlformat = 'SQLFORMAT(SQLPL),'
  cmd_term = '#'
end /* c1ty = 'SQLP'                                                 */
else do
  sqlformat = ''
  cmd_term = ';'
end /* else                                                          */

call readsrc /* Read element source                                  */

if cobd = 'Y' then do
  say 'DB2SPCR: No processing for COBD SPDEFs'
  exit
end /* cobd = 'Y'                                                    */

say 'DB2SPCR:' Date() Time() '>>> Start processing for',
    c1ele 'type' c1ty

call initialise /* switch to the ENDEVOR userid                      */

x = db2parms(c1prgrp c1en c1su c1ty) /* Call DB2PARMS                */
if x ^= 0 then call exception x 'Call to DB2PARMS failed.'

lines = queued()

do i = 1 to lines /* Get the lines returned by DB2PARMS              */
  pull data.i
end /* i = 1 to lines                                                */

do ii = 1 to lines /* Process each line returned by DB2PARMS         */
  parse value data.ii with ,
       dbsub dbqual dbown dbcoll dbwlm dbracf db2inst pgrdesc ,
       dbiso dbcur dbdeg dbrel dbreo dbval dbkdyn dbdynr dbblkn ,
       prodown dbenc .
  if dbsub ^= old_dbsub then do
    if ii ^= 1 then
      if dbsub_ok then do
        call summary 'DB2SPCR:  ' worked 'out of' commands ,
                    'actions completed successfully'
        worked   = 0
        commands = 0
      end /* dbsub_ok                                                */
    dbsub_ok = check_connect() /* Check the db2 subsystem is active  */
  end /* dbsub ^= old_dbsub                                          */
  if dbsub_ok then do
    commands = commands + 1
    call process
    if procrc > maxrc then maxrc = procrc
  end /* rc = 0                                                      */
  else
    maxrc = 8
  old_dbsub = dbsub
end /* ii = 1 to lines                                               */

if dbsub_ok then
  call summary 'DB2SPCR:  ' worked 'out of' commands ,
              'actions completed successfully'
call closedown

say 'DB2SPCR:' Date() Time() '>>> FINITO' ,
    'for' c1ele asxbuser 'MAXRC:' maxrc

call write_output

exit maxrc

/*---------------------- S U B R O U T I N E S ----------------------*/

/*-------------------------------------------------------------------*/
/*  Initialise                                                       */
/*-------------------------------------------------------------------*/
initialise:
 /* Get the userid from storage                                      */
 ascb      = c2x(storage(224,4))
 asxb      = c2x(storage(d2x(x2d(ascb)+108),4))
 acee      = c2x(storage(d2x(x2d(asxb)+200),4))
 asxbuser  =     storage(d2x(x2d(asxb)+192),8)
 /* Switch to alternate userid (ENDEVOR)                             */
 'alloc f(lgnt$$$i) dummy'
 'alloc f(lgnt$$$o) dummy'
 'execio * diskr LGNT$$$I (finis'
 /* Get the userid from storage again (should be ENDEVOR)            */
 asxbuser  =     storage(d2x(x2d(asxb)+192),8)
 /* Say user being used                                              */
 say 'DB2SPCR:' asxbuser 'running on' lpar
 say 'DB2SPCR:'

return /* initialise                                                 */

/*-------------------------------------------------------------------*/
/*  Readsrc - Read element source                                    */
/*            Validation has been moved to REXX EVSPDCHK             */
/*-------------------------------------------------------------------*/
readsrc:
 'execio * diskr source (stem source. finis'
 if rc ^= 0 then call exception rc 'DISKR of SOURCE failed.'

 /* Check first line of SPDEF element                                */
 if subword(source.1,1,2) = 'WLM ENVIRONMENT' then /* cobd only      */
   cobd  = 'Y'
 else do
   spnamel = word(source.1,3)
   splen   = length(spnamel) - pos('.',spnamel)
   spnamer = right(spnamel,splen)           /* get the full spname   */
 end /* else                                                         */

return /* readsrc                                                    */

/*-------------------------------------------------------------------*/
/*  Check_connect - Check that the DB2 subsystem is active           */
/*-------------------------------------------------------------------*/
check_connect:

 call summary 'DB2SPCR:'
 call summary 'DB2SPCR: -- Datasharing group' dbsub

 "SUBCOM DSNREXX" /* Is the host cmd env available?                  */
 if rc then       /* No, let's make one                              */
   s_rc = rxsubcom('ADD','DSNREXX','DSNREXX')

 address DSNREXX "CONNECT" dbsub /* Connect to the DB2 subsystem     */
 say 'DB2SPCR: Connect to' dbsub 'RC='rc
 say 'DB2SPCR:'
 if rc ^= 0 then do
   call summary 'DB2SPCR:'
   call summary 'DB2SPCR:  This job ran on lpar' lpar ,
                'but DB2 subsystem' dbsub
   call summary 'DB2SPCR:  was not running on' lpar'.'
   call summary 'DB2SPCR:'
   call summary 'DB2SPCR:  Please code SCHENV='dbsub'BIND on your' ,
                'Endevor job card,'
   call summary 'DB2SPCR:  remove any SYSAFF cards that you have,'
   call summary 'DB2SPCR:  and reprocess the Endevor action.'
   return 0
 end /* rc ^=                                                        */

 address DSNREXX "DISCONNECT"   /* Disconnect from the DB2 subsystem */
 if sqlcode <> 0 then call sqlca

return 1 /* check_connect                                            */

/*-------------------------------------------------------------------*/
/* Sqlca - Display variables on error                                */
/*-------------------------------------------------------------------*/
sqlca:
 say " SQLSTATE =" sqlstate
 say " SQLERRP  =" sqlerrp
 say " SQLERRMC =" sqlerrmc
 say " SQLCODE  =" sqlcode

return /* sqlca                                                      */

/*-------------------------------------------------------------------*/
/*  Process                                                          */
/*-------------------------------------------------------------------*/
process:

 procrc   = 0
 createrc = 0
 grantorc = 0
 grantrrc = 0

 spname = dbqual'.'spnamer

 say 'DB2SPCR: Process procedure' spname 'requested by' asxbuser
 call sqlout copies('=',80)
 call sqlout ' '
 call sqlout 'DB2SPCR: Process procedure' spname '('runtype')' ,
             prodown dbsub c1en c1su
 call sqlout '                          ' copies('~',length(spname))

 /* STEP#1 Drop SP definition                                        */
 queue "DROP PROCEDURE" spname "RESTRICT"cmd_term
 queue ""
 call connect 'DROP'      /*  process  DB2 commands                  */

 /* STEP#2 Create SP definition                                      */
 queue "SET CURRENT SQLID = 'ENDEVOR'"cmd_term
 queue "CREATE PROCEDURE" spname
 do i = 2 to source.0 /* Queue the rest of the definition            */
   select
     when word(source.i,1) = 'COLLID' then
       queue 'COLLID' dbcoll
     when word(source.i,1) = 'WLM' then
       queue 'WLM ENVIRONMENT' dbwlm
     when c1ty = 'SQLP' & ,
          subword(source.i,1,2) = 'LANGUAGE SQL' then do
       queue source.i
       call add_bind_vars
     end /* c1ty = 'SQLP' & subword(source.i,1,2) = 'LANGUAGE SQL'   */
     otherwise
       queue source.i
   end /* select                                                     */
 end /* i = 2 to source.0                                            */
 queue ""
 call connect 'CREATE'    /* Process DB2 commands                    */

 if procrc = 0 then do
   /* STEP#3 Grant execute on procedure to owner                     */
   queue "SET CURRENT SQLID = 'ENDEVOR'"cmd_term
   queue "GRANT EXECUTE ON PROCEDURE" spname "TO" dbown
   queue ""
   call connect 'GRANT TO' dbown  /* process  DB2 commands           */

   /* STEP#4 Grant execute on procedure to racf group                */
   queue "SET CURRENT SQLID = 'ENDEVOR'"cmd_term
   queue "GRANT EXECUTE ON PROCEDURE" spname "TO" dbracf
   queue ""
   call connect 'GRANT TO' dbracf /* process  DB2 commands           */
 end /* createrc = 0                                                 */

 if procrc = 0 then do
   worked = worked + 1
   call summary 'DB2SPCR:   CREATE worked for' spname' - Instance =' ,
               prodown
 end /* procrc = 0                                                   */

 say 'DB2SPCR:'

return /* process                                                    */

/*-------------------------------------------------------------------*/
/*  Add_bind_vars - Adds bind variables for SQLP                     */
/*-------------------------------------------------------------------*/
add_bind_vars:

 queue " QUALIFIER      " dbqual
 queue " PACKAGE OWNER  " dbown
 queue " ISOLATION LEVEL" dbiso
 queue " CURRENT DATA   " dbcur
 queue " DEGREE         " dbdeg
 queue " RELEASE AT     " dbrel
 queue " VALIDATE       " dbval
 queue " DYNAMICRULES   " dbdynr
 queue " APPLICATION ENCODING SCHEME" dbenc
 select
   when dbreo = 'REOPT'   then
     queue " REOPT           ALWAYS"
   when dbreo = 'NOREOPT' then
     queue " REOPT           NONE"
   otherwise
     call exception 12 'DB2SPCR: Unknown REOPT value...' dbreo
 end /* select                                                       */
 select
   when dbkdyn = 'YES' then
     queue " WITH KEEP DYNAMIC"
   when dbkdyn = 'NO'  then
     queue " WITHOUT KEEP DYNAMIC"
   otherwise
     call exception 12 'DB2SPCR: Unknown KEEP DYNAMIC value...'dbkdyn
 end /* select                                                       */
 queue " WITH EXPLAIN"

return /* add_bind_vars                                              */

/*-------------------------------------------------------------------*/
/*  Connect - Process queued DB2 statements                          */
/*-------------------------------------------------------------------*/
connect:
 arg comtyp

 /*  Allocate files for dsntep2 to run sql                           */
 "ALLOC FI(SYSIN) NEW UNIT(VIO) LRECL(80) RECFM(F B)",
        "BLKSIZE(800) SPACE(1,1) TRACKS REUSE"
 "execio * diskw sysin (finis"
 if rc ^= 0 then call exception rc 'DISKW to SYSIN failed.'
 queue "run program(dsntep2) plan(dsntep2)" ,
       "library('sysdb2."dbsub".runlib.load')" ,
       "PARM('"sqlformat"SQLTERM("cmd_term")')"
 "ALLOC FI(SYSPRINT) NEW UNIT(VIO) LRECL(133) RECFM(F B A)",
        "BLKSIZE(3591) SPACE(1,1) TRACKS REUSE"

 /*  Connect to DB2                                                  */
 queue 'END'
 'DSN SYSTEM('dbsub')'
 dsnrc = rc
 if rc > procrc & comtyp ^= 'DROP' then procrc = rc
 say 'DB2SPCR:' comtyp 'RC was' rc

 /*  Write out the full output to SYSTSPRT which is &ZOUT            */
 'execio * diskr SYSPRINT(stem sqlresult. finis'
 if rc ^= 0 then call exception rc 'DISKR of SYSPRINT failed.'

 do p = 1 to sqlresult.0
   say substr(sqlresult.p,1,131)
 end /* p = 1 to sqlresult.0                                         */

 /*  Write out the filtered output to SQLOUT for developers          */
 if comtyp ^= 'DROP' then do
   call sqlout 'DB2SPCR: ----' comtyp 'output ----'
   call sqlout ' '

   if subword(sqlresult.4,1,3) = 'SET CURRENT SQLID' then st = 12
                                                     else st = 2
   sqlcode = ''
   do p = st to sqlresult.0
     if word(sqlresult.p,1) = '1PAGE' then iterate
     call sqlout '  'substr(sqlresult.p,2,130)
     if word(sqlresult.p,2) = 'SQLCODE' then
       sqlcode = subword(sqlresult.p,4)
   end /* p = 1 to sqlresult.0                                       */
   call sqlout ' '
 end /* comtyp ^= 'DROP'                                             */

 if dsnrc <> 0 & comtyp ^= 'DROP' then do
   say 'DB2SPCR: An error has occured'
   call summary 'DB2SPCR:  *'comtyp 'failed for' spname' - Instance =' ,
               prodown
   if sqlcode ^= '' then
     call summary 'DB2SPCR:   ' sqlcode
 end /* dsnrc <> 0 & comtyp ^= 'DROP'                                */

 "free fi(SYSIN SYSPRINT)" /* Free files                             */

return /* connect                                                    */

/*-------------------------------------------------------------------*/
/*  Closedown - Switch userid back                                   */
/*-------------------------------------------------------------------*/
closedown:
 'execio * diskr LGNT$$$O (finis'
 'free f(LGNT$$$I LGNT$$$O)'
 asxbuser = storage(d2x(x2d(asxb)+192),8)

return /* closedown                                                  */

/*-------------------------------------------------------------------*/
/*  Write_output - Write out all the output                          */
/*-------------------------------------------------------------------*/
write_output:
 call summary ' '
 'execio' r 'diskw SUMMARY (stem summary.'
 if rc ^= 0 then call exception rc 'DISKW to SUMMARY failed.'

 'execio' q 'diskw SQLOUT (stem sqlout.'
 if rc ^= 0 then call exception rc 'DISKW to SQLOUT failed.'

return /* write_output                                               */

/*-------------------------------------------------------------------*/
/*  Summary - adds a line to an array called summary                 */
/*-------------------------------------------------------------------*/
summary:
 parse arg text
 r = r + 1
 summary.r = text

return /* summary                                                    */

/*-------------------------------------------------------------------*/
/*  Sqlout - adds a line to an array called sqlout                   */
/*-------------------------------------------------------------------*/
sqlout:
 parse arg text
 q = q + 1
 sqlout.q = text

return /* sqlout                                                     */

/*-------------------------------------------------------------------*/
/* Error with line number displayed                                  */
/*-------------------------------------------------------------------*/
exception:
 parse arg return_code comment

 call closedown
 call write_output

 delstack /* Clear down the stack                                    */

 parse source . . rexxname . /* Get the rexx name(generic subroutine)*/
 say rexxname':'
 say rexxname':' comment
 say rexxname': Exception called from line' sigl

 call closedown
 call write_output

exit return_code
