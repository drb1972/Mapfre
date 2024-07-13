/*-----------------------------REXX----------------------------------*\
 *                                                                   *
 *   This is invoked when EVGRJOBD runs (or the NDVADMIN harness)    *
 *   It checks if there are any sequential files created by change   *
 *   records being assigned.                                         *
 *   The Rjob is built in to PGEV.AUTO.CMJOBS and demanded on to     *
 *   CA7P04 using the CA7 API.                                       *
 *                                                                   *
 *   Calls:      Rexx      - CMOFFSET in PGEV.BASE.REXX              *
 *               Skeletons - CMSAOL   CMSCDRC1 CMSEXER  CMSPAX       *
 *                           CMSBBBR  CMSCDRC2 CMSINFR  CMSPRSR      *
 *                           CMSBCKR  CMSCDUP1 CMSJOBR  CMSPWARN     *
 *                           CMSBPKG  CMSCDUP2 CMSLIST  CMSSHP1R     *
 *                           CMSCCCR  CMSEDTR  CMSNDRA  CMSSHP2R     *
 *                           CMSCD    CMSEMAIL CMSNDRC  CMSSIGN      *
 *                           CMSCDINF CMSENDR  CMSNDRM  CMSSINR      *
\*-------------------------------------------------------------------*/
signal on syntax  name exception /* Required for ISPF batch only     */
signal on failure name exception /* Required for ISPF batch only     */

trace n
arg hlq /* passed from the batch job                                 */

assignd = hlq'.NCMR.ASSIGN' /* Dataset list for running listcat      */

/* Set default values depending on which system it is running on     */
/* testchk compares char 1 of the current plex against letter S.     */
plxid    = MVSVAR(SYSPLEX) /* GSI plexes are PLEX**                  */
sysid    = MVSVAR(SYSNAME) /* GSI lpars are **OS                     */
plxclone = right(plxid,2)
/* Use Q1 rather than T1 on Tplex - for CD dataset */
If plxclone = 'T1' then plxclone = 'Q1'
sysid1   = left(sysid,1) /* 1st char of LPAR                         */

testchk  = pos(sysid1,'S') /* if > 0 implies in testlist             */

if testchk > 0 then cdstc = "01" /* test systems                     */
               else cdstc = "02"

/*   Set up more variables for later                                 */
test     = "live"
dsn1     = "&DSN1"
ndmsrce  = "&&NDMSRCE"
xlcc     = "&&XLCC"
xnwc     = "&&XNWC"
xdtm     = "&&XDTM"
hdel     = "&&HDEL"
cpysrce  = "&&CPYSRCE"
cmstemp  = "&&CMSTEMP"
datalib  = "&DATALIB"
evbase   = "PGEV"                     /* hlq for base datasets       */
proclib  = "PGOS.BASE.PROCLIB"
cdmsgf   = "PGTN.CD.MSG"
cdnetmap = "PGTN.CD.CD"cdstc"."plxclone".NETMAP"
destdsn  = "PGEV.BASE.DATA(DESTINFO)" /* shipment variables          */
endvdsn  = "PGEV.BASE.DATA(DESTSYS)"  /* valid destinations          */
endvvar  = "PGEV.BASE.DATA(DESTVAR)"  /* ndvedit variables           */
ca7cls   = "CLASS=X"                  /* CA7 class for Rjobs         */
nn       = "00" /* concurrent action processing value                */

/* Get the names of the RJOB sequential files                        */
a = outtrap('cmrs.','*',concat)
address tso "LISTC LEVEL('"assignd"') NAMES"
a = outtrap('off')

if rc = 4 then do
  say 'EVASSIGN: LISTC of' assignd '= 4'
  say 'EVASSIGN: No datasets to process'
  zispfrc = 4
  address ispexec "vput (zispfrc) shared"
  exit 4
end /* rc = 4 */

/* if the listcat came back with anything other than zero then exit  */
if rc ^= 0 then call exception rc 'LISTC failed.'

cmr_no = cmrs.0 / 2 /* listcat produces two lines per cmr            */
say
say 'EVASSIGN: Number of CMRs to schedule =' cmr_no
do x = 1 to cmrs.0 /* display the output from the listcat            */
  say cmrs.x
