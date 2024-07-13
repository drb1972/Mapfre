/*-----------------------------REXX----------------------------------*\
 *  Resize dataset utility                                           *
 *                                                                   *
 *  checks volume info & dataset enq info                            *
 *  creates job to                                                   *
 *    rename old dataset to suffix specified                         *
 *    copy from old dataset to .NEW                                  *
 *    rename .NEW back                                               *
 *   or compress datasets                                            *
 *  Can be used to copy files or convert to PDSE                     *
 *-------------------------------------------------------------------*
 *  Can be invoked by:                                               *
 *   TSO RESIZE                                                      *
 *   TSO RESIZE <dsn>                                                *
 *   TSO RESIZE with point and shoot to the DSN on the scr           *
 *   RESIZE as a line command in a 3.4 list                          *
\*-------------------------------------------------------------------*/
parse source . . rexxname .
if sysdsn("'TTEV.TRACE."rexxname"'") = 'OK' then trace i

arg ewidsn

address ispexec

/* If a dataset was supplied then don't search the screen            */
if ewidsn = '' then do
  /* First check for point and shoot to a valid dsn                  */
  'VGET (ZSCREENI,ZSCREENC)' /* Extract screen image                 */
  delims = "*&<>()=', " || '"'
  curpos = zscreenc + 1
  do x = curpos to 1 by -1 /* Find start of field                    */
    if pos(substr(zscreeni,x,1),delims) ^= 0 then do
      start = x + 1
      leave
    end /* pos(substr(zscreeni,x,1),delims) ^= 0 */
  end
  do x = curpos to length(zscreeni) /* Find end of field             */
    if pos(substr(zscreeni,x,1),delims) ^= 0 | ,
       x = length(zscreeni) then do
      if x = length(zscreeni) then /* Weve reached end of the screen */ /
        x = x + 1
      len = x - start
      if len > 0 then do
        pasdsn  = substr(zscreeni,start,len)
        upper pasdsn
        pasdsnq = "'"pasdsn"'"
        test = msg(off)
        r    = sysdsn(pasdsnq) /* Check validity of dsn gathered     */
        test = msg(on)
        if r = 'OK' then /* Point & shoot has found a valid dsn      */
          ewidsn = pasdsn
        leave
      end /* len > 0 */
    end /* pos(substr(zscreeni,x,1),delims) ^= 0 | ... */
  end /* x = curpos to length(zscreeni) */
end /* ewidsn = '' */

if ewidsn = '' then /* I.e. No point and shoot or dsn specified      */
  "vget (ewidsn) profile"
else do
  donow = 'Y'
  ldsn  = ewidsn
end /* else */

sysuid   = sysvar(sysuid)
copypgm  = 'IEBCOPY'
idsn     = ewidsn
prevldsn = 'x'
msgid    = ''
cursor   = 'idsn'
csrpos   = ''
delold   = 'Y'
dsnsuff  = 'REORG.PAS'left(sysuid,2) || right(date(j),3)
maxwait  = '24'
viewjob  = 'N'
rlse     = 'Y'
interval = '5'

