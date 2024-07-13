/* REXX */
/**********************************************************************/
/*                                                                    */
/* Create the synonym member of a cobol copybook                      */
/*                                                                    */
/* This is a copy of an RBS utility - TTYY.DESIGN.FORUM.EXEC(SYMNAMES)*/
/* It has been amended to be used against CA CSV output copybooks.    */
/*                                                                    */
/* Input variables have been hard coded.                              */
/*                                                                    */
/* Aymeric Duffay                                                     */
/* Jul 2004                                                           */
/**********************************************************************/
trace n
parse arg dsnlist opt SHOW rem vrbl xl pgrs
/* In forgeround DSNLIST should be dsn(member)                       */
if dsnlist = '' then
  dsnlist = 'TTEV.WILLIET.COPYBOOK(ECHALELM)'
opt     = 0     /* Produce symbol table, symname, & rexx variables   */
show    = 'N'   /* Do not display progress                           */
rem     = 'N'   /* Remove variable prefix                            */
vrbl    = 'FB'  /* Data file RECFM                                   */
offset  = 0     /* Record start offset                               */

environ = sysvar("sysenv") /* Foreground or Batch? */
ucase   = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ'
lcase   = 'abcdefghijklmnopqrstuvwxyz'

if show/='N' then do
   xl=0
   /*****************************/
   parse source ' 'com' 'script' 'crap
   call log script
   /*****************************/
end
else do
   if xl='' then xl=0
end
if vrbl='VB' then do
   offset=4
   if show/='N' then
   say 'All fields are offset 4 bytes to cater for variable length.'
end
sch='-\|/'
ADDRESS ISPEXEC "VGET ZUSER"
address ispexec "VGET Zprefix"
/* retrieve copybook */
copybook = strip(dsnlist)
if opt='' then opt='0'
if dsnlist='' then do
   say "Enter a copybook's path and name:"
   pull dsnlist
   copybook = strip(dsnlist)
end

if environ = 'FORE' then do
  if sysdsn("'"copybook"'") /= 'OK' then
    do  /* environment not set up correctly */
    say '>> Cant read ' copybook 'file.'
    exit (8)
  end
  "ALLOC FI(COPYBOOK) DA('"copybook"') SHR"
  if rc /= 0 then
    do  /* Problem getting parameters */
    say "Parameter file '"copybook"' can't be opened ("rc")"
    exit (8)
  end
  "EXECIO * DISKR COPYBOOK (FINIS STEM Prm."
  "FREE F(COPYBOOK)"
end /* environ = 'FORE' */
else
  "EXECIO * DISKR COPYBOOK (FINIS STEM Prm."

if prm.0=0 then do
   omsg='No Data'
   address ispexec "SETMSG MSG(AYMO002)"
   exit
end

parse var copybook dsn'('member')'
if member='' then do
   lp=lastpos('.',dsn)
   member=substr(dsn,lp+1,length(dsn)-lp)
end
pad=' '
statpos=1
field.=''
num=0
frstrn=1
out1r.=''
out1r=0
out2r.=''
out2r=0
out3r.=''
out3r=0
out4r.='' /* rexx */
out4r=0
erreason=0
copyerr=0
thisstat=0
total=0
IF show/='N' then
say "Processing copybook "member"..."
rensym='S'substr(member,2)
renrex='R'substr(member,2)

   if opt='1' | opt='0' then
   if sysdsn("'"zprefix"."ZUSER".COPYMAP("member")'") = 'OK' then do
      rc=purgefile("'"zprefix"."ZUSER".COPYMAP("member")'")
   end
   if opt='2' | opt='0' then
   if sysdsn("'"zprefix"."ZUSER".COPYSYN("rensym")'") = 'OK' then do
      rc=purgefile("'"zprefix"."ZUSER".COPYSYN("rensym")'")
   end
   if opt='3' | opt='0' then
   if sysdsn("'"zprefix"."ZUSER".BYTEMAP("member")'") = 'OK' then do
      rc=purgefile("'"zprefix"."ZUSER".BYTEMAP("member")'")
   end
   num=0
   total=0
   copybooklen=scancopy(thisstat,0,1+offset,0,0,0,0,'')+offset
