/*-----------------------------REXX----------------------------------*\
 *  This is called from the SCANLIST dialog.                         *
 *  It builds a job to scan listings, build summary report and SCL.  *
\*-------------------------------------------------------------------*/
trace n

parse arg action type dsn scantype split build_scl strings

if build_scl ^= 'N' then
  address ISPEXEC 'DISPLAY PANEL(SCANL2)' /* Get CCID, comment etc.  */

/* Set up the type string to scan for                                */
if right(type,1) = '*' then
  typesel = substr(type,1,length(type)-1)
else
  typesel = type

address ispexec "VGET (zprefix) SHARED"

parse source . . . dd rexxdsn .      /* DSN where the rexx runs from */
if rexxdsn = ? then do
  z = listdsi(dd file)
  rexxdsn = sysdsname
end /* rexxdsn = ? */

selected = 0
sclcount = 0
t        = time()
tdsn     = 'TTEV.TMP.SCANLIST.D'date(j)'.T' || ,
           left(t,2)substr(t,4,2)right(t,2)

/* Check the DSN exists                                              */
test  = msg('off')
check = sysdsn("'"dsn"'")
test  = msg('on')
if check <> OK then do
  zedsmsg = 'DSN NOT FOUND'
  zedlmsg = 'LISTING file' dsn 'is not cataloged'
  address ispexec 'setmsg msg(ISRZ001)'
  exit
end /* check <> OK */

call get_member_list

/* Check the number of listings to select                            */
do i = 1 to members.0
  ltype   = substr(members.i,163,8)
  stype   = substr(ltype,1,length(typesel))
  if stype = typesel then
    selected = selected + 1
end /* i = 1 to members.0 */

if selected = 0 then do
  zedsmsg = 'No members selected'
  zedlmsg = 'No members of type' type 'selected'
  address ispexec 'setmsg msg(ISRZ001)'
  exit
end /* check <> OK */

if selected > 1000 & ,
   scantype = 'E'  then do
  zedsmsg = 'Selected Listings > 1000'
  zedlmsg = selected 'selected - Use fast scan instead or use discrete type'
  address ispexec 'setmsg msg(ISRZ001)'
  exit
end /* check <> OK */

/* Set up the string(s) to search for                                */
x = pos('³',strings,2)
string1 = substr(strings,2,x-2)
strings = substr(strings,x+3)
x = pos('³',strings)
string2 = substr(strings,1,x-1)
strings = substr(strings,x+3)
x = pos('³',strings)
string3 = substr(strings,1,x-1)
strings = substr(strings,x+3)
x = pos('³',strings)
string4 = substr(strings,1,x-1)

/* Build the JCL                                                     */
address ispexec
'vget (zscreen)'
'vget (c1bjc1) profile'
'vget (c1bjc2) profile'
'vget (c1bjc3) profile'
'vget (c1bjc4) profile'
address tso
if c1bjc1         <> ''    & ,
   left(c1bjc1,3) <> '//*' then queue c1bjc1
if c1bjc2         <> ''    & ,
   left(c1bjc2,3) <> '//*' then queue c1bjc2
if c1bjc3         <> ''    & ,
   left(c1bjc3,3) <> '//*' then queue c1bjc3
if c1bjc4         <> ''    & ,
   left(c1bjc4,3) <> '//*' then queue c1bjc4
