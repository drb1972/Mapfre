        /* ---------------------  rexx procedure  ---------------------- *
         * Name:       RNEWSKEY                                          *
         *                                                               *
         * Function:   To process all members of the News PDS that are   *
         *             news items and extract all words that are not     *
         *             considered 'noise'.  Then build an 'index' of     *
         *             these words for use with the RNEWS SEARCH         *
         *             function.                                         *
         *                                                               *
         * Syntax:     %RNEWSKEY news_pds_dsn  work_dsn                  *
         *                                                               *
         * Author:    Lionel B. Dyck                                     *
         *                                                               *
         * History:                                                      *
         *             12/10/92 - Add panel to indicate process and      *
         *                        ask the user to be patient.            *
         *                                                               *
         *             11/30/92 - add more words to ignore               *
         *                                                               *
         *             11/25/92 - updated to translate out '='           *
         *                                                               *
         *             11/23/92 - created                                *
         *                                                               *
         *                                                               *
         * ------------------------------------------------------------- */

        arg dsn out_dsn

        ddn       = 'WORD'random()
        w.        = ""
        all_words = ""
        total     = 0
        out.0     = 0

        /* go setup the words to ignore */
        phase = "*** Set up words to ignore ***"
        call please_wait
        call set_ignore
          /* now insure the words are upper case */
          ignore_words = translate(ignore_words)

        if left(dsn,1) <> "'" then do
           dsn = sysvar(syspref)"."dsn
           end
           else do
                dsn = substr(dsn,2,length(dsn)-2)
                end

        if left(out_dsn,1) <> "'" then do
           out_dsn = sysvar(syspref)"."out_dsn
           end
           else do
                out_dsn = substr(out_dsn,2,length(out_dsn)-2)
                end

        x = outtrap("lm.","*")

        phase = "*** Determine News and Information members to Process ***"
        call please_wait

        "LISTD" "'"dsn"'" "MEMBERS"

        x = outtrap("off")

        do i = 1 to lm.0
           if lm.i = "--MEMBERS--" then leave
           end

        i = i + 1

        do count = i to lm.0
           member = strip(lm.count)
           /* we only want members that start with N */
           if left(member,1) <> "N" then iterate
           /* and then only those that are 6 characters in length */
           if length(member) <> 6 then iterate
           drop in.
           "Alloc f("ddn") ds('"dsn"("member")') Shr Reuse"
           "Execio * diskr" ddn "(finis stem in."
           "Free  f("ddn")"
           phase = "*** Processing member:" member "***"
           call please_wait

           do w_count = 1 to in.0
              in.w_count = translate(in.w_count," ","='")
              words = words(in.w_count)
              if words > 0 then
                 do j = 1 to words
                    word = translate(word(in.w_count,j))
                    if length(hold_word) > 0 then do
                       word = hold_word""word
                       hold_word = ""
                       end
                    if right(word,1) = "-" then
                       hold_word = left(word,length(word)-1)
                    if length(word) < 3 then iterate
                    if datatype(word,"A") = 0 then iterate
                    if wordpos(word,ignore_words) > 0 then iterate
                    if w.word = "" then do
                                        w.word = word member
                                        all_words = all_words word
                                        total = total + 1
                                        end
                                   else do
                                         if wordpos(member,w.word) = 0 then
                                            w.word = w.word  member
                                         end
                 end
           end
        end

        phase = "*** Building Index List and Eliminate Redundant Words ***"
        call please_wait

        do i = 1 to total
           word = word(all_words,i)
           line = out.0 + 1
           out.0 = line
           if length(w.word) < 70 then do
              out.line = w.word
              end
           else do forever
                pos = pos(" ",w.word,60)
                pm1 = pos - 1
                pp1 = pos + 1
                if pm1 > 0 then do
                   out.line = substr(w.word,1,pm1)
                   new = substr(w.word,pp1)
                   end
                   else do
                      out.line = w.word
                      new = ""
                      end
                if length(new) = 0 then leave
                w.word = word new
                line = out.0 + 1
                out.0 = line
                end
        end

        phase = "*** Writing the Index of Search Words ***"
        call please_wait

        "Alloc f("ddn") ds('"out_dsn"(index)') Shr Reuse"
        "Execio * diskw" ddn "(finis stem out."
        "Free  f("ddn")"

        exit 0

        set_ignore:
          /* --------------------------------------------------------- *
           * define all words to ignore other than 1 and 2 character   *
           * words which are already ignored........................   *
           *                                                           *
           * Note:                                                     *
           * each set statement must be less than 512 characters..     *
           * --------------------------------------------------------- */
        ignore_words = "THE AND FOR THAT HAVE",
                       "WITH ARE THIS NOT YOU BUT WILL WOULD USE",
                       "WHICH FROM TIME HAS OUR ABOUT ALL WHEN CAN ONE WAS",
                       "SHOULD GET THEY THAN UNDER ANY THERE MORE",
                       "USED HAD THESE NUMBER WHAT SOME ALSO INTO RUN BEEN",
                       "OTHER ABOVE NEW ONLY TWO HOW LIKE SAME DON FIX",
                       "NOW DOES MOST BECAUSE THEM THEN OUT YOUR KNOW MAY",
                       "ANYONE SET CHANGE SUCH MANY NEED VERY WERE JUST OFF"
        ignore_words = ignore_words,
                       "MAIN MUST MAKE LARGE PUT WORK YET DONE FOLLOWING",
                       "FOUND ITS PLEASE SEEMS SEE SINCE AFTER MUCH",
                       "AVAILABLE COULD EITHER ETC GOOD PEOPLE WHERE",
                       "THINK FIRST NAME OVER WAY WITHOUT BAD DURING WANT",
                       "WELL BEING BOTH DIFFERENT EACH GOT STILL TOO ANOTHER",
                       "BEFORE END EVEN LESS REALLY WHO ALLOW THEIR"
        ignore_words = ignore_words,
                       "USING RUNNING USER BACK CALL DOESN AM DID",
                       "LAST REAL USERS GOING APPEARS GETS TRY HERE",
                       "THINGS TRIED WHILE FIXES INSTEAD LOOK MADE WORKS",
                       "ELSE ENCOUNTERED FIXED HOWEVER NEVER RIGHT HAVEN",
                       "HELP SOMETHING CAUSED CHANGES DIDN INSTALLED",
                       "WORKING AGAIN DOWN FINE GETTING HAVING SURE THOSE",
                       "OLD WHY APPLIED CAUSE GIVE PROBABLY THANKS CAN LET",
                       "LONG LOOKS MIGHT SAY THING ANYTHING SAYS TRYING FEW",
                       "THROUGH AROUND CALLED DOING EXCEPT GOES LEAST"
        ignore_words = ignore_words,
                       "THOUGHT UNTIL ABLE ALWAYS AWAY HIS LATER LITTLE NEXT",
                       "YES ANYBODY FAR RATHER SEVERAL BETWEEN DAYS",
                       "NECESSARY READ SEEM TELL TOLD DAY TAKE WEEK ACTUALLY",
                       "CAUSES CHANGED CORRECT KEEP LOT USES AGO BELIEVE DUE",
                       "QUITE REASON WON FINALLY HAPPENS ISN NEEDED",
                       "NOTHING PLACE SENT CONTAINS FOLLOWS HAPPY INTERESTED"
        ignore_words = ignore_words,
                       "ONCE POSSIBLE UNIVERSITY WENT WORKED BETTER GIVEN",
                       "INCORRECT ISSUED OWN SEND THOUGHT TIMES WHETHER",
                       "ALONG ANYWAY BEST COMMENTS LEFT LONGER MAKES MAYBE",
                       "REQUIRED THREE APPARENTLY EXAMPLE EFFECT GIVES HARD",
                       "HIT HOPE LOOKING SOMEONE STARTED WRITTEN COME",
                       "CORRECTLY ENOUGH MEANS RAN RECEIVED RELATED SOON",
                       "TOOK TURNED SYSTEM"
        ignore_words = ignore_words,
                        "KEPT GOTTEN ACCOMPLISH PRESS SELECTIONS SELECTING",
                        "OBTAINING INTENT NEAR DERIVED EASILY VIDEO ALONE",
                        "CANNOT UPON COMES ELIMINATES PLACED WHOSE AFTERWARDS",
                        "OCCUR SIDES DESIRED READY WISH YOURSELF ONTO"

        return

        Please_Wait:
           Address ISPEXEC "Control Display Lock"
           Address ISPEXEC "Display Panel(RNEWWAIT)"
           return
