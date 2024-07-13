/*--------------------------REXX----------------------------*\
 *  This REXX allows the user to switch to view mode when   *
 *  in Endevor temporary dataset browse.                    *
 *  This can either be an element or listing browse or      *
 *  a processor listing (vi help for options).              *
 *                                                          *
 *  (Uses DDNAME C1#xTMPL where x is the zscreen)           *
 *  Try the current screen first then try up to 4 more      *
 *  Note: it could be an old d/s though                     *
\*----------------------------------------------------------*/
trace n
arg parm

type = word(parm,1)

if type = help then do
  say 'This utility switches from Endevor browse to view mode:'
  say
  say ' To view an element or listing           enter "VI"'
  say ' To view an element with no reformatting enter "VI NR"'
  say
  say ' To view a  processor                    enter "VI PR"'
  exit 8
end

found = 'n'
uid      = sysvar(sysuid)
address ispexec
"vget zscreen"
"control errors return"
repddn = outrep || zscreen
address tso
null = outtrap('discard.')         /* Free output file if allocated */
"free fi("repddn")"
null = outtrap('off')
"alloc fi("repddn") space(15,15) tracks reuse lrecl(132)"
if rc > 0 then do
  say "Allocation for temp view dsn failed"
  exit 12
end

if type = 'PR' then call viewpr

else call viewelt

if found = 'n' then do
  address ispexec
  zedsmsg = 'Nothing to Browse' /* set up a message, and exit */
  zedlmsg = 'Could not invoke VIEW. ',
            'The Endevor "browse" was not allocated or was empty.'
  "setmsg msg(isrz001)"
  exit 12
end /* if found = 'n' then do */

exit

/*                          S U B R O U T I N E S                     */

/*------------------------*/
/* View processor         */
/*------------------------*/
VIEWPR:
/*  Read allocated dataset list to get ddname of report output  */
null = outtrap('ddlist.')
address tso "lista status sysnames"
null = outtrap('off')
do k = ddlist.0 to 1 by -1 while found = 'n'  /* Start at last dd */
  x = pos('.'uid'.PRGRP.H',ddlist.k)
  if x <> 0 then do
    n = k + 1
    ddn = subword(ddlist.n,1,1)
    call reformat
  end
end
return
/*------------------------*/
/* View element           */
/*------------------------*/
VIEWELT:
address ispexec
ddn = 'c1#'zscreen'tmpl'
x = listdsi(ddn file)          /* Try current screen */
if x = 0 then
  call reformat
else do y = 1 to 5             /* Try the other screens (up to 5) */
  if y <> zscreen then do
    ddn =  'c1#'y'tmpl'
    x = listdsi(ddn file)
    if x = 0 & type ^= 'NR' then do
      call reformat
      leave
    end
  end
end

return

/*--------------------------------------------------------------*/
/*  Read temp dataset and remove header info and VV.LL info     */
/*--------------------------------------------------------------*/
REFORMAT:
  found = 'y'

  address tso
  "execio * diskr" ddn "(stem code. finis"
  do i= 1 to code.0            /* assume its an element browse */
    if substr(code.i,3,1) = '+' then
      if type ^= 'NR' then
        queue substr(code.i,10)
      else
        queue code.i
  end
  x = queued()
  if x = 0 then              /* if not element browse then output all */
    do i= 1 to code.0
      queue code.i
    end
  queue
  "execio * diskw "repddn" ( finis"
  address ispexec
  "lminit dataid(id) ddname("repddn")"
  "edit dataid(&id) macro(viewed)"
  "lmfree dataid(&id)"
  address tso "free fi("repddn")"
return
