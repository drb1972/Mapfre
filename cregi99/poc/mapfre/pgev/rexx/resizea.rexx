/*--------------------------REXX----------------------------*\
 *  Redefine aliases from one dataset to another            *
 *----------------------------------------------------------*
 *  Author:     Emlyn Williams                              *
 *              Endevor Support                             *
\*----------------------------------------------------------*/
trace n
arg odsn ndsn

odsn = strip(odsn,t,',')
say 'RESIZEA: Old Dataset' odsn
say 'RESIZEA: New Dataset' ndsn
say 'RESIZEA:'
idcrc = 0

null = outtrap('lc.')
address tso "LISTCAT ENTRIES('"odsn"') ALL"

do i = 1 to lc.0
  word1 = word(lc.i,1)
  if substr(word1,1,5) = 'ALIAS' then do
    alias = substr(word1,10)
    queue "  DELETE '"alias"' ALIAS"
    queue "  DEFINE ALIAS(NAME("alias") -"
    queue "             RELATE("ndsn"))"
    say 'RESIZEA: Alias' alias ' will be redefined'
  end
end

if queued() > 0 then
  call idcams
else
  say 'RESIZEA: No aliases to redirect'

exit idcrc
/* +--------------------------------------------------------------+ */
/* !  IDCAMS  - Execute IDCAMS commands                           ! */
/* +--------------------------------------------------------------+ */
idcams:
 address tso

 "alloc f(sysin) new space(2 2) cylinders recfm(f b) lrecl(80)"
 "execio "queued()" diskw sysin (finis)"
 "call 'sys1.linklib(idcams)'"
 idcrc = rc
 say 'RESIZEA:'
 say 'RESIZEA: IDCAMS Return code =' idcrc
 say 'RESIZEA: See DDN SYSPRINT for IDCAMS output'

return
