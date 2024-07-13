/* REXX ENDIE430

        This is the QuickEdit Batch Action Sub Queue Cmd handler.
        It will display the submit job confirmation panel and
        addlow EDit, [ENTER] submit, and associated JCL options to be
        specified/modified.

        Copyright (C) 2022 Broadcom. All rights reserved.
    */

/* Initialise Environment and Variables */
  ADDRESS ISPEXEC
  'VGET (EEVQUTAB VNTQUENA EEVINJCL ZSCREEN EEVQUREQ)' /* use ENzIESCL*/
  'VGET (C1BJC1 C1BJC2 C1BJC3 C1BJC4) PROFILE'   /* Get Jobcards      */
  QETABL = 'EN' || ZSCREEN || 'IE250'      /* QuickEdit table name    */
  ENTRYCMD  = ''
  VARWKCMD  = ''
  ZVERB     = ''
  DISPRC    = 0
  PARMFRR   = ''
  PARMTOR   = ''
  VALCMDS   = 'EDIT ED EDITJCL EJ NEW' ,   /* List of valid commands and  */
     'SUBMIT SUB SU VALIDATE VAL CANCEL CAN EXITING BUILD BLD' /* Abbrev's*/

  if ARG() > 0 then do                     /* were we invoked with Arg    */
     parse upper arg VNTQUEP1 VNTQUEP2,    /* ... only need first word    */
        PARMFRR PARMTOR .                  /* From and To row if specified*/
     'VPUT (VNTQUEP1 VNTQUEP2) SHARED'     /* Save parms for others       */
     if wordpos(VNTQUEP1,VALCMDS) > 0 then /* DO we recognise a valid     */
        ENTRYCMD = strip(VNTQUEP1 VNTQUEP2)/* ... command? Y-use it       */
     else                                  /* not expecting this parm     */
        'SETMSG MSG(ENDE219W)'             /* let user know valid prms    */
  end

  if (VNTQUENA \= 'E') ,                   /* Feature not enabled         */
   | (EEVQUTAB  = '' ) then                /*  or table name not set      */
     if (EEVQUREQ < 1) then                /*   and there are no reqs     */
        do
           "SETMSG MSG(ENDE213E)"          /* not enabled                 */
           exit 0
        end

  IF ENTRYCMD == 'EXITING' then do         /* handle special case         */
       'SETMSG MSG(ENDE219C)'              /* ... last chance END=EXIT    */
        ENTRYCMD = ''                      /* ... go directly to disp     */
     end

/* Check if there are any records to submit, unless user entered NEW      */

  if word(ENTRYCMD,1) == 'BUILD' ,         /* Skip tests if we don't need */
   | word(ENTRYCMD,1) == 'BLD' ,           /* i.e. NEW, Build or Bld...   */
   | ENTRYCMD == 'NEW' then nop            /* creating new SCL from scrat */
  else do
     EEVQURCT = 0
     EEVQUST2 = 0
     'TBSTATS' EEVQUTAB ,                  /* Get current Que Table stats */
             'ROWCURR(EEVQURCT)',          /*   Current row count         */
             'STATUS2(EEVQUST2)'           /*      and status open/closed */
     if (EEVQURCT = 0),                    /* No rows                     */
      | (EEVQUST2 < 2) THEN                /* Or Table Not Open           */
        do
           'SETMSG MSG(ENDE210W) COND'     /* Nothing to Submit           */
           exit 0
        end
     else
        'SETMSG MSG(ENDE211I) COND'        /* 'Edit or Submit'            */
  end

