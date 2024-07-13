/* rexx */                                                              00000100
/*--------------------------------------------------------------------*/00000200
/*--------------------------------------------------------------------*/00000200
/*--------------------------------------------------------------------*/00000500
/*- What                                      Who           When     -*/00000600
/*--------------------------------------------------------------------*/00000700
/*- Created                                   Craig Rex     12/05/04 -*/00000800
/*--------------------------------------------------------------------*/00000900
 trace o
 x = msg(off)                                                           00001100
 zcmd = ''
 top:
 "ISPEXEC DISPLAY PANEL(EVGENER)"                                       00004000
 if rc = 0 then do
  select
   when zcmd = '1' then do
    call evgenbld
   end
   when zcmd = '2' then do
    call evgenmig syst
   end
   when zcmd = '3' then do
    call evgenprm acpt
   end
   when zcmd = '4' then do
    call evgenprm prod
   end
   otherwise nop
  end
  call top
 end
 else exit
