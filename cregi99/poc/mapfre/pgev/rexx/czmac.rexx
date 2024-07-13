/*-----------------------------REXX----------------------------------*\
 *  Edit macro for the cast report analyser.                         *
\*-------------------------------------------------------------------*/

isredit macro
"isredit hilite cursor"      /* toggle cursor hilite off             */
"isredit recovery on"
"isredit caps off"
"isredit find 'E ' 8 first"  /* put cursor on first error            */

/* Get ispf edit notes for the headings                              */
"execio * diskr casthdr (finis"
do i = 1 to queued()
  parse pull data
  "isredit line_before .zfirst = noteline '"data"'"
end /* i = 1 to queued() */

/* Get ispf edit notes for the help text                             */
"execio * diskr castmsg (finis"
do i = 1 to queued()
  parse pull data
  "isredit line_before .zlast = noteline '"data"'"
end /* i = 1 to queued() */

exit
