        /* ---------------------  rexx procedure  ---------------------- *
         * Name:      RNEWS                                              *
         *                                                               *
         * Function:  Present News and Information items for review      *
         *            by an ISPF user in tabular fashion along with      *
         *            providing an easy to use interface for adding      *
         *            the new items to the table.                        *
         *                                                               *
         * Syntax:    %RNEWS options.......                              *
         *                                                               *
         * required options are:                                         *
         *                                                               *
         *            KPIT     -  Kaiser Production ISPF News            *
         *                                                               *
         *            KSYS     -  Kaiser Systems ISPF News               *
         *                                                               *
         *            KTEST    -  Test news table                        *
         *                                                               *
         *            ....     -  others can be added to this exec       *
         *                        using one of the above as a model.     *
         *                                                               *
         * optional options are:                                         *
         *                                                               *
         *            ADMIN    -  Perform administrative functions       *
         *                        such as adding new items               *
         *                        (see code below for internal list of   *
         *                         authorized userids for this function) *
         *            DEBUG    -  Place the exec in rexx trace           *
         *            TEST     -  Use a test table data set              *
         *                        (see test dsn below)                   *
         *            NEW      -  Only display table if new items have   *
         *                        been added since last display          *
         *                        or unread items...................     *
         *                        See check_center processing below      *
         *                        (default is to display all items)      *
         *            FORCE    -  If the news data set is 'locked'       *
         *                        this will over-ride the lock.          *
         *                        (only useful for admin function)       *
         *            SHOW30   -  Only show news items for last 30       *
         *                        days. Read/Unread still apply.         *
         *                                                               *
         *                                                               *
         * Author:    Lionel B. Dyck                                     *
         *                                                               *
         * Dialog components:                                            *
         *                                                               *
         *        Panels:  defined by rexx variables below               *
         *        Skels:   defined by rexx variables below               *
         *        Msgs:    RNEW00                                        *
         *                                                               *
         * History:                                                      *
         *            12/18/07 add SHOW30 & getcut: code to allow        *
         *                   display of only recent news items (PJPoole) *
         *            06/21/00 change ISPTABL to ISPPROF DD usage        *
         *                   because of SCal ISPTABL usage               *
         *            05/31/00 fix ISPTABL allocation                    *
         *            03/30/99 change security to look for racf group    *
         *            09/18/97 Remove KINFO/KFHP Add KPIT                *
         *            04/28/95 Table title center/cleanup                *
         *            04/24/95 Added Kaiser tables                       *
         *                   removed intervening comments                *
         *            10/28/92 to 11/02/92 Creation of this application  *
         *                                                               *
         * Notes:                                                        *
         *                                                               *
         * 1.  There are 2 'system' ISPF tables used by this application *
         *     NEWS which contains information about each news item and  *
         *     ITEMTBL that contains the last item number assigned.      *
         * 2.  The application (AISC, ROCK, etc.) defines the set of     *
         *     ISPF panels and skeleton that will be used.               *
         * 3.  The news_id variable is suffixed with 'TBL' and a 1 row   *
         *     ISPF table is created in the user's ISPPROF data set.     *
         * 4.  Option NEW will check for NEW and Unread notices and if   *
         *     there are any will enter the news application.            *
         * 5.  The ADMIN function is controlled by the userids listed    *
         *     in variable admin_users.                                  *
         * 6.  Under ADMIN the NEWS and ITEMTBL tables are copied        *
         *     into a work data set under the users index to reduce      *
         *     the amount of time the table is locked.  A member in      *
         *     the news data set called LOCK is created to insure        *
         *     serialization in the update process.  This member is      *
         *     then deleted upon successful completion of the update.    *
         * 7.  All updates made under ADMIN are copied from the work     *
         *     data set into the production data set.  If the variable   *
         *     bdt_nodes is non-zero then all updates are sent using     *
         *     MVS/BDT to all of the specified bdt_nodes.                *
         * 8.  Add the following to the ISPCMDS command table to allow   *
         *                                                               *
         *     repeat find:                                              *
         *     '''' RFIND     0  &USRRFIND                               *
         *                          Rfind passthru variable              *
         *                                                               *
         * ------------------------------------------------------------- */
        arg options
        trace n
        /* ------------------------------------------------------------- *
         * Verify entry under ISPF Applid of ISP                         *
         * ------------------------------------------------------------- */
        if "ACTIVE" <> sysvar('sysispf') then do
           exit 0
           end
           else do
           Address ISPEXEC  "VGET ZAPPLID"
           if zapplid <> "ISP" then do
              cmd = sysvar('sysicmd')
              Address ISPEXEC,
                      "SELECT CMD(%"cmd options") NEWAPPL(ISP) PASSLIB"
              exit 0
           end
        end

        null = ""

        /* ------------------------------------------------------------- *
         *                                                               *
         * admin_dsn is a work data set used only during administration  *
         * functions to reduce the time the news data set is 'locked'.   *
         *                                                               *
         * ------------------------------------------------------------- */
        admin_dsn = sysvar(syspref)".WORKNEWS.TABLE"

        /* ------------------------------------------------------------- *
         * Customization variables that must be validated are:           *
         *                                                               *
         * panel          Normal user table display panel                *
         * admin_panel    Table panel for administration functions       *
         * browse_panel   Customized ISPF Browse panel                   *
         * edit_panel     Customized ISPF Edit panel                     *
         * ext_variable   Extension variable names (if any)              *
         *                                                               *
         * news_skeleton  ISPF File Tailoring skeleton                   *
         *                                                               *
         * admin_users    List of authorized administrators for news     *
         *                application                                    *
         *                                                               *
         * title          Title of the application                       *
         *                                                               *
         * news_id        4 character news category (e.g. AISC, ROCK)    *
         * news_dsn       Data set name of the News PDS                  *
         * admin_dsn      Data set name used by admin function to        *
         *                prevent locking real data set/table. Then      *
         *                copied into production data set/table.         *
         *                                                               *
         * news_loc       Centers to honor NEW option.                   *
         *                                                               *
         * check_center   null = do not check.                           *
         *                otherwise contains list of valid centers.      *
         *                (note: ALL is a valid center)                  *
         *                This variable causes verification of the       *
         *                center during Admin creation of a new item     *
         *                and during NEW processing only.  ALL items     *
         *                will be displayed if NEW is not requested.     *
         *                                                               *
         * bdt_nodes      MVS/BDT node names where updates are to be     *
         *                transmitted                                    *
         *                                                               *
         * Note: All dsn's are fully qualified without quotes in the     *
         *       variables.                                              *
         * ------------------------------------------------------------- */

        parse value null with news_id news_dsn bdt_nodes panel admin_panel,
                               browse_panel edit_panel news_skeleton,
                               admin_users check_center ext_variable expdate,
                               news_loc bdt_msg title

        /* "Showtso Center"  */

        if length(options) = 0 then do
           smsg = null
           lmsg = sysvar(sysicmd) "must be invoked with valid parameters",
                  "- try again"
           ADDRESS ISPEXEC "SETMSG MSG(RNEW000)"
           exit 0
           end
           else do    /* game on, we're doing something! */
             /* 3 variables to govern display of latest news only */
             window=30  /* number of days to show news */
             cut='99999'
             S30='N'
             if wordpos("SHOW30",options) > 0 then S30='Y'
             if wordpos("DEBUG",options) > 0 then trace i
             if wordpos("NDVR",options) > 0 then do
                         admin_users   = "ENDEVOR"
                         admin_dsn     = "PREV.NDVRNEWS.WTABLE"
                         news_dsn      = "PREV.NDVRNEWS.TABLE"
                         panel         = "RNEWTBL"
                         admin_panel   = "RNEWTBLA"
                         browse_panel  = "RNR$BRO"
                         edit_panel    = "RNR$EDT"
                         news_skeleton = "RNEWNDVR"
                         ext_variable  = "EXPDATE"
                         news_id       = "NDVR"
                         title         = "Endevor News and Information"
                         end
             if wordpos("KSYS",options) > 0 then do
                         admin_users   = "RACF"
                         admin_dsn     = "SYSL.SYSNEWS.WTABLE"
                         news_dsn      = "SYSL.SYSNEWS.TABLE"
                         panel         = "RNEWTBL"
                         admin_panel   = "RNEWTBLA"
                         browse_panel  = "RNR$BRO"
                         edit_panel    = "RNR$EDT"
                         news_skeleton = "RNEWKSYS"
                         ext_variable  = "EXPDATE"
                         news_id       = "KSYS"
                         title         = "KFHP Systems News and Information"
                         end
             if wordpos("KTEST",options) > 0 then do
                         admin_users   = "SYSLBD"
                         news_dsn      = "SYSLBD.TESTNEWS.TABLE"
                         panel         = "RNEWTBL"
                         admin_panel   = "RNEWTBLA"
                         browse_panel  = "RNR$BRO"
                         edit_panel    = "RNR$EDT"
                         news_skeleton = "RNEWKSYS"
                         ext_variable  = "EXPDATE"
                         news_id       = "KTST"
                         title         = "Test Systems News and Information"
                         end
             if length(news_dsn) = 0 then do
                        smsg = null
                        lmsg = "You have not requested a news application",
                               "- contact your systems administrator"
                        ADDRESS ISPEXEC "SETMSG MSG(RNEW000)"
                        exit 0
                        end
             if check_center <> null then do
                check_center = check_center "ALL"
                end
             if wordpos("FORCE",options) > 0 then force = "on"
             if wordpos("NEW",options)   > 0 then show_opt = "new"
                                             else show_opt = "all"
             if show_opt = "new" then do
                if news_loc <> null then
                   if wordpos(center,news_loc) = 0 then exit
                end
             if wordpos("TEST",options)  > 0 then do
                test = "on"
                news_dsn = sysvar(syspref)".TESTNEWS.TABLE"
                if sysdsn("'"news_dsn"'") <> "OK" then do
                   "Alloc ds('"news_dsn"') New Catalog Recfm(F B) Lrecl(80)",
                         "Dir(15) Blksize(0) Space(15,15) Tr"
                   "Free  ds('"news_dsn"')"
                   end
                end
             if wordpos("ADMIN",options) > 0 then do
                /* check if user has ndvr admin rights */
                resourcename = 'PREW.PROD.PMENU.ENVRMENT'
                classname    = 'FACILITY'
                a = outtrap('rescheck.','*')
                address tso "RESCHECK RESOURCE("resourcename") ,
                             CLASS("classname")"
                reschkrc = rc
                a = outtrap('off')
                /* end of ndvr admin rights check */
                select
                when admin_users = "RACF" then do
                   call outtrap "racf."
                   "LU" sysvar('sysuid')
                   call outtrap "off"
                   parse value racf.2 with " DEFAULT-GROUP=" group .
                   if wordpos(group,"RBMFBIEG") > 0 then
                      admin = "on"
                    if admin <> "on" then do
                        smsg = null
                        lmsg = "You are not authorized for this function"
                        ADDRESS ISPEXEC "SETMSG MSG(RNEW000)"
                        exit 0
                        end
                   panel = admin_panel
                   end
                when reschkrc = 0 then do
                   admin = "on"
                   panel = admin_panel
                   end
                when admin_users = "*" then do
                   admin = "on"
                   panel = admin_panel
                   end
                otherwise do
                        smsg = null
                        lmsg = "You are not authorized for this function"
                        ADDRESS ISPEXEC "SETMSG MSG(RNEW000)"
                        exit 0
                        end
                end
                end
             end

        /* ------------------------------------------------------------- *
         * Verify that the news_id is 4 characters of less...            *
         * ------------------------------------------------------------- */
        if length(news_id) > 4 then do
                        smsg = null
                        lmsg = "Severe Error with news_id -",
                               "contact your systems administrator"
                        ADDRESS ISPEXEC "SETMSG MSG(RNEW000)"
                        exit 0
                        end

        /* -------------------------- *
         * Center the title           *
         * -------------------------- */
         title = center(title,65,)

        /* ------------------------------------------------------------- *
         * Set the data set name variable for the news table d/s         *
         * ------------------------------------------------------------- */
        if admin <> "on" then
           active_dsn = news_dsn
           else
           active_dsn = admin_dsn

        if sysdsn("'"news_dsn"'") <> "OK" then do
           if show_opt = "new" then exit 0
           else do
                smsg = null
                lmsg = "The ISPF" news_id "News application is not supported",
                       "on this system."
                Address ISPEXEC
                call do_msg
                exit 0
                end
        end

        parse value '1 1 0 0 0' with crp rowcrp last_find new_counter,
                     prev_crp

        if admin = "on" then rowcrp = 0

        today = substr(date('S'),3)

        Address ISPEXEC
        "Control Errors Return"

        /* ------------------------------------------------------------- *
         * Open the users one row table containing news item status      *
         * ------------------------------------------------------------- */
        call TBOpen_User

        User_Display:
        do forever

        Redo:
        usrrfind = "PASSTHRU"
        "VPUT USRRFIND"
        zcmd = null
        if src = 4 then "TBDispl news"
           else do
                "TBTOP news"
                "TBSKIP news NUMBER("crp")"
                if rowcrp = 0 then
                   "TBDISPL news PANEL("panel")"
                   else
                   "TBDISPL news PANEL("panel")",
                           "CSRROW("rowcrp") AUTOSEL(NO)"
                end
        src = rc
        if ((src=8)&(S30='Y')) then do
           stay='N'
           "TBQuery NEWS Rownum("rownct")"
           "TBTOP news"
           Do i = 1 to rownct
              "TBSKIP news"
              if pos("Unread",Status) > 0 then stay='Y'
           end
           if stay='Y' then do
   say ""
   say ""
   say ""
   say ""
   say "          All unread news items MUST be read                   "
   say "You can view old news items by typing RNEWS on the command Line"
              src = 0
              signal redo
           end
        end

        Usrrfind = null
        "VPUT USRRFIND"

          if src > 4 then do
             if Changed <> "on" then
                signal Out_A_Here
                smsg = null
                lmsg = "You have changed the table - enter SAVE",
                       " to save it or Cancel to exit now"
                call do_msg
             end

        crp = ztdtop
        rowcrp = null

        if row <> null then
           if row > 0 then do
             "TBTop news"
             "TBSkip news NUMBER("row")"
             end

        zcmd_ok = null

        Select
          When words(Zcmd) > 1 then do
               parse value zcmd with o1 o2
               if abbrev("SEARCH",o1,1) = 1 then call Search_Table
               if abbrev("FIND",o1,1) = 1 then call Find_It
               if zcmd_ok <> "ok" then do
                  smsg = "Error"
                  lmsg = "Invalid command:" zcmd
                  "Setmsg Msg(RNEW000)"
                  end
               end
          When zcmd = "RFIND" then do
               zcmd = "RFIND" o2
               call Find_It
               end
          When abbrev("NEW",zcmd,1) = 1 then call Create_New_Item
          When abbrev("SAVE",zcmd,1) = 1 then call Save_It
          When abbrev("CANCEL",zcmd,1) = 1 then call Out_A_Here
          When length(zcmd) = 0 then do
             if row <> 0 then do
                  Select
                    When admin = "on" then select
                          When zsel = "D" then call Delete_It
                          When zsel = "S" then call Read_it
                          When zsel = "P" then call Print_it
                          otherwise nop;
                          end
                    When admin <> "on" then select
                          When zsel = "S" then call Read_it
                          When zsel = "X" then call Ignore_it
                          When zsel = "U" then call Unread_it
                          When zsel = "P" then call Print_it
                          otherwise nop;
                          end
                    otherwise nop;
                    end
               end
          end
          otherwise nop
        end

        signal User_Display

        Do_Admin:
        lockdd = "LOCK"random()

        if "OK" = sysdsn("'"news_dsn"(LOCK)'") then do
           if force <> "on" then do
           Address TSO,
             "Alloc f("lockdd") ds('"news_dsn"(LOCK)') Shr"
           Address TSO,
             "Execio * diskr "lockdd" (finis stem lock."
           Address TSO,
             "Free f("lockdd")"
           smsg = null
           lmsg = "The News Administration Fucntion is currently in",
                  "use by:" strip(lock.1) "Contact that individual to",
                  "verify when they will be done so you can proceed.",
                  "To over-ride just delete member 'LOCK' in the news",
                  "data set: '"news_dsn"'"
           call do_msg
           exit 0
           end
        end

        else do
           Address TSO,
             "Alloc f("lockdd") ds('"news_dsn"(LOCK)') Shr"
           lock. = null
           lock.0 = 0
           lock.1 = sysvar(sysuid) date('u') time('c')
           Address TSO,
             "Execio * diskw "lockdd" (finis stem lock."
           Address TSO,
             "Free f("lockdd")"
           end

        created_members = null

        if "OK" <> sysdsn("'"admin_dsn"'") then do
           Address TSO,
           "Alloc DS('"admin_dsn"') New Space(15,15) Dir(42) Tr",
           "Lrecl(80) Recfm(F B) Blksize(0)"
           Address TSO,
           "Free DS('"admin_dsn"')"
           end
           else do
                x = msg("OFF")
                Address TSO,
                  "Delete '"admin_dsn"(news)'"
                Address TSO,
                  "Delete '"admin_dsn"(itemtbl)'"
                x = msg("ON")
                end

        "LIBDEF PRDNEWS DATASET ID('"NEWS_dsn"')"
        "LIBDEF NEWS DATASET ID('"admin_dsn"')"

        "LMINIT DATAID(prdnews) DATASET('"news_dsn"') Enq(shr)"
        "LMInit Dataid(news)    DataSet('"admin_dsn"') Enq(shr)"

        "LMCopy FROMID("prdnews")",
               "TODATAID("news") FROMMEM(news) Replace"
        "LMCopy FROMID("prdnews")",
               "TODATAID("news") FROMMEM(itemtbl) Replace"

        "LMFREE Dataid("prdnews")"
        "LMFREE Dataid("news")"

        tbopen:
        "TBOPEN NEWS LIBRARY(NEWS) WRITE"
          If rc <> 0 Then               /* Return codes                     */
            Select                      /*  8 - Table does not exist        */
            When rc = 8 then do
               "TBCreate news Keys(item)",
                        "Names(Subject Member Status Date Author Centers)",
                        "Library(news) Write"
               "TBSort   news Fields(item,N,D)"
               "TBSAVE news REPLCOPY LIBRARY(news)"
               call Create_New_Item
               end
            When rc = 12 then do        /* 12 - Table in use; enq failed    */
               if open_sw <> "on" then do
                  "TBCLOSE news ReplCopy Library(News)"
                  open_sw = "on"
                  signal tbopen
                  end
               smsg = null
               lmsg = news_id "News Table ("active_dsn") in use - try later"
               "Setmsg Msg(RNEW000)"
               "LIBDEF PRDNEWS"
               "LIBDEF NEWS"
               exit 0
               end
            When rc > 12 then do        /* 16 - Input library not allocated */
               smsg = null              /* 20 - Severe error                */
               lmsg = news_id "News Error - Contact System Support"
               "Setmsg Msg(RNEW000)"
               "LIBDEF PRDNEWS"
               "LIBDEF NEWS"
               exit 0
               end
            otherwise nop;
            End
        open_sw = null
        text = null

        return

        /* ------------------------------------------------------------- *
         * Individual processing sub-routines follow:                    *
         *                                                               *
         * General routines:                                             *
         * Find_It         -  Find an item                               *
         * Ignore_It       -  Flag an item as Ingored                    *
         * Print_It        -  Print an item                              *
         * Read_It         -  Read an item                               *
         * Unread_It       -  Flag item as Unread                        *
         * Search_Table    -  Search all items for character string      *
         * Do_Msg          -  issue ispf setmsg                          *
         * check_center_names - verifies center names if check_center on *
         * check_expire_date  - see if expdate variable in table         *
         * TBOpen_User     -  Opens the user item table                  *
         * Read_Index      -  Reads the word index for the Search option *
         * Out_A_Here      -  Exit routine                               *
         *                                                               *
         * ------------------------------------------------------------- *
         * Admin routines:                                               *
         * Create_New_Item - Create a New Item                           *
         * Delete_It       -  Deletes an item                            *
         * Save_It         -  Save the News Table                        *
         * Get_Item_ID     -  gets the next item number                  *
         *                                                               *
         * ------------------------------------------------------------- */

        /* ------------------------------------------------------------- *
         * Delete_it routine used by the administrator to remove items   *
         * from the news and information table and also delete the       *
         * item from the news data set.                                  *
         * ------------------------------------------------------------- */
        Delete_it:
            "LMINIT DATAID(dataid) DATASET('"news_dsn"') ENQ(SHRW)"
            "LMOPEN DATAID("dataid") OPTION(OUTPUT)"
            "LMMDEL DATAID("dataid") MEMBER("member")"
            "LMCLOSE DATAID("dataid")"
            "LMFREE DATAID("dataid")"
            "TBDelete news"
        return

        /* ------------------------------------------------------------- *
         * Find_it routine to search the table subject entries for the   *
         * specified character string.  The search is done using         *
         * REXX instead of using the ISPF TBSCAN which is very limited.  *
         * ------------------------------------------------------------- */
        Find_It:
           zcmd_ok = "ok"
           parse value zcmd with o1 argument
           find_argument = argument
           upper argument
           argument = strip(argument)
           zsel = null
           crp = ztdtop
           rowid = crp
           start_crp = crp
           find_loop = null
           search = null
           if o1 = "RFIND" then do
              if prev_crp <> start_crp then last_find = start_crp
              last_find = last_find + 1
              "TBTOP  news"
              "TBSKIP news     Position(ROWID) Number("Last_find")"
              end
              else do
                   "TBSKIP news     Position(ROWID) Number("start_crp")"
                   end
           if rc = 8 then do
                          s_smsg = find_argument "Found Wrapped"
                          "TBTOP  news"
                          "TBSKIP news     Position(ROWID)"
                          end
                     else s_smsg = find_argument "Found"

           /* perform search */

           do forever
              search = translate(subject)
              if pos(argument,search) > 0 then do
                 crp = rowid + 0
                 rowcrp = crp
                 last_find = crp
                     smsg = s_smsg  /* "Found" */
                     lmsg = find_argument "found during search in row:" crp
                     call do_msg
                 prev_crp = start_crp
                 return
                 end
              "TBSKIP news POSITION(Rowid)"
              if rc = 8 then do
                    "TBTOP news"
                     s_smsg = find_argument "Found Wrapped"
                 if find_loop = "on" then do
                     smsg = find_argument "Not Found"
                     lmsg = find_argument "Not found during search"
                     rowid = crp
                     call do_msg
                     prev_crp = start_crp
                     return
                     end
                     else find_loop = "on"
                 end
              zsel = null
              end
        return

        Search_Table:
           zcmd_ok = "ok"
           argument = translate(o2)
           argument = strip(argument)
           parse value null with zsel show_opt smsg lmsg,
                       hit hit_items
           src    = 0
           crp    = 1
           rowcrp = 0
           hits   = 0
          "TBEnd news "
          call tbopen_user
          call read_index
          if words(word.argument) = 0 then do
             lmsg = "The requested word" argument "was not found.",
                    "All items displayed."
             end
          else do
             hit = wordindex(word.argument,2)
             hit_items = strip(substr(word.argument,hit))
            "TBTop news "
            "TBSkip news"
             do forever
                if wordpos(member,hit_items) = 0 then do
                   "TBDelete news"
                   end
                   else hits = hits + 1
                "TBSkip news"
                if rc > 0 then leave
                end
             lmsg = "The requested word" argument "was found in",
                    "the" hits "displayed items."
             end
        call do_msg
        "TBTop news"
        return

        /* ------------------------------------------------------------- *
         * Ignore_it routine to flag an item as Ignored.                 *
         * ------------------------------------------------------------- */
        Ignore_it:
           if admin <> "on" then do
              x = pos(" "item"/",text)
              l = length(item"/X")
              text = overlay(item"/X",text,x+1,l)
              call Save_User
              end
           status = "Ignored"
           if show_opt = "new" then do
             "TBDelete news"
             new_counter = new_counter - 1
             if new_counter = 0 then signal Out_A_Here
             end
           else do
                if ext_variable = null then
                   "TBMOD news"
                   else "TBMOD News Save("ext_variable")"
                   end
        return

        /* ------------------------------------------------------------- *
         * Print_it routine to print the selected news item.             *
         *                                                               *
         * ISPF file tailoring is used to include the subject, etc.      *
         * as a title for the printed item.                              *
         *                                                               *
         * File tailoring is used to a data set allocated by this        *
         * application of the format userid.NEWS.item.REPORT which       *
         * is deleted after printing.                                    *
         *                                                               *
         * The Rockwell RPRINT generalized print application is used     *
         * to do the actual printing.                                    *
         * ------------------------------------------------------------- */
        Print_it:
           if admin <> "on" then do
              x = pos(" "item"/",text)
              l = length(item"/R")
              text = overlay(item"/R",text,x+1,l)
              end
           "Libdef ISPSLIB Dataset Id('"active_dsn"')"
           report_dsn = "'"sysvar(syspref)".NEWS."member".REPORT'"
           Address TSO,
             "Allocate F(ISPFILE) DS("report_dsn") NEW Reuse",
             "Recfm(F B) Lrecl(80) Blksize(0) Space(2,2) Tr"
           "FTOpen"
           "FTIncl" news_skeleton
           "FTClose"
           "Libdef ISPSLIB"
           "Control Display Save"
           "Select CMD(%KPRINT" report_dsn ")"
           "Control Display Restore"
           msg_opt = msg()
           x = msg("OFF")
           Address TSO,
              "Free f(ISPFILE)"
           Address TSO,
              "Delete" report_dsn
           x = msg(msg_opt)
           status = "Printed"
           if ext_variable = null then
              "TBMOD news"
              else "TBMOD News Save("ext_variable")"
        return

        /* ------------------------------------------------------------- *
         * Read_it routine to use ISPF Browse to view the selected       *
         * news and information item.  The browse uses a customized      *
         * ISPF Browse Panel to allow the display of subject, etc.       *
         * for the user as that information is not part of the item      *
         * text.                                                         *
         * ------------------------------------------------------------- */
        Read_it:
           if admin <> "on" then do
              x = pos(" "item"/",text)
              l = length(item"/R")
              text = overlay(item"/R",text,x+1,l)
              call Save_User
              end
           "TBGET news"
           "Control Display Save"
           "Browse Dataset('"active_dsn"("member")') Panel("browse_panel")"
           "Control Display Restore"
           status = "Read"
           if ext_variable = null then
              "TBMOD news"
              else "TBMOD News Save("ext_variable")"
        return

        /* ------------------------------------------------------------- *
         * Unread_it routine will flag an item in the users news item    *
         * tracking table as unread so that it will cause the display    *
         * of the table when next invoked using the NEW keyword.         *
         * ------------------------------------------------------------- */
        Unread_it:
           if admin <> "on" then do
              x = pos(" "item"/",text)
              l = length(item"/U")
              text = overlay(item"/U",text,x+1,l)
              call Save_User
              end
           status = "Unread"
           if ext_variable = null then
              "TBMOD news"
              else "TBMOD News Save("ext_variable")"
        return

        /* ------------------------------------------------------------- *
         * Save_it routine.  This routine is used by the Administration  *
         * function to save the updated news table and then copy the     *
         * updated NEWS, ITEMTBL and items from the work data set into   *
         * the production data set.  If bdt_nodes is defined then        *
         * MVS/BDT is invoked to transmit the updates to the specified   *
         * other locations.                                              *
         *                                                               *
         * Before the MVS/BDT is processed the index of key words is     *
         * built using the RNEWKEY exec.                                 *
         *                                                               *
         * ------------------------------------------------------------- */
        Save_it:
           if admin <> "on" then do
              smsg = null
              lmsg = "Error: Command SAVE is not allowed"
              call do_msg
              return
              end
           "TBSAVE news REPLCOPY LIBRARY(news)"
           "LMINIT DATAID(prdnews) DATASET('"news_dsn"') Enq(shr)"
           "LMInit Dataid(news)    DataSet('"admin_dsn"')"
           if length(created_members) > 0 then
              do new_count = 1 to words(created_members)
                "LMCopy ToDATAID("prdnews")",
                       "FromID("news")",
                       "FROMMEM("word(created_members,new_count)")",
                       "ToMEM("word(created_members,new_count)")",
                       " Replace"
                 end
           "LMCopy ToDATAID("prdnews")",
                  "FromID("news") FROMMEM(news) ToMem(news) Replace"
           "LMCopy ToDATAID("prdnews")",
                  "FromID("news") FROMMEM(itemtbl) ToMem(itemtbl) Replace"
           "Select Cmd(%RNEWSKEY '"news_dsn"' '"admin_dsn"')"
           "LMCopy ToDATAID("prdnews")",
                  "FromID("news") FROMMEM(index) ToMem(index) replace"
           "LMFREE Dataid("prdnews")"
           "LMFREE Dataid("news")"
           if length(bdt_nodes) > 0 then do
              call bdt_change
              bdt_msg = "Updates sent to nodes:" bdt_nodes
              end
           smsg = null
           lmsg = "News Table saved and copied into production data set.",
                  "Members updated were:" created_members"." bdt_msg
           call do_msg
           Changed = null
           created_members = null
        return

        /* ------------------------------------------------------------- *
         * Save_user routine will save the users item tracking table     *
         * after each items status is changed.                           *
         * ------------------------------------------------------------- */
        Save_User:
           if admin = "on" then return
           "TBPUT" news_id"TBL"
           "TBSAVE "news_id"TBL REPLCOPY Library(ISPPROF)"
           return

        /* ------------------------------------------------------------- *
         * Do_msg routine is used to issue the ISPF Message....          *
         * ------------------------------------------------------------- */
        Do_Msg:
           "Setmsg Msg(RNEW000)"
        return

        /* ------------------------------------------------------------- *
         * Create_new_item routine.                                      *
         *                                                               *
         * this routine is invoked by the administration function to     *
         * create new news and information items.  A customized ISPF     *
         * Edit panel is used to prompt for the subject, etc.            *
         *                                                               *
         * The member name is determined by the item number.             *
         * ------------------------------------------------------------- */
        Create_New_Item:
           if admin <> "on" then do
              smsg = null
              lmsg = "Error: Command NEW is not allowed"
              call do_msg
              return
              end
           "TBSORT news Fields(item,N,D)"
           "TBTop news"
           "TBSkip news"
           call Get_Item_id
           date   = date('U')
           Status = "New"
           Member = "N"right(item+100000,5)
           Subject = item": "
           "Control Display Save"
           do forever
            "Edit Dataset('"active_dsn"("member")') Panel("edit_panel")",
            "Macro(RnewEM)"
               if rnewsend = "CANCEL" then leave
               if check_center = null then leave
                  else call check_center_names
               if check_rc = 0 then leave
                  else do
                       smsg = null
                       lmsg = null
                       if check_rc = 1 then
                          lmsg = "Verify centers and then save again.",
                                 "Valid centers:" check_center
                       if check_rc = 2 then
                          lmsg = lmsg "Verify expiration date format mm/dd/yy"
                       call do_msg
                       end
             end
           "Control Display Restore"
            "VGET (RNEWSEND)"
            if rnewsend = "CANCEL" then do
              smsg = "Cancelled"
              lmsg = "Creation of new NEWS item has been cancelled"
              "Setmsg Msg(RNEW000)"
              end
           else do
              if ext_variable = null then
                "TBAdd news Order"
                else
                "TBAdd news Order Save("ext_variable")"
              created_members = created_members member
              Changed = "on"
              smsg = "OK"
              lmsg = "Creation of new NEWS item was successful",
                     "- don't forget to save the table"
              "Setmsg Msg(RNEW000)"
              end
        return

        /* ------------------------------------------------------------- *
         * Bdt_change routine                                            *
         *                                                               *
         * Used by the administration function to transmit updates to    *
         * other locations using MVS/BDT.                                *
         * ------------------------------------------------------------- */
        Bdt_change:
        created_members = strip(created_members)
        bdt_item = strip("NEWS ITEMTBL INDEX" created_members)
        bdt_item = translate(bdt_item,","," ")
        Address TSO
        do bdt = 1 to words(bdt_nodes)
        if test /= "on" then
         "BDT Q FROM DS('"news_dsn"') SHR Dap(PDS) Parm(r=y s m=("bdt_item"))",
            " TO   DS('"news_dsn"') SHR Dap(PDS) LOC("word(bdt_nodes,bdt)")"
        else
        say  "BDT Q FROM DS('"news_dsn"') SHR Dap(PDS)",
            "Parm(r=y s m=("bdt_item"))",
            " TO   DS('"news_dsn"') SHR Dap(PDS) LOC("word(bdt_nodes,bdt)")"
           end
        Address ISPEXEC
        return

        /* ------------------------------------------------------------- *
         * Get_item_id routine.  Used by the administation function to   *
         * get the next item number for new items.                       *
         * ------------------------------------------------------------- */
        Get_Item_ID:
         "TBOPEN ITEMTBL LIBRARY(NEWS) WRITE"
          If rc <> 0 Then               /* Return codes                     */
            Select                      /*  8 - Table does not exist        */
            When rc = 8 then do
               "TBCreate Itemtbl",
                        "Names(Itemnum)",
                        "Library(news) Write"
               itemnum = 1
               "TBADD    Itemtbl"
               "TBCLOSE  Itemtbl Replcopy Library(news)"
               item = itemnum
               return
               end
            When rc = 12 then do        /* 12 - Table in use; enq failed    */
               if open_sw <> "on" then do
                  "TBCLOSE Itemtbl Replcopy Library(news)"
                  open_sw = "on"
                  signal get_item_id
                  end
               smsg = null
               lmsg = news_id "News Table in use - try later"
               "Setmsg Msg(RNEW000)"
               "LIBDEF NEWS"
               exit 0
               end
            When rc > 12 then do        /* 16 - Input library not allocated */
               smsg = null              /* 20 - Severe error                */
               lmsg = news_id "News Error - Contact System Support"
               "Setmsg Msg(RNEW000)"
               "LIBDEF NEWS"
               exit 0
               end
            otherwise nop;
            End
        "TBSkip   Itemtbl"
        itemnum = itemnum + 1
        item = itemnum
        "TBPUT    Itemtbl"
        "TBCLOSE  Itemtbl Replcopy Library(news)"
        open_sw = null
        return

        Tbopen_User:
        /* ------------------------------------------------------------- *
         * Tbopen_User:                                                  *
         *                                                               *
         * This routine opens and reads the users item table             *
         * ------------------------------------------------------------- */
        if admin = "on" then call Do_Admin
           else do
        "TBOPEN "news_id"TBL Library(ISPPROF) WRITE"
            Select
            when rc = 0 then "TBSkip" news_id"TBL"
            when rc = 8 then do         /*  8 - Table does not exist    */
               call log_user   /* add user to new user list          */
               ADDRESS ISPEXEC "display panel(welcome)"
               "TBCreate "news_id"TBL Names(Text) Write",
                         "Library(ISPPROF)"
               text = null
               item = null
               "TBADD" news_id"TBL"
               "TBSAVE "news_id"TBL REPLCOPY Library(ISPPROF)"
               show_opt = "all" /* first time */
               end
            when rc = 12 then do          /* 12 - Table in use; enq failed  */
               if open_sw <> "on" then do
                  "TBCLOSE" news_id"TBL Library(ISPPROF)"
                  open_sw = "on"
                  signal tbopen_user
                  end
               smsg = null
               lmsg = news_id "User News Table in use - try later"
               "Setmsg Msg(RNEW000)"
               exit 0
               end
            when rc > 12 then do        /* 16 - Input library not allocated */
               smsg = null              /* 20 - Severe error                */
               lmsg = news_id "News Error - Contact System Support"
               "Setmsg Msg(RNEW000)"
               exit 0
               end
            otherwise nop;
            End
            open_sw = null

           call check_uid /* Check that the OMVS segment is set up   */

           "LIBDEF NEWS    DATASET ID('"active_dsn"')"

           "TBCLOSE NEWS"
           "TBOPEN NEWS LIBRARY(NEWS) NOWRITE SHARE"

          /* --------------------------------------------------------- *
           * Get the highest item number for new checking.             *
           * --------------------------------------------------------- */
           "TBOPEN ITEMTBL LIBRARY(NEWS) NOWRITE SHARE"
           "TBSkip ITEMTBL"
            high_item = itemnum
           "TBEnd ITEMTBL"
        end

        /* ------------------------------------------------------------- *
         * Process for display only NEW items:                           *
         *                                                               *
         * Check the high_item value with the users table and if it is   *
         * found then exit as we have seen all items..........           *
         * ------------------------------------------------------------- */
        if show_opt = "new" then
           select
           when pos(high_item"/",text) = 0 then nop
           when pos("/U",text) > 0 then nop
           otherwise  call Out_A_Here
           end

        /* ------------------------------------------------------------- *
         * The table is sorted by item number in descending order        *
         * so the newest is on the top of the display...............     *
         * ------------------------------------------------------------- */
        "TBTop  news"
        "TBSkip news"

        /* ------------------------------------------------------------- *
         * If not admin then update each table row with the status from  *
         * the users item status table.                                  *
         *                                                               *
         *    /E = Expired                                               *
         *    /N = Not Applicable                                        *
         *    /R = Read                                                  *
         *    /U = Unread                                                *
         *    /X = Ignored                                               *
         * ------------------------------------------------------------- */
        if admin <> "on" then do
           if S30='Y' then call getcut /* only set cut if we care */
           "TBQuery NEWS Rownum("rownews")"
           all_rows = rownews
           Do i = 1 to rownews
              Select
                 when pos(" "item"/",text) > 0 then do
                    x = pos(" "item"/",text)
                    l = length(" "item"/")
                    status = substr(text,x+l,1)
                    end
                 when pos(" "item"/",text) = 0 then do
                      status = "New"
                      text = text item"/U"
                      end
                 otherwise nop;
              end
              Select
                 When status = "R" then status = "Read"
                 When status = "X" then status = "Ignored"
                 When status = "U" then status = "Unread"
                 When status = "N" then status = "NotAppl"
                 When status = "E" then status = "Expired"
                 otherwise nop;
              end
          /* --------------------------------------------------------- *
           * if NEWS option then do not display 'old' items...         *
           * --------------------------------------------------------- */
              if show_opt = "new" then do
                 tgt='Unread New'
                 kill='N'
                 if wordpos(status,tgt)=0 then kill='Y'
                 if ((S30='Y')&(item<cut)) then kill='Y'
                 if kill='Y' then do
                    "TBDelete news"
                    all_rows = all_rows - 1
                 end
                 else do
                    check_rc = 0
                    if check_center <> null then
                             call check_center_names
                    call check_expire_date
                    if check_rc = 0 then do
                       new_counter = new_counter + 1
                       if ext_variable = null then
                                  "TBMOD news"
                       else "TBMOD News Save("ext_variable")            "
                    end
                    if check_rc > 0 then do
                       "TBDelete news"
                        all_rows = all_rows - 1
                    end
                 end
              end
              else do
                 if ext_variable = null then
                       "TBMOD news"
                 else "TBMOD News Save("ext_variable")"
              end
              "TBSkip news"
           end  /* do i=1 to rownews */
        call Save_User
        end /* end do for admin <> "on" */

        if all_rows = 0 then signal Out_A_Here

        "TBSort news Fields(item,N,D)"
        "TBTop news"

        return

        check_center_names:
        /* ------------------------------------------------------------- *
         * check_center_names:                                           *
         *                                                               *
         * This routine will verify that the center names entered in     *
         * the centers variable are supported (for the Admin function)   *
         * and if the item should be displayed on this center.           *
         *                                                               *
         * check_rc = 0 if all is OK otherwise it is 1.                  *
         * ------------------------------------------------------------- */
        upper centers
        if admin = "on" then do
           total_centers = words(centers)
           check_rc = 0
           do loc = 1 to total_centers
              locx = word(centers,loc)
              if wordpos(locx,check_center) = 0 then check = 1
              end
           end
        else if show_opt <> "new" then do
        if wordpos(center,centers) = 0 then do
                    check_rc = 1
                    x = pos(" "item"/",text)
                    l = length(item"/N")
                    text = overlay(item"/N",text,x+1,l)
                    call Save_User
                    end
           end
        return

        check_expire_date:
        /* ------------------------------------------------------------- *
         * check_expire_date:                                            *
         *                                                               *
         * This routine will see if the EXPDATE variable is defined      *
         * in the ext_variable in the ISPF Table.  If so, then it will   *
         * be validated for Admin function and for New will determine    *
         * if the item has expired.                                      *
         *                                                               *
         * Invalid or Expired will cause check_rc to be set to 2         *
         * otherwise it will be unchanged.                               *
         *                                                               *
         * ------------------------------------------------------------- */
         if wordpos("EXPDATE",ext_variable) = 0 then return
         if length(expdate) = 0 then do
            if admin = "on" then
               check_rc = 2
            return
            end
         if datatype(expdate) <> "NUM" then do
            check_rc = 2
            return
            end
         parse value expdate with mm "/" dd "/" yy
         if mm = null then check_rc = 2
         if dd = null then check_rc = 2
         if yy = null then check_rc = 2
         if dd > 31 then check_rc = 2
         if mm > 12 then check_rc = 2
         if check_rc = 2 then return
         if admin = "on" then return
         dd = 100 + dd
         mm = 100 + mm
         item_date = yy""substr(mm,2,2)""substr(dd,2,2)
         if item_date < today then do
              check_rc = 2
              x = pos(" "item"/",text)
              l = length(item"/E")
              text = overlay(item"/E",text,x+1,l)
              end
         return

        read_index:
        /* ------------------------------------------------------------- *
         *  This routine reads the words from the index for use with     *
         *  the SEARCH command.                                          *
         * ------------------------------------------------------------- */
         if read_index = "on" then return
                              else read_index = "on"
         index_dd = "Index"random()
         Address TSO
         "Alloc f("index_dd") ds('"news_dsn"(INDEX)') Shr Reuse"
         "Execio * diskr" index_dd "(Finis Stem index."
         "Free f("index_dd")"
         Address ISPexec
         word. = null
         do idx_count = 1 to index.0
            word = word(index.idx_count,1)
            if length(word.word) = 0 then
               word.word = index.idx_count
               else
               word.word = word.word index.idx_count
            end
        drop index.
        return

