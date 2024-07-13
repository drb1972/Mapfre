/*-----------------------------REXX----------------------------------*\
 *  Get an Endevor CAST report, analyse it, and write                *
 *  the report in readable format.                                   *
 *  This works in foreground or batch.                               *
\*-------------------------------------------------------------------*/
trace n

environ = sysvar("sysenv") /* Foreground or Batch?                   */
uid     = sysvar("sysuid")

arg parm
pkgid = word(parm,1)
if pkgid = 'TEST' then pkgid = ''

if environ <> 'FORE' & pkgid = '' then do
  say 'CZ: You must supply a package id'
  exit 12
end /* environ <> 'FORE' & pkgid = '' */

call initialise

if pkgid = '' then
  call find_cast_report
else
  call read_pkg_mast

if environ = 'FORE' then do /* Allocate the output dataset           */
  "alloc file("castrpt") space(15,20) tracks reuse lrecl(132)"
  newstack
end /* environ = 'FORE' */

/* Write out the header for the output report                        */
queue "                 MAPFRE ENDEVOR CAST REPORT ANALYSER"
queue "                 -----------------------------------"
queue "                (Please read the usage notes at the end)"
queue " "

if environ = 'FORE' then do
  /* Write to a temp dataset so that the edit macro can pick it up   */
  "alloc file(CASTHDR) space(15,20) tracks reuse lrecl(132)"
  if rc ^= 0 then call exception rc 'ALLOC of CASTHDR failed'
  "execio" queued() "diskw CASTHDR ( finis"
  if rc ^= 0 then call exception rc 'DISKW to CASTHDR failed'
  "delstack"
end /* environ = 'FORE' */
else do
  queue " Package ID :" pkgid
  queue " Date       :" date('N')
  queue " Userid     :" uid
  queue " "
end /* else */

ignore_msgs = 'PKMR408 C1U0811 ENMP092 ENBP023 ENBP010'

do j = 1 to rpt.0 /* Analyse cast error messages                     */
  msgno  = left(word(rpt.j,2),7)
  select
    when msgno = 'FPVL001' then do
      do jj = j + 1 to rpt.0
        if left(word(rpt.jj,2),7) = 'C1G0000' then
          eltname   = word(rpt.jj,4)

        if left(word(rpt.jj,2),7) = 'PKMR801' then do
          eltsubsy  = word(rpt.jj,9)
          elttype   = word(rpt.jj,11)
          eltstage  = word(rpt.jj,13)
          j = jj
          leave jj
        end /* left(word(rpt.jj,2),7) = 'PKMR801' */

      end /* jj = j + 1 to rpt.0  */

    end /* msgno = 'FPVL001' */
    when msgno = 'C1X0103' then
      do jj = j + 1 to rpt.0
        if left(word(rpt.jj,2),7) = 'C1X0104' then do
          queue ' '
          queue subword(rpt.j,2)
          queue subword(rpt.jj,2)
          jj = jj + 1
          queue subword(rpt.jj,2)
          jj = jj + 1
          queue subword(rpt.jj,2)
          j = jj + 1
          leave jj
        end /* left(word(rpt.jj,2),7) = 'C1X0104' */
        else do
          j = j + 3
          leave jj
        end /* else */
      end /* jj = j + 1 to rpt.0 */
    when msgno = 'C1G0148' then do
      queue ' '
      do jj = j to j + 2
        queue subword(rpt.jj,2)
      end /* jj = j to j + 2 */
      j = jj
    end /* msgno = 'C1G0148' */
    when msgno = 'ENMP302' then nop /* Validation started            */
    when msgno = 'ENMP304' then nop /* Validate completed with msgs  */
    when msgno = 'C1G0503' then nop /* Elt locked in other package   */
    when msgno = 'C1U0816' then nop /* Unable to get elt data        */
    when msgno = 'FPVL002' | ,
         msgno = 'FPVL003' | ,
         msgno = 'FPVL004' | ,
         msgno = 'FPVL008' | ,
         msgno = 'FPVL014' | ,
         msgno = 'PKMR798' then
      call analpkmr
    otherwise
      if pos(msgno,ignore_msgs) = 0 then
        queue subword(rpt.j,2) /* Print out all other lines as is    */
  end /* select */
end /* j = 1 to rpt.0 */

call write_report

if environ = 'FORE' then do
  address ispexec       /* Display report                            */
  "lminit dataid(cid) ddname("castrpt")"
  signal off error
  "edit dataid(&cid) macro(czmac)"
  "lmfree dataid(&cid)" /* Close down                                */
  address tso
  "free file("castrpt "casthdr castmsg)"
  if repddn = 'BSTRPTS' then
    "free f(bstrpts)"
end /* environ = 'FORE' */

exit

/*---------------------- S U B R O U T I N E S ----------------------*/

/*-------------------------------------------------------------------*/
/*  Initialise variables                                             */
/*-------------------------------------------------------------------*/
Initialise:

signal on error name exception
msgcount = 0
msglist  = ''
msgs.    = ''
locklist = ''
lock.    = ''
found    = 'n'
false    = 0
true     = 1
uid      = sysvar(sysuid)
backout  = false

