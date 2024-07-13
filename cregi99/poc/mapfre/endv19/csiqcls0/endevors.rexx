/* Rexx - Main driver for Endevor ISPF applications

   This routine is called by the main entry clists, or by menu
   parameters can include overriding the PREFIX(s) or Suffix(s)
   to use, the APPLid or the C1DEFLTS table name etc.

   */

MainLine:     /* Mainline logic calls each routine in turn            */

   call Defaults    /* Set default values for all strings             */
   arg  parms       /* capture invocation parms to parse and then...  */
   parms = strip(parms,"B","'")      /* Strip leading/trailing APOST  */
   call ParseArgs parms    /* Parse any passed option/overrides       */
   trace(traceOpt)  /* inherit and trace options specified            */

   call LparChk     /* LPAR specific Settings - use LINKLIST? etc.    */
   call FriendlyName /* Substitute friendly names                     */

   if SYSVAR("SYSISPF") \= "ACTIVE" THEN do
      call Discovery /* Validate TASKLIB datasets                     */
      call LaunchPDF /* DO ALTLIB Activate and invoke PDF             */
      exit 0        /* ...on return just get out                      */
   end

   call ChkJapan    /* Check localisation settings for KANA support   */
   call SaveProfile /* Capture Users current settings                 */
   call ListaChk    /* see what's allocated now                       */
   if \EndevorOnSplitScreen then do
      call Discovery /* Validate datasets are OK & build concat strs  */
   /* call Display     Display what we found - for debugging purposes */
      call LibdAloc /* Execute an Allocate                            */
   end
   call LibdStac    /* Issue LIBDEF STACK for each DDname             */

   if ChkFMID = "JPN" then
      call ChkMsgs  /* Check language FMID available                  */
   call RestProfile /* Restore Users current settings                 */

   /* If any pending messages - set them now                          */
   if INITMSG \= "" then do  /* pending messages?                     */
      address ISPEXEC "SETMSG MSG("INITMSG") COND"
      INITMSG = ""     /* reset message code                          */
   end

   /* Set C1DEFLTS Suffix (New Method)                                */
   if DFLTNDVR \= "" then do
      ndvrDFT = "EN$DFT"DFLTNDVR
      "ALLOC F("ndvrDFT") DUMMY REUSE"
   end

   /* Invoke Selected Function                                        */
   if OPTNNDVR = "" ,        /* If a default option is not set, or    */
    | left(OPTNNDVR,1) = "M" then /* set to "M" for menu or passed in */
      call ShowMenu          /* prompt the user                       */
   else
      x = InvokOpt(OPTNNDVR) /* invoke Endevor option requested       */

   call SaveProfile /* Capture Users current settings it might change */
   call LibdUnSt    /* De-Stack LIBDEFs                               */
   call Libdfree    /* ...now free and exit...                        */
   call RestProfile /* Restore Users current settings                 */

exit 0

DEFAULTS:     /* Set Routine default values - tailor as needed        */

   /* Use this section to tailor Endevor startup for your site.
      Typically this will involve adding only your product prefix
      (PRDPRFX) below - but this Rexx supports User and Site prefixes
      that are concatenated ahead if desired.

      Additionally if you wish to make use of ENUXSITE to switch
      the C1DEFLTS table that is loaded - support is included to
      allow selection of the defaults by passing a suffix using
      a special DD name (EN$DFTxx) where xx is the suffix.  Users can
      select a specific suffix using DF(xx) on startup, or you can
      select to store the user choice in a profile variable.
      See "Enabling C1DEFLTS selection" in the Endevor doc.

      */

   /* Prefixes are used to build the concatenation in the order       */
   /*    listed - place overrides at the top, product libs at bottom. */

      UserPfx  = ""             /* User Prefix, or blank for none     */
      SitePfx  = "FDP"          /* Prefix for any site overrides      */
   /* To be tailored by BC1JJB03 or manually in an override library   */
      ProdPfx  = "IPRFX.IQUAL"

   /* Default option to enable/disable Site and User Prefix options
      Note: When the user visits the SITE settings their choice is
            saved in their profile, and will override the default.
            However - this setting is still subject to any provided
            startup parameters.
            */
      ENABUSER = " "            /* Set to "/" to ENABLE a site or     */
      ENABSITE = " "            /* user prefix - if blank, ignored    */

   /* Libdefs define the list of libraries that will be allocated     */
      LIBDEFS  = "ISPPLIB ISPMLIB ISPSLIB ISPTLIB ISPLLIB",
                 "SYSPROC STEPNDVR CONLIB"

   /* Suffixes for each LIBDEF - Tailor for your environment.         */
   /* This makes it easy to tailor according to your naming           */
   /* conventions, for example if you prefer ISPPLIB instead of the   */
   /* Endevor default of CSIQPLIB etc.                                */
      SYSPROC  = "REXX ISRC ISRCLIB CSIQCLS0"
      ISPPLIB  = "ISPP ISPPLIB CSIQPENU"
      ISPMLIB  = "ISPM ISPMLIB CSIQMENU"
      ISPSLIB  = "ISPS ISPSLIB CSIQSENU"
      ISPTLIB  = "ISPT ISPTLIB CSIQTENU"
      ISPLLIB  = "CSIQLOAD"
      CONLIB   = "LOADLIB CSIQLOAD"
      STEPNDVR = "AUTHLIB LOADLIB CSIQAUTU CSIQAUTH"

   /* List of LPARs where Endevor libraries have to be dynamically    */
   /* allocated. Leave empty when running from LINKLIST/LPA or when   */
   /* the Endevor libraries are in STEPLIB.                           */
      LPARLIST = ""
   /* In the example below if the SYSNAME matches one of the          */
   /* words below - use a dynamic STEPLIB utility like TASKLIB+ for   */
   /* those systems.                                                  */
   /* LPARLIST = "XXXX YYYY"                                          */

   /* Default Option to launch ("M" or blank for Menu)                */
      OPTNNDVR = "M"  /* default option is launch Option Menu         */
   /* OPTNNDVR = "2"  -* default option is launch QuickEdit           */

   /* Default APPLICATION ID (for profile pool, saved variables etc.  */
   /* By default Endevor uses CTLI, but if you are regularly swapping */
   /* between instances - you may prefer to also switch APPLIDs so    */
   /* that each instance can save it's own ENVNAME, SYSTEM NAME etc.  */
      APPLNDVR = "CTLI"

   /* Default C1DEFLTS suffix, or blank, for C1DEFLTS                 */
      DFLTNDVR = ""    /* Empty means don't use ENUXSITE EN$DFTxx     */
   /* DFLTNDVR = "PROFILE"    IF set to PROFILE then use UserProfile  */
                       /* See ONBOARDING below for how to set initial */
                       /* values if converting to ENUXSITE            */
   /* DFLTNDVR = "ZZ"  -* To default a specific suffix code it here   */

   /* The menu panel has a dynamic area that can  be used to display  */
   /* messages to the end users. An example routine that shows a      */
   /* welcome message is ENDEVORG. You can write your own message     */
   /* routine and use the following defaults to control if the        */
   /* routine is invoked or to change the name.                       */

   /* Enable Greeting message by uncommenting the following lines     */
   /* and commenting the set after                                    */
   /* ENABGMSG = "/"             * Enable Greeting message            */
   /* REXXGMSG = "ENDEVORG"      * Sample Greeting Message routine    */
      ENABGMSG = ""             /* Disable Greeting message           */
      REXXGMSG = ""             /* No Greeting message routine        */

   /* Assume we are not in split screen mode until proven otherwise   */
      EndevorOnSplitScreen = 0

   /* This flag is used to check for a language setting (TERMTYP) chg */
      ChkFmid = ""

   /* Misc values/defaults                                            */
      LASTTERM = ""                    /* used to check Terminal chg  */
      INITMSG  = ""                    /* Message to Display          */
      SayInfo  = 0                     /* Don't show Info Messages    */

