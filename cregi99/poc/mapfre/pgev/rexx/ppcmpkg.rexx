/*-----------------------------REXX----------------------------------*\
 * To build ndm cards & delete JCL for Dev MPLEX shipment            *
 *
 * Assumptions:                                                      *
 *  //OAR.. JCL statements are DD statements used to                 *
 *  define the shipment estination                                   *
 *                                                                   *
 *  The DD statement for a staging dataset is the                    *
 *  statement immediately prior to its corresponding                 *
 *  //OAR dd statement.                                              *
\*-------------------------------------------------------------------*/
trace n

parse arg trkid pkgid shortd shortm

say 'PPCMPKG:'
say 'PPCMPKG: 'DATE() TIME()
say 'PPCMPKG: '
say 'PPCMPKG: Tracker id                   : ' trkid
say 'PPCMPKG: package id                   : ' pkgid
say 'PPCMPKG: '
call getmlq

"execio * diskr JCL (stem card. finis" /* Read Cjob                  */
if rc > 0 then exit 13

say 'PPCMPKG: '
say 'PPCMPKG: ' card.0 'Lines of JCL read'

/* Start analyse Cjob                                                */
say 'PPCMPKG:'
Say 'PPCMPKG: +-----------------------------------------------+'
say 'PPCMPKG: ! Scan for staging datasets & delete statements !'
say 'PPCMPKG: +-----------------------------------------------+'

oarcount = 0  /* Count of //OAR.. DD statements                      */
delcount = 0  /* Count of //DEL.. DD statements                      */
deldds   = '' /* List of delete ddnames                              */
rmtdsns  = '' /* List of remote dsns                                 */

queue trkid 'PROCESS SNODE=CD.OS390.M102' /* Start of NDM deck       */

/* Look for OAR DD statements & delete statments                     */
do i = 1 to card.0
  select
    when substr(card.i,1,5) = '//OAR' then
      call buildndm
    when word(card.i,1) = 'EDITDIR' then do
      delcount = delcount + 1
      parse value card.i with word1 'OUTDD=' ddname rest
      deldds = deldds '//'ddname /* Build list of delete DDs         */
    end /* word(card.i,1) = 'EDITDIR' */
    otherwise nop
  end /* select */
end  /* i = 1 to card.0 */

say 'PPCMPKG:'
say 'PPCMPKG:' oarcount 'staging datasets found'
say 'PPCMPKG:'
say 'PPCMPKG:' delcount 'delete statements found'

/* Add NDM copy cards for the DELETE.INFO file                       */
if delcount > 0 then do
  stagedsn = 'PGEV.SHIP.D'shortd'.T'shortm'.DELETE.INFO'
  rmtdsn   = 'PGEV.SHIP.'subsys'.'mlq'.'trkid'.DELETE.INFO'
  rmtdsns  = rmtdsns rmtdsn /* Add delete info to the copy list      */
  queue 'STEP000D COPY FROM (PNODE DISP=SHR -'
  queue '     DSN='stagedsn') -'
  queue '  TO (DISP=RPL DSN='rmtdsn')'
  say 'PPCMPKG:'
  say 'PPCMPKG: Stage DSN  :' stagedsn
  say 'PPCMPKG: Remote DSN :' rmtdsn
end /* delcount > 0 */

/* Add NDM copy cards for the CHANGE.INFO file                       */
stagedsn = 'PGEV.SHIP.D'shortd'.T'shortm'.CHANGE.INFO'
rmtdsn   = 'PGEV.SHIP.'subsys'.'mlq'.'trkid'.CHANGE.INFO'
queue 'STEP000I COPY FROM (PNODE DISP=SHR -'
queue '     DSN='stagedsn') -'
queue '  TO (DISP=RPL DSN='rmtdsn')'
say 'PPCMPKG:'
say 'PPCMPKG: Stage DSN  :' stagedsn
say 'PPCMPKG: Remote DSN :' rmtdsn

"execio * diskw NDMDATA (finis"
if rc ^= 0 then call exception rc 'DISKW to NDMDATA failed.'