if environ = 'FORE' then do
  address ispexec
  "vget zscreen"
  "control errors return"
  castrpt = 'castrp'zscreen
  address tso
  g = listdsi(castrpt file) /*  Ensure that the output report        */
  if g = 0 then             /*  is not open already                  */
    call exception 12 'Cast report file is in use'
end /* environ = 'FORE' */

return /* initialise: */

/*-------------------------------------------------------------------*/
/*  Find the package cast report.                                    */
/*-------------------------------------------------------------------*/
Find_cast_report:

 ccol = 4
 /*  First try the report that you get from display package:-        */
 /*  I.e. "R - to display CAST report" screen.                       */
 /*  Read allocated dataset list to get ddname of report output      */
 null = outtrap('ddlist.')
 address tso "lista status sysnames"
 do k = ddlist.0 to 1 by -1 while found = 'n' /* Start at last dd    */
   x = pos('.'uid'.PACKAGE.H',ddlist.k)
   if x <> 0 then do
     n = k + 1
     call readrep word(ddlist.n,1)
   end /* x <> 0 */
 end /* k = ddlist.0 to 1 by -1 while found = 'n' */

 /* If we failed to find the report then try the CAST error report   */
 /* then try the current screen                                      */
 if found = 'n' then do
   address ispexec "vget zscreen"
   call readrep 'C1#'zscreen'TMPR'
 end /* found = 'n' */

 /* Try the cast report produced by PKUTIL                           */
 g = listdsi('PKGRPT1A' file)
 if g = 0 then
   call readrep 'PKGRPT1A'

 /* Try the other screens (up to 5)                                  */
 do y = 1 to 5 while found = 'n'
   if y <> zscreen then
     call readrep 'C1#'y'TMPR'
 end /* y = 1 to 5 while found = 'n' */

 if found = 'n' then call No_Cast_Rpt 'No cast report found'

return /* Find_cast_report: */

/*-------------------------------------------------------------------*/
/*  read package dataset                                             */
/*-------------------------------------------------------------------*/
Read_pkg_mast:

 ccol = 6
 prog = 'C1BR1000'

 /*  Prepare SCL                                                     */
 address tso
 if environ = 'FORE' then do
   test=msg(off)
   "free f(bstinp bstpch bstlst bstrpts sysout sysprint sortin sortout
         sortwk01 sortwk02 sortwk03)"
   test=msg(on)
 end /* environ = 'FORE' */

 /* Allocate the input dataset for the report                        */
 "alloc f(bstinp) new space(2 2) cylinders recfm(f b) lrecl(80)"
 if rc ^= 0 then call exception rc 'ALLOC of BSTINP failed'

 /* Queue up the reports command structure                           */
 queue "     REPORT  72 ."
 queue "     ENVIRONMENT * ."
 queue "     PACKAGE '"pkgid"' ."
 queue "     STATUS  IN-ED IN-AP DE APPROVED EXE AB CO BA ."
 /* Write out the commands                                           */
 "execio "queued()" diskw bstinp (finis)"
 if rc ^= 0 then call exception rc 'DISKW to BSTINP failed'

 /*  Allocate files to process SCL                                   */
 "alloc f(bstrpts) new space(1 2) tracks recfm(f b) lrecl(132)"
 if rc ^= 0 then call exception rc 'ALLOC of BSTRPTS failed'

 if environ = 'FORE' then do
   test=msg(off)
   "alloc f(bstpch) new space(1 2) tracks recfm(f b) lrecl(838)"
   if rc ^= 0 then call exception rc 'ALLOC of BSTPCH failed'
   "alloc f(bstlst) sysout(a)"
   if rc ^= 0 then call exception rc 'ALLOC of BSTLST failed'
   /* Sysprint and sysout have to be allocated                       */
   "alloc f(sysprint) sysout(a)"
   if rc ^= 0 then call exception rc 'ALLOC of SYSPRINT failed'
   "alloc f(sysout) sysout(a)"
   if rc ^= 0 then call exception rc 'ALLOC of SYSOUT failed'
   /* Sortin & sortout required for report step                      */
   "alloc f(sortin) new space(5 15) cylinders"
   if rc ^= 0 then call exception rc 'ALLOC of SORTIN failed'
   "alloc f(sortout) new space(5 15) cylinders"
   if rc ^= 0 then call exception rc 'ALLOC of SORTOUT failed'
   /* Allocate sortwk* not done dynamically                          */
   "alloc f(sortwk01) new space(5 5) cylinders"
   if rc ^= 0 then call exception rc 'ALLOC of SORTWK01 failed'
   "alloc f(sortwk02) new space(5 5) cylinders"
   if rc ^= 0 then call exception rc 'ALLOC of SORTWK02 failed'
   "alloc f(sortwk03) new space(5 5) cylinders"
   if rc ^= 0 then call exception rc 'ALLOC of SORTWK03 failed'

   address "LINKMVS" prog
   lnk_rc = rc

   address tso
   "free f(bstinp bstpch bstlst sysout sysprint sortin sortout
         sortwk01 sortwk02 sortwk03)"
   test=msg(on)
 end /* environ = 'FORE' */
 else do /* not foreground */
   "CALL *(NDVRC1) '"prog"'"
   lnk_rc = rc
 end /* else */

 if lnk_rc > 4 then do
   test=msg(off) /* Suppress messages to console                     */
   "free f(bstrpts)"
   test=msg(on)
   call exception lnkrc 'Call to Endevor failed'
 end /* lnk_rc > 4 */

 call readrep 'BSTRPTS'

 if found = 'n' then call No_Cast_Rpt 'No cast report found.'

