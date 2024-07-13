/*- REXX ------------------------------------------------------------*/
/*                                                                   */
/* Put together the output from the superc compares in to one        */
/* location to help with peer checking.                              */
/*                                                                   */
/*-------------------------------------------------------------------*/

banner = copies('-',133)
error  = copies('*',133)

/* cmr and system passed from initial panel                          */
parse arg c1ccid c1sy

call packcst /* get the package status for checking                  */

call packcsv /* get the package contents for comparison              */

call apireport /* run an API report for all types under the CMR      */

if apilist.0 = 0 then
  call notatf

call allocs /* set up the dataids for the source & target file       */

/* loop through the api output                                       */
do a = 1 to apilist.0

  type.a = strip(substr(apilist.a,49,8)) /* type field               */

  call cmparms

  missing = 1 /* set number to see if the type is not in the package */

  do s = 1 to packrep.0
    if strip(substr(packrep.s,217,8)) = type.a then
      missing = 0
  end /* do s = 1 to packrep.0 */

  if missing = 1 then do
    call missmem /* member not included in the package               */
    iterate /* don't copy in the superc output                       */
  end /* if missing = 1 then do */

  /* set the dataset name up                                         */
  superc = 'PREV.WIZARD'c1sy'.'type.a'.SUPERC'

  /* set the peer checking file up for LMCOPY statements             */
  address ispexec
  "LMINIT DATAID(TARGET) DATASET('"peerdsn"') ENQ(MOD)"
  if rc ^= 0 then call exception 16 'LMINIT of' peerdsn 'failed RC='rc

  /* prepare for the lmcopy                                          */
  "LMINIT DATAID(SOURCE) DATASET('"superc"') ENQ(SHR)"
  if rc ^= 0 then call exception 16 'LMINIT of' superc 'failed RC='rc

  /* copy the superc output                                          */
  "LMCOPY FROMID("source") TODATAID("target") FROMMEM("c1ccid")"
  if rc >= 12 then call exception 16 'LMCOPY failed, investigate RC='rc

  /* release the input file                                          */
  "LMFREE Dataid("source")"
  if rc ^= 0 then call exception 16 'LMFREE of' superc 'failed RC='rc

  /* Free the target dataset to allow execio                         */
  address ispexec
  "LMFREE DATAID("target")"

end /* do a = 1 to apilist.0 */

/* set the peer checking file up for LMCOPY statements               */
"LMINIT DATAID(TARGET) DATASET('"peerdsn"') ENQ(EXCLU)"
if rc ^= 0 then call exception 16 'LMINIT of' peerdsn 'failed RC='rc

"edit dataid("target")"
"lmclose dataid("target")"
"LMFREE DATAID("target")" /* free the peer checking file             */

exit

/*---------------------- S U B R O U T I N E S ----------------------*/

/* +---------------------------------------------------------------+ */
/* | Run Endevor API report                                        | */
/* +---------------------------------------------------------------+ */
apireport:
 address tso
 x = msg(off)
 /* Free ddnames incase of previous failure                          */
 "FREE DD(SYSOUT,SYSPRINT,BSTERR,APIMSGS,APIEXTR)"
 /* Allocate ddnames required by API                                 */
 "ALLOC DD(SYSOUT) SYSOUT"
 "ALLOC DD(SYSPRINT) SYSOUT"
 "ALLOC DD(BSTERR) SYSOUT"
 "ALLOC DD(APIMSGS) LRECL(133) RECFM(F B) BLKSIZE(0)"
 "ALLOC DD(APIEXTR) LRECL(2048) NEW,
  RECFM(V B) DSORG(PS) BLKSIZE(22800) SPACE(75,75) TRACKS REUSE"
 "ALLOC FI(SYSIN) SPACE(1,1) TRACKS,
  LRECL(80) RECFM(F) BLKSIZE(80) REUSE"

 /* build up the sysin command                                       */
 queue 'AACTL APIMSGS APIEXTR'
 queue 'ALELM  N ACPT    F'c1sy'              'c1ccid
 queue 'RUN'
 queue 'AACTLY'
 queue 'RUN'
 queue 'QUIT'

 /* write the sysin                                                  */
 "EXECIO "QUEUED()" DISKW SYSIN (FINIS"

 /* Call Endevor assuming that NDVRC1 is already active              */
 "CALL 'SYSNDVR.CAI.AUTHLIB(ENTBJAPI)'"

 /* Endevor wasn't active so use NDVRC1                              */
 if rc = 12 then
   "CALL 'SYSNDVR.CAI.AUTHLIB(NDVRC1)' 'ENTBJAPI'"

 /* free output datasets                                             */
 "FREE DD(SYSOUT,SYSPRINT,BSTERR,APIMSGS,SYSIN)"

 /* Read in the API extract file                                     */
 "EXECIO * DISKR APIEXTR (STEM apilist. FINIS)"
 "FREE DD(APIEXTR)"

