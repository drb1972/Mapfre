/*-----------------------------REXX----------------------------------*\
 *                                                                   *
 *   This Rexx is used by all Rjobs to set up the shipment           *
 *   datasets and clone Cjob/Bjob JCL for destinations that are      *
 *   defined in the C1SYSTEMC section of the DESTSYS data member.    *
 *                                                                   *
 *   Sample JCL can be found in all Rjobs.                           *
\*-------------------------------------------------------------------*/
signal on syntax  name exception /* Required for ISPF batch only     */
signal on failure name exception /* Required for ISPF batch only     */

trace n

parse arg cmr endevor_id

/*  Read and interpret destinfo table from PGEV.BASE.DATA            */
call readint 'DESTINFO'

/*  Read and interpret destsys table from PGEV.BASE.DATA             */
call readint 'DESTSYS'

/* If DESTSYS has destinations on the C1SYSTEMC card then they must  */
/* be processed                                                      */
clones = words(list_destsc) /* How many clone destinations           */
say 'EVDESTCP: DESTSYS contains' clones 'clone destinations',
    'coded in C1SYSTEMC'
say 'EVDESTCP:' list_destsc
say 'EVDESTCP:'

/*  Process each clone                                               */
do i = 1 to clones

  target = word(list_destsc,i)
  src    = parent.target /* Establish what the parent plex is called */
  ndmin  = 'MODEL'substr(src,5,1) /* Set the NDM  DDname for reading */
  cjobin = 'CJOB'substr(src,5,1)  /* Set the Cjob DDname for reading */
  bjobin = 'BJOB'substr(src,5,1)  /* Set the Bjob DDname for reading */

  say
  say 'EVDESTCP: Processing clone' target 'of' src
  say 'EVDESTCP:'

  /*  Get Cjob input dataset name                                    */
  z = listdsi(cjobin file)

  if z ^= 0000 then do /* if return code is not zero                 */
    say 'EVDESTCP:'
    say 'EVDESTCP:' SYSREASON
    say 'EVDESTCP:' SYSMSGLVL1
    say 'EVDESTCP:' SYSMSGLVL2
    exit z
  end /* z ^= 0000 */

  cjob    = sysdsname /*            whole cjob shipment dataset name */
  cquals  = translate(sysdsname,' ','.') /*        dsn no full stops */
  jobsuff = translate(subword(cquals,1,4),'.',' ') /* 1st 4 quals    */
  dsnguts = translate(subword(cquals,2,3),'.',' ') /*2nd,3rd,4th qual*/

  /* Get Bjob input dataset name                                     */
  z = listdsi(bjobin file)

  if z ^= 0000 then do /* if return code is not zero                 */
    say 'EVDESTCP:'
    say 'EVDESTCP:' SYSREASON
    say 'EVDESTCP:' SYSMSGLVL1
    say 'EVDESTCP:' SYSMSGLVL2
    exit z
  end /* z ^= 0000 */

  bjob   = sysdsname /* whole cjob shipment dataset name             */
  bquals = translate(sysdsname,' ','.') /* dsn no full stops         */

  /*  Read in Cjob JCL from the shipment dataset then                */
  "execio * diskr" cjobin "(finis"
  if rc > 0 then call exception rc 'Read of DDname CJOBIN failed'

  /*  Write out the Cjob JCL to the clone destination dsn            */
  "execio * diskw C"target" (finis"
  if rc > 0 then call exception rc 'Write to DDname C'target 'failed'

  cjobout = jobsuff'.'target'.'word(cquals,6)
  say 'EVDESTCP: JCL        ' cjob
  say 'EVDESTCP: copied to  ' cjobout
  say 'EVDESTCP:'

  /*  Read in Bjob JCL from the shipment dataset then                */
  "execio * diskr" bjobin "(finis"
  if rc > 0 then call exception rc 'Read of DDname BJOBIN failed'

  /*  Write out the Bjob JCL to the clone destination dsn            */
  "execio * diskw B"target" (finis"
  if rc > 0 then call exception rc 'Write to DDname B'target 'failed'

  bjobout = jobsuff'.'target'.'word(bquals,6)
  say 'EVDESTCP: Backout JCL' bjob
  say 'EVDESTCP: copied to  ' bjobout
  say 'EVDESTCP:'

  /*  Read in NDM cards the write out updated source cards           */
  /*  and new target cards.                                          */
  a = listdsi(ndmin file) /*  Get process dataset name               */
  if a ^= 0000 then do /* if return code is not zero                 */
    say 'EVDESTCP:'
    say 'EVDESTCP:' SYSREASON
    say 'EVDESTCP:' SYSMSGLVL1
    say 'EVDESTCP:' SYSMSGLVL2
    exit a
  end /* a ^= 0000 */

  /*  Read model connect direct process statements                   */
  "execio * diskr" ndmin "(stem ndm. finis"
  if rc > 0 then call exception rc 'Read of DDname' ndmin 'failed'

  say 'EVDESTCP:' ndm.0 'records read from NDM member'
  say 'EVDESTCP: 'sysdsname'('src'P)'
  say 'EVDESTCP:'

  /*  Copy NDM cards                                                 */
  say 'EVDESTCP: Creating NDM cards for' target
  say 'EVDESTCP:'

  do m = 1 to ndm.0 /* ndm.0 = total lines in the NDM file           */

    jobpos = pos('JOB)',ndm.m)

    select
      when POS('SNODE=',ndm.m) > 0 then do /* update snode           */
        queue target'P PROCESS SNODE='cd.target
        say 'EVDESTCP: Old' ndm.m
        say 'EVDESTCP: New' target'P PROCESS SNODE='cd.target
        say 'EVDESTCP:'
      end /* POS('SNODE=',ndm.m) > 0 */

      when jobpos > 0 then do /* update job dsn                      */

        prefix = pos('DSN=',ndm.m) + 8
        jobpos = jobpos - 3

        queue left(ndm.m,prefix) || dsnguts'.'target ||,
             substr(ndm.m,jobpos)

        say 'EVDESTCP: Old' ndm.m
        say 'EVDESTCP: New' left(ndm.m,prefix) || dsnguts'.',
             target || substr(ndm.m,jobpos)
      end /* jobpos > 0 */

      otherwise queue ndm.m

     end /* select */

  end /* m = 1 to ndm.0 */

  "execio * diskw " target "(finis"
  if rc > 0 then call exception rc 'Write to DDname' target 'failed'

  say 'EVDESTCP:'
  say 'EVDESTCP: Processing clone' target 'of' src 'complete'

