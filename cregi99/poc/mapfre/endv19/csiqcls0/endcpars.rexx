/* Rexx  *************************************************************/
/*  ENDCPARS                                                         */
/*   Function :                                                      */
/*     -Read the member input or the edit session input from         */
/*      CCOLS command.                                               */
/*     -CHECKNAMES                                                   */
/*         -Check all f row: to be in proper format                  */
/*         -Check that nothing is missing/overwritten                */
/*     -PROCLINE                                                     */
/*         -Prepare main string of element selection table           */
/*          consistiong of Variable names                            */
/*                         Header one                                */
/*                         Header two                                */
/*                         Zvars                                     */
/*     -ENDVWIDE                                                     */
/*             -Process the main string and separate it to "chunks"  */
/*              depending on the screen width.                       */
/*             -Prefix the fixed columns to each chunks              */
/*             -Vput all the variables to ISPF so panel ENDIE250 can */
/*              use them.                                            */
/*                                                                   */
/*                                                                   */
/*   Return :  CSDQXH1,CSDQXH2,CSDQXVR,CSDQXM1 +                     */
/*             CSDQ0H1 --- up to CSDQ25H1 are VPUTED                 */
/*                                                                   */
/*             member is either saved / not depending on the caller  */
/*                                                                   */
/*             XRC return code is returned to caller.                */
/*                                                                   */
/*   Called by : 1) ENDCIMAC macro upon END command in ISPF session  */
/*               2) by ENDCPAR3 that is called by ENDCIMAC un case   */
/*                  of SAVE command.                                 */
/*                                                                   */
/*   Note : The dificult variable string is the model line. It looks */
/* like -                                                            */
/*          _Z &Z  + ¬Z  &Z+¬Z       +.....                          */
/*          _  Ele Stage S Something                                 */
/* Field is defined by the character + which means centered value    */
/*                                   & attribute character           */
/*                                   Z the value.                    */
/*                                                                   */
/* &Z+     This means start of column on char &                      */
/* S       Z is in the one space between the columns and next colum  */
/*         will be centered.                                         */
/*                                                                   */
/* + ¬Z  &Z       This is the case of cenetered value of stage       */
/* Stage Element                                                     */
/*   1   LOADMOD                                                     */
/*                                                                   */
/*                                                                  */
/* *******************************************************************/
 debug = 0             /* debug 0 = no debuging 1 = debug this pgm */
 parse arg Csave       /* Csave defines if user used END or SAVE cmd */
 Option = Csave        /* In special case we can be called with SCROLL */
ADDRESS ISPEXEC "VGET (ZSCREENW) PROFILE"    /* GET THE SCREEN WIDTH   */
  tgtWidth = ZSCREENW                      /* set width from screen  */

ADDRESS ISPEXEC "VGET (MYPANEL NOEDIT RESETARG VARPFX TABLEID NOSAVE) SHARED"
 Option = translate(Option) /* If so, we want to scroll only */

 If option = 'SCROLL' then do /* means we have been called from ENDIE300*/
  If NoSave /= 'YES' then do  /* regular scroll call  */
    call SCROLL               /* we scrolled */
    return 0                  /* good */
  end
  else do                     /* First call from ENDIE300, we don't need*/
    NoSave = 'NO'             /* to scroll = just end */
    ADDRESS ISPEXEC "VPUT (NOSAVE) SHARED"
    return 0
  end
 end

address ISREDIT
"MACRO (PARMS)"
"ISREDIT (SAVE) = USER_STATE"
/********************************************************************/
/* Check the heading row - must be in pristine state                */
/********************************************************************/
  bot = ' Bottom of the List '             /* set last line value    */
HDIN ='*'||'00'x||'Heading'||'000000000000000000000000000000'x||'Atr'||'00'x
HDIN =HDIN||'Max'||'00'x||'Dft'||'00'x||'Len'||'00'x||'Divider'
"SEEK C'"HDIN"' 1 FIRST"                  /*find lower case */
if RC > 0 then do                         /* if not then error */
   HDIN=translate(HDIN)
  bot = translate(bot)                     /* set last l cap     */
   "SEEK C'"HDIN"' 1 FIRST"
  if RC > 0 then signal MissHeading         /* if not then error */