return /* apireport: */

/* +---------------------------------------------------------------+ */
/* | Allocate the peer check file and set it up as the target      | */
/* +---------------------------------------------------------------+ */
allocs:

 hlq = Sysvar(Syspref) /* Get the users default HLQ                  */
 peerdsn = hlq"."c1ccid".PEER.CHECK"

 /* delete Output file if already exists                             */
 ADDRESS TSO
 "DEL '"peerdsn"'"

 /* allocate the peer checking file                                  */
 "ALLOC DA('"peerdsn"') NEW CATALOG SPACE(5,5) TRACKS F(PEERDSN),
 RECFM(F,B) LRECL(133) BLKSIZE(27930) DSORG(PS)"
 "FREE FI(PEERDSN)" /* free the temp file                            */

return /* allocs: */

/* +---------------------------------------------------------------+ */
/* | Get package status to establish the package has been cast     | */
/* +---------------------------------------------------------------+ */
packcst:
 pkgid = c1ccid'P' /* package name                                   */

 x = msg(off) /* turn off messages                                   */
 address tso
 /* free incase there are hangovers. Do not code an exception call   */
 "free f(bsterr c1msgsa csvmsgs1 apiextr csvipt01)"

 "alloc f(csvipt01) new space(1 1) tracks recfm(f b) lrecl(80)"
 if rc ^= 0 then call exception rc 'ALLOC of csvipt01 failed.'

 /* Build the input to the report execution                          */
 queue "  LIST PACKAGE ID" pkgid
 queue "  OPTIONS NOCSV . "
 'execio' queued() 'diskw csvipt01 (finis)'
 if rc ^= 0 then call exception rc 'DISKW to csvipt01 failed.'

 /* Allocate files to process SCL                                    */
 "alloc f(apiextr) new space(1 1) tracks recfm(f b) lrecl(1600)"
 if rc ^= 0 then call exception rc 'ALLOC of APIEXTR failed.'

 "alloc f(c1msgsa) sysout(z)"
 if rc ^= 0 then call exception rc 'ALLOC of c1msgsa failed.'
 "alloc f(csvmsgs1) sysout(z)"
 if rc ^= 0 then call exception rc 'ALLOC of csvmsgs1 failed.'
 "alloc f(bsterr) sysout(z)"
 if rc ^= 0 then call exception rc 'ALLOC of BSTERR failed.'

 /* invoke the program                                               */
 address "LINKMVS" 'BC1PCSV0'
 lnk_rc = rc
 address tso
 "free f(bsterr c1msgsa csvmsgs1 csvipt01)"
 free_rc = rc

 if lnk_rc = 8 then call nopack /* no package found by CSV           */

 if free_rc ^= 0 then call exception rc 'FREE of files failed.'

 if lnk_rc > 0 then do /* error found in running the routine         */
   "free f(apiextr)"
   call exception lnk_rc 'Call to NDVRC1 failed'
 end /* lnk_rc > 4 */

 g = listdsi(apiextr file)

 /* listdsi didn't show the file exists                              */
 if g > 0 then call exception g 'LISTDSI of APIEXTR file failed'
 else
   address tso "execio 1 diskr apiextr" /* read 1 record             */

 pull record /* get the package status of the queue                  */

 address tso "execio 0 diskr apiextr (finis" /* close file           */
 "free f(apiextr)" /* release the file                               */

 x = msg(on) /* turn on messages                                     */

 /* if the package is not in APPROVED status then issue err message  */
 if strip(substr(record,116,12)) ^= 'APPROVED' then
   call nopack