do forever
  if donow ^= 'Y' then
  "display panel(resize) cursor("cursor") msg("msgid") csrpos("csrpos")"
  if rc = 08 | pfk = pf03 | pfk = pf04 then
    leave
  donow   = 'N'

  idsn    = strip(idsn,,"'")
  ldsn    = strip(ldsn,,"'")
  msgid   = ''
  cursor  = ''
  csrpos  = ''
  enqmess = ''
  enqmsg  = ''
  direrr  = ''
  secerr  = ''

  /* Get listdsi values for input dsn                                */
  x = get_ds_info(idsn 'I')
  parse value x with irdsn iorg irfm ilrl ipri isec idir iunits,
        iused iusedp iblktr iblksz ivol iuext iudir iumem iutk iucl,
        iublk idstyp
  if x = 8 then
    iterate

  call idcams          /* Get volume info from DCOLLECT              */

  call check_enq idsn  /* Check dataset enqs                         */

  if iorg ^= 'PO' then do /* Only for PDSs                           */
    msgid   = 'RESIZ003'
    cursor  = 'idsn'
    iterate
  end /* iorg ^= 'PO' */

  if iorg = 'PO' & idir = iudir then do   /* Directory full          */
    direrr = 'Y'
    msgid  = 'RESIZ001'
    cursor = 'idsn'
  end /* org = 'PO' & idir = iudir */
  if iunits = 'TRK' & isec > mtrk then    /* Volume full             */
    secerr = 'TRACK'
  if iunits = 'CYL' & isec > mcyl then    /* Volume full             */
    secerr = 'CYL'
  if datatype(iunits,n) = 1 & ,
     iublk ^= 'N/A' & isec > mblocks then /* Volume full             */
    secerr = 'BLK'
  if secerr ^= '' then do                 /* Volume full             */
    msgid  = 'RESIZ002'
    cursor = 'idsn'
  end
  if idsn ^= irdsn then do                /* Alias                   */
    zedsmsg = ''
    zedlmsg = idsn 'is an alias to' irdsn
    address "ISPEXEC" "SETMSG MSG(ISRZ001)"
    iterate
  end /* idsn ^= irdsn */

  /************** End   of checks for input dataset ******************/

  /************** Start of checks for like  dataset ******************/

  /* Get listdsi values for like dsn                                 */
  if prevldsn ^= ldsn then do
    if ldsn = '' then
      ldsn = idsn
    x = get_ds_info(ldsn 'L')
    parse value x with lrdsn lorg lrfm llrl lpri lsec ldir lunits,
          lused lusedp lblktr lblksz lvol luext ludir lumem lutk lucl,
          lublk ldstyp
    if x = 8 then
      iterate
    if lorg ^= 'PO' then do /* Only for PDSs                         */
      msgid  = 'RESIZ003'
      cursor = 'ldsn'
      iterate
    end /* lorg ^= 'PO' */
  end /* prevldsn <> ldsn */

  if enqmsg ^= '' then
  "display panel(resize) cursor("cursor") msg("msgid") csrpos("csrpos")"

  /************** All dataset checks ok so carry on ******************/

  if lorg = iorg &, /* Check dsn attributes match like dsn atts      */
     lrfm = irfm &,
     llrl = ilrl then do
    if idsn = ldsn then /* Set rename dsn                            */
      likedsn = ldsn || '.' || dsnsuff
    else
      likedsn = ldsn
    renamdsn  = idsn || '.' || dsnsuff
    renamdsnq = "'"renamdsn"'"
    if length(likedsn) > 44 then do /* Rename dsn too large          */
      msgid  = 'RESIZ007'
      cursor = 'dsnsuff'
      csrpos = 44 - length(idsn)
      iterate
    end /* length(likedsn) > 44 */
    if sysdsn(renamdsnq) = 'OK' then do /* Rename dsn already exists */
      zedsmsg = ''
      zedlmsg = 'Rename dataset' renamdsn 'already exists'
      address "ISPEXEC" "SETMSG MSG(ISRZ001)"
      cursor  = 'idsn'
      iterate
    end /* sysdsn(renamdsnq) = 'OK' */
    newdsn  = idsn".NEW"
    newdsnq = "'"newdsn"'"
    if sysdsn(newdsnq) = 'OK' then do /* .NEW dataset already exists */
      zedsmsg = ''
      zedlmsg = 'New dataset' newdsn 'already exists'
      address "ISPEXEC" "SETMSG MSG(ISRZ001)"
      cursor  = 'idsn'
      iterate
    end /* sysdsn(renamdsnq) = 'OK' */
    select
      when lunits = 'TRK'    then
        lpritrk = lpri
      when lunits = 'CYL' then
        lpritrk = lpri * 15
      when datatype(lunits,n) = 1 then do
        lpritrk = 999999
      end
      otherwise nop
    end /* select */

    select
      when ldstyp ^= 'LIBRARY' & ldir = 'NO_LIM' then do
        zedsmsg = ''
        zedlmsg = 'NO_LIM is only valid when the dataset type is LIBRARY'
        address "ISPEXEC" "SETMSG MSG(ISRZ001)"
        cursor  = 'ldir'
        iterate
      end /* ldstyp ^= 'LIBRARY' & ldir = 'NO_LIM' */
      when ldstyp = 'LIBRARY' & ldir ^= 'NO_LIM' then do
        zedsmsg = ''
        zedlmsg = 'Directory blocks must be NO_LIM for DS type LIBRARY'
        address "ISPEXEC" "SETMSG MSG(ISRZ001)"
        cursor  = 'ldir'
        ldir    = 'NO_LIM'
        iterate
      end /* ldstyp = 'LIBRARY' & ldir ^= 'NO_LIM' */
      when ldstyp = 'LIBRARY' & idstyp = 'PDS' then do
        zedsmsg = ''
        zedlmsg = 'RESIZE COPY option can not convert PDS to PDSE,',
                  'use the CONVERT option instead.'
        address "ISPEXEC" "SETMSG MSG(ISRZ001)"
        cursor  = 'ldsn'
        iterate
      end /* ldstyp = 'LIBRARY' & idstyp = 'PDS' */
      when idstyp = 'LIBRARY' & ldstyp = 'PDS' then do
        zedsmsg = ''
        zedlmsg = 'RESIZE COPY option can not convert PDS to PDSE,',
                  'use the CONVERT option instead.'
        address "ISPEXEC" "SETMSG MSG(ISRZ001)"
        cursor  = 'ldsn'
        iterate
      end /* idstyp = 'LIBRARY' & ldstyp = 'PDS' */
      otherwise nop
    end /* select */

    if ldstyp = 'LIBRARY' then
      ldir = 'NO_LIM'
    else do
      if ldir = '' then do
        zedsmsg = ''
        zedlmsg = 'Enter required directory blocks'
        address "ISPEXEC" "SETMSG MSG(ISRZ001)"
        cursor  = 'ldir'
        iterate
      end /* ldir = '' */
      maxdir = lpritrk * 45 - 1 /* Calc max dir blocks in pri ext    */
      ldir   = (ldir % 45) * 45 + 44 /* Round up dir alloc           */
      if maxdir <  ldir then do /* Pri alloc too small for dir blocks*/
        zedsmsg = ''
        zedlmsg = 'Max directory blocks =' maxdir 'for primary extent'
        address "ISPEXEC" "SETMSG MSG(ISRZ001)"
        cursor  = 'ldir'
        iterate
      end /* maxdir <  ldir */
      if ldir < iudir then do /* Dir blocks less than used           */
        zedsmsg = ''
        zedlmsg = 'Directory blocks requested less than used'
        address "ISPEXEC" "SETMSG MSG(ISRZ001)"
        cursor  = 'ldir'
        iterate
      end /* ldir < iudir */
    end /* select */
    select
      when zcmd = 'SUB' then do
        if enqmsg ^= '' then do
          zedsmsg = ''
          zedlmsg = enqmsg
          address "ISPEXEC" "SETMSG MSG(ISRZ001)"
          "display panel(resizee)"
          if rc = 08 | pfk = pf03 | pfk = pf04 then
            iterate
        end /* enqmsg ^= '' */
        "display panel(resizej)"
        if rc = 08 | pfk = pf03 | pfk = pf04 then
          iterate
        if viewjob = 'Y' then
          call editjob resize
        else
          call subjob resize
      end /* zcmd = 'SUB' */
      when zcmd = 'EDIT' then do
        if enqmsg ^= '' then do
          zedsmsg = ''
          zedlmsg = enqmsg
          address "ISPEXEC" "SETMSG MSG(ISRZ001)"
          "display panel(resizee)"
          if rc = 08 | pfk = pf03 | pfk = pf04 then
            iterate
        end /* enqmsg ^= '' */
        /* "display panel(resizej)"                                  */
        /* if rc = 08 | pfk = pf03 | pfk = pf04 then                 */
        /* iterate                                                   */
        call editjob resize
      end /* zcmd = 'EDIT' */
      when zcmd = 'CONVERT' then do
        if enqmsg ^= '' then do
          zedsmsg = ''
          zedlmsg = enqmsg
          address "ISPEXEC" "SETMSG MSG(ISRZ001)"
          "display panel(resizee)"
          if rc = 08 | pfk = pf03 | pfk = pf04 then
            iterate
        end /* enqmsg ^= '' */
        if idir = 'NO_LIM' then do
          ndir   = trunc(lumem/3*1.2)
          ldir   = (ndir % 45) * 45 + 44 /* Round up dir alloc       */
          ldstyp = 'PDS'
        end /* ldir = 'NO_LIM' */
        else do
          ldir   = 'NO_LIM'
          ldstyp = 'LIBRARY'
        end /* else */
        if lrfm = 'U' then copypgm = 'BC1PNCPY'
        call editjob resize
        copypgm = 'IEBCOPY'
      end /* zcmd = 'CONVERT' */
      when zcmd = 'COPY' then do
        ndsn = idsn
        "display panel(resizecp)"
        if rc = 08 | pfk = pf03 | pfk = pf04 then
          iterate
        ndsnq = "'"ndsn"'"
        do while sysdsn(ndsnq) = 'OK' /* New dataset already exists  */
          zedsmsg = ''
          zedlmsg = 'New dataset' ndsn 'already exists'
          address "ISPEXEC" "SETMSG MSG(ISRZ001)"
          cursor  = 'idsn'
          "display panel(resizecp)"
          if rc = 08 | pfk = pf03 | pfk = pf04 then
            leave
          ndsnq = "'"ndsn"'"
        end /* while sysdsn(ndsnq) = 'OK' */
        if rc = 08 | pfk = pf03 | pfk = pf04 then
          iterate
        "display panel(resizej)"
        if rc = 08 | pfk = pf03 | pfk = pf04 then
          iterate
        if rlse = 'Y' then
          rlsej = ',RLSE'
        else
          rlsej = ''
        if viewjob = 'Y' then
          call editjob resizecp
        else
          call subjob resizecp
      end /* zcmd = 'COPY' */
      when zcmd = 'TCOMP' then
        call TCOMPRESS
      when zcmd = 'COMPRESS' | zcmd = 'Z' then do
        if idir = 'NO_LIM' then do
          zedsmsg = ''
          zedlmsg = 'You cannot compress a PDSE'
          address "ISPEXEC" "SETMSG MSG(ISRZ001)"
          iterate
        end /* idir = 'NO_LIM' */
        else do
          if enqmsg ^= '' then do
            zedsmsg = ''
            zedlmsg = enqmsg
            address "ISPEXEC" "SETMSG MSG(ISRZ001)"
            "display panel(resizeec)"
            if rc = 08 | pfk = pf03 | pfk = pf04 then
              iterate
          end /* enqmsg ^= '' */
          iebfunc = 'COMPRESS'
          iebcmd  = 'COPY OUTDD=PDSIN,INDD=((PDSIN,R))'
          call subjob resizec
        end /* else */
      end /* zcmd = 'COMPRESS' | zcmd = 'Z' */
      otherwise nop
    end /* select */
  end /* idsn attributes = ldsn dsn attributes */
  else do /* Reset values for like dsn                               */
    lpri    = ''
    lsec    = ''
    ldir    = ''
    lunits  = ''
    luext   = ''
    ludir   = ''
    lumem   = ''
    lutk    = ''
    lucl    = ''
    lublk   = ''
    lusedp  = ''
    zedsmsg = ''
    zedlmsg = 'Dataset attributes not the same:'
    if lorg ^= iorg then
      zedlmsg = zedlmsg 'DSORG' iorg'/'lorg
    if lrfm ^= irfm then
      zedlmsg  = zedlmsg 'RECFM' irfm'/'lrfm
    if llrl ^= ilrl then
      zedlmsg  = zedlmsg 'LRECL' ilrl'/'llrl
    address "ISPEXEC" "SETMSG MSG(ISRZ001)"
  end /* else */
  zcmd = ''
  prevldsn = ldsn
