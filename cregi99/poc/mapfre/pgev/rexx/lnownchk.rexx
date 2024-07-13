/*--------------------------REXX----------------------------*/
/* LNOWNCK                                                  */
/* -------                                                  */
/* For Direct Line code in the LN system this checks that a */
/* valid owner comment has been added to the source in the  */
/* format:                                                  */
/*   **###** SOURCE OWNED BY GROUP <OWNER>                  */
/*                                                          */
/*----------------------------------------------------------*/
trace n

arg c1ele c1ty

/* read the source code */
"execio * diskr source (stem source. finis"
if rc > 0 then exit 11

/* find the owner comment line */
do i = 1 to source.0
  x = pos('**###** SOURCE OWNED BY GROUP',source.i)
  if x > 0 then
    exit
end /* i = 1 to 100 while i <= source.0 */

/* If we've reached this point then we didn't find an owner comment */
queue 'LNOWNCK: Owner comment error for element' c1ele 'type' c1ty
queue 'LNOWNCK:'
queue 'LNOWNCK: No owner comment specified or'
queue 'LNOWNCK: owner comment not in correct format. e.g.:'
queue 'LNOWNCK:   **###** SOURCE OWNED BY GROUP <OWNER>'
"execio" queued() "diskw warning (finis"
if rc > 1 then exit 14

exit 36
