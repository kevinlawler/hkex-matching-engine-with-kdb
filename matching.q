/ Matching Engine for HKEx
/ Creating dummy data
/ Oct 29, 2015


/ 1. Create dummy input files
s:(),`FDP,`HSBC,`GOOG,`APPL,`REYA;
px:(),5,80,780,120,45;
st:09:00:00.000;
ot:`limit`auction;
/ a function to create random trades data
create:{[n]dict:s!px;id:n?1000000000;sym:n?s;side:n?"BS";
            ordertype:n?ot;price:((+;-)side="B") .'flip(dict sym;.05*n?1+til 10);
            sample:flip`id`time`sym`side`ordertype`price`size! (id;st+n?25200000;sym;side;ordertype;price;100*n?1+til 10)};
input:`time xasc create 10000; input

/ save `$"/Users/Emanuel/Desktop/input.csv"


/ 2. Create bid, ask, trade, rejected book 
book:([]id:`int$();time:`time$();sym:`$();side:`char$();ordertype:`$();price:`float$();size:`int$());
bidbook:`sym`price xasc `sym`price`time xkey book; bidbook
askbook:`sym`price xdesc `sym`price`time xkey book; askbook
tradebook:`id xkey ([]id:`int$();time:`time$();sym:`$();side:`char$();ordertype:`$();quotedprice:`float$(); executedprice:`float$();size:`int$()); tradebook
rejectedbook:([]id:`int$();time:`time$());

/ for testing with some random data in the order book
`bidbook insert(select [20] from input); bidbook
bidbook:`sym xasc `price xdesc `sym`price`time xkey bidbook; bidbook
`askbook insert(select [20] from input); askbook
askbook:`sym`price xasc `sym`price`time xkey askbook; askbook

/ for testing with a single order
testorder:`sym`price`time`id`side`ordertype`size!(`GOOG;120.5;09:40:00.000;1342565432;"B";`limit;200); testorder


/ 3. Handle incoming feed (delta feedhandlers or something similar)


/ 4. Validating the input format 
/ check the time, if it is the latest, etc.


/ 5. Create matching function (using the sample data now)

/ return the price at the top of either the bid/ask book 
getTopOfBook:{[symbol;side]
                $[side="S"; output: exec max price from bidbook where sym=symbol;
                    $[side="B"; output: exec min price from askbook where sym=symbol; 
                        output: `ERROR
                     ]
                 ];
               output};
getTopOfBook[`GOOG;"S"]

{[x;y] x+y} [1 2]

match:{[time,side,sym,ordertype,price,size] 
            $[side="B";
                $[price>=(exec max price from askbook where askbook.sym=sym);0N! 1;0N! 2];
                $[price<=(exec max price from askbook where askbook.sym=sym);0N! 3;0N! 4];] 
         }

match'[input `time;input `side;input `sym;input `ordertype;input `price;input `size] 


/ 6. Run matching function on input data


/ 7. Export data
