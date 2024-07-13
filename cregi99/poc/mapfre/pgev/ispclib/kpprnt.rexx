/* This Rexx Exec will PRINT a data set specified by the user. */

Address ISPEXEC

display_panel:
"display panel(kpprntp)"

if rc = 8 then exit

"Vget (wdsn hcla hpid ncpy ptyp) Profile"

parse value "" with null

pcc = c
pbnd = b
pdcf = d

if pcc = "Y" then pcc = "CCHAR"
             else pcc = ""
if pbnd = "Y" then pbnd = "BIND(4)"
              else pbnd = ""

parse value wdsn with '(' wmem ')'

dsnstat = sysdsn(wdsn)
if dsnstat = "OK" then call print
   else do
      zedlmsg = dsnstat
      "Setmsg Msg(isrz001)"
   end

Signal display_panel

Print:
   worg = Listdsi(wdsn)
   if Sysdsorg = "PO" then
      if wmem = null then Call pds_testing
      else do
         Call print_it_now wdsn
         Call print_msg
      end
   else do
      Call print_it_now wdsn
      Call print_msg
   end
   return

Print_it_now:
   Arg pdsn
   if ptyp = null
      then
        Address TSO "printds ds("pdsn") class("hcla") dest("hpid") ",
                    "copies("ncpy") notitle" pcc pbnd
      else
        Address TSO "printds ds("pdsn") class("hcla") dest("hpid") ",
                    "copies("ncpy") outdes("ptyp") notitle" pcc pbnd
   return

Print_msg:
   if rc = 0
      then do
         if ncpy = 1 then zcpy = 'copy was'
         else zcpy = 'copies were'
         zedlmsg = ""ncpy" "zcpy" successfully printed to "hpid"."
         "Setmsg Msg(isrz001)"
      end
   return

pds_testing:
   "Lminit Dataid(dataid) Dataset("wdsn") Enq(Shrw)"
   "Lmopen Dataid("dataid") Option(Input)"
   "Lmmdisp Dataid("dataid") Option(Display)",
     "Commands(Any) Panel(kplprnt)"
     do while rc == 0
        Call process_selection wdsn
       "Lmmdisp Dataid("dataid") Option(Get)"
        if rc == 8
           then "Lmmdisp Dataid("dataid") Option(Display)",
                "Commands(Any) Panel(kplprnt)"
     end
     "Lmmdisp Dataid("dataid") Option(Free)"
     "Lmclose Dataid("dataid")"
     "Lmfree  Dataid("dataid")"
   return

process_selection:
   Arg pdsn
   if left(pdsn,1) = "'"
   then parse value pdsn with "'" p_dsn "'"
   else p_dsn = sysvar("syspref")"."pdsn
   zlmember = strip(zlmember)
   Select
   When zllcmd = "/" | zllcmd = "S"
   Then do
     "Lmmdisp Dataid("dataid") Option(Put) Member("zlmember")",
         "Zludata(printed)"
     pdsn = "'"p_dsn"("zlmember")'"
     call print_it_now pdsn
     End
   When zllcmd = "B"
   Then "Browse Dataid("dataid") Member("zlmember")"
   Otherwise nop;
   End
   return
