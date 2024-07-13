/* REXX - Routine to retrieve/use the saved rows for Difference Display

   Copyright (C) 2022 Broadcom. All rights reserved.

   THESE SAMPLE ROUTINES ARE DISTRIBUTED BY BROADCOM "AS IS".
   NO WARRANTY, EITHER EXPRESSED OR IMPLIED, IS MADE FOR THEM.
   BROADCOM CANNOT GUARANTEE THAT THE ROUTINES ARE
   ERROR FREE, OR THAT IF ERRORS ARE FOUND, THEY WILL BE CORRECTED.

*/
/* Common Preamble */
if ARG(1) == "DESCRIPTION" THEN
   RETURN "Retrieve and compare elements using SuperC (options set by USRCMDDO)"
/* End of Preamble */

/*
  MAIN LINE LOGIC
       First Check we have valid parms to work with... SCL to retrieve them
  */
  parse arg DiffNumD
  Call Retrieve_Profile_Vars
  /*
       we have two distinct elements to compare, build SCL to retrieve them
  */
  Call Build_Retrieve_SCL
  /*
        Call the API to perform the actions
  */
  Call Execute_API_Action
  /*
        Invoke SuperC to compare and browse the report
  */
  Call Compare_Files
  /*
        Reset the status
  */
  If DiffNumD == 1 then do
    do DiffNum = 1 to 2
       CALL NDUSRSDR "'"DIFFNUM"' '"NEWSTATUS"'"
    end
  end
  else If DiffNumD == 3 then do
    do DiffNum = 3 to 4
       CALL NDUSRSDR "'"DIFFNUM"' '"NEWSTATUS"'"
    end
  end
  /*
        Finally (re)set the message for the current row
  */
  USERMSG = NewStatus
  ADDRESS ISPEXEC "VPUT (USERMSG) SHARED"

exit 0


/****************************************************************************/

Retrieve_Profile_Vars:

If DiffNumD == 1 then do
  do DiffNum = 1 to 2
    DIFFVARS = 'DIFFSET'DIFFNUM,
               'DIFFTBL'DIFFNUM,
               'DIFFROW'DIFFNUM,
               'DIFFELE'DIFFNUM,
               'DIFFENV'DIFFNUM,
               'DIFFSTG'DIFFNUM,
               'DIFFSYS'DIFFNUM,
               'DIFFSBS'DIFFNUM,
               'DIFFTYP'DIFFNUM,
               'DIFFVVL'DIFFNUM
    ADDRESS ISPEXEC "VGET ("DIFFVARS") PROFILE"
   /*  interpret "say 'Vars #' "DiffNum" ':' "DiffVars */
  end
end
else If DiffNumD == 3 then do
  do DiffNum = 3 to 4
    DIFFVARS = 'DIFFSET'DIFFNUM,
               'DIFFTBL'DIFFNUM,
               'DIFFROW'DIFFNUM,
               'DIFFELE'DIFFNUM,
               'DIFFENV'DIFFNUM,
               'DIFFSTG'DIFFNUM,
               'DIFFSYS'DIFFNUM,
               'DIFFSBS'DIFFNUM,
               'DIFFTYP'DIFFNUM,
               'DIFFVVL'DIFFNUM
    ADDRESS ISPEXEC "VGET ("DIFFVARS") SHARED"
  /*   interpret "say 'Vars #' "DiffNum" ':' "DiffVars */
  end
end
/*
  Check we have different elements to compare
*/
If DiffNumD == 1 then do
NT = DIFFENV1'/'DIFFSTG1'/'DIFFSYS1'/'DIFFSBS1'/'DIFFTYP1'/'DIFFELE1':'DIFFVVL1
OT = DIFFENV2'/'DIFFSTG2'/'DIFFSYS2'/'DIFFSBS2'/'DIFFTYP2'/'DIFFELE2':'DIFFVVL2
end
else If diffNumD == 3 then do
NT = DIFFENV3'/'DIFFSTG3'/'DIFFSYS3'/'DIFFSBS3'/'DIFFTYP3'/'DIFFELE3':'DIFFVVL3
OT = DIFFENV4'/'DIFFSTG4'/'DIFFSYS4'/'DIFFSBS4'/'DIFFTYP4'/'DIFFELE4':'DIFFVVL4
end
if NT = OT then
   do
     ADDRESS ISPEXEC "SETMSG MSG(NDUM017E)"
     Exit 4
   end

   RETURN;

