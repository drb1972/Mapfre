/* REXX - User Routine Sample to display user Data in a pop-up screen

   Copyright (C) 2022 Broadcom. All rights reserved.

   THESE SAMPLE ROUTINES ARE DISTRIBUTED BY BROADCOM "AS IS".
   NO WARRANTY, EITHER EXPRESSED OR IMPLIED, IS MADE FOR THEM.
   BROADCOM CANNOT GUARANTEE THAT THE ROUTINES ARE
   ERROR FREE, OR THAT IF ERRORS ARE FOUND, THEY WILL BE CORRECTED.

*/

/* Common Preamble */
if ARG(1) == "DESCRIPTION" THEN
   RETURN "Display Element UserData in a pop-up menu, and Optionaly change it"
/* End of Preamble */

parse arg PassParm                        /* The Parm tells us what variable  */
PassName = strip(PassParm,,"'")           /* holds the variable names, remove */
ADDRESS ISPEXEC "VGET ("PassName") SHARED"/* any quotes and get these names   */
interpret 'ALLVALS = 'PassName            /* use interpret to expand the names*/
ADDRESS ISPEXEC "VGET ("ALLVALS") SHARED" /* and get those values */
USERDAT1 =SUBSTR(EEVEUSRD,01,40)          /* The EEVEUSRD is 80 bytes, tailor */
USERDAT2 =SUBSTR(EEVEUSRD,41,40)          /* this bit to split it into chunks */
BEFRDAT1 = USERDAT1                       /* Save before values so we can see */
BEFRDAT2 = USERDAT2                       /* if user changed them...          */
ADDRESS ISPEXEC "VPUT (USERDAT1 USERDAT2) SHARED" /* make vars available      */
ADDRESS ISPEXEC "ADDPOP"                  /* Show the panel in a pop-up       */
ADDRESS ISPEXEC "DISPLAY PANEL(NDUSRPUD)" /* then show the panel              */
if rc > 0 then                            /* Did user hit END or RETURN?      */
do
   ADDRESS ISPEXEC "REMPOP"               /* Remove the popup                 */
   ADDRESS ISPEXEC "SETMSG MSG(ENDE046E)" /* Request cancelled                */
   exit 0                                 /* and get out (no changes)         */
end
ADDRESS ISPEXEC "REMPOP"                  /* Remove the popup                 */
ADDRESS ISPEXEC "VGET (USERDAT1 USERDAT2) SHARED" /* get the values           */
USERDAT1 = left(USERDAT1,40)              /* make sure they're 40 chars as    */
USERDAT2 = left(USERDAT2,40)              /* trailing blanks were removed     */
USERMSG = '*NDUSRXUD'                     /* Tell Dialog what happened        */
if BEFRDAT1 == USERDAT1 & ,
   BEFRDAT2 == USERDAT2 then
      ADDRESS ISPEXEC "SETMSG MSG(CIIO607)"
else do
  /*
       we now have enough data to build the Alter SCL and try it...
  */
  Call Build_Alter_SCL
  /*
        Call the API to perform the actions
  */
  Call Execute_API_Action
end
EXIT 0

/****************************************************************************/

Build_Alter_SCL:

   sa=SAVESCL(RESET)                    /* reset our cache of SCL lines */

   ADDRESS ISPEXEC "VGET (EEVCCID EEVCOMM EEVOOSGN)" /*incase they changed*/
   Options = "" ;
   IF EEVOOSGN = "Y" then Options = "OVERRIDE SIGNOUT" ;
   IF EEVCCID /= ""  then Options = options 'CCID  "'EEVCCID'"'
   IF EEVCOMM  = ""  then COMLINE = ' .'
   else do
      IF pos("'",EEVCOMM) > 0 then /* if comment has an apost */
        COMLINE = '   COMMENT "'EEVCOMM'" .'
      else
        COMLINE = "   COMMENT '"EEVCOMM"' ."
   end

