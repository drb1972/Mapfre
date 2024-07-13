/*-----------------------------REXX----------------------------------*\
 *  Execute DB2 BINDs on the Qplex.                                  *
 *  The rexx will perform these steps                                *
 *   1. Free old package versions                                    *
 *   2. Delete rows from the plan table                              *
 *   3. Bind the program                                             *
 *   4. Grant execute on the plan for stored procedures              *
 *  For MULTIBINDs each step wil be run once for all                 *
 *  programs.                                                        *
\*-------------------------------------------------------------------*/
trace n

parse arg  ,
c1su       , /* Endevor Subsystem                                    */
c1ele      , /* Endevor Element                                      */
c1elmnt255 , /* Endevor Long Element Name                            */
c1en       , /* Endevor Environment                                  */
c1ty       , /* Endevor Type                                         */
c1prgrp    , /* Endevor Processor Group                              */
tdypln     , /* Delete from plan table      yes or no                */
tdypkg     , /* Free packages               yes or no                */
bindtyp    , /* Bind or Bindback                                     */
location   , /* Remote location or LOCAL                             */

say 'DB2PROC:  *** TOP OF PARMS ***'
say 'DB2PROC:'
say 'DB2PROC:  C1SU.....'c1su
say 'DB2PROC:  C1ELE....'c1ele
say 'DB2PROC:  C1EN.....'c1en
say 'DB2PROC:  C1TY.....'c1ty
say 'DB2PROC:  C1PRGRP..'c1prgrp
say 'DB2PROC:  TDYPLN...'tdypln
say 'DB2PROC:  TDYPKG...'tdypkg
say 'DB2PROC:  BINDTYP..'bindtyp
say 'DB2PROC:  LOCATION.'location
say 'DB2PROC:'
say 'DB2PROC:  *** END OF PARMS ***'

sysid       = mvsvar(sysname)
c1sy        = left(c1su,2)
lpar        = mvsvar(sysname)
r           = 0  /* summary line counter                             */
s           = 0  /* write report lines                               */
q           = 0  /* sqlout line counter                              */
maxrc       = 0
progs       = '' /* program list (could be a multi bind)             */
dbcols      = '' /* collections for free plan                        */
dbowns      = '' /* owners      for delete from plan table           */
del_count   = 0  /* number of delete from plantable statements       */
bind_count  = 0  /* number of bind statements                        */
grant_count = 0  /* number of grant statements                       */
programs    = 1  /* number of programs to bind                       */

call summary 'DB2PROC: -----' bindtyp 'element' c1elmnt255 ,
            '-' c1en c1su c1prgrp '-----'

if location = 'LOCAL' then locn = ''
                      else locn = location'.'

if pos(substr(c1prgrp,4,1),'CPS') > 0 then do_grant = 1
                                      else do_grant = 0

say 'DB2PROC:'
say 'DB2PROC:' Date() Time() '>>> START' bindtyp 'PROCESSING' ,
           'FOR ELEMENT' c1elmnt255
say 'DB2PROC: Environment' c1en
call initialise /* Switch to ENDEVOR userid                          */

if c1ty = 'BINDMULT' then
  call read_source
else
  progs = c1ele

/*  Process returned lines from DB2PARMS                             */
x = db2parms(c1prgrp c1en c1su c1ty) /* Call db2parms                */
if x ^= 0 then call exception x 'Call to DB2PARMS failed.'

lines = queued()

do i = 1 to lines
  pull data.i
end /* i = 1 to lines */