end
"(LP CP)=CURSOR"                          /* get the cursor after headin*/
"(DATALINE)=LINE" LP
DATALINE = translate(DATALINE)            /*Capitalize */
HeadS  = POS('HEADING',DATALINE)-2        /*Get offset to special char  */
HeadO  = POS('HEADING',DATALINE)          /*Get offset of Heading field */
AttrO  = POS('ATR',DATALINE)+1            /*Get offset of Attribute Fld */
MaxLO  = POS('MAX',DATALINE)              /*Get offset of max Len field */
DftLO  = POS('DFT',DATALINE)              /*Get offset of Dft Len field */
LenlO  = POS('LEN',DATALINE)              /*Get offset of Len field */
DivdO  = POS('DIVIDER',DATALINE)          /*Get offset of Divider field */
/*Heading               Atr Max Dft  Len  Divider  */
HeadSe = HeadS + 1
HeadE  = AttrO - 1                        /* then calculate ending points */
AttrE  = AttrO + 1
MaxLE  = DftLO - 1
DftLE  = LenlO - 1
LENLE  = LenlO + 3
ParseEm:
J = 0                                     /* initialise line counter */
Ptr.  = ''                                /* and initialise pointers */
'ISREDIT (LASTL) = LINENUM .ZLAST'


/********************************************************************/
/* Set defaults for this parsing                                    */
/********************************************************************/
DEFAULTNAME = 'ELEMENT + MESSAGE TYPE NS ENVIRON STAGE SYSTEM ',
'SUBSYS VVLL CURDATE/TIME PROCGRP GENDATE/TIME PRRC NDRC USERID CCID ',
'SIGNOUT COMMENT LOCKPKG STNUM MOVDATE/TIME USRDATA STNAME'
MAPPING= 'ELEMENT      EEVETKEL 255 010',
          '+            EEVEIND  001 001',
          'MESSAGE      EEVETDMS 010 010',
          'TYPE         EEVETKTY 008 008',
          'NS           EEVETNS  001 002',
          'ENVIRON      EEVETKEN 008 008',
          'STAGE        EEVETKSI 001 003',
          'SYSTEM       EEVETKSY 008 008',
          'SUBSYS       EEVETKSB 008 008',
          'VVLL         EEVETDVL 004 004',
          'PROCGRP      EEVETPGR 008 008',
          'USERID       EEVETUID 008 007',
          'CCID         EEVETCCI 012 012',
          'PRRC         EEVETPRC 004 004',
          'NDRC         EEVETNRC 004 004',
          'SIGNOUT      EEVETSO  008 007',
          'CURDATE/TIME EEVELDTE 013 007',
          'GENDATE/TIME EEVEGDTE 013 007',
          'MOVDATE/TIME EEVEMDTE 013 007',
          'LOCKPKG      EECPKG   016 016',
          'COMMENT      EEVLCOM  040 028',
          'STNUM        EEVETKST 001 003',
          'USRDATA      EEVEUSRD 080 010',
          'STNAME       EEVETKSN 008 008'
Rowcnt = Words(Mapping) / 4  /* Row count for defined stuff */
/********************************************************************/
/* And call Check routine to find errors                            */
/********************************************************************/
CALL CHECKNAMES
  if debug = 1 then do
    say 'XRC from CHECKNAMES  =' xrc
  end
if xrc = 36 then signal headerChanged
if xrc = 16 then signal twofixClines
if xrc = 20 then signal duplicaterow
if xrc = 24 then signal Linedeleted


/********************************************************************/
/* We are good to go parsing.                                       */
/********************************************************************/
Separate = 0                             /* initiate control values */
seplinefound = 0                     /* this controls fixed portion */
MeSmart = 'Y'
ADDRESS ISPEXEC "VPUT (MESMART)"
DO i = 1 to LASTL                        /*start on 1. to last line */
  "(DATALINE)=LINE" I                    /* fetch the line          */
/*DATALINE = translate(DATALINE)            Capitalize */
  If left(DATALINE,1) == '*' THEN do      /* skip comment lines     */
    Rowcnt = Rowcnt - 1
    ITERATE
  end
  If left(DATALINE,1) == '!' THEN do      /* skip separator line    */
   if POS('*****FIXED COLUMNS ABO',DATALINE)>0 then do
    seplinefound = 1                     /* say separator found     */
    ITERATE
   end
  end
  J = J + 1                               /* increment index */

  PARSE VAR DATALINE =(HeadO) Head.J     =(HeadE), /*parse the variables  */
                     =(AttrO) Attr.J     =(AttrE), /* from the header loc */
                     =(LenlO) Len.J      =(LENLE),
                     =(DivdO) Divd.J

  if Len.J = 0 then do
    Rowcnt = Rowcnt - 1
    J = J - 1
    ITERATE
  end