/* routines to set up selection of latest news items only */

getcut:
tday=date(J)
tyy=substr(tday,1,2)
tjjj=substr(tday,3,3)
if tjjj>window then cutdate=right(tday-window,5,0)
else do
   days=window-tjjj
   lyy=tyy-1
   ldays=365
   if lyy//4=0 then ldays=366
   ljjj=right(ldays-days,3,0)
   cutdate=right(lyy||ljjj,5,0)
end
"LMINIT DATAID("DVAR")  DATASET('"news_dsn"') ENQ(SHR)"
"LMOPEN  DATAID("DVAR")  OPTION(INPUT)"
"LMMLIST  DATAID("DVAR")  OPTION(SAVE) GROUP(NDVRSH30)"
"LMCLOSE  DATAID("DVAR")"
"LMFREE  DATAID("DVAR")"
address ispexec "VGET (ZPREFIX)"
pref = zprefix
indsn=pref||'.'||USERID()||'.NDVRSH30.MEMBERS'
Address tso "ALLOC FI(infil) DA('"indsn"') SHR"
Address tso "EXECIO * DISKR infil (STEM lin. FINIS)"
Address tso 'FREE FI(infil)'
mdays.1=31
mdays.3=31
mdays.4=30
mdays.5=31
mdays.6=30
mdays.7=31
mdays.8=31
mdays.9=30
mdays.10=31
mdays.11=30
mdays.12=31
do j=lin.0 to 1 by -1
   newsno=word(lin.j,1)
   moddate=word(lin.j,4)
   nyy=substr(moddate,1,2)
   mdays.2=28
   if nyy//4=0 then mdays.2=29
   nmm=substr(moddate,4,2)
   ndd=substr(moddate,7,2)
   if nmm='01' then njjj=right(ndd,3,0)
   else do
      njjj=0
      do k=1 to nmm-1
         njjj=njjj+mdays.k
      end
      njjj=right(njjj+ndd,3,0)
   end
   ndate=right(nyy||njjj,5,0)
   if ndate<cutdate then leave
   cut=substr(newsno,2,5)
