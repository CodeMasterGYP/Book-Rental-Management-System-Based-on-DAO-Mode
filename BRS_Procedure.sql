USE BookRentalSystemDB
GO

-----------
--Procedure
-----------
--/*******************************读者借书************************************/		OK
--借书之前先判断账户余额是否小于等于0,若是则不能借
--若书籍库存为0则不能借
--同种书籍只能借一次
IF EXISTS (SELECT * FROM dbo.sysobjects
		WHERE id = object_id(N'[dbo].[BorrowProcedure]') AND OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[BorrowProcedure]
GO
CREATE PROCEDURE BorrowProcedure(@readerID char(6), @isbn char(6), @day int)
AS
BEGIN
	SET NOCOUNT ON
	--判断书籍库存是否为0
	DECLARE @storage INT
	SELECT @storage=storage FROM Book WHERE isbn=@isbn
	IF @storage <= 0
		PRINT '该书库存为0,借书失败!'
	ELSE
	BEGIN
		--判断是否已借过该书
		IF EXISTS(SELECT * FROM Record WHERE readerID=@readerID AND isbn=@isbn)
			PRINT '您已借过该书,借书失败!'
		ELSE
		BEGIN
			DECLARE @expectDate Date
			SET @expectDate = dateAdd(dd, @day, getDate())

			DECLARE @cost money, @dailyPrice money, @balance money
			SELECT @dailyPrice = dailyPrice FROM Book WHERE isbn=@isbn
			SELECT @balance=balance FROM Reader WHERE readerID=@readerID
			SET @cost = @dailyPrice * @day
			IF @cost > @balance
				PRINT '余额不足,请先充值!'
			ELSE
			BEGIN
				--可以借书
				--向Record表中插入记录
				INSERT Record(readerID, isbn, borrowDate, expectDate, judge, cost)
					VALUES(@readerID, @isbn, getDate(), @expectDate, '否', @cost)
				--更新Book表
				UPDATE Book
				SET storage = storage - 1
				WHERE isbn=@isbn
				--更新Reader表
				UPDATE Reader
				SET balance = @balance - @cost
				WHERE readerID = @readerID
			END
		END
	END
	SET NOCOUNT OFF
END
GO
--------
--------
	
--/*******************************读者还书************************************/		OK
--判断读者是否超期, 如果超期需要计算超期费用*2,  并判断账户余额是否足够, 若够则还书成功
IF EXISTS (SELECT * FROM dbo.sysobjects
		WHERE id = object_id(N'[dbo].[ReturnProcedure]') AND OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[ReturnProcedure]
GO
CREATE PROCEDURE ReturnProcedure(@readerID varchar(6), @isbn varchar(6))
AS
BEGIN
	SET NOCOUNT ON
	DECLARE @borrowDate Date, @expectDate Date, @returnDate Date
	SET @returnDate = getDate()

	SELECT @borrowDate=borrowDate, @expectDate=expectDate 
	FROM Record 
	WHERE readerID=@readerID AND isbn=@isbn
	--判断记录是否存在
	IF EXISTS(SELECT * FROM Record WHERE readerID=@readerID AND isbn=@isbn)
	BEGIN
		--计算超期罚金
		DECLARE @beyond INT, @dailyPrice money
		SELECT @dailyPrice=dailyPrice FROM Book WHERE isbn=@isbn
		IF @expectDate >= @returnDate
			SET @beyond = 0		--若未超期则为0
		ELSE
		BEGIN
			SET @beyond = dateDiff(day, @expectDate, @returnDate) * @dailyPrice * 2	--若超期则计算金额
			PRINT '本次借书超期,需要交付罚金!'
		END
		
		--判断余额是否大于等于超期罚金
		DECLARE @balance money
		SELECT @balance=balance FROM Reader WHERE readerID=@readerID
		IF @beyond > @balance
			PRINT '余额不足,还书失败!'
		ELSE
		BEGIN
			--更新Record表
			UPDATE Record
			SET returnDate=@returnDate, cost=cost+@beyond, judge='是'
			WHERE readerID=@readerID AND isbn=@isbn

			--更新Book表的storage
			UPDATE Book
			SET storage=storage+1
			WHERE isbn=@isbn

			--更新Reader表的balance
			UPDATE Reader
			SET balance=balance-@beyond
			WHERE readerID=@readerID

			PRINT '还书成功'
		END
	END

	SET NOCOUNT OFF
END
GO

--/*******************************读者充值************************************/	OK
IF EXISTS (SELECT * FROM dbo.sysobjects
		WHERE id = object_id(N'[dbo].[RechargeProcedure]') AND OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[RechargeProcedure]
GO
CREATE PROCEDURE RechargeProcedure(@readerID CHAR(6), @workerID char(6), @amount money)
AS
BEGIN
	SET NOCOUNT ON

	--判断金额是否合法
	IF @amount <= 0
		PRINT '充值金额不合法,充值失败!'
	ELSE
	BEGIN
		--向Recharge表中插入记录
		INSERT Recharge(readerID, workerID, rechargeDate, amount)
			VALUES(@readerID, @workerID, getDate(), @amount)

		--修改Reader表中记录
		UPDATE Reader
		SET balance = balance + @amount
		WHERE readerID = @readerID

		PRINT '充值成功!'
	END

	SET NOCOUNT OFF
END
GO

--/*******************************读者登陆************************************/	OK
IF EXISTS (SELECT * FROM dbo.sysobjects
		WHERE id = object_id(N'[dbo].[ReaderLogin]') AND OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[ReaderLogin]
GO
CREATE PROCEDURE ReaderLogin(@readerID varchar(6), @readerPassword varchar(6))
AS
BEGIN
	SET NOCOUNT ON

	SELECT *
	FROM Reader
	WHERE readerID=@readerID AND readerPassword=@readerPassword

	SET NOCOUNT OFF
END
GO

--/*******************************员工登陆************************************/	OK
IF EXISTS (SELECT * FROM dbo.sysobjects
		WHERE id = object_id(N'[dbo].[WorkerLogin]') AND OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[WorkerLogin]
GO
CREATE PROCEDURE WorkerLogin(@workerID varchar(6), @workerPassword varchar(6))
AS
BEGIN
	SET NOCOUNT ON

	SELECT * 
	FROM Worker
	WHERE workerID=@workerID AND workerPassword=@workerPassword

	SET NOCOUNT OFF
END
GO

--/*******************************查看借阅************************************/	OK
IF EXISTS (SELECT * FROM dbo.sysobjects
		WHERE id = object_id(N'[dbo].[ViewBorrow]') AND OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[ViewBorrow]
GO
CREATE PROCEDURE ViewBorrow
AS
BEGIN
	SET NOCOUNT ON

	SELECT Book.isbn, bookName, storage, count(*) borrowNum
	FROM Book, Record
	WHERE Book.isbn = Record.isbn
	GROUP BY Book.isbn, bookName, storage
	ORDER BY borrowNum DESC

	SET NOCOUNT OFF
END
GO


--/******************************************************************************************************/
--/*******************************************   Reader 表   ********************************************/
--/******************************************************************************************************/

--------------------------------------------------------------------------
--	Reader表 增 存储过程	（按主键字段)	OK
--------------------------------------------------------------------------
IF EXISTS (SELECT * FROM dbo.sysobjects
		WHERE id = object_id(N'[dbo].[ReaderAdd]') AND OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[ReaderAdd]
GO
CREATE PROCEDURE ReaderAdd(@readerID char(6), @readerPassword char(6),
							@readerName varchar(20), @sex char(2),
							@phoneNumber char(11), @balance money)
AS
BEGIN
	SET NOCOUNT ON
	SET @phoneNumber=ltrim(@phoneNumber)
	SET @phoneNumber=rtrim(@phoneNumber)
	INSERT Reader(readerID,readerPassword,readerName,sex,phoneNumber,balance)
		VALUES(@readerID,@readerPassword,@readerName,@sex,@phoneNumber,@balance)

	SET NOCOUNT OFF
END
GO

--------------------------------------------------------------------------
--	Reader表 删 存储过程	（按主键字段）	OK
--------------------------------------------------------------------------
--不对 Reader 表进行删除操作
/*
IF EXISTS (SELECT * FROM dbo.sysobjects
		WHERE id = object_id(N'[dbo].[ReaderDelete]') AND OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[ReaderDelete]
GO
CREATE PROCEDURE ReaderDelete(@readerID	CHAR(6))
AS
BEGIN
	SET NOCOUNT ON

	IF EXISTS(SELECT * FROM Record WHERE readerID=@readerID AND judge='否')
	BEGIN
		PRINT '该用户存在未归还的图书，删除失败!'
	END
	ELSE
	BEGIN
		DELETE FROM READER 
		WHERE readerID=@readerID
	END

	SET NOCOUNT OFF
END
GO
*/
--------------------------------------------------------------------------
--	Reader表 改 存储过程	（按主键字段）	OK
--------------------------------------------------------------------------
--不能修改 readerID
IF EXISTS (SELECT * FROM dbo.sysobjects
		WHERE id = object_id(N'[dbo].[ReaderUpdate]') AND OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[ReaderUpdate]
GO
CREATE PROCEDURE ReaderUpdate(@readerID CHAR(6), @readerPassword varchar(6), 
								@readerName varchar(20), @sex char(2),
								@phoneNumber char(11))
AS
BEGIN
	SET NOCOUNT ON

	UPDATE Reader
	SET readerPassword=@readerPassword, readerName=@readerName, sex=@sex, phoneNumber=@phoneNumber
	WHERE readerID = @readerID

	SET NOCOUNT OFF
END
GO

--------------------------------------------------------------------------
--	Reader表 查 存储过程	（按主键字段）	OK
--------------------------------------------------------------------------
--按照Reader的 ReaderID 查找读者
IF EXISTS (SELECT * FROM dbo.sysobjects
		WHERE id = object_id(N'[dbo].[ReaderQuery]') AND OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[ReaderQuery]
GO
CREATE PROCEDURE ReaderQuery @ReaderID CHAR(6)
AS
BEGIN
	SET NOCOUNT ON

	SELECT * 
	FROM Reader
	WHERE readerID = @readerID

	SET NOCOUNT OFF
END
GO

--按照Reader的 ReaderID 查找读者
IF EXISTS (SELECT * FROM dbo.sysobjects
		WHERE id = object_id(N'[dbo].[ReaderQueryByReaderID]') AND OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[ReaderQueryByReaderID]
GO
CREATE PROCEDURE ReaderQueryByReaderID @readerID CHAR(6)
AS
BEGIN
	SET NOCOUNT ON

	SELECT *
	FROM Reader
	WHERE readerID = @readerID

	SET NOCOUNT OFF
END
GO

--按照Reader的姓名 ReaderName 查找读者
IF EXISTS (SELECT * FROM dbo.sysobjects
		WHERE id = object_id(N'[dbo].[ReaderQueryByReaderName]') AND OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[ReaderQueryByReaderName]
GO
CREATE PROCEDURE ReaderQueryByReaderName @readerName varchar(20)
AS
BEGIN
	SET NOCOUNT ON

	SELECT *
	FROM Reader
	WHERE readerName = @readerName

	SET NOCOUNT OFF
END
GO

--查询所有读者	
IF EXISTS (SELECT * FROM dbo.sysobjects
		WHERE id = object_id(N'[dbo].[ReaderQueryAll]') AND OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[ReaderQueryAll]
GO
CREATE PROCEDURE ReaderQueryAll
AS
BEGIN
	SET NOCOUNT ON

	SELECT * 
	FROM Reader

	SET NOCOUNT OFF
END
GO

--/******************************************************************************************************/
--/*******************************************   Book 表   **********************************************/
--/******************************************************************************************************/

--------------------------------------------------------------------------
--	Book表 增 存储过程	（按主键字段）	NO
--------------------------------------------------------------------------
--添加一种书	借出数量 loanNum 一定为0
IF EXISTS (SELECT * FROM dbo.sysobjects
		WHERE id = object_id(N'[dbo].[BookAdd]') AND OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[BookAdd]
GO
CREATE PROCEDURE BookAdd(@isbn char(6), @bookName varchar(20),
							@author varchar(20), @press varchar(20),
							@pressDate date, @storage int=0,
							@loanNum int=0,@price money=0, 
							@dailyPrice money=0)
AS
BEGIN
	SET NOCOUNT ON
	--判断isbn号是否已存在
	IF EXISTS(SELECT * FROM Book WHERE isbn=@isbn)
		PRINT '该种书已存在,添加失败!'
	ELSE
	BEGIN
		SET @loanNum = 0
		INSERT Book(isbn,bookName,author,press,pressDate,storage,loanNum,price,dailyPrice)
			VALUES(@isbn,@bookName,@author,@press,@pressDate,@storage,@loanNum,@price,@dailyPrice)
		PRINT '添加成功!'
	END
	SET NOCOUNT OFF
END
GO
--为一种已存在的书添加几本
IF EXISTS (SELECT * FROM dbo.sysobjects
		WHERE id = object_id(N'[dbo].[BookAddOne]') AND OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[BookAddOne]
GO
CREATE PROCEDURE BookAddOne(@isbn char(6), @amount INT)
AS
BEGIN
	SET NOCOUNT ON

	--先判断该种书是否已存在
	IF NOT EXISTS(SELECT * FROM Book WHERE isbn=@isbn)
		PRINT '该种树不存在,添加失败!'
	ELSE
	BEGIN
		UPDATE Book
		SET storage = storage + @amount
		WHERE isbn = @isbn
		PRINT '添加成功!'
	END

	SET NOCOUNT OFF
END
GO

--------------------------------------------------------------------------
--	Book表 删 存储过程	（按主键字段）
--------------------------------------------------------------------------
--不进行删除操作

--------------------------------------------------------------------------
--	Book表 改 存储过程	（按主键字段）	NO
--------------------------------------------------------------------------
--更新操作不能修改图书编号 isbn
IF EXISTS (SELECT * FROM dbo.sysobjects
		WHERE id = object_id(N'[dbo].[BookUpdate]') AND OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[BookUpdate]
GO
CREATE PROCEDURE BookUpdate(@isbn char(6), @bookName varchar(20),
							@author varchar(20), @press varchar(20),
							@pressDate date, @storage int=0,
							@loanNum int=0, @price money=0,
							@dailyPrice money=0)
AS
BEGIN
	SET NOCOUNT ON
	IF NOT EXISTS(SELECT * FROM Book WHERE isbn=@isbn)
		PRINT '该书不存在,更新失败!'
	ELSE
	BEGIN
		SET @loanNum = 0
		UPDATE Book
		SET bookName=@bookName, author=@author, press=@press, pressDate=@pressDate,
				storage=@storage, loanNum=@loanNum, price=@price, dailyPrice=@dailyPrice
		WHERE isbn = @isbn

		PRINT '更新成功!'
	END

	SET NOCOUNT OFF
END
GO
--------------------------------------------------------------------------
--	Book表 查 存储过程	（按主键字段）OK
--------------------------------------------------------------------------
--按照 Book 的 isbn 编号查找单条记录
IF EXISTS (SELECT * FROM dbo.sysobjects
		WHERE id = object_id(N'[dbo].[BookQuery]') AND OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[BookQuery]
GO
CREATE PROCEDURE BookQuery @isbn CHAR(6)
AS
BEGIN
	SET NOCOUNT ON

	SELECT * 
	FROM Book
	WHERE isbn = @isbn

	SET NOCOUNT OFF
END
GO

--按照 Book 的 isbn 编号查找单条记录
IF EXISTS (SELECT * FROM dbo.sysobjects
		WHERE id = object_id(N'[dbo].[BookQueryByIsbn]') AND OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[BookQueryByIsbn]
GO
CREATE PROCEDURE BookQueryByIsbn @isbn CHAR(6)
AS
BEGIN
	SET NOCOUNT ON

	SELECT * 
	FROM Book
	WHERE isbn = @isbn

	SET NOCOUNT OFF
END
GO

--按照 Book 的书名 bookName 查找所有记录
IF EXISTS (SELECT * FROM dbo.sysobjects
		WHERE id = object_id(N'[dbo].[BookQueryByBookName]') AND OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[BookQueryByBookName]
GO
CREATE PROCEDURE BookQueryByBookName @bookName varchar(20)
AS
BEGIN
	SET NOCOUNT ON

	SELECT * 
	FROM Book
	WHERE bookName=@bookName

	SET NOCOUNT OFF
END
GO

--查找 Book 的所有记录
IF EXISTS (SELECT * FROM dbo.sysobjects
		WHERE id = object_id(N'[dbo].[BookQueryAll]') AND OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[BookQueryAll]
GO
CREATE PROCEDURE BookQueryAll
AS
BEGIN
	SET NOCOUNT ON

	SELECT * 
	FROM Book

	SET NOCOUNT OFF
END
GO

--/******************************************************************************************************/
--/*******************************************   Worker 表   ********************************************/
--/******************************************************************************************************/

--------------------------------------------------------------------------
--	Worker表 增 存储过程	（按主键字段）
--------------------------------------------------------------------------
IF EXISTS (SELECT * FROM dbo.sysobjects
		WHERE id = object_id(N'[dbo].[WorkerAdd]') AND OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[WorkerAdd]
GO
CREATE PROCEDURE WorkerAdd(@workerID char(6), @workerPassword char(6), @workerName varchar(20),
							@sex char(2), @phoneNumber char(11))
AS
BEGIN
	SET NOCOUNT ON
	--判断 workerID 是否已存在
	IF EXISTS(SELECT * FROM Worker WHERE workerID=@workerID)
		PRINT '该工号已存在,添加失败!'
	ELSE
	BEGIN
		INSERT Worker(workerID,workerPassword,workerName,sex,phoneNumber)
			VALUES(@workerID,@workerPassword,@workerName,@sex,@phoneNumber)
		PRINT '添加成功!'
	END
	SET NOCOUNT OFF
END
GO

--------------------------------------------------------------------------
--	Worker表 删 存储过程	（按主键字段）
--------------------------------------------------------------------------
--不进行删除操作

--------------------------------------------------------------------------
--	Worker表 改 存储过程	（按主键字段）
--------------------------------------------------------------------------
IF EXISTS (SELECT * FROM dbo.sysobjects
		WHERE id = object_id(N'[dbo].[WorkerUpdate]') AND OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[WorkerUpdate]
GO
CREATE PROCEDURE WorkerUpdate(@workerID char(6), @workerPassword char(6), 
								@workerName char(6), @sex char(2),
								@phoneNumber char(11))
AS
BEGIN
	SET NOCOUNT ON
	IF NOT EXISTS(SELECT * FROM Worker WHERE workerID=@workerID)
		PRINT '该员工不存在,更新失败!'
	ELSE
	BEGIN
		UPDATE Worker
		SET workerPassword=@workerPassword, workerName=@workerName, sex=@sex,
			phoneNumber=@phoneNumber
		WHERE workerID=@workerID
	END

	SET NOCOUNT OFF
END
GO

--------------------------------------------------------------------------
--	Worker表 查 存储过程	（按主键字段）
--------------------------------------------------------------------------
--按工号查询一个员工
IF EXISTS (SELECT * FROM dbo.sysobjects
		WHERE id = object_id(N'[dbo].[WorkerQuery]') AND OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[WorkerQuery]
GO
CREATE PROCEDURE WorkerQuery @workerID CHAR(6)
AS
BEGIN
	SET NOCOUNT ON

	IF NOT EXISTS(SELECT * FROM Worker WHERE workerID=@workerID)
		PRINT '该员工不存在!'
	ELSE
	BEGIN
		SELECT * 
		FROM Worker
		WHERE workerID=@workerID
	END

	SET NOCOUNT OFF
END
GO

--查询所有员工信息
IF EXISTS (SELECT * FROM dbo.sysobjects
		WHERE id = object_id(N'[dbo].[WorkerQueryAll]') AND OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[WorkerQueryAll]
GO
CREATE PROCEDURE WorkerQueryAll
AS
BEGIN
	SET NOCOUNT ON

	SELECT * 
	FROM Worker

	SET NOCOUNT OFF
END
GO
--/******************************************************************************************************/
--/*******************************************   Record 表   ********************************************/
--/******************************************************************************************************/

--------------------------------------------------------------------------
--	Record表 增 存储过程	（按主键字段）
--------------------------------------------------------------------------
--对 Record 表的增加操作由借书时的存储过程 BorrowProcedure 完成
--不再单独对 Record 表进行插入操作

--------------------------------------------------------------------------
--	Record表 删 存储过程	（按主键字段）
--------------------------------------------------------------------------
--不对Record表进行删除操作

--------------------------------------------------------------------------
--	Record表 改 存储过程	（按主键字段）
--------------------------------------------------------------------------
--对 Record 表的修改操作由还书时的存储过程 ReturnProcedure 完成
--不再单独对 Record 表进行修改操作

--------------------------------------------------------------------------
--	Record表 查 存储过程	（按主键字段）
--------------------------------------------------------------------------
--按照 readerID 查看记录
IF EXISTS (SELECT * FROM dbo.sysobjects
		WHERE id = object_id(N'[dbo].[RecordQueryByReaderID]') AND OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[RecordQueryByReaderID]
GO
CREATE PROCEDURE RecordQueryByReaderID @readerID varchar(6)
AS
BEGIN
	SET NOCOUNT ON

	SELECT * 
	FROM Record
	WHERE readerID=@readerID

	SET NOCOUNT OFF
END
GO

--按照 isbn 查看记录
IF EXISTS (SELECT * FROM dbo.sysobjects
		WHERE id = object_id(N'[dbo].[RecordQueryByIsbn]') AND OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[RecordQueryByIsbn]
GO
CREATE PROCEDURE RecordQueryByIsbn @isbn varchar(6)
AS
BEGIN
	SET NOCOUNT ON

	SELECT * 
	FROM Record
	WHERE isbn=@isbn

	SET NOCOUNT OFF
END
GO

--查看所有的 Record 信息
IF EXISTS (SELECT * FROM dbo.sysobjects
		WHERE id = object_id(N'[dbo].[RecordQueryAll]') AND OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[RecordQueryAll]
GO
CREATE PROCEDURE RecordQueryAll
AS
BEGIN
	SET NOCOUNT ON

	SELECT * 
	FROM Record

	SET NOCOUNT OFF
END
GO

--按照读者编号查找, 查看某个读者的 Record 信息
IF EXISTS (SELECT * FROM dbo.sysobjects
		WHERE id = object_id(N'[dbo].[RecordQueryByReaderID]') AND OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[RecordQueryByReaderID]
GO
CREATE PROCEDURE RecordQueryByReaderID @readerID CHAR(6)
AS
BEGIN
	SET NOCOUNT ON

	SELECT * 
	FROM Record
	WHERE readerID = @readerID

	SET NOCOUNT OFF
END
GO

--按照借书日期 borrowDate 查看 Record 表的记录
/*
IF EXISTS (SELECT * FROM dbo.sysobjects
		WHERE id = object_id(N'[dbo].[RecordQueryByBorrowDate]') AND OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[RecordQueryByBorrowDate]
GO
CREATE PROCEDURE RecordQueryByBorrowDate @readerID CHAR(6)
AS
BEGIN
	SET NOCOUNT ON

	SELECT * 
	FROM Record
	WHERE readerID = @readerID

	SET NOCOUNT OFF
END
GO
*/
--按照读者编号 readerID 和借书日期 borrowDate 查看 Record 表的记录




--/******************************************************************************************************/
--/*******************************************   Recharge 表   ******************************************/
--/******************************************************************************************************/

--------------------------------------------------------------------------
--	Recharge表 增 存储过程	（按主键字段）
--------------------------------------------------------------------------
--对 Recharge 表的增加操作由充值时的存储过程 RechargeProcedure 完成
--不再单独对 Recharge 表进行插入操作

--------------------------------------------------------------------------
--	Recharge表 删 存储过程	（按主键字段）
--------------------------------------------------------------------------
--不对Recharge表进行删除操作

--------------------------------------------------------------------------
--	Recharge表 改 存储过程	（按主键字段）
--------------------------------------------------------------------------
--不对 Recharge 表进行修改操作

--------------------------------------------------------------------------
--	Recharge表 查 存储过程	（按主键字段）
--------------------------------------------------------------------------
--按照 rechargeID 查看一条记录
IF EXISTS (SELECT * FROM dbo.sysobjects
		WHERE id = object_id(N'[dbo].[RechargeQuery]') AND OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[RechargeQuery]
GO
CREATE PROCEDURE RechargeQuery @rechargeID CHAR(6)
AS
BEGIN
	SET NOCOUNT ON

	IF NOT EXISTS(SELECT * FROM Recharge WHERE rechargeID=@rechargeID)
		PRINT '该记录不存在!'
	ELSE
	BEGIN
		SELECT * 
		FROM Recharge
		WHERE rechargeID = @rechargeID
	END

	SET NOCOUNT OFF
END
GO

--查看所有的 Recharge 信息
IF EXISTS (SELECT * FROM dbo.sysobjects
		WHERE id = object_id(N'[dbo].[RechargeQueryAll]') AND OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[RechargeQueryAll]
GO
CREATE PROCEDURE RechargeQueryAll
AS
BEGIN
	SET NOCOUNT ON

	SELECT * 
	FROM Recharge

	SET NOCOUNT OFF
END
GO

--按照读者编号查找, 查看某个读者的 Recharge 信息
IF EXISTS (SELECT * FROM dbo.sysobjects
		WHERE id = object_id(N'[dbo].[RechargeQueryByReaderID]') AND OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[RechargeQueryByReaderID]
GO
CREATE PROCEDURE RechargeQueryByReaderID @readerID CHAR(6)
AS
BEGIN
	SET NOCOUNT ON

	SELECT * 
	FROM Recharge
	WHERE readerID = @readerID

	SET NOCOUNT OFF
END
GO


--/******************************************************************************************************/
--/*************************** ****************   Label 表   ********************************************/
--/******************************************************************************************************/

--------------------------------------------------------------------------
--	Label表 增 存储过程	（按主键字段）
--------------------------------------------------------------------------
IF EXISTS (SELECT * FROM dbo.sysobjects
		WHERE id = object_id(N'[dbo].[LabelAdd]') AND OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[LabelAdd]
GO
CREATE PROCEDURE LabelAdd(@labelID int, @isbn char(6), @label varchar(20))
AS
BEGIN
	SET NOCOUNT ON

	INSERT Label(labelID, isbn, label)
		VALUES(@labelID, @isbn, @label)

	SET NOCOUNT OFF
END
GO
--------------------------------------------------------------------------
--	Label表 删 存储过程	（按主键字段）
--------------------------------------------------------------------------
--按照 labelID 删除某一个标签
IF EXISTS (SELECT * FROM dbo.sysobjects
		WHERE id = object_id(N'[dbo].[LabelDelete]') AND OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[LabelDelete]
GO
CREATE PROCEDURE LabelDelete(@labelID int)
AS
BEGIN
	SET NOCOUNT ON

	DELETE Label
	WHERE labelID = @labelID

	SET NOCOUNT OFF
END
GO

--删除指定书号 isbn 的所有标签
IF EXISTS (SELECT * FROM dbo.sysobjects
		WHERE id = object_id(N'[dbo].[LabelDelete]') AND OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[LabelDelete]
GO
CREATE PROCEDURE LabelDelete(@labelID int, @isbn char(6))
AS
BEGIN
	SET NOCOUNT ON

	DELETE Label
	WHERE isbn = @isbn

	SET NOCOUNT OFF
END
GO

--------------------------------------------------------------------------
--	Label表 改 存储过程	（按主键字段）
--------------------------------------------------------------------------
IF EXISTS (SELECT * FROM dbo.sysobjects
		WHERE id = object_id(N'[dbo].[LabelUpdate]') AND OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[LabelUpdate]
GO
CREATE PROCEDURE LabelUpdate(@labelID int, @label varchar(20))
AS
BEGIN
	SET NOCOUNT ON
	IF NOT EXISTS(SELECT * FROM Label WHERE labelID=@labelID)
		PRINT '该标签记录不存在,更新失败!'
	ELSE
	BEGIN
		UPDATE Label
		SET label = @label
		WHERE labelID = @labelID
	END

	SET NOCOUNT OFF
END
GO
--------------------------------------------------------------------------
--	Label表 查 存储过程	（按主键字段）
--------------------------------------------------------------------------
--根据标签号 labelID 查看对应的标签
IF EXISTS (SELECT * FROM dbo.sysobjects
		WHERE id = object_id(N'[dbo].[LabelQuery]') AND OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[LabelQuery]
GO
CREATE PROCEDURE LabelQuery @labelID CHAR(6)
AS
BEGIN
	SET NOCOUNT ON

	IF NOT EXISTS(SELECT * FROM Label WHERE labelID=@labelID)
		PRINT '该标签不存在!'
	ELSE
	BEGIN
		SELECT * 
		FROM Label
		WHERE labelID = @labelID
	END

	SET NOCOUNT OFF
END
GO

--根据书号 isbn 查看该书的所有标签
IF EXISTS (SELECT * FROM dbo.sysobjects
		WHERE id = object_id(N'[dbo].[LabelQueryByIsbn]') AND OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[LabelQueryByIsbn]
GO
CREATE PROCEDURE LabelQueryByIsbn @isbn CHAR(6)
AS
BEGIN
	SET NOCOUNT ON

	IF NOT EXISTS(SELECT * FROM Book WHERE isbn=@isbn)
		PRINT '该书不存在!'
	ELSE
	BEGIN
		SELECT * 
		FROM Label
		WHERE isbn = @isbn
	END

	SET NOCOUNT OFF
END
GO











