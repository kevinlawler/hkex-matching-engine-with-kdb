/ Limit Order

/ GENERATE BASIC DATA STRUCTURES
bid_table:`id xkey ([]id:`int$();time:`time$();sym:`$();price:`float$();size:`int$());
ask_table:`id xkey ([]id:`int$();time:`time$();sym:`$();price:`float$();size:`int$());
trade_table:`trade_id xkey ([]trade_id:`int$();bid_id:`int$();sell_id:`int$();time:`time$();sym:`$();price:`float$();size:`int$());
rejected_orders:`id xkey ([]id:`int$();time:`time$());

/getTopOfBook:{[inputSymbol;side] 
    /$[side=`Sell; output: exec max price from bid_table where sym=inputSymbol; // IF Side= Sell
    /$[side=`Buy; output: exec min price from ask_table where sym=inputSymbol; output: null]]; // Else if side=But; else
    /$[side=`Sell; output: select id from bid_table where sym=inputSymbol, price=max price, time=min time;
    /$[side=`Buy; output: select id from ask_table where sym=inputSymbol, price=min price, time=min time; output: null]];
    /output[`id][0]};

matchBidAndAsk:{[SellOrder] // TODO: Implement Buy Side
    highestBuyOrderID: exec id[0] from bid_table where sym=SellOrder[`sym], price=max price, time=min time;
    $[SellOrder[`price] > bid_table[highestBuyOrderID;`price]; `ask_table upsert (SellOrder[`id]; SellOrder[`time]; SellOrder[`sym]; SellOrder[`price]; SellOrder[`size]); //ORDER IN QUEUE
    $[SellOrder[`price] < bid_table[highestBuyOrderID;`price]; `rejected_orders insert (SellOrder[`id]; .z.T); // ORDER REJECTED
    executeLimitOrderTrade[SellOrder;highestBuyOrderID]]] // EXECUTE TRADE  

// Remark: should the order be first check if the order is valid, then try to execute it, then add the order into the bid/ask table if the price is larger/smaller than the 
// bid/ask price, as we might need to do a semaphore/lock in the table before updating it
// so the bottom line is do not add into the ask table before locking it and trying to execute it
};
 
executeLimitOrderTrade:{[SellOrder; BuyOrderID] 
    /tempOrder: SellOrder
    /$[BuyOrder[`size] < SellOrder[`size]; [updateTradeTable[SellOrder; BuyOrder]; updateBidTable[SellOrder;BuyOrder]; 
    /matchBidAndAsk[tempOrder[`size]: tempOrder[`size]-tempOrder[`size]]]
    updateTradeTable[SellOrder; BuyOrderID];  // Remark: we should probably try to execute it before updating the trade table
    updateBidTable[SellOrder;BuyOrderID];
};

    // if BuySize > SellSize, UPDATE BuySize = BuySize - SellSize, FULL trade on sell side, partial on Buy Side
    // if BuySize < SellSize, delete Buy Order from Bid Table, Full trade on Buy side, partial on Sell Side, call checkLimitSellOrderMatch
    // if BuySize = SellSize, delete Buy Order from Bid Table, FULL TRADE EXECUTED on both sides
updateTradeTable:{[SellOrder;BuyOrderID]
    tradeID: (count trade_table)+1;
    $[bid_table[BuyOrderID;`size] > SellOrder[`size];
    `trade_table insert (tradeID; BuyOrderID; SellOrder[`id]; .z.T; SellOrder[`sym]; SellOrder[`price]; SellOrder[`size]);
    `trade_table insert (tradeID; BuyOrderID; SellOrder[`id]; .z.T; SellOrder[`sym]; SellOrder[`price]; SellOrder[`size]);] /if BuySize < or = SellSize
};

updateBidTable:{[SellOrder;BuyOrderID]
    $[BuyOrder[`size] > SellOrder[`size];
    bid_table[BuyOrder[`id];`size]: BuyOrder[`size] - SellOrder[`size];
    delete from `bid_table where id=BuyOrder[`id][0]] /if BuySize < or = SellSize  // Remark: this should only be =, for < we need to update the ask table as well, and we should modify the trade order here, not before
};
 
/ SAMPLE DATA - assume latests order inserted at the end
`bid_table insert (1;09:04:59:000;`AAPL;10.20;1);
`bid_table insert (2;09:06:59:000;`AAPL;10.00;1);
`bid_table insert (3;09:07:59:000;`AAPL;10.10;1);
`bid_table insert (4;09:09:59:000;`AAPL;10.00;1);
`bid_table insert (5;09:10:59:000;`AAPL;09.80;1);
`bid_table insert (6;09:05:59:000;`AAPL;10.30;1);
`bid_table insert (7;09:03:59:000;`AAPL;10.30;1);
order:`id`time`sym`price`size`side!(10;.z.T;`AAPL;10.40;100;`Sell) 