if copyerr then do
   copybooklen=-1
      if erreason=0001 then
         erreastr="Copybook "member|| ,
                  " contains nested COPY statements. Process aborted."
      else
         erreastr="Copybook "member|| ,
                  "layout non-standard. Process aborted."
   IF show/='N' then do
      say erreastr
   end
   adcoperr=erreason
   ADDRESS ISPEXEC "VPUT (ADcoperr) profile"
   exit
end

IF show/='N' then
say "Copybook "member" is "COPYBOOKLEN" bytes long."
if opt='0' | opt='1' then do
  if environ = 'FORE' then do
   IF show/='N' then
   say "CopyMAP  "member" is being created in "zprefix"."ZUSER".COPYMAP..."
   if sysdsn("'"zprefix"."ZUSER".COPYMAP'") /= 'OK' then do
      "ALLOC FI(out1) DA('"zprefix"."ZUSER".COPYMAP')" ,
      "NEW CATALOG UNIT(SYSDA) SPACE(15 15) TRACKS NOHOLD" ,
      "RECFM(F B) LRECL(80) DSORG(PO) DIR(50) DSNTYPE(LIBRARY)"
      "free f(out1)"
   end
  end
   out1r.1=center('Field name',35)center('Picture',10) ,
                 "  Comp Lvl Start   End Bytes"
   out1r.2=' '
   out1r.3=left(member,35,' '),
            "                    ",
            right('1',5,' '),
            right(copybooklen,5,' '),
            right(copybooklen,5,' ')
END
if opt='0' | opt='2' then do
   IF show/='N' then
   say "CopySYN  "rensym" is being created in "zprefix"."ZUSER".COPYSYN..."
  if environ = 'FORE' then do
   if sysdsn("'"zprefix"."ZUSER".COPYSYN'") /= 'OK' then do
      "ALLOC FI(out2) DA('"zprefix"."ZUSER".COPYSYN')" ,
      "NEW CATALOG UNIT(SYSDA) SPACE(15 15) TRACKS NOHOLD" ,
      "RECFM(F B) LRECL(80) DSORG(PO) DIR(50) DSNTYPE(LIBRARY)"
      "FREE F(OUT2)"
   end
   if sysdsn("'"zprefix"."ZUSER".COPYREXX'") /= 'OK' then do
      "ALLOC FI(out2) DA('"zprefix"."ZUSER".COPYREXX')" ,
      "NEW CATALOG UNIT(SYSDA) SPACE(15 15) TRACKS NOHOLD" ,
      "RECFM(F B) LRECL(80) DSORG(PO) DIR(50) DSNTYPE(LIBRARY)"
      "FREE F(OUT2)"
   end
  end
   k=1
   out2r.=''
   prefix=''
   loop='Y'
end
if /*opt='0' |*/ opt='3' then do
   IF show/='N' then
   say "ByteMap  "member" is being created in "zprefix"."ZUSER".BYTEMAP..."
  if environ = 'FORE' then do
   if sysdsn("'"zprefix"."ZUSER".BYTEMAP'") /= 'OK' then do
      "ALLOC FI(out3) DA('"zprefix"."ZUSER".BYTEMAP')" ,
      "NEW CATALOG UNIT(SYSDA) SPACE(15 50) CYL NOHOLD" ,
      "RECFM(F B) LRECL(2000) DSORG(PO) DIR(50) DSNTYPE(LIBRARY)"
      "FREE F(OUT3)"
   end
  end
   out3r.=''
   if rem/='D' then do
   k=1
   prefix=''
   end
   loop='Y'
end



