/*--------------------------REXX-------------------------------------*\
 *  Looks at PDSM17 SMF output                                       *
 *  Filters the output to exclude those not for an Endevor job       *
 *                                                                   *
 *  Run in proc EV#PD1#D                                             *
\*-------------------------------------------------------------------*/
trace n

say 'EVSMFPDS: ' Date() Time()

parse arg plex
say  'EVSMFPDS: Processing plex:' plex

/* read in the exclusions file                                       */
"execio * diskr masks (stem masks. finis"
if rc ^= 0 then call exception rc 'DISKR of MASKS failed.'

say masks.0 'Records read from MASKS'
/* if the exclusions file is empty then exit with rc 35              */
if masks.0 < 1 then call exception 12 'Error masks.0 = 0, should be > 0'

/* write to systsprt the list of excluded datasets                   */
say 'Monitoring the following dataset masks:'

do i = 1 to masks.0
  masks.i = strip(masks.i)
  say masks.i
end /* i = 1 to masks.0 */

/* set up some headings in systsprt                                  */
say left('JOB',8,'-')         , /* job                               */
         '  '                 , /* plex                              */
    left('TARGET DSN',44,'-') , /* targ dsn                          */
    left('DATE',10,'-')       , /* date                              */
    left('TIME',5,'-')        , /* date + 00                         */
    left('MEMBER',8,'-')      , /* member                            */
    left('ACTION',8,'-')        /* change action                     */

/* initialise variables                                              */
detail    = 0
selected  = 0
tdsncount = 0
ndvrcount = 0
noncount  = 0
pkgcount  = 0
acccount  = 0
spacemems = 0
db2recs   = 0

prevfpdsn = ''
dest      = 'PLEX'plex

/* Loop through the PDSMRPT looking for target dd statements         */
lines    = 0                 /* Total lines read                     */
mem      = ''                /* Get on up on the floor               */
do until readrc = 2          /* loop til you just cant loop no more  */
  "execio 1 diskr pdsmrpt"   /* read 1 line                          */
  if rc > 2 then call exception rc 'DISKR of PDSMRPT failed.'
  readrc  = rc               /* return code from execio              */
  lines   = lines   + 1      /* Total lines read                     */
  pull pdsmrep               /* get pdsmrpt line                     */

  select
    when substr(pdsmrep,2,12) = '** PDSM17 **' then
      newtdsn = substr(pdsmrep,56,44)   /* Store target DSN          */

    when substr(pdsmrep,2,6) = 'PDSMAN' then iterate

    when substr(pdsmrep,4,4) = 'DATE'   then iterate

    otherwise do
      /* detail line                                                 */
      prevtdsn = tdsn                    /* Keep previous tdsn       */
      tdsn     = strip(newtdsn)          /* Set tdsn                 */
      prevmem  = mem                     /* Keep previous mem        */
      prevjob  = job                     /* Keep previous mem        */
      prevkey  = prevtdsn || prevmem || prevjob

      if substr(pdsmrep,2,10) ^= '' then do  /* dat not blank        */
        prevdat = dat                        /* keep previous        */
        dat     = substr(pdsmrep,2,10)       /* keep new             */
      end /* substr(pdsmrep,2,10) */

      if substr(pdsmrep,15,5) ^= '' then do  /* tim not blank        */
        prevtim = tim                        /* keep previous        */
        tim     = substr(pdsmrep,14,5)       /* keep new             */
      end /* substr(pdsmrep,15,5) */

      if substr(pdsmrep,22,8) ^= '' then do  /* mem not blank        */
        prevmem = mem                        /* keep previous        */
        mem     = substr(pdsmrep,21,8)       /* keep new             */
        mem     = strip(mem)
      end /* substr(pdsmrep,22,8) */

      if substr(pdsmrep,56,8) ^= '' then do  /* act not blank        */
        prevact = act                        /* keep previous        */
        act     = substr(pdsmrep,56,8)       /* keep new             */
      end /* substr(pdsmrep,56,8) */

      if substr(pdsmrep,67,8) ^= '' then do  /* job not blank        */
        prevjob = job                        /* keep previous        */
        job     = substr(pdsmrep,67,8)       /* keep new             */
      end /* substr(pdsmrep,67,8) */

      if substr(pdsmrep,77,8) ^= '' then do  /* pgm not blank        */
        prevpgm = pgm                        /* keep previous        */
        pgm     = substr(pdsmrep,77,8)       /* keep new             */
      end /* substr(pdsmrep,77,8) */

      key = tdsn || mem || job               /* new key tdsn+mem     */

      if prevmem <> 'NOTFOUND' & ,           /* Ignore first         */
         prevkey <> key        then          /* If key changed       */
        call filter

    end /* otherwise */
  end /* select */