/****************************************************************************/

Build_Retrieve_SCL:

  /* first check for any temp file preferences */
  ADDRESS ISPEXEC "VGET (LNDFTRFM LNDFTRCL) PROFILE"

  if LNDFTRFM == '1' then            /* record format */
     TEMPRECFM = 'F'
  else
     TEMPRECFM = 'V'

  if DATATYPE(LNDFTRCL,'W') = 0 then /* check for whole number */
     LNDFTRCL = 260
  else do
     if LNDFTRCL  < 80 ,             /* record length */
      | LNDFTRCL  > 4096 then
        LNDFTRCL = 260
  end

  ADDRESS ISPEXEC "VGET (ZAPPLID ZSCREEN ZUSER ZSYSID ZPREFIX)"
   ADDRESS TSO,
   "ALLOC F(NEWDD) LRECL("LNDFTRCL") BLKSIZE(0) SPACE(5,5) ",
    "DSORG(PS)",
     "RECFM("TEMPRECFM" B) TRACKS NEW UNCATALOG REUSE " ;

   "ALLOC F(OLDDD) LRECL("LNDFTRCL") BLKSIZE(0) SPACE(5,5) ",
    "DSORG(PS)",
     "RECFM("TEMPRECFM" B) TRACKS NEW UNCATALOG REUSE " ;

   sa=SAVESCL(RESET)                    /* reset our cache of SCL lines */
   /* retrieve for first element */
   sa=SAVESCL(" RETRIEVE ELEMENT ")
   If DiffNumD == 1 then do
     sa=SAVESCL("'"DiffEle1"'")
     IF LENGTH(DiffVvl1) = 4 THEN,
        sa=SAVESCL(" VERSION" SUBSTR(DiffVvl1,1,2),
                 "LEVEL " SUBSTR(DiffVvl1,3,2));
     ELSE,
        sa=SAVESCL("* Current Version Level")
     sa=SAVESCL(" FROM ENVIRONMENT "DiffEnv1 " SYSTEM "DiffSys1)
     sa=SAVESCL(" SUBSYSTEM "DiffSbs1 " TYPE "Difftyp1 " STAGE" DiffStg1)
     sa=SAVESCL(" TO DDNAME 'NEWDD' OPTIONS NO SIGNOUT NOSEARCH REPLACE.")
     /* retrieve for second element */
     sa=SAVESCL(" RETRIEVE ELEMENT ")
     sa=SAVESCL("'"DiffEle2"'")
     IF LENGTH(DiffVvl2) = 4 THEN,
        sa=SAVESCL(" VERSION" SUBSTR(DiffVvl2,1,2),
                 "LEVEL " SUBSTR(DiffVvl2,3,2));
     ELSE,
        sa=SAVESCL("* Current Version Level")
     sa=SAVESCL(" FROM ENVIRONMENT "DiffEnv2 " SYSTEM "DiffSys2)
     sa=SAVESCL(" SUBSYSTEM "DiffSbs2 " TYPE "Difftyp2 " STAGE" DiffStg2)
     sa=SAVESCL(" TO DDNAME 'OLDDD' OPTIONS NO SIGNOUT NOSEARCH REPLACE.")
     /* Append an EOF flag */
     sa=SAVESCL(" EOF. ")
   end
   If DiffNumD == 3 then do
     sa=SAVESCL("'"DiffEle3"'")
     IF LENGTH(DiffVvl3) = 4 THEN,
        sa=SAVESCL(" VERSION" SUBSTR(DiffVvl3,1,2),
                 "LEVEL " SUBSTR(DiffVvl3,3,2));
     ELSE,
        sa=SAVESCL("* Current Version Level")
     sa=SAVESCL(" FROM ENVIRONMENT "DiffEnv3 " SYSTEM "DiffSys3)
     sa=SAVESCL(" SUBSYSTEM "DiffSbs3 " TYPE "Difftyp3 " STAGE" DiffStg3)
     sa=SAVESCL(" TO DDNAME 'NEWDD' OPTIONS NO SIGNOUT NOSEARCH REPLACE.")
     /* retrieve for second element */
     sa=SAVESCL(" RETRIEVE ELEMENT ")
     sa=SAVESCL("'"DiffEle4"'")
     IF LENGTH(DiffVvl4) = 4 THEN,
        sa=SAVESCL(" VERSION" SUBSTR(DiffVvl4,1,2),
                 "LEVEL " SUBSTR(DiffVvl4,3,2));
     ELSE,
        sa=SAVESCL("* Current Version Level")
     sa=SAVESCL(" FROM ENVIRONMENT "DiffEnv4 " SYSTEM "DiffSys4)
     sa=SAVESCL(" SUBSYSTEM "DiffSbs4 " TYPE "Difftyp4 " STAGE" DiffStg4)
     sa=SAVESCL(" TO DDNAME 'OLDDD' OPTIONS NO SIGNOUT NOSEARCH REPLACE.")
     /* Append an EOF flag */
     sa=SAVESCL(" EOF. ")
     end
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
   ADDRESS LINKMVS 'ndusascl MY_PARMS'
   Temp_RC = RC ;
   If Temp_RC > 4  THEN,
      Do
      ADDRESS ISPEXEC "LMINIT DATAID(DDID) DDNAME(C1MSGS1)"
      ADDRESS ISPEXEC "VIEW DATAID(&DDID)"
      ADDRESS ISPEXEC "LMFREE DATAID(&DDID)"
      End;

   RETURN;


