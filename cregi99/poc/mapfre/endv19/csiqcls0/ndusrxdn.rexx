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
   RETURN "Use the 'DN' command to pick the 'NEW' element for commpare"
/* End of Preamble */

parse arg PassParm
UserCmd = "DN"           /* as if user Command DN were entered */
ADDRESS ISPEXEC "VPUT (USERCMD) SHARED"
call NDUSRSD# "'"PassParm"'" /* call Diff Line Cmd routine to store details */
EXIT 0
