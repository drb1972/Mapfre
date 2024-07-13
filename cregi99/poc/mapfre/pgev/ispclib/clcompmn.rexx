/*-----------------------------REXX----------------------------------*\
 *  Component List Compare front end.                                *
 *  Invoked from the User Menu, option 10                            *
\*-------------------------------------------------------------------*/
parse source . . rexxname rexxdd rexxlib .
if sysdsn("'TTEV.TRACE."rexxname"'") = 'OK' then trace i
arg parm

true     = 1
false    = 0
valid    = 0
action   = word(parm,1)
uid      = sysvar('sysuid')
hlq      = sysvar('syspref')
rexxlib2 = 'PGEV.BASE.ISPCLIB'
if rexxlib = '?' then do
  listdsi_parm = rexxdd 'file'
  x = listdsi(listdsi_parm)
  rexxlib = sysdsname
end /* rexxlib = '?' */

exit_process = false
do until exit_process
  everything_okay = false
  call process_panel
  if ^exit_process then do
    if everything_okay then
      if mode = 'FOREGROUND' then
        call compare_component_lists
      else
        call create_batch_job
    exit_process = false
  end /* ^exit_process */
end /* until exit_process */

exit

/*---------------------- S U B R O U T I N E S ----------------------*/

/*-------------------------------------------------------------------*/
/* display and process the panel - new and old elements              */
/*-------------------------------------------------------------------*/
process_panel:

 address 'ISPEXEC'
 "VGET NEWSBS"
 if NEWSBS = '' then
   cursor = 'NEWSBS'
 else
   cursor = 'NEWELE'
 "DISPLAY PANEL(CLCOMP) CURSOR("cursor")"
 if rc > 4 then exit_process = true

 do while ^everything_okay & ^exit_process
   address 'TSO'
   /* Free in case there are hangovers. Do not code an exception call*/
   test = msg(off)
   "free f(COMPLST1 COMPLST2)"
   test = msg(on)

   "alloc f(COMPLST1) new space(1 1) tracks recfm(f b) lrecl(133)"
   if rc ^= 0 then call exception rc 'ALLOC of COMPLST1 failed.'

   "alloc f(COMPLST2) new space(1 1) tracks recfm(f b) lrecl(133)"
   if rc ^= 0 then call exception rc 'ALLOC of COMPLST2 failed.'

   address 'ISPEXEC'
   oldver = left(oldvvll,2)
   oldlev = right(oldvvll,2)
   newver = left(newvvll,2)
   newlev = right(newvvll,2)
   x = get_comp_list_report()
   if x = valid then
     everything_okay = true
   else do
     "setmsg msg(ISRZ001)"
     "DISPLAY PANEL(CLCOMP) CURSOR("cursor")"
     if rc > 4 then exit_process = true
   end /* else */
 end /* while ^everything_okay & ^exit_process */

return /* process_panel */

/*-------------------------------------------------------------------*/
/* create the batch job via file tailoring and go into edit on it    */
/*-------------------------------------------------------------------*/
create_batch_job:

 address 'ISPEXEC'

 "ftopen temp"
 if rc ^= 0 then call exception rc 'FTOPEN TEMP failed'

 "ftincl clcomp"
 if rc ^= 0 then call exception rc 'FTINCL of CLCOMP failed'
 "vget ( ztempf ztempn ) shared"
 if rc ^= 0 then call exception rc 'VGET of ZTEMPN failed'

 "ftclose"
 if rc ^= 0 then call exception rc 'FTCLOSE of TEMP failed'

 "lminit dataid(did) ddname("ztempn")"
 if rc ^= 0 then call exception rc 'LMINIT of' ztempn 'failed'

 "edit dataid("did")"
 if rc > 4 then call exception rc 'EDIT of' ztempn 'failed'

 "lmclose dataid("did")"
 if rc > 8 then call exception rc 'LMCLOSE of' ztempn 'failed'

 "lmfree  dataid("did")"
 if rc ^= 0 then call exception rc 'LMFREE of' ztempn 'failed'

return /* create_batch_job */

/*-------------------------------------------------------------------*/
/* call CLCOMP component list compare rexx and display report        */
/*-------------------------------------------------------------------*/
compare_component_lists:

 address 'TSO'

 /* Free in case there are hangovers. Do not code an exception call  */
 test = msg(off)
 "free f(REPORT)"
 test = msg(on)

 /* Allocate the necessary datasets                                  */
 /* COMPLST1 and COMPLST2 previously allocated                       */
 "alloc f(report) new space(1 1) tracks recfm(f b) lrecl(160)"
 if rc ^= 0 then call exception rc 'ALLOC of REPORT failed.'

 if action = 'TEST' then do
   say 'Displaying OLD element component list report'
   address 'ISPEXEC'
   "lminit dataid(cid) ddname(complst1)" /* Initialise rpt for view  */
   if rc ^= 0 then call exception rc 'LMINIT of COMPLST1 failed'
   signal off error
   "view dataid(&cid)"
   if rc ^= 0 then call exception rc 'VIEW of COMPLST1 failed'
   "lmfree dataid(&cid)"

   say 'Displaying NEW element component list report'
   address 'ISPEXEC'
   "lminit dataid(cid) ddname(complst2)" /* Initialise rpt for view  */
   if rc ^= 0 then call exception rc 'LMINIT of COMPLST2 failed'
   signal off error
   "view dataid(&cid)"
   if rc ^= 0 then call exception rc 'VIEW of COMPLST2 failed'
   "lmfree dataid(&cid)"
 end /* action = 'TEST' */

 /* call rexx to process the 2 component lists                       */
 call 'CLCOMP' clpgi clpgs clro cloc cldo clic

 address 'ISPEXEC'
 "lminit dataid(cid) ddname(report)" /* Initialise rpt for viewing   */
 if rc ^= 0 then call exception rc 'LMINIT of REPORT failed'

 signal off error
 if clbv = 'VIEW' then
   "view dataid(&cid)"
 else
   "browse dataid(&cid)"
 if rc ^= 0 then call exception rc 'VIEW of REPORT failed'

 "lmfree dataid(&cid)"

 address 'TSO'
 "free f(REPORT COMPLST1 COMPLST2)"