end /* while rc <> 08 & pfk <> pf03 & pfk <> pf04 */

ewidsn = idsn
address ispexec
"vput (ewidsn) profile"

exit

/*---------------------- S U B R O U T I N E S ----------------------*/

/*-------------------------------------------------------------------*/
/* SUBJOB - Creates the JCL with file tailoring and submits          */
/*-------------------------------------------------------------------*/
subjob:
 arg skelid

 address ispexec 'ftopen temp'
 address ispexec 'ftincl ' skelid
 address ispexec 'ftclose'
 address ispexec 'vget (ztempf) shared'
 address tso     "submit '"ztempf"'"

return /* subjob: */

/*-------------------------------------------------------------------*/
/* EDITJOB - Creates the JCL with file tailoring and editss          */
/*-------------------------------------------------------------------*/
editjob:
 arg skelid

 if substr(ldsn,1,6) = 'PREV.R' & right(ldsn,4) = 'CICS' then do
   lpri = '10'
   lsec = '0'
   ldir = '5'
 end /* substr(ldsn,1,6) = 'PREV.R' & right(ldsn,4) = 'CICS' */

 address ispexec 'ftopen temp'
 address ispexec 'ftincl ' skelid
 address ispexec 'ftclose'
 address ispexec 'vget (ztempn)'
 address ispexec 'lminit dataid(did) ddname('ztempn')'
 address ispexec 'edit dataid('did') macro(resizem)'
 address ispexec 'lmclose dataid('did')'
 address ispexec 'lmfree  dataid('did')'

