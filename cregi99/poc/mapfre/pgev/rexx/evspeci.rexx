/*--------------------------REXX----------------------------*/
/* Read package detail report and                           */
/* build SCL to signout elements to #EMERFIX if the         */
/* change is a specific (emer) change.                      */
/* Changed 28th June 2006 to include a signin for PMFBCH    */
/* when a package is shipped to Mplex.                      */
/*----------------------------------------------------------*/
trace n
arg pkgid action

count = 0

pkgstge = substr(pkgid,9,1)

if action = emerfix then signout = '#EMERFIX'
if action = backout then signout = '#BACKOUT'
if action = abort   then signout = '#ABORT'

If action ^= ppcm then
  say 'EVSPECI: Building SCL to signout change elements'
else
  say 'EVSPECI: Building SCL to signin package elements'

"execio * diskr pkgrep (stem pkgrep. finis" /* read package det rep */

/* If this is not a PPCM package then the environment must be PROD */
If action ^= ppcm then do
  queue 'SET FROM    ENVIRONMENT PROD STAGE P .'
  queue 'SET OPTIONS OVERRIDE SIGNOUT'
  queue '            SIGNOUT TO' signout '.'
End /* If action ^= ppcm then do */
else do
  queue 'SET OPTIONS OVERRIDE SIGNOUT SEARCH .'
  queue 'SET FROM    ENVIRONMENT SYST STAGE D .'
End /* else do */

do x = 1 to pkgrep.0 while subword(pkgrep.x,2,1) ^= 'PKMR401I'
  if word(pkgrep.x,2) = 'C1G0000I' then
    elt  = word(pkgrep.x,4)
  if word(pkgrep.x,2) = 'C1G0506I' then do
    env  = word(pkgrep.x,4)
    sys  = word(pkgrep.x,6)
    sub  = word(pkgrep.x,8)
    stge = word(pkgrep.x,10)
    type = word(pkgrep.x,12)

    if action ^= ppcm then do
      if stge = 'P' then iterate /* Its a delete */
      queue " SIGNIN ELEMENT '"elt"'"
      queue '  FROM SYSTEM' sys 'SUBSYSTEM' sys'1 TYPE' type '.'
      count = count + 1
    end  /* If action ^= ppcm then */
    else if pkgstge = stge then do /* Its a generate */
      queue " SIGNIN ELEMENT '"elt"'"
      queue '  FROM ENVIRONMENT 'env' SYSTEM 'sys
      queue '       SUBSYSTEM 'sub' TYPE 'type
      queue '       STAGE 'stge' .'
      count = count + 1
    end  /* if pkgstge = stge then do */
  end /* if subword(pkgrep.x,2,1) = 'C1G0000I' then do */
end  /* do x = i to pkgrep.0 while */

if x >= pkgrep.0 then do
  say 'EVSPECI: Package report read error for package' pkgid
  say 'EVSPECI: Text "C1G0000I" not found'
  exit 12
end

if count > 0 then
  say 'EVSPECI:' count 'elements selected for signout in package' pkgid
else do
  queue ' SIGNIN ELEMENT EVHEMERD'
  queue '  FROM ENV PROD SYSTEM EV'
  queue '       SUBSYSTEM EV1 TYPE DATA STAGE O'
  queue '  OPTIONS SIGNOUT TO " " .'
  say 'EVSPECI: No elements selected for signout in package' pkgid
end

"execio "queued()" diskw scl (finis"

exit