/****************************************************************************/

Compare_Files:
/*  This routine performs a SuperC compare of two previously
    retrieved files (OLDDD and NEWDD) and allows the user to browse the output
    If the files are determined to be equal, RC:9 is returned, even though the
    RC from SuperC was 0, a normal compare (differences found) returns 1 and in
    all other cases, the SuperC return code is returned as is
*/
SUPCRC = 0                                          /* initialise search RC  */
  ADDRESS ISPEXEC "VGET (ZAPPLID ZSCREEN ZUSER ZSYSID ZPREFIX)"
  /* Decide on Temporary Dataset name prefix...                         */
  if zSYSID = SPECIAL then                 /* is this a special system? */
     /* insert system specific logic if required here                   */
     SUPRCOUT = left(zUSER,3)||'.'||zUser'.'ZSYSID||'.SOUT'||ZSCREEN
  else /* otherwise we use some sensible defautls                       */
    if zPrefix \= '',                      /* is Prefix set?  and NOT.. */
     & zPrefix \= zUSER then               /* the same as userid?       */
       SUPRCOUT = zPrefix ||'.'|| zUser'.'ZSYSID || '.SOUT'||ZSCREEN
    else                                   /* otherwise use user name   */
       SUPRCOUT = zUser ||'.'|| ZSYSID || '.SOUT' || ZSCREEN
  CALL MSG "ON"
  CALL OUTTRAP "out."
  "DELETE '"SUPRCOUT"'"                             /* delete any old output */
  CALL OUTTRAP "OFF"
ADDRESS TSO
  "ALLOC DD(OUTDD) SP(1,10) TR NEW RELEASE  REU ",
    "LRECL(202) BLKSIZE(27876) RECFM(F,B) DA('"SUPRCOUT"')",
    "DSORG(PS)"
  "ALLOC DD(SYSIN) SP(1,0) BLOCK(8000) NEW RELEASE",
     "LRECL(80) BLKSIZE(8000) RECFM(F,B) REU NEW UNCATALOG",
    "DSORG(PS)"