/* Display Prompt Panel */
DISPPANL:
  DO FOREVER                               /* Main Display Loop           */
     IF ENTRYCMD \= '' then do             /* Check for valid entry cmd   */
        VARWKCMD  = ENTRYCMD               /* Use the Entry command       */
        ENTRYCMD  = ''                     /* reset to avoid overuse      */
     end
     else do                               /* otherwise...                */
        'VGET (EEVQUREQ)'                  /* refresh values in case...   */
        'DISPLAY PANEL(ENDIE700)'          /* do display                  */
        DispRC = RC                        /* save the return code        */
        'VGET (ZVERB)'                     /* Check what the user did...  */
        if ZVERB \== 'CANCEL' then         /* If user is not cancelling   */
           'VPUT (C1BJC1 C1BJC2 C1BJC3' ,  /* .save the jobcards and user */
              'C1BJC4 EEVINJCL) PROFILE'   /* .include jcl choices        */
     end                                   /*                             */

     /* Process Regular Commands                                          */

     Select
        when VARWKCMD == 'CANCEL',         /* Cancel Command (parm) or    */
           | VARWKCMD == 'CAN' ,           /* Can      . or               */
           | ZVERB == 'CANCEL' THEN do     /* Cancel Request ...          */
           'SETMSG MSG(ENDE214I)'          /* Submit queue Cancelled      */
           if VNTQUEP1 == 'EXITING' THEN   /* were we on the way out?     */
              leave                        /* ... no point updating tabl  */
           call TBCRRUTN                   /* Delete & Recreate the Queue */
           x=TOGLRUTN(QETABL,'EEVETDMS',   /* Replace *Queued with        */
                  'CIEV199O','CIEV191I')   /*  *Cancelled message         */
           x=TOGLRUTN(QETABL,'EEVETDMS',   /* And *Built with             */
                  'CIEV199P','CIEV191I')   /*  *Cancelled message         */
           x=TOGLRUTN(QETABL,'EEVETDMS',   /* And *Saved/Que with         */
                  'CIEV199M','CIEV191L')   /*  *Not Gen'd                 */
           leave                           /* and get out                 */
        end
        when DispRC >= 8 THEN do           /* End Request ...             */
           IF ZVERB == 'END'    then       /* Are we processing an END?   */
              'SETMSG MSG(ENDE217I)'       /* Msg:This request Canceled   */
           else                            /* Otherwise (Return or Cancel)*/
              'SETMSG MSG(ENDE214I)'       /* Msg:Sub Que Canceled        */
           leave                           /* Just exit _ leave queue     */
        end
        when VARWKCMD == 'EDIT',           /* Edit Request ...            */
           | VARWKCMD == 'NEW',            /* New  Request...             */
           | VARWKCMD == 'ED',             /* Ed   Request...             */
           | VARWKCMD == 'E'    THEN do    /* E    Request...             */
           call EDITRUTN                   /* Invoke Edit routine         */
           VARWKCMD = ''                   /* clear command               */
        end
        when VARWKCMD == 'VALIDATE' ,      /* Validate or                 */
           | VARWKCMD == 'VAL'  THEN do    /* Val  Request...             */
           call VALSRUTN                   /* Invoke Validate Routine     */
           VARWKCMD = ''                   /* clear command               */
        end
        when VARWKCMD == 'EDITJCL' ,       /* Edit Request for JCL ...    */
           | VARWKCMD == 'EJ'      THEN do /* EJ   Request ...            */
           call EJCLRUTN                   /* Invoke Edit routine         */
           VARWKCMD = ''                   /* clear command               */
        end
        when word(VARWKCMD,1) == 'BUILD' , /* Build Request for SCL...    */
           | word(VARWKCMD,1) == 'BLD' THEN do /* BLD  Request ...        */
           parse upper var varwkcmd . VNTQUEP2 . /* get trailing parameter*/
           x=BSCLRUTN(QETABL,'EEVETDMS',   /* Process TABLE replacing MSG */
                  'CIEV199P',VNTQUEP2)     /*  with *Built for Action     */
           if x > 0 then                   /* did we build any requests?  */
             call EDITRUTN                 /* then EDIT what you built... */
           else                            /* otherwise we can't build    */
             leave                         /* ...from here show ENDE210C  */
           VARWKCMD = ''                   /* clear command               */
        end
        when VARWKCMD == '' ,              /* ENTER to Submit ...         */
           | VARWKCMD == 'SUB',            /* or SUB from parm...         */
           | VARWKCMD == 'SU'      THEN do /* or SU  from parm...         */
             'TBSTATS' EEVQUTAB ,          /* Get current Que Table stats */
                'ROWCURR(EEVQURCT)',       /*   Current row count         */
                'STATUS2(EEVQUST2)'        /*      and status open/closed */
           if EEVQURCT = 0 then            /* check we have something     */
             'SETMSG MSG(ENDE210W)'        /* Nothing to Submit           */
           else do
              if EEVINJCL = 'Y'    THEN do /* Do we need include JCL?     */
                 DispRC = EINCRUTN()       /* Display panel ENDIE710      */
                 if DispRC = 8 then do     /* End from JCL back's up      */
                    'SETMSG MSG(ENDE217I)' /* Msg:Request Canceled        */
                    iterate
                 end
              end
              call ESUBRUTN                /* Submit Routine              */
              leave                        /* we're done exit with the msg*/
           end
        end
        otherwise                          /* command not recognized      */
          'SETMSG MSG(ENDE219E)'           /* let user know valid prms    */
     end
  END

