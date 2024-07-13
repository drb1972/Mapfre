/*--------------------------REXX------------------------------------*\
 * EVXPED01: ENDEVOR/XPEDITER INTERFACE                             *
 * CREATOR:  CRAIG HILTON                                           *
 * CREATED:  DECEMBER 1996                                          *
 * AMENDED:  APRIL    2001  REMOVE SUBSYSTEM VALIDATION             *
 * CONVERTED: MARCH 2007  CONVERTED TO REXX & ADDED DDIO SUGGESTION *
 *                                                                  *
 *------------------------------------------------------------------*
 *  THIS CLIST ALLOWS USERS TO DO ANY OF THE FOLLOWING:             *
 *      (1) COPY AN ELIB LISTING TO AN XPEDITER DDIO FILE           *
 *      (2) COPY AN ELIB LISTING TO A PDS                           *
 *      (3) COPY A DDIO LISTING TO ANOTHER DDIO FILE                *
\*------------------------------------------------------------------*/
trace n
address ispexec

"VGET (stg sub ele typ iddio1 iddio2 iddio3)   PROFILE"
"VGET (oddio1 oddio2 oddio3 upds1 upds2 upds3) PROFILE"
"VGET (zuser zprefix) SHARED"
"VGET (jname ewxjcl1 ewxjcl2 ewxjcl3 ewxjcl4) PROFILE"
"VGET (C1BJC1 C1BJC2 C1BJC3 C1BJC4) PROFILE"

/* kludge added until the calling clist can be changed via T01       */
if c1bjc1 = '' then c1bjc1 = ewxjcl1
if c1bjc2 = '' then c1bjc2 = ewxjcl2
if c1bjc3 = '' then c1bjc3 = ewxjcl3
if c1bjc4 = '' then c1bjc4 = ewxjcl4

if oddio1 = '' & oddio2 = '' & oddio3 = '' then do
  oddio1 = zprefix
  oddio2 = 'XXXX'
  oddio3 = 'DDIOTSO'
end
if upds1 = '' & upds2 = '' & upds4 = '' then do
  upds1 = zprefix
  upds2 = zuser
  upds3 = 'LISTING'
end

msgid   = ''
csr     = zcmd

/*****************************************************                */
/*****   DISPLAY PANEL AND EXIT IF PF3 ENTERED   *****                */
/*****************************************************                */
do forever
  "display panel(EVXPED01) msg("msgid") cursor("csr")"
  if rc = 8 then
    leave
  msgid  = ''
  cmd = zcmd
  select
    when zcmd = 'E' then do /* from Endevor to ddio */
      x = fromndvr()
      if x = 8 then iterate
      x = toddio()
      if x = 8 then iterate
    end
    when zcmd = 'X' then do /* from ddio to ddio */
      ddiofrom = iddio1"."iddio2"."iddio3
      if sysdsn("'"ddiofrom"'") ^= 'OK' then do /* check ddio exists */
        msgid = 'evxp009'
        csr = 'iddio1'
        iterate
      end
      x = toddio()
      if x = 8 then iterate
    end
    when zcmd = 'P' then do /* from Endevor to PDS */
      x = fromndvr()
      if x = 8 then iterate
      x = topds()
      if x = 8 then iterate
    end
    when zcmd = '' then do /* No entry so iterate */
      csr    = 'zcmd'
      iterate
    end
    otherwise do           /* invalid command */
      csr    = 'zcmd'
      msgid  = 'evxp002'
      zcmd   = ''
      iterate
    end
  end /* select */

  /* Get jobcard & tailor jcl file                   */
    if jname = '' then jname = '????????'
    ewxjcl1 = "//"||jname||" JOB 1,'"zuser" - LISTINGS',"
    ewxjcl2 = "//     NOTIFY="zuser",CLASS=3,REGION=3M"
    ewxjcl3 = "//*"
    ewxjcl4 = "//*"

  ispexec "display panel(evxped0j)"
  if rc = 8 then iterate

  /* treat sceptre and cobol as the same jobtype (i.e. cobol)        */
  select
    when left(typ,1)  = 'A' then jobtype = 'A'
    when left(typ,1)  = 'P' then jobtype = 'P'
    otherwise jobtype = 'C'
  end /* select                                                      */

  xptyp = left(typ,1)

  "ftopen temp"
  if rc ^= 0 then do
    rcode = rc
    ftserv = 'ftopen'
    "setmsg msgid(qjclm007)"
    exit
  end
  "ftincl evxped01"
  "vget ( ztempf ) shared"
  if rc ^= 0 then do
    rcode = rc
    ftserv = 'ftincl'
    "setmsg msgid(qjclm007)"
    exit
  end
  "ftclose"
  if rc ^= 0 then do
    rcode = rc
    ftserv = 'ftclose'
    "setmsg msgid(qjclm007)"
    exit
  end
  address tso "submit '"ztempf"'"
  if rc = 0 then
    "setmsg msg(qjclm005)"
  else
    "setmsg msg(qjclm006)"
