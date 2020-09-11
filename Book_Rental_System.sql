USE MASTER

IF (EXISTS(SELECT * FROM master.dbo.sysdatabases WHERE dbid=db_ID('BookRentalSystemDB')))
BEGIN
����USE master
����ALTER DATABASE BookRentalSystemDB
����SET single_user
����WITH ROLLBACK IMMEDIATE 
����DROP DATABASE BookRentalSystemDB
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
CREATE TABLE Reader(	--���߱�
	readerID		char(6)						not null,	--�˺�
	readerPassword	char(6)						not null,	--����
	readerName		varchar(20)					not null,	--����
	sex				char(2)						not null,	--�Ա�
	phoneNumber		char(11)					not null,   --�ֻ�����

	balance			money			default 0	not null,	--�˻����

	constraint ReaderPK primary key(readerID),

	constraint ReaderSexCK check(sex in ('��','Ů')),
	constraint ReaderBalanceCK check(balance>=0),
)
GO
-------
-------

create table Book(		--ͼ���
	isbn			char(6)						not null,	--ͼ����
	bookName		varchar(20)					not null,	--����
	author			varchar(20)					not null,	--����
	press			varchar(20)					not null,	--����������
	pressDate		date						not null,	--��������
	storage			int				default 0	not null,	--ͼ�����
	loanNum			int				default 0	not null,	--�������
	price			money			default 0	not null,	--��ļ۸�
	dailyPrice		money			default 0	not null,	--ÿ�����

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
insert into Book values('000001','ͼ��1','����1', '��е��ҵ������', '2019-01-16', 10, 0, 20, 0.2)
insert into Book values('000002','ͼ��2','����2', '��е��ҵ������', '2019-01-16', 9, 0, 30, 0.2)
insert into Book values('000003','ͼ��3','����3', '��е��ҵ������', '2019-01-16', 5, 0, 50, 0.2)
-------
-------

create table Worker(		--������Ա��
	workerID		char(6)			UNIQUE		not null,	--Ա������
	workerPassword	char(6)						not null,	--����
	workerName		varchar(20)					not null,	--����
	sex				char(2)						not null,	--�Ա�
	phoneNumber		char(11)					not null,   --�ֻ�����

	constraint WorkerPK primary key(workerID),

	constraint WorkerSexCK check(sex in ('��','Ů')),
)
GO
-------
-------
--***************************************
--dateadd(datepart, number, date)
--dateadd(dd, 2, date)//����date+2�������
--/****************detepart:yy,mm,dd,ww,hh,mi,ss
--********************************************************************
--datediff(datepart,startdate,enddate)
--SELECT DATEDIFF(day,'2008-12-29','2008-12-30') AS DiffDate//���Ϊ1
--SELECT DATEDIFF(day,'2008-12-30','2008-12-29') AS DiffDate//���Ϊ-1
--********************************************************************
--datename(datepart, date)//��������ָ�����ֵ��ַ���
--********************************************************************
--datepart(datepart, date)//��������ָ�����ֵ�����

--convert(data_type(length),data_to_be_converted,style)
--

CREATE TABLE Record(	--�軹���¼��
	recordID		int			identity(1,1)		not null,	--���鵥��		
	readerID		char(6)							not null,	--���ߺ�
	isbn			char(6)							not null,	--ͼ����
	borrowDate		date		default getdate()	not null,	--�������
	expectDate		date							not null,	--Ӧ������
	returnDate		date		default null		null	,	--�黹����
	judge			char(2)		default '��'		not null,	--�ж��Ƿ�黹ͼ��
	cost			money		default 0					,	--�ܻ���

	constraint RecordPK primary key(recordID),
	constraint RecordFK1 foreign key(readerID) references reader(readerID),
	constraint RecordFK2 foreign key(isbn) references Book(isbn) ON UPDATE CASCADE,

	constraint RecordBorrowDateCK check(borrowDate <= getDate()),
	constraint RecordReturnCK check(returnDate >= borrowDate),
	constraint RecordJudgeCK check(judge in ('��','��')),
	constraint RecordCostCK check(cost>=0),
)
GO
-------
-------

CREATE TABLE Recharge(	--��ֵ��
	rechargeID		int			identity(1,1)		not null,	--��ֵ����
	readerID		char(6)							not null,	--���߱��
	workerID		char(6)							not null,	--������Ա���

	rechargeDate	date		default getdate()	not null,	--��ֵ����
	amount			money							not null	--��ֵ���

	constraint RechargePK primary key(rechargeID),
	constraint RechargeFK1 foreign key(readerID) references Reader(readerID),
	constraint RechargeFK2 foreign key(workerID) references Worker(workerID),

	constraint RechargeDateCK check(rechargeDate <= getDate()),
)
GO
-------
-------
CREATE TABLE Label(		--ͼ���ǩ��
	labelID	int				identity(1,1)	not null,	--��ǩ��
	isbn	char(6)							not null,	--ͼ����
	label	varchar(20)						not null,	--ͼ���ǩ

	constraint LabelPK primary key(labelID),
	constraint LabelFK foreign key(isbn) references Book(isbn) ON UPDATE CASCADE,
)
GO
-------
-------


SELECT *
FROM Book