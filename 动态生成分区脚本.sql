--���ɷ����ű�
DECLARE @DataBaseName NVARCHAR(50)--���ݿ�����
DECLARE @TableName NVARCHAR(50)--������
DECLARE @ColumnName NVARCHAR(50)--�ֶ�����
DECLARE @PartNumber INT--��Ҫ�ֶ��ٸ���
DECLARE @Location NVARCHAR(50)--��������ļ���·��
DECLARE @Size NVARCHAR(50)--������ʼ����С
DECLARE @FileGrowth NVARCHAR(50)--�����ļ�����
--DECLARE @FunValue INT--�����ֶ�ֵ
DECLARE @i INT
DECLARE @y INT      --��ʼ���
DECLARE @m INT      --��ʼ�·�
DECLARE @d INT      --��ʼ��
DECLARE @dayGap INT --�����ֶ�ֵ ����
DECLARE @PartNumberStr NVARCHAR(50)
DECLARE @sql NVARCHAR(max)
DECLARE @ValueStart NVARCHAR(50)

--�����������
SET @DataBaseName = 'HEJIEXUN'
SET @TableName = 'DYNAMINE_A_REAL_DATA'
SET @ColumnName = 'TIME'
SET @PartNumber = 500
SET @Location = 'C:\HejiexunServer\Database\'
SET @Size = '80MB'
SET @FileGrowth = '30%'

SET @y = 2015
SET @m = 1
SET @d = 1
SET @dayGap = 3

--1.�����ļ���
SET @i = 1
PRINT '--1.�����ļ���'
WHILE @i <= @PartNumber
BEGIN
    SET @PartNumberStr =  RIGHT('000' + CONVERT(NVARCHAR,@i),4)
    SET @sql = 'ALTER DATABASE ['+@DataBaseName +']
ADD FILEGROUP [FG_'+@TableName+'_'+@ColumnName+'_'+@PartNumberStr+']'
    PRINT @sql + CHAR(13)
    SET @i=@i+1
END

--2.�����ļ�
SET @i = 1
PRINT CHAR(13)+'--2.�����ļ�'
WHILE @i <= @PartNumber
BEGIN
    SET @PartNumberStr =  RIGHT('000' + CONVERT(NVARCHAR,@i),4)
    SET @sql = 'ALTER DATABASE ['+@DataBaseName +']
ADD FILE
(NAME = N''FG_'+@TableName+'_'+@ColumnName+'_'+@PartNumberStr+'_data'',FILENAME = N'''+@Location+'FG_'+@TableName+'_'+@ColumnName+'_'+@PartNumberStr+'_data.ndf'',SIZE = '+@Size+', FILEGROWTH = '+@FileGrowth+' )
TO FILEGROUP [FG_'+@TableName+'_'+@ColumnName+'_'+@PartNumberStr+'];'
    PRINT @sql + CHAR(13)
    SET @i=@i+1
END


--3.������������
PRINT CHAR(13)+'--3.������������'
DECLARE @FunValueStr NVARCHAR(MAX) 

--SET @FunValueStr = substring(@FunValueStr,1,len(@FunValueStr)-1)
SET @sql = 'CREATE PARTITION FUNCTION
Fun_'+@TableName+'_'+@ColumnName+'(DATETIME) AS
RANGE RIGHT
FOR VALUES('
PRINT @sql

SET @i = 1
SET @FunValueStr = ''
WHILE @i < @PartNumber
BEGIN
    SET @FunValueStr = @FunValueStr + '''' + RIGHT(CONVERT(NVARCHAR, @y),4) + '-' + RIGHT('0' + CONVERT(NVARCHAR, @m),2) + '-' + RIGHT('0' + CONVERT(NVARCHAR, @d),2) + ' 00:00:00.000'','
    SET @d = @d + @dayGap
	IF (@d > 30 OR (@m = 2 AND @d > 28))  --������Ҫ���⴦��һ��
        BEGIN
            SET @d = 1
            SET @m = @m + 1
            if (@m > 12)
                BEGIN
                    SET @m = 1
                    SET @y = @y + 1
                END
        END
    IF (@i = @PartNumber - 1)
		BEGIN
			SET @FunValueStr = substring(@FunValueStr,1,len(@FunValueStr)-1)
		END
    PRINT @FunValueStr
    SET @FunValueStr = ''
    SET @i=@i+1
END
PRINT ')' + CHAR(13)



--4.������������
PRINT CHAR(13)+'--4.������������'
DECLARE @FileGroupStr NVARCHAR(MAX) 
--SET @FileGroupStr = substring(@FileGroupStr,1,len(@FileGroupStr)-1)
SET @sql = 'CREATE PARTITION SCHEME
Sch_'+@TableName+'_'+@ColumnName+' AS
PARTITION Fun_'+@TableName+'_'+@ColumnName+'
TO('
PRINT @sql
SET @i = 1
SET @FileGroupStr = ''
WHILE @i <= @PartNumber
BEGIN
    SET @PartNumberStr =  RIGHT('000' + CONVERT(NVARCHAR,@i),4)
    SET @FileGroupStr = @FileGroupStr + '[FG_'+@TableName+'_'+@ColumnName+'_'+@PartNumberStr+'],'
    
    IF (@i = @PartNumber)
		BEGIN
			SET @FileGroupStr = substring(@FileGroupStr,1,len(@FileGroupStr)-1)
		END
    PRINT @FileGroupStr
    SET @FileGroupStr = ''
    
    SET @i=@i+1
END
PRINT ')'



--5.���������ļ�¼��
PRINT CHAR(13)+'--5.���������ļ�¼��'
SET @sql = 'SELECT $PARTITION.Fun_'+@TableName+'_'+@ColumnName+'('+@ColumnName+') AS Partition_num,
  MIN('+@ColumnName+') AS Min_value,MAX('+@ColumnName+') AS Max_value,COUNT(1) AS Record_num
FROM dbo.'+@TableName+'
GROUP BY $PARTITION.Fun_'+@TableName+'_'+@ColumnName+'('+@ColumnName+')
ORDER BY $PARTITION.Fun_'+@TableName+'_'+@ColumnName+'('+@ColumnName+');'
PRINT @sql + CHAR(13)