do i = 1 to lines
  parse value data.i with dbsub dbqual dbown dbcoll dbwlm dbracf ,
                          db2inst desc dbiso dbcur dbdeg dbrel dbreo ,
                          dbval dbkdyn dbdynr dblkn prodown dbenc
  zz = value('prodown.db2inst',prodown)

  if dbsub ^= old_dbsub & i > 1 then do
    dbsub_ok = check_connect() /* Check the db2 subsystem is active  */
    if dbsub_ok then do
      call process         /* Execute all the binds for this dbsub   */
      maxrc       = procrc
    end /* dbsub_ok */
    else do                /* DB2 DSG not active so                  */
      delstack             /* clear down all queued binds            */
      maxrc = 8
    end /* else */
    dbcols      = ''       /* collections for free plan              */
    dbowns      = ''       /* owners      for delete from plan tbl   */
    del_count   = 0        /* number of delete from plantable cmds   */
    bind_count  = 0        /* number of bind statements              */
    grant_count = 0        /* number of grant statements             */
  end /* dbsub ^= old_dbsub & i > 1 */

  do x = 1 to words(progs)   /* Build commands for each program      */
    program = word(progs,x)
    call build_bind_stmts
  end /* x = 1 to words(progs) */

  say 'DB2PROC: RECEIVED PARMS:'
  say 'DB2PROC: DBSUB..........' dbsub
  say 'DB2PROC: DBQUAL.........' dbqual
  say 'DB2PROC: DBOWN..........' dbown
  say 'DB2PROC: DBCOLL.........' dbcoll
  say 'DB2PROC: DBWLM..........' dbwlm
  say 'DB2PROC: DBRACF.........' dbracf
  say 'DB2PROC: PRODOWN........' prodown
  old_dbsub = dbsub
end /* i = 1 to lines */

dbsub_ok = check_connect() /* Check the db2 subsystem is active      */
if dbsub_ok then do
  call process             /* Execute all the commands               */
  maxrc = procrc
end /* dbsub_ok */

call closedown             /* Switch userid back                     */

say ' '
say copies('*',80)
say copies('*',80)
say 'DB2PROC:'
say 'DB2PROC: Environment' c1en
say 'DB2PROC:' Date() Time() '>>> FINITO FOR' c1elmnt255 'USER' ,
           asxbuser 'MAXRC:' maxrc
call write_output

exit 0 /* No maxrc set because DBAs do not want errors to fail the   */
       /* element. Exit rc is set to zero for DB2QPROC               */

/*---------------------- S U B R O U T I N E S ----------------------*/

/*-------------------------------------------------------------------*/
/*  Initialise - Switch to Endevor userid                            */
/*-------------------------------------------------------------------*/
initialise:
 /* Get the userid from storage                                      */
 ascb      = c2x(storage(224,4))
 asxb      = c2x(storage(d2x(x2d(ascb)+108),4))
 acee      = c2x(storage(d2x(x2d(asxb)+200),4))
 asxbuser  =     storage(d2x(x2d(asxb)+192),8)
 /* Switch to alternate userid (ENDEVOR)                             */
 'alloc f(lgnt$$$i) dummy'
 'alloc f(lgnt$$$o) dummy'
 'execio * diskr LGNT$$$I (finis'
 /* Get the userid from storage again (should be ENDEVOR)            */
 asxbuser  =     storage(d2x(x2d(asxb)+192),8)
 /* Say user being used                                              */
 say 'DB2PROC:' asxbuser 'RUNNING ON' sysid
 say 'DB2PROC:'

return /* initialise */

/*-------------------------------------------------------------------*/
/*  Read_source - Read the BIND element source for USS Ear files     */
/*-------------------------------------------------------------------*/
Read_source:

 /* Read the bind element */
 'execio * diskr SOURCE (stem source. finis'
 if rc ^= 0 then call exception rc 'DISKR of SOURCE failed.'

 programs = source.0

 do x = 1 to programs
   program = word(source.x,1)
   if pos(program,progs) = 0 then
     progs = progs program          /* build up the list of programs */
 end /* x = 1 to programs */

return /* Read_source */

/*-------------------------------------------------------------------*/
/*  Build_bind_stmts - Build commands for all programs/instances     */
/*-------------------------------------------------------------------*/
build_bind_stmts:

 /* Set up variables to report package versions to free              */
 if tdypkg = 'Y' & pos(dbcoll,dbcols) = 0 then
   dbcols = dbcols dbcoll

 /* Set up variables to delete form plantable statements             */
 if tdypln = 'Y' then
   if pos(dbown,dbowns) = 0 then
     dbowns = dbowns dbown

 /* Set up BIND commands                                             */
 bind_count = bind_count + 1
 bind.bind_count = 'BIND PACKAGE('locn || dbcoll')' ,
              ' MEMBER('program')' ,
              ' OWNER('dbown')' ,
              ' QUALIFIER('dbqual')' ,
              ' VALIDATE('dbval')' ,
              ' DEGREE('dbdeg')' ,
              ' ISOLATION ('dbiso')' ,
              ' KEEPDYNAMIC('dbkdyn')' ,
              ' CURRENTDATA(NO)' ,
              ' RELEASE('dbrel')' ,
              ' ACTION(REPLACE)' ,
              ' EXPLAIN(YES)' ,
              ' 'dbreo'(VARS)' ,
              ' DBPROTOCOL(DRDA)' ,
              ' DYNAMICRULES('dbdynr')'
 if dbenc = 'UNICODE' then
   bind.bind_count = bind.bind_count ' ENCODING('dbenc')'

 /* Set up GRANT EXECUTE ON PACKAGE statements                       */
 if do_grant then do
   grant_count = grant_count + 1
   grant.grant_count = ,
       "GRANT EXECUTE ON PACKAGE" dbcoll'.'program "TO" dbracf
 end /* do_grant */