EXIT 0                                     /* We're done, get out         */

/* Recreate table on request  Note: We need )PANEL and ZVERB to be sure!  */
TBCRRUTN:
     'TBCREATE' EEVQUTAB ,                 /* Recreate the Table          */
       'NAMES(EEVQUSCL)' ,
       'NOWRITE REPLACE'
     'TBSTATS' EEVQUTAB ,                  /* Update the TableStats       */
       'ROWCURR(EEVQURCT)',
       'STATUS2(EEVQUST2)'
     EEVQUREQ = '00000000'                 /* Reset the Request Count     */
     'VPUT (EEVQUREQ) SHARED'              /* Update the TableStats       */
RETURN

/* Edit the SCL/JCL and allow user to save/validate/submite etc.          */
EDITRUTN:
   /*'SETMSG MSG(ENDE214I)' */             /* Submit queue Cancelled      */
     'FTOPEN TEMP'                         /* Start File Tailoring        */
     'FTINCL ENDES010'                     /* Insert the SCL              */
     'FTCLOSE'
     'VGET (ZTEMPF ZTEMPN)'                /* Get File Tailoring vars     */
     'LMINIT DATAID(DDID) DDNAME(&ZTEMPN)' /* Get a file handle to match  */
     'EDIT DATAID(&DDID) PROFILE(SCL) MACRO(ENDIE4VI)' /* edit the SCL    */
     EditRC = RC                           /* RC:4 means no change or can */
     'LMFREE DATAID(&DDID)'                /* release handle              */
     'VGET (ZVERB)'                        /* Verb: End, Return, Cancel   */
     sa= 'RC:'rc 'Verb:' ZVERB
     if EditRC=0 THEN DO                   /* RC:0 Means file was edited  */

       /* Read input file (JCL skeleton)                                  */
       ADDRESS TSO "EXECIO * DISKR" ZTEMPN "(STEM SCLIN. FINIS"
       IF RC ^= 0 THEN SIGNAL IOERROR

       SAVEEREQ = EEVQUREQ                  /* Save current count         */
       call TBCRRUTN                        /* reset/replace the table    */
       EEVQUREQ = SAVEEREQ                  /* restore current count      */
       EEVQURCT = RIGHT(SCLIN.0,8,'0')      /* How many lines to process  */
       do i = 1 by 1 to SCLIN.0             /* repeat each input line     */
         EEVQUSCL = SCLIN.i
         'TBADD' EEVQUTAB 'MULT('EEVQURCT')'
       end

       if SCLIN.0 = 0 then do               /* If we have no lines left   */
          EEVQUREQ = '00000000'             /* . Reset request count      */
         'SETMSG MSG(ENDE210W)'             /* Nothing to Submit */
       end
       else do                              /* otherwise make sure we have*/
          IF DATATYPE(STRIP(EEVQUREQ,'L','0'),N) = 0 , /* a valid number  */
           | EEVQUREQ < 1 THEN              /* and it's not less than 1   */
             EEVQUREQ = '00000001'          /* or set it to 1 (be valid)  */
       end
       'VPUT (EEVQUREQ EEVQURCT) SHARED'    /* Update the TableStats      */
     end
     if ZVERB = 'END' ,                     /* If user didnt cancel or RTN*/
      & EEVQUREQ \= '00000000' then         /* ...and there is at least 1 */
         call VALSRUTN                      /*  . Invoke Validate Routine */
