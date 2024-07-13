If NewTbl /= 'Y' then $SkipRow = 'Y'
If ElemTble = ' ' then $SkipRow = 'Y'
UsingDataSetClause1 = "USING DSN ''" || UsingDataSet1 || "''"
If UsingDataSet1 = ' ' then UsingDataSetClause1 = ' '
UsingDataSetClause2 = "          ''" || UsingDataSet2 || "''"
UsingDataSetClause3 = "USING DSN ''" || UsingDataSet2 || "''"
If UsingDataSet1 = ' ' then UsingDataSetClause2 = UsingDataSetClause3
If UsingDataSet2 = ' ' then UsingDataSetClause2 = ' '
If UsingDataSet2 = ' ' then UsingDataSetClause3 = ' '
If DB2 /= 'Y' then A = Overlay('*',A,1,2,' ')
If IDMS /= 'Y' then B = Overlay('*',B,1,2,' ')
If IMS /= 'Y' then C = Overlay('*',C,1,2,' ')
If TOTAL /= 'Y' then D = Overlay('*',D,1,2,' ')
If DB2 = 'Y' then A = Overlay(' ',A,1,2,' ')
If IDMS = 'Y' then B = Overlay(' ',B,1,2,' ')
If IMS = 'Y' then C = Overlay(' ',C,1,2,' ')
If TOTAL = 'Y' then D = Overlay(' ',D,1,2,' ')
