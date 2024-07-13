  IF PreferredListingDatasetType /= 'ELIB' THEN MODEL = 'NOTHING'
  $node = Node
  Node = 'LISTLIB LLISTLIB'
  PrimaryFct = '&Primary'
  SecondaryFct = '&Secondary'
  $delimiter = '$'
  ct2 = Substr($node,2,1) || STGNUM
