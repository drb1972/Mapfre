/* REXX - Routine to submit the current selected row/element
          (great sample for any routine that needs a copy of the source)

   Copyright (C) 2022 Broadcom. All rights reserved.

   THESE SAMPLE ROUTINES ARE DISTRIBUTED BY BROADCOM "AS IS".
   NO WARRANTY, EITHER EXPRESSED OR IMPLIED, IS MADE FOR THEM.
   BROADCOM CANNOT GUARANTEE THAT THE ROUTINES ARE
   ERROR FREE, OR THAT IF ERRORS ARE FOUND, THEY WILL BE CORRECTED.

*/

/* Common Preamble */
if ARG(1) == "DESCRIPTION" THEN
   RETURN "Submit the current Element (JCL) as job and capture the jobname/num"
/* End of Preamble */

parse arg PassParm
PassName = strip(PassParm,,"'")
ADDRESS ISPEXEC "VGET ("PASSNAME") SHARED"
interpret 'ALLVALS = 'PassName
ADDRESS ISPEXEC "VGET ("ALLVALS") SHARED"       /* Retrieve all the values */
ADDRESS ISPEXEC "VGET ("EEVCCID EEVCOMM") ASIS" /* get CCID and COMMENT */
  /*
       On entry Set a default processing message
  */
  Call Set_default_Message
  /*
       Set a ds prefix and allocate temp file(s)
  */
  Call Alloc_Temp_file
  /*
       Build the Retrieve SCL for the element
  */
  Call Build_Retrieve_SCL
  /*
       Now submit the API retrieve request
  */
  Call Execute_API_Action
  /*
       For debugging view the retrieved JCL...
     ADDRESS ISPEXEC "LMINIT DATAID(SUID) DDNAME("SUBDDPR"SUDD)"
     ADDRESS ISPEXEC "VIEW DATAID(&SUID)"
     ADDRESS ISPEXEC "LMFREE DATAID(&SUID)"
  */
  /*
       Now submit the Job and capture the jobname...
       storing the job name for the message and SUBHIST
       (and cleanup/delete any temporary files)
  */
  Call Submit_n_save_job
  /*
        Finally (re)set the message for the current row
  */
  USERMSG = '*Submitted'
  ADDRESS ISPEXEC "VPUT (USERMSG) SHARED"
exit 0


/****************************************************************************/

Set_default_Message:                      /* Save the Return message        */
USERMSG =  '*Submitted'
ADDRESS ISPEXEC "VPUT (USERMSG) SHARED"
return

/****************************************************************************/

Alloc_Temp_file:                          /* We need to retrieve to and submit
                                             from a catalogued dataset
*/
   ADDRESS ISPEXEC "VGET (ZSCREEN ZUSER zSYSID ZPREFIX)"
   /* Decide on Temporary DD prefix                                      */
   SUBDDPR = "SU" || ZSCREEN                /* set DD prefix       */
   /* Decide on Temporary Dataset name prefix...                         */
   if zSYSID = SPECIAL then do              /* is this a special system? */
      /* insert system specific logic if required here                   */
      SubDsPrefix = left(zUSER,3)||'.'|| ,
         zUser'.'STRIP(LEFT('E'||ZSYSID,8))||'.USUB'||ZSCREEN
      end
   else /* otherwise we use some sensible defautls                       */
     if zPrefix \= '',                      /* is Prefix set?  and NOT.. */
      & zPrefix \= zUSER then do            /* the same as userid?       */
        SubDsPrefix = zPrefix ||'.'|| ,
           zUser'.'STRIP(LEFT('E'||ZSYSID,8)) || '.USUB'||ZSCREEN
        end
     else do                                /* otherwise use user name   */
        SubDsPrefix = zUser ||'.'|| ,
           STRIP(LEFT('E'||ZSYSID,8)) || '.USUB' || ZSCREEN
     end

   /* delete any preexisting files */

   CALL OUTTRAP "out."
      "FREE  F("SUBDDPR"SUDD)"
      "DELETE '"SubDsPrefix".JCL.TEMP'"
      "FREE  F(C1MSGS1)"
      "DELETE '"SubDsPrefix".MSG1.TEMP'"
      "FREE  F(C1MSGSA)"
      "DELETE '"SubDsPrefix".MSGA.TEMP'"
   CALL OUTTRAP "OFF"

   ADDRESS TSO,
   "ALLOC F("SUBDDPR"SUDD) LRECL(80) BLKSIZE(0) SPACE(5,5) ",
   "DA('"SubDsPrefix".JCL.TEMP')",
    "DSORG(PS)",
     "RECFM(F B) TRACKS NEW CATALOG REUSE " ;

