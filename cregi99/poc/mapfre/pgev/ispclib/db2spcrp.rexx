/*-----------------------------REXX----------------------------------*\
 *  Create DB2 Stored Procedure definitions and SQL stored           *
 *  procedures for production.                                       *
\*-------------------------------------------------------------------*/
trace n

parse arg ,
c1sy      , /* Endevor system                                        */
c1prgrp   , /* Endevor procesor Group                                */
c1ele     , /* Endevor element                                       */
c1ty        /* Endevor type                                          */

say 'DB2SPCRP:  *** TOP OF PARMS ***'
say 'DB2SPCRP:'
say 'DB2SPCRP:  C1SY.....'c1sy
say 'DB2SPCRP:  C1PRGRP..'c1prgrp
say 'DB2SPCRP:  C1ELE....'c1ele
say 'DB2SPCRP:  C1TY.....'c1ty
say 'DB2SPCRP:'
say 'DB2SPCRP:  *** END OF PARMS ***'

j = 0 /* Counter for DROP lines                                      */

call readsrc

c1su    = c1sy'1'
x = db2parms(c1prgrp 'PROD' c1su c1ty) /* Call DB2PARMS              */
if x ^= 0 then call exception x 'Call to DB2PARMS failed.'

lines = queued()

do ii = 1 to lines /* Get the lines returned by DB2PARMS             */
  pull data.ii
end /* i = 1 to lines */

do ii = 1 to lines /* Process each line returned by DB2PARMS         */
  parse value data.ii with ,
        dbsub dbqual dbown dbcoll dbwlm dbracf db2inst pgrdesc ,
        dbiso dbcur dbdeg dbrel dbreo dbval dbkdyn dbdynr dbblkn ,
        prodown dbenc .
  if dbsub ^= old_dbsub & ii > 1 then
    call writesp old_dbsub
  call process
  old_dbsub = dbsub
end /* ii = 1 to lines */

call writesp dbsub

exit

/*---------------------- S U B R O U T I N E S ----------------------*/

/*-------------------------------------------------------------------*/
/*  Readsrc - Read element source                                    */
/*-------------------------------------------------------------------*/
readsrc:
 'execio * diskr spsrc (stem spsrc. finis'
 if rc ^= 0 then call exception rc 'DISKR of SPSRC failed.'

 if c1ty ^= 'SQLP' then do
   if word(spsrc.1,1) = 'WLM' then exit /* Refresh only for COBD     */

   /* Get production WLM                                             */
   do i = 1 to spsrc.0
     if subword(spsrc.i,1,2) = 'WLM ENVIRONMENT' then do
       wlmno = right(word(spsrc.i,3),2)
       leave
     end /* subword(spsrc.i,1,2) = 'WLM ENVIRONMENT' */
   end /* i = 1 to spsrc.0 */

 end /* c1ty ^= 'SQLP' then */

 /* Get the full stored procedure name from the source               */
 spnamel = word(spsrc.1,3)
 splen   = length(spnamel) - pos('.',spnamel)
 spnamer = right(spnamel,splen) /* Get the full spname               */

return /* readsrc */

/*-------------------------------------------------------------------*/
/*  Process - Queue create command                                   */
/*-------------------------------------------------------------------*/
process:

 say 'DB2SPCRP: Building statements for datasharing group' ,
     dbsub 'owner' dbown

 if c1ty ^= 'SQLP' then
   dbwlm  = dbsub'AE'wlmno

 j = j + 1
 drop.j = "DROP PROCEDURE" dbqual'.'spnamer "RESTRICT"

 if c1ty = 'SQLP' then do
   queue '--#SET SQLFORMAT SQLPL'
   queue '--#SET TERMINATOR #'
 end /* c1ty = 'SQLP' */
 else do
   if sysdsn("'PREV.P"c1sy"1.SQLP'") = 'OK' then do
     queue '--#SET SQLFORMAT SQL'
     queue '--#SET TERMINATOR ;'
   end /* sysdsn("'PREV.P"c1sy"1.SQLP'") = 'OK' */
 end /* else */

 queue "CREATE PROCEDURE" dbqual'.'spnamer
 do i = 2 to spsrc.0
   line = spsrc.i
   upper line
   select
   when word(line,1) = 'COLLID' then
     queue 'COLLID' dbcoll
   when word(line,1) = 'WLM' then
     queue 'WLM ENVIRONMENT' dbwlm
   when wordpos('DEBUG MODE',line) > 0  then nop /* no DEBUG in prod */
   when c1ty = 'SQLP' & ,
        subword(line,1,2) = 'LANGUAGE SQL' then do
     queue spsrc.i
     call add_bind_vars
   end /* c1ty = 'SQLP' & subword(spsrc.i,1,2) = 'LANGUAGE SQL' */
   otherwise
     queue spsrc.i
   end /* select */
 end /* i = 2 to spsrc.0 */

 if c1ty = 'SQLP' then do /* Add # to the end if its not there       */
   lastline = spsrc.0
   lastline = left(spsrc.lastline,72)
   lastword = words(lastline)
   if right(word(lastline,lastword),1) ^= '#' then
     queue ' #'
 end /* c1ty = 'SQLP' */

return /* process */

/*-------------------------------------------------------------------*/
/*  Writesp - Write drop and create command(s) to pds                */
/*-------------------------------------------------------------------*/
writesp:
 parse arg curr_dbsub

 drfile = 'SPDR'curr_dbsub
 x = listdsi(drfile file)
 if x > 4 then call exception x 'LISTDSI of' drfile 'failed.'
 say 'DB2SPCRP: Writing DROP   statements to' sysdsname
 /* Write out the drop statements                                    */
 'execio' j 'diskw SPDR'curr_dbsub '(stem drop. finis'
 if rc ^= 0 then call exception rc 'DISKW to' drfile 'failed.'

 j = 0 /* reset DROP counter                                         */

 crfile = 'SPCR'curr_dbsub
 x = listdsi(crfile file)
 if x > 4 then call exception x 'LISTDSI of' crfile 'failed.'
 say 'DB2SPCRP: Writing CREATE statements to' sysdsname
 /* Write out the create statements                                  */
 'execio * diskw SPCR'curr_dbsub '(finis'
 if rc ^= 0 then call exception rc 'DISKW to' crfile 'failed.'

 say 'DB2SPCRP:'

return /* writesp */

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
     call exception 12 'DB2SPCRP: Unknown REOPT value...' dbreo
 end /* select */
 select
   when dbkdyn = 'YES' then
     queue " WITH KEEP DYNAMIC"
   when dbkdyn = 'NO'  then
     queue " WITHOUT KEEP DYNAMIC"
   otherwise
     call exception 12 'DB2SPCRP: Unknown KEEP DYNAMIC value...'dbkdyn
 end /* select */
 queue " WITH EXPLAIN"

return /* add_bind_vars */

/*-------------------------------------------------------------------*/
/* Error with line number displayed                                  */
/*-------------------------------------------------------------------*/
exception:
 parse arg return_code comment

 delstack /* Clear down the stack                                    */

 parse source . . rexxname . /* Get the rexx name(generic subroutine)*/
 say rexxname':'
 say rexxname':' comment
 say rexxname': Exception called from line' sigl

exit return_code