end  /* End of pass through the pdsmrpt */

call filter                                  /* one last time        */

/* Write summary report                                              */
Say 'EVSMFPDS: '
Say 'EVSMFPDS: +---------------+'
Say 'EVSMFPDS: ! End of report !'
Say 'EVSMFPDS: +---------------+'
Say 'EVSMFPDS: 'right(detail,10)    'Filtered'
Say 'EVSMFPDS: 'right(selected,10)  'Recs selected'
Say 'EVSMFPDS: 'right(ndvrcount,10) 'Endevor updates'
Say 'EVSMFPDS: 'right(noncount,10)  'Non Endevor updates'
Say 'EVSMFPDS: '
rejected = acccount + tdsncount + spacemems + pkgcount
Say 'EVSMFPDS: 'right(rejected,10) 'TOTAL rejected'
sum = rejected + selected
Say 'EVSMFPDS: '
Say 'EVSMFPDS: 'right(rejected,10) '+' right(selected,10) '='  ,
                right(sum,10)
Say 'EVSMFPDS: '
Say 'EVSMFPDS: 'right(acccount,10)  'Access records'
Say 'EVSMFPDS: 'right(pkgcount,10)  'Batch Package Updates'
Say 'EVSMFPDS: 'right(spacemems,10) '$$$SPACE and ENCRYPTED members'
Say 'EVSMFPDS: 'right(tdsncount,10) 'Others not selected'
say lines 'lines of pdsmrpt processed'

say 'EVSMFPDS:' db2recs 'written to cmdb2'

exit 0

/*---------------------- S U B R O U T I N E S ----------------------*/

/*-------------------------------------------------------------------*/
/* Filter                                                            */
/*-------------------------------------------------------------------*/
filter:

 detail = detail + 1
 doit   =  'Y'

 select
   when act = 'ACCESSED' then
     acccount  = acccount  + 1

   when mem = '$$$SPACE' then
     spacemems = spacemems + 1

   when pdm = 'ENBP1000' then
     pkgcount  = pkgcount  + 1

   otherwise do
     select
       when substr(job,1,2) = 'C0' then do
         cmr       = 'C' || substr(job,2,7)
         cmract    = 'IMPL'
         ndvrcount = ndvrcount + 1
       end /* C0 */
       when substr(job,1,2) = 'B0' then do
         cmr       = 'C' || substr(job,2,7)
         cmract    = 'BACKOUT'
         ndvrcount = ndvrcount + 1
       end /* B0 */

       when mask(tdsn) > 0 then do
         cmr      = job
         cmract   = 'NON'
         noncount = noncount + 1
       end /* mask(tdsn) */

       otherwise do
         tdsncount = tdsncount + 1
         doit      = 'N' /* should leave here                        */
       end /* otherwise */

     end /* select */

     if doit <> 'N' then do
       selected = selected + 1

       if cmract <> 'NON' then
         xrefdsn = "'PGEV.SHIP."job"."dest".XREF'"
       else
         xrefdsn = 'none'

       if oxrefdsn <> xrefdsn | xrefdsn = 'none' then do
         call xref
         fpele. = ' '
         fpsys. = ' '
         fpsub. = ' '
         fptyp. = ' '
         fpdat. = ' '
         fptim. = ' '
         fpvv.  = ' '
         fpll.  = ' '
         pdat.  = ' '
         ptim.  = ' '
         pver.  = ' '
         pjob.  = ' '
       end /* new xref */

       if strip(fpdsn.tdsn) <> ' ' then
         if sysdsn("'"fpdsn.tdsn"'") = 'OK' & ,
            fpdsn.tdsn <> prevfpdsn then
           call foot

       pdsn      = tdsn

       ussdirnam = ' '                        /* clear out each time */
       ussfilnam = ' '                        /* so no old data left */
       ussmoddat = ' '
       ussmodtim = ' '

       /* If it's a USS type then acquire directory & file name      */
       If right(tdsn,4) = '.USS' then
         call ussname       /* will call write_detail & write_db2    */
       else do
         call write_detail
         call write_db2
       end /* else */

     end /* if doit <> 'N' then do */

   end /* otherwise */

 end /* select */

