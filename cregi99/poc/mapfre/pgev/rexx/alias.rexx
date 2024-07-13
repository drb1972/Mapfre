/* REXX */

/* This rexx is used by the MOVE & DELETE  processors             */
/* to process the output of a step that checks to see if there    */
/* are any aliases that belong to the LNK* type being processed   */
/* if aliases are found, then the step builds copy or delete      */
/* cards for them and passes them to a later step for actioning.  */
/*                                                                */

foundrc = 0
parse arg action
say 'ALIAS: '
say 'ALIAS: Start of the ALIAS routine with the following parm:-'
say 'ALIAS: 'action
say 'ALIAS: '

"execio * diskr aliasin (stem rep. finis"
cc = rc
  if cc > 0 then do
    say 'ALIAS: execio of ALIASIN ddname gave a return code of 'cc
    exit cc
  end /* if cc > 0 then do */

do c=1 to rep.0
say 'ALIAS: Processing 'strip(rep.c)
  if substr(rep.c,2,8) = 'FCO141M' then do
    say 'ALIAS: A occurance of FCO141M has been found'
    if pos('*ALIAS*',rep.c) > 0 then do
      say 'ALIAS:   A occurance of *ALIAS* has been found'
      alias = strip(substr(rep.c,10,8))

      if action = 'MOVE' then do
        queue '  SELECT MEMBER=(('ALIAS',,R))'
        say 'ALIAS:     As the action is a MOVE'
        say 'ALIAS:     Record   SELECT MEMBER=(('ALIAS',,R)) has beed queued'
        say 'ALIAS: '
      end /* if action = 'MOVE' then do */

      if action = 'DELETE' then do
        queue '  DELETE    MEMBER='ALIAS
        say 'ALIAS:     As the action is a DELETE'
        say 'ALIAS:     Record   DELETE    MEMBER='ALIAS' has beed queued'
        say 'ALIAS: '
      end /* if action = 'DELETE' then do */

    end /* if pos('*ALIAS*',rep.c) > 0 then do */
  end /* if substr(rep.c,2,8) = 'FCO141M' then do */
end /* do c=1 to rep.0 */

if action = 'DELETE' & queued() > 0 then do
  push ' EDITDIR OUTDD=DELOUT'
  say 'ALIAS: '
  say 'ALIAS: Record   EDITDIR OUTDD=DELOUT has beed queued'
  foundrc = 1
end /* if action = 'DELETE' & queued() > 0 then do */

"execio "queued()" diskw copyout (finis)"
cc = rc
  if cc > 0 then do
    say 'ALIAS: execio of COPYOUT ddname gave a return code of 'cc
    exit cc
  end /* if cc > 0 then do */

exit foundrc