return /* build_bind_stmts */

/*-------------------------------------------------------------------*/
/*  Check_connect - Check that the DB2 subsystem is active           */
/*-------------------------------------------------------------------*/
check_connect:

 call summary 'DB2PROC:'
 call summary 'DB2PROC: -- Datasharing group' old_dbsub

 "SUBCOM DSNREXX" /* Is the host cmd env available?                  */
 if rc then       /* No, let's make one                              */
   s_rc = rxsubcom('ADD','DSNREXX','DSNREXX')

 address DSNREXX "CONNECT" old_dbsub /* Connect to the DB2 subsystem */
 say 'DB2PROC: Connect to' old_dbsub 'RC='rc
 say 'DB2PROC:'
 if rc ^= 0 then do
   call summary 'DB2PROC:'
   call summary 'DB2PROC:  This job ran on lpar' lpar ,
                'but DB2 subsystem' old_dbsub
   call summary 'DB2PROC:  was not running on' lpar'.'
   call summary 'DB2PROC:'
   call summary 'DB2PROC:  Please code SCHENV='old_dbsub'BIND on your' ,
                'Endevor job card,'
   call summary 'DB2PROC:  remove any SYSAFF cards that you have,'
   call summary 'DB2PROC:  then reprocess the Endevor action.'
   return 0
 end /* rc ^= */

 address DSNREXX "DISCONNECT"   /* Disconnect from the DB2 subsystem */
 if sqlcode <> 0 then call sqlca

return 1 /* check_connect */

/*-------------------------------------------------------------------*/
/* Sqlca - Display variables on error                                */
/*-------------------------------------------------------------------*/
sqlca:
 say " SQLSTATE =" sqlstate
 say " SQLERRP  =" sqlerrp
 say " SQLERRMC =" sqlerrmc
 say " SQLCODE  =" sqlcode

return /* sqlca */

