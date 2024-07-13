/*-----------------------------REXX----------------------------------*\
 * Reads Endevor Cjob JCL and checks that the target datasets exist  *
 * and have enough space for the stuff in the staging datasets.      *
 *                                                                   *
 * Sample JCL can be found in PGEV.BASE.REXX(SPACESUB)               *
 *                                                                   *
 * Assumptions:                                                      *
 *  We can predict the target library from the DDNAME:               *
 *  e.g. //DEL                                                       *
 *       //OAR                                                       *
 *       //OCR                                                       *
 * The previous DD name is the associated staging DSN                *
 *                                                                   *
 * Return Code:   0 - everything okay - no email created             *
 *                4 - send email but don't abend (no IM)             *
 *                8 - send email and abend (create IM)               *
 *               12 - send email and abend (create IM)               *
\*-------------------------------------------------------------------*/
parse source . . rexxname .
if sysdsn("'TTEV.TRACE."rexxname"'") = 'OK' then trace i

say rexxname':' DATE() TIME()

call main

call summary

exit maxrc

/*---------------------- S U B R O U T I N E S ----------------------*/

/*-------------------------------------------------------------------*/
/* Loop through the JCL looking for target dd statements             */
/*                                                                   */
/* Save the 'from' and 'to' line numbers of //tgt DD statements      */
/*-------------------------------------------------------------------*/
main:
 maxrc    = 0
 errlines = 0

 "execio * diskr JCL (stem line. finis" /* read the Cjob JCL         */
 if rc ^= 0 then call exception rc 'DISKR of JCL failed'

 jobname = substr(line.1,3,8)
 say rexxname': Jobname:' jobname
 do i = 2 to line.0

   /* Look for jobname                                               */
   if word(line.i,2)  = 'JOB' & ,
      left(line.i,2)  = '//'  & ,
      left(line.i,3) ^= '//*' then iterate

   /* Look for target DD statements                                  */
   target = left(line.i,5)

   if target = '//DEL' then do
     parse value line.i with word1 'DSN=' tgt_dsn rest
     parse value tgt_dsn with tgt_dsn ',' rest
     say rexxname':'
     call getdsinfo "'"tgt_dsn"'"
     say rexxname': DELETE ONLY. NO STAGING DATASET FOR THIS TARGET'
     say rexxname': TGT:' left(tgt_dsn,45)
     iterate
   end /* target = '//DEL' */

   if target = '//OAR' | ,
      target = '//OCR' then do

     say rexxname':'

     /* Find the target dataset name                                 */
     ddlines = line.i                            /* load first line  */
     do dd = i + 1 while left(line.dd,3) = '// ' /* Build DD stmt    */
       ddlines = ddlines || line.dd              /* into one line    */
     end /* do dd = i + 1 while substr(line.dd,1,3) = '// ' */

     parse value ddlines with word1 'DSN=' tgt_dsn rest
     parse value tgt_dsn with tgt_dsn ',' rest

     dsnquals = translate(tgt_dsn,' ','.')
     if word(dsnquals,2) = jobname then do
       say rexxname': TGT:' tgt_dsn
       say rexxname': Looks like a specific, no calculations performed'
       iterate
     end /* word(dsnquals,2) = jobname */

     /* Find the staging dataset that relates to this target         */
     ddlines  = ''                /* Reset the area to save lines    */
     do dd = i - 1 to 1 by -1                 /* Loop backwards      */
       if word(line.x,2) = 'EXEC' then leave  /* to start of step    */
       ddlines = ddlines || line.dd           /* concatenate lines   */
     end /* do dd = i - 1 to 1 by -1 */

     parse value ddlines with word1 'DSN=' stg_dsn rest
     parse value stg_dsn with stg_dsn ',' rest

     call getdsinfo "'"stg_dsn"'"
     stg_dsinfo = dsinfo
     if stg_dsinfo = 'GOOD' then do
       stg_dstype = dstype
       say rexxname': STG:' left(stg_dsn,45) '('stg_dstype')'
       if stg_dstype = 'PDS' then do
         stg_udirblk   = sysudirblk
         stg_blksize   = sysblksize
         stg_blocks    = blocks(sysused)
         stg_bytesused = stg_blocks * stg_blksize
         stg_trksused  = stg_blocks / sysblkstrk
       end /* stg_dstype = 'PDS' */
       else do
         stg_members   = sysmembers
         stg_bytesused = sysusedpages * 4096   /* convert to bytes   */
         stg_trksused  = stg_bytesused / 56664 /* convert to tracks  */
         if sysrecfm = 'U' then tgt_memperdir = 4
                           else tgt_memperdir = 3
         stg_udirblk   = stg_members / tgt_memperdir
       end /* else */
     end /* stg_dsinfo = 'GOOD' */
     else
       say rexxname': STG:' left(stg_dsn,45)

     call getdsinfo "'"tgt_dsn"'"
     if dsinfo     = 'GOOD' & ,
        stg_dsinfo = 'GOOD' then do
       tgt_dstype  = dstype
       tgt_dirinfo = dirinfo
       say rexxname': TGT:' left(tgt_dsn,45) '('tgt_dstype')'
       call calc_alloc

       if tgt_dirinfo = 'TRUE' then
         call calc_dir

       if sysrecfm    = 'U'        & ,
          tgt_dstype ^= stg_dstype then do
         call errline 'Target and staging DSTYPEs do not match'
         call errline left(stg_dsn,45)   '-' stg_dstype
         call errline left(sysdsname,45) '-' tgt_dstype
         call errline ' *LOADMOD footprints will be lost'
         maxrc = 8
       end /* tgt_dstype ^= stg_dstype */

     end /* dsinfo = 'GOOD & stg_dsinfo = 'GOOD' */

   end /* target = '//OAR' | target = '//OCR' */

 end /* do until readrc = 2 */

