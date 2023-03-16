drop table if exists bond_master;
CREATE TABLE `bond_master` (
  `SecurityId` varchar(20),
  `Coupon` double DEFAULT NULL,
  `Maturity` date DEFAULT NULL,
  `SecurityType` varchar(100) DEFAULT NULL,
  `issuerId` varchar(20) DEFAULT NULL,
  `IssuerDate` date DEFAULT NULL,
  `Benchmark` varchar(20) DEFAULT NULL,
   primary key (SecurityId)
);


drop table if exists bond_price;
CREATE TABLE `bond_price` (
  `SourceType` varchar(100),
  `SecurityId` varchar(20),
  `TradeDate` date,
  `BidPrice` double DEFAULT NULL,
  `BidYield` double DEFAULT NULL,
  `AskPrice` double DEFAULT NULL,
  `AskYield` double DEFAULT NULL,
   primary key (SourceType, SecurityId, TradeDate)
);


drop table if exists issuer_desp;
CREATE TABLE `issuer_desp` (
  `issuerId` varchar(20) NOT NULL,
  `IssuerName` varchar(100) DEFAULT NULL,
  `ticker` varchar(100) DEFAULT NULL,
  PRIMARY KEY (`issuerId`)
);


drop table if exists cds_history;
CREATE TABLE `cds_history` (
  `TradeDate` date,
  `SecurityId` varchar(20),
  `Price` double,
  `Yield` double DEFAULT NULL,
  `Volume` double DEFAULT NULL,
   primary key (TradeDate, SecurityId, Price, Volume)
);

-- temp staging table
drop table if exists last_trades;
CREATE TABLE `last_trades` (
  `Id` INTEGER primary key AUTOINCREMENT,
  `TradeDate` date,
  `SecurityId` varchar(20),
  `Price` double,
  `Yield` double DEFAULT NULL,
  `Volume` double DEFAULT NULL
);

--Sqlite/ Mysql/ MS Sql server/Access support autoincrement
-- Oracle did not suppport autoincrement 
-- Oracle support Sequence object


--Leetcode

-- Step 1:
insert into last_trades(tradedate, securityid, price, yield, volume)
select *
from cds_history
where volume > 500000
order by securityid asc, tradedate desc
;


-- Step 2:

delete from last_trades
where id not in (
    select min(id) from last_trades
    group by securityid
)
;

-- Step 3:

create table last_trades_1 as
select
      a.securityid,
      a.coupon,
      a.maturity,
      a.benchmark,
      b.issuername,
      c.price   as cds_price,
      c.yield   as cds_yield,
      c.volume  as cds_volume,
      c.tradedate as cds_lasttradedate
from bond_master a
left join issuer_desp b
on a.issuerid = b.issuerid
left join last_trades c
on a.securityid = c.securityid
where a.securitytype = 'Corp'
;


-- Step 4:

create table last_trades_2 as
select 
      a.*,
      b.bidprice as cibc_price,
      b.bidyield as cibc_yield
from last_trades_1 a
left join bond_price b
on a.securityid = b.securityid
where b.sourcetype = 'CIBC_EOD'
  and b.tradedate  = '2020-12-05'
;


-- Step 5:

create table last_trades_3 as
select 
      a.*,
      round((a.cds_yield - b.bidyield) * 100, 3) as cds_spread,
      round((a.cibc_yield - b.bidyield)* 100, 3) as cibc_spread
from last_trades_2 a
left join bond_price b
on a.benchmark = b.securityid
where b.sourcetype = 'TSX_EOD' 
  and b.tradedate  = '2020-12-05'
;


-- Step 6:

create table last_trades_report as
select 
      securityid,
      coupon,
      maturity,
      issuername,
      cds_price,
      cds_yield,
      cds_spread,
      cds_volume,
      cds_lasttradedate,
      cibc_price
      cibc_yield,
      cibc_spread,
      '2020-12-05' as cibc_lasttradedate
from last_trades_3
;