return /* Read_pkg_mast: */

/*-------------------------------------------------------------------*/
/*  Read cast report                                                 */
/*-------------------------------------------------------------------*/
Readrep:
 arg repddn

 rpt. = ''
 rpt1. = ''
 g = listdsi(repddn file)
 if g = 0 then do
   address tso "execio * diskr" repddn "(stem rpt1. finis"
   if rc ^= 0 then call exception rc 'DISKR of BSTPCH failed'

   do i = 1 to rpt1.0
     if sysfound <> 'Y' then do /* Get the system name             */
       sysword = wordpos('SYSTEM',rpt1.i)
       if sysword > 0 then do
         nextword = sysword + 1
         c1sys = strip(word(rpt1.i,nextword),b,"'")
         if length(c1sys) = 2 then
           sysfound = 'y'
       end /* sysword > 0 */
     end /* sysfound <> 'Y' */
     if word(rpt1.i,2) = 'PKMR400I' then do
       found = 'y'  /* Start of action validation                  */
       pkmr400I = i
     end /* word(rpt1.i,2) = 'PKMR400I' */
     if word(rpt1.i,2) = 'PKMR401I' then do
       pkmr401I = i /* End of action validation                    */
       leave i
     end /* word(rpt1.i,2) = 'PKMR401I' */
   end /* i = 1 to rpt1.0 */

 end /* g = 0 */

 if found = 'y' then do
   count  = 0
   lcount = 0

   do i = pkmr400i to pkmr401i /* Only save error msgs in this sctn  */
     msgsev = right(word(rpt1.i,2),1)

     if word(rpt1.i,2) = 'C1G0501I' then
       pkgid = word(rpt1.i,7)


    if word(rpt1.i,2) = 'C1G0503E' then do /* Elt locked in other pkg*/
      lpackage = word(rpt1.i,10)
      do ii = i to 1 by -1
        if word(rpt1.ii,2) = 'C1G0000I' then do
          element = word(rpt1.ii,4)
          leave ii
        end /* word(rpt1.i,2) = 'C1G0000I' */
        if word(rpt1.ii,2) = 'C1G0506I' then do
          subsys = word(rpt1.ii,8)
          stage  = word(rpt1.ii,10)
          type   = word(rpt1.ii,12)
        end /* word(rpt1.i,2) = 'C1G0506I' */
      end /* ii = i to 1 by -1 */
      lcount      = lcount + 1
      lock.lcount = lpackage element subsys type stage
    end /* msgno = 'C1G0503' */

     if substr(rpt1.i,ccol,1) = ':' & msgsev = 'E' then do
       count = count + 1
       rpt.count = rpt1.i
       nexti = i + 1

       if word(rpt1.nexti,2) = 'C1G0000I' then do /* Element name    */
         count = count + 1
         rpt.count = rpt1.nexti
       end /* word(rpt1.nexti,2) = 'C1G0000I' */

     end /* substr(rpt1.i,ccol,1) = ':' & msgsev = 'E' */

   end /* i = pkmr400i to pkmr401i */

   do i = pkmr401i to rpt1.0 /* Only keep comp validation lines      */

     if substr(rpt1.i,ccol,1) = ':' then do
       count = count + 1
       rpt.count = rpt1.i
     end /* substr(rpt1.i,ccol,1) = ':' */

   end /* i = pkmr401i to rpt1.0 */

   rpt.0 = count
 end /* found = 'y' */

return /* Readrep: */

/*-------------------------------------------------------------------*/
/*  analyse pkmr mesages                                             */
/*-------------------------------------------------------------------*/
Analpkmr:
 compmem  = '.'
 compdsn  = '.'
 compelt  = '.'
 compenv  = '.'
 comptype = '.'
 compsub  = '.'
 compstno = '.'
 compstn  = '.'
 compfoot = '. .'
 compgen  = '. .'
 complpro = '. .'
 compsrc  = '. .'
 curstg   = '.'
 chgstg   = '.'

 do x = j+1 to rpt.0
   msg_id = left(word(rpt.x,2),7)

   select
     when msg_id        = 'C1G0000' & ,
          word(rpt.x,3) = 'INPUT'   then do
       compelt  = word(rpt.x,5)
     end /* msg_id = 'C1G0000' & ... */
     when msg_id        = 'C1G0000' & ,
          word(rpt.x,3) = 'FROM'    then do
       compdsn  = word(rpt.x,6)
     end /* msg_id = 'C1G0000' & ... */
     when msg_id = 'PKMR797' then
       curstg   = substr(word(rpt.x,7),5)
     when msg_id = 'PKMR802' then do
       compsub  = word(rpt.x,9)
       comptype = word(rpt.x,11)
       compstn  = word(rpt.x,13)
     end /* msg_id = 'PKMR802' */
     when msg_id = 'PKMR805' then
       compfoot = subword(rpt.x,9,2)
     when msg_id = 'PKMR806' then
       curstg   = word(rpt.x,8)
     when msg_id = 'PKMR807' then
       compgen  = subword(rpt.x,7,2)
     when msg_id = 'PKMR808' then
       complpro = subword(rpt.x,7,2)
     when msg_id = 'PKMR809' then
       compsrc  = subword(rpt.x,7,2)
     when msg_id = 'PKMR810' then do
       chgsys   = word(rpt.x,9)
       chgstg   = word(rpt.x,14)
     end /* msg_id = 'PKMR810' */
     when left(word(rpt.x,2),4) = 'FPVL'    | ,
          msg_id                = 'PKMR798' | ,
          msg_id                = 'PKMR799' then
       leave x
     otherwise
       queue 'x' subword(rpt.x,2)
   end /* select */
 end /* x = j+1 to rpt.0 */

 compmem = compelt /* need to investigate why compmem not in rpt     */

 j = x - 1
 msgcount  = msgcount + 1
 msgs.msgcount = ,
      msgno compmem compfoot compelt compdsn compenv compstn,
      comptype compsub compgen complpro compsrc,
      eltname eltstage elttype eltsubsy curstg chgstg

