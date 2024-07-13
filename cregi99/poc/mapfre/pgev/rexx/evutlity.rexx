/*-----------------------------REXX----------------------------------*\
 *   This is invoked when EVGMJOBI runs.                             *
 *                                                                   *
 *   It checks if there are any sequential files created by change   *
 *   records being aborted/backed out/re-scheduled.                  *
 *   The Mjob is built in to PGEV.AUTO.CMJOBS and demanded on to     *
 *   CA7P04 using the CA7 API.                                       *
 *                                                                   *
 *   Calls:      Rexx      - CMOFFSET in PGEV.BASE.REXX              *
 *               Skeletons - CMSPACKB CMSWIZAB CMSAOT   CMSAOA       *
 *                           CMSAOB   CMSPACKS CMSRSCH  CMSAOR       *
\*-------------------------------------------------------------------*/
signal on syntax  name exception /* Required for ISPF batch only     */
signal on failure name exception /* Required for ISPF batch only     */

parse source . . rexxname . . . . addr .
if sysdsn("'TTEV.TRACE."rexxname"'") = 'OK' then trace i

arg hlq /* passed from the batch job                                 */

assignd = hlq'.NCMR.UTILITY' /* Dataset list for running listcat     */

/* Get the names of the utility sequential files                     */
z = outtrap('cmrs.','*',concat)
address tso "LISTC LEVEL('"assignd"') NAMES"
z = outtrap('off')

if rc = 4 then do
  say rexxname': LISTC of' assignd '= 4'
  say rexxname': No datasets to process'
  zispfrc = 4
  address ispexec "vput (zispfrc) shared"
  exit 4
end /* rc = 4 */

/* if the listcat came back with anything other than zero then exit  */
if rc ^= 0 then call exception rc 'LISTC failed.'

call stemvars /* Read DESTSYS & DESTINFO                             */

call dests /* Work out the destination names                         */

cmr_no = cmrs.0 / 2 /* listcat produces two lines per cmr            */
say
say rexxname': Number of CMRs to process =' cmr_no
say
do c = 1 to cmrs.0 /* display the output from the listcat            */
  say cmrs.c
end /* c = 1 to cmrs.0 */
say

/* Process the assigned CMR datasets                                 */
do a = 1 to cmrs.0 /* loop through the listcat output                */

  if pos(assignd,cmrs.a) > 1 then do

    dsn      = strip(word(cmrs.a,3)) /* get the dsn from listcat     */
    cmr      = substr(dsn,19,8)      /* CMR number                   */
    cnum     = right(cmr,7)          /* The numeric part of the CMR  */
    rmem     = 'M'cnum               /* &RMEM used by skeletons      */
    shiphlqc = 'PGEV.SHIP.'cmr       /* used in skeletons            */

    /* Allocate the Infoman data file exclusively                    */
    "ALLOC F(SOURCE) DSNAME('"dsn"') OLD"
    if rc ^= 0 then call exception rc 'ALLOC of' dsn 'failed.'

    'EXECIO 1 DISKR SOURCE (FINIS' /* Read CMR info                  */
    if rc ^= 0 then call exception rc 'EXECIO read of' dsn 'failed.'

    parse pull cci parm1 parm2 rest
    say rexxname':'
    say rexxname': The following data will be processed:-'
    rest = strip(rest,'t')
    say
    say cmr parm1 parm2 rest
    say
    say rexxname':'

    select
      when parm2 = 'ABORT'      then call EVGABRTI
      when parm2 = 'BACKOUT'    then call EVGBACKI
      when parm2 = 'RESCHEDULE' then call EVGRSCHI
      otherwise call exception 7 'Unrecognised action:-' parm2
    end /* select */

    /* Use the CA7 API to demand the Mjob on                         */
    say rexxname':'
    say rexxname': Using the CA7 API to issue the command:-'
    say rexxname': P04 YE DEMAND,JOB='rmem','ca7cls',JCLID=6'
    say rexxname':'

    if hlq = 'PGEV' then do /* only run for production hlq           */

      /* Use the CA7 API to demand the Rjob on                       */
      call @CA7RXIF("P04 YE DEMAND,JOB="rmem",CLASS=A,JCLID=6")

      if result <> 0 then do /* Error encountered from CA7/rexx      */
        do x = 1 to queued   /* Loop round error messages            */
          pull ca7out.x      /* get next error message               */
          say ca7out.x       /* Print to SYSTSPRT                    */
        end /* x = 1 to queued */
        call exception result 'CA7 demand has failed.'
      end /* result <> 0 */

      delstack /* Clear down the stack                               */

    end /* hlq = 'PGEV'*/

    "FREE F(SOURCE)" /* free the Infoman data file                   */
    if rc ^= 0 then call exception rc 'FREE of' dsn 'failed.'

    if hlq = 'PGEV' then do /* only run for production hlq           */

      "DELETE '"dsn"'" /* delete the Infoman data file               */
      if rc ^= 0 then call exception rc 'DELETE of' dsn 'failed.'

    end /* hlq = 'PGEV'*/

  end /* pos(assignd,cmrs.a) > 1 */

