/*--------------------------REXX----------------------------*\
 *  Check racf command element names are standard.          *
 *  Scan for password commands and check password member    *
 *  exists.                                                 *
 *----------------------------------------------------------*
 *  Author:     Emlyn Williams                              *
 *              Endevor Support                             *
 *----------------------------------------------------------*
 *                                                          *
\*----------------------------------------------------------*/
trace n

parse arg c1ele c1ccid

c1ele   = strip(c1ele)
elenum  = substr(c1ele,2,6)
c1ccid  = strip(c1ccid)
ccidnum = right(c1ccid,6)

if c1ccid = 'NDVR#SUPPORT' then
  passwdsn = 'TTEK.AUTO.PASSWORD'   /* For testing               */
else
  passwdsn = 'PGSQ.AUTO.PASSWORD'

/* Check the element name matches the ccid */
if c1ccid ^= 'NDVR#SUPPORT' & ,     /* For testing               */
   (pos(left(c1ele,1),'BC') = 0 | , /* First char must be C or B */
    elenum ^= ccidnum) then do      /* The numbers must match    */
  queue 'RACFCHK: Invalid element name    : ' c1ele
  queue 'RACFCHK: The CCID (CMR number) is: ' c1ccid
  queue 'RACFCHK: The format of the element name is:'
  queue 'RACFCHK:   The first character must be C for change  or'
  queue 'RACFCHK:                               B for backout'
  queue 'RACFCHK:   The next 6 characters must match the last 6 of the CCID'
  queue 'RACFCHK:   The last character is free format'
  queue 'RACFCHK:'
end

/* Check for password commands             */
"execio * diskr source (stem source. finis"
if rc > 0 then do
  say 'RACFCHK: Error reading DD SOURCE, RC =' rc
  call exception 12
end

do i = 1 to source.0
  line    = source.i
  upper line
  pwdscan = pos('PASSWORD(%%PWD%%)',line)
  command = word(line,1)
  userid  = word(line,2)
  memchk  = passwdsn'('userid')'

  if pwdscan > 0 then do
    if command ^= 'ALU' & command ^= 'ALTUSER' then do
      queue 'RACFCHK: %%PWD%% found but the command is not "ALU" or "ALTUSER".'
      queue 'RACFCHK: Line number:' i
      queue '-->' source.i
      queue 'RACFCHK:'
    end
    else
      if sysdsn("'"memchk"'") <> 'OK' then do
        queue 'RACFCHK: No password member found for' userid
        queue 'RACFCHK:' memchk 'not found'
        queue 'RACFCHK: Line number:' i
        queue '-->' source.i
        queue 'RACFCHK:'
      end
  end /* pwdscan > 0 */

  if (command = 'ALU' | command = 'ALTUSER') &,
     pos('PASSWORD(',line) > 0 &,
     pos('PASSWORD(%%PWD%%)',line) = 0 then do
    queue 'RACFCHK: ALU command found but no PASSWORD(%%PWD%%) coded'
    queue 'RACFCHK: Line number:' i
    queue '-->' source.i
    queue 'RACFCHK:'
  end

  if wordpos(command,'ADDUSER PASSWORD') > 0 then do
    queue 'RACFCHK: The ADDUSER & PASSWORD commands are not permitted'
    queue 'RACFCHK: Line number:' i
    queue '-->' source.i
    queue 'RACFCHK:'
  end

end /* i = 1 to source.0 */

if queued() > 0 then do
  'execio' queued() 'diskw README (finis'
  if rc > 1 then do
    say 'RACFCHK:'
    say 'RACFCHK: Error writting to DD README. RC =' rc
    call exception 12
  end
  exit 8
end /* queued() > 0 */

exit

/*------------------ S U B R O U T I N E S ------------------*/

/* +---------------------------------------------------------------+ */
/* |  Error with line number displayed                             | */
/* +---------------------------------------------------------------+ */
Exception:
 arg return_code

 parse source . . rexxname . /* Get the rexx name (generic subroutine)*/
 say rexxname': Exception called from line' sigl

exit return_code
