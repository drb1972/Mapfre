/* REXX - User Routine Sample to display Alterable Fields in a pop-up screen

   Note: Currently Quick Edit does not have the generate or retrieve CCID
   in the table (ENzIE250) - alter should still work, but the data (before)
   will not be shown.  Use View Master to display/check.

   Copyright (C) 2022 Broadcom. All rights reserved.

   THESE SAMPLE ROUTINES ARE DISTRIBUTED BY BROADCOM "AS IS".
   NO WARRANTY, EITHER EXPRESSED OR IMPLIED, IS MADE FOR THEM.
   BROADCOM CANNOT GUARANTEE THAT THE ROUTINES ARE
   ERROR FREE, OR THAT IF ERRORS ARE FOUND, THEY WILL BE CORRECTED.

*/

/* Common Preamble */
if ARG(1) == "DESCRIPTION" THEN
   RETURN "Display Element MetaData in a pop-up menu, and Optionaly change it"
/* End of Preamble */

parse arg PassParm                        /* The Parm tells us what variable  */
PassName = strip(PassParm,,"'")           /* holds the varialbe names, remove */
ADDRESS ISPEXEC "VGET ("PASSNAME") SHARED"/* ANY QUOTES AND GET THESE NAMES   */
interpret 'ALLVALS = 'PassName            /* use interpret to expand the names*/
ADDRESS ISPEXEC "VGET ("ALLVALS") SHARED" /* and get those values */
USERDAT1 = SUBSTR(EEVEUSRD,01,40)         /* The EEVEUSRD is 80 bytes, tailor */
USERDAT2 = SUBSTR(EEVEUSRD,41,40)         /* this bit to split it into chunks */
USERDESC = EEVBCOM                        /* ...description                   */
USERPGRP = EEVETPGR                       /* ...Processor Group               */
USERLCCI = EEVETCCI                       /* ...Last Action CCID              */
USERGCCI = EEVETCCG                       /* ...Generate CCID (new)           */
USERRCCI = EEVETCCR                       /* ...Retrieve CCID (new)           */
USERUSER = EEVETSO                        /* ...Signout UserID                */
BEFRDAT1 = USERDAT1                       /* Save before values so we can see */
BEFRDAT2 = USERDAT2                       /* if user changed them...          */
BEFRDESC = USERDESC                       /* ...description                   */
BEFRPGRP = USERPGRP                       /* ...Processor Group               */
BEFRLCCI = USERLCCI                       /* ...Last Action CCID              */
BEFRGCCI = USERGCCI                       /* ...Generate CCID (new)           */
BEFRRCCI = USERRCCI                       /* ...Retrieve CCID (new)           */
BEFRUSER = USERUSER                       /* ...Signout UserID                */
ADDRESS ISPEXEC "VPUT (USERDAT1 USERDAT2",  /* Make vars available            */
    "USERDESC USERPGRP USERLCCI USERGCCI",  /*                                */
    "USERRCCI USERUSER ) SHARED"            /*                                */
ADDRESS ISPEXEC "ADDPOP"                  /* Show the panel in a pop-up       */
ADDRESS ISPEXEC "DISPLAY PANEL(NDUSRPAL)" /* Then show the panel              */
if rc > 0 then                            /* Did use hit END or RETURN?       */
do
   ADDRESS ISPEXEC "REMPOP"               /* Remove the popup                 */
   ADDRESS ISPEXEC "SETMSG MSG(ENDE046E)" /* Request cancelled                */
   exit 0                                 /* and get out (no changes)         */
end
ADDRESS ISPEXEC "REMPOP"                  /* Remove the popup                 */
ADDRESS ISPEXEC "VGET (USERDAT1 USERDAT2",  /* Get the values again           */
    "USERDESC USERPGRP USERLCCI USERGCCI",  /*                                */
    "USERRCCI USERUSER ) SHARED"            /*                                */