return /* editjob: */

/*-------------------------------------------------------------------*/
/* IDCAMS  - Get volume information (max space)                      */
/*-------------------------------------------------------------------*/
idcams:
 address tso

 test = msg(off)
 "free f(print1 sysin sysprint)"
 "alloc f(sysin) new space(2 2) cylinders recfm(f b) lrecl(80)"
 queue "  DCOLLECT OUTFILE(PRINT1) VOLUMES("ivol") NODATAINFO"
 "execio" queued() "diskw sysin (finis)"
 "alloc f(print1) new space(2 2) cylinders recfm(v b) lrecl(264)"
 "alloc f(sysprint) new space(2 2) cylinders recfm(f b) lrecl(133)"
 "call 'sys1.linklib(idcams)'"
 "execio * diskr print1 (stem idc. finis"
 if rc <> 0 then do
   say 'Internal error. Contact Endevor Support. Quote IDCAMS'
   leave
 end /* rc <> 0 */
 hexval = substr(idc.1,53,4)
 qq     = pos('"',hexval) /* Find double quote in the hexval         */
 if qq = 0 then
   interpret 'hex = c2x("'hexval'")' /* Use double quotes            */
 else
   interpret "hex = c2x('"hexval"')" /* Use single quotes            */
 interpret "kb = x2d('"hex"',8)"
 mtrk = trunc((kb * 1024) / 56664)
 mcyl = trunc(mtrk / 15)
 if datatype(iblktr,n) = 1 then
   mblocks = trunc(mtrk * iblktr)
 else
   mblocks = ''
 "free f(sysin print1 sysprint)"
 test = msg(on)

