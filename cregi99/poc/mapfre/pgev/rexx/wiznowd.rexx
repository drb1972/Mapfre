/*-----------------------------REXX----------------------------------*\
 *  Called by TSO WIZ <cmr>                                          *
 *  This option does not display a panel and submits the job.        *
\*-------------------------------------------------------------------*/

SAY 'estoy en el rexx WIZNOWD'
trace i
parse arg change emerchg

address ispexec
"vget (zuser zprefix)"
if zprefix ^= 'TTOS' then do /* For the DBAs                         */
  wizlib = "TT"right(zprefix,2)"."ZUSER"."change".WIZCNTL"
  mask   = 'TT'right(zprefix,2)'.'change'.**'
end /* zprefix ^= 'TTOS' */
else do /* For Batch Services                                        */
  wizlib = "TT"c1system"."ZUSER"."change".WIZCNTL"
  mask   = 'TT'c1system'.'change'.**'
end /* else */

"VPUT (WIZLIB)"
"VPUT (CHANGE)"
"VPUT (C1SYSTEM)"
"VPUT (MASK)"

call 'WIZ0201D' change 'OS'

if emerchg = 'EMER' then
  call 'WIZ0401D' change 'OS' 'Y' 'N' 'Y' 'PROD' 'N' 'WIZNOW'
else
  call 'WIZ0401D' change 'OS' 'Y' 'Y' 'Y' 'ACPT' 'N' 'WIZNOW'

exit
