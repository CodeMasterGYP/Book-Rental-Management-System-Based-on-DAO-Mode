USE BookRentalSystemDB
GO

insert into Book values('000004','图书','二月河', '机械工业出版社', '2019-01-16', 7, 0, 50, 1.3)
insert into Book values('000005','computer','peter', '机械工业出版社', '2019-01-16', 4, 0, 35, 1.3)
insert into Book values('000006','明朝那些事儿','当年明月', '清华大学出版社', '2019-01-16', 7, 0, 50, 1.3)
insert into Book values('000007','三体','刘慈欣', '人民出版社', '2019-01-16', 4, 0, 35, 1.3)


insert into Reader values('000001','000001','罗辑', '男', '00000000001', 500)
insert into Reader values('000002','000002','Sharlock', '男', '00000000002', 50.5)
insert into Reader values('000003','000003','Tusk', '男', '00000000003', 3333)
insert into Reader values('000004','000004','彭于晏', '男', '00000000004', 1300)


insert into Worker values('111111','111111','员工1', '女', '11111111111')