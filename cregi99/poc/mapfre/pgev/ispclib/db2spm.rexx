/*--------------------------REXX----------------------------*\
 *  Create DB2 Stored Procedure definitions suite           *
 *  Edit macro to put comments in SP edit screen            *
 *                                                          *
 *----------------------------------------------------------*
 *  Author:     Emlyn Williams                              *
 *              Endevor Support                             *
 *              July 2002                                   *
\*----------------------------------------------------------*/
trace n

isredit macro
"isredit hilite cursor"     /* toggle cursor hilite off */
"isredit recovery on"
"isredit caps off"

queue  "  You may edit the following if you wish but do not change" ,
       "the defaults."
queue  "  When you have finished <pf3> for the next panel"
do i = 1 to queued()
  parse pull data
  "isredit line_before .zfirst = noteline '"data"'"
end

exit
