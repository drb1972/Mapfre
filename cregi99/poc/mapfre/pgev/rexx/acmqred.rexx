/*-----------------------------REXX----------------------------------*\
 *  Analyse ACMQ output and build DELETE SCL for unused components.  *
 *  Executed from option 6 on the user menu option 11.               *
 *  Skeleton JCL is ACMQRED                                          *
\*-------------------------------------------------------------------*/
trace n

arg c1en c1si c1su c1ty

say 'ACMQRED:' date() time()
say 'ACMQRED:'
say 'ACMQRED: c1si............:' c1en
say 'ACMQRED: c1si............:' c1si
say 'ACMQRED: c1su............:' c1su
say 'ACMQRED: c1ty............:' c1ty
say 'ACMQRED:'

c1sy = left(c1su,2)

"execio * diskr ACMQ (stem acmq. finis"
if rc ^= 0 then call exception rc 'DISKR of ACMQ failed.'

do i = 1 to acmq.0
  if word(acmq.i,2) = 'ACMQ204I' then do /* Element name record      */
    x = i + 1
    y = i + 2
    z = i + 3
    if word(acmq.x,2) = 'ACMQ212W' & ,        /* NO MATCHING ENTRY   */
       word(acmq.y,2) = 'ACMQ207I' then do    /* Member name record  */
      element = left(word(acmq.i,4),8)
      if word(acmq.z,2) = 'ACMQ212W' then do  /* NO MATCHING ENTRY   */
        /* No input element or input member component found          */
        queue '  DELETE ELEMENT' element '.'
        i = i + 3
      end /* word(acmq.z,2) = 'ACMQ212W' */
      else do
        dsn     = strip(word(acmq.y,6),,"'")
        dsn_sys = substr(dsn,7,2)
        if dsn_sys       = c1sy & ,
           pos(c1ty,dsn) > 0    then do
          /* Its an input member component from a DSN from the same  */
          /* system and the type name is found in the DSN so no      */
          /* delete.                                                 */
          say '* NON FOOTPRINTED MEMBER' element 'USED FROM' dsn
          say '  No delete SCL written'
          i = i + 2
        end /* dsn_sys = c1sy & pos(c1ty,dsn) > 0 */
        else do
          /* Its an input member component but the DSN is either     */
          /* not from the same system or the type name is not in the */
          /* DSN, or both. So we delete it.                          */
          say '* NON FOOTPRINTED MEMBER' element 'USED FROM' dsn
          say '  Delete SCL written'
          queue '  DELETE ELEMENT' element '.'
          i = i + 2
        end /* else */
      end /* else */
    end /* word(acmq.x,2) = 'ACMQ212W' & .. */
  end /* word(acmq.i,2) = 'ACMQ204I' */
end /* i = 1 to acmq.0 */

say 'ACMQRED:'
say 'ACMQRED:' queued() 'DELETE statements written'
if queued() = 0 then
  say 'ACMQRED: All stage' c1si c1ty's are in use'

if queued() > 0 then do
  /* Write out the SCL                                               */
  newstack
  if c1ty = 'COPYBOOK' then do
    queue '* WARNING ** COPYBOOKs can be used for file layouts.       '
    queue '* Endevor only tracks COPYBOOK input components that have' ,
          'been compiled'
    queue '* If COPYBOOKs are used as file layouts by other utilities',
          'like Fileaid'
    queue '* then some of these COPYBOOK elements may not be redundant.'
    queue '*                                                          '
  end /* c1ty = 'COPYBOOK' */
  if c1ty = 'EASYMAC' then do
    queue '* WARNING ** EASYTRIEVE can be run interpretively.         '
    queue '* Endevor only tracks EASYMAC input components that have' ,
          'been compiled.'
    queue '* If you have EASYTREV elements with processor group' ,
          'EASYTREV'
    queue '* then some of these EASYMAC elements may not be redundant.'
    queue '*                                                          '
  end /* c1ty = 'EASYMAC' */
  if c1si = 'P' then do
    queue '* This SCL can be CUT and PASTE (using ISPF edit CUT &' ,
          'PASTE)'
    queue '* into your Endevor package.                               '
    queue '* Use the SE line command in SDSF to edit this SCL DD      '
  end /* c1si = 'P' */
  else do
    queue '* If you are in view or edit mode you can type SCL on the  '
    queue '* command line to submit this SCL.                         '
    queue '* Use the SE line command in SDSF to edit this SCL DD      '
  end /* else*/
  queue '*                                                            '
  queue ' SET FROM ENVIRONMENT' c1en 'SYSTEM' c1sy 'SUBSYSTEM' c1su
  queue '          TYPE' c1ty 'STAGE' c1si '.'
  if c1si = 'P' then
    queue ' SET OPTIONS CCID "        " COMMENT "#" .'
  else
    queue ' SET OPTIONS CCID "DELETE" COMMENT' ,
          '"DELETE UNUSED ELEMENT" .'

  "execio" queued() "diskw SCL"
  if rc ^= 0 then call exception rc 'DISKW to SCL failed.'
  delstack

  "execio" queued() "diskw SCL (finis"
  if rc ^= 0 then call exception rc 'DISKW to SCL failed.'
end /* queued() > 0 */

exit

/*---------------------- S U B R O U T I N E S ----------------------*/

/*-------------------------------------------------------------------*/
/* Error with line number displayed                                  */
/*-------------------------------------------------------------------*/
exception:
 parse arg return_code comment

 address tso 'delstack' /* Clear down the stack                      */

 parse source . . rexxname . /* Get the rexx name(generic subroutine)*/
 say rexxname':'
 say rexxname':' comment
 say rexxname': Exception called from line' sigl

exit return_code