/********************************************************************/
/* Place default values to MAX and DEF lenght field. Populate       */
/* CTLICSDQ fields also before saving.                              */
/********************************************************************/

 wrk=translate(LEFT(HEAD.J,POS('00'x,HEAD.J)-1))   /* strip the head of X */
 MaxL.J = SUBWORD(MAPPING,WORDPOS(wrk,MAPPING)+2,1)/* characters and make */
 DftL.J = SUBWORD(MAPPING,WORDPOS(wrk,MAPPING)+3,1)/*max and dflt default */

  "ISREDIT CURSOR =" I MaxLO             /* set cursor to max len pos     */
  "C P'==='" MaxL.J                      /* rewrite whatever with  default*/
  "ISREDIT CURSOR =" I DftLO             /* set cursor to dflt len pos    */
  "C P'==='" DftL.J                      /* rewrite whatever with  default*/

  call PROCLINE J                    /* call routine to process this line */
  if debug = 1 then do
    say 'result from PROCLINE =' result
  end
  If result = 12 then signal BadChar
  If result = 24 then signal BadAttr
END

If seplinefound = 0 then signal SepNotFound  /* If we didn't find sep line*/

  Head.0 = J                             /* store STEM count to .0 */
  Head.J = LEFT(Head.J,length(Head.J)-1) /* fix last space */
  Divd.J = LEFT(Divd.J,length(Divd.J)-1) /* fix last space */
/********************************************************************/
/* Call ENDVWIDE to build the strings for screen "chunks"           */
/********************************************************************/
signal ENDVWIDE
xrc = 0
signal fini

/********************************************************************/
/* End of main code .. error messages and FINIsh routine.           */
/********************************************************************/

BadChar:
address ISPEXEC "SETMSG MSG(ENDE240E)"
xrc = 12
signal fini

BadAttr:
address ISPEXEC "SETMSG MSG(ENDE241E)"
xrc = 12
signal fini

SepNotFound:
address ISPEXEC "SETMSG MSG(ENDE242E)"
xrc = 12
signal fini

MissHeading:
address ISPEXEC "SETMSG MSG(ENDE243E)"
xrc = 12
signal fini

Linedeleted:
address ISPEXEC "SETMSG MSG(ENDE244E)"
xrc = 12
signal fini

HeaderChanged:
address ISPEXEC "SETMSG MSG(ENDE245E)"
xrc = 12
signal fini

twofixClines:
address ISPEXEC "SETMSG MSG(ENDE246E)"
xrc = 12
signal fini

duplicaterow:
address ISPEXEC "SETMSG MSG(ENDE247E)"
xrc = 20
signal fini

/********************************************************************/
/* This routine is last in the program. It will result error message*/
/* and decides to save / not to save the member.                    */
/* Also it will resolve the + indicator of long element name.       */
/********************************************************************/
fini:
/********************************************************************/
/* Open table and depending on element value length update it with  */
/* + indicator. Do this only on panel ENDIE250 or if we are comming */
/* here from ENDIE300 asm pgm with NOEDIT. (table dont exist otherw)*/
/********************************************************************/
if XRC = 0 then do
  if TABLEID /= '' then do
   if RC = 8 then INDECOL = 0
   ADDRESS ISPEXEC "TBSTATS" TABLEID "STATUS2(TABSTAT)"
    if TABSTAT = 4 Then do
     address ISPEXEC "TBTOP "TABLEID""    /* point ot top of ESL table */
     Do forever
      address ISPEXEC "TBSKIP "TABLEID""  /* Skip to next row          */
      if rc > 0 then leave                /* we are done               */
      EEVEIND =' '                                    /* set default */
      if LENGTH(EEVETKEL) > INDECOL then EEVEIND ='+' /* If ELM name len */
      address ISPEXEC "TBPUT "TABLEID""  /* is > then column change IND */
     end
    end
  end
end