if opt='0' | opt='2' | opt='3' then do
   if rem='Y' then do
      i=1
      do while pos(field.i.name,'FILLER')=1
         i=i+1
      end
      prefix=field.i.name
      do while i<=total & loop='Y'
         if xl>0 then
         if i//20=0 | i=1 then do
            xl=xl+1
            if xl=length(sch)+1 then xl=1
            wheel=substr(sch,xl ,1)
            pc=center('Copybook 'member,21,' ')right(wheel,3)
            pc=center('  'right(' ',3)'  ø',21)right(wheel,3)
            if pgrs/='' then
            pc=center('  'right(pgrs,3)'% ø',21)right(wheel,3)
            lines='Please wait... '||pc
            address ispexec "CONTROL DISPLAY LOCK"
            ADDRESS ISPEXEC "DISPLAY MSG(AYMO004)"
         end
         upper field.i.name field.i.name
         if pos(field.i.name,'FILLER')=0 &,
            field.i.pic/='GROUP' then do
            k=compare(field.i.name,prefix)-1
            if k=1 then loop='N'
            else do
               if k>0 then do
                  if k<length(prefix) then prefix=substr(field.i.name,1,k)
               end
               else do
                  if k=0 then prefix=''
               end
            end
         end
         i=i+1
      end
      if loop='Y' then k=k+1
                  else k=k-1
      if length(prefix)>1 & k>0 then do
         prefix=substr(prefix,1,length(prefix)-1)
         upper prefix prefix
         IF show/='N' then do
            say "Prefix '"prefix"' was removed."
         end
      end
      else do
         prefix=''
         k=0
      end
   end
   else k=0
end

first=1
do i=1 to total
   if xl>0 then
   if i//20=0 | i=1 then do
      xl=xl+1
      if xl=length(sch)+1 then xl=1
      wheel=substr(sch,xl ,1)
      pc=center('Copybook 'member,21,' ')right(wheel,3)
      pc=center('  'right(' ',3)'  @',21)right(wheel,3)
      if pgrs/='' then
      pc=center('  'right(pgrs,3)'% @',21)right(wheel,3)
      lines='Please wait... '||pc
      address ispexec "CONTROL DISPLAY LOCK"
      ADDRESS ISPEXEC "DISPLAY MSG(AYMO004)"
   end
   if opt='0' | opt='1' then do
     q=i+3
   /*outr.k=left(insert('',field.i.name,,field.i.lev),35,'_'), */
     out1r.q=RIGHT(field.i.name||field.i.cell,35,pad),
            left(field.i.pic,10,pad),
            left(field.i.type,6,pad),
            right(field.i.lev,2,'0'),
            right(field.i.start,5,pad),
            right(field.i.start+field.i.len-1,5,pad),
            right(field.i.len,5,pad)
   end
   if first then do
      if opt='0' | opt='2' then do
            w=1
            if left(member,1) = '-' then
              member = substr(member,2)
            out2r.w=member',1,'copybooklen',CH'
            rexxvar = translate(member,'_','-')
            rexxvar = translate(rexxvar,lcase,ucase)'.i'
            out4r.w = left(rexxvar,23) ,
                      '= strip(substr(line.i,1,'copybooklen'))'
      end
   end
   if opt='0' | opt='2' then do
         if pos(field.i.name,'FILLER')=0 then do
         /* field.i.pic/='GROUP' then do    */
            if rem='Y' & pos(prefix,field.i.name)=1 then do
               newname=substr(field.i.name,k,length(field.i.name)-k+1)
            end
            else newname=field.i.name
            /*determine field type*/
            if field.i.type='' then do
               if pos('X',field.i.pic)/=0 | ,
                  field.i.pic='GROUP' then dtatype='CH'
               else do
                  if pos('S',field.i.pic)=0 then dtatype='ZD'
                  else do
                     dtatype='CTO'
                     IF show/='N' then
                     say "Warning: Signed decimal. "||,
                         "Compiler default CTO assumed."
                  end
               end
            end
            else do
               if field.i.type='PACKED'   then dtatype='PD'
               if field.i.type='BINARY'   then do
                  dtatype='BI'
                  if pos('V',field.i.pic)/=0|,
                     pos('.',field.i.pic)/=0|,
                     pos('S',field.i.pic)/=0 then dtatype='FI'
               end
               if pos('E',field.i.pic)/=0|,
                     field.i.type='SHORT'|,
                     field.i.type='LONG' then dtatype='FL'
            end
            occurstr=''
            if field.i.cell/='' then do
            occurstr=strip(translate(field.i.cell,' ','('))
            occurstr=strip(translate(occurstr,' ',')'))
            occurstr=translate(occurstr,'-',',')
            occurstr='-'occurstr
            end
            if left(newname,1) = '-' then
              newname = substr(newname,2)
            if newname ^= '' then do
              w=w+1
              out2r.w=newname||occurstr','field.i.start','field.i.len','dtatype
              rexxvar = translate(newname||occurstr,'_','-')
              rexxvar = translate(rexxvar,lcase,ucase)'.i'
              out4r.w = left(rexxvar,24) ,
                   '= strip(substr(line.i,'field.i.start','field.i.len'))'
            end
         end
      /*if rem='Y' then rem='D'*/
   end
   if first then do
      if /*opt='0' |*/ opt='3' then do
         w=0
         bytemap.=''
      end
   end
   if /*opt='0' |*/ opt='3' then do
      newname=field.i.name
      if pos(field.i.name,'FILLER')=0 & rem/='N' & ,
         pos(prefix,newname)=1 then do
         newname=substr(field.i.name,k,length(field.i.name)-k+1)
      end
      if field.i.pic='GROUP' then newname='{G}'newname
                             else newname='{v}'newname
      occurstr=field.i.cell
      maxlen=0
      do byte=field.i.start to field.i.start+field.i.len-1
         maxlen=max(length(bytemap.byte),maxlen)
      end
      j=0
      do byte=field.i.start to field.i.start+field.i.len-1
         j=j+1
         bytemap.byte=left(bytemap.byte,maxlen+1)||newname||occurstr
         bytemap.byte=bytemap.byte||'£'|| ,
         right(j,length(field.i.len),0)'/'|| ,
         field.i.len'¨'
      end
   end
   first=0
