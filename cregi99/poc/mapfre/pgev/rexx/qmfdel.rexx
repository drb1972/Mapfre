/*--------------------------REXX----------------------------*\
 *  Delete QMF data migration files from stage F            *
 *----------------------------------------------------------*
 *  Author:     Emlyn Williams                              *
 *              Endevor Support                             *
 *----------------------------------------------------------*
 *                                                          *
\*----------------------------------------------------------*/
trace n
arg sub element tables

tables = strip(tables,b,"'")
do i = 1 to words(tables)
  table = word(tables,i)
  llq = translate(table,'#','_')
  select
    when length(llq) > 16 then
      llq = left(llq,8) || '.' || substr(llq,9,8) || '.' substr(llq,16)
    when length(llq) > 8 then
      llq = left(llq,8) || '.' || substr(llq,9)
    otherwise nop
  end
  mem = 'PREV.'sub'.'llq'('element')'
  say 'QMFDEL: Deleting' mem
  "DELETE '"mem"'"
end

exit 0
