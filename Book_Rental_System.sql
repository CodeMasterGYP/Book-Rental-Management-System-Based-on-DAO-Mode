USE MASTER

IF (EXISTS(SELECT * FROM master.dbo.sysdatabases WHERE dbid=db_ID('BookRentalSystemDB')))
BEGIN
　　USE master
　　ALTER DATABASE BookRentalSystemDB
　　SET single_user
　　WITH ROLLBACK IMMEDIATE 
　　DROP DATABASE BookRentalSystemDB
END
GO
------
------
IF EXISTS (SELECT * FROM sysdatabases WHERE NAME='BookRentalSystemDB')
	DROP DATABASE BookRentalSystemDB
GO

CREATE DATABASE BookRentalSystemDB
GO
/*
CREATE DATABASE BookRentalSystemDB
on(
	name=BookRentalSystemDB,
	filename='C:\BookRentalSystemDB\BookRentalSystemDB.mdf',
	size=10,
	filegrowth=5
)
GO
*/

USE BookRentalSystemDB
GO
-------
-------
CREATE TABLE Reader(	--读者表
	readerID		char(6)						not null,	--账号
	readerPassword	char(6)						not null,	--密码
	readerName		varchar(20)					not null,	--姓名
	sex				char(2)						not null,	--性别
	phoneNumber		char(11)					not null,   --手机号码

	balance			money			default 0	not null,	--账户余额

	constraint ReaderPK primary key(readerID),

	constraint ReaderSexCK check(sex in ('男','女')),
	constraint ReaderBalanceCK check(balance>=0),
)
GO
-------
-------

create table Book(		--图书表
	isbn			char(6)						not null,	--图书编号
	bookName		varchar(20)					not null,	--书名
	author			varchar(20)					not null,	--作者
	press			varchar(20)					not null,	--出版社名称
	pressDate		date						not null,	--出版日期
	storage			int				default 0	not null,	--图书存量
	loanNum			int				default 0	not null,	--借出数量
	price			money			default 0	not null,	--书的价格
	dailyPrice		money			default 0	not null,	--每天租金

	constraint BookPK primary key(isbn),

	constraint pressDateCK check(pressDate<=getDate()),
	constraint BookStorageCK check(storage>=0),
	constraint BookLoanNumCK check(loanNum>=0 and loanNum<=storage),
	constraint BookPriceCK check(price>0),
	constraint BookDailyPriceCK check(dailyPrice>0),
)
GO
-------
-------
insert into Book values('000001','图书1','作者1', '机械工业出版社', '2019-01-16', 10, 0, 20, 0.2)
insert into Book values('000002','图书2','作者2', '机械工业出版社', '2019-01-16', 9, 0, 30, 0.2)
insert into Book values('000003','图书3','作者3', '机械工业出版社', '2019-01-16', 5, 0, 50, 0.2)
-------
-------

create table Worker(		--工作人员表
	workerID		char(6)			UNIQUE		not null,	--员工工号
	workerPassword	char(6)						not null,	--密码
	workerName		varchar(20)					not null,	--姓名
	sex				char(2)						not null,	--性别
	phoneNumber		char(11)					not null,   --手机号码

	constraint WorkerPK primary key(workerID),

	constraint WorkerSexCK check(sex in ('男','女')),
)
GO
-------
-------
--***************************************
--dateadd(datepart, number, date)
--dateadd(dd, 2, date)//返回date+2天的日期
--/****************detepart:yy,mm,dd,ww,hh,mi,ss
--********************************************************************
--datediff(datepart,startdate,enddate)
--SELECT DATEDIFF(day,'2008-12-29','2008-12-30') AS DiffDate//结果为1
--SELECT DATEDIFF(day,'2008-12-30','2008-12-29') AS DiffDate//结果为-1
--********************************************************************
--datename(datepart, date)//返回日期指定部分的字符串
--********************************************************************
--datepart(datepart, date)//返回日期指定部分的整数

--convert(data_type(length),data_to_be_converted,style)
--

CREATE TABLE Record(	--借还书记录表
	recordID		int			identity(1,1)		not null,	--借书单号		
	readerID		char(6)							not null,	--读者号
	isbn			char(6)							not null,	--图书编号
	borrowDate		date		default getdate()	not null,	--租借日期
	expectDate		date							not null,	--应还日期
	returnDate		date		default null		null	,	--归还日期
	judge			char(2)		default '否'		not null,	--判断是否归还图书
	cost			money		default 0					,	--总花费

	constraint RecordPK primary key(recordID),
	constraint RecordFK1 foreign key(readerID) references reader(readerID),
	constraint RecordFK2 foreign key(isbn) references Book(isbn) ON UPDATE CASCADE,

	constraint RecordBorrowDateCK check(borrowDate <= getDate()),
	constraint RecordReturnCK check(returnDate >= borrowDate),
	constraint RecordJudgeCK check(judge in ('是','否')),
	constraint RecordCostCK check(cost>=0),
)
GO
-------
-------

CREATE TABLE Recharge(	--充值表
	rechargeID		int			identity(1,1)		not null,	--充值单号
	readerID		char(6)							not null,	--读者编号
	workerID		char(6)							not null,	--工作人员编号

	rechargeDate	date		default getdate()	not null,	--充值日期
	amount			money							not null	--充值金额

	constraint RechargePK primary key(rechargeID),
	constraint RechargeFK1 foreign key(readerID) references Reader(readerID),
	constraint RechargeFK2 foreign key(workerID) references Worker(workerID),

	constraint RechargeDateCK check(rechargeDate <= getDate()),
)
GO
-------
-------
CREATE TABLE Label(		--图书标签表
	labelID	int				identity(1,1)	not null,	--标签号
	isbn	char(6)							not null,	--图书编号
	label	varchar(20)						not null,	--图书标签

	constraint LabelPK primary key(labelID),
	constraint LabelFK foreign key(isbn) references Book(isbn) ON UPDATE CASCADE,
)
GO
-------
-------


SELECT *
FROM Book