RETURN

/* Edit the SCL/JCL and allow user to save/validate/submite etc.          */
EJCLRUTN:
     'SETMSG MSG(ENDE212I)'                /* Sub or End                  */
     'FTOPEN TEMP'                         /* Start File Tailoring        */
     'FTINCL ENDES000'                     /* Insert the SCL              */
     'FTCLOSE'
     'VGET (ZTEMPF ZTEMPN)'                /* Get File Tailoring vars     */
     'LMINIT DATAID(DIDVAR) DDNAME('ZTEMPN') ENQ(SHR)' /* and get handle  */
     'EDIT DATAID('DIDVAR') PROFILE(JCL)'  /* Edit using handle           */
     EditRC = RC                           /* RC:4 means no change or can */
     'LMFREE DATAID('DIDVAR')'             /* Free handle - all done      */
     'VGET (ZVERB)'                        /* Verb: End, Return, Cancel   */
     sa= 'RC:'rc 'Verb:' ZVERB
/* Not sure what should happen after an EDITJCL - should I clear the queue
   or require an explicit Cancel - clearly a cancel of the Edit session is
   just that, a cancel of the The edit session - without hooking the SUBMIT
   command I don't know if they have done a submit (or the jobname/number)
   which might be a good idea (make it use CISUB) and then delete the queue
   Message ENDE212I lets them know they can SUB to Submit, End to Clear or
   CANCEL to exit without any changes.
*/
     if ZVERB \== 'CANCEL' THEN DO         /* Assume Job edited/submitted */
       call TBCRRUTN                       /* reset the table             */
       'SETMSG MSG(ENDE214I)'              /* Submit queue Cleared...     */
     end
RETURN

/* Validate the SCL and let user know if not valid                        */
VALSRUTN:
     'FTOPEN TEMP'                         /* Start File Tailoring        */
     'FTINCL ENDES010'                     /* Insert the SCL              */
     'FTCLOSE'
     'VGET (ZTEMPF ZTEMPN)'                /* Get File Tailoring vars     */
     'SELECT PGM(ENDIE4VS)'                /* invoke validation routine   */
     ValdRC = RC                           /* RC:4 means no change or can */
     sa= 'RC:'rc 'from Validate routine'
RETURN

/* Include JCL                                                            */
EINCRUTN:
     'VGET (',                             /* Freshen all vars            */
           'VNBDD01 VNBDD02 VNBDD03 VNBDD04 VNBDD05 VNBDD06',
           'VNBDD07 VNBDD08 VNBDD09 VNBDD10 VNBDD11 VNBDD12',
           'VNBDD13 VNBDD14 VNBDD15 VNBDD16 VNBDD17 VNBDD18',
           'VNBDD19 VNBDD20 ) ASIS'
     'DISPLAY PANEL(ENDIE710)'             /* Get Additional JCL etc.     */
     DispRC = RC
     address ispexec 'VGET (ZVERB)'        /* Cancel, End or Return?      */
     if DispRC = 0 then                    /* Just pressed Enter?         */
        'VPUT (',                          /*   Then save all vars        */
           'VNBDD01 VNBDD02 VNBDD03 VNBDD04 VNBDD05 VNBDD06',
           'VNBDD07 VNBDD08 VNBDD09 VNBDD10 VNBDD11 VNBDD12',
           'VNBDD13 VNBDD14 VNBDD15 VNBDD16 VNBDD17 VNBDD18',
           'VNBDD19 VNBDD20 ) PROFILE'
     else                                  /* otherwise RESTORE           */
        'VGET (',                          /*   all vars                  */
           'VNBDD01 VNBDD02 VNBDD03 VNBDD04 VNBDD05 VNBDD06',
           'VNBDD07 VNBDD08 VNBDD09 VNBDD10 VNBDD11 VNBDD12',
           'VNBDD13 VNBDD14 VNBDD15 VNBDD16 VNBDD17 VNBDD18',
           'VNBDD19 VNBDD20 ) PROFILE'
RETURN DispRC

