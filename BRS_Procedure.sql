USE BookRentalSystemDB
GO

-----------
--Procedure
-----------
--/*******************************���߽���************************************/		OK
--����֮ǰ���ж��˻�����Ƿ�С�ڵ���0,�������ܽ�
--���鼮���Ϊ0���ܽ�
--ͬ���鼮ֻ�ܽ�һ��
IF EXISTS (SELECT * FROM dbo.sysobjects
		WHERE id = object_id(N'[dbo].[BorrowProcedure]') AND OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[BorrowProcedure]
GO
CREATE PROCEDURE BorrowProcedure(@readerID char(6), @isbn char(6), @day int)
AS
BEGIN
	SET NOCOUNT ON
	--�ж��鼮����Ƿ�Ϊ0
	DECLARE @storage INT
	SELECT @storage=storage FROM Book WHERE isbn=@isbn
	IF @storage <= 0
		PRINT '������Ϊ0,����ʧ��!'
	ELSE
	BEGIN
		--�ж��Ƿ��ѽ������
		IF EXISTS(SELECT * FROM Record WHERE readerID=@readerID AND isbn=@isbn)
			PRINT '���ѽ������,����ʧ��!'
		ELSE
		BEGIN
			DECLARE @expectDate Date
			SET @expectDate = dateAdd(dd, @day, getDate())

			DECLARE @cost money, @dailyPrice money, @balance money
			SELECT @dailyPrice = dailyPrice FROM Book WHERE isbn=@isbn
			SELECT @balance=balance FROM Reader WHERE readerID=@readerID
			SET @cost = @dailyPrice * @day
			IF @cost > @balance
				PRINT '����,���ȳ�ֵ!'
			ELSE
			BEGIN
				--���Խ���
				--��Record���в����¼
				INSERT Record(readerID, isbn, borrowDate, expectDate, judge, cost)
					VALUES(@readerID, @isbn, getDate(), @expectDate, '��', @cost)
				--����Book��
				UPDATE Book
				SET storage = storage - 1
				WHERE isbn=@isbn
				--����Reader��
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
	
--/*******************************���߻���************************************/		OK
--�ж϶����Ƿ���, ���������Ҫ���㳬�ڷ���*2,  ���ж��˻�����Ƿ��㹻, ��������ɹ�
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
	--�жϼ�¼�Ƿ����
	IF EXISTS(SELECT * FROM Record WHERE readerID=@readerID AND isbn=@isbn)
	BEGIN
		--���㳬�ڷ���
		DECLARE @beyond INT, @dailyPrice money
		SELECT @dailyPrice=dailyPrice FROM Book WHERE isbn=@isbn
		IF @expectDate >= @returnDate
			SET @beyond = 0		--��δ������Ϊ0
		ELSE
		BEGIN
			SET @beyond = dateDiff(day, @expectDate, @returnDate) * @dailyPrice * 2	--�������������
			PRINT '���ν��鳬��,��Ҫ��������!'
		END
		
		--�ж�����Ƿ���ڵ��ڳ��ڷ���
		DECLARE @balance money
		SELECT @balance=balance FROM Reader WHERE readerID=@readerID
		IF @beyond > @balance
			PRINT '����,����ʧ��!'
		ELSE
		BEGIN
			--����Record��
			UPDATE Record
			SET returnDate=@returnDate, cost=cost+@beyond, judge='��'
			WHERE readerID=@readerID AND isbn=@isbn

			--����Book���storage
			UPDATE Book
			SET storage=storage+1
			WHERE isbn=@isbn

			--����Reader���balance
			UPDATE Reader
			SET balance=balance-@beyond
			WHERE readerID=@readerID

			PRINT '����ɹ�'
		END
	END

	SET NOCOUNT OFF
END
GO

--/*******************************���߳�ֵ************************************/	OK
IF EXISTS (SELECT * FROM dbo.sysobjects
		WHERE id = object_id(N'[dbo].[RechargeProcedure]') AND OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[RechargeProcedure]
GO
CREATE PROCEDURE RechargeProcedure(@readerID CHAR(6), @workerID char(6), @amount money)
AS
BEGIN
	SET NOCOUNT ON

	--�жϽ���Ƿ�Ϸ�
	IF @amount <= 0
		PRINT '��ֵ���Ϸ�,��ֵʧ��!'
	ELSE
	BEGIN
		--��Recharge���в����¼
		INSERT Recharge(readerID, workerID, rechargeDate, amount)
			VALUES(@readerID, @workerID, getDate(), @amount)

		--�޸�Reader���м�¼
		UPDATE Reader
		SET balance = balance + @amount
		WHERE readerID = @readerID

		PRINT '��ֵ�ɹ�!'
	END

	SET NOCOUNT OFF
END
GO

--/*******************************���ߵ�½************************************/	OK
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

--/*******************************Ա����½************************************/	OK
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

--/*******************************�鿴����************************************/	OK
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
--/*******************************************   Reader ��   ********************************************/
--/******************************************************************************************************/

--------------------------------------------------------------------------
--	Reader�� �� �洢����	���������ֶ�)	OK
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
--	Reader�� ɾ �洢����	���������ֶΣ�	OK
--------------------------------------------------------------------------
--���� Reader �����ɾ������
/*
IF EXISTS (SELECT * FROM dbo.sysobjects
		WHERE id = object_id(N'[dbo].[ReaderDelete]') AND OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[ReaderDelete]
GO
CREATE PROCEDURE ReaderDelete(@readerID	CHAR(6))
AS
BEGIN
	SET NOCOUNT ON

	IF EXISTS(SELECT * FROM Record WHERE readerID=@readerID AND judge='��')
	BEGIN
		PRINT '���û�����δ�黹��ͼ�飬ɾ��ʧ��!'
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
--	Reader�� �� �洢����	���������ֶΣ�	OK
--------------------------------------------------------------------------
--�����޸� readerID
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
--	Reader�� �� �洢����	���������ֶΣ�	OK
--------------------------------------------------------------------------
--����Reader�� ReaderID ���Ҷ���
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

--����Reader�� ReaderID ���Ҷ���
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

--����Reader������ ReaderName ���Ҷ���
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

--��ѯ���ж���	
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
--/*******************************************   Book ��   **********************************************/
--/******************************************************************************************************/

--------------------------------------------------------------------------
--	Book�� �� �洢����	���������ֶΣ�	NO
--------------------------------------------------------------------------
--���һ����	������� loanNum һ��Ϊ0
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
	--�ж�isbn���Ƿ��Ѵ���
	IF EXISTS(SELECT * FROM Book WHERE isbn=@isbn)
		PRINT '�������Ѵ���,���ʧ��!'
	ELSE
	BEGIN
		SET @loanNum = 0
		INSERT Book(isbn,bookName,author,press,pressDate,storage,loanNum,price,dailyPrice)
			VALUES(@isbn,@bookName,@author,@press,@pressDate,@storage,@loanNum,@price,@dailyPrice)
		PRINT '��ӳɹ�!'
	END
	SET NOCOUNT OFF
END
GO
--Ϊһ���Ѵ��ڵ�����Ӽ���
IF EXISTS (SELECT * FROM dbo.sysobjects
		WHERE id = object_id(N'[dbo].[BookAddOne]') AND OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[BookAddOne]
GO
CREATE PROCEDURE BookAddOne(@isbn char(6), @amount INT)
AS
BEGIN
	SET NOCOUNT ON

	--���жϸ������Ƿ��Ѵ���
	IF NOT EXISTS(SELECT * FROM Book WHERE isbn=@isbn)
		PRINT '������������,���ʧ��!'
	ELSE
	BEGIN
		UPDATE Book
		SET storage = storage + @amount
		WHERE isbn = @isbn
		PRINT '��ӳɹ�!'
	END

	SET NOCOUNT OFF
END
GO

--------------------------------------------------------------------------
--	Book�� ɾ �洢����	���������ֶΣ�
--------------------------------------------------------------------------
--������ɾ������

--------------------------------------------------------------------------
--	Book�� �� �洢����	���������ֶΣ�	NO
--------------------------------------------------------------------------
--���²��������޸�ͼ���� isbn
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
		PRINT '���鲻����,����ʧ��!'
	ELSE
	BEGIN
		SET @loanNum = 0
		UPDATE Book
		SET bookName=@bookName, author=@author, press=@press, pressDate=@pressDate,
				storage=@storage, loanNum=@loanNum, price=@price, dailyPrice=@dailyPrice
		WHERE isbn = @isbn

		PRINT '���³ɹ�!'
	END

	SET NOCOUNT OFF
END
GO
--------------------------------------------------------------------------
--	Book�� �� �洢����	���������ֶΣ�OK
--------------------------------------------------------------------------
--���� Book �� isbn ��Ų��ҵ�����¼
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

--���� Book �� isbn ��Ų��ҵ�����¼
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

--���� Book ������ bookName �������м�¼
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

--���� Book �����м�¼
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
--/*******************************************   Worker ��   ********************************************/
--/******************************************************************************************************/

--------------------------------------------------------------------------
--	Worker�� �� �洢����	���������ֶΣ�
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
	--�ж� workerID �Ƿ��Ѵ���
	IF EXISTS(SELECT * FROM Worker WHERE workerID=@workerID)
		PRINT '�ù����Ѵ���,���ʧ��!'
	ELSE
	BEGIN
		INSERT Worker(workerID,workerPassword,workerName,sex,phoneNumber)
			VALUES(@workerID,@workerPassword,@workerName,@sex,@phoneNumber)
		PRINT '��ӳɹ�!'
	END
	SET NOCOUNT OFF
END
GO

--------------------------------------------------------------------------
--	Worker�� ɾ �洢����	���������ֶΣ�
--------------------------------------------------------------------------
--������ɾ������

--------------------------------------------------------------------------
--	Worker�� �� �洢����	���������ֶΣ�
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
		PRINT '��Ա��������,����ʧ��!'
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
--	Worker�� �� �洢����	���������ֶΣ�
--------------------------------------------------------------------------
--�����Ų�ѯһ��Ա��
IF EXISTS (SELECT * FROM dbo.sysobjects
		WHERE id = object_id(N'[dbo].[WorkerQuery]') AND OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[WorkerQuery]
GO
CREATE PROCEDURE WorkerQuery @workerID CHAR(6)
AS
BEGIN
	SET NOCOUNT ON

	IF NOT EXISTS(SELECT * FROM Worker WHERE workerID=@workerID)
		PRINT '��Ա��������!'
	ELSE
	BEGIN
		SELECT * 
		FROM Worker
		WHERE workerID=@workerID
	END

	SET NOCOUNT OFF
END
GO

--��ѯ����Ա����Ϣ
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
--/*******************************************   Record ��   ********************************************/
--/******************************************************************************************************/

--------------------------------------------------------------------------
--	Record�� �� �洢����	���������ֶΣ�
--------------------------------------------------------------------------
--�� Record ������Ӳ����ɽ���ʱ�Ĵ洢���� BorrowProcedure ���
--���ٵ����� Record ����в������

--------------------------------------------------------------------------
--	Record�� ɾ �洢����	���������ֶΣ�
--------------------------------------------------------------------------
--����Record�����ɾ������

--------------------------------------------------------------------------
--	Record�� �� �洢����	���������ֶΣ�
--------------------------------------------------------------------------
--�� Record ����޸Ĳ����ɻ���ʱ�Ĵ洢���� ReturnProcedure ���
--���ٵ����� Record ������޸Ĳ���

--------------------------------------------------------------------------
--	Record�� �� �洢����	���������ֶΣ�
--------------------------------------------------------------------------
--���� readerID �鿴��¼
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

--���� isbn �鿴��¼
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

--�鿴���е� Record ��Ϣ
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

--���ն��߱�Ų���, �鿴ĳ�����ߵ� Record ��Ϣ
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

--���ս������� borrowDate �鿴 Record ��ļ�¼
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
--���ն��߱�� readerID �ͽ������� borrowDate �鿴 Record ��ļ�¼




--/******************************************************************************************************/
--/*******************************************   Recharge ��   ******************************************/
--/******************************************************************************************************/

--------------------------------------------------------------------------
--	Recharge�� �� �洢����	���������ֶΣ�
--------------------------------------------------------------------------
--�� Recharge ������Ӳ����ɳ�ֵʱ�Ĵ洢���� RechargeProcedure ���
--���ٵ����� Recharge ����в������

--------------------------------------------------------------------------
--	Recharge�� ɾ �洢����	���������ֶΣ�
--------------------------------------------------------------------------
--����Recharge�����ɾ������

--------------------------------------------------------------------------
--	Recharge�� �� �洢����	���������ֶΣ�
--------------------------------------------------------------------------
--���� Recharge ������޸Ĳ���

--------------------------------------------------------------------------
--	Recharge�� �� �洢����	���������ֶΣ�
--------------------------------------------------------------------------
--���� rechargeID �鿴һ����¼
IF EXISTS (SELECT * FROM dbo.sysobjects
		WHERE id = object_id(N'[dbo].[RechargeQuery]') AND OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[RechargeQuery]
GO
CREATE PROCEDURE RechargeQuery @rechargeID CHAR(6)
AS
BEGIN
	SET NOCOUNT ON

	IF NOT EXISTS(SELECT * FROM Recharge WHERE rechargeID=@rechargeID)
		PRINT '�ü�¼������!'
	ELSE
	BEGIN
		SELECT * 
		FROM Recharge
		WHERE rechargeID = @rechargeID
	END

	SET NOCOUNT OFF
END
GO

--�鿴���е� Recharge ��Ϣ
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

--���ն��߱�Ų���, �鿴ĳ�����ߵ� Recharge ��Ϣ
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
--/*************************** ****************   Label ��   ********************************************/
--/******************************************************************************************************/

--------------------------------------------------------------------------
--	Label�� �� �洢����	���������ֶΣ�
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
--	Label�� ɾ �洢����	���������ֶΣ�
--------------------------------------------------------------------------
--���� labelID ɾ��ĳһ����ǩ
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

--ɾ��ָ����� isbn �����б�ǩ
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
--	Label�� �� �洢����	���������ֶΣ�
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
		PRINT '�ñ�ǩ��¼������,����ʧ��!'
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
--	Label�� �� �洢����	���������ֶΣ�
--------------------------------------------------------------------------
--���ݱ�ǩ�� labelID �鿴��Ӧ�ı�ǩ
IF EXISTS (SELECT * FROM dbo.sysobjects
		WHERE id = object_id(N'[dbo].[LabelQuery]') AND OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[LabelQuery]
GO
CREATE PROCEDURE LabelQuery @labelID CHAR(6)
AS
BEGIN
	SET NOCOUNT ON

	IF NOT EXISTS(SELECT * FROM Label WHERE labelID=@labelID)
		PRINT '�ñ�ǩ������!'
	ELSE
	BEGIN
		SELECT * 
		FROM Label
		WHERE labelID = @labelID
	END

	SET NOCOUNT OFF
END
GO

--������� isbn �鿴��������б�ǩ
IF EXISTS (SELECT * FROM dbo.sysobjects
		WHERE id = object_id(N'[dbo].[LabelQueryByIsbn]') AND OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[LabelQueryByIsbn]
GO
CREATE PROCEDURE LabelQueryByIsbn @isbn CHAR(6)
AS
BEGIN
	SET NOCOUNT ON

	IF NOT EXISTS(SELECT * FROM Book WHERE isbn=@isbn)
		PRINT '���鲻����!'
	ELSE
	BEGIN
		SELECT * 
		FROM Label
		WHERE isbn = @isbn
	END

	SET NOCOUNT OFF
END
GO











