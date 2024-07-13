/*-----------------------------REXX----------------------------------*\
 *  Issue README messages from processors.                           *
 *  This is used to allow lower case messages and so that variables  *
 *  can be used in the text.                                         *
 *                                                                   *
 *  To add a new message just add a subroutine with same name as the *
 *  message type.                                                    *
\*-------------------------------------------------------------------*/
trace n

arg msgtype c1element c1ty outdd exitrc indd

say 'MESSAGE:' Date() Time()
say 'MESSAGE:'
say 'MESSAGE: Msgtype.........:' msgtype
say 'MESSAGE: C1element.......:' c1element
say 'MESSAGE: C1ty............:' c1ty
say 'MESSAGE: Outdd...........:' outdd
say 'MESSAGE: Exitrc..........:' exitrc
say 'MESSAGE: Indd............:' indd
say 'MESSAGE:'

/* Read additional non standard paramters to display in messages     */
say 'MESSAGE: Reading PARMS file which may not exist'
"execio * diskr PARMS (stem parms. finis"
if rc = 0 then
  do i = 1 to parms.0
    say 'MESSAGE:' parms.i
    interpret parms.i
  end /* i = 1 to parms.0 */
else
  say 'MESSAGE: No PARMS file found, continuing...'
say 'MESSAGE:'

queue '   Element:' c1element  'Type:' c1ty
queue ' '

/* Add text from input file E.g. Output from VALID8                  */
if indd ^= '' then do
  "execio * diskr" indd "(stem text. finis"
  if rc ^= 0 then call exception rc 'DISKR of' indd 'failed.'
end /* indd ^= '' */

/* Call the subroutine to queue the text                             */
signal on syntax name nosub
interpret 'call' msgtype
signal off syntax

queue ' '
"execio" queued() "diskw" outdd "(finis"
if rc ^= 0 then call exception rc 'DISKW to' outdd 'failed.'

exit exitrc

/*---------------------- S U B R O U T I N E S ----------------------*/

/*-------------------------------------------------------------------*/
/* BIND@O                                                            */
/*-------------------------------------------------------------------*/
bind@o:

queue '   WARNING: No Qplex bind performed                                     '
queue copies('-',80)
queue '                                                                        '
queue '   You are making an emergency change to a' c1ty 'element at Endevor    '
queue '   stage O.                                                             '
queue '                                                                        '
queue '   No automatic Qplex bind has occurred, you must bind the DBRM manually'
queue '   before the program can be tested on the Qplex.                       '
queue '                                                                        '
queue '   You must include this' c1ty 'element in the package move to stage P  '
queue '   of Endevor so that a production bind is done.                        '
queue '                                                                        '
queue '   N.B. The processor has raised a return code of 20 but this is NOT a  '
queue '   failure (just an eye catcher).                                       '
queue '   This return code will not cause issues in the cast of the package to '
queue '   move the elements to stage P.                                        '

return /* bind@o */


/*-------------------------------------------------------------------*/
/* SPDEF@O                                                           */
/*-------------------------------------------------------------------*/
spdef@o:

queue '   WARNING: No Qplex create performed                                   '
queue copies('-',80)
queue '                                                                        '
queue '   You are making an emergency change to an SPDEF element at Endevor    '
queue '   stage O.                                                             '
queue '                                                                        '
queue '   No automatic Qplex create has occurred, you must create the procedure'
queue '   manually before the program can be tested on the Qplex.              '
queue '                                                                        '
queue '   You must include this SPDEF element in the package move to stage P of'
queue '   Endevor so that a production create is done.                         '
queue '                                                                        '
queue '   N.B. The processor has raised a return code of 20 but this is NOT a  '
queue '   failure (just an eye catcher).                                       '
queue '   This return code will not cause issues in the cast of the package to '
queue '   move the elements to stage P.                                        '

return /* spdef@o */

/*-------------------------------------------------------------------*/
/* DEFAULT                                                           */
/*-------------------------------------------------------------------*/
default:

