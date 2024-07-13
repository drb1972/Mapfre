/*-----------------------------REXX----------------------------------*\
 *  Validate Wizard input cards                                      *
 *                                                                   *
\*-------------------------------------------------------------------*/
trace n

say 'CMPARM1:'

address tso
makecopy       = 'NO'
makedele       = 'NO'
makebackoutdel = 'NO'
doalloc        = 'NO'
listprod       = 'NO'
rcode          = 0
backout        = 0
copycnt        = 0
out            = 0

/* NB. On the parse statement variable comma is used to overcome     */
/* a bug in REXX that includes the JCL continuation ',' as a variable*/
/* when passed to the REXX                                           */

parse arg ele ccid action comma stage sub type c1prgrp aliens
basetype = type
sys      = substr(sub,1,2)

/* If the CCID is not the regular one, and the system is not EK then */
/* terminate the routine with a return code of 32                    */
if action ^= 'DELETE' then
  if substr(ccid,1,2) ^= 'C0' & substr(sub,1,2) ^= 'EK' then do
    say 'CMPARM1: The CCID must be a valid Infoman change'
    say 'CMPARM1: The routine is terminating with a return code 32'
    exit 32
  end /* substr(ccid,1,2) ^= 'C0' & ... */

if left(type,4) = 'JOBS' & length(type) = 5 then
  checkmemname = 'YES'

if type = 'MZPARMLX' then
  lrecl = '121'
else
  lrecl = '80'

if c1prgrp = 'WIZARD' then
  tdsn = "TT"sys"."ele"."type
else
  tdsn = "TT"right(strip(c1prgrp),2)"."ele"."type

/* Get the block size of the stage P source library for allocations  */
blksize = 0
ldsn    = "'PREV.P"sub"."type"'"
x       = listdsi(ldsn)
if x < 5 then
  blksize = sysblksize
else
  say 'CMPARM1: File not found' ldsn

/* remove # from end of type names                                   */
if pos('#',type) > 0 then do
  typlen = length(type)
  basetype = substr(type,1,(typlen-1))
end /* pos('#',type) > 0 */

/* Read input file into stem variable                                */
"execio * diskr REPIN (stem rep. finis"
if rc ^= 0 then call exception rc 'DISKR of REPIN failed.'

/* Check to see if deletes are being done                            */
do c = 1 to rep.0
  if substr(rep.c,1,6) = 'DELETE' then makedele = 'YES'
end /* c = 1 to rep.0 */

if action = 'MOVE' & stage = 'F' then listprod = 'YES'
if action = 'MOVE' & stage = 'O' then listprod = 'YES'