Return

LparChk:      /* Perform LPAR specific customisations, LINKLIST, etc. */
   thislpar = MVSVAR(SYSNAME)
   if wordpos(thislpar,LPARLIST) = 0,  /* if this system doesn't need */
      then do                          /* dynamic STEPLIB, remove    */
         libdefs = RepWord('STEPNDVR',libdefs) /* any STEPNDVR        */
         libdefs = RepWord('CONLIB  ',libdefs) /*  or CONLIB          */
         NDVLNDVR = ""                 /* Also don't use TASKLIB      */
      end

Return

FriendlyName: /* Substitute friendly names with full expansion        */

 /*
   /* The following code is an example to expand "friendly" names in
      the prefixes
      */

   /* Example 1: Replace a friendly name with a fully qualified       */
   /*            dataset name (prefix)                                */
   friendly   = 'EDB2'              /* if this friendly name is found */
   ExpandedDS = 'CAIPROD.EDB2.V40L00' /* replace it with expanded pfx */
   if wordpos(friendly,AllPrfx) > 0 then
         AllPrfx = RepWord(friendly,AllPrfx,ExpandedDS)

   /* Example 2: Replace a friendly name with a fully qualified       */
   /*            dataset name DEPENDING on the LPAR name...           */
   friendly = 'FDP'
   if wordpos(thislpar,LPARLIST) > 0 then /* If dynamic STEPLIB       */
      ExpandedDS = 'CAIPROD.NDVR.V170FDP' /* use development library  */
   else                                   /* otherwise                */
      ExpandedDS = 'CAIPROD.NDVR.PRODFDP' /* use production library   */
   if wordpos(friendly,AllPrfx) > 0 then
         AllPrfx = RepWord(friendly,AllPrfx,ExpandedDS)
 */

Return

ChkJapan:     /* Check if KANA support is needed and adjust libraries */

   x = TIME(R)
   if ZTERM == LASTTERM then return    /* No change - nothing to do   */
   LASTTERM = ZTERM                    /* otherwise  save for future  */
   if right(ZTERM,2) == 'KN' then do   /* Kana ON                     */
      ChkFmid = "JPN"
      ISPPLIB = RepWord('CSIQPENU',ISPPLIB,'CSIQPJPN')
      ISPPLIB = RepWord('ISPP'    ,ISPPLIB,'ISPPJPN' )
      ISPMLIB = RepWord('CSIQMENU',ISPMLIB,'CSIQMJPN')
      ISPMLIB = RepWord('ISPM'    ,ISPMLIB,'ISPMJPN' )
   end
   else do                             /* Kana off                    */
      ChkFmid = "ENU"
      ISPPLIB = RepWord('CSIQPJPN',ISPPLIB,'CSIQPENU')
      ISPPLIB = RepWord('ISPPJPN' ,ISPPLIB,'ISPP'    )
      ISPMLIB = RepWord('CSIQMJPN',ISPMLIB,'CSIQMENU')
      ISPMLIB = RepWord('ISPMJPN' ,ISPMLIB,'ISPM'    )
   end
   if SayInfo then say "ChkJapan  Elapsed:" TIME(E) ChkFmid

Return

SaveProfile:  /* Save current users profile values to allow restore   */
   intercom = 'INTERCOM'             /* set defaults for intercom and */
   msgid    = 'MSGID'                /* msgid settings if not found   */

   MSGSTATUS = MSG("ON")
   x = Outtrap("out.",10,"NOCONCAT") /* Trap output                   */

   address tso "PROFILE"             /* Get current profile values    */
   If out.0 \= 0 Then Do             /* if we got output save it      */
      if left(out.1,3) == "IKJ" then /* if MSGID was already on       */
        Parse Upper Var out.1 ,
         . . . prompt intercom pause msgid mode wtpmsg recover tprefix .
      else                           /* othewise no prefix            */
        Parse Upper Var out.1 ,
           . . prompt intercom pause msgid mode wtpmsg recover tprefix .
      Address  TSO "PROFILE MSGID"   /* Please tell us what happened  */
   End

   x = Outtrap("OFF")                /* Stop trapping output          */
   MSGSTATUS = MSG(MSGSTATUS)
return

RestProfile:  /* Restore user's environment settings                  */
              /* Restore only the one that was changed here: MSGID    */
              /* Security can be set up so that a user may not have   */
              /* the authority to update certain settings like        */
              /* RECOVER.                                             */
              /* To restore other settings, add the proper variables  */
              /* from this list:                                      */
              /* prompt intercom pause mode wtpmsg recover tprefix    */
              /* They were saved in SaveProfile.                      */
   Address  TSO "PROFILE" msgid                 /* Restore settings   */
return

