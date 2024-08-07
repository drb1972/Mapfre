/* rexx - This routine is used to trim the model line variables to match the
          available screen width.  It is typically called by the 'entry' panel
          after setting the prefix for the variable names (VARPFX) and passes
          the necessary variables.
/* Copyright (C) 2022 Broadcom. All rights reserved.                 */

   Change Log:
    20Nov14 - Add support for per-screen bottom of data marker (ZTDMARK)

          */
/*
*REXX (ZSCREENW hvarxzm  ESRCHWRP varpfx
       hvarxH1  hvarxH2  hvarxM1  hvarxM2  hvarxVR  hvarxCL
       hvarxH1  hvarxH2  hvarxM1  hvarxM2  hvarxVR  hvarxCL (ENXVWIDE))
*/
  sa= 'Vars:' ZSCREENW'/'ZTDMARK'/'ESRCHWRP'/'varpfx
  if ESRCHWRP == 'DEBUG' then TRACE R /* activate trace from Dialog defaults */
  tgtWidth = ZSCREENW
  WrapOpt.0 = 'PRI BOTH'
  WrapOpt.1 = 'ALT BOTH'
/* main loop - for Primary and alternate screens */
do x = 0 to 1 by 1
  /* use Value to lookup the variables we need to change */
  hvarxh1 = value(varpfx||x||'H1')
  hvarxh2 = value(varpfx||x||'H2')
  hvarxm1 = value(varpfx||x||'M1')
  hvarxm2 = value(varpfx||x||'M2')
  hvarxvr = value(varpfx||x||'VR')
  hvarxcl = value(varpfx||x||'CL')
  hvarxzm = value(varpfx||x||'ZM')
  sa= x'VB4:' hvarxH1'/'hvarxH2'/'hvarxM1'/'hvarxM2'/'hvarxVR'/'hvarxCL
  /* process Screen values                                             */
  if wordpos(ESRCHWRP,WrapOpt.X) > 0 then do /* Has user enabled wrap?*/
    if tgtWidth >= length(hvarxH2) then   /* if no need to split */
      hvarxM2 = 'OMIT'                    /* set continuation to off */
    else do
      if substr(hvarxM1,(tgtWidth+1)) == 'Z' then /* split on between attr & Z*/
        tgtWidth = tgtWidth - 1           /* split a bit earlier */
      else
        if substr(hvarxM1,(tgtWidth+2)) == 'Z' then /* split on boundry */
          nop                             /* we can just split where we are */
        else                              /* otherwise find prev var end...*/
          tgtWidth = lastpos('Z',left(hvarxM1,tgtWidth)) - 2
      hvarxM2 = '+   '||Substr(hvarxM1,(tgtWidth+1),(ZSCREENW-5))
      hvarxM2 = '+   '||Substr(hvarxM1,(tgtWidth+1),(ZSCREENW-5))
      RestOfH = '-- -'||strip(Substr(hvarxH1,(tgtWidth+1)))
      RHandBt = Substr(hvarxH2,(length(RestOfH)+1))
      hvarxH2 = left(RestOfH||RhandBt,(ZSCREENW-5))
    end
  end
  else                                    /* User disabled Wrap...   */
    hvarxM2 = 'OMIT'                      /* set continuation to off */
  hvarxH1 = LEFT(hvarxH1,(tgtWidth - 1))  /* The header lines are displaced */
  hvarxH2 = LEFT(hvarxH2,(tgtWidth - 1))  /* so shorten them a little less */
  hvarxM1 = LEFT(hvarxM1,(tgtWidth - 0))  /* But model line should match */
  if right(hvarxM1,1) == ' ' | ,          /* If the last char is a space */
     right(hvarxM1,1) == 'Z' | ,          /* ...or a Z/z place holder */
     right(hvarxM1,1) == 'z' Then  NOP    /* that's OK , otherwise... */
  Else                                    /* we found some unexpected chr */
    hvarxM1 = LEFT(hvarxM1,(tgtWidth - 1))/* ...so trim it off */
  ZEDs = length(space(hvarxM1||hvarxM2, 0)) - ,    /* How many Zs are left? */
         length(space(translate(hvarxM1||hvarxM2, '  ', 'Zz'), 0))
  myline = (space(hvarxVR, 1,':'))        /* save the var list delim by : */
  do i = 1 by 1 while myline <> ''        /* Loop to save each word */
      parse var myline w.i ':' myline     /* grab each word and store it */
  end
  w.0 = i - 1                             /* Save word count (-1)     */
  hvarxVR = ""                            /* Reset and build the new VarLine */
  do i = 1 to ZEDs                        /* for each var required */
      hvarxVR = hvarxVR || w.i || ' '     /* append it to the list */
  end
  myline = (space(hvarxCL, 1,':'))        /* now scan the clear var list */
  do i = 1 by 1 while myline <> ''        /* Loop to save each word */
      parse var myline c.i ':' myline
  end
  c.0 = i - 1                             /* Save word count (-1)     */
  hvarxCL = ""                            /* Now rebuild the clear list */
  do i = 1 to c.0                         /* for each var found    */
      if pos(c.i, hvarxVR) > 0 then       /* if it's a valid variable */
         hvarxCL = hvarxCL || c.i || ' '  /* append it to the list */
  end
  /* Set the ZTDMARK to match the max width of the Pri Panael      */
  if wordpos(varpfx,'ENWL ENLS') > 0 then /* if Screen supports long marks */
    hvarxZM = center(' Bottom of the List ', ,
      (min(160,max((length(strip(hvarxH1))),(length(strip(hvarxH2)))))),"-")
  else             /* otherwise, we're limited by the size of the VDEFINE */
    hvarxZM = center(' Bottom of the List ', ,
      (min(133,max((length(strip(hvarxH1))),(length(strip(hvarxH2)))))),"-")
  /* Update the values for the for the panel that called us */
  newhvar = value(varpfx||x||'H1',hvarxh1)
  newhvar = value(varpfx||x||'H2',hvarxh2)
  newhvar = value(varpfx||x||'M1',hvarxm1)
  newhvar = value(varpfx||x||'M2',hvarxm2)
  newhvar = value(varpfx||x||'VR',hvarxvr)
  newhvar = value(varpfx||x||'CL',hvarxcl)
  newhvar = value(varpfx||x||'ZM',hvarxzm)
  sa= x'Aft:' hvarxH1'/'hvarxH2'/'hvarxM1'/'hvarxM2'/'hvarxVR'/'hvarxCL
  sa= 'Zeds:' zeds 'Words:' words(hvarxvr)
end /* main loop */
