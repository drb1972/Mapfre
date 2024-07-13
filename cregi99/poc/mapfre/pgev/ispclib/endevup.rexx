/*-----------------------------REXX----------------------------------*\
 *  Check Endevor is up before letting users in.                     *
 *  Then display RNEWS if it is up.                                  *
\*-------------------------------------------------------------------*/
trace n

plex = MVSVAR(sysplex)
if plex ^= 'PLEXE1' & plex ^= 'PLEXS1' then do
  say 'Endevor is not available on' plex
  say 'It is only available on the Eplex'
  exit 12
end /* plex ^= 'PLEXT1' & plex ^= 'PLEXS1' */

downdsn  = 'PREV.ENDEVOR.DOWN'

if sysdsn("'"downdsn"'")  =  'OK' then do
  /* check if user is an administrator                               */
  resourcename = 'PREW.PROD.PMENU.ENVRMENT'
  classname    = 'FACILITY'
  a = outtrap('rescheck.','*')
  address tso "RESCHECK RESOURCE("resourcename") CLASS("classname")"
  reschkrc = rc
  a = outtrap('off')
  /* end of ndvr admin rights check                                  */

  if reschkrc ^= 0 then do
    zedsmsg = ""
    zedlmsg = "Endevor is unavailable at the moment."          ,
              "For more information - During UK working hours" ,
              "contact mapfre.endevor@rsmpartners.com"   ,
              "or +44 (0)1527 837767.",
              "Outside UK working hours contact Systems"       ,
              "Operations on +44 000 000 0000."
    address ispexec "SETMSG MSG(ISRZ001)"
    exit 12
  end /* reschkrc ^= 0 */
  else do
    say 'Endevor is down for most people'
    exit 4
  end /* else */

end /* sysdsn("'"downdsn"'")  =  'OK' */

Address Ispexec
"SELECT CMD(%RNEWS NDVR NEW SHOW30) NEWAPPL(ISP) PASSLIB"

exit 0