queue "//*                                                            "
queue "//* JCL CREATED BY THE SCANLIST DIALOG                         "
queue "//*                                                            "
queue "//NDVR010  EXEC PGM=IEFBR14                                    "
queue "//DELTMP   DD DISP=(MOD,DELETE),DSN="tdsn","
queue "//            SPACE=(TRK,(1,1))                                "
queue "//*                                                            "
queue "//* GET THE LISTING FILE MEMBER LIST                           "
queue "//*                                                            "
queue "//NDVR020  EXEC PGM=NDVRC1,PARM='BC1PFOOT'                     "
queue "//BSTLST   DD SYSOUT=Z                                         "
queue "//APIPRINT DD SYSOUT=Z                                         "
queue "//BSTPCH   DD DSN=&&LISTMEMS,DISP=(NEW,PASS),                  "
queue "//            SPACE=(TRK,(15,45),RLSE),                        "
queue "//            LRECL=838,RECFM=FB                               "
queue "//BSTPDS   DD DISP=SHR,DSN="dsn
queue "//BSTIPT   DD *                                                "
queue "   ANALYZE .                                                   "
queue "/*                                                             "
queue "//CHECK020 IF NDVR020.RC GT 4 THEN                             "
queue "//NDVR025  EXEC @SPWARN                                        "
queue "//CHECK020 ENDIF                                               "
queue "//*                                                            "
queue "//* BUILD THE PRINT STATEMENTS AND SPLIT LINES                 "
queue "//*                                                            "
queue "//NDVR030  EXEC PGM=IKJEFT1B,PARM='SCAN2 "type dsn"'"
call evexecr /* Add SYSEXEC DD                                       */
queue "//SYSTSIN  DD DUMMY                                            "
queue "//LISTMEMS DD DISP=(OLD,DELETE),DSN=&&LISTMEMS                 "
queue "//PRINTSCL DD DISP=(NEW,PASS),DSN=&&PRINTSCL,                  "
queue "//            SPACE=(TRK,(5,15),RLSE),                         "
queue "//            RECFM=FB,LRECL=80                                "
queue "//SPLITS   DD DISP=(NEW,PASS),DSN=&&SPLITS,                    "
queue "//            SPACE=(TRK,(5,15),RLSE),                         "
queue "//            RECFM=FB,LRECL=80                                "
queue "//ERROR    DD SYSOUT=*                                         "
queue "//SYSTSPRT DD SYSOUT=Z                                         "
queue "//*                                                            "
queue "//CHECK030 IF NDVR030.RC GT 0 THEN                             "
queue "//NDVR035  EXEC @SPWARN                                        "
queue "//CHECK030 ENDIF                                               "
queue "//*                                                            "
queue "//* WRITE OUT THE SPLIT LINES                                  "
queue "//*                                                            "
queue "//NDVR040  EXEC PGM=IEBUPDTE,PARM=NEW                          "
queue "//SYSPRINT DD SYSOUT=Z                                         "
queue "//SYSUT2   DD DISP=(NEW,CATLG),DSN="tdsn","
queue "//            SPACE=(TRK,(45,45),RLSE),DSNTYPE=LIBRARY,        "
queue "//            RECFM=FB,LRECL=80,DSORG=PO                       "
queue "//SYSIN    DD DISP=(OLD,DELETE),DSN=&&SPLITS                   "
queue "//*                                                            "
queue "//CHECK040 IF NDVR040.RC GT 0 THEN                             "
queue "//NDVR045  EXEC @SPWARN                                        "
queue "//CHECK040 ENDIF                                               "
queue "//*                                                            "
queue "//* PRINT OUT THE LISTINGS                                     "
queue "//*                                                            "
queue "//NDVR050  EXEC PGM=NDVRC1,DYNAMNBR=1500,PARM='C1BM3000'       "
queue "//C1SORTIO DD SPACE=(CYL,(50,50)),RECFM=VB,LRECL=32760         "
queue "//APIPRINT DD SYSOUT=Z                                         "
queue "//C1MSGS1  DD SYSOUT=*                                         "
queue "//C1MSGS2  DD SYSOUT=*                                         "
queue "//SYSPRINT DD SYSOUT=*                                         "
queue "//SYSUDUMP DD SYSOUT=C                                         "
queue "//SYSOUT   DD SYSOUT=*                                         "
queue "//SYMDUMP  DD DUMMY                                            "
queue "//LISTINGS DD DISP=SHR,DSN="dsn
queue "//SPLITER  DD DISP=(OLD,DELETE),DSN="tdsn
queue "//C1PRINT  DD DISP=(NEW,PASS),DSN=&&C1PRINT,                   "
queue "//            SPACE=(CYL,(15,300),RLSE),                       "
queue "//            RECFM=FBA,LRECL=133                              "
queue "//BSTIPT01 DD DISP=(OLD,DELETE),DSN=&&PRINTSCL                 "
queue "//*                                                            "
queue "//CHECK050 IF NDVR050.RC GT 0 THEN                             "
queue "//NDVR055  EXEC @SPWARN                                        "
queue "//CHECK050 ENDIF                                               "

if scantype = 'E' then do
  queue "//*                                                          "
  queue "//* SCAN THE LISTINGS                                        "
  queue "//*                                                          "
  queue "//SCAN     EXEC PGM=IKJEFT1B,                                "
  queue "//         PARM='SCAN3" ,
        dsn type selected build_scl 'LIST' slccid
  queue "//             "slretdsn slove slrep"'"
  call evexecr /* Add SYSEXEC DD                                     */
  queue "//SYSTSIN  DD DUMMY                                          "
  queue "//SYSTSPRT DD SYSOUT=Z                                       "
  queue "//C1PRINT  DD DSN=&&C1PRINT,DISP=(OLD,DELETE)                "
  queue "//STRING   DD *                                              "
  if string1 ^= '' then
    queue string1
  if string2 ^= '' then
    queue string2
  if string3 ^= '' then
    queue string3
  if string4 ^= '' then
    queue string4
  queue "/*                                                           "
  queue "//RESULTS  DD SYSOUT=*                                       "
  queue "//SUMMARY  DD SYSOUT=*                                       "
  if build_scl ^= 'N' then
    queue "//SCL      DD SYSOUT=*                                     "
  queue "//*                                                          "
  queue "//CHECKSC  IF SCAN.RC GT 0 THEN                              "
  queue "//SCANFAIL EXEC @SPWARN                                      "
  queue "//CHECKSC  ENDIF                                             "
