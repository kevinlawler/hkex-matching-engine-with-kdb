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
/fixTbl:(uj/){flip fixTagToName[key d]!value enlist each d:GetAllTags x} testMessage;

GetAllTags:{[msg](!)."S=|"0:msg};
GetTag:{[tag;msg](GetAllTags[msg])[tag]};

ProcessMessage:{[message]
    oID: "I"$ GetTag[`37;message];
    oTime: "T"$ GetTag[`52;message];
    oSym: `$ GetTag[`55;message];
    oSide: $[(`$ GetTag[`54;message])=`1;`bid;(`$ GetTag[`54;message])=`2;`offer;`$ GetTag[`54;message]]; // `1 = buy, 2 = sell
    // type: oType
    oPrice: "F"$ GetTag[`44;message]; // not sure if it should be 44 (Price) or 6 (av. price)
    oQuantity: "I"$ GetTag[`14;message];

    convertedOrder:`orderID`time`sym`side`orderType`price`quantity!(oID;oTime;oSym;oSide;`limit;oPrice;oQuantity);
    MatchOrder[convertedOrder];
  };


/ 4. Validating the input format
/ check the time, if it is the latest, etc.
/ minimum table spread https://www.hkex.com.hk/eng/rulesreg/traderules/sehk/Documents/sch-2_eng.pdf
/ call getminimumspread

/ 5. Create matching function (using the sample data now)

/ MatchOrder: Top level function to match market order with different types
/ assume the order is in the format of a dictionary