return /* packcst */

/* +---------------------------------------------------------------+ */
/* | Get package actions to compare to existing elements           | */
/* +---------------------------------------------------------------+ */
packcsv:
 pkgid = c1ccid'P' /* package name                                   */

 x = msg(off) /* turn off messages                                   */
 address tso
 /* free incase there are hangovers. Do not code an exception call */
 "free f(bsterr c1msgsa csvmsgs1 apiextr csvipt01)"

 "alloc f(csvipt01) new space(1 1) tracks recfm(f b) lrecl(80)"
 if rc ^= 0 then call exception rc 'ALLOC of csvipt01 failed.'

 /* Build the input to the report execution                          */
 queue "  LIST PACKAGE ACTION FROM PACKAGE ID" pkgid
 queue "  OPTIONS NOCSV . "
 'execio' queued() 'diskw csvipt01 (finis)'
 if rc ^= 0 then call exception rc 'DISKW to csvipt01 failed.'

 /* Allocate files to process SCL                                    */
 "alloc f(apiextr) new space(1 1) tracks recfm(f b) lrecl(1600)"
 if rc ^= 0 then call exception rc 'ALLOC of APIEXTR failed.'

 "alloc f(c1msgsa) sysout(z)"
 if rc ^= 0 then call exception rc 'ALLOC of c1msgsa failed.'
 "alloc f(csvmsgs1) sysout(z)"
 if rc ^= 0 then call exception rc 'ALLOC of csvmsgs1 failed.'
 "alloc f(bsterr) sysout(z)"
 if rc ^= 0 then call exception rc 'ALLOC of BSTERR failed.'

 /* invoke the program                                               */
 address "LINKMVS" 'BC1PCSV0'
 lnk_rc = rc
 address tso
 "free f(bsterr c1msgsa csvmsgs1 csvipt01)"
 if rc ^= 0 then call exception rc 'FREE of files failed.'

 if lnk_rc > 0 then do /* error found in running the routine         */
   "free f(apiextr)"
   call exception lnk_rc 'Call to NDVRC1 failed'
 end /* lnk_rc > 4 */

 g = listdsi(apiextr file)

 /* listdsi didn't show the file exists                              */
 if g > 0 then call exception g 'LISTDSI of APIEXTR file failed'
 else
   address tso "execio * diskr apiextr (STEM PACKREP. FINIS"

 "free f(apiextr)"

 x = msg(on) /* turn on messages                                     */

return /* packcsv */