end
cut=strip(cut,'L','0')
call outtrap "junk."
Address TSO "Delete '"indsn"'"
call outtrap "off"
return

/* end of routine to set up selection of latest news items only */


        /* ------------------------------------------------------------- *
         * Out_a_here routine.   This is where everything comes to an    *
         * end (as all good things must).............................    *
         * ------------------------------------------------------------- */
        Out_A_Here:
        if admin <> "on" then do
           "TBSAVE "news_id"TBL REPLCOPY Library(ISPPROF)"
           "TBCLOSE" news_id"TBL Library(ISPPROF)"
           end
        else do
            "LMINIT DATAID(dataid) DATASET('"news_dsn"') ENQ(SHRW)"
            "LMOPEN DATAID("dataid") OPTION(OUTPUT)"
            "LMMDEL DATAID("dataid") MEMBER(LOCK)"
            "LMCLOSE DATAID("dataid")"
            "LMFREE DATAID("dataid")"
            "LIBDEF PRDNEWS"
           end
        "TBEnd news "
        "LIBDEF NEWS"
        exit 0

/*-------------------------------------------------------------------*/
/* Record new users to add to # endevor users                        */
/*-------------------------------------------------------------------*/
Log_user:

 null = outtrap('output.',1)
 address tso "lu"
 line = left(output.1,pos(' OWNER=',output.1))
 name = substr(word(line,2),6) subword(line,3)
 outlook_name = word(name,(words(name)))',' ,
                subword(name,1,words(name)-1)
 usr.1 = left(outlook_name,40) left(sysvar(sysuid),8) date(s)
 /* This first file will be cleared down manually once the welcome   */
 /* email is sent and the user added to # endveor users              */
 address tso "alloc f(out) dsname('TTEV.TMP.NEW.USERS') mod"
 address tso "execio 1 diskw out (stem usr. finis"
 address tso "free fi(out)"
 /* This second file is a permanent log file.                        */
 address tso "alloc f(out) dsname('TTEV.TMP.NEW.USERS.LOG') mod"
 address tso "execio 1 diskw out (stem usr. finis"
 address tso "free fi(out)"
 null = outtrap('off')

return /* Log_user: */

/*-------------------------------------------------------------------*/
/* Check that the uid/omvs segment is set up correctly               */
/*-------------------------------------------------------------------*/
Check_uid:

 null = outtrap('output.')
 address tso "lu" userid() "NORACF OMVS"
 null = outtrap('off')
 do iii = 1 to output.0
   if subword(output.iii,1,2) = 'UID= NONE'           | ,
      subword(output.iii,1,3) = 'NO OMVS INFORMATION' then do
     /* Display the panel with instructions.                       */
     address ispexec "display panel(nouid)"
     /* Log the user.                                              */
     usr.1 = left(sysvar(sysuid),8) date(s)
     null = outtrap('xx.')
     address tso "alloc f(out) dsname('TTEV.TMP.BAD.UID') mod"
     address tso "execio 1 diskw out (stem usr. finis"
     address tso "free fi(out)"
     null = outtrap('off')
     leave
   end /* word(output.i,1) = 'UID=' */
 end /* iii = 1 to output.0 */

return /* Check_uid: */
