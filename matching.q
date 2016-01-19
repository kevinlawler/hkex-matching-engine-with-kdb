/ Matching Engine for HKEx
/ Limit Order
/ Jan 17, 2015
/ Created by: Raymond Sak, Damian Dutkiewicz


/ 1. Create dummy trades for testing

s:(),`FDP,`HSBC,`GOOG,`APPL,`REYA;
px:(),5,80,780,120,45;
st:09:00:00.000;
ot:`limit; /`auction

/ CreateData: Create random trade orders
CreateData:{[n]dict:s!px;orderID:n?1000000000;sym:n?s;side:n?`bid`offer;
            orderType:ot;price:((+;-)side=`bid) .'flip(dict sym;.050*n?1+til 10);
            sample:flip`orderID`time`sym`side`orderType`price`quantity! (orderID;st+n?25200000;sym;side;orderType;price;100*n?1+til 10)}; /orderType:n?ot


/ 2. Create bid, ask, trade, rejected book 


book:([]orderID:`int$();time:`time$();sym:`$();side:`$();orderType:`$();price:`float$();quantity:`int$());
bidbook:`sym xasc `price xdesc `time xasc `orderID xkey book;
askbook:`sym`price`time xasc `orderID xkey book;
tradebook:`tradeID xkey ([]tradeID:`int$();orderID:`int$();time:`time$();sym:`$();side:`$();orderType:`$();price:`float$();quantity:`int$()); 
rejectedbook:([]orderID:`int$();time:`time$());


/ 3. Handle incoming message
testMessage: "8=FIX.4.4|9=178|37=00001|52=09:00:00.000|55=APPL|54=1|44=239.5|14=100"

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
    $[order[`price] > askbook[GetTopOfBookOrderID[order[`sym];`offer];`price];
        `rejectedbook insert (order[`orderID]; .z.T); / reject invalid orders
        [   / TODO: implement the deviation 9 times later
            / TODO: lock the table
            `bidbook insert order; 
            bidbook:`sym xasc `price xdesc `time xasc `orderID xkey bidbook; / sort the table
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
            `askbook insert order; 
            askbook:`sym`price`time xasc `orderID xkey askbook; /sort the table
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
    `tradebook insert ((1+count tradebook;bidbookID;tradeTime),bidbook[bidbookID;`sym`side`orderType`price`quantity]);
    delete from `bidbook where orderID=bidbookID;
    if[orderSide=`offer;
        MatchLimitOrder[GetTopOfBookOrderID[askbook[askbookID;`sym];`bid];askbookID;orderSide]
      ];                                
};

/ Condition where the ask order quantity is the same as that of buy order 
MatchLimitOrderCondition2: {[bidbookID;askbookID;orderSide]
    tradeTime:.z.T;         
    `tradebook insert ((1+count tradebook;askbookID;tradeTime),askbook[askbookID;`sym`side`orderType`price`quantity]);
    `tradebook insert ((1+count tradebook;bidbookID;tradeTime),bidbook[bidbookID;`sym`side`orderType`price`quantity]);
    delete from `askbook where orderID=askbookID;
    delete from `bidbook where orderID=bidbookID;
};
                           
/ Condition where the ask order quantity is smaller than that of buy order 
MatchLimitOrderCondition3: {[bidbookID;askbookID;orderSide]
    bidbook[bidbookID;`quantity]:bidbook[bidbookID;`quantity]-askbook[askbookID;`quantity];                                
    tradeTime:.z.T;
    `tradebook insert ((1+count tradebook;askbookID;tradeTime),askbook[askbookID;`sym`side`orderType`price`quantity]);
    `tradebook insert ((1+count tradebook;bidbookID;tradeTime),bidbook[bidbookID;`sym`side`orderType`price],askbook[askbookID;`quantity]);
    delete from `askbook where orderID=askbookID;
    if[orderSide=`bid;
        MatchLimitOrder[bidbookID;GetTopOfBookOrderID[bidbook[bidbookID;`sym];`offer];orderSide]
      ];
};
                            

/ GetTopOfBookOrderID: Return the top price of either the bid/ask book 
GetTopOfBookOrderID: {[symbol;side]
     $[side=`bid; 
         output: exec orderID[0] from bidbook where sym=symbol;
       side=`offer; 
         output: exec orderID[0] from askbook where sym=symbol;
       output: -1];
     output
};
               

/ ************* 6. TEST CASES *************

/ Prepare data for testing 
input:`time xasc CreateData 10000;
`bidbook upsert(select [50] from input where side=`bid); 
bidbook:`sym xasc `price xdesc `time xasc `orderID xkey bidbook;
`askbook upsert(select [50] from input where side=`offer); 
askbook:`sym`price`time xasc `orderID xkey askbook;

/ Test case 1: Incoming order:: buy limit order, price: > top of askbook
testorder:`orderID`time`sym`side`orderType`price`quantity!(111111111;09:40:00.000;`GOOG;`bid;`limit;askbook[GetTopOfBookOrderID[`GOOG;`offer]][`price]+1;123); / offfer = ask
MatchOrder[testorder];
/ Expected Result: the order is inserted into the rejected book, and no trades take places
select from rejectedbook
select from tradebook where sym=`GOOG

/ Test case 2: Incoming order:: buy limit order, price: < top of askbook
testorder:`orderID`time`sym`side`orderType`price`quantity!(222222222;09:40:00.000;`GOOG;`bid;`limit;askbook[GetTopOfBookOrderID[`GOOG;`offer]][`price]-1;123); / offfer = ask
MatchOrder[testorder];
/ Expected Result: order get inserted into the bidbook and tradebook
select from bidbook where sym=`GOOG, orderType=`limit
select from tradebook where sym=`GOOG

/ Test case 3: Incoming order:: buy limit order, price: = top of askbook, quantity: < quantity of top of askbook
testorder:`orderID`time`sym`side`orderType`price`quantity!(333333333;09:40:00.000;`GOOG;`bid;`limit;askbook[GetTopOfBookOrderID[`GOOG;`offer]][`price];askbook[GetTopOfBookOrderID[`GOOG;`offer]][`quantity]-1); / offfer = ask
MatchOrder[testorder];
/ Expected Result: the incoming order get fully executed, the top of the askbook order quantity gets updated (left with a size of 1)
select from bidbook where sym=`GOOG, orderType=`limit
select from askbook where sym=`GOOG, orderType=`limit
select from tradebook where sym=`GOOG

/ Test case 4: Incoming order:: buy limit order, price: = top of askbook, quantity: = quantity of top of askbook
testorder:`orderID`time`sym`side`orderType`price`quantity!(444444444;09:40:00.000;`GOOG;`bid;`limit;askbook[GetTopOfBookOrderID[`GOOG;`offer]][`price];askbook[GetTopOfBookOrderID[`GOOG;`offer]][`quantity]); / offfer = ask
MatchOrder[testorder];
/ Expected Result: both the incoming order and the top of the askbook order gets fully executed
select from bidbook where sym=`GOOG, orderType=`limit
select from askbook where sym=`GOOG, orderType=`limit
select from tradebook where sym=`GOOG

/ Test case 5: Incoming order:: buy limit order, price: = top of askbook, quantity: > quantity of top of askbook
/ there are more orders with the same price as the incoming order price
testorder:`orderID`time`sym`side`orderType`price`quantity!(555555555;09:40:00.000;`GOOG;`bid;`limit;askbook[GetTopOfBookOrderID[`GOOG;`offer]][`price];askbook[GetTopOfBookOrderID[`GOOG;`offer]][`quantity]+10); / offfer = ask
`askbook insert (100000000;09:04:59:000;`GOOG;`offer;`limit;askbook[GetTopOfBookOrderID[`GOOG;`offer]][`price];3);
`askbook insert (200000000;09:06:59:000;`GOOG;`offer;`limit;askbook[GetTopOfBookOrderID[`GOOG;`offer]][`price];4);
`askbook insert (300000000;09:08:59:000;`GOOG;`offer;`limit;askbook[GetTopOfBookOrderID[`GOOG;`offer]][`price];3);
askbook:`sym`price`time xasc `orderID xkey askbook;
MatchOrder[testorder];
/ Expected Result: the incoming order get fully executed and multiple order from the top of the askbook gets executed
select from bidbook where sym=`GOOG, orderType=`limit
select from askbook where sym=`GOOG, orderType=`limit
select from tradebook where sym=`GOOG

/ Test case 6: Incoming order:: buy limit order, price: = top of askbook, quantity: > quantity of top of askbook
/ there are no more orders with the same price as the incoming order price
`askbook insert (400000000;09:00:00:001;`GOOG;`offer;`limit;(askbook[GetTopOfBookOrderID[`GOOG;`offer]][`price]+bidbook[GetTopOfBookOrderID[`GOOG;`bid]][`price])%2;10);
askbook:`sym`price`time xasc `orderID xkey askbook;
testorder:`orderID`time`sym`side`orderType`price`quantity!(666666666;09:40:00.000;`GOOG;`bid;`limit;askbook[GetTopOfBookOrderID[`GOOG;`offer]][`price];askbook[GetTopOfBookOrderID[`GOOG;`offer]][`quantity]+1); / offfer = ask
MatchOrder[testorder];
/ Expected Result: the incoming order get partially executed (left with a size of 1) and the top of the askbook order gets fully executed
select from bidbook where sym=`GOOG, orderType=`limit 
select from askbook where sym=`GOOG, orderType=`limit
select from tradebook where sym=`GOOG

/ Clean the books before you execute another test cases
book:([]orderID:`int$();time:`time$();sym:`$();side:`$();orderType:`$();price:`float$();quantity:`int$());
bidbook:`sym xasc `price xdesc `time xasc `orderID xkey book;
askbook:`sym`price xdesc `orderID xkey book;
tradebook:`tradeID xkey ([]tradeID:`int$();orderID:`int$();time:`time$();sym:`$();side:`$();orderType:`$();price:`float$();quantity:`int$()); 
rejectedbook:([]orderID:`int$();time:`time$());
input:`time xasc CreateData 10000; input;
`bidbook upsert(select [50] from input where side=`bid); 
bidbook:`sym xasc `price xdesc `time xasc `orderID xkey bidbook;
`askbook upsert(select [50] from input where side=`offer); 
askbook:`sym`price`time xasc `orderID xkey askbook;

/ Test case 7: Incoming order:: ask limit order, price: < top of bidbook
testorder:`orderID`time`sym`side`orderType`price`quantity!(111111111;09:40:00.000;`GOOG;`offer;`limit;bidbook[GetTopOfBookOrderID[`GOOG;`bid]][`price]-1;123); / offfer = ask
MatchOrder[testorder];
/ Expected Result: the order is inserted into the rejected book, and no trades take places
select from rejectedbook
select from tradebook where sym=`GOOG

/ Test case 8: Incoming order:: ask limit order, price: > top of bidbook
testorder:`orderID`time`sym`side`orderType`price`quantity!(222222222;09:40:00.000;`GOOG;`offer;`limit;bidbook[GetTopOfBookOrderID[`GOOG;`bid]][`price]+1;123); / offfer = ask
MatchOrder[testorder];
/ Expected Result: order get inserted into the askbook and tradebook
select from askbook where sym=`GOOG, orderType=`limit
select from tradebook where sym=`GOOG

/ Test case 9: Incoming order:: ask limit order, price: = top of bidbook, quantity: < quantity of top of bidbook
testorder:`orderID`time`sym`side`orderType`price`quantity!(333333333;09:40:00.000;`GOOG;`offer;`limit;bidbook[GetTopOfBookOrderID[`GOOG;`bid]][`price];bidbook[GetTopOfBookOrderID[`GOOG;`bid]][`quantity]-1); / offfer = ask
MatchOrder[testorder];
/ Expected Result: the incoming order get fully executed, the top of the bidbook order quantity gets updated (left with a size of 1)
select from bidbook where sym=`GOOG, orderType=`limit
select from askbook where sym=`GOOG, orderType=`limit
select from tradebook where sym=`GOOG

/ Test case 10: Incoming order:: ask limit order, price: = top of bidbook, quantity: = quantity of top of bidbook
testorder:`orderID`time`sym`side`orderType`price`quantity!(444444444;09:40:00.000;`GOOG;`offer;`limit;bidbook[GetTopOfBookOrderID[`GOOG;`bid]][`price];bidbook[GetTopOfBookOrderID[`GOOG;`bid]][`quantity]); / offfer = ask
MatchOrder[testorder];
/ Expected Result: both the incoming order and the top of the askbook order gets fully executed
select from bidbook where sym=`GOOG, orderType=`limit
select from askbook where sym=`GOOG, orderType=`limit
select from tradebook where sym=`GOOG

/ Test case 11: Incoming order:: ask limit order, price: = top of bidbook, quantity: > quantity of top of bidbook
/ there are more orders with the same price as the incoming order price
testorder:`orderID`time`sym`side`orderType`price`quantity!(555555555;09:40:00.000;`GOOG;`offer;`limit;bidbook[GetTopOfBookOrderID[`GOOG;`bid]][`price];bidbook[GetTopOfBookOrderID[`GOOG;`bid]][`quantity]+10); / offfer = ask
`bidbook insert (100000000;09:04:59:000;`GOOG;`bid;`limit;bidbook[GetTopOfBookOrderID[`GOOG;`bid]][`price];3);
`bidbook insert (200000000;09:06:59:000;`GOOG;`bid;`limit;bidbook[GetTopOfBookOrderID[`GOOG;`bid]][`price];4);
`bidbook insert (300000000;09:08:59:000;`GOOG;`bid;`limit;bidbook[GetTopOfBookOrderID[`GOOG;`bid]][`price];3);
bidbook:`sym xasc `price xdesc `time xasc `orderID xkey bidbook;
MatchOrder[testorder];
/ Expected Result: the incoming order get fully executed and multiple order from the top of the bidbook gets executed
select from bidbook where sym=`GOOG, orderType=`limit
select from askbook where sym=`GOOG, orderType=`limit
select from tradebook where sym=`GOOG

/ Test case 12: Incoming order:: ask limit order, price: = top of bidbook, quantity: > quantity of top of bidbook
/ there are no more orders with the same price as the incoming order price
`bidbook insert (400000000;09:00:00:001;`GOOG;`bid;`limit;(askbook[GetTopOfBookOrderID[`GOOG;`offer]][`price]+bidbook[GetTopOfBookOrderID[`GOOG;`bid]][`price])%2;10);
bidbook:`sym xasc `price xdesc `time xasc `orderID xkey bidbook;
testorder:`orderID`time`sym`side`orderType`price`quantity!(666666666;09:40:00.000;`GOOG;`offer;`limit;bidbook[GetTopOfBookOrderID[`GOOG;`bid]][`price];bidbook[GetTopOfBookOrderID[`GOOG;`bid]][`quantity]+1); / offfer = ask
MatchOrder[testorder];
/ Expected Result: the incoming order get partially executed (left with a size of 1) and the top of the bidbook order gets fully executed
select from bidbook where sym=`GOOG, orderType=`limit 
select from askbook where sym=`GOOG, orderType=`limit
select from tradebook where sym=`GOOG

/ Clean the books
book:([]orderID:`int$();time:`time$();sym:`$();side:`$();orderType:`$();price:`float$();quantity:`int$());
bidbook:`sym xasc `price xdesc `time xasc `orderID xkey book;
askbook:`sym`price`time xasc `orderID xkey book;
tradebook:`tradeID xkey ([]tradeID:`int$();orderID:`int$();time:`time$();sym:`$();side:`$();orderType:`$();price:`float$();quantity:`int$()); 
rejectedbook:([]orderID:`int$();time:`time$());
input:`time xasc CreateData 10000; input
`bidbook upsert(select [50] from input where side=`bid); 
bidbook:`sym xasc `price xdesc `time xasc `orderID xkey bidbook;
`askbook upsert(select [50] from input where side=`offer); 
askbook:`sym`price`time xasc `orderID xkey askbook;


/ 7. Export data