end /* do forever */

/*      terminate                                   */
"VPUT (stg sub ele typ iddio1 iddio2 iddio3)   PROFILE"
"VPUT (oddio1 oddio2 oddio3 upds1 upds2 upds3) PROFILE"
"VPUT (jname ewxjcl1 ewxjcl2 ewxjcl3 ewxjcl4) PROFILE"
"VPUT (C1BJC1 C1BJC2 C1BJC3 C1BJC4) PROFILE"

exit

/*--------------------------------------------------------------------*/
/* Source is from Endevor                                             */
/*--------------------------------------------------------------------*/
fromndvr:
 sys = left(sub,2)
 select
   when stg = 'T' | stg = 'U' then
     envr = 'UTIL'
   when stg = 'A' | stg = 'B' then
     envr = 'UNIT'
   when stg = 'C' | stg = 'D' then
     envr = 'SYST'
   when stg = 'E' | stg = 'F' then
     envr = 'ACPT'
   when stg = 'O' | stg = 'P' then
     envr = 'PROD'
   otherwise nop
 end
 call runapi /* check element exists & get the processor group */
 if result = 12 then return 8 /* element not found */
 /* set up the listing name */
 char8 = right(pgrp,1)
 select
   when char8 = 'B' then
     suff = 'P'
   when char8 = 'K' | char8 = 'I' then
     suff = 'K'
   otherwise
     suff = left(typ,1)
 end /* select */
 listmem  = ele || suff || substr(sub,3,3)
 listqual = stg || substr(sub,1,2)

 /* listing name will be truncated to 8 chrs when copied to a pds */
 listmem = strip(listmem)
 if length(listmem) > 8 then
   listm8  = left(listmem,8)
 else
   listm8  = listmem

 /* set up the defailt DDIO files - for display only */
 deftgtt = 'TT'sys'.'stg||sub'.DDIOTSO'
 deftgtc = 'No default - TTSP.X#nn.DDIOCICS' /* initial setting */
 cicsdsn = "PREV."stg||sub".CICS"
 address tso
 x = listdsi("'"cicsdsn"'") /* get CICS load lib alias */
 address ispexec
 if x < 5 then do
   rdsn  = sysdsname
   if rdsn = cicsdsn then do /* no CICS alias so check the table */
     address tso
     "alloc f(temp) dsname('prev.pev1.data(xpeddioc)') shr"
     "execio * diskr temp (stem line. finis"
     "free fi(temp)"
     address ispexec
     do i = 1 to line.0
       if left(line.i,1) ^= '*' then do
         xsub = subword(line.i,1,1)
         if xsub = sub then do /* subsys found so set default */
           deftgtc = 'TTSP.'subword(line.i,2,1)'.DDIOCICS'
           leave i
         end
       end
     end /* do i = 1 to line.0 */
   end /* rdsn = cicsdsn */
   else do  /* the CICS load lib has an alias */
     stream = substr(rdsn,8,2)
     deftgtc = 'TTSP.X#'stream'.DDIOCICS'
   end
 end /* if listdsi result < 5 then do */

return 0