return /* filter */

/*-------------------------------------------------------------------*/
/* Xref - Get BASE > staging & staging.FP dataset cross reference    */
/*-------------------------------------------------------------------*/
xref:
 oxrefdsn = xrefdsn
 stage. = ' '
 fpdsn. = ' '
 xrefstat = sysdsn(xrefdsn)

 if xrefstat = 'OK' then do

   "alloc fi(xref) da("xrefdsn") shr reus"
   if rc ^= 0 then say 'Alloc of' xrefdsn 'failed. Continuing...'
   "execio * diskr xref (stem xref. finis"  /* read lines            */
   if rc = 0 then do

     /* read the xref file and interpret the content E.g.            */
     /* stage.PGQI.BASE.SQL = PGEV.SHIP.D110225.T120915.PLEXQ1.AH001 */
     /* fpdsn.PGQI.BASE.SQL = PGEV.SHIP.D110225.T120915.PLEXQ1.AH001.FP*/
     do x = 1 to xref.0
       interpret xref.x
     end /* 1 to xref.0 */

   end /* if rc = 0 then do */
   "free fi(xref)"

 end /* if xrefstat = 'OK' then do */

return /* xref */

/*-------------------------------------------------------------------*/
/* Foot - Get element footprint information from the .FP file        */
/*-------------------------------------------------------------------*/
foot:
 prevfpdsn = fpdsn.tdsn

 "alloc fi(foot) da('"fpdsn.tdsn"') shr reus"
 if rc ^= 0 then call exception rc 'ALLOC of' fpdsn.tdsn 'failed.'

 do until footrc = 2          /* loop til you just cant loop no more */
   "execio 1 diskr foot "     /* read 1 line                         */
   if rc > 2 then call exception rc 'DISKR of FOOT failed.'
   footrc = rc                /* return code from execio             */
   pull foot                  /* store pdsmrpt line                  */
   /* E.g                                                            */
   /* PGEV.SHIP.D110225.T141935.PLEXQ1.AH001       C0793981 C0793981   OS */

   fpmem        = strip(substr(foot,46,8))
   fpele.fpmem  = substr(foot,55,10)
   fpsys.fpmem  = substr(foot,66,8)
   fpsub.fpmem  = substr(foot,75,8)
   fptyp.fpmem  = substr(foot,84,8)
   fpdat.fpmem  = substr(foot,93,8)
   fptim.fpmem  = substr(foot,102,5)
   fpvv.fpmem   = substr(foot,108,2)
   fpll.fpmem   = substr(foot,111,2)
   pdat.fpmem   = substr(foot,129,10)
   ptim.fpmem   = substr(foot,140,5)
   pver.fpmem   = substr(foot,146,3)
   pjob.fpmem   = substr(foot,150,8)
 end /* do until footrc = 2 */

 "execio 0 diskr FOOT (finis"
 if rc ^= 0 then call exception rc 'DISKR of FOOT failed.'
 "free fi(foot)"

return /* foot */

/*-------------------------------------------------------------------*/
/* USSname - Routine to get USS directory name and USS file name     */
/*-------------------------------------------------------------------*/
ussname:

 select
   when cmract = 'IMPL'    then
     ussinfo_dsn = "'PGEV.SHIP."job".USSINFO'"
   when cmract = 'BACKOUT' then
     ussinfo_dsn = "'PGEV.SHIP.B"right(job,7)".USSINFO'"
   otherwise
     return
 end /* select */

 ussstat = sysdsn(ussinfo_dsn)
 if ussstat ^= 'OK' then call exception 16 ussinfo_dsn 'not found.'

 "alloc fi(USSINFO) da("ussinfo_dsn") shr reus"
 if rc ^= 0 then call exception rc 'ALLOC of' ussinfo_dsn 'failed.'
 "execio * diskr USSINFO (stem uss. finis"
 if rc ^= 0 then call exception rc 'DISKR of' ussinfo_dsn 'failed.'
 "free fi(USSINFO)"

 /* Loop through the USS info records and write if the memeber name  */
 /* is the same as the short element name                            */
 do ii = 1 to uss.0
   shortname = word(uss.ii,1)
   if shortname = mem then do
     act       = word(uss.ii,2)
     dir_file  = word(uss.ii,3)
     ussmoddat = word(uss.ii,4)
     ussmodtim = word(uss.ii,5)
     /* Acquire directory info - terminated by final slash           */
     lastslash = lastpos('/',dir_file)
     dirlen    = lastslash - 1
     ussdirnam = left(dir_file,dirlen)
     /* Acquire the file name - starts after the final slash         */
     ussfilnam = substr(dir_file,lastslash+1)
     call write_detail
     call write_db2
   end /* shortname = mem */
 end /* ii = 1 to uss.0 */

