/* rexx - to look at PDSM17 SMF output                          */
/* Filters the output to report on non Endevor updates          */
/*                                                              */
/* Run daily by job EVCMUPDT                                    */
/*                                                              */
/****************************************************************/
trace n
say 'EVSMFNON: ' DATE() TIME()

exitrc = 0
new    = 0

/* get the list of excluded dsns */
/* this is run from PREV.PEV1.DATA so CMRs are not required */
"execio * diskr exclude (stem excl. finis"
if rc > 0 then exit(30)
say excl.0 'Records read from exclude'
if excl.0 < 1 then exit(35)
say 'Excluding the following datasets:'
do i = 1 to excl.0
  interpret excl.i
  say excl.i
end /* i = 1 to excl.0 */
say

/* get the list of in progress updates */
"execio * diskr inprog (stem inprog. finis"
do i = 1 to inprog.0
  line = inprog.i
  plex = substr(line,16,1)
  dsnmem = word(line,4)
  lb = pos('(',dsnmem)
  len = length(dsnmem)
  mempos = len - lb
  lb = lb - 1
  dsn = left(dsnmem,lb)
  mem = strip(right(dsnmem,mempos),,')')
  job = substr(line,59,8)
  pgm = substr(line,68,8)
  key = plex || dsn || mem || job || pgm
  inprogress.key = 'true'
end

selected  = 0

/*----------------------------------------------------------------*/
/* Loop through the PDSMRPT looking for target dd statements      */
/*----------------------------------------------------------------*/
do forever                     /* until readrc = 2                    */
  "execio 1 diskr pdsmrpt "    /* read one line                       */
  readrc = rc                  /* return code from execio             */
  if readrc > 2 then
    exit readrc                /* I/O error                */
  if readrc = 2 then
    leave                      /* End of file              */
  pull pdsmrep                 /* store pdsmrpt line                  */
  select
    when substr(pdsmrep,2,12) = '** PDSM17 **' then
      dsn = strip(substr(pdsmrep,56,44))
    otherwise do                           /* detail line */
      if left(dsn,2) = 'PR' | ,
         left(dsn,2) = 'TT' | ,
         left(dsn,7) = 'SYSNETV' then
        iterate
      call filter
    end /* otherwise */
  end /* select */
end  /* End of pass through the pdsmrpt */

/* summary report */
say 'Readrc' readrc
Say 'EVSMFNON: '
Say 'EVSMFNON: +---------------+'
Say 'EVSMFNON: ! End of report !'
Say 'EVSMFNON: +---------------+'
Say 'EVSMFNON: 'selected 'Non Endevor updates reported'
Say 'EVSMFNON: 'new      'New Non Endevor updates reported'
Say 'EVSMFNON: '

exit exitrc

/*----------------------------------------------------------------*/
/*  Filter the updates to required DSNs only                      */
/*----------------------------------------------------------------*/
filter:
 plex = substr(pdsmrep,51,1)
 mem = strip(substr(pdsmrep,21,8))
 job = substr(pdsmrep,67,8)
 pgm = substr(pdsmrep,77,8)
 key = plex || dsn || mem || job || pgm
 dsnquals = translate(dsn,' ','.')
 hlq   = word(dsnquals,1)
 mlq   = word(dsnquals,2)
 llq   = word(dsnquals,3)
 nod4  = word(dsnquals,4)
 xlq   = word(dsnquals,5)
 if mlq = 'BASE' & xlq     = ' ' & ,
    wordpos(dsn,excldsn)   = 0 & ,
    wordpos(hlq,exclhlq)   = 0 & ,
    wordpos(llq,exclllq)   = 0 & ,
    wordpos(nod4,exclnod4) = 0 & ,
    wordpos(job,excluid)   = 0 & ,
    left(llq,7) <> 'DOCJOBS' then do
   if plex = 'M' & wordpos(dsn,excldsnm) > 0 then
     return
   selected = selected + 1
   dat = substr(pdsmrep,10,2)'/'substr(pdsmrep,2,2)'/' || ,
         substr(pdsmrep,5,2)
   tim = substr(pdsmrep,14,5)
   dsnmem = left(dsn'('mem')',40)
   access = substr(pdsmrep,56,8)
   desc = substr(pdsmrep,87,30)
   queue dat tim plex dsnmem job pgm access desc
   "execio 1 diskw cmdetail"
   if rc > 0 then do
     say 'ERROR WRITING CMDETAIL' rc
     exit rc
   end
   if inprogress.key ^= 'true' then do   /* not in progress */
     new = new + 1
     exitrc = 1
     queue dat tim plex dsnmem job pgm access desc
     "execio 1 diskw cmnew"
     if rc > 0 then do
       say 'ERROR WRITING CMNEW' rc
       exit rc
     end
   end
 end
return /* filter: */