ListaChk:     /* Find any allocated Endevor datasets                  */
   x = TIME(R)
   ndvrDDs = ""
   ndvrDFT = ""
   MSGSTATUS = MSG("ON")
   x = Outtrap("out.",512,"NOCONCAT") /* Trap output                  */

   address tso "LISTA STATUS SYSNAM" /* Get current profile values    */
   If out.0 = 0 Then return          /* give up, nothing trapped      */
   do i = 2 to out.0                 /* For each line                 */
      Parse Upper Var out.i p1 p2 . 1 f2 3 1 f3 4
      select
         when p1 == "TERMFILE" then iterate
         when p1 == "NULLFILE" then do
            if left(p2,6) = "EN$DFT" then ndvrDFT = ndvrDFT p2
         end
         when f3 == "   " then iterate /*Concatenation contd          */
         when f2 == "  "  then  DO     /* DDname (1st in concat)      */
            if right(p1,4) = "NDVR" then ndvrDDs = ndvrDDs p1
         end
         otherwise NOP               /* DSN line - we don't care      */
      end
   End

   if words(NdvrDDs) > 3 then   /* we need at least ISPxLIB x=M/P/S/T */
      EndevorOnSplitScreen = 1      /* We have pre-allo'd files       */

   /* Assign / Save C1DEFLTS Suffix if used                           */
   if DFLTNDVR = "PROFILE" then do /* Use Profile for Default Suff */
      address ISPEXEC "VGET (NDVLDFLT) PROFILE"
      if RC = 0 then             /* we got a value from profile       */
         DFLTNDVR = NDVLDFLT
      else do

      /* OnBoarding: If the user has no stored defaults value then
         we need to consider how to set a default suffix.  For sites
         that already use ENUXSITE there may be some way to convert
         their existing method programmatically.  In the example below
         we will show how a different ISPF variable can be used to
         convert or ONBOARD that user...  (Tailor as needed)

         Example: Check for another ISPF Profile value...
         */
         address ISPEXEC "VGET (PRDADSN) PROFILE"
         if RC = 0 ,             /* IF we found a likely source       */
          & right(PRDADSN,8) == ".LOADLIB" then DO    /* check it's OK*/
            DFLTNDVR = SUBSTR(PRDADSN,3,2) /* grab the relevant bits  */
         end
         else                    /* Not a good source... set to...    */
            DFLTNDVR = ""        /* blank or use some other method... */
      end
   end

   /* now check to see if a EN$DFTxx DD is already present            */
   ndvrDFT = strip(ndvrDFT,"B")      /* strip blanks so it's clean    */
   if ndvrDFT \= "" ,                /* If we already have an override*/
    & ndvrDFT \= "EN$DFT"DFLTNDVR then do /* and it doesn't match     */
      /* Set ISPF message for next panel display to let user know     */
      INITMSG = "ENDS021C"
      DFLTSELD = DFLTNDVR            /* Save requested dflts for msg  */
      Sa= "Endevor defaults:" DFLTNDVR "selected, but" ndvrDFT ,
          "already allocated, option ignored..."
      DFLTNDVR = substr(ndvrDFT,7)   /* reset to current use          */
   end

   /* whatever value we've got - make sure we save it for next time   */
   NDVLDFLT = DFLTNDVR
   address ISPEXEC "VPUT (NDVLDFLT) PROFILE"

   x = Outtrap("OFF")                /* Stop trapping output           */
   MSGSTATUS = MSG(MSGSTATUS)
   if SayInfo then Say "Lista st  Elapsed:" TIME(E) ,
       EndevorOnSplitScreen ndvrDFT ndvrDDs

return

Discovery:    /* Iterate through libraries to determine which are OK  */
   x = TIME(R)
    /* first build a list of vars to store/retrieve the libraries     */
    VGETLIST = "("
    do i = 1 to words(libdefs)
        VGETLIST = VGETLIST "NDVL"||right(word(libdefs,i),4)
    end
    VGETLIST = VGETLIST ")"

   /* check to see if we already did discovery for the current user
      choice of libraries and prefixes. If so and the user didn't
      request a reset, retrieve the lists and use them
      */
   if WORDPOS('RESET',PARMS) = 0 then do /* User did not request RESET*/
      if SYSVAR("SYSISPF") = "ACTIVE" THEN do /* and we are in ISPF...*/
         address ISPEXEC "VGET (NDVLPFXS NDVLLIBS NDVLFMID) PROFILE"
         if NDVLLIBS = LIBDEFS ,         /* same as last time?        */
          & NDVLFmid = ChkFmid ,         /* Same Terminal Type?       */
          & NDVLPFXS = AllPrfx then do
             address ISPEXEC "VGET" vgetlist "PROFILE"  /* Y - get 'em*/
             if RC = 0 then do       /* we have a good list, continue */
                if SayInfo then say "DCacheHit Elapsed:" TIME(E)
                return
             end
         end
      end
   end

   /* reset Statistics                                                */
   CntChk = 0
   CntOK  = 0

   /* Iterate through possible DS names and collect the GOOD ones     */
   MSGSTATUS = MSG("ON")
   do i = 1 to words(LIBDEFS)
      thislibd = word(LIBDEFS,i)
      x = value("NDVL"||right(thislibd,4)," ")
      do j = 1 to words(AllPrfx)
         thispref = word(AllPrfx,j)
         do k = 1 to words(value(thislibd))
            thissuff = word(value(thislibd),k)
            thisdsn = thispref || "." || thissuff
            thisChk = SYSDSN("'"thisdsn"'")
            sa= "Libdef:" right(thislibd,8) ,
                "Status:" left(thischk,8),
                "DSn:" left(thisdsn,44)
            if thischk = "OK" then do
               cntOK = CntOK +1
               dsnlist = value("NDVL"||right(thislibd,4)) "'"thisdsn"'"
               x = value("NDVL"||right(thislibd,4),dsnlist)
            end
            else
               cntChk = CntChk +1
         end
      end
      sa= "   >>> liblist for DDname:" thislibd ,
         value("NDVL"||right(thislibd,4))
   end
   MSGSTATUS = MSG(MSGSTATUS)

   /* discovery is complete - save the results for next time          */
   if SYSVAR("SYSISPF") = "ACTIVE" THEN do    /* Are we are in ISPF?  */
      NDVLLIBS = LIBDEFS                      /* yes - save libs and  */
      NDVLPFXS = AllPrfx                      /* prefixes and         */
      NDVLFMID = ChkFmid                      /* terminal to compare  */
      address ISPEXEC "VPUT (NDVLPFXS NDVLLIBS NDVLFMID) PROFILE"
      address ISPEXEC "VPUT" vgetlist "PROFILE"
   end

   if SayInfo then say "Discovery Elapsed:" TIME(E) ,
                       "CntOK:" CntOK "CntChk:" CntChk
return

ChkMsgs:      /* Check that Japanese messages are available           */

   /* If we got here it means that we detected a user with a KANA
      terminal in settings 32xxKN.  But it's possible that the
      Japanese localisation FMID is not installed or the
      wrong prefixes were set.  Also possible that the user
      did not really want Japanese messages.  To perform the check
      we will look for a message that only exists in the japanese
      language library .CSIQMJPN.  If it's not found show a message
      and exit.
      */

   address ISPEXEC "CONTROL ERRORS RETURN"
   address ISPEXEC "GETMSG MSG(CIEV190I)" /* Do we have any messages? */
   iF rc = 0 then                         /* OK?  check special JPN?  */
      address ISPEXEC "GETMSG MSG(ENDS020S)"

   if RC > 0 then do                      /* if either failed tell usr*/
      Say " "
      Say "ENDEVOR LOCALIZATION (JAPANESE MESSAGES) DO NOT APPEAR TO"
      Say "BE AVAILABLE.  CHECK WITH YOUR ENDEVOR ADMINISTRATOR TO "
      Say "MAKE SURE THE JAPANESE FMID (CSIQ%11) IS INSTALLED."
      Say "IF YOU DID NOT EXPECT/WANT KANA SUPPORT, USE THE ISPF"
      Say "SETTINGS DIALOG TO SELECT A TERMINAL TYPE THAT DOES NOT"
      Say "END IN 'KN' E.G. 3278T, THEN RE-START ENDEVOR."
      Say " "

      /* Since a RESTART will skip discovery if all files are
         allocated - make sure we DE-stack and free them...           */
      call LibdUnSt              /* De-Stack LIBDEFs                  */
      call Libdfree              /* ...and free the files .           */
      call RestProfile           /* Restore Users current settings    */
      EXIT 20                    /* Exit wiht High RC - Severe        */
   end

   /* Otherwise everything is fine - keep calm and carry on           */
   address ISPEXEC "CONTROL ERRORS CANCEL"

return

