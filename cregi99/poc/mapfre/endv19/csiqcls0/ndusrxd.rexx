/* REXX - Sample routine redirect a user command to another user command
          Works like Alias, but can adjust values

   Copyright (C) 2022 Broadcom. All rights reserved.

   THESE SAMPLE ROUTINES ARE DISTRIBUTED BY BROADCOM "AS IS".
   NO WARRANTY, EITHER EXPRESSED OR IMPLIED, IS MADE FOR THEM.
   BROADCOM CANNOT GUARANTEE THAT THE ROUTINES ARE
   ERROR FREE, OR THAT IF ERRORS ARE FOUND, THEY WILL BE CORRECTED.

*/

/* Common Preamble */
if ARG(1) == "DESCRIPTION" THEN
   RETURN "Use the 'D' command to pick an element for compare"
/* End of Preamble */

parse arg PassParm
call  NDUSRSDR "DIFFRESET"
ADDRESS ISPEXEC "VGET (DiffSet3 DiffSet4) SHARED"
select
  When DiffSet3 ^== 'YES' & Diffset4  == 'YES' Then UserCmd = 'D1'
  When DiffSet3  == 'YES' & Diffset4 ^== 'YES' Then UserCmd = 'D2'
  When DiffSet3 ^== 'YES' & Diffset4 ^== 'YES' Then UserCmd = 'D1'
  Otherwise                                   /* if both are set...    */
    do                                        /*  ... reset them       */
      Do DiffNum = 3 to 4                     /* for each saved set... */
         call NDUSRSDR "'"DiffNum"'"          /* reset row pointed to  */
      end
      UserCmd = 'D1'                          /* Use this row as first */
    end
end
ADDRESS ISPEXEC "VPUT (USERCMD) SHARED"       /* save cmd to pass      */
call NDUSRSD# "'"PassParm"'" /* call Diff Line Cmd routine to store details */
EXIT 0