/* Submit the JCL                                                         */
ESUBRUTN:
     'VPUT (C1BJC1 C1BJC2 C1BJC3 C1BJC4) PROFILE' /* Save JobCards        */
     'FTOPEN TEMP'                         /* Start File Tailoring        */
     'FTINCL ENDES000'                     /* Insert the SCL              */
     'FTCLOSE'
     'VGET (ZTEMPF ZTEMPN)'                /* Get File Tailoring vars     */
     'SELECT CMD(%CISUB' ZTEMPF ')'        /* Call Submit Routine         */
     SubRC = RC                            /* I expect only RC:0 but could*/
     sa= 'RC:'Subrc 'Verb:' ZVERB          /*   also see END/RETURN/CANCEL*/
     if SubRc = 0          THEN DO         /* Assume Job edited/submitted */
       call TBCRRUTN                       /* reset the table             */
       call INCRRUTN                       /* reset the table             */
       'SETMSG MSG(ENDE216I) COND'         /* Job Submitted, Request Clea */
     x = TOGLRUTN(QETABL,'EEVETDMS',       /* Replace *Queued with        */
              'CIEV199O','CIEV198L')       /*  *Submitted message         */
     x = TOGLRUTN(QETABL,'EEVETDMS',       /* Replace *Built with         */
              'CIEV199P','CIEV198L')       /*  *Submitted message         */
     x = TOGLRUTN(QETABL,'EEVETDMS',       /* And *Saved/Que witj         */
              'CIEV199M','CIEV191Q')       /*  *Saved/Sub                 */
     end
RETURN SubRc

/* Search and replace a given column in a given table                     */
TOGLRUTN:
   parse arg  tablename, srchfld,          /* Name of table & column      */
              frmsg, tomsg .               /* the from and two message IDs*/
    'GETMSG MSG('FRMSG') SHORTMSG(FRMSG)'  /* Look up from and to messages*/
    'GETMSG MSG('TOMSG') SHORTMSG(TOMSG)'  /* which may be DBCS strings   */
    CNTUPDTS = 0                           /* Initialise changed row count*/
    'CONTROL ERRORS RETURN'                /* allow rc from top if not ope*/
    'TBTOP'  tablename                     /* Start at top of table       */
    IF RC > 0 THEN return CNTUPDTS         /* Get out if table not avail  */
    'CONTROL ERRORS CANCEL'                /* allow rc from top if not ope*/
     do forever                            /* now search table...         */
        'TBVCLEAR' tablename               /*  clear vars                 */
        x = value(srchfld,FRMSG)           /* Set our target value        */
        'TBSARG'   tablename ,             /* Set up Args for search      */
             'NEXT NAMECOND('srchfld',EQ)' /*   NEXT for named column     */
        'TBSCAN'   tablename 'SAVENAME(QEEXT)' /* find next match with ext*/
        if rc > 0 then leave               /* get out on not found        */
        x=value(srchfld,tomsg)             /* otherwise set new value     */
        'TBPUT'    tablename 'SAVE(QEEXT)' /* Update table with any ext v */
        CNTUPDTS = CNTUPDTS + 1            /* Increment counter           */
     end                                   /* End scan loop               */
return CNTUPDTS                            /* pass back number of hits    */

/* Add a line of SCL to our request Table                                 */
ADDSCL:
   parse arg SCLREC
   SCLPERL = SCLPERL + 1                   /* increment the item count    */
   EEVQUSCL = LEFT(sclrec,72),             /* get the SCL stmt            */
    || RIGHT(CNTBUILD,6,'0'),              /* append a request number     */
    || RIGHT(SCLPERL,2,'0')                /* and a per request count     */
   'TBADD' EEVQUTAB                        /* add the request to scl table*/
return rc                                  /* return with RC from Add     */