if action ^= 'DELETE' then do

  /* Build list of member names that exist at stage P                */
  /* and write to them into an array                                 */
  if listprod = 'YES' then do
    dsn = "'PREV.P"sub"."type"'"
    a   = outtrap('pdsmems.','*')
    queue "display"
    queue "end"
    /* Changed to use PDSMAN to bring back lists of members          */
    /* this traps less lines than listds so avoids storage abend     */
    "pdsman" dsn
    pdsrc = rc
    a     = outtrap('off')

    if pdsrc > 0 then do
      say "CMPARM1: Error reading" dsn "directory"
      exit pdsrc
    end /* pdsrc > 0 */

    if pdsmems.0 > 0 then too = pdsmems.0 - 1

    do i = 2 to too

      do y = 1 to words(pdsmems.i)
        mem = word(pdsmems.i,y)
        found.mem = 'YES'
      end /* y = 1 to words(pdsmems.i) */

    end /* i = 2 to too */

  end  /* listprod = 'YES' then */

  if substr(ccid,1,8) ^= ele & substr(ccid,1,8) ^= 'NDVR#SUP' then do
    say 'CMPARM1: Error - element must have same name as ccid'
    rcode = 8
  end /* substr(ccid,1,8) ^= ele & */

  ccidmain = substr(ccid,1,8)
  last     = ''
  blankvar = substr(' ',1,56,' ')

  /* Run through syntax and check its is all good                    */
  do c = 1 to rep.0
    if substr(rep.c,17,56) ^= blankvar then do
      say 'CMPARM1: Error on line' c 'columns 17 to 80 must be blank'
      rcode = 8
    end /* substr(rep.c,17,56) ^= blankvar */
    if substr(rep.c,8,8) = '        ' then do
      say 'CMPARM1: Error on line' c 'missing element name'
      rcode = 8
    end /* substr(rep.c,8,8) = '        ' */
    if substr(rep.c,1,6) ^= 'COPY  ' & substr(rep.c,1,6) ^= 'DELETE' then do
      say 'CMPARM1: Error on line' c 'invalid action -' substr(rep.c,1,6)
      say 'CMPARM1: Must be copy or delete'
      rcode = 8
    end /* substr(rep.c,1,6) ^= 'COPY  ' & ... */
    thismem = strip(substr(rep.c,8,8))
    if substr(rep.c,1,6) = 'COPY  ' then do
      makecopy = 'YES'
      copycnt  = copycnt + 1
      /* Check member name for JOBS* types                           */
      if checkmemname = 'YES' & left(thismem,1) <> right(type,1) then
        if thismem ^= 'UCC7I' & ,
           thismem ^= 'EMON'  then do /* UCC7I & EMON are exceptions */
          say 'CMPARM1: Error!! member names for type' type
          say 'CMPARM1: should begin with' right(type,1)
          say 'CMPARM1: Member name =' thismem
          rcode = 8
        end /* thismem ^= 'UCC7I' */
    end /*  substr(rep.c,1,6) = 'COPY  ' */

    if substr(rep.c,1,6) = 'COPY  ' & found.thismem ^= 'YES' then
      makebackoutdel = 'YES'

    curr = substr(rep.c,8,8)

    if curr = last then do
      say 'CMPARM1: Error, duplicate member found,' ,
          curr 'reference more than once, line' c
      rcode = 8
    end /* curr = last */
    last=curr
  end /* c = 1 to rep.0 */

  /* Check that wizard copies match members on TT library            */
  if stage = 'E' & action = 'MOVE' & makecopy = 'YES' then do
    dsn = "'"tdsn"'"
    x   = outtrap('listds.')
    'listds' dsn 'members'
    y   = outtrap('off')
    do a = 7 to listds.0
      if substr(listds.a,3,8) > 'ZZZZZZZZ' then leave
      ttmem         = strip(substr(listds.a,3,8))
      ttfound.ttmem = 'YES'
    end /* a = 7 to listds.0 */
  end /* stage = 'E' & action = 'MOVE' & ... */

  if makecopy = 'NO' & makedele = 'NO' then do
    say 'ERROR - No copy or delete statements in' substr(ele,1,8)
    rcode = 8
  end /* makecopy = 'NO' & makedele = 'NO' */

  /* Build delete and BSTCOPY SYSIN statements                       */
  if rcode = 0 then do
    say 'CMPARM1: '
    say 'CMPARM1: '
    say 'CMPARM1: Syntax check complete - no errors found          '
    say 'CMPARM1: '

    if makecopy = 'YES' then do
      rcode = 1
      say 'CMPARM1:'
      say 'CMPARM1: Building copy statements for the following'
      say 'CMPARM1: these will be written to the BSTCOPY ddname'
      say 'CMAPRM1:'
      queue '  COPY O=OUTDD,I=INDD'
      do c = 1 to rep.0
        mem = strip(substr(rep.c,8,8))
        if substr(rep.c,1,6)= 'COPY  ' then do
          say 'CMPARM1:  SELECT MEMBER=(('MEM',,R))'
          queue '  SELECT MEMBER=(('MEM',,R))'
        end /* substr(rep.c,1,6)= 'COPY  ' */
      end /* c = 1 to rep.0 */
      "execio" queued() "diskw BSTCOPY (finis)"
      if rc ^= 0 then call exception rc 'DISKW to BSTCOPY failed.'

      say 'CMPARM1: '
      say 'CMPARM1: Building SYSIN for SUPERC compare step  '
      say 'CMPARM1: These will be written to the COMPARE ddname'
      do c = 1 to rep.0
        mem = strip(substr(rep.c,8,8))
        if substr(rep.c,1,6)= 'COPY  ' then do
          say 'CMPARM1: SELECT 'mem''
          queue 'SELECT 'mem
        end /* substr(rep.c,1,6)= 'COPY  ' */
      end /* c = 1 to rep.0 */
      "execio" queued() "diskw COMPARE (finis)"
      if rc ^= 0 then call exception rc 'DISKW to COMPARE failed.'
    end /* makecopy = 'YES' */

    if makedele  = 'YES' then do
      say 'CMPARM1: '
      say 'CMPARM1: Building DELETE statements for the following:- '
      say 'CMPARM1: These will be written to the PRODDEL ddname'
      say 'CMPARM1: '
      rcode = 2
      say "CMPARM1: EDITDIR OUTDD=STAGE"
      queue " EDITDIR OUTDD=STAGE"
      do c = 1 to rep.0
        mem = strip(substr(rep.c,8,8))
        if substr(rep.c,1,6)= 'DELETE' then do
          say "CMPARM1: DELETE    MEMBER="mem""
          queue " DELETE    MEMBER="mem
        end /* substr(rep.c,1,6)= 'DELETE' */
      end /* c = 1 to rep.0 */
      "execio" queued() "diskw PRODDEL (finis)"
      if rc ^= 0 then call exception rc 'DISKW to PRODDEL failed.'
    end /* makedele  = 'YES' */

    /*  Set the return code depending on the combination             */
    /*  of copy and delete statement so the other steps              */
    /*  in the processor can perform actions if required             */

    if makecopy = 'YES' & makedele = 'YES' then rcode = 3
  end /* rcode = 0 */

  /* If at stage E, then allocate a TT library for holding the       */
  /* source code based on the number of members being copied         */

  if copycnt > 0 & stage = 'E' | stage = 'O',
     & rcode <= 4 & action = 'GEN' then do
    prim = trunc(copycnt/16)+1
    sec  = trunc(prim/10)+1
    dbs  = trunc(copycnt/3)+4
    /* Convert cyls to trks                                          */
    prim = prim*15
    sec  = sec*15
    result = sysdsn("'"tdsn"'")

    if result = 'DATASET NOT FOUND' & stage = 'O' then do
      "ALLOC  DA('"tdsn"') SPACE("prim","sec")",
        "DIR("dbs") TRACKS LRECL("lrecl") RECFM(F B)"
      if rc ^= 0 then call exception rc 'ALLOC of' tdsn 'failed.'
      "FREE DATASET('"tdsn"')"
      say 'CMPARM1: 'tdsn 'not found.'
      say 'CMPARM1: 'tdsn 'has been allocated, ',
          'please populate and regenerate'
      exit 8
    end /* result = 'DATASET NOT FOUND' & stage = 'O' */

    if result = 'DATASET NOT FOUND' & stage ^= 'O' then do
      "ALLOC  DA('"tdsn"') SPACE("prim","sec")",
        "DIR("dbs") TRACKS LRECL("lrecl") RECFM(F B)"
      if rc ^= 0 then call exception rc 'ALLOC of' tdsn 'failed.'
      "FREE DATASET('"tdsn"')"
    end /* result = 'DATASET NOT FOUND' & stage ^= 'O' */
  end /*  copycnt > 0 & stage = 'E' | ... */

  if makecopy = 'YES' then do
    say 'CMPARM1:'
    say 'CMPARM1: Building IEBCOPY statements for the SHIPMENT dataset'
    say 'CMPARM1: These will be written to the PRODDEL ddname'
    say 'CMPARM1: COPY OUTDD=STAGE,INDD=NEW,UNPACK'
    queue ' COPY OUTDD=STAGE,INDD=NEW,UNPACK'
    do c = 1 to rep.0
      mem = strip(substr(rep.c,8,8))
      if substr(rep.c,1,6)= 'COPY  ' & stage = 'E' then do
        queue ' S M=('mem')'
        if action = 'MOVE' & ttfound.mem ^= 'YES' then do
          say 'CMPARM1: ERROR , MEMBER' mem 'NOT FOUND IN' tdsn
          rcode = 8
        end /* action = 'MOVE' & ttfound.mem ^= 'YES' */
      end /* substr(rep.c,1,6)= 'COPY  ' & stage = 'E' */
      if substr(rep.c,1,6) = 'COPY  ' & stage ^= 'E' then do
        say 'CMPARM1: S M=(('mem',,R))'
        queue ' S M=(('mem',,R))'
      end /* substr(rep.c,1,6) = 'COPY  ' & stage ^= 'E' */
    end /* c = 1 to rep.0 */
    "execio" queued() "diskw SHIPMENT (finis)"
    if rc ^= 0 then call exception rc 'DISKW to SHIPMENT failed.'
  end /* makecopy = 'YES' */

  if (stage = 'F' | stage = 'O') & action = 'MOVE',
     & makecopy = 'YES' then
    doalloc = 'YES'

  /*   Building backout copy SYSIN for existing members              */
  /*   so that any members being updated or deleted                  */
  /*   are first backed up to a backout library                      */

  if (stage = 'F' | stage = 'O') & action = 'MOVE' then do
    allocst = 'P'

    /*   If we're moving to production then check to see             */
    /*   if the member being deleted or copied exists in             */
    /*   the target library and if so build copy statement           */
    /*   to back it up to backout libaray                            */

    do c = 1 to rep.0
      thismem = strip(substr(rep.c,8,8))
      if found.thismem = 'YES' then do
        say 'CMPARM1: S M='thismem''
        queue ' S M='thismem
        backout = backout + 1
      end /* found.thismem = 'YES' */
    end /* c = 1 to rep.0 */
    if backout > 0 then push ' COPY OUTDD=BACKOUT,INDD=OAR000'
    queue ' '
    "execio" queued() "diskw COPYBOUT (finis)"
    if rc ^= 0 then call exception rc 'DISKW to COPYBOUT failed.'

    /*   If all is ok and there are members to ship to               */
    /*   production, allocate a shipment dataset based               */
    /*   on the test library                                         */

    /*  Check to see if we are moving to production and              */
    /*  if so set some variables for allocation the                  */
    /*  staging libraries                                            */

    staging = "PREV."allocst||sub"."type"."ele
    proddsn = "##"sys".BASE."basetype
    bdsn    = "PREV."allocst||sub"."type".B"substr(ele,2,7)
    result  = sysdsn("'"bdsn"'")

    if doalloc = 'YES' & rcode <= 4 & ,
       result = 'DATASET NOT FOUND' then do
      prim   = trunc(copycnt/16)+1
      sec    = trunc(prim/10)+1
      dbs    = trunc(copycnt/3)+4
      /* Convert cyls to tracks                                      */
      prim   = prim*15
      sec    = sec*15
      "ALLOC  DA('"staging"') SPACE("prim","sec")",
        "DIR("dbs") TRACKS LRECL("lrecl") RECFM(F B)",
        "BLKSIZE("blksize")"
      if rc ^= 0 then call exception rc 'ALLOC of' staging 'failed.'
      "FREE DATASET('"staging"')"
    end /* doalloc = 'YES' & rcode <= 4 & ... */

    /* If no staging library needed, allocate dummy one with small   */
    /* size, to prevent JCL error in BSTCOPY step and do the same    */
    /* for the backout staging library                               */

    if doalloc = 'NO' & rcode <= 4 & ,
       result = 'DATASET NOT FOUND' then do
      "ALLOC  DA('"staging"') SPACE(5,5)",
        "DIR(5) TRACK LRECL(80) RECFM(F B) BLKSIZE("blksize")"
      if rc ^= 0 then call exception rc 'ALLOC of' staging 'failed.'
      "FREE DATASET('"staging"')"
    end /* doalloc = 'NO' & rcode <= 4 & ... */

    if backout = 0 & rcode <= 4 & ,
       result = 'DATASET NOT FOUND' then do
      "ALLOC  DA('"bdsn"') SPACE(5,5)",
        "DIR(5) TRACK LRECL(80) RECFM(F B) BLKSIZE("blksize")"
      if rc ^= 0 then call exception rc 'ALLOC of' bdsn 'failed.'
      "FREE DATASET('"bdsn"')"
    end /* backout = 0 & rcode <= 4 & ... */

    /* Allocate backout library based on the number of members to    */
    /* be backed out (both copies that exist and deletes from prod)  */
    /* assume that you get 16 members per cylinder (same as shipment)*/

    if backout > 0 & rcode <= 4 & ,
       result = 'DATASET NOT FOUND' then do
      prim = trunc(backout/16)+1
      sec  = trunc(prim/10)+1
      dbs  = trunc(backout/3)+4
      /* Convert cyls to tracks                                      */
      prim = prim*15
      sec  = sec*15
      "ALLOC  DA('"bdsn"') SPACE("prim","sec")",
        "DIR("dbs") TRACKS LRECL("lrecl") RECFM(F B)",
        "BLKSIZE("blksize")"
      if rc ^= 0 then call exception rc 'ALLOC of' bdsn 'failed.'
      "FREE DATASET('"bdsn"')"
    end /* backout > 0 & rcode <= 4 & ... */

    say 'CMPARM1: '
    say 'CMPARM1: Building NDM cards'
    say 'CMAPRM1:'
    /* Allocate input libraries and read into stem vars              */
    "EXECIO * DISKR systems (STEM plex. FINIS)"
    if rc ^= 0 then call exception rc 'DISKR of SYSTEMS failed.'
    "EXECIO * DISKR destinfo (STEM destinfo. FINIS)"
    if rc ^= 0 then call exception rc 'DISKR of DESTINFO failed.'

    /* Get list of plex names                                        */
    do i = 1 to plex.0
      interpret plex.i
    end /* i = 1 to plex.0 */

    /* Obtain SNODE                                                  */
    do kount = 1 to destinfo.0
      interpret destinfo.kount
    end /* kount = 1 to destinfo.0 */

    /* Create Prod Plex's jcl                                        */
    do iii = 1 to words(C1SYSTEMB.DEFAULT)
      plex = word(C1SYSTEMB.DEFAULT,iii)
      interpret "SNODE = CD."plex
      if snode ^= 'LOCAL' then
        call process snode
    end /* iii = 1 to words(C1SYSTEMB.DEFAULT) */

    /* write out ndm cards                                           */
    "execio" out "diskw ndmout (stem data. "
    if rc ^= 0 then call exception rc 'DISKR to NDMOUT failed.'

    /* Create change job jcl to be NDVEDITed into change.            */
    /* If NDVEDIT sees a CMPARM member being shipped then            */
    /* it will insert this step into the Cjob JCL                    */

    staging = "##EV."allocst||sub"."type"."ele
    proddsn = "##"sys".BASE."basetype
    bdsn    = "##EV."allocst||sub"."type".B"substr(ele,2,7)

    "delstack"
    queue "//WIZARD   EXEC PGM=IEBCOPY                            "
    queue "//FCOPYON  DD DUMMY                                    "
    queue "//SYSPRINT DD SYSOUT=*                                 "
    queue "//SYSUT3   DD UNIT=DASD,SPACE=(TRK,(5,5))              "
    queue "//SYSUT4   DD UNIT=DASD,SPACE=(TRK,(5,5))              "
    queue "//STAGE    DD DISP=SHR,DSN="staging
    queue "//OAR000   DD DISP=SHR,DSN="proddsn
    queue "//SYSIN    DD *                                        "

    if makecopy = 'YES' then
      queue " COPY      INDD=((STAGE,R)),OUTDD=OAR000               "

    if makedele  = 'YES' then do
      queue " EDITDIR OUTDD=OAR000                                  "
      do c = 1 to rep.0
        mem = strip(substr(rep.c,8,8))
        if substr(rep.c,1,6)= 'DELETE' then
          queue " DELETE    MEMBER="mem
      end /* c = 1 to rep.0 */
    end /* makedele  = 'YES' */

    queue "//*                                                    "
    queue "//CHECKIT  IF (ABEND OR RC GT 4) THEN                  "
    queue "//*                                                    "
    queue "//SPWARN   EXEC @SPWARN                                "
    queue "//CHECKIT  ENDIF                                       "
    queue "//*                                                    "


    "execio" queued() "diskw CJOBJCL (finis)"
    if rc ^= 0 then call exception rc 'DISKW to CJOBJCL failed.'

    /* End of step that creates cjob jcl                             */

    /* Create additional JCL to be NDVEDITed into Cjob for dev lpar  */
    /* This is to remove the in progress CMPARM member               */
    prevdsn = "PREV.P"sub"."type""

    "delstack"
    queue "//WIZARDIP EXEC PGM=IEBCOPY                            "
    queue "//FCOPYON  DD DUMMY                                    "
    queue "//SYSPRINT DD SYSOUT=*                                 "
    queue "//SYSUT3   DD UNIT=DASD,SPACE=(TRK,(5,5))              "
    queue "//SYSUT4   DD UNIT=DASD,SPACE=(TRK,(5,5))              "
    queue "//DELCMPI  DD DISP=SHR,DSN="prevdsn".CMPARM.INPROG     "
    queue "//SYSIN    DD *                                        "
    queue " EDITDIR OUTDD=DELCMPI                                 "
    queue "  DELETE    MEMBER="left(ccid,8)
    queue "/*                                                     "
    queue "//CHECKIT  IF (ABEND OR RC GT 4) THEN                  "
    queue "//*                                                    "
    queue "//SPWARN   EXEC @SPWARN                                "
    queue "//CHECKIT  ENDIF                                       "
    queue "//*                                                    "

    "execio" queued() "diskw PJOBJCL (finis)"
    if rc ^= 0 then call exception rc 'DISKW to PJOBJCL failed.'

    /* End of step that creates pjob jcl                             */

    /* Create backout job JCL to be NDVEDITed into Bjob.             */
    /* If NDVEDIT sees a CMPARM member being shipped then            */
    /* it will insert this step into the B job jcl                   */

    "delstack"
    queue "//WIZARD   EXEC PGM=IEBCOPY                            "
    queue "//FCOPYON  DD DUMMY                                    "
    queue "//SYSPRINT DD SYSOUT=*                                 "
    queue "//SYSUT3   DD UNIT=DASD,SPACE=(TRK,(5,5))              "
    queue "//SYSUT4   DD UNIT=DASD,SPACE=(TRK,(5,5))              "
    queue "//STAGE    DD DISP=SHR,DSN="bdsn
    queue "//OAR000   DD DISP=SHR,DSN="proddsn
    queue "//SYSIN    DD *                                        "

    if makedele = 'YES' | backout > 0 then
      queue " COPY      INDD=((STAGE,R)),OUTDD=OAR000               "

    if makebackoutdel = 'YES' then do
      queue " EDITDIR OUTDD=OAR000                                  "
      do c = 1 to rep.0
        if substr(rep.c,1,6)= 'COPY  ' then do
          thismem = strip(substr(rep.c,8,8))
          if found.thismem ^= 'YES' then
            queue " DELETE    MEMBER="thismem
        end /* substr(rep.c,1,6)= 'COPY  ' */
      end /* c = 1 to rep.0 */
    end /* makebackoutdel = 'YES' */
    queue "/*                                                     "
    queue "//CHECKIT  IF (ABEND OR RC GT 4) THEN                  "
    queue "//*                                                    "
    queue "//SPWARN   EXEC @SPWARN                                "
    queue "//CHECKIT  ENDIF                                       "
    queue "//*                                                    "

    "execio" queued() "diskw BJOBJCL (finis)"
    if rc ^= 0 then call exception rc 'DISKW to BJOBJCL failed.'

    /* End of step that creates bjob jcl                             */

    /* Create additional JCL to be NDVEDITed into Bjob for dev lpar  */
    /* This is to backout source from prev stage P library           */
    /* NDVEDIT will put this step in the Bjob targeted at the Qplex  */
    prevdsn = "PREV.P"sub"."type""

    "delstack"
    queue "//WIZARD   EXEC PGM=IEBCOPY                            "
    queue "//FCOPYON  DD DUMMY                                    "
    queue "//SYSPRINT DD SYSOUT=*                                 "
    queue "//SYSUT3   DD UNIT=DASD,SPACE=(TRK,(5,5))              "
    queue "//SYSUT4   DD UNIT=DASD,SPACE=(TRK,(5,5))              "
    queue "//STAGE    DD DISP=SHR,DSN="bdsn
    queue "//OAR000   DD DISP=SHR,DSN="prevdsn
    queue "//DELCMPI  DD DISP=SHR,DSN="prevdsn".CMPARM.INPROG     "
    queue "//SYSIN    DD *                                        "

    if makedele = 'YES' | backout > 0 then
      queue " COPY      INDD=((STAGE,R)),OUTDD=OAR000               "

    if makebackoutdel = 'YES' then do
      queue " EDITDIR OUTDD=OAR000                                  "
      do c = 1 to rep.0
        if substr(rep.c,1,6)= 'COPY  ' then do
          thismem = strip(substr(rep.c,8,8))
          if found.thismem ^= 'YES' then
            queue " DELETE    MEMBER="thismem
        end /* substr(rep.c,1,6)= 'COPY  ' */
      end /* c = 1 to rep.0 */
    end /* makebackoutdel = 'YES' */

    queue " EDITDIR OUTDD=DELCMPI                                 "
    queue "  DELETE    MEMBER="left(ccid,8)
    queue "/*                                                     "
    queue "//CHECKIT  IF (ABEND OR RC GT 4) THEN                  "
    queue "//*                                                    "
    queue "//SPWARN   EXEC @SPWARN                                "
    queue "//CHECKIT  ENDIF                                       "
    queue "//*                                                    "

    "execio" queued() "diskw XBJOBJCL (finis)"
    if rc ^= 0 then call exception rc 'DISKW to XJOBJCL failed.'

    /* End of step that creates bjob jcl                             */
    exit rcode
  end /* rcode = 0 */
