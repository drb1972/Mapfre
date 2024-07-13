/*--------------------------------REXX-------------------------------*/
/* Description:  This REXX has been built to run the CMSNDVRU exec   */
/*               and if the infoman record is in use then it will    */
/*               sleep for 15 minutes and try again.                 */
/*                                                                   */
/*-------------------------------------------------------------------*/

Arg session class user_id site status pkid
do retry = 1 to 4
  Call 'CMSNDVRU 'session class user_id site status pkid
say 'The Infoman update completed with condition code 'result
  If result = 0 then exit 0
                else do
                       Address syscall
                        "sleep "500
                     end /* end else do */
end /* end retry */

Exit 12