return /* idcams: */

/*-------------------------------------------------------------------*/
/* TCOMPRESS - How much wasted space                                 */
/*-------------------------------------------------------------------*/
tcompress:
 address tso

 if iucl > 50 then do
   iebfunc = 'TCOMPRESS'
   iebcmd  = 'TCOMPRESS OUTDD=PDSIN,LIST=NO'
   call subjob resizec
   zedsmsg = ''
   zedlmsg = 'File too big for online TCOMPRESS, batch job submitted'
   address "ISPEXEC" "SETMSG MSG(ISRZ001)"
   return
 end /* iucl > 50 */
 if idir = 'NO_LIM' then do
   zedsmsg = ''
   zedlmsg = 'You cannot compress a PDSE'
   address "ISPEXEC" "SETMSG MSG(ISRZ001)"
   return
 end /* idir = 'NO_LIM' */
 zedlmsg = ''
 test    = msg(off)
 "free f(sysin sysprint)"
 "alloc f(sysin) new space(2 2) cylinders recfm(f b) lrecl(80)"
 queue " TCOMPRESS OUTDD=TCOMP,LIST=NO"
 "execio" queued() "diskw sysin (finis)"
 "alloc f(sysprint) new space(2 2) cylinders recfm(f b) lrecl(133)"
 "alloc f(tcomp) da('"idsn"') shr"
 "call 'sys1.linklib(iebcopy)'"
 "execio * diskr sysprint (stem ieb. finis"
 if rc <> 0 then do
   say 'Internal error. Contact Endevor Support. Quote TCOMPRESS'
   leave
 end /* rc <> 0 */
 do i = 1 to ieb.0
   if word(ieb.i,1) = 'FCO215U' then do
     tused   = iutk - word(ieb.i,5)
     zedsmsg = ''
     zedlmsg = 'COMPRESS WILL REGAIN' subword(ieb.i,5) ,
               '                  ' tused 'tracks would be in use'
     address "ISPEXEC" "SETMSG MSG(ISRZ001)"
   end /* word(ieb.i,1) = 'FCO215U' */
 end /* i = 1 to ieb.0 */
 if zedlmsg = '' then do
   zedsmsg = ''
   zedlmsg = 'UNKNOWN TCOMPRESS ERROR'
   address "ISPEXEC" "SETMSG MSG(ISRZ001)"
 end /* zedlmsg = '' */
 "free f(sysin tcomp sysprint)"
 test = msg(on)