return /* ussname */

/*-------------------------------------------------------------------*/
/* Mask - Routine to check word against include_masks                */
/*-------------------------------------------------------------------*/
mask:

 result = 0
 do m = 1 to masks.0
   pointer = 0
   remain  = masks.m
   testdsn = tdsn
   /* Percent (%) in the mask allows any character                   */
   do while index(remain,'%') > 0
     percent_index = index(remain,'%')
     remain        = substr(remain,percent_index+1)
     pointer       = pointer + percent_index
     testdsn       = overlay('%',testdsn,pointer)
   end /* while */

   if index(testdsn,masks.m) = 1 then do
     say ,
         left(job,8) ,             /* job                            */
         left(plex,2) ,            /* plex                           */
         left(tdsn,44) ,           /* targ dsn                       */
         left(dat,10) ,            /* date                           */
         left(tim,5) ,             /* date + 00                      */
         left(mem,8) ,             /* member                         */
         left(act,8)               /* change action                  */
     result = m
     leave
   end /* index */
 end  /* do m = 1 to masks.0 */

return result /* mask */

/*-------------------------------------------------------------------*/
/* Write_detail                                                      */
/*-------------------------------------------------------------------*/
write_detail:

 /* change the staging dataset name if it is a backout job           */
 if substr(job,1,2) = 'B0' & substr(stage.tdsn,33,2) = 'AH' then
   stage.tdsn = overlay('CH',stage.tdsn,33,2)

 /* correct HLQ for non Eplex dataset names                          */
 if plex ^= 'E1' & substr(stage.tdsn,1,2) = 'PR' then do
   stage.tdsn = overlay('PG',stage.tdsn,1,2)
   if substr(stage.tdsn,35,1) <> ' ' then
     stage.tdsn = overlay('R',stage.tdsn,35,1)
 end /* if plex ^= 'E1' */

 select
   when act = 'A' then act_full = 'ADDED'   /* For USS files         */
   when act = 'D' then act_full = 'DELETED' /* For USS files         */
   otherwise           act_full = act
 end /* select */

 /* Current JCL declares the output file as 480                      */
 queue left(dat,10)        ,     /* date                   1 -  10   */
       left(tim,5)         ,     /* time                  12 -  16   */
       left(job,8)         ,     /* job                   18 -  25   */
       left(tdsn,44)       ,     /* targ dsn              27 -  70   */
       left(mem,8)         ,     /* member                72 -  79   */
       left(act_full,8)    ,     /* action                81 -  88   */
       left(plex,2)        ,     /* plex                  90 -  91   */
       left(cmract,7)      ,     /* change action         93 -  99   */
       left(cmr,8)         ,     /* change record        101 - 108   */
       left(stage.tdsn,44) ,     /* staging dsn          110 - 153   */
       copies(' ',44)      ,     /* was real dsn         155 - 198   */
       copies(' ',3)       ,     /* was test stream      200 - 202   */
       copies(' ',8)       ,     /* was SSI              204 - 211   */
       left(fpele.mem,10)  ,     /* fp element           213 - 222   */
       left(fpsys.mem,8)   ,     /* fp system            224 - 231   */
       left(fpsub.mem,8)   ,     /* fp subsys            233 - 240   */
       left(fptyp.mem,8)   ,     /* fp type              242 - 249   */
       left(fpdat.mem,8)   ,     /* fp date              251 - 258   */
       left(fptim.mem,5)   ,     /* fp time              260 - 264   */
       left(fpvv.mem,2)    ,     /* fp version           266 - 267   */
       left(fpll.mem,2)    ,     /* fp level             269 - 270   */
       left(pdat.mem,10)   ,     /* pdsman date          272 - 281   */
       left(ptim.mem,5)    ,     /* pdsman time          283 - 287   */
       left(pver.mem,3)    ,     /* pdsman ver           289 - 291   */
       left(pjob.mem,8)    ,     /* pdsman ident         293 - 300   */
       left(pgm,8)         ,     /* Program              302 - 309   */
       left(ussdirnam,80)  ,     /* uss dir name         311 - 390   */
       left(ussfilnam,80)        /* uss file name        392 - 471   */

 parse pull cmdetail                         /* save for use in CMDB2*/
 push cmdetail                               /* then replace in stack*/

 /* write the report to DDname CMDETAIL                              */
 "execio 1 diskw cmdetail"
 if rc ^= 0 then call exception rc 'DISKW to CMDETAIL failed.'