/*--------------------------------------------------------------------*/
/* Target is a DDIO file                                              */
/*--------------------------------------------------------------------*/
toddio:
 if zcmd = 'E' then
   pan = 'EVXPED02' /* With suggessted target DDIO file */
 else
   pan = 'EVXPED04' /* No target DDIO file suggestions */
 do forever
   "addpop"
   "display panel("pan") msg("msgid")"
   disprc = rc
   "rempop"
   msgid = ''
   if disprc = 8 then
     return 8
   /* check that the target ddio file exists */
   ddioto = oddio1"."oddio2"."oddio3
   if sysdsn("'"ddioto"'") ^= 'OK' then do
     msgid = 'evxp009'
     iterate
   end
   if zcmd = 'X' then
     if ddiofrom = ddioto then do
       msgid = 'evxp001e'
       iterate
     end
   leave
 end /* do forever */
return 0

/*--------------------------------------------------------------------*/
/* copy to a PDS                                                      */
/*--------------------------------------------------------------------*/
topds:
 do forever
   "addpop"
   "display panel(EVXPED03) msg("msgid")"
   disprc = rc
   "rempop"
   msgid = ''
   if disprc = 8 then
     return 8
   /* check that the target pds exists */
   tgtpds = "'"upds1"."upds2"."upds3"'"
   address tso
   x = listdsi(tgtpds)
   address ispexec
   if x ^= 0 then do
     msgid = 'evxp009'
     iterate
   end
   if syslrecl ^= 133 then do
     msgid = 'evxp001d'
     iterate
   end
   /* set the replace parm of the iebcopy statement */
   if repl = 'Y' then
     upd = ',R'
   else
     upd = ''
   leave
 end /* do forever */
return 0

/*--------------------------------------------------------------------*/
/*      Run the API to check that the element exists                  */
/*--------------------------------------------------------------------*/
Runapi:
 address tso
 /* allocate datasets */
 test=msg(off)
 "FREE DD(SYSOUT,SYSPRINT,BSTERR,APIMSGS,APIEXTR)"
 test=msg(on)
 "ALLOC DD(SYSOUT) SYSOUT"
 "ALLOC DD(SYSPRINT) SYSOUT"
 "ALLOC DD(BSTERR) SYSOUT"
 "ALLOC DD(APIMSGS) LRECL(133) RECFM(F B) BLKSIZE(0)"
 "ALLOC DD(APIEXTR) LRECL(2048) NEW,
  RECFM(V B) DSORG(PS) BLKSIZE(22800) SPACE(75,75) TRACKS REUSE"
 "ALLOC FI(SYSIN) SPACE(1,1) TRACKS,
                   LRECL(80) RECFM(F) BLKSIZE(80) REUSE"
 /* build up the sysin command */
 queue 'AACTL APIMSGS APIEXTR'
 ele8 = left(ele,8)
 queue 'ALELM  N 'envr'    'stg || sys'      'sub'     'ele8'  'typ
 queue 'RUN'
 queue 'AACTLY'
 queue 'RUN'
 queue 'QUIT'
 /* write the sysin */
 "EXECIO "queued()" DISKW SYSIN (FINIS"
 /* Call the API */
 address "LINKMVS" ENTBJAPI
 if rc ^= 0 then do
   "FREE DD(SYSOUT,SYSPRINT,BSTERR,APIMSGS,APIEXTR,SYSIN)"
   say 'API failed - RETURN CODE IS' rc
   say 'Please call Endevor Support on +44 (0)123 963 8560'
   return
 end
 /* read the API element list */
 "EXECIO * DISKR apiextr (STEM eltlist. FINIS)"
 "FREE DD(SYSOUT,SYSPRINT,BSTERR,APIMSGS,APIEXTR,SYSIN)"
 if eltlist.0 = 0 then do
   msgid = 'evxp001c'
   csr   = 'ele'
   return 12
 end
 do ii = 1 to eltlist.0
   if pos('*FAILED*',eltlist.ii) = 654 then
     do
       msgid = 'evxp001g'
       csr   = 'ele'
       return 12
     end
 end
 pgrp = substr(eltlist.1,71,8)
 address ispexec
return