return /* tcompress: */

/*-------------------------------------------------------------------*/
/* Check dataset enqs                                                */
/*-------------------------------------------------------------------*/
check_enq:
 arg enqdsn

 enqjob.0 = ''
 s = queryenq("'"enqdsn"'")
 /* Queryenq sometimes does not set variables and so the rexx fails */
 /* only for one user (BOWERC)? The next if allows for this         */
 if enqjob.0 <> '' then do
   if enqjob.0 = 0 then
     enqmess = 'Dataset not in use'
   else do
     cursor = 'idsn'
     /* Queryenq delivers a maximum of 84 enqs                       */
     if enqjob.0 = 84 then
       enqmsg = 'Dataset in use by' enqjob.0'+ jobs:'
     else
       enqmsg = 'Dataset in use by' enqjob.0 'jobs:'
     do a = 1 to enqjob.0
       /* zedlmsgs can list a maxiumum of 52 enqs                    */
       if a = 52 then do
         enqmsg = enqmsg 'more...'
         leave
       end /* a = 52 */
       else
         enqmsg = enqmsg enqjob.a
     end /* do a = 1 to enqjob.0 */
     zedsmsg = ''
     zedlmsg = enqmsg
     address "ISPEXEC" "SETMSG MSG(ISRZ001)"
   end /* else */
 end /* enqjob.0 <> '' */

return /* check_enq: */