return /* write_detail */

/*-------------------------------------------------------------------*/
/* write_db2                                                         */
/*-------------------------------------------------------------------*/
write_db2:

 if (left(tdsn,6) = 'PGEV.P' & right(tdsn,4) ^= '.USS') | ,
     left(tdsn,9) = 'PGEV.AUTO'                         | ,
     left(tdsn,2) = 'PR'                                then
   return

 /* change pdsman smf date 02/23/2002 to 2001-02-23                  */
 datpart = translate(dat,' ','/')
 db2dat  = word(datpart,3)'-'word(datpart,1)'-'word(datpart,2)
 db2tim  = tim':00'

 /* check footprint time to blank out any ??                         */
 if pos('?',fptim.mem) ^= 0 then
   db2fptim = ' '
 else do
   if fptim.mem <> ' ' then db2fptim = fptim.mem':00'
                       else db2fptim = ' '
 end

 /* check footprint date to blank out any ??                         */
 if pos('?',fpdat.mem) ^= 0 then
   db2fpdat = ' '
 else do
   /* change footprint date 20020223 to 2001-02-23                   */
   if fpdat.mem <> ' ' then
     db2fpdat = substr(fpdat.mem,1,4)'-' || ,
                substr(fpdat.mem,5,2)'-' || ,
                substr(fpdat.mem,7,2)
   else
     db2fpdat = ' '
 end

 /* put dot in vv.ll                                                 */
 if fpvv.mem <> ' ' then dot = '.'
                    else dot = ' '

 /* Current JCL declares the output file as 400                      */
 queue left(job,8)         ,     /* job            001 - 008         */
       left(plex,2)        ,     /* plex           010 - 011         */
       left(tdsn,44)       ,     /* targ dsn       013 - 056         */
       left(db2dat,10)     ,     /* date           058 - 067         */
       left(db2tim,8)      ,     /* date + 00      069 - 076         */
       left(tim,5)         ,     /* time           078 - 082         */
       left(mem,8)         ,     /* member         084 - 091         */
       left(stage.tdsn,44) ,     /* staging dsn    093 - 136         */
       left(act,1)         ,     /* actionb        138 - 138         */
       left(fpsub.mem,8)   ,     /* fp subsys      140 - 147         */
       left(fptyp.mem,8)   ,     /* fp type        149 - 156         */
       left(db2fpdat,10)   ,     /* fp date        158 - 167         */
       left(db2fptim,8)    ,     /* fp time + 00   169 - 176         */
       left(fpvv.mem,2) || ,     /* fp vv.         178 - 180         */
       dot              || ,
       left(fpll.mem,2)    ,     /* fp ll          181 - 182         */
       left(cmr,8)         ,     /* change record  184 - 191         */
       left(cmract,1)      ,     /* change action  193 - 193         */
       left(ussdirnam,80)  ,     /* uss dir name   195 - 274         */
       left(ussfilnam,80)  ,     /* uss file name  276 - 355         */
       ussmoddat           ,     /* uss mod date   357 - 356         */
       ussmodtim                 /* uss mod time   358 - 367         */

 "execio 1 diskw CMDB2"
 if rc ^= 0 then call exception rc 'DISKW to CMDB2 failed.'
 db2recs = db2recs + 1

return /* write_db2 */

/*-------------------------------------------------------------------*/
/* Error with line number displayed                                  */
/*-------------------------------------------------------------------*/
exception:
 parse arg return_code comment

 parse source . . rexxname . . . . addr .
 say rexxname':'
 say rexxname':' comment 'RC='return_code
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