/*-------------------------------------------------------------------*/
/*  Process                                                          */
/*-------------------------------------------------------------------*/
process:
 tofree   = 0 /* Count of packages to free                           */
 procrc   = 0
 selpkgrc = 0
 freerc   = 0
 planrc   = 0
 bindrc   = 0
 grantrc  = 0

 say 'DB2PROC:' bindtyp 'REQUESTED BY' asxbuser
 call sqlout copies('=',80)
 call sqlout ' '
 call sqlout 'DB2PROC: Process element' c1elmnt255 '('bindtyp')' ,
             old_dbsub c1en c1su
 call sqlout '                        ' copies('~',length(c1elmnt255))

 /*------------------------------------------------------------------*/
 /* STEP#1 Free package versions ?                                   */

 say ' '
 say copies('*',80)
 say copies('*',80)
 say 'DB2PROC:'
 say 'DB2PROC:' Date() Time()
 say 'DB2PROC: STEP#1 SELECT OLD VERSION OF PACKAGES'
 if tdypkg <> 'Y' then
   say 'DB2PROC: BYPASSED BY SYMBOLIC OVERRIDE'
 else do
   if location ^= 'LOCAL' then
     queue " CONNECT TO" location ";"
   queue " SELECT 'FREE PACKAGE ('||RTRIM(A.COLLID)||'.'||"
   queue " RTRIM(A.NAME)||'.('||                          "
   queue " RTRIM(A.VERSION)||'))'                         "
   queue " FROM   SYSIBM.SYSPACKAGE A"
   queue " WHERE  A.COLLID    IN  ("

   /* Build a list of collections                                    */
   call build_collid_freepkg_sql

   queue "   AND  A.NAME      IN  ("
   call build_program_sql

   queue "   AND  A.LOCATION  =   '                '"
   queue "   AND  A.VERSION  LIKE '"c1su"%'"
   queue "   AND  3 < (SELECT COUNT(*) FROM SYSIBM.SYSPACKAGE B"
   queue "            WHERE  A.NAME      =   B.NAME"
   queue "              AND  A.COLLID    =   B.COLLID"
   queue "              AND  A.LOCATION  =   B.LOCATION"
   queue "              AND  B.VERSION  LIKE '"c1su"%'"
   queue "              AND  A.VERSION   <   B.VERSION )"
   queue ""
   commands = 1
   call connect_sql 'SELECT packages to free'
   selpkgrc = dsnrc
   say 'DB2PROC:'
   say 'DB2PROC:' Date() Time()
   /* Loop through lines of report of packages                       */
   do p = 1 to sqlresult.0
     if subword(sqlresult.p,2,2) = 'FREE PACKAGE' then do
       tofree = tofree + 1
       queue subword(sqlresult.p,2,3) /* queue up a free package cmd */
     end /* subword(sqlresult.p,2,2) = 'FREE PACKAGE' */
     if subword(sqlresult.p,1,2) = '0SUCCESSFUL RETRIEVAL' then
       say 'DB2PROC:' substr(sqlresult.p,2,80)
   end /* p = 1 to sqlresult.0 */

   say 'DB2PROC: SELECT PACKAGES TO FREE RC was' selpkgrc

   /* Any package versions to free                                   */
   if tofree > 0 then do
     /*  Free packages get yourself connected                        */
     commands = 1
     call connect_cmd 'FREE packages from plan table'
     freerc = dsnrc
     say 'DB2PROC:'
     say 'DB2PROC: FREE RC was' freerc

   end /* if tofree > 0 */
 end /* tdypkg = y */

 /* End of STEP#1 Free package versions ?                            */
 /*------------------------------------------------------------------*/

 /*------------------------------------------------------------------*/
 /* STEP#2 Delete from plan table                                    */

 say ' '
 say copies('*',80)
 say copies('*',80)
 say 'DB2PROC:'
 say 'DB2PROC:' Date() Time()
 say 'DB2PROC: STEP#2 DELETE FROM PLAN TABLE'
 if tdypln <> 'Y' then
   say 'DB2PROC: NOT EXECUTED DUE TO SYMBOLIC OVERRIDES'
 else do
   /* Set up SQL to delete from plan table                           */
   if location ^= 'LOCAL' then
     queue " CONNECT TO" location ";"
   commands = 0
   do x = 1 to words(dbowns)     /* queue up all the delete commands */
     owner = word(dbowns,x)
     queue "DELETE FROM" owner".PLAN_TABLE"
     queue "WHERE PROGNAME IN ("
     call build_program_sql
     queue "  AND COLLID   IN ("
     call build_collid_delplan_sql
     commands = commands + 1
   end /* x = 1 to words(dbowns) */
   queue ""
   call connect_sql 'DELETE rows from plan table'
   planrc = dsnrc
   do p = 1 to sqlresult.0
     if subword(sqlresult.p,1,2) = 'DELETE FROM' then
       plantab = word(sqlresult.p,3)
     if subword(sqlresult.p,1,2) = 'SUCCESSFUL DELETE' then do
       say 'DB2PROC:'
       say 'DB2PROC:' plantab '-' left(sqlresult.p,80)
     end /* subword(sqlresult.p,1,2) = 'SUCCESSFUL DELETE' */
   end /* p = 1 to sqlresult.0 */
   say 'DB2PROC: DELETE FROM PLAN TABLE RC was 'planrc
 end /* tdypln = y */

 /* End of STEP#2 Delete from plan table                             */
 /*------------------------------------------------------------------*/

 /*------------------------------------------------------------------*/
 /* STEP#3 BIND package                                              */

 say ' '
 say copies('*',80)
 say copies('*',80)
 say 'DB2PROC:'
 say 'DB2PROC:' Date() Time()
 say 'DB2PROC: STEP#3 PACKAGE BIND FOR ELEMENT' c1elmnt255
 say 'DB2PROC: Will bind' programs 'program(s)'
 say '                              '
 say '=======================       '
 say '!   BIND STATEMENT(S) !       '
 say '=======================       '
 say '                              '
 stmt = ''
 do x = 1 to bind_count
   say   bind.x                              /* print the bind stmnt */
   queue bind.x                              /* queue the bind stmnt */
 end /* x = 1 to bind_count */
 say
 call connect_cmd 'BIND'
 bindrc = dsnrc

 say 'DB2PROC:'

 /* End of STEP#3 BIND package                                       */
 /*------------------------------------------------------------------*/

 /*------------------------------------------------------------------*/
 /* STEP#4 Grant execute on package (Stored procedures only)         */

 if do_grant & bindrc <= 4 then do          /* DB2 Stored Procedures */
   say ' '
   say copies('*',80)
   say copies('*',80)
   say 'DB2PROC:'
   say 'DB2PROC:' Date() Time()
   say 'DB2PROC: STEP#4 GRANT EXECUTE ON PACKAGE'
   queue "SET CURRENT SQLID = 'ENDEVOR';"
   commands = 0
   do x = 1 to grant_count
     queue grant.x
     commands = commands + 1
   end /* x = 1 to grant_count */
   queue ""
   call connect_sql 'GRANT'      /*  process  DB2 statements         */
   grantrc = dsnrc
   say 'DB2PROC:'
   say 'DB2PROC: GRANT PACK RC was' grantrc
 end /* do_grant & bindrc <= 4 */

 /* End of STEP#4 Grant execute on package (Stored procedures only)  */
 /*------------------------------------------------------------------*/

 if selpkgrc > procrc then procrc = selpkgrc
 if freerc   > procrc then procrc = freerc
 if planrc   > procrc then procrc = planrc
 if bindrc   > procrc then procrc = bindrc
 if grantrc  > 4 & grantrc > procrc then procrc = grantrc

