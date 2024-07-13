/*-----------------------------REXX----------------------------------*\
 *  This routine gets output from the current active job in SDSF     *
 *  and writes it out to ddname OUTPUTn.                             *
 *  It accepts the DDNAME(s) to copy from as input and uses the last *
 *  DDNAME of that name on the spool.                                *
 *  E.g. To copy EAR file customise output to a listing in GEAR.     *
\*-------------------------------------------------------------------*/
trace n

arg ddnames

say 'SDSFGET:' Date() Time()
say 'SDSFGET:'
say 'SDSFGET: Ddnames.........:' ddnames
say 'SDSFGET:'

/* Work out job number and job name                                  */
ascb      = c2x(storage(224,4))
assb      = c2x(storage(d2x(x2d(ascb)+336),4))
jsab      = c2x(storage(d2x(x2d(assb)+168),4))
jobnum    = storage(d2x(x2d(jsab)+20),8)
job       = mvsvar('SYMDEF','JOBNAME')
user      = userid()

say 'SDSFGET: Jobnum..........:' jobnum
say 'SDSFGET: Jobname.........:' job
say 'SDSFGET: Owner...........:' user
say 'SDSFGET:'

/* Set up some variables for SDSF calls                              */
rc        = isfcalls('ON')
isfprefix = job
isfowner  = user
isffilter = 'jobid eq' jobnum
cmd       = 'DA OJOB'

/* Find the job in SDSF                                              */
call sdsfcall "ISFEXEC" cmd

if jname.0 = 0 then do
  say 'SDSFGET:' job 'not found on spool'
  exit 12
end /* jname.0 = 0 */

/* ? the job to split the output                                     */
call sdsfcall "ISFACT" cmd "TOKEN('"token.1"') PARM(NP ?) (PREFIX JDS_"

/* Loop through each of the requested DDNAMEs                        */
do z = 1 to words(ddnames)
  ddname = word(ddnames,z)
  say 'SDSFGET:'
  say 'SDSFGET: Scanning for DDname' ddname

  /* loop backwards through each of the DDNAMEs in teh job output    */
  do jx = jds_token.0 to 1 by -1

    say 'SDSFGET:' left(jds_ddname.jx,8) left(jds_stepn.jx,8) ,
        jds_dsid.jx

    if jds_ddname.jx = ddname then do
      call extract
      leave jx
    end /* jds_ddname.jx = ddname */

  end /* jx = 1 to jds_token.0 */

  say 'SDSFGET:' right(records,6) 'records copied from' ,
      left(ddname,8) right(jds_dsid.jx,3) 'to OUTPUT'z

  "execio 0 diskw OUTPUT"z "(finis"
  if rc ^= 0 then call exception rc 'DISKW of OUTPUT1 failed'

end /* z = 1 to words(ddnames) */

rc = isfcalls("Off")

exit

/*---------------------- S U B R O U T I N E S ----------------------*/

/*-------------------------------------------------------------------*/
/* Extract and write the SDSF output                                 */
/*-------------------------------------------------------------------*/
extract:

 /* Allocate the DD using the SA command                             */
 call sdsfcall "ISFACT" cmd "TOKEN('"jds_token.jx"') PARM(NP SA)"

 records = 0

 /* Read in the records from the spool and write to DD OUTPUTn       */
 do forever

   "execio 500 diskr" isfddname.1
   readrc = rc
   if rc > 2 then call exception rc 'DISKW of OUTPUT'z 'failed'

   records = records + queued()

   "execio" queued() "diskw OUTPUT"z "(finis"
   if rc ^= 0 then call exception rc 'DISKW of OUTPUT'z 'failed'

   if readrc = 2 then leave

 end /* do forever */

return /* extract: */

/*-------------------------------------------------------------------*/
/* sdsfcall - Call SDSF to issue the command                         */
/*-------------------------------------------------------------------*/
sdsfcall:

 parse arg cmdstr

 address SDSF cmdstr
 if rc = 0 then return

 say 'SDSFGET: Command "'cmdstr'" failed RC='rc

 if isfmsg <> "" then say isfmsg

 do ix = 1 to isfmsg2.0
   say 'SDSFGET:' isfmsg2.ix
 end /* ix = 1 to isfmsg2.0 */

 exit 20

return /* sdsfcall: */

/*-------------------------------------------------------------------*/
/* Error with line number displayed                                  */
/*-------------------------------------------------------------------*/
exception:
 parse arg return_code comment

 parse source . . rexxname . . . . addr .
 say rexxname':'
 say rexxname':' comment 'RC='return_code
 say rexxname': Exception called from line' sigl

 if addr ^= 'MVS' then do
   z = msg(off)
   address tso 'delstack'           /* Clear down the stack          */
   z = msg(on)
 end /* addr ^= 'MVS' */

 if return_code < 0 then return_code = 12 /* - RCs can be invalid    */

exit return_code