return /* Analpkmr: */

/*-------------------------------------------------------------------*/
/*  Write reformatted report                                         */
/*-------------------------------------------------------------------*/
Write_report:

 queue ' '

 /* First write out any element locked in another package messages   */
 lock.0 = lcount
 if lcount > 2 then call sort_locks

 prevpkg  = ''
 prevlock = ''
 do i = 1 to lock.0
   if lock.i = prevlock then iterate /* Duplicate locks              */
   if word(lock.i,1) ^= prevpkg then do
     queue ' '
     lpkgid = word(lock.i,1)
     if pos(lpkgid,locklist) = 0 then do
       locklist = locklist lpkgid
       queue 'C1G0503E  ELEMENT(S) UNAVAILABLE - RESERVED BY PKG' ,
             word(lock.i,1)
       queue '          Element:' word(lock.i,2)
       queue '            Subsystem:' word(lock.i,3) ,
             'Type:' left(word(lock.i,4),8) ,
             'Stage:' word(lock.i,5)
     end /* pos(lpkgid,locklist) = 0 */
     prevpkg  = word(lock.i,1)
     prevlock = lock.i
   end /* word(lock.i,1) <> prevpkg */
   else do
     queue '          Element:' word(lock.i,2)
     queue '            Subsystem:' word(lock.i,3) ,
           'Type:' left(word(lock.i,4),8) ,
           'Stage:' word(lock.i,5)
   end /* else */
 end /* i = 1 to lcount */

 /* Second write out any component validation messages               */
 msgs.0 = msgcount
 if msgcount > 2 then call sort_msgs

 prevcomp = ''
 prevmsgs = ''
 do i = 1 to msgs.0
   if msgs.i = prevmsgs then iterate /* Duplicate msg e.g. BINDBACK  */
   call set_vars
   if subword(msgs.i,1,16) <> prevcomp then do
     queue ' '
     msgid = word(msgs.i,1)
     if pos(msgid,msglist) = 0 then
       msglist = msglist msgid
     interpret "call" msgid
     call write_elt_info
     prevcomp = subword(msgs.i,1,16)
     prevmsgs = msgs.i
   end /* subword(msgs.i,1,16) <> prevcomp */
   else
     call write_elt_info
 end /* i = 1 to msgs.0 */

 queue ' '
 queue ' '
 /* Write out the help messages                                      */
 if environ = 'FORE' then
   "newstack"
 else do /* Batch only */
   queue '---------------------------------------------------------------------'
   queue 'NOTES:'
   queue ' '
 end /* else */

 msghelp = 'FPVL002 FPVL003 FPVL004 FPVL008 FPVL014'

 do i = 1 to words(msglist)
   msgid = word(msglist,i)
   if wordpos(msgid,msghelp) > 0 then /* Msgs with msg help txt      */
    interpret "call" msgid"M"
 end /* i = 1 to words(msglist) */

 call foottext /* Write out the footer for the output report         */

 if environ = 'FORE' then do
   /* Write to a temp dataset so that the edit macro can pick it up  */
   "alloc file(CASTMSG) space(15,20) tracks reuse lrecl(132)"
   if rc ^= 0 then call exception rc 'ALLOC of CASTMSG failed'
   "execio" queued() "diskw CASTMSG ( finis"
   if rc ^= 0 then call exception rc 'DISKW to CASTMSG failed'
   "delstack"
 end /* environ = 'FORE' */
 queue ''
 address tso
 "execio * diskw "castrpt" ( finis"
 if rc ^= 0 then call exception rc 'DISKW to' castrpt 'failed'

return /* Write_report: */

/*-------------------------------------------------------------------*/
/*  Set output variables                                             */
/*-------------------------------------------------------------------*/
Set_vars:

 msgno    = word(msgs.i,1)
 eltname  = word(msgs.i,17)
 eltstage = word(msgs.i,18)
 elttype  = word(msgs.i,19)
 eltsubsy = word(msgs.i,20)
 compmem  = word(msgs.i,2)
 compfoot = word(msgs.i,3)
 compelt  = word(msgs.i,5)
 compdsn  = word(msgs.i,6)
 compenv  = word(msgs.i,7)
 compstn  = word(msgs.i,8)
 comptype = word(msgs.i,9)
 compsub  = word(msgs.i,10)
 compgen  = subword(msgs.i,11,2)
 complpro = subword(msgs.i,13,2)
 compsrc  = subword(msgs.i,15,2)
 curstg   = word(msgs.i,21)
 chgstg   = word(msgs.i,22)