end

if /*opt='0' |*/ opt='3' then do
   do i=1 to copybooklen
      if xl>0 then
      if i//20=0 | i=1 then do
         xl=xl+1
         if xl=length(sch)+1 then xl=1
         wheel=substr(sch,xl ,1)
         pc=center('Copybook 'member,21,' ')right(wheel,3)
         pc=center('  'right(' ',3)'  @',21)right(wheel,3)
         if pgrs/='' then
         pc=center('  'right(pgrs,3)'% @',21)right(wheel,3)
         lines='Please wait... '||pc
         address ispexec "CONTROL DISPLAY LOCK"
         ADDRESS ISPEXEC "DISPLAY MSG(AYMO004)"
      end

      if strip(bytemap.i)='' then bytemap.i='Not allocated'
      out3r.i=right(i,5,'0')' 'strip(bytemap.i)
   end
end

if environ = 'FORE' then do
  if opt='0' | opt='1' then do
     "ALLOC FI(out1) DA('"zprefix"."ZUSER".copyMAP("member")') SHR"
     "EXECIO * DISKW OUT1 (FINIS STEM out1r."
     "FREE F(OUT1)"
  end
  if opt='0' | opt='2' then do
  "ALLOC FI(out2) DA('"zprefix"."ZUSER".copysyn("rensym")') SHR"
  "EXECIO * DISKW OUT2 (FINIS STEM out2r."
  "FREE F(OUT2)"
  IF show/='N' then
  say 'Note that the symname member has been renamed from',
      member' to 'rensym'.'
  "ALLOC FI(out4) DA('"zprefix"."ZUSER".copyrexx("renrex")') SHR"
  "EXECIO * DISKW OUT4 (FINIS STEM out4r."
  "FREE F(OUT4)"
  end
  if /*opt='0' |*/ opt='3' then do
  "ALLOC FI(out3) DA('"zprefix"."ZUSER".bytemap("member")') SHR"
  "EXECIO * DISKW OUT3 (FINIS STEM out3r."
  "FREE F(OUT3)"
  end
end /* environ = 'FORE' */
else do
  if opt='0' | opt='1' then
    "EXECIO * DISKW MAP     (FINIS STEM out1r."
  if opt='0' | opt='2' then
    "EXECIO * DISKW SYMNAME (FINIS STEM out2r."
    "EXECIO * DISKW REXXVAR (FINIS STEM out4r."
  if /*opt='0' |*/ opt='3' then
    "EXECIO * DISKW BYTEMAP (FINIS STEM out3r."
end /* else */

exit

