/ Limit Order

/ GENERATE BASIC DATA STRUCTURES
bid_table:([]id:`int$();time:`time$();sym:`$();price:`float$();size:`int$());
ask_table:([]id:`int$();time:`time$();sym:`$();price:`float$();size:`int$());
trade_table:([]trade_id:`int$();bid_id:`int$();sell_id:`int$();time:`time$();sym:`$();price:`float$();size:`int$());
rejected_orders:([]id:`int$();time:`time$());

/getTopOfBook:{[inputSymbol;side] 
    /$[side=`Sell; output: exec max price from bid_table where sym=inputSymbol; // IF Side= Sell
    /$[side=`Buy; output: exec min price from ask_table where sym=inputSymbol; output: null]]; // Else if side=But; else
    /$[side=`Sell; output: select id from bid_table where sym=inputSymbol, price=max price, time=min time;
    /$[side=`Buy; output: select id from ask_table where sym=inputSymbol, price=min price, time=min time; output: null]];
    /output[`id][0]};

matchBidAndAsk:{[SellOrder] // TODO: Implement Buy Side
    highestBuyOrder: select from bid_table where sym=SellOrder[`sym], price=max price, time=min time;
    $[SellOrder[`price] > highestBuyOrder[`price][0]; `ask_table insert (SellOrder[`id]; SellOrder[`time]; SellOrder[`sym]; SellOrder[`price]; SellOrder[`size]); //ORDER IN QUEUE
    $[SellOrder[`price] < highestBuyOrder[`price][0]; `rejected_orders insert (SellOrder[`id]; .z.T); // ORDER REJECTED
    executeLimitOrderTrade[SellOrder;highestBuyOrder]]] // EXECUTE TRADE
};
 
executeLimitOrderTrade:{[SellOrder; highestBuyOrder] // TODO: order size not yet handled
    // if BuySize > SellSize, UPDATE BuySize = BuySize - SellSize, FULL trade on sell side, partial on Buy Side
    // if BuySize < SellSize, delete Buy Order from Bid Table, Full trade on Buy side, partial on Sell Side, call checkLimitSellOrderMatch
    // if BuySize = SellSize, delete Buy Order from Bid Table, FULL TRADE EXECUTED on both sides
    `trade_table insert ((count trade_table)+1; highestBuyOrder[`id][0]; SellOrder[`id]; .z.T; 
    SellOrder[`sym]; SellOrder[`price]; SellOrder[`size]);
    delete from `bid_table where id=highestBuyOrder[`id][0] // TODO: should delete only the FIRST row found (now deletes all with max price)
};
 
/ SAMPLE DATA - assume latests order inserted at the end
`bid_table insert (1;09:04:59:000;`AAPL;10.20;1);
`bid_table insert (2;09:06:59:000;`AAPL;10.00;1);
`bid_table insert (3;09:07:59:000;`AAPL;10.10;1);
`bid_table insert (4;09:09:59:000;`AAPL;10.00;1);
`bid_table insert (5;09:10:59:000;`AAPL;09.80;1);
`bid_table insert (6;09:05:59:000;`AAPL;10.30;1);
`bid_table insert (7;09:03:59:000;`AAPL;10.30;1);
order:`id`time`sym`price`size`side!(10;.z.T;`AAPL;10.30;100;`Sell) 