return /* main: */

/*-------------------------------------------------------------------*/
/* Get dataset info with LISTDSI                                     */
/*-------------------------------------------------------------------*/
Getdsinfo:
 arg listdsn

 dsinfo  = 'GOOD'
 dirinfo = 'TRUE'

 j = listdsi(listdsn "directory" "recall")
 if sysreason          = 2           & ,
    word(SYSMSGLVL2,1) = 'IKJ56225I' then do /* dataset in use       */
   say rexxname':' time() listdsn 'in use, waiting 30 seconds'
   call syscalls('ON')
   address syscall "sleep" 30
   call syscalls('OFF')

   j = listdsi(listdsn "directory" "recall")
   if sysreason          = 2           & ,
      word(sysmsglvl2,1) = 'IKJ56225I' then do /*dataset still in use*/
     dirinfo = 'FALSE'
     say rexxname':' listdsn 'in use,' ,
                     'unable to get directory information'
   end /* sysreason = 2 & word(sysmsglvl2,1) = 'IKJ56225I' */
 end /* sysreason = 2 & word(sysmsglvl2,1) = 'IKJ56225I' */

 if sysreason ^= 0 & ,
    sysreason ^= 2 then do /* dynamic allocation failed              */
   call errline listdsn
   call errline SYSMSGLVL1
   call errline SYSMSGLVL2
   call errline "Reason code" SYSREASON
   /* a sysreason of 5 means "dataset not catalogued"                */
   if sysreason = 5 & maxrc <= 4 then maxrc = 4
                                else maxrc = 8
   dsinfo = 'BAD'
 end /* sysreason ^= 0 & sysreason ^= 2 */
 else
   if sysadirblk = 'NO_LIM' then do
     dstype  = 'PDSE'
     dirinfo = 'FALSE'
   end /* sysadirblk ^= 'NO_LIM' */
   else
     dstype  = 'PDS'

return /* Getdsinfo: */

/*-------------------------------------------------------------------*/
/* Calculate target dataset requirements.                            */
/*-------------------------------------------------------------------*/
calc_alloc:

 /* Calculate the number of spare tracks    in the target dataset    */
 /* and       the number of tracks required in the target dataset    */
 if tgt_dstype = 'PDS' then do
   max_alloc     = sysalloc + (sysseconds * (16 - sysextents))
   tgt_trksused  = tracks(sysused)
   /* This calculation is to allow for non matching block sizes      */
   tgt_trksreq   = stg_bytesused / (sysblksize * sysblkstrk)
 end /* tgt_dstype = 'PDS' */
 else do /* its a PDSE */
   max_alloc     = sysalloc + (sysseconds * (123 - sysextents))
   tgt_trksused  = trunc(sysusedpages * 4096) / 56664 /* conv to trks*/
   tgt_trksreq   = stg_trksused
 end /* else */
 max_alloc     = tracks(max_alloc)
 tgt_trksspare = max_alloc - tgt_trksused
 tgt_trksreq = trunc(tgt_trksreq + 0.999) /* Round up tracks required*/

 say rexxname': Tracks required        :' tgt_trksreq
 say rexxname': Total tracks spare     :' tgt_trksspare

 /* Check target PDS space and volume space                          */
 tgt_trksalloc = tracks(sysalloc)
 tgt_seconds   = tracks(sysseconds)
 call idcams          /* get volume info from DCOLLECT               */

 /* Send error message if there is not enough room                   */
 select
   when tgt_trksreq > tgt_trksspare then do
     /* Not enough room in the PDS                                   */
     call errline sysdsname 'not big enough for' stg_dsn
     call errline sysdsname 'needs' tgt_trksreq 'tracks'
     call errline sysdsname 'only' tgt_trksspare 'available'
     maxrc = 8
   end /* tgt_trksreq > tgt_trksspare */
   when tgt_trksreq > tgt_trksalloc - tgt_trksused then do
     /* We need to extend the PDS                                    */
     if tgt_trksreq > vol_tftrk then do
       /* Tracks required > vol total free space                     */
       call errline sysdsname 'not enough space on volume' sysvolume
       call errline sysdsname 'needs an extra' tgt_trksreq 'tracks'
       call errline sysdsname 'total free space is' vol_tftrk 'tracks'
       maxrc = 8
     end /* tgt_trksreq > vol_tftrk */
     else
       if tgt_seconds > vol_maxext then do
         /* Secondary tracks > largest free extent on volume         */
         call errline sysdsname 'no space for extents on' sysvolume
         call errline sysdsname 'has secondary of' tgt_seconds 'tracks'
         call errline sysdsname 'largest extent available' ,
                                 vol_maxext 'tracks.'
         maxrc = 8
       end /* tgt_seconds > vol_maxext */
   end /* tgt_trksreq > tgt_trksalloc */
   otherwise nop
 end /* select */

