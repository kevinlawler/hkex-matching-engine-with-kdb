/ Matching Engine for HKEx
/ Last Modified: Jan 20, 2015
/ Created by: Raymond Sak, Damian Dutkiewicz


/ 1. Create dummy trades for testing

s:(),`FDP,`HSBC,`GOOG,`APPL,`REYA;
px:(),5,80,780,120,45;
st:09:00:00.000;
ot:`limit; /`auction

/ CreateData: Create random trade orders
CreateData:{[n]
    dict:s!px;orderID:n?1000000000;sym:n?s;side:n?`bid`offer;
    orderType:ot;price:((+;-)side=`bid) .'flip(dict sym;.050*n?1+til 10);
    sample:flip`orderID`time`sym`side`orderType`price`quantity! (orderID;st+n?25200000;sym;side;orderType;price;100*n?1+til 10)
  }; /orderType:n?ot

/ 2. Create bid, ask, trade, rejected book

book:([]orderID:`int$();time:`time$();sym:`$();side:`$();orderType:`$();price:`float$();quantity:`int$());
bidbook:`sym xasc `price xdesc `time xasc `orderID xkey book;
askbook:`sym`price`time xasc `orderID xkey book;
tradebook:`tradeID xkey ([]tradeID:`int$();orderID:`int$();time:`time$();sym:`$();side:`$();orderType:`$();price:`float$();quantity:`int$());
rejectedbook:([]orderID:`int$();time:`time$());


/ 3. Handle incoming message
testMessage: "8=FIX.4.4|9=178|37=00001|52=09:00:00.000|55=APPL|54=1|44=239.5|14=100";

/fixTagToName:`1`6`8`9`10`11`12`13`14`15`17`19`21`29`30`31`32`34`35`37`38`39`49`52`54`56`151!`Account`AvgPx`BeginString`BodyLength`CheckSum`ClOrdID`Commission`CommType`CumQty`Currency`ExecID`ExecRefID`HandlInst`LastCapacity`LastMkt`LastPx`LastQty`MsgSeqNum`MsgType`OrderID`OrderQty`OrderStatus`SenderCompID`SendingTime`Side`TargetCompID`LeavesQty;
/fixTbl:(uj/){flip fixTagToName[key d]!value enlist each d:getAllTags x} testMessage;

getAllTags:{[msg](!)."S=|"0:msg};
getTag:{[tag;msg](getAllTags[msg])[tag]};

processMessage:{[message]
    oID: "I"$ getTag[`37;message];
    oTime: "T"$ getTag[`52;message];
    oSym: `$ getTag[`55;message];
    oSide: $[(`$ getTag[`54;message])=`1;`bid;(`$ getTag[`54;message])=`2;`offer;`$ getTag[`54;message]]; // `1 = buy, 2 = sell
    // type: oType
    oPrice: "F"$ getTag[`44;message]; // not sure if it should be 44 (Price) or 6 (av. price)
    oQuantity: "I"$ getTag[`14;message];

    convertedOrder:`orderID`time`sym`side`orderType`price`quantity!(oID;oTime;oSym;oSide;`limit;oPrice;oQuantity);
    MatchOrder[convertedOrder];
  };


/ 4. Validating the input format
/ check the time, if it is the latest, etc.



/ 5. Create matching function (using the sample data now)

/ MatchOrder: Top level function to match market order with different types
/ assume the order is in the format of a dictionary
MatchOrder: {[order]
    $[order[`orderType]=`limit;
        ExecuteLimitOrder[order];
        `WrongOrderType] / add more order Types
 };

/ ExecuteLimitOrder: Check if the order is valid, reject if not, otherwise call MatchLimitOrder to do the matching
ExecuteLimitOrder: {[order]
    $[order[`side]=`bid;
        ExecuteLimitOrderCondition1[order];
      order[`side]=`offer;
        ExecuteLimitOrderCondition2[order];
      `WrongOrderSide]
 };

/ Condition where the incoming order is of bid type
ExecuteLimitOrderCondition1: {[order]
    $[order[`price] > askbook[GetTopOfBookOrderID[testorder[`sym];`offer];`price];
        `rejectedbook insert (order[`orderID]; .z.T); / reject invalid orders
        [   / TODO: implement the deviation 9 times later
            / TODO: lock the table
            `bidbook insert order;
            `sym xasc `price xdesc `time xasc `bidbook; / sort the table
            MatchLimitOrder[order[`orderID];GetTopOfBookOrderID[order[`sym];`offer];order[`side]]
            / TODO: unlock the table
        ]
     ]
 };

/ Condition where the incoming order is of ask type
ExecuteLimitOrderCondition2: {[order]
    $[order[`price] < bidbook[GetTopOfBookOrderID[testorder[`sym];`bid];`price];
        `rejectedbook insert (order[`orderID]; .z.T);
        [   / TODO: implement the deviation 9 times later
            / TODO: lock the table
            `askbook insert testorder;
            `sym`price`time xasc `askbook; /sort the table
            MatchLimitOrder[GetTopOfBookOrderID[order[`sym];`bid];order[`orderID];order[`side]]
            / TODO: unlock the table
        ]
     ]
 };

/ MatchLimitOrder: The actual matching function between the bid and ask order
MatchLimitOrder:{[bidbookID;askbookID;orderSide]
    if[bidbook[bidbookID;`price]=askbook[askbookID;`price];
        $[askbook[askbookID;`quantity]>bidbook[bidbookID;`quantity];
            MatchLimitOrderCondition1[bidbookID;askbookID;orderSide];
          askbook[askbookID;`quantity]=bidbook[bidbookID;`quantity];
            MatchLimitOrderCondition2[bidbookID;askbookID;orderSide];
          askbook[askbookID;`quantity]<bidbook[bidbookID;`quantity];
            MatchLimitOrderCondition3[bidbookID;askbookID;orderSide];
          `WRONGSIZE]
      ];
 };

/ Condition where the ask order quantity is larger than that of buy order
MatchLimitOrderCondition1: {[bidbookID;askbookID;orderSide]
    askbook[askbookID;`quantity]:askbook[askbookID;`quantity]-bidbook[bidbookID;`quantity];
    tradeTime:.z.T;
    `tradebook insert ((1+count tradebook;askbookID;tradeTime),askbook[askbookID;`sym`side`orderType`price],bidbook[bidbookID;`quantity]);
    `sym xasc `time xdesc `tradebook;
    `tradebook insert ((1+count tradebook;bidbookID;tradeTime),bidbook[bidbookID;`sym`side`orderType`price`quantity]);
    `sym xasc `time xdesc `tradebook;
    delete from `bidbook where orderID=bidbookID;
    if[orderSide=`offer;
        MatchLimitOrder[GetTopOfBookOrderID[askbook[askbookID;`sym];`bid];askbookID;orderSide]
      ];
 };

/ Condition where the ask order quantity is the same as that of buy order
MatchLimitOrderCondition2: {[bidbookID;askbookID;orderSide]
    tradeTime:.z.T;
    `tradebook insert ((1+count tradebook;askbookID;tradeTime),askbook[askbookID;`sym`side`orderType`price`quantity]);
    `sym xasc `time xdesc `tradebook;
    `tradebook insert ((1+count tradebook;bidbookID;tradeTime),bidbook[bidbookID;`sym`side`orderType`price`quantity]);
    `sym xasc `time xdesc `tradebook;
    delete from `askbook where orderID=askbookID;
    delete from `bidbook where orderID=bidbookID;
 };

/ Condition where the ask order quantity is smaller than that of buy order
MatchLimitOrderCondition3: {[bidbookID;askbookID;orderSide]
    bidbook[bidbookID;`quantity]:bidbook[bidbookID;`quantity]-askbook[askbookID;`quantity];
    tradeTime:.z.T;
    `tradebook insert ((1+count tradebook;askbookID;tradeTime),askbook[askbookID;`sym`side`orderType`price`quantity]);
    `sym xasc `time xdesc `tradebook;
    `tradebook insert ((1+count tradebook;bidbookID;tradeTime),bidbook[bidbookID;`sym`side`orderType`price],askbook[askbookID;`quantity]);
    `sym xasc `time xdesc `tradebook;
    delete from `askbook where orderID=askbookID;
    if[orderSide=`bid;
        MatchLimitOrder[bidbookID;GetTopOfBookOrderID[bidbook[bidbookID;`sym];`offer];orderSide]
      ];
 };


/ GetTopOfBookOrderID: Return the order id of the top of either the bid/ask book
GetTopOfBookOrderID: {[symbol;side]
    $[side=`bid;
       output: exec orderID[0] from bidbook where sym=symbol;
     side=`offer;
       output: exec orderID[0] from askbook where sym=symbol;
     output: -1];
    output
 };

 / GetTopOfBookPrice: Return the top price of either the bid/ask book
 GetTopOfBookPrice: {[symbol;side]
     $[side=`bid;
        output: exec price[0] from bidbook where sym=symbol;
      side=`offer;
        output: exec price[0] from askbook where sym=symbol;
      output: -1];
     output
  };

/ GetNominalPrice: Return the nominal price at the time the function is called
/ Input parameter: symbol: the security symbol
/ Decision Tree:
/ pre-opening session   -> IEP can be determined    -> IEP (Note: Not implementing now)
/                       -> IEP cannot be determined -> previous close
/ continuous session -> same day trade takes place      -> currentbid > lastprice  -> currentbid
/                                                       -> currentask < last price -> currentask
/                                                       -> else                    -> lastprice
/                    -> not traded yet on the same day  -> currentbid > previousclose -> currentbid
/                                                       -> currentask < previousclose -> currentask
/                                                       -> else                       -> previousclose

GetNominalPrice: {[symbol]
  / assume previous close equal to last recorded price,
  / might change later if the system has difficulty in handling too much order near the close

  lastPrice: exec price[0] from tradebook where sym=symbol;
  prevClose: lastPrice;
  currentBid: GetTopOfBookPrice[symbol;`bid];
  currentAsk: GetTopOfBookPrice[symbol;`offer];

  / TODO: case for pre-opening session or continuous session
  / Assume it's always continuous session now

  / TODO: distinguish between if the last trade takes place in the same day or not
  / Last trade in the same day: take the last recorded price
  / Last trade in previous day: take the previous close
  / Assume it has the last trade in the same day now

  $[currentBid>lastPrice;
      output:currentbid;
    currentAsk<lastPrice;
      output:currentAsk;
    output:lastPrice
  ];
  output
 };




/ 7. Export data
