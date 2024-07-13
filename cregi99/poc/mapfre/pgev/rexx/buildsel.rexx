/* REXX */
trace o
ADDRESS tso
   s = 0
   t = 0
   u = 0
   "execio * diskr repin (stem act. finis"
   "execio * diskr shiprule (stem ship. finis"
do d=1 to act.0
   lastsys=sys
   sys=substr(act.d,3,2)
   if sys ^= lastsys then
     call output
   baselib=strip(substr(act.d,1,44))
   if baselib = 'PGAC.BASE.CICS' then iterate
   if baselib = 'PGBA.BASE.CICS' then iterate
   if baselib = 'PGBB.BASE.CICS' then iterate
   if sysdsn("'"baselib"'") = 'OK' then do
     do a = 1 to ship.0 /* read the ship rule results to get prev dataset */
       if pos(baselib,ship.a) > 1 then do
          prevlib = substr(ship.a,3,44)
          prevlib = strip(prevlib)
          u = u + 1
          selprev.u = ' SELECT DSN='||prevlib
       end /* if pos(baselib,ship.a) > 1 then do */
     end /* do a = 1 to ship.0 */
     t = t + 1
     selbase.t = ' SELECT DSN='||BASELIB
   end /* if sysdsn("'"baselib"'") = 'OK' then do */
   else say baselib' dataset not found on the Qplex'
end

output:
if sys ^= 'sys' then do
  s = s + 1
  syslist.s = sys
  "ALLOC DA('PREV.BASELIB.DATA("LASTSYS")') F(DATAOUT) SHR"
  "EXECIO "t " DISKW DATAOUT (stem selbase. FINIS"
  "FREE FI(DATAOUT)"
  "ALLOC DA('PREV.BASELIB.DATA("LASTSYS"PREV)') F(PREVOUT) SHR"
  "EXECIO "u " DISKW PREVOUT (stem selprev. FINIS"
  "FREE FI(PREVOUT)"
/* reset the counters after diskw */
 t = 0
 u = 0
end
return
    "ALLOC DA('PREV.BASELIB.CHECK(SYSTEMS)') F(F) SHR"
    "EXECIO" s "DISKW F (STEM syslist. FINIS"
    "FREE FI(F)"
     say finished