return /* calc_alloc: */

/*-------------------------------------------------------------------*/
/* Calculate target dataset directory requirements                   */
/*-------------------------------------------------------------------*/
calc_dir:

 /* Calculate the maximum number of directory blocks possible        */
 /* after the data has been copied.                                  */
 /* N.B. PDSMAN will move members out of the primary into the        */
 /* secondary to create more space in the primary for dir blocks     */
 tgt_pritrks  = tracks(sysprimary)
 tgt_spare    = tgt_trksspare - tgt_trksreq /*Spare tracks after copy*/
 if tgt_spare < 0 then
   tgt_spare = 0

 if tgt_pritrks < tgt_spare then        /* The whole primary can be  */
   tgt_maxdirblk = tgt_pritrks * 45 - 1 /* used for the directory    */
 else
   tgt_maxdirblk = tgt_spare * 45 - 1 +, /* Can only use what we can */
                   sysudirblk            /* move out of the primary  */

 /* Calculate the number of spare directory blocks.                  */
 /* N.B. tgt_maxdirblk is after data is copied                       */
 tgt_dblkspare = tgt_maxdirblk - sysudirblk
 if tgt_dblkspare < 0 then
   tgt_dblkspare = sysadirblk - sysudirblk

 /* PDSMAN now adds another 10% onto the dir requird (FREEDIR%)      */
 /* So if the is not enough room then we must make sure that         */
 /* there is the room for what we need + 10%                         */
 /* and then round the answer (add 0.5 and drop any decimals)        */
 tgt_reqdirblk = trunc(((sysudirblk + stg_udirblk) * 1.10) + 0.5)

 say rexxname': Dir blocks required    :' stg_udirblk
 say rexxname': Dir blocks spare       :' tgt_dblkspare
 say rexxname': Tot Dir blocks required:' tgt_reqdirblk '(+10%)'
 say rexxname': Max dir blocks         :' tgt_maxdirblk

 /* Send error message if there are not enough directory blocks     */
 if stg_udirblk   > tgt_dblkspare & ,
    tgt_reqdirblk > tgt_maxdirblk then do
   call errline sysdsname 'not enough space in directory'
   call errline sysdsname 'needs' tgt_reqdirblk 'dir blocks'
   call errline sysdsname 'only' tgt_maxdirblk 'available'
   maxrc = 8
 end /* stg_udirblk > tgt_dblkspare & tgt_reqdirblk > tgt_maxdirblk */

return /* calc_dir: */

/*-------------------------------------------------------------------*/
/* Calculate the number of tracks                                    */
/*-------------------------------------------------------------------*/
tracks:
 parse arg val

 select  /* Calculate number of tracks required */
   when sysunits = 'CYLINDER' then
     tracks = val * 15
   when sysunits = 'TRACK'    then
     tracks = val
   when sysunits = 'BLOCK'    then
     tracks = val % sysblkstrk
   otherwise do
     call errline 'Unknown SYSUNITS:' sysunits
     maxrc = 12
   end /* unknown sysunits */
 end /* select */

return tracks /* tracks: */

/*-------------------------------------------------------------------*/
/* Calculate the number of blocks                                    */
/*-------------------------------------------------------------------*/
blocks:
 parse arg val

 select  /* Calculate number of blocks used */
   when sysunits = 'CYLINDER' then
     blocks = val * sysblkstrk * 15
   when sysunits = 'TRACK'    then
     blocks = val * sysblkstrk
   when sysunits = 'BLOCK'    then
     blocks = val
   otherwise do
     call errline 'Unknown SYSUNITS:' sysunits
     maxrc = 12
   end /* otherwise */
 end /* select */