Display:      /* Display Library allocation(s) that will be used      */
   x = TIME(R)
   Say " "
   do i =1 to words(LIBDEFS)
      thislibd = word(LIBDEFS,i)
      Say "  ===>" left(thislibd,8) ,
         value("NDVL"||right(thislibd,4))
   end
   Say " "
   if SayInfo then say "Display   Elapsed:" TIME(E)
return

LibdAloc:    /* Issue ALLOC(s) for Endevor Libraries                  */
   sa= " "
   x = TIME(R)

   MSGSTATUS = MSG("ON")
   x = Outtrap("out.",10,"NOCONCAT")    /* Trap output                */

   do i =1 to words(LIBDEFS)
      thislibd = word(LIBDEFS,i)
      select
         when thislibd = 'CONLIB'  then /* For Conlib use Endevor     */
            thisddnm = thislibd         /* ... specific name          */
         otherwise                      /* otherwise use common suffix*/
            thisddnm = left(thislibd,4) || 'NDVR'
      end
      if pos('.',value("NDVL"||right(thislibd,4))) > 0
      then do                                    /* if non-empty list */
      sa= "ALLOC SHR REUSE FILE(" || thisddnm || ")",
          " DS(" || value("NDVL"||right(thislibd,4)) || ")"
          "ALLOC SHR REUSE FILE(" || thisddnm || ")",
          " DS(" || value("NDVL"||right(thislibd,4)) || ")"
      if RC > 0 ,
       & out.0 \= 0 Then Do              /* if we got output save it  */
         if left(out.1,9) == "IKJ56861I" then      /* dataset is open */
            EndevorOnSplitScreen = 1               /* keep track of it*/
         else do
            Say ""
            Say "Unexpected RC:"rc ,
                "from allocate for file:" thisddnm
            Say "to:" value("NDVL"||right(thislibd,4))
            do o = 1 to out.0
               Say out.o
            end
            Say" "
         end
      end
   end
   end

   x = Outtrap("OFF")                   /* Stop trapping output       */
   MSGSTATUS = MSG(MSGSTATUS)
   sa= " "
   if SayInfo then say "Alloc     Elapsed:" TIME(E)

return

LibdFree:    /* Free allocation libraries (unless still in use)       */
   sa= " "
   x = TIME(R)

   MSGSTATUS = MSG("ON")
   x = Outtrap("out.",10,"NOCONCAT")    /* Trap output                */

   do i =1 to words(LIBDEFS)
      thislibd = word(LIBDEFS,i)
      select
         when thislibd = 'CONLIB'  then /* For Conlib use Endevor     */
            thisddnm = thislibd         /* ... specific name          */
         when thislibd = 'STEPNDVR' then /* STEPNDVR special proc     */
            DO                           /* Check SplitScreen/TaskLib */
              thisddnm = thislibd        /* ... specific name         */
              if EndevorOnSplitScreen ,
               | wordpos('TASKNDVR',ndvrDDs) > 0 then
                 iterate
              /* Tailor with any DYNAMIC Steplib commands if used
                 or make sure Endevor authorized libraries are in
                 LINKLIST/LPA(Recommended) or LOGON PROC STEPLIB

                 Example TASKLIB+ command syntax might be:
                   TASKLIB DEACTIVATE
              */
              /* Add command(s) here                                  */
              /* and carry on to free the file as normal...           */
            END
         otherwise                      /* otherwise use common suffix*/
            thisddnm = left(thislibd,4) || 'NDVR'
      end
      if BPXWDYN("INFO DD("thisddnm")") = 0
      then do                      /* Free the DD if it was allocated */
         sa= "FREE  FILE(" || thisddnm || ")"
             "FREE  FILE(" || thisddnm || ")"
         if RC = 0 then                 /* if DS was freed - not split*/
            EndevorOnSplitScreen = 0               /* keep track of it*/
         else if,
            out.0 \= 0 Then Do           /* if we got output save it  */
               if left(out.1,9) == "IKJ56861I"
               then do                             /* dataset is open */
               EndevorOnSplitScreen = 1            /* keep track of it*/
                  return      /* Endevor on split screens, don't free */
            end
            else do
               Say ""
               Say "Unexpected RC:"rc ,
                   "from free for file:" thisddnm
               Say "ds:" value("NDVL"||right(thislibd,4))
               do o = 1 to out.0
                  Say out.o
               end
               Say" "
            end
         end
      end

   end

   x = Outtrap("OFF")                   /* Stop trapping output       */
   MSGSTATUS = MSG(MSGSTATUS)

   /* if we're still here we've freed all LIBDFEF files - next
      just free EN$DFTxx if used
      */

   if ndvrDFT \= "" then
      "FREE FILE("ndvrDFT")"

   /* Since we stored the libraries for batch use in the profile
      (to survive the newappl) we need to clear them now
      so they aren't used unexpectedly
      */

   address ISPEXEC "VERASE (" ,     /* drop profile vars now   */
      "EEVLIB01 EEVLIB02 EEVLIB03 EEVLIB04 EEVLIB05",
      "EEVLIB06 EEVLIB07 EEVLIB08 EEVLIB09 EEVLIB10",
      "EEVLIB11 EEVLIB12 EEVLIB13 EEVLIB14 EEVLIB15",
      ") PROFILE"
   address ISPEXEC "VERASE (" ,   /* split in two for max length   */
      "EEVLIB16 EEVLIB17 EEVLIB18 EEVLIB19 EEVLIB20",
      "EEVLIB21 EEVLIB22 EEVLIB23 EEVLIB24 EEVLIB25",
      "EEVLIB26 EEVLIB27 EEVLIB28 EEVLIB29 EEVLIB30",
      ") PROFILE"


   if SayInfo then say "Free      Elapsed:" TIME(E)

return