queue '   ERROR..: No processor group specified                                '
queue copies('-',80)
queue '                                                                        '
queue '   This is the first time this element has been added into Endevor, so  '
queue '   you must specify a processor group.                                  '
queue '                                                                        '
queue '   When building ADD SCL, enter an asterisk in the processor group field'
queue '   to view a selection list of available processor groups.              '

return /* default */

/*-------------------------------------------------------------------*/
/* NOBNDELT                                                          */
/*-------------------------------------------------------------------*/
nobndelt:

queue '   ERROR..: No dummy BIND element found                                 '
queue copies('-',80)
queue '                                                                        '
queue '   You have generated a DB2 program, but a dummy bind element could not '
queue '   be pulled back to the current stage.                                 '
queue '                                                                        '
queue '   This is usually because the bind element does not exist, or it is    '
queue '   signed out to someone else.                                          '
queue '                                                                        '
queue '   No development DB2 bind has occured.                                 '
queue '                                                                        '
queue '   You should either resolve the signout problems or add a new bind     '
queue '   element for this program.                                            '
queue '                                                                        '

return /* nobndelt */

/*-------------------------------------------------------------------*/
/* GLINK                                                             */
/*-------------------------------------------------------------------*/
glink:

queue '   ERROR..: No objects found                                            '
queue copies('-',80)
queue '                                                                        '
queue '   None of the object modules specified in this link deck were found.   '
queue '                                                                        '
queue '   This is normally because none of the program elements that make up   '
queue '   this load module have been generated since their conversion to       '
queue '   Endevor.                                                             '
queue '                                                                        '
queue '   As nothing has changed, there is no need to recreate this load module'
queue '                                                                        '
queue '   No new load module has been created.                                 '

return /* glink */

/*-------------------------------------------------------------------*/
/* SDFCOPY                                                           */
/*-------------------------------------------------------------------*/
sdfcopy:

queue '   ERROR..: Map copybook found in type COPYBOOK                         '
queue copies('-',80)
queue '                                                                        '
queue '   A copybook element the same name as the sdf2 map was found.          '
queue '                                                                        '
queue '   As the map will produce a copybook, this can cause problems when you '
queue '   come to move the map element forward.                                '
queue '                                                                        '
queue '   Please delete the copybook and regenerate the map. If the copybook is'
queue '   at stage P, Endevor Support may be able to assist with this.         '
queue '                                                                        '
queue '   No new load module has been created.                                 '

return /* sdfcopy */

/*-------------------------------------------------------------------*/
/* SDFGRP                                                            */
/*-------------------------------------------------------------------*/
sdfgrp:

queue '   ERROR..: SDF2 group found with the same name                         '
queue copies('-',80)
queue '                                                                        '
queue '   A MAPSDF2G (group) element was found with the same name as this      '
queue '   MAPSDF2P (panel) element.                                            '
queue '                                                                        '
queue '   You should process this SDF2 map by generating the MAPSDF2G element. '
queue '                                                                        '
queue '   To achieve this you should:                                          '
queue '     1) Generate this MAPSDF2P element with a processor group of        '
queue '        "MAPSDF2P".                                                     '
queue '     2) Use generate with copyback to generate the MAPSDF2G element back'
queue '        at this stage.                                                  '

return /* sdfgrp */

/*-------------------------------------------------------------------*/
/* DB2V7                                                             */
/*-------------------------------------------------------------------*/
db2v7:

queue '   WARNING: COBOL2 and DB2 not compatible                               '
queue copies('-',80)
queue '                                                                        '
queue '   Warning!! The DB2v7 precompiler is licenced until DB2 v9.            '
queue '   *** COBOL2 is non standard ***                                       '
queue '   Please convert this program to the latest version of COBOL.          '

return /* db2v7 */

/*-------------------------------------------------------------------*/
/* NOBINDP                                                           */
/*-------------------------------------------------------------------*/
nobindp:

