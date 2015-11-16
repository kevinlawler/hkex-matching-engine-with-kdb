/ Matching Engine for HKEx
/ Creating dummy data
/ Oct 29, 2015

/ 1. Create dummy input files
s:(),`FDP,`HSBC,`GOOG,`APPL,`REYA
px:(),5,80,780,120,45
st:09:00:00.000
ot:`limit`auction
/ a function to create random trades data
create:{[n]dict:s!px;id:n?10000000000;sym:n?s;side:n?"BS";ordertype:n?ot;price:((+;-)side="B") .'flip(dict sym;.05*n?1+til 10);sample:flip`id`time`sym`side`ordertype`price`size! (id;st+n?25200000;sym;side;ordertype;price;100*n?1+til 10)}
input:`time xasc create 10000
input
/ save `$"/Users/Emanuel/Desktop/input.csv"

/ 2. Create bid, ask, trade, rejected book 
book:([]id:`int$();time:`time$();sym:`$();side:`char$();ordertype:`$();price:`float$();size:`int$())
bidbook:`sym`price xasc `sym`price`time xkey book
askbook:`sym`price xdesc `sym`price`time xkey book
`bidbook insert(select [10] from input)
bidbook
askbook
`bidbook insert(`GOOG;120.5;123;09:00:00.000;"B";`limit;200)
tradebook:`id xkey ([]id:`int$();time:`second$();sym:`$();side:`char$();ordertype:`char$();quotedprice:`float$();executedprice:`float$();size:`int$())

/ 3. Handle incoming feed (delta feedhandlers or something similar)
/ 4. Validating the input format 
/ check the time, if it is the latest
/ 5. Create matching function (using the sample data now)
matching:{[time,side,sym,ordertype,price,size] 
            $[side="B";
                $[price>=(select top price from askbook where askbook.sym=sym);0N! 1;0N! 2];
                $[price<=(select top price from askbook where askbook.sym=sym);0N! 3;0N! 4];] }

matching'[input `time;input `side;input `sym;input `ordertype;input `price;input `size] 
/ 6. Run matching function on input data

/ 7. Export data
