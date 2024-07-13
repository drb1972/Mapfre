/* REXX - Routine to store the current row/line for Difference Display

   Copyright (C) 2022 Broadcom. All rights reserved.

   THESE SAMPLE ROUTINES ARE DISTRIBUTED BY BROADCOM "AS IS".
   NO WARRANTY, EITHER EXPRESSED OR IMPLIED, IS MADE FOR THEM.
   BROADCOM CANNOT GUARANTEE THAT THE ROUTINES ARE
   ERROR FREE, OR THAT IF ERRORS ARE FOUND, THEY WILL BE CORRECTED.

*/

/* Common Preamble */
if ARG(1) == "DESCRIPTION" THEN
   RETURN "Process the 'Dx' commands until two (old/new) are known"
/* End of Preamble */

parse arg PassParm
PassName = strip(PassParm,,"'")
ADDRESS ISPEXEC "VGET ("PASSNAME") SHARED"
interpret 'ALLVALS = 'PassName
ADDRESS ISPEXEC "VGET ("ALLVALS") SHARED"
ADDRESS ISPEXEC "VGET (DIFFSET1 DIFFSET2 ) PROFILE"
ADDRESS ISPEXEC "VGET (DIFFSET3 DIFFSET4) SHARED"
ADDRESS ISPEXEC "VGET (DIFFTIME DIFFDATE) SHARED"
/*
  Save the selected row details
*/
DiffCmd = USERCMD
Select
  When DiffCmd == 'DN' Then DiffNum = 1
  When DiffCmd == 'DO' Then DiffNum = 2
  When DiffCmd == 'D1' Then DiffNum = 3
  When DiffCmd == 'D2' Then DiffNum = 4
  When DiffCmd == 'DU' Then DiffNum = 1
  When DiffCmd == 'DP' Then DiffNum = 2
  otherwise do
    DiffNum = 5
  end
end
DiffLbl = word("New Old Left Rght ???",DiffNum)
if value('DIFFSET'DiffNum) == 'YES' then  /* if we already have a set line */
  call NDUSRSDR "'"DiffNum"'"             /* reset row pointed to  */
sa= value('DiffSet'DiffNum,'YES')         /* value has been set  flag */
sa= value('DiffTbl'DiffNum,USERTABL)
sa= value('DiffRow'DiffNum,USERROW )
sa= value('DiffEle'DiffNum,EEVETKEL)
sa= value('DiffEnv'DiffNum,EEVETKEN)
sa= value('DiffStg'DiffNum,EEVETKSI)
sa= value('DiffSys'DiffNum,EEVETKSY)
sa= value('DiffSbs'DiffNum,EEVETKSB)
sa= value('DiffTyp'DiffNum,EEVETKTY)
sa= value('Diffdat'DiffNum,DIFFDATE)
sa= value('Difftim'DiffNum,DIFFTIME)
if WORDpos('EEVESKVL',ALLVALS) > 0 then  /* are we on a summary screen? */
  sa= value('DiffVvl'DiffNum,EEVESKVL)   /* use the ENzIE260 key value  */
else
  sa= value('DiffVvl'DiffNum,EEVETDVL)   /* otherwise assume QE Elem Sel*/
DIFFVARS = 'DIFFSET'DIFFNUM,
           'DIFFTBL'DIFFNUM,
           'DIFFROW'DIFFNUM,
           'DIFFELE'DIFFNUM,
           'DIFFENV'DIFFNUM,
           'DIFFSTG'DIFFNUM,
           'DIFFSYS'DIFFNUM,
           'DIFFSBS'DIFFNUM,
           'DIFFTYP'DIFFNUM,
           'DIFFKEN'DIFFNUM,
           'DIFFVVL'DIFFNUM,
           'DIFFTIM'DIFFNUM,
           'DIFFDAT'DIFFNUM
USERMSG =  '*DIFF:'DIFFLBL
ADDRESS ISPEXEC "VPUT (USERMSG) SHARED"
if DiffNum == 1 | DiffNum == 2 then do
  ADDRESS ISPEXEC "VPUT ("DIFFVARS") PROFILE"
  If DiffSet1 == 'YES' & DiffSet2 == 'YES' then
    Call NDUSRSDC "1"
end
if DiffNum == 3 | DiffNum == 4 then do
  ADDRESS ISPEXEC "VPUT ("DIFFVARS") SHARED"
  If DiffSet3 == 'YES' & DiffSet4 == 'YES' then
    Call NDUSRSDC "3"
end
EXIT 0