end /* a = 1 to cmrs.0 */

exit

/*---------------------- S U B R O U T I N E S ----------------------*/

/*-------------------------------------------------------------------*/
/*   This builds the Mjob for aborting change records.               */
/*-------------------------------------------------------------------*/
evgabrti:

 stpname = 'EVGABRTI' /* Set the AO stepname                         */
 option  = 'ABORT'    /* &OPTION used by CMSAOT skeleton             */
 c1sy    = parm1      /* &C1SY used by CMSPACS skeleton              */

 address ispexec
 FTOPEN /* start file tailoring                                      */

 FTINCL CMSPACKB /* package backout                                  */
 if rc ^= 0 then call exception rc 'FTINCL of CMSPACKB failed.'

 FTINCL CMSWIZAB /* Wizard change abort                              */
 if rc ^= 0 then call exception rc 'FTINCL of CMSWIZAB failed.'

 FTINCL CMSAOT /* start of the AO step                               */
 if rc ^= 0 then call exception rc 'FTINCL of CMSAOT failed.'

 do s = 1 to dest.0
   dest = dest.s
   ca7 = ca7.dest
   FTINCL CMSAOA /* The abort command for each dest                  */
   if rc ^= 0 then call exception rc 'FTINCL of CMSAOA failed.'
 end /* s = 1 to dest.0 */

 FTINCL CMSAOB /* end of the AO step                                 */
 if rc ^= 0 then call exception rc 'FTINCL of CMSAOB failed.'

 FTINCL CMSPACKS /* signout elements                                 */
 if rc ^= 0 then call exception rc 'FTINCL of CMSPACKS failed.'

 /* no exception coded because there may not be a member             */
 "FTINCL" cmr /* include archive restore                             */
 if rc ^= 0 then say rexxname': No archive restore JCL found.'

 "FTCLOSE NAME("rmem")" /* store the member name                     */
 if rc ^= 0 then call exception rc 'FTCLOSE failed'

 say rexxname': Mjob JCL written to dataset PGEV.AUTO.CMJOBS('rmem')'

return /* EVGABRTI: */

/*-------------------------------------------------------------------*/
/*   This builds the Mjob for backout of change records.             */
/*-------------------------------------------------------------------*/
evgbacki:

 stpname = 'EVGBACKI' /* Set the AO stepname                         */
 option  = 'BACKOUT'  /* &OPTION used by CMSAOT skeleton             */
 c1sy    = parm1      /* &C1SY used by CMSPACS skeleton              */

 address ispexec
 FTOPEN /* start file tailoring                                      */

 FTINCL CMSPACKB /* package backout                                  */
 if rc ^= 0 then call exception rc 'FTINCL of CMSPACKB failed.'

 FTINCL CMSAOT /* start of the AO step                               */
 if rc ^= 0 then call exception rc 'FTINCL of CMSAOT failed.'

 call stemvars /* Read DESTSYS & DESTINFO                            */

 call dests /* Work out the destination names                        */

 do i = 1 to dest.0
   dest = dest.i
   ca7 = ca7.dest
   FTINCL CMSAOA /* The backout command for each dest                */
   if rc ^= 0 then call exception rc 'FTINCL of CMSAOA failed.'
 end /* i = 1 to dest.0 */

 FTINCL CMSAOB /* end of the AO step                                 */
 if rc ^= 0 then call exception rc 'FTINCL of CMSAOB failed.'

 FTINCL CMSPACKS /* signout elements                                 */
 if rc ^= 0 then call exception rc 'FTINCL of CMSPACKS failed.'

 /* no exception coded because there may not be a member             */
 "FTINCL" cmr /* include archive restore                             */
 if rc ^= 0 then say rexxname': No archive restore JCL found.'

 "FTCLOSE NAME("rmem")" /* store the member name                     */
 if rc ^= 0 then call exception rc 'FTCLOSE failed'

 say rexxname': Mjob JCL written to dataset PGEV.AUTO.CMJOBS('rmem')'

return /* evgbacki: */