return /* Set_vars: */

/*-------------------------------------------------------------------*/
/*  PKMR791 start of cast errors                                     */
/*-------------------------------------------------------------------*/
PKMR791:
 queue subword(rpt.j,2)
 queue ' '

return /* PKMR791: */

/*-------------------------------------------------------------------*/
/*  PKMR799 end of cast errors                                       */
/*-------------------------------------------------------------------*/
PKMR799:
 queue ' '
 queue ' '
 queue subword(rpt.j,2)

return /* PKMR799: */

/*-------------------------------------------------------------------*/
/*  FPVL001 messages                                                 */
/*-------------------------------------------------------------------*/
FPVL001:
return /* FPVL001: */

/*-------------------------------------------------------------------*/
/*  FPVL002 messages                                                 */
/*-------------------------------------------------------------------*/
FPVL002:
 if pos('.OLD',compdsn) > 0 then do
   queue msgno'E For input component' compelt 'can',
         'be ignored as the input'
   queue '            dataset name contains .OLD -' compdsn
 end /* pos('.OLD',compdsn) > 0 */
 else do
   queue msgno'E Input component' compelt 'is not in Endevor'
   queue '  The Component was input from' compdsn'('compmem')'
   queue '      Element:' compelt 'Type:' comptype 'Subsystem:' compsub ,
         'Stage:' compstn
 end /* else */
 queue '  The above component is used by the following element(s):'

return /* FPVL002: */

/*-------------------------------------------------------------------*/
/*  FPVL002 message help text                                        */
/*-------------------------------------------------------------------*/
FPVL002M:
 queue ' FPVL002E messages:-'
 queue '  If an input component dataset name has .OLD then you should'
 queue '  consider adding the component to your system and promoting it as'
 queue '  as it is not owned by anyone at the moment.'
 queue '  Otherwise the input component element has been deleted from'
 queue '  Endevor'
 queue ' '

return /* FPVL002M: */

/*-------------------------------------------------------------------*/
/*  FPVL003 messages                                                 */
/*-------------------------------------------------------------------*/
FPVL003:
 select
   when comptype = 'BIND' | comptype = 'SPDEF' then
     queue msgno'E For input component' compelt 'can be ignored',
           'for type' comptype
   when elttype = 'BIND' | elttype = 'SPDEF' then do
     queue msgno'E Program' compelt 'type' comptype 'has been',
           'regenerated but not the'
     queue '        ' elttype 'element.'
     queue '         This can be ignored but you may want to',
           'regenrate the' elttype
     queue '         element to update DB2.'
   end /* elttype = 'BIND' | elttype = 'SPDEF' */
   when comptype = 'COPYBOOK' & compsrc = compfoot then do
     queue msgno'E For input component' compelt 'can be ignored as',
           'copybook element'
     queue '          has been regenerated'
   end /* comptype = 'COPYBOOK' & compsrc = compfoot */
   otherwise do
     backedout = 'N'
     /* If the input component is at stage P is it backed out?       */
     if compstn  = 'P' then do
       /* Call the CSV API to get the element info                   */
       inp.1 = '  LIST ELEMENT' compelt
       inp.2 = '    FROM ENV PROD SYS' left(compsub,2) ,
               'SUB' left(compsub,2)'1'
       inp.3 = '         TYP' comptype 'STA P'
       inp.4 = '    OPTIONS NOSEARCH NOCSV .'
       inp.0 = 4
       call csv_rpt
       if csv.0 > 0 then /* The elment was found                     */
         if substr(csv.1,821,16) ^= substr(csv.1,853,16) then
           backedout = 'Y' /* Pkg source id ^= pkg output id         */
     end /* compstn = 'P' */
     if backedout = 'N' then do
       queue msgno'E The version of input component' compelt 'used has'
       queue '         been superseded or deleted'
       queue '  The component was input from' compdsn'('compmem') with'
       queue '  the following footprint:'
       queue '      Element:' compelt 'Type:' comptype 'Subsystem:',
             compsub 'Stage:' compstn
       queue '        timestamp:     ' compfoot
       if complpro <> '. .' | compgen <> '. .' | compsrc <> '. .' then
         queue '  The current version of' compelt ,
               'in Endevor has the following timestamps:'
       if complpro <> '. .' then
         queue '        last processor:' complpro
       if compgen <> '. .' then
         queue '        generate:      ' compgen
       if compsrc <> '. .' then
         queue '        source:        ' compsrc
     end /* compstn = 'P' */
     else do
       queue msgno'E Input component' compelt 'has been backed out.'
       queue '      Element:' compelt 'Type:' comptype 'Subsystem:',
             left(compsub,2)'1 Stage: P'
       queue '  Ideally you should re-promote the previous version',
             'of' compelt
       queue '    in order to prevent further cast errors.'
       backout = true
     end /* else */
   end /* otherwise */
 end /* select */
 queue '  The above component is used by the following element(s):'

return /* FPVL003: */

