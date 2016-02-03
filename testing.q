/ Matching Engine for HKEx
/ Test cases
/ Last Modified: Jan 20, 2015
/ Created by: Raymond Sak, Damian Dutkiewicz

/ import matching.q
\l /Users/Raymond/Projects/hkex-matching-engine-with-kdb/matching.q
\l /Users/Damian/Documents/HKEx-Matching-Engine-with-kdb/matching.q

CleanAndPrepareData[];

/ Function for cleaning up table and prepare data for testing
CleanAndPrepareData: {[]
  delete from `bidbook;
  delete from `askbook;
  delete from `tradebook;
  delete from `rejectedbook;
  input:`time xasc CreateData 10000;
  `bidbook upsert(select [50] from input where side=`bid);
  `sym xasc `price xdesc `time xasc `orderID xkey `bidbook;
  `askbook upsert(select [50] from input where side=`offer);
  `sym`price`time xasc `orderID xkey `askbook;
 }

 / ============================== Limit Bid Order ============================= /

/ Test case 1: Incoming order:: buy limit order, price: > top of askbook
testorder:`orderID`time`sym`side`orderType`price`quantity!(111111111;09:40:00.000;`GOOG;`bid;`limit;askbook[GetTopOfBookOrderID[`GOOG;`offer]][`price]+1;123); / offfer = ask
MatchOrder[testorder];
/ Expected Result: the order is inserted into the rejected book, and no trades take places
select from rejectedbook
select from tradebook where sym=`GOOG

/ Test case 2: Incoming order:: buy limit order, price: < top of askbook
testorder:`orderID`time`sym`side`orderType`price`quantity!(222222222;09:40:00.000;`GOOG;`bid;`limit;askbook[GetTopOfBookOrderID[`GOOG;`offer]][`price]-1;123); / offfer = ask
MatchOrder[testorder];
/ Expected Result: order get inserted into the bidbook, and no trades take places
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

/ =============================== Limit Ask Order ============================= /

/ Clean the books before you execute another test cases
CleanAndPrepareData[];