return /* process */

/*-------------------------------------------------------------------*/
/*  Build_collid_freepkg_sql for use in free package statements      */
/*-------------------------------------------------------------------*/
build_collid_freepkg_sql:
 /* This will build a list of collections like this                  */
 /* 'CNEKD1','CREKD1') ;                                             */
 temp = ''
 do zz = 1 to words(dbcols)
   temp = temp"'"word(dbcols,zz)"',"
   if length(temp) > 60 & zz < words(dbcols) then do
     queue temp
     temp = ''
   end /* length(temp) > 60 & zz < words(dbcols) */
 end /* zz = 1 to words(dbcols) */
 if length(temp) ^= 0 then
   queue strip(temp,t,',') || ')'

return /* build_collid_freepkg_sql */

/*-------------------------------------------------------------------*/
/*  Build_program_sql for use in select where statements             */
/*-------------------------------------------------------------------*/
build_program_sql:
 /* This will build a list of programs like this                     */
 /* 'EMLYN','GAV1','DAXXXBXX')                                       */

 temp = ''
 do zz = 1 to words(progs)
   temp = temp"'"word(progs,zz)"',"
   if length(temp) > 60 & zz < words(progs) then do
     queue temp
     temp = ''
   end /* length(temp) > 60 & zz < words(progs) */
 end /* zz = 1 to words(progs) */
 if length(temp) ^= 0 then
   queue strip(temp,t,',') || ')'

return /* build_program_sql */

/*-------------------------------------------------------------------*/
/*  Build_collid_delplan_sql for use in delete plan statements       */
/*-------------------------------------------------------------------*/
build_collid_delplan_sql:
 /* This will build a list of collections like this                  */
 /* 'CNEKD1') ;                                                      */
 /* In reality it would only be one collection per prodown.          */
 temp = ''
 if substr(c1prgrp,5,1) ^= 'X' then
   owner_sys = substr(owner,2,2)
 else
   owner_sys = substr(owner,3,2)
 do zz = 1 to words(dbcols)   /* Loop through all the collections    */
   coll = word(dbcols,zz)
   /* Match up the collection to the owner                           */
   if left(owner,1) || owner_sys || right(owner,2) = ,
      right(coll,5) then do
     temp = temp"'"coll"',"
     if length(temp) > 60 & zz < words(dbcols) then do
       queue temp
       temp = ''
     end /* length(temp) > 60 & zz < words(dbcols) */
   end /* left(owner,1) || right(owner,4) = right(dbqual,5) */
 end /* zz = 1 to words(dbcols) */
 if length(temp) ^= 0 then
   queue strip(temp,t,',') || ') ;'