/*-------------------------------------------------------------------*/
/*  FPVL003 message help text                                        */
/*-------------------------------------------------------------------*/
FPVL003M:
 queue ' FPVL003E messages:-'
 if backout then do
   queue '  If the input component has been backed out then it will' ,
         'be stated'
   queue '  above and you should follow the given instructions.' ,
         'Otherwise'
 end /* backout */
 queue '  The input component has been updated since you added/updated'
 queue '  or generated the element.'
 queue '  You may wish to generate your program to pick up the'
 queue '  latest version of the input component and then re-test.'
 queue ' '

return /* FPVL003M: */

/*-------------------------------------------------------------------*/
/*  FPVL004 messages                                                 */
/*-------------------------------------------------------------------*/
FPVL004:
 if compstn >= eltstage then do
   queue msgno'E A new version of input component' compelt ,
         'has been found in'
   queue '           stage' eltstage 'of subsystem' compsub
   queue '         The version used is in a higher stage than' eltstage
 end /* compstn >= eltstage */
 else do
   queue msgno'E The version of' compelt 'used' ,
         'is still in a prior stage to' eltstage
 end /* else */
 queue '  The component was input from' compdsn'('compmem') with the'
 queue '  following footprint:'
 queue '      Element:' compelt 'Type:' comptype 'Subsystem:' compsub ,
       'Stage:' compstn
 queue '  The above component is used by the following element(s):'

return /* FPVL004: */

/*-------------------------------------------------------------------*/
/*  FPVL004 messages help text                                       */
/*-------------------------------------------------------------------*/
FPVL004M:
 queue ' FPVL004E messages:-'
 queue '  If the input component is in a prior stage then consider'
 queue '  moving the input component to the current stage then include'
 queue '  it in your package.'
 queue '  If there is a new version in the current stage and the'
 queue '  version of the input component that was used is in a higher'
 queue '  stage then consider recompiling and re testing your program.'
 queue '  If the component is common and in another system then'
 queue '  you will have to set VALIDATE COMPONENTS = W in order to cast the'
 queue '  package, and bear in mind that the owner of the common component,'
 queue '  needs to move it to production.'
 queue ' '

return /* FPVL004M: */

/*-------------------------------------------------------------------*/
/*  FPVL008 messages                                                 */
/*-------------------------------------------------------------------*/
FPVL008:
 if comptype = 'BIND' then
   queue msgno'E For input component' compelt 'can be ignored',
         'for type' comptype
 else do
   compsys = left(compsub,2)
   eltsys  = left(eltsubsy,2)
   if substr(compdsn,7,2) = 'RG'   & ,
      compsys            ^= eltsys & ,
      chgsys              = eltsys then do
     queue msgno'E There are duplicate versions of' comptype compelt ,
           'in Endevor.'
     queue '  The common version is from the     ' compsys 'system'
     queue '  There is a duplicate version in the' eltsys 'system'
     queue '  The' compsys 'version has been used.'
     queue '  You should add a DELETE action for the' eltsys ,
           'version of'
     queue ' ' comptype compelt ,
           'to this package to avoid further cast errors.'
   end /* substr(compdsn,7,2) = 'RG' & ... */
   else do
     queue msgno'E',
           'The element being moved does not use the first found'
     queue '         copy of input component' compelt 'type' comptype
     queue '         The input component used currently resides in' ,
           'stage' curstg
     queue '         The changed input component resides in stage' ,
           chgstg
     queue '  The component was input from' compdsn'('compmem ,
           ') with the'
     queue '  following footprint:'
     queue '      Element:' compelt 'Type:' comptype 'Subsystem:',
           compsub 'Stage:' compstn
   end /* else */
 end /* else */
 queue '  The above component is used by the following element(s):'

return /* FPVL008: */

/*-------------------------------------------------------------------*/
/*  FPVL008 message help text                                        */
/*-------------------------------------------------------------------*/
FPVL008M:
 queue ' FPVL008E messages:-'
 queue '  If the element in error is a program then consider'
 queue '  regenerating and re-testing your program with the latest'
 queue '  version of the copybook.'
 queue ' '

return /* FPVL008M: */

/*-------------------------------------------------------------------*/
/*  FPVL014 messages                                                 */
/*-------------------------------------------------------------------*/
FPVL014:
 queue msgno'E The failed flag is set for input component' compelt
 queue '  The component was input from' compdsn'('compmem') with the'
 queue '  following footprint:'
 queue '      Element:' compelt 'Type:' comptype 'Subsystem:' compsub ,
       'Stage:' compstn
 queue '  The above component is used by the following element(s):'

return /* FPVL014: */

/*-------------------------------------------------------------------*/
/*  FPVL014 message help text                                        */
/*-------------------------------------------------------------------*/
FPVL014M:
 queue ' FPVL014E messages:-'
 queue '  You must regenerate the element.'
 queue ' '

return /* FPVL014M: */