/ Test case 7: Incoming order:: ask limit order, price: < top of bidbook
testorder:`orderID`time`sym`side`orderType`price`quantity!(111111111;09:40:00.000;`GOOG;`offer;`limit;bidbook[GetTopOfBookOrderID[`GOOG;`bid]][`price]-1;123); / offfer = ask
MatchOrder[testorder];
/ Expected Result: the order is inserted into the rejected book, and no trades take places
select from rejectedbook
select from tradebook where sym=`GOOG

/ Test case 8: Incoming order:: ask limit order, price: > top of bidbook
testorder:`orderID`time`sym`side`orderType`price`quantity!(222222222;09:40:00.000;`GOOG;`offer;`limit;bidbook[GetTopOfBookOrderID[`GOOG;`bid]][`price]+1;123); / offfer = ask
MatchOrder[testorder];
/ Expected Result: order get inserted into the askbook, and no trades take places
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

/ =============================== Special Limit Bid Order ============================= /

CleanAndPrepareData[];

/ 1.


/ =============================== Special Limit Ask Order ============================= /

CleanAndPrepareData[];

/ 1. Test case: condition 1: order price > top bidbook order price

/ 2. Test case: condition 2: order price = top bidbook order price

/ ask order quantity < bidbook top order quantity
testorder:`orderID`time`sym`side`orderType`price`quantity!
(222222222;09:40:00.000;`GOOG;`offer;`speciallimit;GetTopOfBookPrice[`GOOG;`bid];bidbook[GetTopOfBookOrderID[`GOOG;`bid]][`quantity]-10);
MatchOrder[testorder];
/ Expected Result: order fully executed, bidbook top order quantity has 10 left
select from bidbook where sym=`GOOG, orderType=`limit
select from askbook where sym=`GOOG, orderType=`limit
select from tradebook where sym=`GOOG

/ ask order quantity = bidbook top order quantity
testorder:`orderID`time`sym`side`orderType`price`quantity!
(333333333;09:40:00.000;`GOOG;`offer;`speciallimit;GetTopOfBookPrice[`GOOG;`bid];bidbook[GetTopOfBookOrderID[`GOOG;`bid]][`quantity]);
MatchOrder[testorder];
/ Expected Result: order and bidbook top order fully executed
select from bidbook where sym=`GOOG, orderType=`limit
select from askbook where sym=`GOOG, orderType=`limit
select from tradebook where sym=`GOOG

/ ask order quantity > bidbook top order quantity
testorder:`orderID`time`sym`side`orderType`price`quantity!
(444444444;09:40:00.000;`GOOG;`offer;`speciallimit;GetTopOfBookPrice[`GOOG;`bid];bidbook[GetTopOfBookOrderID[`GOOG;`bid]][`quantity]+10);
MatchOrder[testorder];
/ Expected Result: order partially executed, remaining order is rejected, bidbook top order fully executed
select from bidbook where sym=`GOOG, orderType=`limit
select from askbook where sym=`GOOG, orderType=`limit
select from tradebook where sym=`GOOG
select from rejectedbook

/ 3. Test case: condition 3: 9spread < order price < top bidbook order price
testorder:`orderID`time`sym`side`orderType`price`quantity!
(555555555;09:40:00.000;`GOOG;`offer;`speciallimit;GetTopOfBookPrice[`GOOG;`bid]-4;bidbook[GetTopOfBookOrderID[`GOOG;`bid]][`quantity]-10);
MatchOrder[testorder];
/ Expected Result: order fully executed, bidbook top order quantity has 10 left
select from bidbook where sym=`GOOG, orderType=`limit
select from askbook where sym=`GOOG, orderType=`limit
select from tradebook where sym=`GOOG

/ ask order quantity = bidbook top order quantity
testorder:`orderID`time`sym`side`orderType`price`quantity!
(666666666;09:40:00.000;`GOOG;`offer;`speciallimit;GetTopOfBookPrice[`GOOG;`bid]-4;bidbook[GetTopOfBookOrderID[`GOOG;`bid]][`quantity]);
MatchOrder[testorder];
/ Expected Result: order and bidbook top order fully executed
select from bidbook where sym=`GOOG, orderType=`limit
select from askbook where sym=`GOOG, orderType=`limit
select from tradebook where sym=`GOOG

/ ask order quantity > bidbook top order quantity
testorder:`orderID`time`sym`side`orderType`price`quantity!
(777777777;09:40:00.000;`GOOG;`offer;`speciallimit;GetTopOfBookPrice[`GOOG;`bid]-4;bidbook[GetTopOfBookOrderID[`GOOG;`bid]][`quantity]+10);
MatchOrder[testorder];
/ Expected Result: order fully executed, bidbook top order fully executed, 2nd top order has 10 quantity executed
select from bidbook where sym=`GOOG, orderType=`limit
select from askbook where sym=`GOOG, orderType=`limit
select from tradebook where sym=`GOOG

/ ask order quantity > bidbook top 9 spread orders total quantity
testorder:`orderID`time`sym`side`orderType`price`quantity!
(888888888;09:40:00.000;`GOOG;`offer;`speciallimit;GetTopOfBookPrice[`GOOG;`bid]-4;10+(exec sum quantity from bidbook where (sym = `GOOG) and (price > GetTopOfBookPrice[`GOOG;`bid]-4)));
MatchOrder[testorder];
/ Expected Result: order partially executed, leaving 10 quantity inserted to reject book, bidbook top order within 10 spreads all get executed
select from bidbook where sym=`GOOG, orderType=`limit
select from askbook where sym=`GOOG, orderType=`limit
select from tradebook where sym=`GOOG
select from rejectedbook

/ 4. Test case: condition 4: 9 deviation < order price < 9 spread

/ 5. Test case: condition 5: order price < 9 deviation

/ Testing for GetNominalPrice
GetNominalPrice[`GOOG]