end /* do x = 1 to cmrs.0 */
say 'EVASSIGN:'

/* Process the assigned CMR datasets                                 */
do a = 1 to cmrs.0 /* loop through the listcat output                */

  if pos(assignd,cmrs.a) > 1 then do

    dsn = strip(word(cmrs.a,3)) /* get the dsn from listcat          */

    /* Allocate the Infoman data file exclusively                    */
    "ALLOC F(SOURCE) DSNAME('"dsn"') OLD"
    if rc ^= 0 then call exception rc 'Alloc of' dsn 'failed.'

    'EXECIO 1 DISKR SOURCE (FINIS' /* Read CMR info                  */
    if rc ^= 0 then call exception rc 'EXECIO read of' dsn 'failed.'

    parse pull cmr assoc c1sy ri rest
    say 'EVASSIGN: '
    say 'EVASSIGN: The following data will be processed:-'
    rest = strip(rest,'t')
    say cmr assoc c1sy ri rest
    say 'EVASSIGN: '

    /* remove any blanks and set variables up                        */
    cmr   = strip(cmr)    /* CMR number                              */
    suf   = right(cmr,7)  /* numeric part of the CMR number          */
    rmem  = 'R'suf        /* Rjob name                               */
    bkid  = 'B'suf        /* Bjob name                               */
    pkg   = cmr'P'        /* package name                            */
    assoc = strip(assoc)  /* change data                             */
    c1sy  = strip(c1sy)   /* system affected by the package          */
    ri    = strip(ri)     /* CMR category or EMER or CMASSIGN        */

    if c1sy = 'EK' then
      address ispexec ,
        "libdef ISPSLIB dataset id('PREV.FEV1.ISPSLIB') stkadd"

    /* Some systems are excluded from the specific process           */
    /* This ensures the specific flag has not been set accidentally  */
    speciex = 'AO MT WA OD OJ OS'
    if wordpos(c1sy,speciex) ^= 0 then assoc = overlay('G',assoc,1)

    /* set some of the variables that are required later and in      */
    /* the skeletons that will be included.                          */
    currdt   = Date(S);
    currds   = substr(currdt,3,6);
    currtm   = substr(time(),1,2) || substr(time(),4,2) || ,
               substr(time(),7,2)'00'
    currts   = substr(currtm,1,6)
    shortm   = substr(currtm,1,6)

    shiphlqs = 'PGEV.SHIP.D'currds'.T'shortm
    shiphlqc = 'PGEV.SHIP.'cmr

    /* Split data supplied from CMR into variables for release job   */
    call get_cmr_data

    /* Get the destinations that this change should be propagated to */
    /* and then set up the corresponding node names for later        */
    /* transmissions                                                 */
    call get_dests

    /* Get the number of elements in the package to determine how    */
    /* many concurrent action processing tasks are spawned off.      */
    if hlq = 'PGEV' then call pack_num /* interrogate the package    */
                    else nn = 4 /* test harness value for EN$CAP DD  */

    call create_rjob

    if hlq = 'PGEV' then do /* only run for production hlq           */

      /* Use the CA7 API to demand the Rjob on                       */
      say 'EVASSIGN:'
      say 'EVASSIGN: Using the CA7 API to issue the command:-'
      say 'EVASSIGN: P04 YE DEMAND,JOB='rmem','ca7cls',JCLID=6'
      say 'EVASSIGN:'

      /* Use the CA7 API to demand the Rjob on                       */
      call @CA7RXIF("P04 YE DEMAND,JOB="rmem","ca7cls",JCLID=6")

      if result <> 0 then do /* Error encountered from CA7/rexx      */
        do x = 1 to queued() /* Loop round error messages            */
          pull ca7out.x      /* get next error message               */
          say ca7out.x       /* Print to SYSTSPRT                    */
        end /* x = 1 to queued() */
        call exception result 'CA7 demand has failed.'
      end /* result <> 0 */

      delstack /* Clear down the stack                               */

    end /* hlq = 'PGEV' */

    "FREE F(SOURCE)" /* free the Infoman data file                   */
    if rc ^= 0 then call exception rc 'FREE of' dsn 'failed.'

    if hlq = 'PGEV' then do /* only run for production hlq           */

      "DELETE '"dsn"'" /* delete the Infoman data file               */
      if rc ^= 0 then call exception rc 'DELETE of' dsn 'failed.'

    end /* hlq = 'PGEV' */

  end /* pos(assignd,cmrs.a) > 1 */