/*-------------------------------------------------------------------*/
/*  PKMR798 messages                                                 */
/*-------------------------------------------------------------------*/
PKMR798:
 queue msgno'E COMMENTED SCL MOVE ACTIONS ADDED TO PACKAGE'
 queue '  There are input components that are used by elements in' ,
       'this package'
 queue '  that are not being moved as part of this package.'
 queue '  Endevor has added commented out MOVE SCL actions to your' ,
       'Package.'
 queue '  The commented out SCL statements are for the following' ,
       'elements:'

 /* Call the CSV report to get the package SCL                       */
 inp.1 = '  LIST PACKAGE SCL FROM PACKAGE ID' pkgid 'OPTIONS NOCSV.'
 inp.0 = 1
 call csv_rpt

 /* Analyse the SCL to find the commented out SCL                    */
 samesys = false /* Is the input component from the same system?     */
 diffsys = false /* Is the input component from a different system?  */

 /* Loop backwards through the SCL to only find the most recently    */
 /* added SCL.                                                       */
 do zzz = csv.0 to 1 by -1
   do xxx = 775 to 55 by -80 /* Multiple SCL lines per CSV record    */
     scl = substr(csv.zzz,xxx,79)
     if left(scl,1) = '*' then
       select
         when subword(scl,2,2) = 'YOU MAY' then
           leave zzz
         when word(scl,2) = 'MOVE' then do
           cmntd_elt = left(strip(word(scl,4),,"'"),8)
           /* Write out the input component details                  */
           queue '     MOVE' cmntd_elt cmntd_env cmntd_sys cmntd_sub ,
                 cmntd_typ cmntd_stg
         end /* word(scl,2) = 'MOVE' then */
         when word(scl,2) = 'FROM' then do
           cmntd_env = strip(word(scl,4),,"'")
           cmntd_sys = strip(word(scl,6),,"'")
           cmntd_sub = strip(word(scl,8),,"'")
           if cmntd_sys  = c1sys then samesys = true
           if cmntd_sys ^= c1sys then diffsys = true
         end /* word(scl,2) = 'FROM' */
         when word(scl,2) = 'TYPE' then do
           cmntd_typ = left(strip(word(scl,3),,"'"),8)
           cmntd_stg = word(scl,5)
         end /* word(scl,2) = 'TYPE' */
         otherwise nop
       end /* select */
   end /* xxx = 55 to 775 by 80 */
 end /* zzz = 1 to csv.0 */

 queue ' '
 select
   when samesys then do
     queue '  You must either'
     queue '   - Edit the package SCL and uncomment the SCL to' ,
           'MOVE the elements.'
     queue '  or'
     queue '   - Ensure that the elements are being moved in another' ,
           'package.'
   end /* samesys */
   when diffsys & ^samesys then do
     queue '  You must ensure that the elements are being moved in' ,
           'another package.'
   end /* diffsys & ^samesys */
   otherwise nop
 end /* select */

 queue ' '
 queue '  Failure to do this will result in unsupportable code in' ,
       'production.'

return /* PKMR798: */

/*-------------------------------------------------------------------*/
/*  Footer text                                                      */
/*-------------------------------------------------------------------*/
Foottext:

if c1sys = 'LN' | c1sys = 'LJ' then do /* Domestic insurance users   */
 queue ' If after analysing the cast errors you are satisfied that the cast'
 queue ' errors do not affect your implementation you can contact ADSM Code to'
 queue ' discuss and resolve the error.'
 queue ' NOTE - You should be aware that overriding the cast errors can make'
 queue ' the program unsupportable, you are responsible for problems arising as'
 queue ' a result of this action.'
 queue ' '
 queue ' N.B. Elements are not regenerated/compiled when you move them.'
 queue ' '
 queue ' For further assistance please contact ADSM Code on'
 queue '                         VERTIZOS@kyndryl.com'
end /* c1sys = 'LN' | c1sys = 'LJ' */
else do /* Banking users */
 queue ' If after analysing the cast errors you are satisfied that the'
 queue ' cast errors do not affect your implementation you can override them'
 queue ' by setting the "VALIDATE COMPONENTS" flag to "W" on the cast'
 queue ' package screen.'
 queue ' NOTE - You should be aware that using VALIDATE COMPONENTS = W'
 queue ' bypasses package errors and can make the program unsupportable,'
 queue ' you are responsible for problems arising as a result of this'
 queue ' action.'
 queue ' '
 queue ' '
 queue ' '
 queue ' N.B. Elements are not regenerated/compiled when you move them'
 queue ' '
 queue ' For more help then please contact Endevor Support on '
 queue '                         VERTIZOS@kyndryl.com'
end /* else do */

return /* Foottext: */

/*-------------------------------------------------------------------*/
/*  Write element information                                        */
/*-------------------------------------------------------------------*/
Write_elt_info:

 if msgid ^= 'PKMR798' then
   queue '       ' eltname '   Type:' elttype 'Subsystem:' eltsubsy ,
         'Stage:' eltstage

return /* Write_elt_info: */

/*-------------------------------------------------------------------*/
/*  Bubble sort for messages                                         */
/*-------------------------------------------------------------------*/
Sort_msgs:
Procedure Expose msgs. false true

 sorted = false

 do i = msgs.0 to 1 by -1 until sorted
   sorted = true /* Assume the items are sorted                      */
   do j = 2 to i
     m = j-1
     if msgs.m > msgs.j then do /* If the items are out of order swap*/
       a      = msgs.m
       msgs.m = msgs.j
       msgs.j = a
       sorted = false /* We swapped two items, so were not sorted yet*/
     end /* if msgs.m > msgs.j then do */
   end /* j = 2 to i */
 end /* i = msgs.0 to 1 by -1 until sorted = 1 */

return /* Sort_msgs: */