/*-------------------------------------------------------------------*/
/*   This builds the Mjob for re-schedule of change records.         */
/*-------------------------------------------------------------------*/
evgrschi:

 stpname = 'EVGRSCHI'   /* Set the AO stepname                       */
 option  = 'RESCHEDULE' /* &OPTION used by CMSAOT skeleton           */
 assoc   = parm1        /* assoc is the data from Infoman            */

 /* Assign initial variables                                         */
 libtyp      = substr(assoc,1,1)
 demand_type = substr(assoc,2,1)
 chdate      = substr(assoc,10,5)
 chtime      = substr(assoc,15,4)
 frdate      = substr(assoc,19,5)
 frtime      = substr(assoc,24,4)

 select
   when demand_type = 'N' then demand = 'DEMAND'
   when demand_type = 'Y' then demand = 'DEMANDH'
   otherwise call exception 20 'Unknown demand type of' demand_type
 end /* select */

 address ispexec
 FTOPEN /* start file tailoring                                      */

 FTINCL CMSRSCH /* Start of the re-schedule job                      */
 if rc ^= 0 then call exception rc 'FTINCL of CMSRSCH failed.'

 do u = 1 to dest.0 /* loop through each destination                 */

   dest      = dest.u
   ca7       = ca7.dest     /* ca7 long name                         */
   xcmr      = cmr.dest     /* time offset for destination           */
   direction = word(xcmr,1) /* is it + or - for time offset          */
   amount    = word(xcmr,2) /* how much time do we add               */

   /* Date / Time re-calculation                                     */
   call CMOFFSET chdate chtime direction amount
   /* Results from CMOFFSET routine                                  */
   parse var RESULT xchdate xchtime xfrdate xfrtime

   FTINCL CMSAOR /* The reschedule cmd for each dest  */
   if rc ^= 0 then call exception rc 'FTINCL of CMSAOR failed.'

 end /* u = 1 to dest.0 */

 FTINCL CMSAOB /* end of the AO step                                 */
 if rc ^= 0 then call exception rc 'FTINCL of CMSAOB failed.'

 "FTCLOSE NAME("rmem")" /* store the member name                     */
 if rc ^= 0 then call exception rc 'FTCLOSE failed'

 say rexxname': Mjob JCL written to dataset PGEV.AUTO.CMJOBS('rmem')'

return /* evgbacki: */

/*-------------------------------------------------------------------*/
/* Read data members in to stem vars                                 */
/*-------------------------------------------------------------------*/
stemvars:

 /* Read the file in                                                 */
 ADDRESS TSO "EXECIO * DISKR PLEXES (STEM destsys. FINIS)"
 if rc ^= 0 then call exception rc 'DISKR of DDname PLEXES failed'

 do j = 1 to destsys.0
   interpret destsys.j /* Interpret the variables                    */
 end  /* j = 1 to destsys.0 */

 /* Read the file in                                                 */
 ADDRESS TSO "EXECIO * DISKR VARIABLE (STEM destinfo. FINIS)"
 if rc ^= 0 then call exception rc 'DISKR of DDname VARIABLE failed'

 do k = 1 to destinfo.0
   interpret destinfo.k /* Interpret the variables                   */
 end  /* k = 1 to destinfo.0 */

return /* stemvars: */

/*-------------------------------------------------------------------*/
/* Work out where we need to abort                                   */
/*-------------------------------------------------------------------*/
dests:

 list_dests = c1systemb.default /* set up the initial variable       */
 f          = 1 /* set the array counter initially                   */
 dest.0     = 0 /* set the array maximum initially                   */

 /* Get all the destinations for this system into array "dest"       */
 do while list_dests ^= ''
   parse var list_dests dest.f list_dests
   if dest.f = "" then leave /* nothing left in the string           */
   dest.0 = f /* set the array maximum                               */
   f = f + 1 /* increment array counter                              */
 end /* while list_dests ^= '' */

return /* dests: */

/*-------------------------------------------------------------------*/
/* Error with line number displayed                                  */
/*-------------------------------------------------------------------*/
exception:
 parse arg return_code comment

 if wordpos(condition('C'),'SYNTAX FAILURE') > 0 then do
   say 'Line' sigl':' left(sourceline(sigl),70)
   say 'Errortext:' errortext(rc)
   return_code = rc
   comment     = condition('C') 'failure at line' sigl
 end /* wordpos(condition('C'),'SYNTAX FAILURE') > 0 */

 say rexxname':'
 say rexxname':' comment 'RC='return_code
 say rexxname': Exception called from line' sigl

 if addr ^= 'MVS' then do
   z = msg(off)
   address ispexec "FTCLOSE" /* Close any FTOPENed files             */
   address tso 'delstack'    /* Clear down the stack                 */
   z = msg(on)
 end /* addr ^= 'MVS' */

 if return_code < 0 then return_code = 12 /* - RCs can be invalid    */

 zispfrc = return_code
 address ispexec "vput (zispfrc) shared"

exit return_code