EEVEUSRD = LEFT(USERDAT1,40) || LEFT(USERDAT2,40) /* rebuild the EEVEUSRD.    */
EEVBCOM  = USERDESC                       /* ...description                   */
EEVETPGR = USERPGRP                       /* ...Processor Group               */
EEVETCCI = USERLCCI                       /* ...Last Action CCID              */
EEVETCCG = USERGCCI                       /* ...Generate CCID (new)           */
EEVETCCR = USERRCCI                       /* ...Retrieve CCID (new)           */
EEVETSO  = USERUSER                       /* ...Signout UserID                */
/* Note prior to V16 EEVEUSRD can only be updated by an Exit, and field meta
   data not at all, but with V17 and later we can use alter action.           */
if BEFRDAT1 = USERDAT1 & ,
   BEFRDAT2 = USERDAT2 & ,
   BEFRDESC = USERDESC & ,
   BEFRPGRP = USERPGRP & ,
   BEFRLCCI = USERLCCI & ,
   BEFRGCCI = USERGCCI & ,
   BEFRRCCI = USERRCCI & ,
   BEFRUSER = USERUSER then do
      ADDRESS ISPEXEC "SETMSG MSG(CIIO607)"
   USERMSG  = '*NoChange'                    /* Tell caller what happened     */
      end
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
  /*
        Finally update the the status depending on how the alter went
  */
if FGAPIRC >= 12 then do                  /* Was there an error?          */
   USERMSG  = '*AltRC:' || FGAPIRC        /* Show action failed            */
   ADDRESS ISPEXEC "VPUT (USERMSG) SHARED"       /* pass back the updated msg*/
   end
else do
   USERMSG  = '*Altered'                  /* Tell caller what happened     */
   /* we need to tell Quick Edit about the fields we updated - add then to
      refresh list in USERRFSH - max len 512 */
   USERRFSH = OVERLAY(" EEVEUSRD EEVBCOM EEVETPGR EEVETCCI" ||,
                      " EEVETCCG EEVETCCR EEVETSO)",,
                        USERRFSH,POS(')',USERRFSH))       /*add modified flds*/
   USERRFSH = LEFT(USERRFSH,POS(')',USERRFSH))               /* and truncate */
   ADDRESS ISPEXEC "VPUT (USERRFSH) SHARED" /* Update the refresh list for Q/E*/
   ADDRESS ISPEXEC "VPUT" USERRFSH "SHARED" /* and pass back the updated vars */
   end                                           /* End NORMAL processing */
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

   sa=SAVESCL(" SET FROM ENVIRONMENT "EEVETKEN " SYSTEM "EEVETKSY)
   sa=SAVESCL("   SUBSYSTEM   "EEVETKSB " TYPE   "EEVETKTY " STAGE" EEVETKSI".")