/* +---------------------------------------------------------------+ */
/* | Allocate the cmparm member to look for delete statements      | */
/* +---------------------------------------------------------------+ */
cmparms:
 d = 0 /* 0 delete statements found                                  */

 queue ''
 queue banner
 queue ''
 queue centre('You are peer checking the element' c1ccid 'for type' type.a,80)
 queue ''
 queue banner
 queue ''

 cmdsn = 'prev.F'c1sy'1.'type.a'.cmparm('c1ccid')'

 /* Read the CMPARM member for delete statements                     */
 address tso
 "ALLOC DA('"cmdsn"') F(CMFILE) SHR"
 if rc ^= 0 then call exception 16 'ALLOC of DDname CMFILE failed RC='rc

 "EXECIO * DISKR CMFILE (STEM REP. FINIS"
 if rc ^= 0 then call exception 16 'EXECIO of DDname CMFILE failed RC='rc

 /* release the cmparm file                                          */
 "FREE DD(CMFILE)"
 if rc ^= 0 then call exception 16 'FREE of DDname CMFILE failed RC='rc

 do z = 1 to rep.0 /* loop through the cmparm content                */

   if word(rep.z,1) = 'DELETE' then do
     d = d + 1 /* increment counter                                  */
     delete.d = rep.z
   end /* if word(rep.z,1) = 'DELETE' then do */

 end /* do z = 1 to rep.0 */

 if d > 0 then do /* delete statements found in the cmparm member   */

   queue centre('Delete statements found in the CMPARM member',80)
   queue ''

   do e = 1 to d /* queue up the delete statements                  */
     queue delete.e
   end /* do = 1 to d */

   queue ''
   queue centre('No more delete statements',80)

 end /* if d > 0 then do */

 /* allocate the peer checking file for writing                      */
 "ALLOC DA('"peerdsn"') F(PEERDSN) MOD"
 if rc ^= 0 then call exception 16 'ALLOC of DDname PEERDSN failed RC='rc

 /* write our the results to the peer checking file                  */
 "execio" queued() "diskw PEERDSN (finis"
 if rc ^= 0 then call exception 16 'EXECIO of DDname PEERDSN failed RC='rc

 address tso delstack /* clear down the queue                        */

 /* release the cmparm file                                          */
 "FREE DD(PEERDSN)"
 if rc ^= 0 then call exception 16 'FREE of DDname PEERDSN failed RC='rc

return /* cmparms: */

/* +---------------------------------------------------------------+ */
/* | Write a record if the member is missing from the package      | */
/* +---------------------------------------------------------------+ */
missmem:
 address tso
 /* allocate the peer checking file for writing                      */
 "ALLOC DA('"peerdsn"') F(PEERDSN) MOD"
 if rc ^= 0 then call exception 16 'ALLOC of DDname PEERDSN failed RC='rc

 queue
 queue error
 queue
 queue centre('An element of type' type.a 'for CMR' c1ccid 'was  ',80)
 queue centre('NOT found in package' pkgid', but was found at ',80)
 queue centre('stage F of system' c1sy'.                            ',80)
 queue
 queue centre('Either re-build the package or delete the' type.a,80)
 queue centre('element from stage F.                             ',80)
 queue
 queue centre('If you take no action and the CMR gets implemented',80)
 queue centre('then you will receive e-mails asking you to delete',80)
 queue centre('the element anyway.                               ',80)
 queue
 queue error
 queue

 /* write our the results to the peer checking file                  */
 "execio" queued() "diskw PEERDSN (finis"
 if rc ^= 0 then call exception 16 'EXECIO of DDname PEERDSN failed RC='rc

 address tso delstack /* clear down the queue                        */

 /* release the cmparm file                                          */
 "FREE DD(PEERDSN)"
 if rc ^= 0 then call exception 16 'FREE of DDname PEERDSN failed RC='rc

return /* missmem: */

/* +---------------------------------------------------------------+ */
/* | End because the members are not at stage F                    | */
/* +---------------------------------------------------------------+ */
notatf:
 zedsmsg = 'No elements found'
 zedlmsg = 'The CMR' c1ccid 'is not at stage F' ,
           'in system' c1sy

 address ispexec "setmsg msg(isrz001)"
 exit 8

return /* notatf: */

/* +---------------------------------------------------------------+ */
/* | End because the package is not ready                          | */
/* +---------------------------------------------------------------+ */
nopack:
 zedsmsg = 'Package not cast'
 zedlmsg = 'The package' c1ccid'P has not been cast' ,
           'and cannot be peer checked'

 address ispexec "setmsg msg(isrz001)"
 exit lnk_rc

return /* nopack: */

/* +---------------------------------------------------------------+ */
/* | Error with line number displayed                              | */
/* +---------------------------------------------------------------+ */
exception:
 parse arg return_code comment

 "LMFREE DATAID("source")"
 "LMFREE DATAID("target")"

 address tso delstack        /* Clear down the stack                 */

 parse source . . rexxname . /* Get the rexx name(generic subroutine)*/
 say rexxname':'
 say rexxname': Return code is' return_code
 say rexxname':' comment
 say rexxname': Exception called from line' sigl

exit 12
