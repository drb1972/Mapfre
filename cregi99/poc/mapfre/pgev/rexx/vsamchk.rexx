/* rexx */

/* This rexx is responsible for checking input dataset    */
/* name and also checking that the output dataset resides */
/* of either the xxxx/yyyy or aaaa/bbbb systems.          */

parse arg ndvsys ndvsbs ndvele .

say ' '
say ' DATE: 'DATE(e) ' TIME: 'time()
say ' '
say ' '
say ' Endevor is promoting a VSAM record for:-'
say ' '
say ' System : 'ndvsys'              Sub-System: 'ndvsbs
say ' Type   : VSAM            Element   : 'ndvele
say ' '

/* Read in VSAM file to be updated */

 "EXECIO 1 DISKR input (STEM IN. FINIS)"

 PARSE VAR in.1 idsn odsn

 idsn=strip(idsn)
 odsn=strip(odsn)

 say ' Input  Dataset Name: 'idsn
 say ' Output Dataset Name: 'odsn
 say ' '
 call check_dsn_syntax input idsn
 call check_dsn_syntax output odsn
 call check_dsn_exists

 queue " REPRO IDS('"idsn"') OFILE(UNLOAD)"
 queue " "
"EXECIO "QUEUED()" DISKW idcams (FINIS)"
 if rc^=0 then exit 8
 call write_idcams
 exit 0

/* Ensure dataset does not contain quotes and check hlq length */
/* Also check input=TT||&system and output=PR||&system         */

check_dsn_syntax:

 ARG type chkdsn     .

/* check to see if datasetname is prefixed with a ' or " */
/* if so then strip this info                            */

if substr(chkdsn,1,1)="'" | substr(chkdsn,1,1)='"' then do
   chkdsn=substr(chkdsn,1,(length(chkdsn)-1))
   chkdsn=substr(chkdsn,2)
   if      type=input  then idsn=chkdsn
   else if type=output then odsn=chkdsn
   end

 say ' Checking Dataset Syntax for : 'chkdsn

/* check to dataset name contains a period               */

if pos('.',chkdsn)=0 then do
   Say ' *** ERROR ***               : 'Invalid DSN
   Say ''
   exit 8
   end

/* check to see if hlq=4 bytes long                      */

tsthlq=SUBSTR(chkdsn,1,(POS('.',chkdsn)-1))
if length(tsthlq)^=4 then do
   Say ' *** ERROR ***               : ' HLQ Too Long
   Say ''
   exit 8
   end

/* check to see if idsn=tt||&system                      */

if type=input & substr(chkdsn,1,4)^='TT'||ndvsys then do
   Say ' *** ERROR *** : Input Dataset must be prefixed TT'||ndvsys
   Say ''
   exit 8
   end

if type=output & substr(chkdsn,1,4)^='PR'||ndvsys then do
   Say ' *** ERROR *** : Output Dataset must be prefixed PR'||ndvsys
   Say ''
   exit 8
   end

 say ' Dataset Syntax OK'
 say ' '
return

/* Check input dataset exists and output dsn exists at either  */
/* site                                                        */

check_dsn_exists:

 say ' Checking Catalog Entry For Input  DSN: 'idsn

if SYSDSN("'"idsn"'") ^= 'OK' then do
   Say ' *** ERROR *** : Input Dataset must Exist on the XXXX System'
   Say ''
   exit 8
   End

 say ' Input Dataset Successfully Located on the XXXX System'
 say ' '

 say ' Checking Catalog Entry For Output DSN: 'odsn
if SYSDSN("'"odsn"'") ^= 'OK' then do
   say ' Output Dataset not Found on the X/Y System - Checking SMG List'
   "EXECIO * DISKR SMGLIST (STEM SMG. FINIS)"
   do i=1 to smg.0
      if pos(odsn,smg.i)^=0 then dsn_found=yes
      end
   if dsn_found=yes then say ' Output Dataset Found on SMG List'
   else do
      say ' Output Dataset not Found on SMG List'
      exit 8
      end
   end

return

write_idcams:

 say ' Writing out Idcams records for SMG rename job'

QUEUE " "
QUEUE " LISTC ENT('"ODSN"')"
QUEUE " "
QUEUE "    IF LASTCC > 0 THEN SET MAXCC = 4 "
QUEUE "    ELSE DO "
QUEUE " "
QUEUE "       DEF CL(NAME('"ODSN".SMGNEW') - "
QUEUE "           MODEL ('"ODSN"')) - "
QUEUE "           DATA  (NAME('"ODSN".SMGNEW.DATA')) - "
QUEUE "           INDEX (NAME('"ODSN".SMGNEW.INDEX')) "
QUEUE " "
QUEUE "       IF LASTCC GT 0 THEN SET MAXCC=8 "
QUEUE "       ELSE DO "
QUEUE " "
QUEUE "          REPRO IFILE(INDD) ODS('"ODSN".SMGNEW') "
QUEUE " "
QUEUE "          IF LASTCC GT 0 THEN SET MAXCC=8 "
QUEUE "          ELSE DO "
QUEUE " "
QUEUE "             ALTER   '"ODSN"' - "
QUEUE "             NEWNAME('"ODSN".SMG"||DATE(J)"') "
QUEUE "             IF LASTCC GT 0 THEN SET MAXCC=8 "
QUEUE "             ALTER   '"ODSN".DATA' - "
QUEUE "             NEWNAME('"ODSN".DATA.SMG"||DATE(J)"') "
QUEUE "             IF LASTCC GT 0 THEN SET MAXCC=8 "
QUEUE "             ALTER   '"ODSN".INDEX' - "
QUEUE "             NEWNAME('"ODSN".INDEX.SMG"||DATE(J)"') "
QUEUE " "
QUEUE "             IF LASTCC GT 0 THEN SET MAXCC=8 "
QUEUE "             ELSE DO "
QUEUE " "
QUEUE "                ALTER   '"ODSN".SMGNEW' - "
QUEUE "                NEWNAME('"ODSN"') "
QUEUE "                IF LASTCC GT 0 THEN SET MAXCC=8 "
QUEUE "                ALTER   '"ODSN".SMGNEW.DATA' - "
QUEUE "                NEWNAME('"ODSN".DATA') "
QUEUE "                IF LASTCC GT 0 THEN SET MAXCC=8 "
QUEUE "                ALTER   '"ODSN".SMGNEW.INDEX' - "
QUEUE "                NEWNAME('"ODSN".INDEX') "
QUEUE " "
QUEUE "                IF LASTCC GT 0 THEN SET MAXCC=8 "
QUEUE " "
QUEUE "                END "
QUEUE "             END "
QUEUE "          END "
QUEUE "       END "

"EXECIO "QUEUED()" DISKW vsamcntl (FINIS)"
if rc^=0 then exit 8

return
