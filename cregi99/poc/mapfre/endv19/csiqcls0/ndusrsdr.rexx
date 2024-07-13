/* REXX - Display DIfferences - reset message routine

   Copyright (C) 2022 Broadcom. All rights reserved.

   THESE SAMPLE ROUTINES ARE DISTRIBUTED BY BROADCOM "AS IS".
   NO WARRANTY, EITHER EXPRESSED OR IMPLIED, IS MADE FOR THEM.
   BROADCOM CANNOT GUARANTEE THAT THE ROUTINES ARE
   ERROR FREE, OR THAT IF ERRORS ARE FOUND, THEY WILL BE CORRECTED.

*/

/* Common Preamble */
if ARG(1) == "DESCRIPTION" THEN
   RETURN "Sample routine to display row contents"
/* End of Preamble */

/* Reset the prior selection */
if ARG(1) == "DIFFRESET" then do
   call Gbl_Scope_Reset
   RETURN
end

parse arg DiffNum NewStatus /* Expect up to 2 parms; the DiffSet to Reset */
DiffNum = strip(DiffNum,,"'")                 /* remove any quotes        */
if NewStatus == '' then                       /* do we have a new status? */
   NewStatus = '*Reset'                       /* set status to *Reset     */
else                                          /* Otherwise...             */
   NewStatus = strip(NewStatus,,"'")          /* remove any quotes        */
/* OK we have a valid value */
if DiffNum = 1 | DiffNum = 2 | DiffNum = 3 | DiffNum = 4 then NOP
else Exit 12                               /* something wrong investigate */

/*
ADDRESS ISPEXEC "CONTROL ERRORS RETURN"       /* IGNORE TB STATUS MSGS    */
*/
SA= VALUE('DIFFSET'DIFFNUM,'RESET')           /* RESET THIS STATUS  AND...*/
if DiffNum == 3 | DiffNum == 4 then           /* SAVE IT  */
  INTERPRET 'ADDRESS ISPEXEC "VPUT (DIFFSET'DIFFNUM') SHARED"'
else
  INTERPRET 'ADDRESS ISPEXEC "VPUT (DIFFSET'DIFFNUM') PROFILE"'
DIFFVARS = 'DIFFTBL'DIFFNUM,                  /* SET THE VAR NAMES WE NEED*/
           'DIFFROW'DIFFNUM,
           'DIFFELE'DIFFNUM,
           'DIFFENV'DIFFNUM,
           'DIFFSTG'DIFFNUM,
           'DIFFSYS'DIFFNUM,
           'DIFFSBS'DIFFNUM,
           'DIFFTYP'DIFFNUM,
           'DIFFKEN'DIFFNUM,
           'DIFFVVL'DIFFNUM
if DiffNum == 3 | DiffNum == 4 then
   ADDRESS ISPEXEC "VGET ("DIFFVARS") SHARED"    /* ...AND GET THEM       */
else
   ADDRESS ISPEXEC "VGET ("DIFFVARS") PROFILE"   /* ...AND GET THEM       */
INTERPRET 'ADDRESS ISPEXEC "TBOPEN" DIFFTBL'DIFFNUM  "NOWRITE SHARE"
TBOPENRC = RC
If TBOPENRC > 0 then Exit 0                   /* no table to update, exit */
INTERPRET 'ADDRESS ISPEXEC "TBVCLEAR" DIFFTBL'DIFFNUM
TBCLERRC = RC
EEVETKEL = VALUE('DIFFELE'DIFFNUM)            /* SET THE TABLE KEYS       */
EEVETKEN = VALUE('DIFFENV'DIFFNUM)
EEVETKSI = VALUE('DIFFSTG'DIFFNUM)
EEVETKSY = VALUE('DIFFSYS'DIFFNUM)
EEVETKSB = VALUE('DIFFSBS'DIFFNUM)
EEVETKTY = VALUE('DIFFTYP'DIFFNUM)
if WORDpos('EEVESKVL',DiffVars) > 0 then /* are we on a summary screen? */
  SA= VALUE('DIFFVVL'DIFFNUM,EEVESKVL)   /* USE THE ENZIE260 KEY VALUE  */
else
  SA= VALUE('DIFFVVL'DIFFNUM,EEVETDVL)   /* OTHERWISE ASSUME QE ELEM SEL*/
INTERPRET 'ADDRESS ISPEXEC "TBGET" DIFFTBL'DIFFNUM
TBGETRC = RC                                  /* if we got it...          */
if TBGETRC = 0 Then do                        /* reset the row and save it*/
   EEVETDMS = NEWSTATUS                       /* NEW STATUS */
   INTERPRET 'ADDRESS ISPEXEC "TBPUT" DIFFTBL'DIFFNUM
end
if TBOPENRC = 0 then
  INTERPRET 'ADDRESS ISPEXEC "TBEND" DIFFTBL'DIFFNUM
ADDRESS ISPEXEC "CONTROL ERRORS CANCEL"       /* RESET ERROR TTRAP        */
exit

Gbl_Scope_Reset:
ADDRESS ISPEXEC "VGET (ZSCREEN) SHARED"
TABLEID =  "EN"ZSCREEN"IE250"
if TABLEID /= '' then do
  ADDRESS ISPEXEC "TBSTATS" TABLEID "STATUS2(TABSTAT)"
  if TABSTAT = 4 Then do
    ADDRESS ISPEXEC "VGET (DiffSet3 DiffSet4) SHARED"
    ADDRESS ISPEXEC "TBSTATS" TABLEID "CDATE(DIFFDATE)" "CTIME(DIFFTIME)"
    ADDRESS ISPEXEC "VPUT (DIFFDATE DIFFTIME) SHARED"
    if diffset3 == 'YES' then do
      ADDRESS ISPEXEC "VGET (Diffdat3 Difftim3 ) SHARED"
      if (Difftim3||Diffdat3) ^== (DIFFTIME||DIFFDATE) then do
        call NDUSRSDR "3"
        ADDRESS ISPEXEC "VGET (DiffSet3 DiffSet4) SHARED"
        end
    end
    if diffset4 == 'YES' then do
      ADDRESS ISPEXEC "VGET (Diffdat4 Difftim4 ) SHARED"
      if (Difftim4||Diffdat4) ^== (DIFFTIME||DIFFDATE) then
        call NDUSRSDR "4"
    end
  end
end
RETURN;