end /* action ^= 'DELETE' */

/* Just do the next step if running the delete processor             */

if action = 'DELETE' then do
  /* If deleting ignore reset rcode to allow processor to work       */
  /* regardless of syntax errors in wizard member                    */
  rcode = 4
  say 'CMPARM1: '
  say 'CMPARM1: BUILDING DELETE CARDS FOR STAGE F AND O LIBRARIES'
  say 'CMPARM1: These will be written to the OANDFDEL ddname'
  say 'CMPARM1:'
  say "CMPARM1: EDITDIR OUTDD=DEL"
  queue " EDITDIR OUTDD=DEL"
  do c = 1 to rep.0
    mem = strip(substr(rep.c,8,8))
    if substr(rep.c,1,6)= 'COPY  ' then do
      say "CMPARM1: DELETE    MEMBER="mem""
      queue " DELETE    MEMBER="mem
      rcode = 1
    end /* substr(rep.c,1,6)= 'COPY  ' */
  end /* c = 1 to rep.0 */
  "execio" queued() "diskw OANDFDEL (finis)"
  if rc ^= 0 then call exception rc 'DISKW to OANDFDEL failed.'
end /* action = 'DELETE' */

exit rcode

/*---------------------- S U B R O U T I N E S ----------------------*/

/*-------------------------------------------------------------------*/
/* Create ndm cards                                                  */
/*-------------------------------------------------------------------*/
process:
 parse arg snode

 filein1  = "'PREV.P"sub"."type'.'ele"' - "
 fileout1 = "'PGEV.P"sub"."type'.'ele"' - "
 filein2  = "'PREV.P"sub"."type".B"substr(ele,2,7)"' - "
 fileout2 = "'PGEV.P"sub"."type".B"substr(ele,2,7)"'"

 out = out + 1
 data.out = "   SIGNON                                         "
 out = out + 1
 data.out = "    SUBMIT  PROC=PREVDSN2 SNODE="snode"         - "
 out = out + 1
 data.out = "    NEWNAME=R"substr(ele,2,7)" -                  "
 out = out + 1
 data.out = "    &FILEIN1="filein1
 out = out + 1
 data.out = "    &FILEOUT1="fileout1
 out = out + 1
 data.out = "    &FILEIN2="filein2
 out = out + 1
 data.out = "    &FILEOUT2="fileout2
 out = out + 1
 data.out = "   SIGNOFF                                            "

return /* process: */

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