/* Build delete JCL                                                  */
if delcount > 0 then
  call builddeljcl

/* Build & write CHANGE.INFO                                         */
do while rmtdsns <> ''
  parse value rmtdsns with rmtdsn rmtdsns
  queue rmtdsn
end /* do while rmtdsns <> ''*/

"execio * diskw INFO (finis"
if rc ^= 0 then call exception rc 'DISKW to INFO failed.'

exit

/*---------------------- S U B R O U T I N E S ----------------------*/

/*-------------------------------------------------------------------*/
/* BUILDNDM - build NDM cards                                        */
/*-------------------------------------------------------------------*/
buildndm:

 oarcount = oarcount + 1

 parse value card.i with word1 'DSN=' hostdsn rest
 x        = i - 1
 parse value card.x with word1 'DSN=' stagedsn rest

 stagedsn = OVERLAY('0',stagedsn,36)
 dsnquals = translate(hostdsn,' ','.')
 qual2    = word(dsnquals,2)
 qual3    = word(dsnquals,3)
 if qual3 = CICS & substr(qual2,2,2) ^= 'RG' then
   qual2 = mlq

 rmtdsn   = 'PGEV.SHIP.'subsys'.'qual2'.'trkid'.'qual3
 rmtdsns  = rmtdsns rmtdsn /* Add to remote dsn list                 */

 queue 'STEP00'oarcount'  COPY FROM (PNODE DISP=SHR -'
 queue '     DSN='stagedsn') -'
 queue '  TO (DISP=RPL DSN='rmtdsn')'
 say 'PPCMPKG:'
 say 'PPCMPKG: Stage DSN  :' stagedsn
 say 'PPCMPKG: Remote DSN :' rmtdsn

return /* buildndm */

/*-------------------------------------------------------------------*/
/* BUILDDELJCL - build delete JCL                                    */
/*-------------------------------------------------------------------*/
builddeljcl:

 queue '//STEP010  EXEC PGM=IEBCOPY'
 queue '//FCOPYON  DD   DUMMY'
 queue '//SYSPRINT DD   SYSOUT=*'
 queue '//SYSUT3   DD   SPACE=(TRK,(5,5))'
 queue '//SYSUT4   DD   SPACE=(TRK,(5,5))'
 do i = 1 to card.0
   select
     when wordpos(word(card.i,1),deldds) > 0 then
       queue card.i                        /* write DD statement */
     when word(card.i,1) = 'EDITDIR' then
       queue card.i                        /* write EDITDIR line */
     when word(card.i,1) = 'DELETE' then
       queue card.i                        /* write DELETE line  */
     otherwise nop
   end /* select  */
 end  /* i = 1 to card.0 */

 "execio * diskw DELJCL (finis"
 if rc ^= 0 then call exception rc 'DISKW to DELJCL failed.'

return /* builddeljcl */

/*-------------------------------------------------------------------*/
/* GETMLQ in package report                                          */
/*-------------------------------------------------------------------*/
getmlq:

 "execio * diskr PKGREP (stem pkgrep. finis"
 if rc ^= 0 then call exception rc 'DISKR of PKGREP failed.'

 do i = 1 to pkgrep.0
   if pos('ENDEVOR RC =',pkgrep.i,2) > 0 then
     subsys = word(pkgrep.i,5)
 end  /* i = 1 to pkgrep.0 */
 stage = substr(pkgid,9,1)
 mlq = stage || subsys
 say 'PPCMPKG: From subsystem =' subsys
 say 'PPCMPKG:      stage     =' stage
 say 'PPCMPKG:'

return /* getmlq */

/*-------------------------------------------------------------------*/
/* Error with line number displayed                                  */
/*-------------------------------------------------------------------*/
exception:
 parse arg return_code comment

 address tso 'delstack' /* Clear down the stack                      */

 parse source . . rexxname . /* Get the rexx name(generic subroutine)*/
 say rexxname':'
 say rexxname':' comment
 say rexxname': Exception called from line' sigl

exit return_code
