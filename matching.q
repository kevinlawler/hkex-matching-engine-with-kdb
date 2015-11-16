/ Matching Engine for HKEx
/ Creating dummy data
/ Oct 29, 2015


/ 1. Create dummy input files
s:(),`FDP,`HSBC,`GOOG,`APPL,`REYA;
px:(),5,80,780,120,45;
st:09:00:00.000;
ot:`limit`auction;
/ a function to create random trades data
createData:{[n]dict:s!px;orderID:n?1000000000;sym:n?s;side:n?`bid`offer;
            orderType:n?ot;price:((+;-)side=`bid) .'flip(dict sym;.050*n?1+til 10);
            sample:flip`orderID`time`sym`side`orderType`price`quantity! (orderID;st+n?25200000;sym;side;orderType;price;100*n?1+til 10)};
input:`time xasc createData 10000; input

/ save `$"/Users/Emanuel/Desktop/input.csv"


/ 2. Create bid, ask, trade, rejected book 
book:([]orderID:`int$();time:`time$();sym:`$();side:`$();orderType:`$();price:`float$();quantity:`int$());
bidbook:`sym`price xasc `orderID xkey book; bidbook
askbook:`sym`price xdesc `orderID xkey book; askbook
tradebook:`tradeID xkey ([]tradeID:`int$();orderID:`int$();time:`time$();sym:`$();side:`$();orderType:`$();price:`float$();quantity:`int$()); tradebook
rejectedbook:([]orderID:`int$();time:`time$());

/ for testing with some random data in the order book
`bidbook insert(select [20] from input where side=`bid); 
bidbook:`sym xasc `price xdesc `orderID xkey bidbook; bidbook
`askbook insert(select [20] from input where side=`offer); askbook
askbook:`sym`price xasc `orderID xkey askbook; askbook

/ for testing with a single order
testorder:`orderID`time`sym`side`orderType`price`quantity!(934256543;09:40:00.000;`GOOG;`ask;`limit;120.5;200); testorder
MatchOrder[testorder]; 
select from bidbook where sym=`GOOG
select from askbook where sym=`GOOG
select from tradebook where sym=`GOOG
select from rejectedbook

/ 3. Handle incoming feed (delta feedhandlers or something similar)


/ 4. Validating the input format 
/ check the time, if it is the latest, etc.


/ 5. Create matching function (using the sample data now)

/ Top level function to run with different order types
/ assume the order is in the format of a dictionary
MatchOrder:{[order]
                $[order[`orderType]=`limit; ExecuteLimitOrder[order];
                    ] / put other order types here
           };

/order:testorder

/ For limit order, reject if invalid, match otherwise
ExecuteLimitOrder:{[order]
                        $[order[`side]=`bid; 
                            ExecuteLimitOrderCondition1;
                            $[order[`side]=`offer; 
                                ExecuteLimitOrderCondition2; 
                                `ERROR
                             ]
                         ]
                  };

ExecuteLimitOrderCondition1: {[order] 
                                $[order[`price] > askbook[GetTopOfBookOrderID[order[`sym];`offer];`price];
                                    `rejectedbook insert (order[`orderID]; .z.T); / reject invalid orders
                                    [   / implement the deviation 9 times later
                                        / lock the table
                                        `bidbook insert order; / insert into the table 
                                        MatchLimitOrder[order[`orderID];GetTopOfBookOrderID[order[`sym];`offer]];
                                        / unlock the table
                                    ]
                                 ]
                             };

ExecuteLimitOrderCondition2: {[order]
                                $[order[`price] < bidbook[GetTopOfBookOrderID[order[`sym];`bid];`price];
                                    `rejectedbook insert (order[`orderID]; .z.T); / reject invalid orders
                                    [
                                        / implement the deviation 9 times later
                                        / lock the table
                                        `askbook insert order; / insert into the table 
                                        MatchLimitOrder[order[`orderID];GetTopOfBookOrderID[order[`sym];`bid]];
                                        / unlock the table
                                    ]
                                 ]
                             };


/ Matching bid and ask limit order

MatchLimitOrder:{[bidbookID;askbookID]
                   $[bidbook[bidbookID;`price]=askbook[askbookID;`price];                        
                        $[askbook[askbookID;`quantity]>bidbook[bidbookID;`quantity];
                            MatchLimitOrderCondition1[bidbookID;askbookID];
                        $[askbook[askbookID;`quantity]=bidbook[bidbookID;`quantity];
                            MatchLimitOrderCondition2[bidbookID;askbookID];
                        $[askbook[askbookID;`quantity]<bidbook[bidbookID;`quantity];
                            MatchLimitOrderCondition3[bidbookID;askbookID];
                            `WRONGSIZE
                         ]
                         ]
                         ]; `PRICEUNMATCHED
                         / Price does not match; leave;
                     ]
                 };

MatchLimitOrderCondition1: {[bidbookID;askbookID]
                                        askbook[askbookID;`quantity]:askbook[askbookID;`quantity]-bidbook[bidbookID;`quantity];
                                        delete from `bidbook where orderID=bidbookID;
                                        tradeTime:.z.T;
                                        `tradebook insert ((1+count tradebook;askbookID;tradeTime),askbook[askbookID;`sym`side`orderType`price],bidbook[bidbookID;`quantity]);
                                        `tradebook insert ((1+count tradebook;bidbookID;tradeTime),bidbook[bidbookID;`sym`side`orderType`price`quantity]);
                                        MatchLimitOrder[GetTopOfBookOrderID[askbook[askbookID;`sym];`bid];askbookID];                                
                                   };

MatchLimitOrderCondition2: {[bidbookID;askbookID]
                                    delete from `askbook where orderID=askbookID;
                                    delete from `bidbook where orderID=bidbookID;
                                    tradeTime:.z.T;         
                                    `tradebook insert ((1+count tradebook;askbookID;tradeTime),askbook[askbookID;`sym`side`orderType`price`quantity]);
                                    `tradebook insert ((1+count tradebook;bidbookID;tradeTime),bidbook[bidbookID;`sym`side`orderType`price`quantity]);
                              };

MatchLimitOrderCondition3: {[bidbookID;askbookID]
                                        delete from `askbook where orderID=askbookID;
                                        bidbook[bidbookID;`quantity]:bidbook[bidbookID;`quantity]-askbook[askbookID;`quantity];                                
                                        tradeTime:.z.T;
                                        `tradebook insert ((1+count tradebook;askbookID;tradeTime),askbook[askbookID;`sym`side`orderType`price`quantity]);
                                        `tradebook insert ((1+count tradebook;bidbookID;tradeTime),bidbook[bidbookID;`sym`side`orderType`price],askbook[askbookID;`quantity]);
                                        MatchLimitOrder[bidbookID;GetTopOfBookOrderID[bidbook[bidbookID;`sym];`ask]]
                                    };
                            

/ return the price at the top of either the bid/ask book 
GetTopOfBookOrderID:{[symbol;side]
                $[side=`bid; output: exec orderID[0] from bidbook where sym=symbol, price=max price, time=min time;
                    $[side=`offer; output: exec orderID[0] from askbook where sym=symbol, price=min price, time=min time;
                        output: -1
                     ]
                 ];
               output};
GetTopOfBookOrderID[`GOOG;`bid]




/ 6. Run matching function on input data


/ 7. Export data
