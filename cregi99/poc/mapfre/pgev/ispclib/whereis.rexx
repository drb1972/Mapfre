/***rexx*********************************************************/
/** PROGRAM: Whereis                                           **/
/** Author: Stuart Ashby                                       **/
/** DATE: Started 02/06/2004                                   **/
/**                                                            **/
/** Function: This rexx uses the Endevor API to show where an  **/
/** element is in Endevor                                      **/
/****************************************************************/

trace o
address tso
uid = sysvar(sysuid)

panel:

/* Display input panel */
zcmd = ''
address ispexec "DISPLAY PANEL(WHEREIS)"

/* If rc 8 then PF3 was pressed */

if rc = 8 then
  do
    exit
  end

if mode = 'B' then do
  x = msg('ON')
  address ispexec "VGET (JNAME) PROFILE"
  address ispexec 'ftopen temp'
  address ispexec 'ftincl ' WHEREIS
  address ispexec 'ftclose'
  address ispexec 'vget (ztempf) shared'
  address tso     "submit '"ztempf"'"
  signal panel
end

if mode = 'F' then
  do
  x = msg(off)
  address ispexec "VGET (TELM) PROFILE"
  /* Allocate ddnames required by API */
  "FREE DD(SYSOUT,SYSPRINT,BSTERR,APIMSGS,APIEXTR)"
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
  queue 'ALELMPAA UNIT                     'telm
  queue 'RUN'
  queue 'AACTLY'
  queue 'RUN'
  queue 'QUIT'

  /* write the sysin */
  "EXECIO "QUEUED()" DISKW SYSIN (FINIS"
  /* Call Endevor assuming that NDVRC1 is already active */
  "CALL 'SYSNDVR.CAI.AUTHLIB(ENTBJAPI)'"

  /* Check return code and execute Endevor from a link listed
     library if the previous call fails rc 12 */
  select
    when rc = 0 then
      "FREE DD(SYSOUT,SYSPRINT,BSTERR,APIMSGS,SYSIN)"
    when rc = 12 then do
      rcode = 12
      "CALL 'SYSNDVR.CAI.AUTHLIB(NDVRC1)' 'ENTBJAPI'"
      rcode = rcode + rc
      "FREE DD(SYSOUT,SYSPRINT,BSTERR,APIMSGS,APIEXTR,SYSIN)"
    end /* end do */
    otherwise do
      say 'RETURN CODE IS' rc
      exit
    end /* end do */
  end /* end select */

  /* Read in the API extract file */
  "EXECIO * DISKR APIEXTR (STEM dslist. FINIS)"
  "FREE DD(APIEXTR)"

  /* if the api extract file is empty, then set a message and go back
     to the primary panel */
  if dslist.0 = 0 then do
    messinv = 'No elements found, check the spelling. If it is correct'
    messinv2 = ', make sure Endevor is started in your TSO session'
    "ISPEXEC ADDPOP"
    "ISPEXEC DISPLAY PANEL(WHEREIS3)"
    "ISPEXEC REMPOP"
    signal panel /* display primary panel for correction */
  end /* end do */

  /* sort the API extract into stage id order */

  /* Allocate the ddnames required */
  "ALLOC DD(SORTIN) LRECL(2048) NEW,
   RECFM(V B) DSORG(PS) BLKSIZE(22800) SPACE(75,75) TRACKS REUSE"
  "EXECIO * DISKW SORTIN (stem dslist. FINIS"
  "ALLOC DD(SORTOUT) NEW,
   RECFM(V B) DSORG(PS) BLKSIZE(22800) SPACE(75,75) TRACKS REUSE"
  "ALLOC DD(SYSIN) LRECL(80) NEW,
   RECFM(F B) DSORG(PS) BLKSIZE(0) SPACE(1,1) TRACKS REUSE"
  "ALLOC DD(SYSOUT) SYSOUT"

  /* Build & write the sort sysin */
  queue " SORT FIELDS=(66,1,CH,A,58,8,CH,A)"
  "EXECIO "queued()" DISKW SYSIN (FINIS"

  /* run the sort */
  address ispexec "SELECT PGM(SORT)"

  if rc ^= 0 then do
    say "Sort failed, contact Endevor Support +44 (0)123 963 8560"
    exit
  end /* End do */
  else
    "FREE DD(SYSIN,SORTIN,SYSOUT)"

  /* Load the API extracted records in to a table */

  /* Read in the API extract file */
  "EXECIO * DISKR SORTOUT (STEM dslist. FINIS)"
  "FREE DD(SORTOUT)"

  /* if the api extract file is empty, then set a message and go back
     to the primary panel */
  if dslist.0 = 0 then do
    messinv = 'No elements found, check the spelling. If it is correct'
    messinv2 = ', make sure Endevor is started in your TSO session'
    "ISPEXEC ADDPOP"
    "ISPEXEC DISPLAY PANEL(WHEREIS3)"
    "ISPEXEC REMPOP"
    signal panel /* display primary panel for correction */
  end /* end do */

  /* Create a temp table */
  "ISPEXEC TBCREATE "uid" NAMES(ENV SYS SUB ELE TYP STG PRO CCI COM)
   NOWRITE"
  do i = 1 to dslist.0

    /* Build up the column data */
    env = substr(dslist.i,15,4)
    sys = substr(dslist.i,23,2)
    sub = substr(dslist.i,31,3)
    ele = substr(dslist.i,39,8)
    typ = substr(dslist.i,49,8)
    stg = substr(dslist.i,57,1)
    pro = substr(dslist.i,71,8)
    cci = substr(dslist.i,156,12)
    com = substr(dslist.i,168,40)

    /* Add the data to a row in the table */
    "ISPEXEC TBADD "uid
  end
  "ISPEXEC TBTOP "uid

  /* Set the panel return code to zero */
  prc = 0
  cursor = 'CURSOR( )'
  csrrow = 'CSRROW(1)'
  message = 'MSG( )'

  /* Display the table in scrollable panel format         */
  "ISPEXEC TBTOP "uid

  /* Do whilst the selection panel does not have PF3 entered       */
  do while prc ^= 8

    "ISPEXEC TBDISPL "uid" PANEL(WHEREIS2)" message cursor csrrow ,
    "AUTOSEL(NO) POSITION(CRP)"

    /* save panel return code & get the line command in upper case */
    prc = rc
    upper zcmd
    cursor = 'CURSOR( )'
    csrrow = 'CSRROW(1)'

    select
      when zcmd = 'BACK' then do
        "ISPEXEC TBCLOSE "uid
        signal panel
      end /* end do */
      when zcmd = 'END' then do
        "ISPEXEC TBCLOSE "uid
        exit
      end /* end do */
      when zcmd = 'RETURN' then do
        "ISPEXEC TBCLOSE "uid
        signal panel
      end /* end do */
      otherwise do
        "ISPEXEC TBCLOSE "uid
        signal panel
      end /* end do */
    end /* end select */
  end /* end do */

  "ISPEXEC TBCLOSE "uid

End /* end of foreground mode */

exit