/********************************************************************/
/* Check if we are about to save .. if not just end                 */
/********************************************************************/

  ADDRESS ISPEXEC "VGET (MYPROF MEM) SHARED"
if NoSave = 'YES' then do     /* we have not been in edit session */
  if XRC > 0 then do
    NoSave = 'NO'
    address ISPEXEC "SETMSG MSG(ENDE251E)"
    ADDRESS ISPEXEC "VPUT (NOSAVE) SHARED"
  end
  zedsmsg = ''                /* so don't save the member and just end */
  zedlmsg = ''
 "ISREDIT USER_STATE = (SAVE)"
 "BUILTIN END"
  return(xrc)
end

/********************************************************************/
/* we are saving .. try it, and let user know we did by msg         */
/********************************************************************/

if XRC = 0 then do
 "BUILTIN SAVE" /* since user pressed End to get here, make sure we can save*/
 if RC > 4 then do /* save error */
   xrc = RC       /* severe error */
  address ISPEXEC "SETMSG MSG(ENDE253E)"
   return(xrc)
 end
 address ISPEXEC "VGET (AUTOENTR) SHARED" /* get state of AutoEnter Flag */
 if AUTOENTR = 'YES' THEN
   address ISPEXEC "CONTROL NONDISPL ENTER"  /*simulate ENTER for user */
 "ISREDIT USER_STATE = (SAVE)"
 if CSAVE = 'YES' then do
   address ISPEXEC "SETMSG MSG(ENDE243I)"
  xrc = 8
  return(xrc)
 end
 else do
   address ISPEXEC "SETMSG MSG(ENDE243I)"
 end
end

/********************************************************************/
/* If non 0 RC we will endup here                                   */
/********************************************************************/
"BUILTIN END" /* since user pressed End to get here, issue the end now */
return(xrc)
/********************************************************************/
/*   ******  *   *  ****     *   *     *      *   *   *             */
/*   *       **  *  *   *    ** **    * *     *   **  *             */
/*   ****    * * *  *   *    * * *   *   *    *   * * *             */
/*   *       *  **  *   *    *   *  *******   *   *  **             */
/*   ******  *   *  ****     *   * *       *  *   *   *             */
/********************************************************************/

PROCLINE:
/**********************************************************************/
/*  Main parser routine that will parse rows from the edit seession   */
/*  and create CSDQ main variable set. #0                             */
/**********************************************************************/
  parse arg ROW
  ThisSeq = Row
  If Ptr.ThisSeq == '' then Ptr.ThisSeq = ROW

  Head.ROW = strip(Head.ROW,,'00'x)                /* trim trailing spaces */
  If Head.ROW == '' then                           /* was it all spaces?   */
    Head.ROW = left('00'x,DftL.ROW)                /* use null padded      */

/**********************************************************************/
/* Lets start with error handeling for each row first.                */
/* - check length field for numberic value                            */
/**********************************************************************/
  if DATATYPE(Len.ROW) /= 'NUM' & Len.ROW /= '   ' then do
    BNWH = Head.row
    BNW = Len.Row
    return 12
  end

  if VERIFY(Len.ROW,'0123456789 ') /= 0 then do
     BNW = Len.ROW
     BNWH = Head.ROW
     return 12
  end

/**********************************************************************/
/* If lenght is st more than a screen width is, it make no sense at   */
/* all, SO I will set it to screen -3 (select line)  kloto0x          */
/**********************************************************************/
  if Len.ROW > (tgtWidth-4) then do
  Len.ROW = tgtWidth-4
  end

/**********************************************************************/
/* - check 0 len and use default len if so.                           */
/**********************************************************************/

  If Len.ROW  == '' | Len.ROW  = '' Then do  /* If there is no override?*/
    Len.ROW = DftL.ROW                             /* use the default width */
    If DftL.ROW == '' | DftL.ROW = '' Then do
      BNW = 'Dflt'
      BNWH = Head.ROW
      return 12
    end
  end

/**********************************************************************/
/* - check attribute field, If it uses allowed characters             */
/**********************************************************************/

  if VERIFY(Attr.ROW,'£¦¬¢@!][') /= 0 then do
     BAT = Attr.ROW
     BATH = Head.ROW
     return 24
  end