LibdStac:    /* Issue LIBDEF STACK for each library                   */
   sa= " "
   x = TIME(R)
   do i =1 to words(LIBDEFS)
      thislibd = word(LIBDEFS,i)
      select
         when thislibd = 'CONLIB'  then /* No Libdef for CONLIB       */
            iterate                     /* go fetch next one...       */
         when thislibd = 'STEPNDVR' then /* No Libdef for STEPNDVR    */
            DO                          /* check splitscreen/TaskLib  */
               if EndevorOnSplitScreen ,
               | wordpos('TASKNDVR',ndvrDDs) > 0 then
                  iterate
              /* tailor with any dynamic STEPLIB commands if used
                 or make sure Endevor authorized libraries are in
                 LINKLIST/LPA(Recommended) or LOGON PROC STEPLIB

                 An example of a dynamic STEPLIB utility is TASKLIB+.
                 Example TASKLIB+ command syntax might be:
                    TASKLIB ACTIVATE DDNAME(STEPNDVR) LEVEL(1) APF(YES)
              */
              /* Add command(s) here and comment out the SAY commands
                 below                                                */
               SAY "THE CUSTOMIZATION OF ENDEVOR MAY BE INCOMPLETE."
               SAY "LPAR" THISLPAR "IS IN THE LIST OF LPARS THAT",
                   "DO NOT HAVE THE ENDEVOR LIBRARIES IN THE",
                   "LINKLIST."
               SAY "EITHER REMOVE" THISLPAR "FROM LPARLIST OR USE A",
                   "DYNAMIC STEPLIB UTILITY IN REXX EXEC ENDEVORS",
                   "ROUTINE LIBDSTAC TO ALLOCATE THE ENDEVOR",
                   "LIBRARIES."
               iterate                  /*     go do next             */
            END
         when thislibd = 'SYSPROC' then /* Use Altlib activate for    */
            DO                          /* ... clist/rexx             */
               sa= "ALTLIB ACTIVATE APPLICATION(CLIST)" ,
                   "LIBRARY(SYSPNDVR)"
                   "ALTLIB ACTIVATE APPLICATION(CLIST)" ,
                   "LIBRARY(SYSPNDVR)"
               iterate                  /* and go do next             */
            END                         /* ... clist/rexx             */
         otherwise                      /* otherwise use common suffix*/
            thisddnm = left(thislibd,4) || 'NDVR'
      end
      if BPXWDYN("INFO DD("thisddnm")") = 0
      then do
         sa= "ISPEXEC LIBDEF"  thislibd "STACK LIBRARY",
             " ID(" || thisddnm || ")"
             "ISPEXEC LIBDEF"  thislibd "STACK LIBRARY",
             " ID(" || thisddnm || ")"
      end
   end

  /* Save STEPLIB / CONLIB cards for batch jobs so they get the same
     treatment, same concatenation, etc.
     */

   if EndevorOnSplitScreen then do      /* If we've already set/saved */
      address ISPEXEC "VGET (" ,     /* the vars, just fetch them back*/
         "EEVLIB01 EEVLIB02 EEVLIB03 EEVLIB04 EEVLIB05",
         "EEVLIB06 EEVLIB07 EEVLIB08 EEVLIB09 EEVLIB10",
         "EEVLIB11 EEVLIB12 EEVLIB13 EEVLIB14 EEVLIB15",
         ") PROFILE"
      address ISPEXEC "VGET (" ,     /* split in two for max length   */
         "EEVLIB16 EEVLIB17 EEVLIB18 EEVLIB19 EEVLIB20",
         "EEVLIB21 EEVLIB22 EEVLIB23 EEVLIB24 EEVLIB25",
         "EEVLIB26 EEVLIB27 EEVLIB28 EEVLIB29 EEVLIB30",
         ") PROFILE"
      if SayInfo then say "LIBDEF ST Elapsed: SplitScreen" TIME(E)
      return
   end

   OUTSUB = 0                           /* Set index for output lines */

   IF wordpos('STEPNDVR',LIBDEFS) > 0 then do  /* If we have a STEPLIB*/
      outline = LEFT("//STEPLIB  DD DISP=SHR,DSN=",80) /* set template*/
      do i = 1 to words(NDVLNDVR)              /* and for each DSN... */
         outsub = outsub + 1                /* increment output index */
         outdsn = strip(word(ndvlndvr,i),"B","'") /* strip off aposts */
         OUTLINE = overlay(outdsn,OUTLINE,28,44)  /* place after DSN= */
         x = value("EEVLIB"right(outsub,2,'0'),outline) /* save var   */
         OUTLINE = overlay("//    ",OUTLINE,1,10)  /* blank out DDNAM */
      end
   end

   IF wordpos('CONLIB',LIBDEFS) > 0 then do    /* If we have a CONLIB */
      outline = LEFT("//CONLIB   DD DISP=SHR,DSN=",80) /*rest template*/
      do i = 1 to words(NDVLNLIB)              /* and for each DSN... */
         outsub = outsub + 1                /* increment output index */
         outdsn = strip(word(ndvlnlib,i),"B","'")
         OUTLINE = overlay(outdsn,OUTLINE,28,44)
         x = value("EEVLIB"right(outsub,2,'0'),outline)
         OUTLINE = overlay("//    ",OUTLINE,1,10)  /* blank out DDNAM */
      end
   end

   if outsub = 0 then do           /* if we are running from linklist */
      EEVLIB01 = "//* NO LIBRARIES - ENDEVOR RUNNING FROM LPA/LINKLIST"
   end

   do i = (outsub +1) to 30                 /* set rest to nulls      */
      x = value("EEVLIB"right(i,2,"0"),"")
   end
   address ISPEXEC "VPUT (" ,     /* Save vars for Skeleton SCMM@LIB  */
      "EEVLIB01 EEVLIB02 EEVLIB03 EEVLIB04 EEVLIB05",
      "EEVLIB06 EEVLIB07 EEVLIB08 EEVLIB09 EEVLIB10",
      "EEVLIB11 EEVLIB12 EEVLIB13 EEVLIB14 EEVLIB15",
      ") PROFILE"
   address ISPEXEC "VPUT (" ,     /* split in two for max length      */
      "EEVLIB16 EEVLIB17 EEVLIB18 EEVLIB19 EEVLIB20",
      "EEVLIB21 EEVLIB22 EEVLIB23 EEVLIB24 EEVLIB25",
      "EEVLIB26 EEVLIB27 EEVLIB28 EEVLIB29 EEVLIB30",
      ") PROFILE"
   if SayInfo then say "LIBDEF ST Elapsed:" TIME(E)


return

LaunchPDF:   /* Invoked from TSO/E setup tasklib & launch PDF         */

   /* If a TSO/E user invokes any of the startup clists before
      launching ISPF this will now work, and and will additionally
      try to allocate the Endevor authorized libraries using the
      TSOLIB ACTIVATE LIBRARY... command.  All libraries in this
      concatenation must be authorized (use SYSVIEW: ACT, DS commands
      to confirm that every dataset under the TASKNDVR DD is APF
      Authorized.  If not, the symptom will be a long wait and
      eventual timeout trying to start the server task.
      Additionaly some extra steps are required on the ISPF
      configuration side.  An ENDEVORS menu item must be added to
      point to the ISPF primary menu that points to the ENDEVORS clist
      and that clist must be in the SYSPROC or SYSEXEC concatenation.
      Additionaly to support passing long parameter strings from the
      TSO/E clist, the primary menu should include a )FIELD section
      with a "FIELD(ZCMD) LEN(1024)" or suitable size specified.

      Snippets from that menu screen should look like this;

        &ZSEL = TRANS(TRUNC(&ZCMD,'.')
                     0,'PGM(ISPISM)'
      -  -  -  -  -  -  -  -  -  -  -  -  -  -  - Lines not displayed
              ENDEVORS,'CMD(%ENDEVORS &ZPARM) NOCHECK'
      -  -  -  -  -  -  -  -  -  -  -  -  -  -  - Lines not displayed
                     *,'?' )
        &ZTRAIL = .TRAIL
      )FIELD
       FIELD(ZCMD) LEN(1024)
      )END







      */
   /* first wrap up the parms so they can be passed with spaces/parens*/
   parms = translate(parms,'!{}',' ()')   /* replace special chars    */
   if LIBDEFS > " ",                    /* if we have DDNames to alloc*/
    & NDVLNDVR > " " then do            /* and DSNAMES found          */
      PUSH "FREE F(TASKNDVR)"                 /* Free the TSO TASKLIB */
      PUSH "TSOLIB DEACTIVATE"                /* Deactivate TSOLIB    */
      PUSH "PDF ENDEVORS."parms
      PUSH "TSOLIB DISPLAY"                   /* Show what we got     */
      PUSH "TSOLIB ACT LIBRARY(TASKNDVR)"     /* Activate the TSOLIB  */
      PUSH "ALLOC F(TASKNDVR) DS("NDVLNDVR") SHR REUSE"    /* TASKLIB */
   end
   else                         /* otherwise TASKLIB not required just*/
      PUSH "PDF ENDEVORS."parms               /* Invoke PDF with parms*/

   /* At this point the TSO commands are stacked waiting to execute
      so this rexx can safely exit and let those commands run
      */
   Exit