/* Build SCL for the current Element Selection list                       */
BSCLRUTN:
   parse arg  bscltab, srchfld,            /* Name of table & column      */
              slmsg, bldact .              /* the msg to set and action   */
   'GETMSG MSG('SLMSG') SHORTMSG(SLMSG)'   /* Look up the Selected Message*/
   if wordpos(bldact,,                     /* check valid actions         */
     'GEN GENERATE MOV MOVE TRA TRANSFER', /* for the ones we want to     */
     'DEL DELETE SIGNOUT SIGN',            /* support and their valid     */
      ) = 0 then                           /* abbreviations               */
         bldact = 'GENERATE'               /* default action is generate  */
   CNTBUILD = 0                            /* Initialise changed row count*/
   LASTENV  = ''                           /* Initialise control vars     */
   LASTSTG  = ''                           /* ...Stage ID                 */
   LASTSYS  = ''                           /* ...System Name              */
   LASTSUB  = ''                           /* ...SubSystem Name           */
   LASTTYP  = ''                           /* ...Type Name                */

   'TBSTATS' bscltab,                      /* Get current Table Stats     */
           'ROWCURR(QETABRCT)',            /*   Current row count         */
           'STATUS2(QETABST2)'             /*      and status open/closed */
   if (QETABRCT = 0),                      /* No rows                     */
    | (QETABST2 < 2) THEN                  /* Or Table Not Open           */
      do
         'SETMSG MSG(ENDE210C)'            /* Nothing to Build...         */
         return 0                          /* Get out if table not avail  */
      end

   ESTSCLS = RIGHT(QETABRCT+20,8,'0')      /* estimate space needed       */
   SCLPERL = 0                             /* reset per item count        */
   'TBBOTTOM' EEVQUTAB                     /* Position at bottom of SCL   */
   if rc = 0 then do                       /* if RC=0 then there is SCL   */
     x=ADDSCL(' ')                         /* ...already - add space ...  */
     x=ADDSCL('*** NEW BUILD REQUEST ***') /* ...          and marker...  */
     x=ADDSCL(' ')                         /* ...          and space ...  */
   end
   EEVQUSCL = LEFT('SET ACTION 'BLDACT' .',72),
    || RIGHT(CNTBUILD,6,'0'),              /* append a request number     */
    || RIGHT(SCLPERL,2,'0')                /* and a per request count     */
         'TBADD' EEVQUTAB 'MULT('ESTSCLS')'  /* first SCL with estimate   */

   /* CCID/Comment */
   x=ADDSCL(' ')                           /* Space a line After Action...*/
   'VGET (EEVCCID EEVCOMM) ASIS'           /* get current CCID/Comment    */
   x=ADDSCL('SET OPTION CCID "'LEFT(EEVCCID,12)'"') /* and add them even  */
   x=ADDSCL('        COMMENT "'LEFT(EEVCOMM,40)'" .') /* if blank in case */

   /* Build options string */
   options = ''                            /* start simple */
   'VGET (EEVCCID EEVCOMM', /* Get  CCID and COMMENT & MOVE/GEN OPTIIONS */
         'EEVOOSGN EEVOCPBK EEVONSRC EEVOAUTG EEVOSPAN EEVPRGRP',
         'EEVSYNC  EEVMOVWH EEVRTNSO EEVSETSO EEVJMPEL EEVF9NOD',
         'EEVSITSO EEVONLCM) SHARED'

   if EEVOOSGN == 'Y' THEN options = options 'OVERRIDE SIGNOUT'

   /* Generate Options */
   if LEFT(BLDACT,3) == 'GEN' THEN DO
      if EEVOCPBK == 'N' THEN options = options 'COPYBACK'  /* in place? */
      else if EEVONSRC == 'Y' THEN options = options 'NOSOURCE'
      if EEVOAUTG == 'Y' THEN
         options = options 'AUTOGEN SPAN' EEVOSPAN
      if EEVPRGRP \= '' THEN options = options 'PROCESSOR GROUP' EEVPRGRP
   end

   /* Move/Transfer Options */
   if LEFT(BLDACT,3) == 'MOV' ,
    | LEFT(BLDACT,3) == 'TRA' THEN DO
      if EEVSYNC  == 'Y' THEN options = options 'SYNCHRONIZE'
      if EEVMOVWH == 'Y' THEN options = options 'WITH HISTORY' /*History*/
      if EEVRTNSO == 'Y' THEN options = options 'RETAIN SIGNOUT '
      ELSE if EEVSETSO \= ''  THEN options = options 'SIGNOUT TO' EEVSETSO
      if EEVJMPEL == 'Y' THEN options = options 'JUMP'
      if EEVF9NOD == 'N' THEN options = options 'BYPASS ELEMENT DELETE'
   end

   /* Delete Options */
   if LEFT(BLDACT,3) == 'DEL' THEN DO
      if EEVONLCM == 'Y' THEN options = options 'ONLY COMPONENT'
   end

   /* Signout Options */
   if LEFT(BLDACT,3) == 'SIG' THEN DO
      if EEVSITSO \= ''  THEN options = options 'SIGNOUT TO' EEVSITSO
   end

   /* Now build options string */
   if options  \= '' THEN do               /* nothing more to do          */
      x=ADDSCL(' ')                        /* Space a line before opts... */
      j = 1                                /* init chunk count            */
      chunk. = copies(' ',10)              /* and clear chunks with prefix*/
      do i = 1 to words(options)           /* grab each word...           */
         chunk.j = chunk.j word(options,i) /* ...and append to chunk      */
         if length(chunk.j) > 50,          /* are we running out of space */
          & words(options) > i then        /* ...and we still have more   */
            j = J + 1                      /* start next chunk            */
      end
      chunk.1 = overlay('SET OPTION',chunk.1) /* insert on first          */
      chunk.j = strip(chunk.j,'T') '.'     /* append trailing dot         */
      do i = 1 to j                        /* Now write all the chunks    */
         x=ADDSCL(chunk.i)                 /* ...Add SCL line for this bit*/
      end
      drop chunk.
   end

   /* If it was a Transfer - append some target placeholders */
   if LEFT(BLDACT,3) == 'TRA' THEN DO
      x=ADDSCL(' ')                        /* Space a line before opts... */
      x=ADDSCL('* FOR TRANSFER FILL-IN/REMOVE TARGET INFO AS REQUIRED')
      x=ADDSCL('SET     TO ENV "<env>   " STAGE NUMBER n .')
      x=ADDSCL(' SET    TO SYS "<sys>   " SUBSY "<subsys>" .')
   end

   'TBTOP'  bscltab                        /* Start at top of table       */
   IF PARMFRR = '' then SKIPNUM = ''       /* default skip                */
   ELSE SKIPNUM = 'NUMBER('PARMFRR')'      /* set to first selected row   */
    do forever                             /* now search table...         */
       'TBVCLEAR' bscltab                  /*  clear vars                 */
       'TBSKIP'   bscltab ,                /* Get first/next row          */
          skipnum 'POSITION(BCSLCRP)',     /* Skippif necessary & set CRP */
          'SAVENAME(QEEXT)'                /* find next match with ext    */
       if rc > 0 then leave                /* get out on not found        */
       skipnum = ''                        /* Reset nitial skip           */
       CNTBUILD = CNTBUILD + 1             /* Increment counter           */

       /* Environment/Stage */
       if LASTENV \== EEVETKEN ,           /* Did Env                     */
        | LASTSTG \== EEVETKSI then do     /* ...or stage change?         */
          LASTENV = EEVETKEN               /* update Control Vars...      */
          LASTSTG = EEVETKSI               /* ...so we don't do again     */
          x=ADDSCL(' ')                    /* Space a line before env...  */
          x=ADDSCL('SET   FROM ENV "',     /* Build Set From Env..        */
          || left(LASTENV,8) || '" STAGE "' || left(LASTSTG,1) || '" .')
       end
       /* SYStem/Subsystem */
       if LASTSYS \== EEVETKSY ,           /* Did System                  */
        | LASTSUB \== EEVETKSB then do     /* ...or SubSys change?        */
          LASTSYS = EEVETKSY               /* update Control Vars...      */
          LASTSUB = EEVETKSB               /* ...so we don't do again     */
          x=ADDSCL(' SET  FROM SYS "',     /* Build Set From Env..        */
          || left(LASTSYS,8) || '" SUBSY "' || left(LASTSUB,8) || '" .')
       end
       /* Type */
       if LASTTYP \== EEVETKTY then do     /* Did type change?            */
          LASTTYP = EEVETKTY               /* update Control Vars...      */
          x=ADDSCL('  SET FROM TYP "',     /* Build Set From Env..        */
          || left(LASTTYP,8) || '" .')
       end

       /* Element */
       lenEle = length(strip(EEVETKEL))    /* check for long element names*/
       if lenEle <= 8 then                 /* Handle regular elements     */
       x=ADDSCL('  &&ACTION ELE "',        /* Add SCL line for this ele   */
         || left(EEVETKEL,8) ||'" .')
       else do                             /* Long elements need formating*/
         j = 0                             /* init chunk count */
         do i = 1 to lenEle by 51          /* chunk it 51 chr pieces      */
            j = J+1                        /* keep track of the # chunks  */
            chunk.j = copies(' ',15) || '"' || substr(EEVETKEL,i,51) ||'" ,'
         end
         chunk.1 = overlay('  &&ACTION ELE',chunk.1) /* insert on first   */
         chunk.j = strip(,                 /* and fix up last line by     */
            left(chunk.j,,                 /* removing the last quote and */
            (length(chunk.j)-3)),,         /* comma and then replacing    */
            'T') || '" .'                  /* them, after trimming with . */
         do i = 1 to j                     /* Now write all the chunks    */
            x=ADDSCL(chunk.i)              /* ...Add SCL line for this bit*/
         end
         drop chunk.
       end
       x=value(srchfld,SLMSG)              /* otherwise set *Built msg    */
       'TBPUT'    bscltab 'SAVE(QEEXT)'    /* Update table with any ext v */
       IF PARMTOR \= '' then               /* Do we have a TO ROW parm?   */
          if BCSLCRP >=  PARMTOR           /*  and we got to that point?  */
             then leave                    /*   then leave early          */
    end                                    /* End scan loop               */
    EEVQUREQ = RIGHT(EEVQUREQ+CNTBUILD,8,'0') /* update request count     */
    'VPUT (EEVQUREQ) SHARED'               /* Update the TableStats       */
