/* Rexx */
/*
**    NAME        : EVBNDCHK
**    DESCRIPTION : Read off host bind output file, check for existence
**                  of SQL error message, e.g. SQL0092N, supplied in JCL
**    WRITTEN     : 24/10/2007
**    AUTHOR      : Stuart Crowder
**    Notes       : Used by the Off Host Bind QA process DFOBND02
**                : in TTDF.BASE.SKELS
*/
trace n
arg sqlMessage dsn
sqlMessage=strip(sqlMessage,,' ')
dsn=strip(dsn,,' ')
rc = 0
x = SYSDSN(''''||dsn||'''')
if x = 'OK' then
  "ALLOC F(INDD) DA('"||dsn||"') SHR REU"
else
  do
    Say 'Dataset' dsn 'does not exist'
    Exit 8
  end
"execio * diskr INDD (stem inrec. finis"
do i=1 to inrec.0
  if pos(sqlMessage,inrec.i) > 0
  then rc = 8
end/*do i=1 to inrec.0*/
if rc > 0 then
do
  say sqlMessage 'found in input file'
  say ' '
  do i=1 to inrec.0
    say inrec.i
  end
end
else
  say sqlMessage 'not found'
exit rc