end /* scantype = 'E' */
else do
  queue "//*                                                          "
  queue "//* SEARCH THE LISTINGS                                      "
  queue "//*                                                          "
  queue "//SEARCH   EXEC PGM=FILEAID                                  "
  queue "//SYSPRINT DD SYSOUT=*                                       "
  queue "//SYSLIST  DD SYSOUT=*                                       "
  queue "//DD01     DD DISP=(OLD,DELETE),DSN=&&C1PRINT                "
  queue "//RES      DD DISP=(NEW,PASS),DSN=&&RES,                     "
  queue "//            SPACE=(TRK,(5,15),RLSE),                       "
  queue "//            RECFM=FBA,LRECL=133                            "
  if split = 'Y' then do
    queue "//RESULT1  DD SYSOUT=*                                     "
    write = '(RESULT1'
    if string2 ^= '' then do
      queue "//RESULT2  DD SYSOUT=*                                   "
      write = write',RESULT2'
    end /* string2 ^= '' */
    if string3 ^= '' then do
      queue "//RESULT3  DD SYSOUT=*                                   "
      write = write',RESULT3'
    end /* string3 ^= '' */
    if string4 ^= '' then do
      queue "//RESULT4  DD SYSOUT=*                                   "
      write = write',RESULT4'
    end /* string4 ^= '' */
    write = write',RES),'
    stub  = ',WRITE=RES'
    queue "//SYSIN    DD *                                            "
    queue "$$DD01 USER IF=(1,8,C' ----- '),WRITE="write
    if string2 ^= '' | ,
       string3 ^= '' | ,
       string4 ^= '' then comma = ','
                     else comma = ' '
    queue "            IF=(1,0,C'"string1"'),WRITE=RESULT1"stub||comma
    if string3 ^= '' | ,
       string4 ^= '' then comma = ','
                     else comma = ' '
    if string2 ^= '' then
      queue "            IF=(1,0,C'"string2"'),WRITE=RESULT2"stub||comma
    if string4 ^= '' then comma = ','
                     else comma = ' '
    if string3 ^= '' then
      queue "            IF=(1,0,C'"string3"'),WRITE=RESULT3"stub||comma
    if string4 ^= '' then
      queue "            IF=(1,0,C'"string4"'),WRITE=RESULT4"stub
  end /* split = 'Y' */
  else do
    queue "//RESULTS  DD SYSOUT=*                                     "
    queue "//SYSIN    DD *                                            "
    queue "$$DD01 USER IF=(1,8,C' ----- '),                           "
    queue "          ORIF=(1,0,C'"string1"'),"
    if string2 ^= '' then
      queue "          ORIF=(1,0,C'"string2"'),"
    if string3 ^= '' then
      queue "          ORIF=(1,0,C'"string3"'),"
    if string4 ^= '' then
      queue "          ORIF=(1,0,C'"string4"'),"
    queue "            WRITE=RESULTS,WRITE=RES                        "
  end /* else */
  queue "/*                                                           "
  queue "//*                                                          "
  queue "//CHECKSR  IF SEARCH.RC GT 4 THEN                            "
  queue "//SRCHFAIL EXEC @SPWARN                                      "
  queue "//CHECKSR  ENDIF                                             "
  queue "//*                                                          "
  queue "//*                                                          "
  if build_scl ^= 'N' then
    queue "//* WRITE SUMMARY                                          "
  else
    queue "//* WRITE SUMMARY AND BUILD SCL                            "
  queue "//*                                                          "
  queue "//BLDSCL   EXEC PGM=IKJEFT1B,                                "
  queue "//         PARM='SCAN3" ,
        dsn type selected build_scl 'FAID' slccid
  queue "//             "slretdsn slove slrep"'"
  call evexecr /* Add SYSEXEC DD                                     */
  queue "//SYSTSIN  DD DUMMY                                          "
  queue "//SYSTSPRT DD SYSOUT=Z                                       "
  queue "//C1PRINT  DD DSN=&&RES,DISP=(OLD,DELETE)                    "
  queue "//STRING   DD *                                              "
  if string1 ^= '' then
    queue string1
  if string2 ^= '' then
    queue string2
  if string3 ^= '' then
    queue string3
  if string4 ^= '' then
    queue string4
  queue "/*                                                           "
  queue "//SUMMARY  DD SYSOUT=*                                       "
  if build_scl ^= 'N' then
    queue "//SCL      DD SYSOUT=*                                     "
  queue "//*                                                          "
  queue "//CHECKBL  IF BLDSCL.RC GT 0 THEN                            "
  queue "//BLDFAIL  EXEC @SPWARN                                      "
  queue "//CHECKBL  ENDIF                                             "