/**********************************************************************/
/* - If there is no devider row then use ----- as default.            */
/**********************************************************************/

  If Divd.ROW = '' Then Divd.ROW = Copies('-',Len.ROW)
  Divd.ROW =  TRANSLATE(Divd.ROW,'-',' ') /* fill with bogus chars */

/**********************************************************************/
/* - If len is 0 then just get rid of the column.                     */
/**********************************************************************/
  if Len.ROW = 0 then do /* if column is hidden - reset it's vars */
      Head.ROW = ''
      Divd.ROW = ''
      Modl.ROW = ''
      Vars.ROW = ''
  end
  else do /* we are golden - create the stem result of this row */
 Vars.ROW = word(mapping,(WORDPOS(translate(Head.ROW),Mapping)+1)) || ' '
      Head.ROW = Left(Head.ROW,Len.ROW) || ' '
      Divd.ROW = Left(Divd.ROW,Len.ROW,'-') || ' '
  END
  If Vars.ROW = 'EEVETKEL' then do  /* Vput the length of element column */
      INDECOL = Len.ROW    /* for + indicator resolution later  */
      address ISPEXEC "VPUT (INDECOL) SHARED"
  end

  If seplinefound = 0 & Len.ROW /= 0 then    /* Set Fixed by sep line */
    Separate = Separate + 1           /* we dont count hidden columns */

if debug = 1 then do                              /* debug only */
 say '--------------------------------------------------------------------'
 say '-- Separate=' Separate '--------------------------------------------'
 say right(ROW,2,'0') '|'||Head.ROW ||'|'
 say right(ROW,2,'0') '|'||Divd.ROW ||'|'
 say right(ROW,2,'0') '|'||Modl.ROW ||'|'
 say right(ROW,2,'0') '|'||Vars.ROW ||'|'
  /**/
end

return 0

/**********************************************************************/
/* SCROLL - Rather special routine. It controls the scroll "possition"*/
/*   called via special argument from BC1PFLOW.                       */
/**********************************************************************/

SCROLL:
ADDRESS ISPEXEC "VGET (PX VARWKCMD TBLCNT VNTMORE1 MESMART) SHARED"
   if DATATYPE(PX) /= 'NUM' then PX = 0 /* Safety measure */
    VARWKCMD = TRANSLATE(VARWKCMD) /* if we are refreshing, return */
    if MESMART = 'N' then do       /* Case when no scrolling allowed, */
      PX = 0                       /* fixed part over the screen      */
      VNTMORE1 = '          '
      signal scrolldone
    end
     if TBLCNT = 0  then do        /* Same case , if we have only 1   */
      PX = 0                       /* chunk */
     VNTMORE1 = '       '
     signal scrolldone
    end
    If WORD(VARWKCMD,1) = 'RIGHT' then PX = PX + 1   /* right scroll */
    If WORD(VARWKCMD,1) = 'LEFT'  then PX = PX - 1    /* left  scroll */
    if Px < 0      then Px = TBLCNT          /* wrap around back */
    if Px > TBLCNT then Px = 0               /* wrap around forward */

    if Px = 0 then do                        /* Now set the more text */
      VNTMORE1 = '   More==>'
      signal scrolldone
    end
      if Px = TBLCNT then do
      VNTMORE1 = '<==More'
      signal scrolldone
    end
    VNTMORE1 = '<==More==>'

scrolldone:
INTERPRET 'ADDRESS ISPEXEC "VGET (CSDQ'PX'H1 CSDQ'PX'H2 ' , /* Broadcast*/
           ' CSDQ'PX'M1 CSDQ'PX'VR) SHARED" '

       CSDQXH1 = VALUE('CSDQ'||PX||'H1')
       CSDQXH2 = VALUE('CSDQ'||PX||'H2')
       CSDQXM1 = VALUE('CSDQ'||PX||'M1')||'+' /* supress value over col */
       CSDQXVR = VALUE('CSDQ'||PX||'VR')

       slen = length(VALUE('CSDQ'||PX||'M1')) /* if end of screen + will cut*/
       if slen = tgtWidth-1 then CSDQXM1 = VALUE('CSDQ'||PX||'M1') /* char */
/*     say CSDQXH1'F'
       say CSDQXH2'F'
       say CSDQXM1'F' */
ADDRESS ISPEXEC "VPUT (PX CSDQXH1 CSDQXH2 CSDQXM1 CSDQXVR VNTMORE1)",
                " SHARED"
  NoSave ='YES'
  XRC = 0
  return
  End