return /* build_collid_delplan_sql */

/*-------------------------------------------------------------------*/
/*  Connect_sql - Process queued DB2 statements                      */
/*-------------------------------------------------------------------*/
Connect_sql:
 parse arg comtyp

 worked = 0               /* number of successful statements         */

 /*  Allocate files for dsntep2 to run sql                           */
 "alloc fi(SYSIN) new unit(vio) lrecl(80) recfm(f b)",
        " space(15,90) tracks"
 "execio * diskw SYSIN (finis"
 if rc ^= 0 then call exception rc 'DISKW to SYSIN failed.'
 queue "run program(dsntep2) plan(dsntep2)
        library('sysdb2."old_dbsub".runlib.load')"
 "alloc fi(SYSPRINT) new unit(vio) lrecl(133) recfm(f b a)",
        "blksize(3591) space(15,90) tracks reuse"

 queue 'END'
 'DSN SYSTEM('old_dbsub')'         /*  Connect to DB2                */
 dsnrc = rc
 delstack
 /*  Get the full output from SYSPRINT which is &ZOUT                */
 'execio * diskr SYSPRINT(stem sqlresult. finis'
 if rc ^= 0 then call exception rc 'DISKR of SYSPRINT failed.'

 do p = 1 to sqlresult.0
   say substr(sqlresult.p,1,131)
 end /* p = 1 to sqlresult.0 */

 sq = 0
 do p = 1 to sqlresult.0
   if word(sqlresult.p,2) = 'SQLCODE' & ,
      left(word(sqlresult.p,4),1) = '-' then do
     sq = sq + 1
     sqlcode.sq = subword(sqlresult.p,4)
   end /* word(sqlresult.p,2) = 'SQLCODE' */
 end /* p = 1 to sqlresult.0 */

 if dsnrc <> 0 then do
   if dsnrc = 4 & comtyp = 'GRANT' then  /* no errmsg for grant rc=4 */
     nop
   else do
     say 'DB2PROC:'
     if dsnrc > 4 then
       say 'DB2PROC: An error has occured'
     else
       say 'DB2PROC: Warning(s) issued'
   end /* else */
   call summary 'DB2PROC: ' comtyp
   if sq > 0 then
     do zz = 1 to sq
       call summary 'DB2PROC:  ' sqlcode.zz
     end /* zz = 1 to sq */
   worked = commands - sq
   call summary 'DB2PROC:  ' worked 'out of' commands ,
               'actions completed successfully'
 end /* dsnrc <> 0 */

 "free fi(SYSIN SYSPRINT)" /* Free files                             */

return /* Connect_sql */