queue '   WARNING: No automatic binding                                        '
queue copies('-',80)
queue '                                                                        '
queue '   No automatic bind will be performed in development or production     '
queue '   you must bind manually.                                              '
queue '                                                                        '
queue '   Instructions may be in the source of this' c1ty ' member.            '
queue '                                                                        '
queue '   ** Please contact your DBA **                                        '

return /* nobindp */

/*-------------------------------------------------------------------*/
/* LINKDATA                                                          */
/*-------------------------------------------------------------------*/
linkdata:

queue '   ERROR  : No LINKDATA element found                                   '
queue copies('-',80)
queue '                                                                        '
queue '   You have just processed an element with a processor group that       '
queue '   has an L in position 2 but no associated LINKDATA element has been   '
queue '   found.                                                               '
queue '                                                                        '
queue '   Either add the LINKDATA element and then re-process this element or  '
queue '   amend the processor group to have an X in position 2.                '
queue '                                                                        '
queue '   e-mail Endevor Support via VERTIZOS@kyndryl.com '

return /* linkdata */

/*-------------------------------------------------------------------*/
/* NOSPDEF                                                           */
/*-------------------------------------------------------------------*/
nospdef:

queue '   ERROR  : No SPDEF element found                                      '
queue copies('-',80)
queue '                                                                        '
queue '   The equivalent SPDEF element for this program has not been found.    '
queue '   You will need to create the stored procedure definition through      '
queue '   Endevor user menu option 8.                                          '
if c1ty = 'COBD' then do
  queue '                                                                      '
  queue '   For type COBD you only need to specify the WLM environment in the  '
  queue '   SPDEF source.                                                      '
end /* c1ty = 'COBD' */

return /* nospdef */

/*-------------------------------------------------------------------*/
/* COB2FAIL                                                          */
/*-------------------------------------------------------------------*/
cob2fail:

queue '   ERROR  : COBOL2 programs must be converted to the latest version     '
queue copies('-',80)
queue '                                                                        '
queue '   You are trying to compile a program with Cobol2, which is no longer  '
queue '   supported. You should change the processor group to to one that has  '
queue '   an "M" in character 4, which will invoke the latest Cobol compiler.  '
queue '   compiler.                                                            '
queue '                                                                        '
queue '   If you are using SQL in Cobol2 then it will not be possible to       '
queue '   generate when DB2 V9 is implemneted.                                 '
queue '                                                                        '
queue '   New processor groups have been created for each system for types COBB'
queue '   & COBC, which should work for the majority of programs. If your      '
queue '   existing processor group has an "X" in position 5 then you should aim'
queue '   to use one of the following groups.                                  '
queue '                                                                        '
queue '   For COBC elements use                                                '
queue '   XXLMJXDX     Load/trunc(opt)/A=31/R=Any/RENT                         '
queue '   XXOMJXXX     Object/trunc(opt)                                       '
queue '   DXLMMXDX DB2/Load/trunc(bin)/A=31/R=Any/RENT                         '
queue '   DXOMMXXX DB2/Object/trunc(bin)                                       '
queue '                                                                        '
queue '   For COBB elements use                                                '
queue '   XXLMJXXX     Load/trunc(opt)/A=31/R=Any                              '
queue '   XXOMJXXX     Object/trunc(opt)                                       '
queue '   DXLMMXXX DB2/Load/trunc(bin)/A=31/R=Any                              '
queue '   DXOMMXXX DB2/Object/trunc(bin)                                       '
queue '                                                                        '
queue '   If you have another character in position 5 then please refer to the '
queue '   document entitled "Migrating to Cobol 3" which is on the Endevor     '
queue '   Support web page at the following address.                           '
queue '                                                                        '
queue '   http://www.manufacturing.rbs.co.uk/gtendevor/                        '
queue '                                                                        '
queue '   If you have a technical reason for not migrating your code at this   '
queue '   time then you must enter the string "**COB2" as the 1st 6 characters '
queue '   of the comment in your ADD/UPDATE/GENERATE scl. This will allow you  '
queue '   to proceed with your compile.                                        '