end /* else */
queue ''

jclddn = 'JCL'zscreen
"ALLOC FI("jclddn") space(1 1) track lrecl(80) reus recfm(F B)"

"execio * diskw" jclddn "(finis"
if rc ^= 0 then call exception rc 'DISKW to' jclddn 'failed.'

if action = 'J' then do /* Edit the JCL                              */
  address ispexec
  "lminit dataid(JCL) ddname("jclddn") enq(shr)"
  "EDIT DATAID("jcl")"
  'lmfree dataid('jcl')'
end /* action = 'J' */
else do
  y = listdsi(jclddn file)
  "submit '"sysdsname"'"
  zedsmsg = 'Job submitted'
  zedlmsg = 'SCAN LIST job submitted'
  address ispexec 'setmsg msg(ISRZ001)'
end /* else */

zedsmsg = selected 'members selected'
zedlmsg = selected 'members of type' type 'selected for scan'
address ispexec 'setmsg msg(ISRZ001)'

exit

/*---------------------- S U B R O U T I N E S ----------------------*/

/*-------------------------------------------------------------------*/
/* Get member list from the listing Elib                             */
/*-------------------------------------------------------------------*/
Get_member_list:

 /*  Allocate required d/sets for Endevor call                       */
 address tso
 test = msg(off)
 "FREE F(BSTLST,BSTPCH,BSTPDS,BSTIPT)"
 test = msg(on)

 "ALLOC f(BSTLST) SYSOUT(Z)"
 "ALLOC f(BSTPCH) SPACE(5,45) TRACKS LRECL(838) RECFM(F B)"
 "ALLOC f(BSTPDS) DSNAME('"dsn"') SHR"
 "ALLOC f(BSTIPT) SPACE(5,45) TRACKS LRECL(80)  RECFM(F) REUSE"

 /*  Create input for Endevor call                                   */
 queue ' ANALYZE .'
 queue ' INCLUDE MEMBERS * .'
 "EXECIO "queued()" DISKW BSTIPT (FINIS"
 if rc ^= 0 then call exception rc 'DISKW to BSTIPT failed.'

 /* Call Endevor assuming that NDVRC1 is already active */
 "CALL 'SYSNDVR.CAI.AUTHLIB(BC1PFOOT)'"

 /* Execute Endevor from a the link list if the previous call fails */
 if rc = 12 then
   "CALL 'SYSNDVR.CAI.AUTHLIB(NDVRC1)' 'ENTBJAPI'"

 if rc = 4 then do
   zedsmsg = 'Empty listing library'
   zedlmsg = dsn 'is empty'
   address ispexec
   'setmsg msg(ISRZ001)'
   exit
 end /* check <> OK */

 if rc > 4 then call exception rc 'Footprint report failed RC'

 /*  Read results from Endevor, exit if empty                        */
 "EXECIO * DISKR BSTPCH (STEM members. FINIS)"
 if rc ^= 0 then call exception rc 'DISKR of BSTPCH failed.'

 "FREE F(BSTLST,BSTPCH,BSTPDS,BSTIPT)"

return /* Get_member_list */

/*-------------------------------------------------------------------*/
/* Evexecr - Add rexx SYSEXEC DD                                     */
/*-------------------------------------------------------------------*/
evexecr:

 if substr(rexxdsn,6,4) = 'BASE' then
   queue "//SYSEXEC  DD DISP=SHR,DSN=PGEV.BASE.ISPCLIB                "
 else do
   queue "//SYSEXEC  DD DISP=SHR,DSN=PREV."substr(rexxdsn,6,1) || ,
         "EV1.ISPCLIB"
   queue "//         DD DISP=SHR,DSN=PGEV.BASE.ISPCLIB                "
 end /* substr(rexxdsn,6,4) = 'BASE' */

return /* evexecr */

/*-------------------------------------------------------------------*/
/* Error with line number displayed                                  */
/*-------------------------------------------------------------------*/
exception:
 parse arg return_code comment

 test = msg(off)
 "FREE F(BSTLST,BSTPCH,BSTPDS,BSTIPT)"
 test = msg(on)

 address tso delstack /* Clear down the stack                        */

 parse source . . rexxname . /* Get the rexx name(generic subroutine)*/
 say rexxname':'
 say rexxname':' comment
 say rexxname': Exception called from line' sigl 'RC' return_code

exit return_code