/************************************************************************/
/* This routine will do main sanity check.                              */
/* check for :                                                          */
/*       1) If the header was changed                                   */
/*       2) If the separator is missing / duplicated                    */
/*       3) If the line was deleted                                     */
/*                                                                      */
/* xrc = 12 header Changed                                              */
/* xrc = 16  two fix lines                                              */
/* xrc = 20 duplicate row                                               */
/* xrc = 24 Line deleted                                                */
/*                                                                      */
/************************************************************************/
checknames:
xrc    = 0                                /*initiate */
Colc   = 0                                /*initiate */
FIXEDC = 0                                /*initiate */
DUPCHECK = ''                             /*initiate */
DO k = 1 to LASTL                         /* loop over all lines        */
  "(DATALINE)=LINE" k
  DATALINE = translate(DATALINE)            /*Capitalize */

  PARSE VAR DATALINE =(HeadO) Headtst.K     =(HeadE)
  Headtst.K = strip(Headtst.k,,'00'x)           /* strip unchangable chars    */
  if WORDPOS(Headtst.K,DEFAULTNAME) > 0 then Colc = colc +1
  If left(DATALINE,1) == '*' THEN ITERATE /* skip comment lines         */
  if WORDPOS(Headtst.K,DEFAULTNAME) > 0 then do      /* if found check next*/
   If WORDPOS(Headtst.K,DUPCHECK) > 0 then do /* check for duplicates */
    xrc = 20                               /* Dup found ! error    */
    Whead = Headtst.K
    leave
   end
   DUPCHECK = DUPCHECK || Headtst.K || ' '    /* Add word to dup string */
   iterate
   end
  else do
    if POS('*****FIXED COLUMNS ABO',Headtst.K)>0 then do
     PARSE VAR DATALINE Excla +1
       if POS('!',Excla) = 0 then do
          xrc = 12
          Wrng = Headtst.K
       end
     if FIXEDC = 1 then  xrc = 16         /* if second time = DUp = ERR */
     FIXEDC = 1                           /* it is a first found = ok   */
     iterate
    end
     Wrng = Headtst.K                         /* header changed indicate so */
     xrc =  36                             /*headerChanged*/
     leave
  end
  k = k + 1                               /* increment index */
  Colc = colc +1                          /* update count for deleted line*/
end

if colc < Rowcnt & xrc = 0 then xrc = 24    /* less lines ? = deleted = err */
return

ENDVWIDE:                        /*ENDVWIDE name inherited from ECOLS*/
  if debug = 1 then do                     /* DEBUG */
  say  'Vars:' ZSCREENW'varpfx ='varpfx ' Separate =' SL /* DEBUG */
  end                                      /* DEBUG */

  if datatype(Separate) = CHAR then Separate = 4 /*Default to 4 columns fixed */

/* We do have all variables ready in the correct sequence now. lets start */
/* building first string. Save the fixed part defined by separator in the */
/* process. */
  MeSmart = 'Y'
  CTRL1= 0
  LCFIXM1 = '_Z '
  LCFIXVR = 'EEVETSEL '
  LCFIXH1 = '00'x || '  '
  LCFIXH2 = '-- '
  Fixedok = 0
  prfixed = 0
  cols = 0
  DUMY=value(varpfx||'0M1','')     /* clear to be sure */
  If Separate = 0 then Fixedok = 1 /*If spearator is the first line */