scancopy: procedure expose field. prm. nextstat total oldstat xl sch member ,
            pgrs copyerr frstrn offset erreason
   arg thisstat,num,statpos,bin,grpcp1,grpcp2,grpcp3,grpocc
   statement=getstatement(thisstat)
   copylen=0
   exitloop='N'
   if statement/='' then do
      if pos(substr(word(statement,1),1,1),'0123456789')>0 & ,
         pos(substr(word(statement,1),2,1),'0123456789')>0 & ,
         length(word(statement,1))=2 then level=word(statement,1)+0
                                     else do
                                          exitloop='E'
                                          level=-1
                                     end
   end
   thislevel=level
   do while exitloop='N'
      if xl>0 then
      if num//100=0 | frstrn then do
         frstrn=0
         xl=xl+1
         if xl=length(sch)+1 then xl=1
         wheel=substr(sch,xl ,1)
         pc=center('Copybook 'member,21,' ')right(wheel,3)
         pc=center('  'right(' ',3)'  ©',21)right(wheel,3)
         if pgrs/='' then
         pc=center('  'right(pgrs,3)'% ©',21)right(wheel,3)
    /*   pc=center('  'right(pgrs,3)'% © 'member,21)right(wheel,3)
     */  lines='Please wait... '||pc
         address ispexec "CONTROL DISPLAY LOCK"
         ADDRESS ISPEXEC "DISPLAY MSG(AYMO004)"
      end
      redef =wordpos('REDEFINES',statement,2)+0
      if redef>0 then do
         redefw=space(translate(word(statement,redef+1),' ','.'))
         def=findfield(num+1,redefw)+0
         statpos=field.def.start+0
         origlen=field.def.len+0
      end

      occurs=wordpos('OCCURS',statement,2)+0
      if occurs>0 then do
         occursTo=wordpos(' TO ',statement,occurs)+0
         occurs=strip(translate(word(statement,occurs+1),' ','.'))
         if occursto>0 then do
            occursto=strip(translate(word(statement,occursto+1),' ','.'))
         end
         else do
            occursto=occurs
            occurs=1
         end
      end
      else do
         occurs=1
         occursto=1
      end
      nbocc=occursto-occurs+1
      do j=occurs to occursto
         num=num+1
         total=total+1
         field.num.lev=level
         field.num.name=space(translate(word(statement,2),' ','.'))
         if grpocc/=''|nbocc>1 then do
            field.num.cell="("grpocc
            if grpocc/=''&nbocc>1 then field.num.cell=field.num.cell","
            if nbocc>1 then
               field.num.cell=field.num.cell||right(j,length(occursto),0)
            field.num.cell=field.num.cell")"
         end
         field.num.start=statpos
         field.num.len=0
         field.num.type=''
         picture=wordpos(' PICTURE ',statement,2)
         if picture=0 then   picture=wordpos(' PIC ',statement,2)
         comp1=pos(' COMP-1',statement,2)+grpcp1
         comp2=pos(' COMP-2',statement,2)+grpcp2
         comp3=pos(' COMP-3',statement,2)+grpcp3
         comp=pos(' COMP-4',statement,2)+bin+pos(' BINARY',statement,2)
         if comp=0 & comp1=0 & comp2=0 & comp3=0 then
            comp=pos(' COMP',statement,2)+bin
         if comp>0 then field.num.type='BINARY'
         if comp1>0 then field.num.type='SHORT'
         if comp2>0 then field.num.type='LONG'
         if comp3>0 then field.num.type='PACKED'
         readnext='N'
         if picture>0 then do
            picdef=word(statement,picture+1)
            if substr(picdef,length(picdef),1)='.' then
                      picdef=substr(picdef,1,length(picdef)-1)
            field.num.pic=picdef
            piclen=calclen(picdef)
            if comp/=0 then do
               piclen=((piclen%5)+1)*2
               if piclen>4 then piclen=8
            end
            if comp1/=0 then piclen=4
            if comp2/=0 then piclen=8
            if comp3/=0 then piclen=piclen%2+1
            field.num.len=piclen
            if occursto=j then readnext='Y'
         end
         else do
         /*group level is comp-3?*/
           field.num.pic='GROUP'
           group=nextstat
           par=grpocc
           if nbocc>1 then do
              if par/='' then par=par","
              par=par||right(j,length(occursto),0)
           end
           piclen=scancopy(nextstat,num,statpos,comp,comp1,comp2,comp3,par)
           if occursto>j then nextstat=group
           field.num.len=piclen
           comp=bin
           comp1=grpcp1
           comp2=grpcp2
           comp3=grpcp3
         end /*picture*/

         if redef>0 & piclen<origlen then
       /*   statpos=statpos+origlen
         */ statpos=statpos+piclen
         else do
            if redef=0 then copylen=copylen+piclen
            statpos=statpos+field.num.len
         end
         num=total
      end /*occurs*/
      if picture=0 then do
         statement=oldstat
         if statement/='' then
            if pos(substr(word(statement,1),1,1),'0123456789')>0 & ,
               pos(substr(word(statement,1),2,1),'0123456789')>0 & ,
               length(word(statement,1))=2 then
                                          level=word(statement,1)+0
                                     else do
                                          exitloop='E'
                                          level=-1
                                     end
      end

   /* say "level="level"    thislevel="thislevel  */
      if readnext='Y' then do
         thisstat=nextstat
         if nextstat<=prm.0 then do
            statement=getstatement(nextstat)
            if statement/='' then do
            if pos(substr(word(statement,1),1,1),'0123456789')>0 & ,
               pos(substr(word(statement,1),2,1),'0123456789')>0 & ,
               length(word(statement,1))=2 then
                                          level=word(statement,1)+0
                                     else do
                                          exitloop='E'
                                          level=-1
                                     end
            end
         end
      end /*readnext*/
      if level>=thislevel & thisstat<=prm.0 & statement/='' then
         exitloop='N'
      else exitloop='Y'
   end /* while */
   oldstat=statement
   return copylen


