/* REXX - DiffProd (DP) this routine sets the request to be diff command
          comparing this element to the top of the map (Prod)

   Copyright (C) 2022 Broadcom. All rights reserved.

   THESE SAMPLE ROUTINES ARE DISTRIBUTED BY BROADCOM "AS IS".
   NO WARRANTY, EITHER EXPRESSED OR IMPLIED, IS MADE FOR THEM.
   BROADCOM CANNOT GUARANTEE THAT THE ROUTINES ARE
   ERROR FREE, OR THAT IF ERRORS ARE FOUND, THEY WILL BE CORRECTED.

*/

/* Common Preamble */
if ARG(1) == "DESCRIPTION" THEN
   RETURN "Use the 'DP' command to compare this Ele to the top of the map(PROD)"
/* End of Preamble */

parse arg PassParm
UserCmd = "DP"           /* as if user Command DP were entered */
ADDRESS ISPEXEC "VPUT (USERCMD) SHARED"
call NDUSRXDU "'"PassParm"'" /* call Diff Up the map to resolve the top */
EXIT 0
