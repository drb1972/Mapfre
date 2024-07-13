/*-----------------------------REXX----------------------------------*\
 *  Create DB2 Stored Procedure definitions                          *
\*-------------------------------------------------------------------*/
trace n

parse arg ,
c1en        /* Endevor Environment                      */ ,
c1ele       /* Endevor Element name                     */ ,
c1prgrp     /* Endevor Processor Group                  */ ,
c1su        /* Endevor Subsystem                        */ ,
c1ty        /* Endevor Type                             */ ,
server      /* Offhost Server Name                      */ ,
drive       /* Offhost Server Drive Letter              */

c1en        = 'PROD'
source.0    = 0
count       = 0
write_count = 0

clen    = strip(c1en)
c1ele   = strip(c1ele)
c1prgrp = strip(c1prgrp)
c1su    = strip(c1su)
c1ty    = strip(c1ty)
server  = strip(server)
drive   = strip(drive)

say 'DB2BUILD:  *** TOP OF PARMS ***'
say 'DB2BUILD:'
say 'DB2BUILD:  C1EN.....'c1en
say 'DB2BUILD:  C1ELE....'c1ele
say 'DB2BUILD:  C1PRGRP..'c1prgrp
say 'DB2BUILD:  C1SU.....'c1su
say 'DB2BUILD:  C1TY.....'c1ty
say 'DB2BUILD:  SERVER...'server
say 'DB2BUILD:  DRIVE....'drive
say 'DB2BUILD:'
say 'DB2BUILD:  *** END OF PARMS ***'

if c1ty = 'BINDMULT' then do /* Read the bind element                */
  'execio * diskr SOURCE (stem source. finis'
  if rc ^= 0 then call exception rc 'DISKR of SOURCE failed.'
end /* c1ty = 'BINDMULT'                                             */

/* Call db2parms                                                     */
x = db2parms(c1prgrp c1en c1su c1ty)
if x ^= 0 then call exception x 'Call to DB2PARMS failed.'

lines = queued()

do ii = 1 to lines
  pull data.ii
end /* ii = 1 to lines                                               */

/*  Process returned lines from DB2PARMS                             */
do ii = 1 to lines
  parse value data.ii with dbsub dbqual dbown dbcoll dbwlm dbracf ,
                          db2inst desc dbiso dbcur dbdeg dbrel dbreo ,
                          dbval dbkdyn dbdynr dbblkn prodown dbenc
  if dbsub ^= old_dbsub & ii > 1 then do
    call write old_dbsub
    if c1ty = 'BINDOH' then leave /* No multi DSG for BINDOH         */
  end /* dbsub ^= old_dbsub & ii > 1                                 */

  if source.0 > 0 then /* USS/Ear file processing                    */
    do i = 1 to source.0
      c1ele = word(source.i,1)
      call process
    end /* i = 1 to source.0                                         */
  else
    call process /* Normal processing                                */

  old_dbsub = dbsub

end /* ii = 1 to lines                                               */

call write dbsub

exit

/*---------------------- S U B R O U T I N E S ----------------------*/

/*-------------------------------------------------------------------*/
/*  Process                                                          */
/*-------------------------------------------------------------------*/
process:

say 'DB2SPCRP: Building statements for datasharing group' ,
    dbsub 'owner' dbown

if c1ty ^= 'BINDOH' then do
  call build_line '   BIND PACKAGE('dbcoll')             -'
  call build_line '        MEMBER('c1ele')               -'
  call build_line '        OWNER('dbown')                -'
  call build_line '        QUALIFIER('dbqual')           -'
  call build_line '        VALIDATE('dbval')             -'
  call build_line '        DEGREE('dbdeg')               -'
  call build_line '        ISOLATION('dbiso')            -'
  call build_line '        CURRENTDATA(NO)               -'
  call build_line '        KEEPDYNAMIC('dbkdyn')         -'
  call build_line '        DYNAMICRULES('dbdynr')        -'
  call build_line '        RELEASE('dbrel')              -'
  if dbenc = 'UNICODE' then
    call build_line '        ENCODING('dbenc')           -'
  call build_line '        ACTION(REPLACE)               -'
  call build_line '        EXPLAIN(YES)                  -'
  call build_line '        'dbreo'(VARS)                  '
end /* c1ty ^= 'BINDOH'                                              */

if c1ty = 'BINDOH' then do
  /* DB2REO currently not used, amend below when required            */
  if db2reo= 'NOREOPT' then db2reo = ''
                       else db2reo = 'REOPT VARS'

  /*  Only code ENCODING if it's UNICODE                             */
  if dbenc = 'UNICODE' then encoding = 'ENCODING' dbenc
                       else encoding = ''

  bind_statement = 'BIND',
  Drive':\DBRMLIB\'c1ele'.BND',
   'ACTION REPLACE COLLECTION' dbcoll,
   'ISOLATION' dbiso,
   'OWNER' dbown,
   'QUALIFIER' dbqual,
   'EXPLAIN YES',
   'VALIDATE' dbval,
   'DEGREE' dbdeg,
   'KEEPDYNAMIC' dbkdyn,
   'RELEASE' dbrel,
   encoding,
   'DYNAMICRULES' dbdynr,
   'BLOCKING' dbblkn,
   'MESSAGES' drive||,
   ':\BINDS\OUTPUT\'c1ele'_'dbown'.TXT;'
  call build_line bind_statement
end /* c1ty = 'BINDOH'                                               */

return /* process                                                    */

/*-------------------------------------------------------------------*/
/* Build_line - Build each line of the statement                     */
/*-------------------------------------------------------------------*/
build_line:
 arg line

 /* Put the hyphen in column 30 for readability                      */
 if right(line,2) = ' -' then do
   line     = strip(line,t,'-')
   line     = strip(line,t)
   line_len = length(line)
   if line_len < 29 then
     line = line || copies(' ',29-line_len)'-'
   else
     line = line '-'
 end /* right(line,2) = ' -'                                         */

 count = count + 1
 out.count = line

return /* build_line                                                 */

/*-------------------------------------------------------------------*/
/*  Write                                                            */
/*-------------------------------------------------------------------*/
write:
 parse arg curr_dbsub

 if c1ty = 'BINDOH' then
   bindfile = 'BINDOH'
 else
   if write_count = 0 then
     bindfile = 'BIND@1'
   else
     bindfile = 'BIND'curr_dbsub

 x = listdsi(bindfile file)
 if x > 4 then call exception x 'LISTDSI of' bindfile 'failed.'
 say 'DB2BUILD: Writing BIND statements to' sysdsname
 say 'DB2BUILD:'
 'execio' count 'diskw' bindfile '(stem out. finis'
 if rc ^= 0 then call exception rc 'DISKW to' bindfile 'failed.'

 write_count = write_count + 1

return /* write                                                      */

/*-------------------------------------------------------------------*/
/* Error with line number displayed                                  */
/*-------------------------------------------------------------------*/
exception:
 parse arg return_code comment

 delstack /* Clear down the stack                                    */

 parse source . . rexxname . /* Get the rexx name(generic subroutine)*/
 say rexxname':'
 say rexxname':' comment
 say rexxname': Exception called from line' sigl

exit return_code
