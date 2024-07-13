/*--------------------------REXX----------------------------*\
 *  Used to submit a C or B job on a remote system          *
 *  Submits jobs on plexes where CA7 is not an option       *
 *  This can be triggered by a C or B job any host plex     *
 *----------------------------------------------------------*
 *  Author:     Emlyn Williams                              *
 *              Endevor Support                             *
\*----------------------------------------------------------*/
trace n

arg reqdest jobname rdests
/* reqdest = jesnode from which remote submits are requested        */
/* jobname = the job name to be submitted on the remote node        */
/* rdests  = the remote destinations to submit the jobs on          */

/* read in the supplied information from destinfo                   */
/* joblib.dest=                                                     */
/* jesnode.dest=                                                    */
"execio * diskr destinfo (stem lines. finis"
do i = 1 to lines.0
  interpret lines.i
end

maxrc = 0

say "EVRMTSUB: Submit" jobname "on remote destinations" rdests
say "EVRMTSUB: from destination" reqdest
currnode = sysvar(sysnode)
say "EVRMTSUB: Running on" currnode

reqnode = jesnode.reqdest
if reqnode = 'JESNODE.' || reqdest then do
  say "EVRMTSUB: Error JESNODE not specified for destination",
      reqdest "in DESTINFO"
  exit 12
end

if reqnode = currnode then  /* were on the right plex to submit */
  do i = 1 to words(rdests) /* loop through rdests */
    rmtdest = word(rdests,i)
    rmtnode = jesnode.rmtdest
    if rmtnode = 'JESNODE.' || rmtdest then do
      say "EVRMTSUB: Error JESNODE not specified for destination",
           rmtdest "in DESTINFO"
      exit 12
    end
    say ""
    say "EVRMTSUB: Submit on remote node" rmtnode "requested for",
        "destination" rmtdest
    if rmtnode ^= currnode then do /* unlikely but possble */
      joblib = joblib.rmtdest
      if joblib = 'JOBLIB.' || rmtdest then do
        say "EVRMTSUB: Error JOBLIB not specified for destination",
             rmtdest "in DESTINFO"
        exit 12
      end
      queue "//EVL6001D JOB CLASS=N,MSGCLASS=Y"
      queue "/*ROUTE XEQ" rmtnode
      queue "/*ROUTE PRINT" rmtnode
      queue "//*"
      queue "//* SUBMITS C/BJOBS TO THE INTERNAL READER."
      queue "//* TO RESTART, DEMAND THE C/BJOB ON THE HOST DESTINATION"
      queue "//* AND COMMENT OUT ALL STEPS BUT TSOSUB."
      queue "//* TO OVERRIDE THE JCL COPY IT TO PGEV.AUTO.CMJOBS ON THE"
      queue "//* REMOTE DESTINATION"
      queue "//*"
      queue "//SUBMIT   EXEC PGM=FILEAID"
      queue "//SYSPRINT DD  SYSOUT=*"
      queue "//SYSLIST  DD  SYSOUT=*"
      queue "//DD01     DD DISP=SHR,DSN=PGEV.AUTO.CMJOBS"
      queue "//         DD DISP=SHR,DSN="joblib
      queue "//DD01O    DD SYSOUT=(A,INTRDR)"
      queue "//SYSIN    DD *"
      queue '$$DD01 COPY MEMBER='jobname','
      queue '       REPL=(1,80,C"@SASBSTR,HLQ=PROS,LOCN=FROW",'
      queue '       C"PGM=IEFBR14 NO CA7FROW ON MPLEX")'
      queue "//*"
      queue "//CHECKIT  IF SUBMIT.RC NE 0 THEN"
      queue "//@SPWARN  EXEC @SPWARN"
      queue "//CHECKIT  ENDIF"
      queue ""
      address tso "submit *"  /* submit JCL */
      subrc = rc
      say "EVRMTSUB: Submit RC =" subrc
      subrc = abs(subrc)
      if subrc > maxrc then
        maxrc = subrc
    end
    else do
      say "EVRMTSUB: Remote node" rmtnode "= current node" currnode
      say "EVRMTSUB: No submit on" rmtnode "for destination" rmtdest
    end
  end
else
  say "EVRMTSUB: Not running on destination" reqdest,
      "no jobs submitted"

exit maxrc