if BEFRDAT1 /== USERDAT1 THEN do
   /* Alter first 40 bytes       */
   sa=SAVESCL(" ALTER ELEMENT ")
   sa=SAVESCL("'"EEVETKEL"'")
   sa=SAVESCL(" FROM ENVIRONMENT "EEVETKEN " SYSTEM "EEVETKSY)
   sa=SAVESCL("      SUBSYSTEM   "EEVETKSB " TYPE   "EEVETKTY " STAGE" EEVETKSI)
   sa=SAVESCL(" REPLACE USER DATA WITH (1,40,,")
   if pos('"',USERDAT1) > 0 then           /* any double quote? */
      sa=SAVESCL("   '"left(USERDAT1,40)"')")
   else
      sa=SAVESCL('   "'left(USERDAT1,40)'")')
   sa=SAVESCL(" OPTION UPDATE ELEMENT" options)
   sa=SAVESCL(COMLINE)
end
if BEFRDAT2 /== USERDAT2 THEN do
   /* Alter first 40 bytes       */
   sa=SAVESCL(" ALTER ELEMENT ")
   sa=SAVESCL("'"EEVETKEL"'")
   sa=SAVESCL(" FROM ENVIRONMENT "EEVETKEN " SYSTEM "EEVETKSY)
   sa=SAVESCL("      SUBSYSTEM   "EEVETKSB " TYPE   "EEVETKTY " STAGE" EEVETKSI)
   sa=SAVESCL(" REPLACE USER DATA WITH (41,40,,")
   if pos('"',USERDAT2) > 0 then           /* any double quote? */
      sa=SAVESCL("   '"left(USERDAT2,40)"')")
   else
      sa=SAVESCL('   "'left(USERDAT2,40)'")')
   sa=SAVESCL(" OPTION UPDATE ELEMENT" options)
   sa=SAVESCL(COMLINE)
end
   /* Append an EOF flag */
   sa=SAVESCL(" EOF. ")
   return;

/****************************************************************************/

Execute_API_Action:
   /* set up parms with SCL TYPE:E (Element Action) and messages DD */
   MY_PARMS = LEFT('*SCLTYPE:E MSGS:C1MSGSA',80) || ,
              SAVESCL(GETALL)   /* retrieve the accumulated SCL */
   Sa= my_parms ;

/* testing - consider keeping the APIMSG for debugging
   ADDRESS TSO "ALLOC F(C1MSGSA)  DUMMY REUSE"
   */
   ADDRESS TSO,
   "ALLOC F(C1MSGSA) LRECL(133) BLKSIZE(26600) SPACE(5,5) ",
     "DSORG(PS) RECFM(V B) TRACKS NEW UNCATALOG REUSE " ;
   ADDRESS TSO,
   "ALLOC F(C1MSGS1) LRECL(133) BLKSIZE(26600) SPACE(5,5) ",
     "DSORG(PS) RECFM(V B) TRACKS NEW UNCATALOG REUSE " ;
   ADDRESS TSO "ALLOC FI(SYSOUT)  DUMMY SHR REUSE"
   ADDRESS LINKMVS 'NDUSASCL MY_PARMS'
   Temp_RC = RC ;
   If Temp_RC >= 4  THEN,
      Do
         LNLASACT = 'Submit'
         FGAPIRC  = Temp_RC
         ADDRESS ISPEXEC "SETMSG MSG(NDUM027C)"
         ADDRESS ISPEXEC "LMINIT DATAID(DDID) DDNAME(C1MSGS1)"
         ADDRESS ISPEXEC "VIEW DATAID(&DDID)"
         ADDRESS ISPEXEC "LMFREE DATAID(&DDID)"
      End;
   else
      do
         TOFRNAME = 'USER DATA'
         VAREVNME = 'ELEMENT:'EEVETKSY'/'EEVETKSB'/'EEVETKEL'/'EEVETKTY
         D        = EEVETKSI
         ADDRESS ISPEXEC "SETMSG MSG(CIIO089)"
         EEVEUSRD = LEFT(USERDAT1,40) || LEFT(USERDAT2,40) /* new EEVEUSRD.   */
         /*
            We need to tell Quick Edit about the fields we updated - add
            EEVEUSRD to refresh list in USERRFSH
         */
         USERRFSH = OVERLAY(" EEVEUSRD)",USERRFSH,POS(')',USERRFSH))   /* add */
         USERRFSH = LEFT(USERRFSH,POS(')',USERRFSH)) /* EEVEUSRD and truncate */
         ADDRESS ISPEXEC "VPUT (USERRFSH) SHARED"  /* Update Q/E refresh list */
      end
   ADDRESS ISPEXEC "VPUT" USERRFSH "SHARED" /* and pass back the updated vars */
   RETURN;


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