return

LibdUnSt:    /* Issue LIBDEF (unstacks) to free libraries             */
   sa= " "
   x = TIME(R)
   do i =1 to words(LIBDEFS)
      thislibd = word(LIBDEFS,i)
      select
         when thislibd = 'CONLIB'  then /* No Libdef for CONLIB       */
            iterate                     /* go fetch next one...       */
         when thislibd = 'STEPNDVR' then /* Ditto for STEPNDVR        */
            iterate                     /* ... go do next             */
         when thislibd = 'SYSPROC' then /* Use Altlib activate for    */
            DO                          /* ... clist/rexx             */
               sa= "ALTLIB DEACTIVATE APPLICATION(CLIST)"
                   "ALTLIB DEACTIVATE APPLICATION(CLIST)"
               iterate                  /* and go do next             */
            END                         /* ... clist/rexx             */
         otherwise                      /* otherwise use common suffix*/
            thisddnm = left(thislibd,4) || 'NDVR'
      end
      if BPXWDYN("INFO DD("thisddnm")") = 0
      then do
         sa= "ISPEXEC LIBDEF"  thislibd
             "ISPEXEC LIBDEF"  thislibd
      end

   end
   if SayInfo then say "LIBDEF UN Elapsed:" TIME(E)

return

ShowMenu:    /* No pre-defined option show a menu panel and ask user  */

   x = TIME(R)
   if ENABGMSG == '/' then do
      ZERRMSG = ""
      ADDRESS ISPEXEC "CONTROL ERRORS RETURN"
      "ISPEXEC SELECT CMD(%"REXXGMSG")" /* refresh scrollable area    */
      ADDRESS ISPEXEC "CONTROL ERRORS CANCEL"
      If ZERRMSG \= "" then
         "ISPEXEC SETMSG MSG("ZERRMSG")"
   end
   if SayInfo then say REXXGMSG " Elapsed:" TIME(E)

   parse var OPTNNDVR  option '.' ZTRAIL
   do forever
      "ISPEXEC DISPLAY PANEL(ENDEVORM)"
      dispRC = RC
      if dispRC > 0,              /* If user pressed END/RETURN       */
       | ZCMD = 'X' then leave    /*    or used option 'X' then exit  */
      x = InvokOpt(zcmd)          /* Otherwise try to do it           */
      if x = 0 then               /* if it was a valid command        */
         ZCMD = ""                /*    then reset it                 */
      ZTRAIL = ""                 /* and reset the ZTRAIL             */
   end

return

InvokOpt:    /* Issue appropriate handler to perform function         */

   parse arg  option ZTRAIL
   if pos('.',option) > 0 then do /* if user passed a suboption       */
      parse arg option '.' ZTRAIL
      subOpt = " OPT("ZTRAIL")"
   end
   else
      subOpt = ""
   if ZTRAIL \= "" then
      address ISPEXEC "VPUT (ZTRAIL) SHARED"

   scrName = "SCRNAME(NDVR" || left(option,1) || left(ZTRAIL,1) || ")"
   scrName =  scrName "NEWAPPL(" || APPL || ") PASSLIB"

   ADDRESS ISPEXEC "CONTROL ERRORS RETURN"
   ZERRMSG = ""

   select
      when option =   ""  then    /* Nothing entered                 */
         nop
      when (option = "1" | option = "E") then   /* Classic Endevor   */
         "ISPEXEC SELECT PGM(C1SM1000)  PARM("ZTRAIL") NOCHECK "scrName
      when (option = "2" | option = "Q") then   /* Quick Edit        */
         "ISPEXEC SELECT PGM(ENDIE000)  PARM("ZTRAIL") NOCHECK" scrName
      when (option = "3" | option = "P") then   /* PDM               */
         "ISPEXEC SELECT PGM(BC1G1000)  PARM("ZTRAIL") NOCHECK" scrName
      when (option = "S")                then   /* Settings          */
         call EditSets            /* Process User request            */
   /* Undocumented options */
      when option =  "I7" then    /* ISPF Option 7 - Dialogue Test   */
         "ISPEXEC SELECT PGM(ISPYXDR) PARM("appl")     NOCHECK" scrname
      when option =  "DD" then    /* ISRDDN                          */
         "ISPEXEC SELECT CMD(ISRDDN ONLY NDVR)         NOCHECK" scrname
      when option = "FDP" then    /* LongName Utility FDP            */
         "ISPEXEC SELECT CMD(%LONGNAME)                NOCHECK" scrname
      otherwise do
         ADDRESS ISPEXEC "CONTROL ERRORS CANCEL"
         "ISPEXEC SETMSG MSG(ISPD241)"
        return 8
      end
   end

   ADDRESS ISPEXEC "CONTROL ERRORS CANCEL"
   InvokRet = 0
   IF ZERRMSG \= "" THEN DO
      InvokRet = 1
      "ISPEXEC SETMSG MSG("ZERRMSG")"
   END

return InvokRet

