/*                  REXX                              */
/*  This rexx is used to create spreadsheet of        */
/*  duplicate elements for an endevor system          */
/*                                                    */
/*  Author - Gavin Smith Jan 05                       */
/*                                                    */
panelrc = 1

do while panelrc > 0
display:
 address ispexec
 'display panel(dups)'
 if rc = 08 | pfk = pf03 | pfk = pf04 then exit
 panelrc = rc
 if unit||syst||acpt||prod = 'NNNN' then do
      panelrc = 4
      zedsmsg = 'Error'
      zedlmsg = 'You must select at least one Environment'
      err = 'Error - you must select at least one Environment'
      address ispexec
      'setmsg msg(ISRZ001)'
 end
end

 address ispexec
 'vget (zuser)'
 'vget (zprefix)'
 c1sysuid = zuser
 c1pref = zprefix
 c1jb = substr(c1sysuid,1,4)
 say 'Summary spreadsheet for system 'c1sys' will be sent to 'c1email

 address ispexec 'ftopen temp'
 address ispexec 'ftincl ' dups
 address ispexec 'ftclose'
 address ispexec 'vget (ztempf) shared'
 address tso     "submit '"ztempf"'"
return

