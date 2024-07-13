/*----------------------------------------------------------*\
 *  Interrogate the XPETGT schedule environment and report  *
 *  any Lpars where it is switched off.                     *
 *  Its executed in job EVHTASKD.                           *
\*----------------------------------------------------------*/
schenv  = "XPETGT"
lpars   = "A B C D E F"
/* Temp - only check the QBOS until dumps are produced for XPEHOST   */
lpars   = "B"
lparoff = ''
maxrc   = 0

Do I = 1 to Words(lpars)
   lpar = "Q"||word(lpars,i)||"OS"
   var = opswlm('I',schenv,lpar)
   say lpar var
   If var ^= "AVAIL" then do
     lparoff = lparoff lpar
     maxrc = 4
   end
End

if maxrc = 4 then do
  queue 'The XPETGT sheduling environment is switched off on the'
  queue 'following Lpars:'
  queue lparoff
  queue
  queue 'If you want to switch the Lpars back on then call Systems'
  queue 'Operations on x221208'
  "execio" queued() "diskw SEINFO (finis"
end

exit maxrc