do TBLCNT = 0 to 24 by 1 while CTRL1 = 0  /* main loop over 25 allowed chunks */
      CTRL2 = 0
  do while CTRL2 = 0   /* sub loop up to 24 columns */
       cols = cols + 1
       if cols > head.0 then do  /* end of data ? */
         CTRL2 = 1
         CTRL1 = 1
         if prfixed = 1 then nop                      /* Specoal case  */
         else do                                  /*1 chunk only and all     */
          DUMY=value(varpfx||TBLCNT||'M1',LCFIXM1)/*datais fixed .. we need  */
          DUMY=value(varpfx||TBLCNT||'VR',LCFIXVR)/*to populate here extra.  */
          DUMY=value(varpfx||TBLCNT||'H1',LCFIXH1)/*                         */
          DUMY=value(varpfx||TBLCNT||'H2',LCFIXH2)/*                         */
          prfixed = 1
         end
         iterate
       end
       If Len.cols = 0 then do
          iterate
       end
       if MaxL.cols < Len.cols then do              /* Do we need to center? */
          Modl.cols = '+'|| ,
          center(left(Attr.cols||'Z',(MaxL.cols+1)),Len.cols,' ')
       end
       else Modl.cols = Attr.cols||'Z'||copies(' ',(Len.cols - 1))

       if Fixedok = 0 then do          /* this will build fixed portion once */

         if length(LCFIXM1)=tgtwidth-1 | length(LCFIXM1)= tgtwidth-2 then do
           MeSmart = 'N'         /* In the case fixed is more then screen */
           ADDRESS ISPEXEC "VPUT (MESMART)"
           Fixedok = 1
           iterate
         end

         if length(LCFIXM1) + length(Modl.cols) > tgtwidth-1 then do
           Modl.cols = Attr.cols||'Z'||copies(' ',(Len.cols - 1)) /* decenter */
         end
         LCFIXM1 = LCFIXM1||Modl.cols
         LCFIXVR = LCFIXVR||Vars.cols
         LCFIXH1 = LCFIXH1||Head.cols
         LCFIXH2 = LCFIXH2||Divd.cols

         if length(LCFIXM1) >= tgtwidth-1 then do
            LCFIXM1=LEFT(LCFIXM1,tgtwidth-1)
            LCFIXH1=LEFT(LCFIXH1,tgtwidth-1)
            LCFIXH2=LEFT(LCFIXH2,tgtwidth-1)
           MeSmart = 'N'         /* In the case fixed is more then screen */
           ADDRESS ISPEXEC "VPUT (MESMART)"
           Fixedok = 1
           iterate
         end

         if length(LCFIXM1)=tgtwidth-1 | length(LCFIXM1)= tgtwidth-2 then do
           MeSmart = 'N'         /* In the case fixed is more then screen */
           ADDRESS ISPEXEC "VPUT (MESMART)"
           Fixedok = 1
           iterate
         end

         if cols = Separate then do
           Fixedok = 1 /* check if we are done with the fixed */
           iterate
         end
       end
       else do
         if prfixed = 0 then do
           DUMY=value(varpfx||TBLCNT||'M1',LCFIXM1)  /*assign fixed part */
           DUMY=value(varpfx||TBLCNT||'VR',LCFIXVR)
           DUMY=value(varpfx||TBLCNT||'H1',LCFIXH1)
           DUMY=value(varpfx||TBLCNT||'H2',LCFIXH2)
           prfixed = 1
         end
         if length(value(varpfx||TBLCNT||'M1'))+length(Head.cols)<tgtwidth-2
         then do

         DUMY=value(varpfx||TBLCNT||'M1',value(varpfx||TBLCNT||'M1')||Modl.cols)
         DUMY=value(varpfx||TBLCNT||'VR',value(varpfx||TBLCNT||'VR')||Vars.cols)
         DUMY=value(varpfx||TBLCNT||'H1',value(varpfx||TBLCNT||'H1')||Head.cols)
         DUMY=value(varpfx||TBLCNT||'H2',value(varpfx||TBLCNT||'H2')||Divd.cols)

         end
         else do
          /*      No Go Zone                                                  */
          /* @z______|________    last column will not fit the screen.        */
          /*       @z|________    we need to decide what to do with it        */
          /*        @|Z_______    rule of thum here is to display it partialy */
          /*         |@Z______    and redisplay on scroll.                    */
          /* +@z_____|________    This will not be done if whole the rest is  */
          /*      +@z|________    fixed. then dont supress the redisplay.     */
          /*         |                                                        */
          /*       +@|Z______     Secondly if the value is centered and column*/
          /*        +|@Z_____     is severed, them dont center it.            */
          /* +__@z___|________                                                */
          /* +_____@z|________                                                */
          /* +_______|___@z____________                                       */

          if MeSmart = 'N' then do
           CTRL1 = 1
           CTRL2 = 1
           cols = cols - 1
           if tgtwidth - 2 - length(value(varpfx||TBLCNT||'M1')) < 1 then do
            iterate
           end
          end

          Modl.cols = Attr.cols||'Z'||copies(' ',(Len.cols - 1)) /* decenter */
          Olen = length(value(varpfx||TBLCNT||'M1'))
          Slen = tgtwidth-length(value(varpfx||TBLCNT||'M1'))-1
          if length(Modl.cols)<= slen then slen = length(Modl.cols)-1

          wrkm1 = LEFT(Modl.cols,Slen)
          if slen = 1 then wrkm1 = LEFT(Modl.cols,2)
          wrkvr = Vars.cols
          wrkh1 = LEFT(Head.cols,Slen)
          wrkh2 = LEFT(Divd.cols,Slen)

          DMY=value(varpfx||TBLCNT||'M1',value(varpfx||TBLCNT||'M1')||wrkm1)
          DMY=value(varpfx||TBLCNT||'VR',value(varpfx||TBLCNT||'VR')||wrkvr)
          DMY=value(varpfx||TBLCNT||'H1',value(varpfx||TBLCNT||'H1')||wrkh1)
          DMY=value(varpfx||TBLCNT||'H2',value(varpfx||TBLCNT||'H2')||wrkh2)
          /* Supress logic   > is result                                redis*/
          /* ElemF staF envF colum column CO|LUMN_____                    Y  */
          /*>ElemF staF envF COLUMN_____ col|umn                             */
          /*                                |                                */
          /* ElemF staF envF COLUMN_________|_________                    N  */
          /*>       <===More                |                                */
          /*                                |                                */
          /* and combination of both previous cases. ..                      */
          /* | Fix len     |                                                 */
          /* |                 res len      | slen   |                       */
          /*                              | head len |                       */

            if OLEN <= length(LCFIXM1)|Olen+length(Modl.cols)<=tgtwidth then do
             cols = cols + 1 /* supress redisplay  of column if necessary */
            if cols > head.0 then do  /* end of data ? */
             CTRL1=1
            end
           end
         cols = cols - 1 /* redispley by default */
         CTRL2=1
         end /* else redisplay control */
       end /* Else - last column resolution */
  end /* Sub loop */
  prfixed = 0