end /* a = 1 to cmrs.0 */

exit

/*---------------------- S U B R O U T I N E S ----------------------*/

/*-------------------------------------------------------------------*/
/* Set up the values passed through from the CMR                     */
/*-------------------------------------------------------------------*/
get_cmr_data:

 libtyp = substr(assoc,1,1)

 select
   when libtyp = 'G' then cmr_type = 'GLOBAL'
   when libtyp = 'S' then cmr_type = 'SPECIFIC'
   otherwise call exception 99 'Unknown CMR type.'
 end /* select */

 demand_type = substr(assoc,2,1)
 if demand_type = 'N' then demand = 'DEMAND'
 if demand_type = 'Y' then demand = 'DEMANDH'

 usename     = substr(assoc,3,7)
 index_pos   = Index(usename,#)

 if index_pos > 0 then usename = substr(usename,1,index_pos-1)

 chdate = substr(assoc,10,5) /* date in julian format                */
 chtime = substr(assoc,15,4) /* time in hhmm format                  */

 notify_name = substr(assoc,28,7)
 index_pos   = index(notify_name,#)

 if index_pos > 0 then notify_name = substr(notify_name,1,index_pos-1)

 if ri = 'EMER' then do /* if emergency record the date is 00000     */
   skdate = 'EMER CMR'
   sktime = 'RUN ASAP'
   demand = 'EM'
   notify = ',NOTIFY='notify_name /* only add notify on EM changes   */
 end /* ri = 'EMER' */
 else do
   /* Alter date and time format for skeleton detail                 */
   skdate = date('E',''chdate'','J')
   skdate = left(skdate,8) /* pad the string to 8 characters         */
   sktime = left(chtime,2)':'substr(chtime,3,2)
   sktime = left(sktime,8) /* pad the string to 8 characters         */
   notify = '' /* if standard CMR then no notify                     */
 end /* else */

return /* Get_cmr_data: */

/*-------------------------------------------------------------------*/
/*   This is invoked to determine the destinations that a change     */
/*   should be propagated to                                         */
/*   This will be determined from the file PGEV.BASE.DATA(DESTINFO)  */
/*-------------------------------------------------------------------*/
get_dests:

 address TSO

 /* Allocate PGEV.BASE.DATA(DESTSYS)                                 */
 "ALLOCATE FI(ENDDESTS) DA('"endvdsn"') SHR REUSE"
 if rc ^= 0 then call exception rc 'Alloc of ENDDESTS failed.'

 /* Populate LINE1 stem                                              */
 "EXECIO * DISKR ENDDESTS (STEM LINE1. FINIS)"
 if rc ^= 0 then call exception rc 'DISKR of ENDDESTS failed.'

 /* De-allocate PGEV.BASE.DATA(DESTSYS)                              */
 "FREE FI(ENDDESTS)"
 if rc ^= 0 then call exception rc 'FREE of ENDDESTS failed.'

 /*  Read the dests files                                            */
 /*  Assigns destinations for this ENDEVOR subsystem id and          */
 /*  sets variables for each destination                             */
 do b = 1 to line1.0
   interpret line1.b
 end  /* b = 1 to line1.0 */

 /* Look for the line in the file for the ENDEVOR system id          */
 /* or pick up the DEFAULT destinations which is the last line in    */
 /* destinations file                                                */
 /* Ignore all comment lines                                         */
 if C1SYSTEMA.c1sy = "C1SYSTEMA."c1sy ,
    then list_destsa = C1SYSTEMA.DEFAULT
    else list_destsa = C1SYSTEMA.c1sy

 x       = 1
 desta.  = " "
 desta.0 = 0

 /* Get all the destinations for this system into array "desta"      */
 do while list_destsa ^= ''
   parse var list_destsa desta.x list_destsa
   if desta.x = "" then leave
   desta.0    = x
   x          = x + 1
 end /* while list_destsa ^= '' */

 /* Allocate PGEV.BASE.DATA(DESTINFO)                                */
 "ALLOCATE FI(ENDSYS) DA('"destdsn"') SHR REUSE"
 if rc ^= 0 then call exception rc 'Alloc of ENDSYS failed.'

 /* Populate LINE2 stem                                              */
 "EXECIO * DISKR ENDSYS (STEM LINE2. FINIS)"
 if rc ^= 0 then call exception rc 'DISKR of ENDSYS failed.'

 /* De-allocate PGEV.BASE.DATA(DESTINFO)                             */
 "FREE FI(ENDSYS)"
 if rc ^= 0 then call exception rc 'FREE of ENDSYS failed.'

 do c = 1 to line2.0
   interpret line2.c
 end /* c = 1 to line2.0 */

 /* Look for the line in the file for the ENDEVOR system id          */
 /* or pick up the DEFAULT destinations which is the last line in    */
 /* destinations file                                                */
 /* Ignore all comment lines                                         */
 if C1SYSTEMB.c1sy="C1SYSTEMB."c1sy ,
    then list_destsb=C1SYSTEMB.DEFAULT
    else list_destsb=C1SYSTEMB.c1sy

 y       = 1
 destb.  = " "
 destb.0 = 0

 /* Get all the destinations for this system into array "destb"      */
 do while list_destsb ^= ''
   parse var list_destsb destb.y list_destsb
   if destb.y = "" then leave
   destb.0    = y
   y          = y + 1
 end /* while list_destsb ^= '' */

 /* Look for the line in the file for the ENDEVOR system id          */
 /* or pick up the DEFAULT destinations which is the last line in    */
 /* destinations file                                                */
 /* Ignore all comment lines                                         */
 if C1SYSTEMC.c1sy="C1SYSTEMC."c1sy ,
   then list_destsc=C1SYSTEMC.DEFAULT
   else list_destsc=C1SYSTEMC.c1sy

 z       = 1
 destc.  = " "
 destc.0 = 0

 /* Get all the destinations for this system into array "dest"       */
 do while list_destsc ^= ''
   parse var list_destsc destc.z list_destsc
   if destc.z = "" then leave
   destc.0    = z
   z          = z + 1
 end /* while list_destsc ^= '' */

return /* get_dests: */

/*-------------------------------------------------------------------*/
/* Establish how many elements are moved in the package              */
/*-------------------------------------------------------------------*/
pack_num:
 address tso

 /* Free incase there are hangovers. Do not code an exception call */
 test=msg(off)
 "free f(bsterr c1msgsa csvmsgs1 apiextr apiprint csvipt01)"
 test=msg(on)

 "alloc f(csvipt01) new space(1 1) tracks recfm(f b) lrecl(80)"
 if rc ^= 0 then call exception rc 'ALLOC of csvipt01 failed.'

 /* Build the input to the report execution                          */
 queue "  LIST PACKAGE ACTION FROM PACKAGE ID" pkg
 queue "  OPTIONS NOCSV . "
 'execio' queued() 'diskw csvipt01 (finis)'
 if rc ^= 0 then call exception rc 'DISKW to csvipt01 failed.'

 /* Allocate files to process SCL                                    */
 "alloc f(apiextr) new space(1 1) tracks recfm(f b) lrecl(1600)"
 if rc ^= 0 then call exception rc 'ALLOC of APIEXTR failed.'
 "alloc f(apiprint) sysout(*)"
 if rc ^= 0 then call exception rc 'ALLOC of APIPRINT failed.'

 /* allocate the necessary datasets                                  */
 test=msg(off)
 "ALLOC F(C1MSGSA) SYSOUT(Z)"
 if rc ^= 0 then call exception rc 'ALLOC of c1msgsa failed.'
 "ALLOC F(CSVMSGS1) SYSOUT(Z)"
 if rc ^= 0 then call exception rc 'ALLOC of csvmsgs1 failed.'
 "ALLOC F(BSTERR) SYSOUT(Z)"
 if rc ^= 0 then call exception rc 'ALLOC of BSTERR failed.'
 test=msg(on)

 if environ = 'FORE' then do
   /* invoke the program                                             */
   address "LINKMVS" 'BC1PCSV0'
   lnk_rc = rc
   address tso
 end /* environ = 'FORE' */
 else do /* running in batch                                         */
   "CALL *(NDVRC1) 'BC1PCSV0'"
   lnk_rc = rc
 end /* else */

 "free f(bsterr c1msgsa csvmsgs1 csvipt01)"
 if rc ^= 0 then call exception rc 'FREE of files failed.'

 if lnk_rc > 0 then do /* error found in running the routine         */
   "free f(apiextr)"
   call exception lnk_rc 'Call to NDVRC1 failed'
 end /* lnk_rc > 4 */

 g = listdsi(apiextr file)

 /* listdsi didn't show the file exists                              */
 if g > 0 then
   call exception g 'LISTDSI of APIEXTR file failed'
 else do
   address tso "execio * diskr apiextr (STEM REP. FINIS"
   "free f(apiextr)"

   /* determine how many cap tasks                                   */
   select
     when rep.0 < 20 then nn = '00'
     when rep.0 >= 20 & rep.0 < 50 then nn = '02'
     when rep.0 >= 50 & rep.0 < 100 then nn = '03'
     when rep.0 >= 100 then nn = '04'
     otherwise nn = '00' /* default to 00                            */
   end /* select */

 end /* else */

return /* pack_num: */

/*-------------------------------------------------------------------*/
/* Create the sequential file to allocate on the ISPFILE to build    */
/* the Rjob JCL and the CA7 batch commands.                          */
/* Allocate a new dataset for use as the sysin to the SHIPMENT       */
/* step which has all the required destinations                      */
/*-------------------------------------------------------------------*/
create_rjob:

 if ri = 'EMER' then emergncy = 'YES'
                else emergncy = 'NO'

 address ispexec
 FTOPEN

 /* Include all the bits of JCL necessary to create the full R job   */

 FTINCL CMSENDR /* ENDEVOR steps                                     */
 if rc ^= 0 then call exception rc 'FTINCL of CMSENDR failed.'

 FTINCL CMSEXER /* PACKAGE execution                                 */
 if rc ^= 0 then call exception rc 'FTINCL of CMSEXER failed.'

 FTINCL CMSPAX  /* PAX up any USS files/directories                  */
 if rc ^= 0 then call exception rc 'FTINCL of CMSPAX failed.'

 /* Element signout for specific changes                             */
 If libtyp = 'S' then FTINCL CMSSIGN
 if rc ^= 0 then call exception rc 'FTINCL of CMSSIGN failed.'

 FTINCL CMSSHP1R /* FIRST BIT OF PACKAGE SHIPMENT STEP               */
 if rc ^= 0 then call exception rc 'FTINCL of CMSSHP1R failed.'

 do e = 1 to desta.0 /* SHIPMENT statement for each destination      */
   destid = desta.e

   FTINCL CMSSINR
   if rc ^= 0 then call exception rc 'FTINCL of CMSSINR failed.'
 end

 FTINCL CMSSHP2R /* LAST BIT OF PACKAGE SHIPMENT STEP                */
 if rc ^= 0 then call exception rc 'FTINCL of CMSSHP2R failed.'

 /* Backout package for specific changes                             */
 if libtyp = 'S' then FTINCL CMSBPKG
 if rc ^= 0 then call exception rc 'FTINCL of CMSBPKG failed.'

 FTINCL CMSLIST /* Delete empty listing backup files                 */
 if rc ^= 0 then call exception rc 'FTINCL of CMSLIST failed.'

 /* Add JOBCARD for each Cjob & Bjob created by SHIPMENT             */
 do f = 1 to desta.0
   destid   = desta.f
   cjobdset = shiphlqs'.'destid'.AHJOB'
   bjobdset = shiphlqs'.'destid'.CHJOB'
   stpnme   = 'J'destid /* Stepname eg JPLEXP1                       */

   FTINCL CMSJOBR
   if rc ^= 0 then call exception rc 'FTINCL of CMSJOBR failed.'
 end /* f = 1 to desta.0 */

 /* Add PACKAGE BACKOUT for the LOCAL node                           */
 do g = 1 to destb.0
   destid   = destb.g
   bjobdset = shiphlqs'.'destid'.CHJOB'
   stepname = "B"destid

   if cd.destid = "LOCAL" then FTINCL CMSBCKR
   if rc ^= 0 then call exception rc 'FTINCL of CMSBCKR failed.'

 end /* g = 1 to destb.0 */

 /* Add a step to Bjob if remote submission for other dest is reqd   */
 do h = 1 to desta.0
   destid   = desta.h
   bjobdset = shiphlqs'.'destid'.CHJOB'
   rmts     = rmtsub.destid
   stepname = "D"destid

   FTINCL CMSBBBR
   if rc ^= 0 then call exception rc 'FTINCL of CMSBBBR failed.'
 end /* h = 1 to desta.0 */

 /* Add INFO/MAN update to each C job created by R job               */
 do j = 1 to desta.0
   destid   = desta.j
   cjobdset = shiphlqs'.'destid'.AHJOB'
   bjobdset = shiphlqs'.'destid'.CHJOB'
   stepname = "I"destid

   FTINCL CMSINFR
   if rc ^= 0 then call exception rc 'FTINCL of CMSINFR failed.'

 end /* j = 1 to desta.0 */

 /* Add a step to C job if remote submission for another dest is     */
 /* required                                                         */
 do k = 1 to desta.0
   destid   = desta.k
   cjobdset = shiphlqs'.'destid'.AHJOB'
   rmts     = rmtsub.destid
   stepname = "R"destid

   FTINCL CMSCCCR
   if rc ^= 0 then call exception rc 'FTINCL of CMSCCCR failed.'

 end /* k = 1 to desta.0 */

 FTINCL CMSPRSR /* Create PROCESS file and NDM info                  */
 if rc ^= 0 then call exception rc 'FTINCL of CMSPRSR failed.'

 FTINCL CMSNDRM /* Stepname & sysexec declaration                    */
 if rc ^= 0 then call exception rc 'FTINCL of CMSNDRM failed.'

 /* Add rexx to clone the NDM destination from the parent plex       */
 /* by looping through the C1SYSTEMC string and include the correct  */
 /* parent and child variables.                                      */
 do l = 1 to destc.0

   destid   = destc.l /* Get the variable from the array             */
   destl    = parent.destid
   cpymem   = destl'P' /* get which system is the parent             */
   srcdsn   = 'MODEL'substr(destl,5,1) /* input JCL ddname           */
   cjobin   = 'CJOB'substr(destl,5,1)  /* Cjob dsn ddname            */
   bjobin   = 'BJOB'substr(destl,5,1)  /* Bjob dsn ddname            */

   /* Resolve variables from the destvar/destinfo                    */
   cjobcpy  = shiphlqs'.'destl'.AHJOB'
   bjobcpy  = shiphlqs'.'destl'.CHJOB'

   cjobdset = shiphlqs'.'destid'.AHJOB'
   bjobdset = shiphlqs'.'destid'.CHJOB'

   ndmcpy   = destid
   cdmembr  = destid'P'

   FTINCL CMSNDRA /* include copy and rename of parent cd stmt       */
   if rc ^= 0 then call exception rc 'FTINCL of CMSNDRA failed.'

 end /* l = 1 to destc.0 */

 FTINCL CMSNDRC /* this is the destinfo destsys skeleton             */
 if rc ^= 0 then call exception rc 'FTINCL of CMSNDRC failed.'

 /* Add NDVEDIT for each destination to R job                        */
 do m = 1 to destb.0

   destid   = destb.m
   stepname = "E"destid

   cjobdset = shiphlqs'.'destid'.AHJOB'
   bjobdset = shiphlqs'.'destid'.CHJOB'

   if cd.destid = "LOCAL" then LOCAL = "YES"
                          else LOCAL = "NO"

   FTINCL CMSEDTR /* include ndvedit                                 */
   if rc ^= 0 then call exception rc 'FTINCL of CMSEDTR failed.'

 end /* m = 1 to destb.0 */

 /* Add OPSWTO step to demand EVL0101D on the local plex             */
 do g = 1 to destb.0
   destid = destb.g
   if cd.destid = "LOCAL" then do
     dshlqs = shiphlqs'.'destid
     ca7    = ca7.destid
     FTINCL CMSAOL  /* Local destination AO EVL0101D trigger         */
     if rc ^= 0 then call exception rc 'FTINCL of CMSAOL failed.'
   end /* cd.destid = "LOCAL" */
 end /* g = 1 to destb.0 */

 /* Insert cond code checking & OPSWTO to NDM members                */
 FTINCL CMSCDUP1
 if rc ^= 0 then call exception rc 'FTINCL of CMSCDUP1 failed.'

 /* Add a data line for each destination                             */
 do o = 1 to destb.0
   destid = destb.o

   if cd.destid <> "LOCAL" then do

     if cmr.destid ^= '+ 0' & , /* Add a time offset e.g. C&D plex   */
        ri ^= 'EMER' then do
       direction = word(cmr.destid,1)
       amount    = word(cmr.destid,2)
       varlist   = chdate chtime direction amount
       call CMOFFSET varlist
       parse var result idate itime xx yy /* results from CMOFFSET   */
     end /* cmr.destid ^= '+ 0' */
     else do
       idate  = chdate
       itime  = chtime
     end /* else */

     dshlqs = shiphlqs'.'destid
     ca7    = ca7.destid

     FTINCL CMSCDINF
     if rc ^= 0 then call exception rc 'FTINCL of CMSCDINF failed.'

   end /* cd.destid <> "LOCAL" */

 end /* o = 1 to destb.0 */

 FTINCL CMSCDUP2 /* End of insert cond code checks and OPSWTO to NDM */
 if rc ^= 0 then call exception rc 'FTINCL of CMSCDUP2 failed.'

 /* Add steps to Connect Direct d/sets to each destination           */
 do n = 1 to destb.0
   destid = destb.n
   if cd.destid <> "LOCAL" then do
     stepname = "N"destid
     cdmembr  = destid'P'
     FTINCL CMSCD /* Include the CD step                             */
     if rc ^= 0 then call exception rc 'FTINCL of CMSCD failed.'
   end /* cd.destid <> "LOCAL" */
 end /* n = 1 to destb.0 */

 /* Add an NDM step return code checks                               */
 FTINCL CMSCDRC1
 if rc ^= 0 then call exception rc 'FTINCL of CMSCDRC1 failed.'
 do o = 1 to destb.0
   destid   = destb.o
   if cd.destid <> "LOCAL" then do
     stepname = 'N'destid
     if o ^= destb.0 then lop = 'OR'
                     else lop = 'THEN'
     FTINCL CMSCDRC2 /* NDM step return code checks                  */
     if rc ^= 0 then call exception rc 'FTINCL of CMSCDRC2 failed.'
   end /* cd.destid <> "LOCAL" */
 end /* o = 1 to destb.0 */
 FTINCL CMSPWARN /* NDM step return code checks                      */
 if rc ^= 0 then call exception rc 'FTINCL of CMSPWARN failed.'

 /* Send email on error                                              */
 FTINCL CMSEMAIL
 if rc ^= 0 then call exception rc 'FTINCL of CMSEMAIL failed.'

 "FTCLOSE NAME("rmem")" /* save the jcl with the rjob name           */
 if rc ^= 0 then call exception rc 'FTCLOSE of' rmem 'failed.'

 say 'EVASSIGN:' rmem 'JCL written to dataset' hlq'.AUTO.CMJOBS'

return /* create_rjob: */

/*-------------------------------------------------------------------*/
/* Error with line number displayed                                  */
/*-------------------------------------------------------------------*/
exception:
 parse arg return_code comment

 if wordpos(condition('C'),'SYNTAX FAILURE') > 0 then do
   say 'Line' sigl':' left(sourceline(sigl),70)
   say 'Errortext:' errortext(rc)
   return_code = rc
   comment     = condition('C') 'failure at line' sigl
 end /* wordpos(condition('C'),'SYNTAX FAILURE') > 0 */

 parse source . . rexxname . . . . addr .
 say rexxname':'
 say rexxname':' comment 'RC='return_code
 say rexxname': Exception called from line' sigl

 if addr ^= 'MVS' then do
   z = msg(off)
   address ispexec "FTCLOSE" /* Close any FTOPENed files             */
   address tso 'delstack'    /* Clear down the stack                 */
   z = msg(on)
 end /* addr ^= 'MVS' */

 if return_code < 0 then return_code = 12 /* - RCs can be invalid    */

 zispfrc = return_code
 address ispexec "vput (zispfrc) shared"

exit return_code