MatchOrder: {[order]
    $[order[`side]=`bid;
      BidOrderCheckCondition[order];
    order[`side]=`offer;
      AskOrderCheckCondition[order];
    `WrongOrderSide]
  };


/ BidOrderCheckCondition: Incoming order is the bid order, check which condition it applies
BidOrderCheckCondition: {[order]
    orderPrice: order[`price];
    askbookTopPrice: askbook[GetTopOfBookOrderID[order[`sym];`offer];`price];
    askbookTopPrice10spread: askbookTopPrice+9*GetMinimumSpread[order[`price]];
    nominalPriceDeviate9times: GetNominalPrice[order[`sym]]*9;

    $[orderPrice < askbookTopPrice;
        / condition 1:
        ProcessBidCondition1[order];
      orderPrice = askbookTopPrice;
        / condition 2:
        ProcessBidCondition2[order];
      ((orderPrice within(askbookTopPrice,askbookTopPrice10spread)) and (not orderPrice = askbookTopPrice));
        / condition 3:
        ProcessBidCondition3[order];
      ((orderPrice within (askbookTopPrice10spread, nominalPriceDeviate9times)) and (not orderPrice = askbookTopPrice10spread));
        / condition 4:
        ProcessBidCondition4[order];
      orderPrice > nominalPriceDeviate9times;
        / condition 5:
        ProcessBidCondition5[order];
      ]
  };

/ AskOrderCheckCondition: Incoming order is the ask order, check which condition it applies

AskOrderCheckCondition: {[order]
    orderPrice: order[`price];
    bidbookTopPrice: bidbook[GetTopOfBookOrderID[order[`sym];`bid];`price];
    bidbookTopPrice10spread: bidbookTopPrice-9*GetMinimumSpread[order[`price]];
    nominalPriceDeviate9times: GetNominalPrice[order[`sym]]%9;

    $[orderPrice > bidbookTopPrice;
        / condition 1:
        ProcessAskCondition1[order];
      orderPrice = bidbookTopPrice;
        / condition 2:
        ProcessAskCondition2[order];
      ((orderPrice within(bidbookTopPrice10spread,bidbookTopPrice)) and (not orderPrice = bidbookTopPrice));
        / condition 3:
        ProcessAskCondition3[order];
      ((orderPrice within (nominalPriceDeviate9times, bidbookTopPrice10spread)) and (not orderPrice = bidbookTopPrice10spread));
        / condition 4:
        ProcessAskCondition4[order];
      orderPrice < nominalPriceDeviate9times;
        / condition 5:
        ProcessAskCondition5[order];
      ]
  };

/ ============================= ASK ORDER CONDITIONS ===========================

ProcessAskCondition1:{[order] / Ask Order Above Top Bid Price
  $[order[`orderType]=`speciallimit;
    AddToRejectBook[order];
  AddToAskBook[order]]; / If limit order OR Enhanced Limit Order
 };

ProcessAskCondition2:{[order]  / Ask Order = Top Bid Price
  $[order[`orderType]=`speciallimit;
      AddToRejectBook[MatchAskOrderAtTopBidPrice[order]];
    AddToAskBook[MatchAskOrderAtTopBidPrice[order]]]; / if limit order OR enhanced limit order
 };

ProcessAskCondition3:{[order] / Ask Order < Top Bid Price AND Ask Order > Price @ 9 Spreads away
  $[order[`orderType]=`limit;
      AddToRejectBook[order];
    order[`orderType]=`enhancedlimit;
      AddToAskBook[MatchAskOrderUpTo9Spreads[order]];
    AddToRejectBook[MatchAskOrderUpTo9Spreads[order]]]; / if special limit order
 };

ProcessAskCondition4:{[order] / Ask Order < Price @ 9 Spreads Away AND Ask Order > Price @ 9 deviations away
  $[order[`orderType]=`speciallimit;
    AddToRejectBook[MatchAskOrderUpTo9Spreads[order]];
  AddToRejectBook[order]]; / if limit order OR enhanced limit order
 };

ProcessAskCondition5:{[order] /  Ask Order < Price @ 9 deviations Away
  AddToRejectBook[order];     / Reject Order regardless of order type
 };

/ ============================= BID ORDER CONDITIONS ===========================

ProcessBidCondition1:{[order] / Bid Order Below Top Ask Price
  $[order[`orderType]=`speciallimit;
    AddToRejectBook[order];
  AddToBidBook[order]]; / If limit order OR Enhanced Limit Order
 };

ProcessBidCondition2:{[order] / Bid Order = Top Ask Price
  $[order[`orderType]=`speciallimit;
      AddToRejectBook[MatchBidOrderAtTopAskPrice[order]];
    AddToBidBook[MatchBidOrderAtTopAskPrice[order]]]; / if limit order OR enhanced limit order
 };

ProcessBidCondition3:{[order] / Bid Order > Top Ask Price AND Bid Order < Price @ 9 Spreads Away
  $[order[`orderType]=`limit[[]];
      AddToRejectBook[order];
    order[`orderType]=`enhancedlimit;
      AddToBidBook[MatchBidOrderUpTo9Spreads[order]];
    AddToRejectBook[MatchBidOrderUpTo9Spreads[order]]]; / if special limit order
 };

ProcessBidCondition4:{[order] / Bid Order > Prie @ 9 Spreads Away AND Ask Order < Price @ 9 deviations Away
  $[order[`orderType]=`speciallimit;
    AddToRejectBook[MatchBidOrderUpTo9Spreads[order]];
  AddToRejectBook[order]]; / if limit order OR enhanced limit order
 };

ProcessBidCondition5:{[order] / Bid Order > Price @ 9 deviations Away
  AddToRejectBook[order];
 };


MatchAskOrderAtTopBidPrice: {[order]}; / The function has to return updated order with unmatched number of underlying
MatchBidOrderAtTopAskPrice: {[order]}; / The function has to return updated order with unmatched number of underlying
MatchAskOrderUpTo9Spreads: {[order]}; / The function has to return updated order with unmatched number of underlying
MatchBidOrderUpTo9Spreads: {[order]}; / The function has to return updated order with unmatched number of underlying

AddToAskBook: {[order]
  `askbook insert order;
  `sym`price`time xasc `askbook; /sort the table
 };

AddToBidBook: {[order]
  `bidbook insert order;
  `sym xasc `price xdesc `time xasc `bidbook; / sort the table
 };

AddToRejectBook: {[order]
  `rejectedbook insert (order[`orderID]; .z.T);
 };

/
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
    $[order[`price] > askbook[GetTopOfBookOrderID[order[`sym];`offer];`price];
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
    $[order[`price] < bidbook[GetTopOfBookOrderID[order[`sym];`bid];`price];
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
\

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
      output:currentBid;
    currentAsk<lastPrice;
      output:currentAsk;
    output:lastPrice
  ];
  output
 };

/ Check if we need to change the .00001 design later
GetMinimumSpread: {[price]
  $[price within(0.01,0.25);
      output:0.001;
    price within(0.2500001,0.50);
      output:0.005;
    price within(0.5000001,10.00);
      output:0.010;
    price within(10.0000001,20.00);
      output:0.020;
    price within(20.0000001,100.00);
      output:0.050;
    price within(100.0000001,200.00);
      output:0.100;
    price within(200.0000001,500.00);
      output:0.200;
    price within(500.0000001,1000.00);
      output:0.500;
    price within(1000.0000001,2000.00);
      output:1.000;
    price within(2000.0000001,5000.00);
      output:2.000;
    price within(5000.0000001,9995.00);
      output:5.000;
  ]
 };




/ 7. Export data