return /* cob2fail */

/*-------------------------------------------------------------------*/
/* COMNCOPY                                                          */
/*-------------------------------------------------------------------*/
comncopy:

do i = 1 to text.0 /* Write out the output from the VALID8 step      */
  queue text.i
end /* i = 1 to text.0 */

queue copies('-',80)
queue '                                                                        '
queue '   You have just added/generated' c1ty c1element 'with processor        '
queue '   group' c1ty 'that already exists in Endevor in the above system.     '
queue '                                                                        '
queue '   !!!!!!!!! Duplicate' c1ty's are not allowed. !!!!!!!!!               '
queue '   You must immediately delete element' c1element 'in system' c1sy'.    '
queue '                                                                        '
queue '   Please check the processor group in the other system, if it is not   '
queue '   common then make it common so that you can use it.                   '
queue '                                                                        '
queue '   N.B. Endevor has not saved the source of this element.               '
queue '                                                                        '
queue '   It is possible that that the' c1ty 'does not exist in the other      '
queue '   system and our file needs updating. Please contact Endevor Support   '
queue '   if this is may be the case.                                          '
queue '                                                                        '
queue '   or email ¯ (VERTIZOS@kyndryl.com)   '

return /* comncopy */

/*-------------------------------------------------------------------*/
/* wsdlcopy                                                          */
/*-------------------------------------------------------------------*/
wsdlcopy:

do i = 1 to text.0 /* Write out the output from the WSDL8 step       */
  queue text.i
end /* i = 1 to text.0 */

queue copies('-',80)
queue '                                                                        '
queue '   You have just added/generated' c1ty c1element 'with processor        '
queue '   group' c1ty 'that already exists in Endevor as a WSDL copybook.      '
queue '                                                                        '
queue '   !!!!!!!!! You can not add WSDL copybooks to type COPYBOOK !!!!!!!!!  '
queue '   !!!!!!!!! They are managed by the WSDL element.           !!!!!!!!!  '
queue '   You must immediately delete element' c1element 'in system' c1sy'.    '
queue '                                                                        '
queue '   N.B. Endevor has not saved the source of this element.               '
queue '                                                                        '
queue '      email ¯ endevor (VERTIZOS@kyndryl.com)   '

return /* wsdlcopy */

/*-------------------------------------------------------------------*/
/* DPLYFAIL                                                          */
/*-------------------------------------------------------------------*/
dplyfail:

queue '   WEBSPHERE DEPLOYMENT FOR ELEMENT' C1ELMNT255 'FAILED                 '
queue copies('-',80)
queue '                                                                        '
queue '   The automated Websphere deployment of the EAR file has failed.       '
queue '                                                                        '
queue '   View the log output in DDNAMEs STDOUTL and STDERRL                   '
queue '     Logs are also written to:                                          '
queue '      ' logpath || logfile'.out                                         '
queue '      ' logpath || logfile'.err                                         '
queue '                                                                        '
queue '   If you can not resolve the issue yourself then please contact        '
queue '   WebSphere Support.                                                   '

return /* dplyfail */

/*-------------------------------------------------------------------*/
/* NOBINDMU                                                          */
/*-------------------------------------------------------------------*/
nobindmu:

queue copies('-',80)
queue '                                                                        '
queue '   The BINDMULT element for this EAR file could not be found            '
queue '   and no DB2 package bind(s) have occurred.                            '
queue '                                                                        '
queue '   For new EAR files you will need to successfully transform            '
queue '   the EAR file to create the BINDMULT element.                         '
queue '                                                                        '
queue '   Another common problem is that the BINDMULT element is               '
queue '   signed out to another user.                                          '

return /* nobindmu */

/*-------------------------------------------------------------------*/
/* NORENAME                                                          */
/*-------------------------------------------------------------------*/
norename:

queue '   The renaming of a load module on ADD is not allowed for type' c1ty
queue copies('-',80)
queue '                                                                        '
queue '   Input member name =' c1usrmbr
queue '   Element name      =' c1element

return /* norename */

/*-------------------------------------------------------------------*/
/* NOCPYBAK                                                          */
/*-------------------------------------------------------------------*/
nocpybak:

queue copies('-',80)
queue '                                                                        '
queue '   Step PRECOPY has failed.                                             '
queue '   A possible cause of this is generate with copyback which is not      '
queue '   allowed for load module types at MAPFRE.                             '
queue '   You must use the ADD action instead.                                 '

return /* nocpybak */

/*-------------------------------------------------------------------*/
/* EARDELTA                                                          */
/*-------------------------------------------------------------------*/
eardelta:

queue '   The failed flag has been set for this element.                       '
queue copies('-',80)
queue '                                                                        '
queue '   This is because a delta EAR has overwritten another EAR element.     '
queue '   The move has been successful and the EAR file can be deployed.       '
queue '   However, in order to move the element further up the map it must be  '
queue '   re generated at stage' c1si'.'
queue '   You must also regenerate the BINDMULT and DEPLOY elements in the same'
queue '   package.'
queue ' '
queue '   You should also delete the EAR file at stage' c1sstgid 'manually     '
queue '   as Endevor has been unable to do this.                               '

return /* eardelta */

/*-------------------------------------------------------------------*/
/* WIZARD                                                            */
/*-------------------------------------------------------------------*/
wizard:

queue '   ERROR  : USER= parameter invalid                                     '
queue copies('-',80)
queue '                                                                        '
queue '  Your add has failed because a USER= statement is not coded to standard'
queue '  in TT'c1sy'.'c1element'.'c1ty
queue '                                                                        '

"execio * diskr PRODOPS (stem prodops. finis"
if rc ^= 0 then call exception rc 'DISKR of PRODOPS failed.'
do i = 1 to prodops.0 /* Write out the output from the PRODOPS search*/
  queue '  ' left(word(prodops.i,8),8) '- USER=PRODOPS coded'
end /* i = 1 to prodops.0 */

"execio * diskr USERPARM (stem userparm. finis"
if rc ^= 0 then call exception rc 'DISKR of USERPARM failed.'
do i = 1 to userparm.0 /* Write out the output from the USER= search */
  queue '  ' left(word(userparm.i,7),8) ,
        '- No USER= parameter coded on the jobcard'
end /* i = 1 to userparm.0 */

return /* wizard */

/*-------------------------------------------------------------------*/
/* NOEAR                                                             */
/*-------------------------------------------------------------------*/
noear:

queue '   ERROR..: No EAR element found                                        '
queue copies('-',80)
queue '                                                                        '
queue '   You have generated a DEPLOY element, but the EAR file of the same    '
queue '   name could not be found in Endevor (within the same subsystem).      '
queue '                                                                        '
queue '   The Endevor map has been searched to find the EAR element.           '
queue '                                                                        '
queue '   You should check where the EAR element is (that you wish to          '
queue '   auto-deploy) and process the deploy element in that subsystem.       '
queue '                                                                        '

return /* noear    */

/*-------------------------------------------------------------------*/
/* nosub - if the interpret fails bacause the subroutine doesnt exist*/
/*-------------------------------------------------------------------*/
nosub:

 delstack /* clear down the stack                                    */

 say 'MESSAGE:'
 say 'MESSAGE: Call to subroutine' msgtype 'failed at line' sigl
 say 'MESSAGE:'
 say 'MESSAGE: The subroutine for msgtype' msgtype 'has not been created'

exit 3659

/*-------------------------------------------------------------------*/
/* error with line number displayed                                  */
/*-------------------------------------------------------------------*/
exception:
 parse arg return_code comment

 delstack /* clear down the stack                                    */

 parse source . . rexxname . /* get the rexx name(generic subroutine)*/
 say rexxname':'
 say rexxname':' comment
 say rexxname': exception called from line' sigl

exit return_code