calclen: procedure
   arg thispic
   piclength=0
   valpic=0
   thispic=translate(thispic,'','S')
   thispic=translate(thispic,'','V')
   thispic=space(thispic,0)
   pin=pos('(',thispic)
   if pin=0 then piclength=length(thispic)
   else do
      i=1
      do while pin/=0
         piclength=piclength+pin-i
         pout=pos(')',thispic,pin+1)
         valpic=substr(thispic,pin+1,pout-pin-1)
         piclength=piclength+valpic-1
         i=pout+1
         pin=pos('(',thispic,i)
      end
      if i<length(thispic) then piclength=piclength+length(thispic)-i+1
   end
   return piclength

findfield: procedure expose field.
   arg thisnum,findname
   do while field.thisnum.name/=findname&thisnum>1
      thisnum=thisnum-1
   end
   return thisnum

getstatement: procedure expose prm. nextstat copyerr erreason
   arg thisline
   stat=''
   do while stat='' & thisline<prm.0
      endstr=''
      do until endstr="." | thisline>=prm.0
         thisline=thisline+1
         currline=strip(substr(prm.thisline,7,66))
         if currline='' then currline=left('*',30,'*')
         currlen =length(currline)
         comment =substr(currline,1,1)
         if comment/='*' then do
            if currlen>0 then do
               if pos("'",currline)>0 then
               parse var currline beg"'"remquotes"'"fin
               else fin=currline
               endstr=''
               if length(fin)>0 then
               endstr=substr(fin,length(fin),1)
               stat=stat currline
            end
         end
      end
      if word(stat,1)='EXEC' then stat=''
      if word(stat,1)='88' then stat=''
      if pos(' COPY ',' 'translate(stat,' ','.'))>0 then do
         copyerr=1
         erreason=0001
         stat=''
      end
   end
   nextstat=thisline
   stat=space(stat)
   return stat

purgefile: procedure
 arg filename
   res=0
   filename=strip(filename,,"'")
   rc=listdsi("'"filename"'" "NORECALL")
   if rc=16 then do
   address tso "HDELETE '"filename"' PURGE WAIT"
   end
   else if sysdsn("'"filename"'") = 'OK' then do
       x=msg('Off')
       address tso "DELETE '"filename"'"
       if rc>0 then res=rc
       x=msg(x)
   end
   if res>0 then       address tso "CLRSCR"
   return res

