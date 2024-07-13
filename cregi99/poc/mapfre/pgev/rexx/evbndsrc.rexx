/*-----------------------------REXX----------------------------------*\
 *  This Rexx is used by GBIND to validate that the bind source      *
 *  is 1 line long and is not blank.                                 *
\*-------------------------------------------------------------------*/
trace n

arg c1element c1ty

queue 'EVBNDSRC: Element:' c1element 'Type:' c1ty
queue ' '

/* Read the element source                                           */
"execio 2 diskr SRCEIN (stem source. finis"
if rc > 2 then call exception rc "DISKR of SRCEIN failed. RC="rc

check = left(source.1,72) /* get the first 72 characters of the line */

if source.0 = 0 then do
  queue "EVBNDSRC: Your BIND element contains no source."
  queue "EVBNDSRC:"
  queue "EVBNDSRC: Please use the member MODEL from the dataset"
  queue "EVBNDSRC: PREV.UEV1.BIND on the Qplex."

  call oldsource

  "EXECIO "queued()" DISKW readme (FINIS)"
  exit 17 /* this return code will fail the GCOBM return code        */
end /* source.0 = 0 */

if source.0 > 1 then do
  queue "EVBNDSRC: Your BIND element contains more than 1 line of source,"
  queue "EVBNDSRC: this is not correct. Please check that you have not"
  queue "EVBNDSRC: added your source in to the wrong type."
  queue "EVBNDSRC:"
  queue "EVBNDSRC: Please use the member MODEL from the dataset"
  queue "EVBNDSRC: PREV.UEV1.BIND on the Qplex."

  call oldsource

  "EXECIO "queued()" DISKW readme (FINIS)"
  exit 17 /* this return code will fail the GCOBM return code        */
end /* source.0 > 1 */

if strip(check) = '' then do
  queue "EVBNDSRC: Your BIND element contains just spaces, this is not correct."
  queue "EVBNDSRC:"
  queue "EVBNDSRC: Please use the member MODEL from the dataset"
  queue "EVBNDSRC: PREV.UEV1.BIND on the Qplex."

  call oldsource

  "EXECIO "queued()" DISKW readme (FINIS)"
  exit 17 /* this return code will fail the GCOBM return code        */
end /* strip(check) = '' */

exit

/*-------------------------------------------------------------------*/
/* What if the bind element was not changed                          */
/*-------------------------------------------------------------------*/
oldsource:
 queue "EVBNDSRC:"
 queue "EVBNDSRC: If you have not amended the bind source as part of your"
 queue "EVBNDSRC: action, then this message has been raised because the"
 queue "EVBNDSRC: original element had been created incorrectly."
 queue "EVBNDSRC:"
 queue "EVBNDSRC: Please correct this problem by updating the bind element"
 queue "EVBNDSRC: using the PREV.UEV1.BIND(MODEL) source on the Qplex."
 queue "EVBNDSRC:"
 queue "EVBNDSRC: Thank you for your co-operation."

return /* oldsource: */

/*-------------------------------------------------------------------*/
/* Error with line number displayed                                  */
/*-------------------------------------------------------------------*/
exception:
 parse arg return_code comment

 delstack /* Clear down the stack                                    */

 parse source . . rexxname . /* Get the rexx name(generic subroutine)*/
 say rexxname":"
 say rexxname":" comment
 say rexxname": Exception called from line" sigl
 say rexxname":"

exit return_code
