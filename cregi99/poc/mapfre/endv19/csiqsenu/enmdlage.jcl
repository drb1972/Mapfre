 GENERATE ELEMENT "        "
)N        THROUGH "<THRUNAME>"
     FROM ENV     "        " STAGE NUM "1"
          SYS     "        " SUBSYSTEM "        " TYPE "        "
)N
)N USE "MD" LINE COMMANDS TO CONVERT REQUIRED OPTIONS TO VALID SCL
)N NOTE: WHERE KEYWORDS ARE GROUPED, PICK ONE LINE ONLY E.G. SPAN
)N
)N  OPTION
)N    CCID    "            "
)N    COMMENT "                                        "
)N
)N    OVERRIDE SIGNOUT
)N
)N    PROCESSOR GROUP EQ GROUP NAME
)N
)N      COPYBACK
)N      NOSOURCE
)N
)N      SEARCH
)N      NOSEARCH
)N
)N    AUTOGEN
)N      SPAN NONE
)N      SPAN ALL
)N      SPAN SYSTEMS
)N      SPAN SUBSYSTEMS
)N
)N  WHERE
)N    CCID
)N      OF CURRENT  EQUAL <CCID>
)N      OF ALL      EQ   (<CCID1>, <CCID2>, <CCID3>)
)N      OF RETRIEVE =     <CCID>
)N    PROCESSOR GROUP EQUAL <PG>
    .