return /* compare_component_lists */

/*-------------------------------------------------------------------*/
/* get the component list for the specified element                  */
/*-------------------------------------------------------------------*/
get_comp_list_report:

 address 'TSO'
 /* Free in case there are hangovers. Do not code an exception call  */
 test = msg(off)
 "free f(BSTIPT01 C1MSGS1 C1MSGS2)"
 test = msg(on)

 "alloc f(BSTIPT01) new space(1 1) tracks recfm(f b) lrecl(80)"
 if rc ^= 0 then call exception rc 'ALLOC of BSTIPT01 failed.'

 /* Write the input for the call to the utility                      */
 inp.1  = "  PRINT ELEMENT '"newele"'"
 inp.2  = "  VER" newver "LEV" newlev
 inp.3  = "    FROM ENVIRONMENT" newenv
 inp.4  = "         SYSTEM" newsys "SUBSYSTEM" newsbs
 inp.5  = "         TYPE" newtyp "STAGE" newstg
 inp.6  = "      TO FILE COMPLST2"
 inp.7  = "    OPTIONS NOSEARCH NOCC"
 inp.8  = "    COMPONENT BROWSE"
 inp.9  = "   ."
 inp.10 = "  PRINT ELEMENT '"oldele"'"
 inp.11 = "  VER" oldver "LEV" oldlev
 inp.12 = "    FROM ENVIRONMENT" oldenv
 inp.13 = "         SYSTEM" oldsys "SUBSYSTEM" oldsbs
 inp.14 = "         TYPE" oldtyp "STAGE" oldstg
 inp.15 = "      TO FILE COMPLST1"
 inp.16 = "    OPTIONS NOSEARCH NOCC"
 inp.17 = "    COMPONENT BROWSE"
 inp.18 = "   ."
 inp.0 = 18
 if newver = '' then inp.2  = ' '
 if oldver = '' then inp.11 = ' '
 'execio' inp.0 'diskw BSTIPT01 (stem inp. finis)'
 if rc ^= 0 then call exception rc 'DISKW to BSTIPT01 failed.'

 /* Allocate the necessary datasets                                  */
 "alloc f(C1MSGS1) new space(1 1) tracks recfm(f b a) lrecl(134)"
 if rc ^= 0 then call exception rc 'ALLOC of C1MSGS1 failed.'
 "alloc f(C1MSGS2) new space(1 1) tracks recfm(f b a) lrecl(134)"
 if rc ^= 0 then call exception rc 'ALLOC of C1MSGS2 failed.'

 /* Invoke the SCL utility                                           */
 address "LINKMVS" 'C1BM3000'
 lnk_rc = rc

 if lnk_rc ^= valid then do
   "execio * diskr complst1 (stem out1. finis"
   "execio * diskr complst2 (stem out2. finis"
   zedsmsg = 'Component list not found'
   if out2.0 = 0 then do
     zedlmsg = 'Component list for' newenv'/'newstg'/'newsys'/' ||,
               newsbs'/'newtyp'/'newele 'not found or element',
               'does not exist'
     cursor = 'NEWELE'
   end /* out2.0 = 0 */
   else do
     zedlmsg = 'Component list for' oldenv'/'oldstg'/'oldsys'/' ||,
               oldsbs'/'oldtyp'/'oldele 'not found or element',
               'does not exist'
     cursor = 'OLDELE'
   end /* else */
 end /* lnk_rc ^= valid */
 if action = 'TEST' then do
   say 'viewing C1MSGS1 output'
   address 'ISPEXEC'
   "lminit dataid(cid) ddname(C1MSGS1)" /* Initialise for viewing    */
   if rc ^= 0 then call exception rc 'LMINIT of C1MSGS1 failed'
   signal off error
   "view dataid(&cid)"
   if rc ^= 0 then call exception rc 'VIEW of C1MSGS1 failed'
   "lmfree dataid(&cid)"
 end /* action = 'TEST' */

 address 'TSO'
 "free f(BSTIPT01 C1MSGS1 C1MSGS2)"

return lnk_rc /* get_comp_list_report */

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
   /*address ispexec "FTCLOSE"    *//* Close any FTOPENed files      */
   /*address tso "FREE F(ISPFILE)"*//* Free files that may be open   */
   address tso 'delstack'           /* Clear down the stack          */
   z = msg(on)
 end /* addr ^= 'MVS' */
 if addr ^= 'MVS' then do
   z = msg(off)
   address ispexec "FTCLOSE"     /* Close any FTOPENed files         */
   address tso "FREE F(ISPFILE)" /* Free files that may be open      */
   address tso 'delstack' /* Clear down the stack                    */
   z = msg(on)
 end /* addr ^= 'MVS' */

 if return_code < 0 then return_code = 12 /* - RCs can be invalid    */

 if addr = 'ISPF' then do
   zispfrc = return_code
   address ispexec "vput (zispfrc) shared"
 end /* addr = 'ISPF' */

exit return_code