EditSets:    /* Display user Environment Settings panel and validate  */
   /* Save current variables                                          */
   WAPPLNDV = APPLNDVR
   WDFLTNDV = DFLTNDVR
   WENABUSR = ENABUSER
   WENABSIT = ENABSITE
   WUserPfx = UserPfx
   WSitePfx = SitePfx
   WProdPfx = ProdPfx
   WREXXGMS = REXXGMSG
   WCURS = ''
   WMSG = ''
   do forever
      ZCMD = ""                   /* reset Entry field                */
      If WCURS \= '' Then WCURS = 'CURSOR('WCURS')'
      If WMSG \= '' Then WMSG = 'MSG('WMSG')'
      "ISPEXEC DISPLAY PANEL(ENDEVORE)" WCURS WMSG
      dispRC = RC
      WCURS = ''
      WMSG = ''
      if dispRC > 0 then leave    /* If user pressed END/RETURN       */
      if ZCMD = 'CAN',            /* If Cancel - restore settings and */
       | ZCMD = 'CANCEL' then leave  /* just exit                     */

      /* Validate the prefixes                                        */
      ValPfx = UserPfx SitePfx ProdPfx   /* Concatenate prefixes      */
      Do j = 1 to words(ValPfx)
         TestPfx = word(ValPfx,j)
         ValRC = SYSDSN(TestPfx)
         If LEFT(ValRC,20) = "INVALID DATASET NAME"
         Then leave
         Else ValRC = 0
      End
      If ValRC \= 0
      Then do
         /* determine which prefix field has the error                */
         If j <= words(UserPfx)
         Then WCURS = 'UserPfx'
         Else
            If j <= words(UserPfx) + words(SitePfx)
            Then WCURS = 'SitePfx'
            Else WCURS = 'ProdPfx'
         /* Set error message and redisplay the panel                 */
         WMSG = 'CISSD006'
         DADSN = TestPfx          /* CISSD006 displays this variable  */
         iterate
      End

      /* If user Pressed Enter - process options and re-invoke EXEC   */
      If ZCMD = "" then do        /* Go validate and try...           */

         /* Call clean-up routines to free resources we hold          */
         call SaveProfile  /* Capture Users current                   */
         call LibdUnSt     /* De-Stack LIBDEFs                        */
         call Libdfree     /* ...now free and exit...                 */
         call RestProfile  /* Restore Users current settings          */

         /* Decide how to pass control, Explicit or implicit?         */
         parse source OP_SYSTEM HOW_CALLED EXEC_NAME,
            DD_NAME DATASET_NAME AS_CALLED,
            DEFAULT_ADDRESS,
            NAMEOF_ADDRESS_SPACE
         if DATASET_NAME == '?' then
            invokeStr = '%' || EXEC_NAME
         else
            invokeStr = "EX '"DATASET_NAME"("EXEC_NAME")'"

         /* Now we have to build the parm string to pass              */
         /* Allow user to specify - to disable an option              */
         /* or "blank" it out to not send anything (let default apply)*/
         parms = ""
         if DFLTNDVR   \= "" ,
          & DFLTNDVR   \= "-" then parms = parms "DF("DFLTNDVR")"
         if APPLNDVR   \= "" ,
          & APPLNDVR   \= "-" then parms = parms "APPL("APPLNDVR")"
         if LPARLIST   \= "" ,
          & LPARLIST   \= "-" then parms = parms "LL("LPARLIST")"
         if UserPfx    \= ""  then
            if UserPfx \= "-" then parms = parms "UP("UserPfx")"
            else                   parms = parms "UP( )"
         if SitePfx    \= ""  then
            if SitePfx \= "-" then parms = parms "SP("SitePfx")"
            else                   parms = parms "SP( )"
         if ProdPfx    \= ""  then
            if ProdPfx \= "-" then parms = parms "PP("ProdPfx")"
         if ENABSITE   \= "/" then parms = parms "NOSITE"
         if ENABUSER   \= "/" then parms = parms "NOUSER"
         if REXXGMSG   \= ""  then parms = parms "GM(" || REXXGMSG ||")"
         else                      parms = parms "NOGMSG"

         /* Finally - reinvoke the Rexx passing the Parms (and exit)  */
         sa= " "
         sa= "About to switch settings to:" PARMS
         sa= "ISPEXEC SELECT CMD("invokeStr "'"PARMS"'" ||,
             ") NEWAPPL("applndvr") MODE(FSCR)"
             "ISPEXEC SELECT CMD("invokeStr "'"PARMS"'" ||,
             ") NEWAPPL("applndvr") MODE(FSCR)"
         exit 0
      end
   end
   /* Restore variables                                               */
   APPLNDVR = WAPPLNDV
   DFLTNDVR = WDFLTNDV
   ENABUSER = WENABUSR
   ENABSITE = WENABSIT
   UserPfx  = WUserPfx
   SitePfx  = WSitePfx
   ProdPfx  = WProdPfx
   REXXGMSG = WREXXGMS

return 0

/*
  This routine will open/check the current command table and if not found
  create a new one copying the Endevor one (CTLICMDS)
  */
CopyTabl:
  CTLICMDS = "CTLICMDS"           /* Name of Table for Msgs -Source   */
  APPLCMDS = appl"CMDS"           /* Name of Table for Msgs -TGT      */

  /* At this point in processing we need access to command table but
     we might not have turned on the libdefs yet - just set up a temp
     libdef to the prod tables and use that

     TODO: This workaround seems to work (we can copy CTLICMDS) but it
     might not be the right one - we'd have to complete processing
     of all arguments to get the right ISPTABL concatenation, and
     even then it has to be copied before we invoke with the NEWAPPL
     keyword.
     */
  Sa= "DEBUG: APPLID:" ZAPPLID "DESIRED:"APPL
  ADDRESS ISPEXEC "LIBDEF ISPTLIB STACK DATASET",
          "ID('"ProdPfx"."word(ISPTLIB,words(ISPTLIB))"')"
  ADDRESS ISPEXEC "TBOPEN"  APPLCMDS "NOWRITE SHARE" /* maybe there?  */
  if RC = 0 then do                       /* Table is good - get out  */
     ADDRESS ISPEXEC "TBEND" APPLCMDS     /* we opened, so we close   */
     ADDRESS ISPEXEC "LIBDEF ISPTLIB "         /* restore ISPTLIB     */
     return 0
  end
  /*
     Table should already be open, check it's status...
    */
  ADDRESS ISPEXEC "TBSTATS" APPLCMDS "STATUS2(APPLTST2)"
  if APPLTST2 = 4 Then do         /* if table Open Share nowrite -    */
     sa= "Table exists - nothing to do here!"  /* we're all good, exit*/
  end
  if APPLTST2 = 2 ,               /* if table not open in this screen */
   | APPLTST2 = 3 ,               /* or table is open in WRITE mode...*/
   | APPLTST2 = 5 then do         /* or SHARED WRITE mode (not suppt')*/
     Say "Invalid Table Status"   /* something bad has happened - exit*/
     Say "Table:" APPLCMDS "has status2:" APPLTST2
     Say "Command tables should have status of 4 - (Shared NoWrite)"
     ADDRESS ISPEXEC "LIBDEF ISPTLIB "         /* restore ISPTLIB     */
     return 0
  end
  /*
     Continue ... Find the table keys and varnames from the Endevor model
    */
  ADDRESS ISPEXEC "TBOPEN"  CTLICMDS "NOWRITE SHARE"
  If rc \= 0 Then do
     Say "Bad RC: from TBOpen CTLICMDS RC:" rc /*  get out on error   */
     ADDRESS ISPEXEC "LIBDEF ISPTLIB "         /* restore ISPTLIB     */
     return 12
  end
  ADDRESS ISPEXEC "TBQUERY" CTLICMDS "KEYS(TABKEYS) NAMES(TABVARS)"
  /*
    Make a copy of CTLICMDS table
    */
  ADDRESS ISPEXEC "TBCREATE" APPLCMDS ,        /* using the APPL name */
               /* "KEYS"TABKEYS */ ,           /* no keys but vars &  */
                  "NAMES"TABVARS ,             /* options to match    */
                  "NOWRITE SHARE"              /* DO NOT save to disk!*/
  If rc \= 0 Then do
     Say "Bad RC: from TBCreate RC:" rc        /*  get out on error   */
     ADDRESS ISPEXEC "LIBDEF ISPTLIB "         /* restore ISPTLIB     */
     return 12
  end

  /* Otherwise - start at the top and copy each row                   */
  ADDRESS ISPEXEC "TBTOP" CTLICMDS
  DO FOREVER
     ADDRESS ISPEXEC "TBSKIP" CTLICMDS "SAVENAME(SAVEVARS)" /* next   */
     if rc \= 0 THEN LEAVE                     /* ...at end we're done*/
     ADDRESS ISPEXEC "TBADD" APPLCMDS  "SAVE(SAVEVARS)" /* add  to tmp*/
     if rc \= 0 THEN                           /* somethign wrong!    */
        Say "Bad RC from TBADD RC:" rc
  END

  ADDRESS ISPEXEC "TBEND" CTLICMDS             /* we're finished with */
                                               /* the source table    */
  ADDRESS ISPEXEC "LIBDEF ISPTLIB "            /* restore ISPTLIB     */

  if SayInfo then say "CMDTABLE  Elapsed:" TIME(E)