end /*Chunk loop */
 TBLCNT = TBLCNT - 1 /*Fix last do while counter pop */

do v = 0 to TBLCNT by 1 /* X is updated on a loop before end so -1 it is */
 INTERPRET ' ADDRESS ISPEXEC "VPUT   ('VARPFX''V'H1) SHARED" '
 INTERPRET ' ADDRESS ISPEXEC "VPUT   ('VARPFX''V'H2) SHARED" '
 INTERPRET ' ADDRESS ISPEXEC "VPUT   ('VARPFX''V'VR) SHARED" '
 INTERPRET ' ADDRESS ISPEXEC "VPUT   ('VARPFX''V'M1) SHARED" '
  if debug = 1 then do
   Say 'Iteration=' V
   say 'F'value(varpfx||v||'H1')'F'
   say 'F'value(varpfx||v||'H2')'F'
   say 'F'value(varpfx||v||'M1')'F'
   say 'F'value(varpfx||v||'VR')'F'
  end
end

address ISPEXEC "VPUT (TBLCNT) SHARED" /*TBLCNT = number of screens  */
address ISPEXEC "VGET (PX) SHARED" /*TBLCNT = number of screens  */
/* GET PX to see if first call / we are on 1. display, if so we have */
/* nobody to initiate the values and we have to do it here  **********/
if PX = '' then do
  PX = 0
  address ISPEXEC "VPUT (PX) SHARED"
end
If PX = 0 then do
   CSDQXH1 =value(varpfx||'0H1')                /* first display vals*/
   CSDQXH2 =value(varpfx||'0H2')
   CSDQXM1 =value(varpfx||'0M1')||'+'
   CSDQXVR =value(varpfx||'0VR')
   CSDQXZM = center(bot,tgtWidth,"-")
    slen = length(VALUE('CSDQ'||PX||'M1')) /* if end of screen + will cut*/
    if slen = tgtWidth-1 then CSDQXM1 = VALUE(varpfx||PX||'M1') /* char */
   VNTMORE1 = '   More==>'
    if TBLCNT = 0 then  VNTMORE1 = '   '
address ISPEXEC "VPUT (CSDQXH1 CSDQXH2 CSDQXVR CSDQXM1 CSDQXZM VNTMORE1 " ,
                ") SHARED"
end
zedsmsg=''
zedlmsg=''
xrc = 0
signal fini
return