/* eoc todo - do I need this?
    if EEVQUREQ > 0 THEN DO                /* If we have Queued requests  */
       VNTQUQUE = 'Y'                      /* ...set flag to indicate...  */
       'VPUT (VNTQUQUE) SHARED'            /* ...& save (but not to prof) */
    END
*/
return CNTBUILD                            /* pass back number of hits    */

/* Increment the QuickEdit JobCard                                        */
INCRRUTN:
   'VGET (C1BJC1 C1BJC2 C1BJC3 C1BJC4 ZUSER)'  /* Get job cards & userid  */
   /*---------------------------------------------------------------------*/
   /* C1SPACE contains the position of the first space.  If the value is  */
   /* in the range 4-11 then the jcl statement is assumed to contain a    */
   /* valid jobcard.  The first three characters of the jcl statement     */
   /* are assumed to be // and the first character of the job name.       */
   /*---------------------------------------------------------------------*/
   VALIDCHRS = 'ABCDEFGHIJKLMNOPQRSTUVWXYZA01234567890'
   C1LN = LENGTH(C1BJC1)                   /* Length of jobcard           */
   C1SPACE = INDEX(C1BJC1," ")             /* Find First space            */
   IF (C1SPACE > 3) & (C1SPACE < 12) THEN
      DO
         C1LASTCH = SUBSTR(C1BJC1,(C1SPACE - 1),1)
         C1UID    = SUBSTR(C1BJC1,3,(C1SPACE - 4))
         IF  (C1UID = ZUSER) THEN DO       /* Only increment if userid fnd*/
            C1CURCH = POS(C1LASTCH,VALIDCHRS) /* is it a valid chr?       */
            IF C1CURCH > 0  THEN DO        /* Then pick the next chr      */
               C1NEXTCH = SUBSTR(VALIDCHRS,(C1CURCH+1),1)
               C1BJC1 = OVERLAY(C1NEXTCH,C1BJC1,(C1SPACE - 1))
            END
         END
      END
   'VPUT (C1BJC1 C1BJC2 C1BJC3 C1BJC4 EEVINJCL) PROFILE' /* save Job info */
return

IOERROR:
  say "ENDIE430S: UNEXPECTD I/O ERROR IN READ ROUTINE"
  say "ENDIE430S: UNABLE TO READ EDITED SCL in '"ZTEMPF"' DDNAME:"ZTEMPN
  EXIT 12