return blocks /* blocks: */

/*-------------------------------------------------------------------*/
/* Write error line.                                                 */
/*-------------------------------------------------------------------*/
errline:
 parse arg text
 say rexxname':' text

 /* Print out header info if this is the first error                 */
 if errlines = 0 then do
   sysplex = mvsvar(sysplex)        /* Which plex is this running on */
   /* work out job number                                            */
   ascb  = c2x(storage(224,4))
   assb  = c2x(storage(d2x(x2d(ascb)+336),4))
   jsab  = c2x(storage(d2x(x2d(assb)+168),4))
   jobid = storage(d2x(x2d(jsab)+20),8)
   errlines         = errlines + 1
   errline.errlines = sysplex'  'jobname ' EVL0102D' jobid
   errlines         = errlines + 1
   errline.errlines = '------  --------'
   errlines         = errlines + 1
   errline.errlines = ' '
 end /* errlines = 0 */

 errlines         = errlines + 1
 errline.errlines = text

return /* errline: */

/*-------------------------------------------------------------------*/
/* IDCAMS  - Get volume information (for largest free extent)        */
/*-------------------------------------------------------------------*/
idcams:
 address tso

 test = msg(off)
 "free f(sysin print1 sysprint)"
 test = msg(on)

 "alloc f(sysin) new space(2 2) cylinders recfm(f b) lrecl(80)"
 queue "  DCOLLECT OUTFILE(PRINT1) VOLUMES("sysvolume") NODATAINFO"
 "execio "queued()" diskw sysin (finis)"
  if rc ^= 0 then call exception rc 'DISKW to SYSIN failed'

 "alloc f(print1) new space(2 2) cylinders recfm(v b) lrecl(264)"
 "alloc f(sysprint) new space(2 2) cylinders recfm(f b) lrecl(133)"
 "call 'sys1.linklib(idcams)'"
 if rc ^= 0 then call exception rc 'IDCAMS/DCOLLECT failed'
 "execio * diskr print1 (stem idc. finis"
 if rc ^= 0 then call exception rc 'DISKR of PRINT1 failed'
 "free f(sysin print1 sysprint)"

 hexval     = substr(idc.1,53,4)  /* Get the largest free extent     */
 kb         = c2d(hexval)         /* and convert to trks, cyls etc   */
 vol_maxext = trunc((kb * 1024) / 56664) /* 56664 bytes/track on 3390*/

 dcvcylmg   = substr(idc.1,122,1)
 dcvcylmg   = x2b(c2x(dcvcylmg))
 if left(dcvcylmg,1) = 1 then         /* if flag is 1 then           */
   freefactor = 1024*1024             /*   free space is megabytes   */
 else                                 /* otherwise                   */
   freefactor = 1024                  /*   it is quoted in kilobytes */
 hexval     = substr(idc.1,37,4)
 tfs        = c2d(hexval)              /* Total free space on volume */
 vol_tftrk  = freefactor / 56664 * tfs /* convert into tracks        */

return /* idcams: */

/*-------------------------------------------------------------------*/
/* Write summary.                                                    */
/*-------------------------------------------------------------------*/
summary:

 say rexxname':'
 say rexxname': E R R O R  S U M M A R Y     ' DATE() TIME()
 say rexxname':'

 if errlines > 3 then do
   jobn = MVSVAR('SYMDEF','JOBNAME')
   if left(jobn,2) = 'TT' then jobn = '**TEST**' jobn

   queue 'FROM: mapfre.endevor@rsmpartners.com'
   queue 'TO: VERTIZOS@kyndryl.com'
   queue 'SUBJECT:' jobn '- SPACEMAN ERRORS in' jobname 'on' sysplex

   "execio" queued() "diskw SYSADDR (finis)"
   if rc ^= 0 then call exception rc 'DISKW to SYSADDR failed'

   do e = 1 to errlines
     say errline.e
   end /* 1 to errlines */
   "execio * diskw spacelog (stem errline."
   if rc ^= 0 then call exception rc 'DISKW to SPACELOG failed'
 end /* errlines > 3 */
 else
   say rexxname': NO ERRORS FOUND FOR' jobname

 say rexxname':'
 say rexxname': T H E   E N D'

return /* summary: */

/*-------------------------------------------------------------------*/
/* Error with line number displayed - for IKJEFT non ISPF            */
/*-------------------------------------------------------------------*/
exception:
 parse arg return_code comment

 say rexxname':'
 say rexxname':' comment'. RC='return_code
 say rexxname': Exception called from line' sigl

 z = msg(off)
 address tso "FREE F(sysin print1 sysprint)"
 address tso 'delstack'           /* Clear down the stack            */
 z = msg(on)

 if return_code < 0 then return_code = 12 /* - RCs can be invalid    */

exit return_code
