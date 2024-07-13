/* this rexx reads all the archive statements built and remove   */
/* any referring to system EV - Endevor Support                  */
/* Note: Does a dummy arch in case nothing to archive to set rc  */
/* Jobname - EVHEMERD S.Batt 20/04/98.                           */

/* read all records                                              */

"execio * diskr archin   (stem arch. finis"
  cc = rc
    if cc > 0 then do
      say 'EVHEMER3: execio of ARCHIN ddname gave a return code of 'cc
      exit cc
    end /* if cc > 0 then do */

/* Queue initial SET SCL statements for ARCHIVE                  */

Queue " SET OPTIONS CCID     'NDVR#SUPPORT'                        "
Queue "             COMMENT  'ARCHIVE FROM STAGE  O'               "
Queue "             OVERRIDE SIGNOUT  .                            "
Queue "                                                            "
Queue " SET FROM    ENVIRONMENT  PROD   SYSTEM  EV  SUBSYSTEM  EV1 "
Queue "             TYPE         DATA   STAGE NUMBER 2 .           "
Queue "                                                            "
Queue " SET TO      DDNAME   ARCHIVE  .                            "
Queue "                                                            "
Queue " ARCHIVE ELEMENT  'EVHEMERD' OPTIONS BYPASS ELEMENT DELETE ."
Queue "                                                            "

/* scan the records                                                 */
/* if it is EV/EK then set flag to delete else set to queue         */

do c=1 to arch.0
   check1=index(arch.c,'SET FROM')
   if check1^=0 then do
       check2=index(arch.c,"'EV")
       check3=index(arch.c,"'EK")
      if check2^=0|,
         check3^=0 then action=delete
      else action=queue
   end /* if check1^=0 then do */
   if action^=delete then queue arch.c
end /* do c=1 to arch.0 */

/* write out the archive statements to temp file                 */

"EXECIO "QUEUED()" DISKW archout1 (FINIS)"
  cc = rc
    if cc > 0 then do
      say 'EVHEMER3: execio of ARCHOUT1 ddname gave a return code of 'cc
      exit cc
    end /* if cc > 0 then do */

 "execio * diskr archout1 (finis)"
  cc = rc
    if cc > 0 then do
      say 'EVHEMER3: execio of ARCHOUT1 ddname gave a return code of 'cc
      exit cc
    end /* if cc > 0 then do */

Push '   '
push date(e)' EVHEMERD Executed at 'time()
push '   '

"EXECIO "QUEUED()" DISKW archout2 (FINIS)"
  cc = rc
    if cc > 0 then do
      say 'EVHEMER3: execio of ARCHOUT2 ddname gave a return code of 'cc
      exit cc
    end /* if cc > 0 then do */

say "EVHEMER3: Check the following dataset         "
say "EVHEMER3: PREV.NENDEVOR.EVHEMERD.STAGEO.SCL(0)"
say "EVHEMER3: to see what SCL was generated       "
exit 0;