end /* i = 1 to clones */

exit

/*--------------------- S U B R O U T I N E S -----------------------*/

/*-------------------------------------------------------------------*/
/* Read & interpret input data                                       */
/*-------------------------------------------------------------------*/
readint:

 arg ddname

 "execio * diskr" ddname "(stem record. finis"
 if rc > 0 then call exception rc 'Read of DDname' ddname 'failed'

 do i = 1 to record.0
   interpret record.i
 end /* i = 1 record.0 */

 /* Check to see if there are any overrides in DESTSYS               */
 if C1SYSTEMC.endevor_id = "C1SYSTEMC."endevor_id then
   list_destsc = C1SYSTEMC.DEFAULT
 else
   list_destsc = C1SYSTEMC.endevor_id

return

/*-------------------------------------------------------------------*/
/* Error with line number displayed                                  */
/*-------------------------------------------------------------------*/
exception:
 parse arg return_code comment

 /* This if is for ISPF in batch only                                */
 if wordpos(condition('C'),'SYNTAX FAILURE') > 0 then do
   say 'Line' sigl':' left(sourceline(sigl),70)
   say 'Errortext:' errortext(rc)
   return_code = rc
   comment     = condition('C') 'failure at line' sigl                 /
 end /* wordpos(condition('C'),'SYNTAX FAILURE') > 0 */

 parse source . . rexxname . . . . addr .
 say rexxname':'
 say rexxname':' comment'. RC='return_code
 say rexxname': Exception called from line' sigl

 if addr ^= 'MVS' then do
   z = msg(off)
   address tso 'delstack'           /* Clear down the stack          */
   z = msg(on)
 end /* addr ^= 'MVS' */

 if return_code < 0 then return_code = 12 /* - RCs can be invalid    */

 if addr = 'ISPF' then do
   zispfrc = return_code
   address ispexec "vput (zispfrc) shared"
 end /* addr = 'ISPF' */

exit return_code