return

/****************************************************************************/

Build_Retrieve_SCL:

   sa=SAVESCL(RESET)                    /* reset our cache of SCL lines */
   /* retrieve for JCL element */
   sa=SAVESCL(" RETRIEVE ELEMENT ")
   sa=SAVESCL("'"EEVETKEL"'")
   IF LENGTH(EEVETDVL) = 4 THEN,
      sa=SAVESCL(" VERSION" SUBSTR(EEVETDVL,1,2),
               "LEVEL " SUBSTR(EEVETDVL,3,2));
   ELSE,
      sa=SAVESCL("* Current Version Level")
   sa=SAVESCL(" FROM ENVIRONMENT "EEVETKEN " SYSTEM "EEVETKSY)
   sa=SAVESCL(" SUBSYSTEM "EEVETKSB " TYPE "EEVETKTY " STAGE" EEVETKSI)
   sa=SAVESCL(" TO DDNAME '"SUBDDPR"SUDD' OPTIONS NO SIGNOUT NOSEARCH REPLACE.")
   /* Append an EOF flag */
   sa=SAVESCL(" EOF. ")
   return;

/****************************************************************************/

Execute_API_Action:

   /* set up parms with SCL TYPE:E (Element Action) and messages DD */
   MY_PARMS = LEFT('*SCLTYPE:E MSGS:C1MSGSA',80) || ,
              SAVESCL(GETALL)   /* retrieve the accumulated SCL */
   SA= my_parms ;

   ADDRESS TSO,
   "ALLOC F(C1MSGS1) LRECL(133) BLKSIZE(26600) SPACE(5,5) ",
   "DA('"SubDsPrefix".MSG1.TEMP')",
    "DSORG(PS)",
     "RECFM(V B) TRACKS MOD CATALOG REUSE " ;
   ADDRESS TSO,
   "ALLOC F(C1MSGSA) LRECL(133) BLKSIZE(26600) SPACE(5,5) ",
   "DA('"SubDsPrefix".MSGA.TEMP')",
     "DSORG(PS) RECFM(V B) TRACKS MOD CATALOG REUSE " ;
   ADDRESS TSO "ALLOC FI(SYSOUT)  DUMMY SHR REUSE"
   ADDRESS LINKMVS 'NDUSASCL MY_PARMS'
   API_RC = RC ;
   If API_RC > 4   THEN,
      Do
      ADDRESS ISPEXEC "LMINIT DATAID(DDID) DDNAME(C1MSGS1)"
      ADDRESS ISPEXEC "VIEW DATAID(&DDID)"
      ADDRESS ISPEXEC "LMFREE DATAID(&DDID)"
      End;

   RETURN;



