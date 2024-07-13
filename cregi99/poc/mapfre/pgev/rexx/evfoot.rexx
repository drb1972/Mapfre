/*-----------------------------REXX----------------------------------*\
 *  Gets PDSMAN stats & Endevor footprint information                *
 *  then builds records for input to the change database             *
 *-------------------------------------------------------------------*
 *  Executed by : JOB EVFT%1% which is built by EVAUDIT              *
\*-------------------------------------------------------------------*/
  trace n

  arg dsn                      /* staging dataset name               */

  say 'EVFOOT:' Date() Time()
  say 'EVFOOT: Staging DSN...:' dsn

  fplines = 0                  /* position in output                 */
  count   = 0

  /* Get pdsman stats                                                */
  pdsn = "'"strip(dsn,'B')"'"
  address tso
  a = outtrap('pdsmstat.','*')
  queue "audit"
  queue "end"
  "pdsman" pdsn
  pdsrc = rc
  a = outtrap('off')
  say
  say 'EVFOOT: PDSMAN Stats...'
  say
  do i = 6 to pdsmstat.0-1
    if substr(pdsmstat.i,16,10) = 'No Control' | ,
       substr(pdsmstat.i,1,8)   = ' ' then iterate
    else do
      pmem = strip(substr(pdsmstat.i,1,8),'B')
      mem.i = pmem
      pdat.pmem = substr(pdsmstat.i,16,10)
      ptim.pmem = substr(pdsmstat.i,28,5)
      pver.pmem = substr(pdsmstat.i,36,3)
      pjob.pmem = substr(pdsmstat.i,42,8)
      say      left(pmem,8) ,
               pdat.pmem ,
               ptim.pmem ,
               pver.pmem,
               pjob.pmem
    end /* control */
  end /* do i = 3 to pdsattr.0-1 */

  say
  say 'EVFOOT: Building records...'
  say
  do until readrc = 2          /* start looping                      */

    "execio 1 diskr bstpch "   /* read 1 line                        */
    readrc = rc                /* return code from execio            */
    parse pull bstpch          /* store bc1foot line no upper        */

    if readrc > 2 then call exception readrc 'DISKR from BSTPCH failed.'
    if readrc = 2 then leave

    fplines = fplines + 1      /* Total fplines read                 */

    csect = substr(bstpch,97,8)
    mem   = substr(bstpch,72,10)
    fpsys = substr(bstpch,137,8)
    fpsub = substr(bstpch,145,8)
    fpele = substr(bstpch,153,10)
    fptyp = substr(bstpch,163,8)
    fpvv  = substr(bstpch,180,2)
    fpll  = substr(bstpch,182,2)
    ssi   = '        '
    dat   = substr(bstpch,184,3)
    fptim = substr(bstpch,187,5)

    if fpsys = ' ' then fpsys = '????????'
    if fpsub = ' ' then fpsub = '????????'
    if fpele = ' ' then fpele = '??????????'
    if fptyp = ' ' then fptyp = '????????'
    if fpvv  = ' ' then fpvv  = '??'
    if fpll  = ' ' then fpll  = '??'
    if fptim = ' ' then fptim = '?????'
    if dat   = ' ' then fpdat = '????????'
    else do
      datj = p2d(dat)
      fpdat =  DATE('S',datj,'J')
    end /* dat */

    call write_line

    mem = strip(mem)
    done.mem = 'Y' /* set the done flag for this member              */

  end  /* do until readrc = 2 */

  /* Loop through the PDSMAN report to list members that are not     */
  /* footprinted. E.g. load modules with no *LOADMOD footprints      */
  fpsys = '????????'
  fpsub = '????????'
  fpele = '??????????'
  fptyp = '????????'
  fpvv  = '??'
  fpll  = '??'
  ssi   = '        '
  fptim = '?????'
  fpdat = '????????'
  do i = 6 to pdsmstat.0-1
    mem = mem.i
    if done.mem ^= 'Y'     & ,
       mem.i    ^= 'MEM.'i then
      call write_line
  end /* do i = 3 to pdsattr.0-1 */

  "EXECIO 0 DISKW FOOTREP (FINIS"
  if rc ^= 0 then call exception rc 'DISKW to FOOTREP failed.'

  Say
  say 'EVFOOT:' count   'members processed from' dsn
  say 'EVFOOT:' fplines 'lines of BSTPCH processed'

exit 0

/*---------------------- S U B R O U T I N E S ----------------------*/

/*-------------------------------------------------------------------*/
/* Convert footprint date                                            */
/*-------------------------------------------------------------------*/
p2d: procedure
 parse arg p
 num = c2x(p)
 d = substr(num,1,length(num)-1)
 if substr(num,length(num),1) = 'D' then
 d= '-' unpack
 return d

/*-------------------------------------------------------------------*/
/* Write a line of output                                            */
/*-------------------------------------------------------------------*/
write_line:
 count = count + 1
 pmem = strip(mem,'B')
 push ,
 left(dsn,44) ,
 left(mem,8) ,
 left(fpele,10) ,
 left(fpsys,8) ,
 left(fpsub,8) ,
 left(fptyp,8) ,
 left(fpdat,8) ,
 left(fptim,5) ,
 left(fpvv,2) ,
 left(fpll,8) ,
 left(ssi,8) ,
 left(pdat.pmem,10) ,
 left(ptim.pmem,5) ,
 left(pver.pmem,3) ,
 left(pjob.pmem,8)
 say ,
 left(mem,8) ,
 left(fpele,10) ,
 left(fpsys,8) ,
 left(fpsub,8) ,
 left(fptyp,8) ,
 left(fpdat,8) ,
 left(fptim,5) ,
 left(fpvv,2) ,
 left(fpll,8) ,
 left(ssi,8) ,
 left(pdat.pmem,10) ,
 left(ptim.pmem,5) ,
 left(pver.pmem,3) ,
 left(pjob.pmem,8)
 "EXECIO 1 DISKW FOOTREP"
 if rc ^= 0 then call exception rc 'DISKW to FOOTREP failed.'

return

/* +---------------------------------------------------------------+ */
/* | Error with line number displayed                              | */
/* +---------------------------------------------------------------+ */
exception:
 parse arg return_code comment

 delstack /* Clear down the stack                                    */

 parse source . . rexxname . /*Get the rexx name (generic subroutine)*/
 say rexxname':'
 say rexxname':' comment
 say rexxname': Exception called from line' sigl

exit return_code