/*-------------------------------------------------------------------*/
/* Get DS info                                                       */
/*-------------------------------------------------------------------*/
get_ds_info:
 procedure expose msgid cursor mcyl mtrk mblocks
 arg dsname type

 result = 0
 rdsn  = '.'
 org   = '.'
 rfm   = '.'
 lrl   = '.'
 used  = '.'
 blktr = '.'
 blksz = '.'
 vol   = '.'
 pri   = '.'
 sec   = '.'
 dir   = '.'
 units = '.'
 uext  = '.'
 udir  = '.'
 umem  = '.'
 utk   = '.'
 ucl   = '.'
 ublk  = '.'
 usedp = '.'
 if type = 'I' then do
   mcyl    = ''
   mtrk    = ''
   mblocks = ''
 end /* type = i */

 dsnquote = "'"dsname"'"
 x = listdsi(dsnquote directory)
 if x = 0 then do
   rdsn = sysdsname
   org  = sysdsorg
   rfm  = sysrecfm
   lrl  = syslrecl
   pri  = sysprimary
   sec  = sysseconds
   if org = 'PO' then do
     dir  = sysadirblk
     udir = sysudirblk
     umem = sysmembers
   end /* org = 'PO' */
   units = sysunits
   alloc = sysalloc
   used  = sysused
   blktr = sysblkstrk
   vol   = sysvolume
   uext  = sysextents
   blksz = sysblksize
   select
     when units = 'TRACK'    then
       units = 'TRK'
     when units = 'CYLINDER' then
       units = 'CYL'
     when units = 'BLOCK' then
       units = blksz
     otherwise nop
   end /* select */
   dstyp = ''
   if left(org,2) = 'PO' then do
     if dir ^= 'NO_LIM' then do
       dstyp    = 'PDS'
       freeexts = 16 - uext
     end /* dir ^= 'NO_LIM' */
     else do
       dstyp    = 'LIBRARY'
       freeexts = 123 - uext
       used     = alloc
     end /* else */
   end /* left(org,2) = 'PO' */
   else
     freeexts = 16 - uext
   maxalloc = alloc + (freeexts * sec)
   usedp    = (used / maxalloc) * 100
   usedp    = trunc(usedp,0)'%full'
   select
     when units = 'TRK' then do
       utk = used
       ucl = trunc((used / 15) + .99999)
       if datatype(blktr,n) = 1 then
         ublk  = used * blktr
     end /* units = 'TRACK' */
     when units = 'CYL' then do
       units = 'CYL'
       utk   = used * 15
       ucl   = used
       if datatype(blktr,n) = 1 then
         ublk  = utk * blktr
     end /* units = 'CYLINDER' */
     when datatype(units,n) = 1 then do
       ublk = used
       if datatype(blktr,n) = 1 then do
         utk = trunc((used / blktr) + .9999)
         ucl = trunc((utk / 15) + .999999)
       end /* datatype(blktr,n) = 1 */
       else do
         utk = '.'
         ucl = '.'
       end /* datatype(blktr,n) ^= 1 */
     end /* units = 'BLOCK' */
     otherwise nop
   end /* select */
   dsndata = rdsn org rfm lrl pri sec dir units used usedp,
             blktr blksz vol uext udir umem utk ucl ublk dstyp
 end /* x = 0 */
 else do /* x ^= 0 - lisdsi failed                                   */
   dsndata = 8
   interpret "cursor = '"type"dsn'"
   zedsmsg = ''
   zedlmsg = sysmsglvl2
   address "ISPEXEC" "SETMSG MSG(ISRZ001)"
 end /* else */

return dsndata /* get_ds_info: */

/*-------------------------------------------------------------------*/
/* Error with line number displayed - for IKJEFT non ISPF            */
/*-------------------------------------------------------------------*/
exception:
 parse arg return_code comment

 say rexxname':'
 say rexxname':' comment'. RC='return_code
 say rexxname': Exception called from line' sigl

 z = msg(off)
 address tso "free f(sysin tcomp print1 sysprint)"
 address tso 'delstack'           /* Clear down the stack            */
 z = msg(on)

 if return_code < 0 then return_code = 12 /* - RCs can be invalid    */

exit return_code
