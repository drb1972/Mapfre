/*-----------------------------REXX----------------------------------*\
 *  Called by TSO WIZ                                                *
 *  Initial WIZ rexx to display WIZ panels                           *
\*-------------------------------------------------------------------*/
trace i
say 'estoy en el rexx wizzerd'
address ispexec

/* Obtain CMR and system from initial panel                          */
do while panok <> 'y'
  'display PANEL(WIZ1000)'
  if rc > 0 then exit
            else call wiz2000
end /* do while panok = 'n' */

exit

/*---------------------- S U B R O U T I N E S ----------------------*/

/*-------------------------------------------------------------------*/
/* Wiz2000                                                           */
/*-------------------------------------------------------------------*/
wiz2000:

 "vget (zuser zprefix)"

 say c1system
 say scladd
 say sclmov
 say sclpkg
 say c1env
 say ove
 say caller
 suffix = right(zprefix,2) /* get the users suite code               */

 if zprefix ^= 'TTOS' then do /* For the DBAs                        */
   wizlib = "TT"suffix"."ZUSER"."change".WIZCNTL"
   mask   = 'TT'suffix'.'change'.**'
 end /* zprefix ^= 'TTOS' */
 else do /* For Batch Services                                       */
   wizlib = "TT"c1system"."ZUSER"."change".WIZCNTL"
   mask   = 'TT'c1system'.'change'.**'
 end /* else */

 OVE    = 'N'
 "VPUT (WIZLIB)"
 "VPUT (CHANGE)"
 "VPUT (SUFFIX)"
 "VPUT (C1SYSTEM)"
 "VPUT (MASK)"
 "VPUT (OVE)"

 EMER   = 'N'
 SCLADD = 'Y'
 SCLMOV = 'N'
 SCLPKG = 'N'
 OVE    = 'N'

 say c1system
 say scladd
 say sclmov
 say sclpkg
 say c1env
 say ove
 say caller
 "VPUT (EMER)"
 "VPUT (SCLADD)"
 "VPUT (SCLMOV)"
 "VPUT (SCLPKG)"
 "VPUT (C1ENV)"
 "SELECT PANEL(WIZ2000D)"
 "VPUT (EMER)"
 "VPUT (SCLADD)"
 "VPUT (SCLMOV)"
 "VPUT (C1ENV)"
 "VPUT (OVE)"

return /* wiz2000 */
