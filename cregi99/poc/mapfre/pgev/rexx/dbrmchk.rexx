/*--------------------------REXX----------------------------*\
 *  Check for empty DBRMs.                                  *
 *----------------------------------------------------------*
 *  Author:     Emlyn Williams                              *
 *              Endevor Support                             *
 *----------------------------------------------------------*
 *                                                          *
\*----------------------------------------------------------*/
trace n

parse arg c1prg

chr1 = left(c1prg,1)
if chr1 = 'N' then
  nondb2_prg = 'M'right(c1prg,7)
else
  if pos(chr1,'DQP') > 0 then
    nondb2_prg = 'X'right(c1prg,7)

"execio * diskr DBRMLIB (stem dbrm. finis"
if rc > 0 then exit(9) ;

if dbrm.0 = 0 then do
  queue 'DBRMCHK: The DBRM is empty, this denotes that no SQL statements'
  queue 'DBRMCHK: exist in the source code.'
  queue 'DBRMCHK:'
  queue 'DBRMCHK: If there are no SQL INCLUDE statements in the source code'
  queue 'DBRMCHK: then change the processor group to' nondb2_prg 'i.e. remove'
  queue 'DBRMCHK: the' chr1 'from position 1 of the existing processor group.'
  queue 'DBRMCHK:'
  queue 'DBRMCHK: If there are SQL INCLUDE statements in the source code then'
  queue 'DBRMCHK: consider converting them to COPY statements and'
  queue 'DBRMCHK: changing the processor group to' nondb2_prg
  queue 'DBRMCHK:'
  queue 'DBRMCHK: If the code can not be changed then change the processor'
  queue 'DBRMCHK: group to' left(c1prg,7)'D'
  queue 'DBRMCHK:'
  queue 'DBRMCHK: If the suggested processor group does not exist then call'
  queue '         Endevor Support                      '
  queue 'DBRMCHK: email ¯ (VERTIZOS@kyndryl.com)'
  "execio * diskw README (finis"
  exit 12
end /* if dbrm.0 = 0 */

exit