/*-------------------------------------------------------------------*/
/*  Bubble sort for locked element messages                          */
/*-------------------------------------------------------------------*/
Sort_locks:
Procedure Expose lock. false true

 sorted = false

 do i = lock.0 to 1 by -1 until sorted
   sorted = true /* Assume the items are sorted                      */
   do j = 2 to i
     m = j - 1
     if lock.m > lock.j then do /* If the items are out of order swap*/
       a      = lock.m
       lock.m = lock.j
       lock.j = a
       sorted = false /* We swapped two items, so were not sorted yet*/
     end /* if lock.m > lock.j then do */
   end /* j = 2 to i */
 end /* i = lock.0 to 1 by -1 until sorted */

return /* Sort_locks: */

/*-------------------------------------------------------------------*/
/*  No cast report found                                             */
/*-------------------------------------------------------------------*/
No_Cast_Rpt:

 signal off error
 arg msgtext

 address tso
 delstack /* Clear down the stack                                    */

 if environ = 'FORE' then do
   address ispexec /* Set up short error message                     */
   if msgtext <> '' then zedsmsg = msgtext
                    else zedsmsg = 'Cast report error'

   /* Long message set up                                            */
   zedlmsg = 'No cast report found,',
             ' please ensure package has been cast.'

   "setmsg msg(isrz001)" /* ISPF message set                         */
   "lmfree dataid('id')"

   test=msg(off) /* Suppress messages                                */
   address tso "free file("castrpt")"
   test=msg(on) /* turn messages back on                             */

 end /* environ = 'FORE' */
 else do /* Not foreground */
   say 'CZ: Castrep error'
   if msgtext <> '' then do /* Message text provided                 */
     say 'CZ: '
     say 'CZ: Package ID :' pkgid
     say 'CZ:' msgtext
     say 'CZ: '
   end /* msgtext <> '' */
   else do
     say 'CZ: The Endevor formatted cast report failed'
     say 'CZ: Please check the package has been cast'
     say 'CZ: '
   end /* else */
 end /* else */

exit 12

/*-------------------------------------------------------------------*/
/* CSV_RPT - Execute the CSV report.                                 */
/*-------------------------------------------------------------------*/
csv_rpt:

 address tso
 /* Free incase there are hangovers. Do not code an exception call   */
 test = msg(off)
 "free f(bsterr c1msgsa csvmsgs1 apiextr csvipt01)"
 test = msg(on)

 "alloc f(csvipt01) new space(1 1) tracks recfm(f b) lrecl(80)"
 if rc ^= 0 then call exception rc 'ALLOC of csvipt01 failed.'

 /* Write the input for the CSV utility                              */
 'execio' inp.0 'diskw csvipt01 (stem inp. finis)'
 if rc ^= 0 then call exception rc 'DISKW to csvipt01 failed.'

 /* Allocate files to process SCL                                    */
 "alloc f(apiextr) new space(1 1) tracks recfm(f b) lrecl(1600)"
 if rc ^= 0 then call exception rc 'ALLOC of APIEXTR failed.'

 /* Allocate the necessary datasets                                  */
 test = msg(off)
 "alloc F(C1MSGSA)  new space(1 1) tracks recfm(f b a) lrecl(134)"
 if rc ^= 0 then call exception rc 'ALLOC of C1MSGSA failed.'
 "alloc f(CSVMSGS1) new space(1 1) tracks recfm(f b a) lrecl(134)"
 if rc ^= 0 then call exception rc 'ALLOC of CSVMSGS1 failed.'
 "ALLOC F(BSTERR) SYSOUT(a)"
 if rc ^= 0 then call exception rc 'ALLOC of BSTERR failed.'
 test = msg(on)

 /* Invoke the CSV utility                                           */
 if environ = 'FORE' then
   address "LINKMVS" 'BC1PCSV0'
 else
   "CALL   *(NDVRC1) 'BC1PCSV0'"
 lnk_rc = rc

 if lnk_rc > 0 then do
   "execio * diskr CSVMSGS1 (stem c1. finis"
   do i = 1 to c1.0
     say c1.i
   end /* i = 1 to c1.0 */
   "execio * diskr C1MSGSA  (stem c1. finis"
   do i = 1 to c1.0
     say c1.i
   end /* i = 1 to c1.0 */
   call exception lnk_rc 'Call to BC1PCSV0 failed'
 end /* rc > 0 */

 "free f(bsterr c1msgsa csvmsgs1 csvipt01)"

 csv.0 = 0
 g = listdsi(APIEXTR file) /* Check for output                       */
 if g = 0 then do
   "execio * diskr APIEXTR (stem csv. finis"
   if rc ^= 0 then call exception rc 'DISKR of APIEXTR failed.'
   "free f(apiextr)"
 end /* g = 0 */

return /* csv_rpt: */

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
   address tso "free f("castrpt "casthdr castmsg bstinp bstpch bstlst" ,
           "sysout sysprint sortin sortout c1msgsa csvmsgs1 csvipt01" ,
           "bstrpts bsterr apiextr sortwk01 sortwk02 sortwk03)"
   address tso 'delstack' /* Clear down the stack                    */
   z = msg(on)
 end /* addr ^= 'MVS' */

 if return_code < 0 then return_code = 12 /* - RCs can be invalid    */

 if addr = 'ISPF' then do
   zispfrc = return_code
   address ispexec "vput (zispfrc) shared"
 end /* addr = 'ISPF' */

exit return_code