/****************************************************************************/
Submit_n_save_job: /* submit current ZTEMPF job and save job info       */
   ADDRESS ISPEXEC "VGET (SUBHIST) SHARED"
   if SUBHIST = '' then
      SUBHIST  = "***"                         /* initialise history  */

   CALL MSG "ON"
   x = Outtrap("out.",10,"NOCONCAT")    /* Trap output                */
   address tso "PROFILE"                /* Get current profile values */
   intercom = 'INTERCOM'                /* Default setting if not fnd */
   If out.0 \= 0 Then Do
      Parse Upper Var out.1 . . . p4 p5 p6 . /* Save profile settings */
      Address  TSO "PROFILE NOINTERCOM" /* Please do not disturb      */
   End

   ADDRESS TSO "SUBMIT '"SubDsPrefix".JCL.TEMP'";
   CALL OUTTRAP "OFF"
   Address  TSO "PROFILE" p4 p5 p6      /* Restore profile settings   */
   DO k = 1 TO out.0
   /*                                                                */
   /* Added support for up to 7-digit job names (only seen 6)        */
   /*                                                                */
      PARSE VAR out.k WITH . "JOB " jobnam "(J" JOBNUM ")" .
      if left(jobnum,2) == 'OB' then    /* If we have .(JOBnnnnn)     */
        jobnum = right(substr(jobnum,3),7,'0')
      else
        if left(jobnum,1) == 'O' then   /* or we have .(JOnnnnnn)     */
          jobnum = right(substr(jobnum,2),7,'0')
      if jobnum == '' then jobnum = '*' /* default to last fnd        */
   END
   LNLASACT = 'Submit'
   ZEDSMSG = jobnam || '(' || jobnum || ') Sub''d'
   SUBHIST = left(Date(N),06,'00'x)copies('00'x,1)left(Time(N),09,'00'x),
     ||LEFT(LEFT(ZEDSMSG,POS(')',ZEDSMSG)),18,'00'x),
     /* DEV/1/ESCM181/SIQ07777/REXX */ ,
     ||LEFT(STRIP(EEVETKEN)||'/',
     ||STRIP(EEVETKSI)||'/',
     ||STRIP(EEVETKSY)||'/',
     ||STRIP(EEVETKSB)||'/',
     ||STRIP(EEVETKEL)||'/',
     ||STRIP(EEVETKTY)||'00'x,
     ||STRIP(EEVCCID)||'00'x,
     ||STRIP(EEVCOMM),
     ,42,'00'x)||'00'x, /* always include white space for the word wrap */
     || SUBHIST
   ZEDLMSG = LEFT('SUBMITTED JOBS HISTORY (THIS SESSION)',77,'00'X)||SUBHIST
   ADDRESS ISPEXEC "VPUT (SUBHIST) SHARED"  /* Update history value  */
   ADDRESS ISPEXEC "SETMSG MSG(ENDE218W)"

   /* Free and delete files */

   IF API_RC = 0 then do     /* if all was well... clenup before exit*/
      CALL OUTTRAP "out."
         "FREE  F("SUBDDPR"SUDD)"
         "DELETE '"SubDsPrefix".JCL.TEMP'"
         "FREE  F(C1MSGS1)"
         "DELETE '"SubDsPrefix".MSG1.TEMP'"
         "FREE  F(C1MSGSA)"
         "DELETE '"SubDsPrefix".MSGA.TEMP'"
      CALL OUTTRAP "OFF"
   end
  RETURN ;

/****************************************************************************/

SaveScl : procedure  expose SCLLINE. /* This routine handles accumulating
                                        SCL lines until it's time to pass
                                        them off to the execute routine

                                        Eventually it might handle auto
                                        formatting long lines but at first
                                        the goal is just to save each line
                                        passed and increment the counter.
                                        */
if ARG(1) == 'RESET' then do         /* reset */
   SCLLINE. = ''                     /* reset stem var */
   SCLLINE.0 = 0                     /* and counter */
   return SCLLINE.0                  /* normaly return the number of lines */
end

if ARG(1) == 'EXECIO' then do        /* We need to write our lines to arg(2) */
   OUTDD = ARG(2)                    /* reset Output   */
   "EXECIO * DISKW" OUTDD "(STEM SCLLINE. FINIS" /* write all output */
   return RC                         /* Return The RC in this case */
end

if ARG(1) == 'GETALL' then do        /* Return all SCL */
   ALLSCL = ''                       /* reset Output   */
   do I = 1 to SCLLINE.0             /* For each saved line */
     ALLSCL = ALLSCL || LEFT(SCLLINE.i,80) /* append the SCL line */
   end
   return ALLSCL                     /* Return all the SCL as a single str */
end
        /* still here?  Must have some SCL to save... */
   do j = 1  by 72 while j < length(ARG(1))
      i = SCLLINE.0 + 1              /* increment the line count */
      SCLLINE.i = substr(ARG(1),j,72)/* save next chunk */
      SCLLINE.0 = i                  /* and the new count */
   end
   return SCLLINE.0                  /* always return the number of lines */

exit 999                             /* should never hit this */