Return 0


ParseArgs:/* Parse any options or overrides passed to the routine     */
/*--------------------------------------------------------------------*/
/* Parse Values passed to routine                                     */
/*--------------------------------------------------------------------*/

   /*
      If we were invoked from TSO/E we want to set up a tasklib and
      then invoke ourselves under PDF - this requires that ENDEVORS
      has been added to the primary menu with NOCHECK to pass the
      trailing parms
      */

   if SYSVAR("SYSISPF") = "ACTIVE" THEN
      /* If we are in ISPF get vars we need                           */
      address ISPEXEC "VGET (ZTERM ZTRAIL ZAPPLID)"
   else
      LIBDEFS = "STEPNDVR SYSPROC"   /* we only need TASKLIB/SYSPROC  */

   /* If there are no parms, check ZTRAIL (i.e. Entering from TSO/E)  */
   if parms == "" then do
      if ZTRAIL \= "" then
         parms = translate(ZTRAIL,' ()','!{}')  /* replace markers    */
   end

   /* Make sure Parms are all uppercase                               */
   parms = translate(parms)

   /* check if Debug is required                                      */
   PARSE VAR PARMS 'DEBUG(' debugOpt ')'
   if debugOpt == ""      then debugOpt = "NOBUG"
   select
      when debugOpt == "DEBUG" then Trace re
      when left(debugOpt,5) == "TRACE" then Trace VALUE SubStr(debugOpt,6)
      when  debugOpt == "INFO" then SayInfo = 1
      otherwise NOP
   end
   TraceOpt = Trace()                /* Propagate Trace Option(s)     */

   /* Did caller specify an Endevor option to invoke? - Yes:Save it   */
   if pos('OPT(',parms) > 0 then
      PARSE VAR PARMS 'OPT(' OPTNNDVR ')'

   if pos('DF(',parms) > 0 then
      PARSE VAR PARMS 'DF(' DFLTNDVR ')'

   if pos('PP(',parms) > 0 then
      PARSE VAR PARMS 'PP(' ProdPfx ')'

   /* Check if we are being called from ISPF - and check our applid   */
   if SYSVAR("SYSISPF") = "ACTIVE" THEN do

      /* check the applid and relaunch if new appl is required   */
      PARSE VAR PARMS 'APPL(' APPL ')'
      if APPL = "" then
         APPL = APPLNDVR
      else APPLNDVR = APPL

      if APPL \= "CTLI" then         /* If appl is not the default one*/
         call CopyTabl               /* Check/Create a copy of the    */
                                       /* Endevor cmd table if needed */
      if APPL \== ZAPPLID then do
         parse source OP_SYSTEM HOW_CALLED EXEC_NAME,
            DD_NAME DATASET_NAME AS_CALLED,
            DEFAULT_ADDRESS,
            NAMEOF_ADDRESS_SPACE
         if DATASET_NAME == '?' then
            invokeStr = '%' || EXEC_NAME
         else
            invokeStr = "EX '"DATASET_NAME"("EXEC_NAME")'"
         sa= " "
         sa= "About to switch applid to:" APPL "passing:" PARMS
         sa= "ISPEXEC SELECT CMD("invokeStr "'"PARMS"'" ||,
             ") NEWAPPL("appl") MODE(FSCR)"
             "ISPEXEC SELECT CMD("invokeStr "'"PARMS"'" ||,
             ") NEWAPPL("appl") MODE(FSCR)"
         exit 0
      end
   end

   /* If the user has saved a preference to enable SITE/USER prefix
      fetch it now.  Then it can be overridden by passed parms
      */
   if SYSVAR("SYSISPF") = "ACTIVE" THEN do
      address ISPEXEC "VGET (NDVLUSER NDVLSITE) PROFILE"
      if RC = 0 then do /* if the user has a stored preference...     */
         ENABSITE = NDVLSITE
         ENABUSER = NDVLUSER
      end
      /* Initialize ENDEVORM scrollable area variables                */
      THUMBA = ''
      THUMBS = ''
      address ispexec "VPUT (THUMBA,THUMBS) PROFILE"
   end

   if pos('SP(',parms) > 0 then do          /* Site Prefix            */
      PARSE VAR PARMS 'SP(' SitePfx ')'
      ENABSITE = "/"
   end

   if pos('UP(',parms) > 0 then do          /* User Prefix            */
      PARSE VAR PARMS 'UP(' UserPfx ')'
      ENABUSER = "/"
   end

   if pos('GM(',parms) > 0 then do          /* Good-Morning Routine   */
      PARSE VAR PARMS 'GM(' REXXGMSG ')'
      ENABGMSG = "/"
   end

   /* LPARLIST parameter can be used to specify the list of LPARs
      searched to determine if Endevor libraries should be allocated
      by a dynamic STEPLIB utility.
      Leave LPARLIST empty if the Endevor libraries are in the
      LINKLIST, LPA or in STEPLIB.
      */
   if pos('LL(',parms) > 0 then do          /* LPARLIST               */
      PARSE VAR PARMS 'LL(' LPARLIST ')'
   end

   if wordpos('NOSITE',PARMS) > 0 then do   /* Don't use SITE PREFIX  */
      ENABSITE = " "
   end

   if wordpos('NOUSER',PARMS) > 0 then do   /* Don't use User Prefix  */
      ENABUSER = " "
   end

   if wordpos('NOGMSG',PARMS) > 0 then do   /* Don't use Good-Morning */
      ENABGMSG = " "                        /* routine                */
   end

   allPrfx = ProdPfx
   if ENABSITE = "/" then allPrfx = SitePfx allPrfx
   if ENABUSER = "/" then allPrfx = UserPfx allPrfx

return

/* local routines                                                     */

RepWord: procedure               /* Routine to replace words in string*/
  istring = arg(2)               /* arg1=Search string, Arg2=InpString*/
  rstring = ""                   /* and arg3 is the replacement string*/
  if length(arg(3)) > 0 ,        /* If the replacement string is NULL */
     then notnull = 1            /* matching word is removed          */
     else notnull = 0
  do words(istring)              /* repeat for each word in inpString */
     parse var istring thisword istring
     if thisword = arg(1) then   /* does it match the search string?  */
        if notNull then          /*...and it's not null               */
           rstring = rstring arg(3) /* ... then append it to rtnString*/
        else nop                 /*    otherwise don't append a space */
     else                        /* If the word didn't match          */
        rstring = rstring thisword  /* just tack it on the end        */
  end
return strip(rstring,'L')        /* return the replaced string        */
