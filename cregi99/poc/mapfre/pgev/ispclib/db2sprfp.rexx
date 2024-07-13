/*-----------------------------REXX----------------------------------*\
 *  Refresh DB2 Stored Procedure definitions for production          *
 *  N.B. Not called for SQLP                                         *
\*-------------------------------------------------------------------*/
trace n

parse arg ,
c1prgrp   , /* Endevor procesor Group                                */
c1ty      , /* Endevor Type                                          */
c1ele     , /* Endevor Element                                       */
ccid        /* Endevor CCID                                          */

say 'DB2SPRFP:  *** TOP OF PARMS ***'
say 'DB2SPRFP:'
say 'DB2SPRFP:  C1PRGRP..'c1prgrp
say 'DB2SPRFP:  C1TY.....'c1ty
say 'DB2SPRFP:  C1ELE....'c1ele
say 'DB2SPRFP:  CCID.....'ccid
say 'DB2SPRFP:'
say 'DB2SPRFP:  *** END OF PARMS ***'
say 'DB2SPRFP:'

ccid = left(ccid,8)

if c1ty ^= 'SPDEF' then
  call readprg         /* Read proc group for spdef elt              */

call readsrc

/* Call DB2PARMS to just find out the DB2 subsystem.                 */
c1en    = 'PROD'
c1su    = 'XXX' /* value is irrelevent                               */
x = db2parms(c1prgrp c1en c1su c1ty) /* Call DB2PARMS                */
if x ^= 0 then call exception x 'Call to DB2PARMS failed.'

lines = queued()

do i = 1 to lines  /* Get the lines returned by DB2PARMS             */
  pull data.i
end /* i = 1 to lines                                                */

do i = 1 to lines  /* Process each line returned by DB2PARMS         */
  parse value data.i with dbsub dbqual dbown dbcoll dbwlm ,
                          dbracf db2inst desc ,
                          . . . . . . . . . . .
  if db2.dbsub ^= 'DONE' then do
    call writewlm
    db2.dbsub = 'DONE'
  end /* db2.dbsub ^= 'DONE'                                         */
end /* i = 1 to lines                                                */

exit

/*---------------------- S U B R O U T I N E S ----------------------*/

/*-------------------------------------------------------------------*/
/*  Readsrc - Read element source & check WLM no is correct          */
/*-------------------------------------------------------------------*/
readsrc:
 'execio * diskr spsrc (stem spsrc. finis'
 if rc ^= 0 then call exception rc 'DISKR of SPSRC failed'
 if spsrc.0 = 0 then call exception 4 'No SPDEF source found'

 if c1ty ^= 'SPDEF' then do
   /* If the type is not SPDEF then the API gets the source for us   */
   do i = 1 to spsrc.0                        /* Reformat API output */
     spsrc.i = substr(spsrc.i,73,80)
   end /* i = 1 to spsrc.0                                           */
 end /* c1ty ^= 'SPDEF'                                              */

 do i = 1 to spsrc.0 /* Get the production WLM environment number    */
   if subword(spsrc.i,1,2) = 'WLM ENVIRONMENT' then do
     wlmno = right(word(spsrc.i,3),2)
     leave
   end /* subword(spsrc.i,1,2) = 'WLM ENVIRONMENT'                   */
 end /* i = 1 to spsrc.0                                             */

return /* readsrc                                                    */

/*-------------------------------------------------------------------*/
/*  Readprg - If the type is not SPDEF then read the processor group */
/*            of the SPDEF element from the API output               */
/*-------------------------------------------------------------------*/
readprg:
 'execio * diskr spdef (stem spdef. finis'
 if rc ^= 0 then call exception rc 'DISKR of SPDEF failed'
 if spdef.0 = 0 then call exception 4 'No SPDEF element found'

 last_line = spdef.0
 c1prgrp   = substr(spdef.last_line,71,8)
 say 'DB2SPRFP: SPDEF processor group =' c1prgrp
 say 'DB2SPRFP:'

return /* readprg                                                    */

/*-------------------------------------------------------------------*/
/*  Writewlm - Write refresh trigger to pds                          */
/*-------------------------------------------------------------------*/
writewlm:

 say 'DB2SPRFP: Processing DB2 subsystem -' dbsub
 rffile = 'SPRF'dbsub
 x = listdsi(rffile file)
 if x > 4 then call exception x 'LISTDSI of' rffile 'failed.'
 say 'DB2SPRFP: Writing REFRESH command to' sysdsname

 dbwlm = dbsub'AE'wlmno
 queue 'EV000303 VARY WLM ENVIRONMENT' dbwlm ccid

 'execio * diskw' rffile '(finis'
 if rc ^= 0 then call exception rc 'DISKW to SPWLM failed'

 say 'DB2SPRFP: "VARY WLM ENVIRONMENT' dbwlm ccid'" written'
 say 'DB2SPRFP:'

return /* writewlm                                                   */

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