/*-------------------------------------------------------------------*/
/*  Connect_cmd - Process queued FREE or BIND commands               */
/*-------------------------------------------------------------------*/
Connect_cmd:
 parse arg comtyp
 worked = 0               /* number of successful commands           */

 queue 'END'
 null = outtrap('cmd_out.')
 'DSN SYSTEM('old_dbsub')'              /*  Connect to DB2           */
 null = outtrap('off')
 dsnrc = rc

 do p = 1 to cmd_out.0
   say substr(cmd_out.p,1,131)
 end /* p = 1 to cmd_out.0 */

 if word(comtyp,1) = 'BIND' then do
   call summary 'DB2PROC: ' comtyp
   /*  Write out the filtered output to SQLOUT for developers        */
   call sqlout 'DB2PROC: ---- BIND output ----'
   do x = 1 to bind_count            /* First write the bind stmt(s) */
     bind_stmt = ''
     do yy = 1 to words(bind.x)
       bind_stmt = bind_stmt word(bind.x,yy)
       if length(bind_stmt) > 80 then do
         bind_stmt = substr(bind_stmt,1,lastpos(' ',bind_stmt))
         call sqlout bind_stmt
         bind_stmt = '  'word(bind.x,yy)
       end /* length(bind_stmt) > 80 */
     end /* yy = 1 to words(bind.x) */
   end /* x = 1 to bind_count */
   call sqlout ' '

   reason  = ''
   sqlcode = ''
   token   = ''
   mem_msg = ''
   do a = 1 to cmd_out.0
     if word(cmd_out.p,1) = '1PAGE' then iterate
     call sqlout '  'left(cmd_out.a,130)

     select /* find the information needed to write the report */
       when pos('PACKAGE =',cmd_out.a) > 0 | ,
            pos('PACKAGE=',cmd_out.a)  > 0 then
         parse var cmd_out.a pack '=' start '.' coll '.' pkge '.' rest

       when pos('DBRM=',cmd_out.a) > 0 then
         parse value word(cmd_out.a,1) with 'DBRM=' pkge

       when pos('SQLCODE=',cmd_out.a) > 0 then
         sqlcode = right(cmd_out.a,4)

       when pos('REASON ',cmd_out.a) > 0 then
         reason = right(cmd_out.a,8)

       when pos('TOKENS=',cmd_out.a) > 0 then
         parse var cmd_out.a part1 '=' token

       when word(cmd_out.a,1) = 'MEMBER' then
         mem_msg = subword(cmd_out.a,1)

       when pos('SUCCESSFUL BIND',cmd_out.a) > 0 then do
         next = a + 1
         if pos('PACKAGE =',cmd_out.next) > 0 | ,
            pos('PACKAGE=',cmd_out.next)  > 0 then
           parse var cmd_out.next pack '=' start '.' coll '.' pkge '.'rest

         inst = substr(coll,2,1)
         pown = prodown.inst
         if pos(' UNSUCCESSFUL BIND',cmd_out.a) > 0 then do
           call summary 'DB2PROC:  *BIND failed for' ,
                       coll'.'pkge' - Instance =' pown
           call summary 'DB2PROC:   ' space(sqlcode token reason mem_msg)
         end /* else */
         else do
           call summary 'DB2PROC:   BIND worked for' ,
                       coll'.'pkge' - Instance =' pown
           worked = worked + 1
         end /* else */
         reason  = ''
         sqlcode = ''
         token   = ''
         mem_msg = ''
       end /* pos('SUCCESSFUL BIND',cmd_out.a) > 0 */

       otherwise nop
     end /* end select */
   end /* end do a = 1 to cmd_out.0 */

   call summary 'DB2PROC:  ' worked 'out of' bind_count ,
               'BINDs completed successfully'
   call sqlout ' '
 end /* comtyp = 'BIND' */

 else
   if dsnrc > 0 then do
     call summary 'DB2PROC: ' comtyp
     call summary 'DB2PROC:   Return code' dsnrc
   end /* dsnrc > 0 */

return /* Connect_cmd */

/*-------------------------------------------------------------------*/
/*  Summary - Adds a line to an array called summary                 */
/*-------------------------------------------------------------------*/
summary:
 parse arg text
 r = r + 1
 summary.r = text

return /* summary */

/*-------------------------------------------------------------------*/
/*  Sqlout - adds a line to an array called sqlout                   */
/*-------------------------------------------------------------------*/
sqlout:
 parse arg text
 q = q + 1
 sqlout.q = text

return /* sqlout */

/*-------------------------------------------------------------------*/
/*  Closedown - Switch back from Endevor userid                      */
/*-------------------------------------------------------------------*/
closedown:
 'execio * diskr LGNT$$$O (finis'
 'free f(LGNT$$$I)'
 'free f(LGNT$$$O)'
 asxbuser = storage(d2x(x2d(asxb)+192),8)

return /* closedown */

/*-------------------------------------------------------------------*/
/*  Write_output - Write out all the output                          */
/*-------------------------------------------------------------------*/
write_output:
 call summary ' '
 'execio' r 'diskw SUMMARY (stem summary.'
 if rc ^= 0 then call exception rc 'DISKW to SUMMARY failed.'

 'execio' q 'diskw SQLOUT (stem sqlout.'
 if rc ^= 0 then call exception rc 'DISKW to SQLOUT failed.'

return /* write_output */

/*-------------------------------------------------------------------*/
/* Error with line number displayed                                  */
/*-------------------------------------------------------------------*/
exception:

 call closedown
 call write_output

 delstack /* Clear down the stack                                    */

 parse source . . rexxname . /* Get the rexx name(generic subroutine)*/
 say rexxname':'
 say rexxname':' comment
 say rexxname': Exception called from line' sigl

