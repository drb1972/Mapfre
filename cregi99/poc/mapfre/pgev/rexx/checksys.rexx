/* REXX */
trace o
w = 0

   "execio * diskr baselibs (stem base. finis"  /* base library list */
   "execio * diskr systems (stem sys. finis"    /* Endevor system list */

do a=1 to base.0 /* count through base library list */
true = 0
basedsn = substr(base.a,1,44)
basedsn = strip(basedsn)
sys = substr(basedsn,3,2)
if substr(basedsn,6,4) ^= 'BASE' then iterate
if basedsn = 'PGDF.BASE.LOAD' then iterate
if sys     = 'EK' then iterate
if sys = 'RG' then do
   w =w + 1 /* increment counter */
   true = 1 /* found record */
   syslist.w = basedsn /* add array variable */
end /* if sys = 'RG' then do */
else do b=1 to sys.0 /* loop through system names */
ndvsys = substr(sys.b,1,2)
if sys = ndvsys then do
   w =w + 1 /* increment counter */
   true = 1 /* found record */
   syslist.w = basedsn /* add array variable */
end /* if sys = ndvsys then do */
end /* do b=1 to sys.0 */
if true = 0 then say 'CHECKSYS: 'basedsn' is not under Endevor control'
end /* do a=1 to base.0 */

    "EXECIO" w "DISKW NEWBASE (STEM syslist. FINIS"
say 'CHECKSYS: dsn list updated to only contain Endevor controlled libraries'