ADDRESS MVS
/* The max length for parameters is 72, but the max allowed             */
/*  for a title is just 53 so we may need to trim the titles            */
if diffnumd == 1 then do
Queue "*"
Queue "****+****|****+****|****+****|****+****|****+****|****+****|****+****|"
Queue "*"
Queue "* The Following Endevor elements were compared"
Queue "*"
Queue "* New: Environment..:"Left(DiffEnv1,15)"Old: Environment..:"DiffEnv2
Queue "*      Stage........:"Left(DiffStg1,15)"     Stage........:"DiffStg2
Queue "*      System.......:"Left(DiffSys1,15)"     System.......:"DiffSys2
Queue "*      SubSystem....:"Left(DiffSbs1,15)"     SubSystem....:"DiffSbs2
if length(DiffEle1) < 16 & length(DiffEle2) < 16 then
Queue "*      Element......:"Left(DiffEle1,15)"     Element......:"DiffEle2
Queue "*      Type.........:"Left(DiffTyp1,15)"     Type.........:"DiffTyp2
Queue "*      VVLL.........:"Left(DiffVvl1,15)"     VVLL.........:"DiffVvl2
Queue "*"
if length(DiffEle1) > 15 | length(DiffEle2) > 15 then do
Queue "* New  Element......:"Left(DiffEle1,42)
do i = 43 to length(diffEle1) by 42
Queue "*                   :"Substr(DiffEle1,i,42)
end
Queue "*"
Queue "* Old  Element......:"Left(DiffEle2,42)
do i = 43 to length(diffEle2) by 42
Queue "*                   :"Substr(DiffEle2,i,42)
end
Queue "*"
end
end
if diffnumd == 3 then do
Queue "*"
Queue "****+****|****+****|****+****|****+****|****+****|****+****|****+****|"
Queue "*"
Queue "* The Following Endevor elements were compared"
Queue "*"
Queue "* New: Environment..:"Left(DiffEnv3,15)"Old: Environment..:"DiffEnv4
Queue "*      Stage........:"Left(DiffStg3,15)"     Stage........:"DiffStg4
Queue "*      System.......:"Left(DiffSys3,15)"     System.......:"DiffSys4
Queue "*      SubSystem....:"Left(DiffSbs3,15)"     SubSystem....:"DiffSbs4
if length(DiffEle3) < 16 & length(DiffEle4) < 16 then
Queue "*      Element......:"Left(DiffEle3,15)"     Element......:"DiffEle4
Queue "*      Type.........:"Left(DiffTyp3,15)"     Type.........:"DiffTyp4
Queue "*      VVLL.........:"Left(DiffVvl3,15)"     VVLL.........:"DiffVvl4
Queue "*"
if length(DiffEle3) > 15 | length(DiffEle4) > 15 then do
Queue "* New  Element......:"Left(DiffEle3,42)
do i = 43 to length(diffEle3) by 42
Queue "*                   :"Substr(DiffEle3,i,42)
end
Queue "*"
Queue "* Old  Element......:"Left(DiffEle4,42)
do i = 43 to length(diffEle4) by 42
Queue "*                   :"Substr(DiffEle4,i,42)
end
Queue "*"
end
end
Queue "*"
Queue "****+****|****+****|****+****|****+****|****+****|****+****|****+****|"
Queue "*"
Queue "NTITLE '"Elipsize(NT)"'"
Queue "OTITLE '"Elipsize(OT)"'"
Queue "*"
/* if there are any process options append them to the request file */
ADDRESS ISPEXEC "VGET (LNDIFS1 LNDIFS2 LNDIFS3 LNDIFS4 LNDIFS5) PROFILE"
if LNDIFS1 /= '' then Queue LNDIFS1
if LNDIFS2 /= '' then Queue LNDIFS2
if LNDIFS3 /= '' then Queue LNDIFS3
if LNDIFS4 /= '' then Queue LNDIFS4
if LNDIFS5 /= '' then Queue LNDIFS5
Queue ""
"EXECIO * DISKW SYSIN (FINIS"

ADDRESS ISPEXEC "VGET (LNDIFPRM ) PROFILE"
if LNDIFPRM = '' then         /* if options never set, set a default */
   LNDIFPRM = 'LINECMP,LONGL,WIDE,NOPRTCC'

ADDRESS ISPEXEC "SELECT PGM(ISRSUPC)" ,
  "PARM("LNDIFPRM")"
  /*  LONGL|DELTAL|CHNGL LINECMP|WORDCMP|BYTECMP (NO)SEQ COBOL ASCII NOSUMS */
  SUPCRC = RC
ADDRESS TSO "FREE DD(OUTDD)"
If SUPCRC = 0 then do
   SUPCRC = 9
   NewStatus = '*NoDiff'
   ADDRESS ISPEXEC "SETMSG MSG(NDUM017W)" /* no differences found */
   end
else do
   ADDRESS ISPEXEC "SETMSG MSG(NDUM017I)" /* differences found */
   ADDRESS ISPEXEC "VIEW DATASET('"SUPRCOUT"') PROFILE(SUPERC) MACRO(NDUSRMD)"
   NewStatus = '*DiffFound'
   end
/*
ADDRESS TSO
  "FREE DD(OUTDD) "
  "FREE DD(NEWDD) "
  "FREE DD(OLDDD) "
  "FREE DD(SYSIN) "
*/

return SUPCRC

/****************************************************************************/

Elipsize: procedure /* This procedure returns a 'truncated' version of
                       the passed Endevor location where the long name
                       is considered the least important part if if the
                       total string is gt than 53 characters the name
                       will be shortened and elipses added preserving
                       the last 5 characters (typically :vvll)
                    */
if length(arg(1)) <= 53 then return arg(1)
else return left(arg(1),45) || '...' || right(arg(1),5)


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
