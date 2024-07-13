/*----------------------------REXX----------------------------------*/
/*    Analyses output from the IOBKRSTR step in the Walker          */
/*    tools add to Endevor procesing.                               */
/*------------------------------------------------------------------*/
trace 0
arg type name unloddsn mem
name = strip(name,t,',')
say 'WAIOBKCK: Type       -' type
say 'WAIOBKCK: Name       -' name
say 'WAIOBKCK: Unload dsn -' unloddsn
say 'WAIOBKCK: Member     -' mem
say

/**  read the iobkrstr report file SYS012 **/
'execio * diskr report (stem j. finis'
if rc > 0 then do
  say 'WAIOBKCK: Error reading file REPORT'
  exit 12
end
/**  write the iobkrstr report file SYS012 **/
'execio * diskw sys012 (stem j. finis'
if rc > 0 then do
  say 'WAIOBKCK: Error writing file SYS012'
  exit 12
end
/*------------------------------------------------------------------*/
/* check iobkrstr report for unsucessfull data backup               */
/*------------------------------------------------------------------*/
select
    when type = 'COB' then filename = '**S3200'
    when type = 'DOC' then filename = '**DGS***'
    when type = 'DOP' then filename = '**S2000'
    when type = 'ERR' then filename = '**SSERR'
    when type = 'FID' then filename = 'RGSDATAR'
    when type = 'GMT' then filename = '**GMT***'
    when type = 'MVT' then filename = 'SCC134'
    when type = 'NAM' then filename = '*IGSNAME'
    when type = 'RPT' then filename = '*RGSHDR*'
    when type = 'SCR' then filename = '*SCRHDR*'
    when type = 'SVC' then filename = '**S3000'
    when type = 'TGS' then filename = '*TGSHDR'
    when type = 'TID' then filename = '**S1200'
    when type = 'VMS' then filename = '**VMSR**'
otherwise
  say ' +------------------------------------------------+'
  say '    Type' type 'not defined to REXX exec WAIOBKCK'
  say '    Element' name ' not added'
  say ' +------------------------------------------------+'
  exit 0
end

do i=1 to j.0
  flen = length(filename)
  if substr(j.i,104,flen) = filename &,
     substr(j.i,115,16) = 'FILE HEADER ONLY' then do
    say ' +----------------------------------------+'
    say '    No data backed up from file' filename
    say '   ' type name 'does not exist'
    say '    Element' name 'not added'
    say ' +----------------------------------------+'
    call delmem
    exit 4
  end
end

exit
/*------------------------------------------------------------------*/
/* Delete member from unload library to force add failure           */
/*------------------------------------------------------------------*/
DELMEM:
 queue 'delete' mem
 queue 'end'
 queue ''
 address tso "pdsman" "'"unloddsn"'"
return