if BEFRDAT1 /= USERDAT1 | ,
   BEFRDAT2 /= USERDAT2 | ,
   BEFRDESC /= USERDESC | ,
   BEFRPGRP /= USERPGRP | ,
   BEFRLCCI /= USERLCCI | ,
   BEFRGCCI /= USERGCCI | ,
   BEFRRCCI /= USERRCCI | ,
   BEFRUSER /= USERUSER then DO
      sa=SAVESCL(" ALTER ELEMENT ")
      sa=SAVESCL("'"EEVETKEL"'")
      sa=SAVESCL(" REPLACE ")
   if BEFRDESC /= USERDESC THEN do        /* Alter Description ?     */
      if pos("'",USERDESC) > 0 then        /* any single quote?       */
         sa=SAVESCL('  DESCRIPTION WITH "'left(USERDESC,40)'"')
      else
         sa=SAVESCL("  DESCRIPTION WITH '"left(USERDESC,40)"'")
   end
   if BEFRLCCI /= USERLCCI THEN do        /* Alter Last Action CCID  */
      if pos('"',USERLCCI) > 0 then        /* any double quote?       */
         sa=SAVESCL("  LAST ACTION CCID WITH '"left(USERLCCI,12)"'")
      else
         sa=SAVESCL('  LAST ACTION CCID WITH "'left(USERLCCI,12)'"')
   end
   if BEFRGCCI /= USERGCCI THEN do        /* Alter Generate CCID     */
      if pos('"',USERGCCI) > 0 then        /* any double quote?       */
         sa=SAVESCL("     GENERATE CCID WITH '"left(USERGCCI,12)"'")
      else
         sa=SAVESCL('     GENERATE CCID WITH "'left(USERGCCI,12)'"')
   end
   if BEFRRCCI /= USERRCCI THEN do        /* Alter Retrieve CCID     */
      if pos('"',USERRCCI) > 0 then        /* any double quote?       */
         sa=SAVESCL("     RETRIEVE CCID WITH '"left(USERRCCI,12)"'")
      else
         sa=SAVESCL('     RETRIEVE CCID WITH "'left(USERRCCI,12)'"')
   end
   if BEFRPGRP /= USERPGRP THEN           /* Alter Processor Group?  */
         sa=SAVESCL("   PROCESSOR GROUP WITH '"left(USERPGRP,8)"'")
   if BEFRUSER /= USERUSER THEN           /* Alter Signout User?     */
         sa=SAVESCL("    SIGNOUT USERID WITH '"left(USERUSER,8)"'")
   if BEFRDAT1 /= USERDAT1 & ,            /* Alter 1st 40 bytes      */
      BEFRDAT2  = USERDAT2 THEN do        /* 2nd 40 bytes unchanged  */
      sa=SAVESCL("   USER DATA WITH (1,40,' ',")
      if pos('"',USERDAT1) > 0 then        /* any double quote?       */
         sa=SAVESCL("   '"left(USERDAT1,40)"')")
      else
         sa=SAVESCL('   "'left(USERDAT1,40)'")')
   end
   if BEFRDAT2 /= USERDAT2 & ,            /* Alter 2nd 40 bytes      */
      BEFRDAT1  = USERDAT1 THEN do        /* 1st 40 bytes unchanged  */
      sa=SAVESCL("   USER DATA WITH (41,40,' ',")
      if pos('"',USERDAT2) > 0 then        /* any double quote?       */
         sa=SAVESCL("   '"left(USERDAT2,40)"')")
      else
         sa=SAVESCL('   "'left(USERDAT2,40)'")')
   end
   if BEFRDAT1 /= USERDAT1 & ,            /* BOTH chunks of user data*/
      BEFRDAT2 /= USERDAT2 THEN do        /* changed, try spanning   */
      sa=SAVESCL("   USER DATA WITH (1,80,' ',")
      if pos('"',EEVEUSRD) > 0 then        /* any double quote?       */
         sa=SAVESCL("   '"left(EEVEUSRD,80)"')")
      else
         sa=SAVESCL('   "'left(EEVEUSRD,80)'")')
   end
      sa=SAVESCL(" OPTION UPDATE ELEMENT" options)
      sa=SAVESCL(COMLINE)
end

/* There is a risk, that if the user data contain spaces and is broken over
   two lines, with spaces around the split, then parsing could end up
   getting confused over the proper string length - in which case it would
   be safer to always use two alter statements for 40 bytes each so we never
   have to span an scl line - in which case un-comment this block and comment
   the last two blocks in the first statement... or come up with a better
   way to split the line at NON-Whitespace characters.  */
/*
if BEFRDAT2 /= USERDAT2 THEN do
   /* Alter second 40 bytes,we need a new statement to continue the user data */
   sa=SAVESCL(" ALTER ELEMENT ")
   sa=SAVESCL("'"EEVETKEL"'")
   sa=SAVESCL(" REPLACE USER DATA WITH (41,40,,")
   if pos('"',USERDAT2) > 0 then           /* any double quote?       */
      sa=SAVESCL("   '"left(USERDAT2,40)"')")
   else
      sa=SAVESCL('   "'left(USERDAT2,40)'")')
   sa=SAVESCL(" OPTION UPDATE ELEMENT" options)
   sa=SAVESCL(COMLINE)
end
*/
   /* Append an EOF flag */
   sa=SAVESCL(" EOF. ")
   return;

/****************************************************************************/

Execute_API_Action:

   /* set up parms with SCL TYPE:E (Element Action) and messages DD */
   MY_PARMS = LEFT('*SCLTYPE:E MSGS:C1MSGSA',80) || ,
              SAVESCL(GETALL)   /* retrieve the accumulated SCL */
   SA= my_parms ;

/* testing - consider keeping the C1MSGSA for debugging
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
         LNLASACT = 'Alter'
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
      end
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
