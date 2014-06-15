/***********************************************
Create TPCC database script
http://www.mikefal.net

Creates
-Shell database
-Index maintenance stored procedure
-Objects and data should be created using the HammerDB utility (http://hammerora.sourceforge.net/)
***********************************************/

create database tpcc
on (name=tpcc_data,filename='C:\DBFiles\tpcc_data.mdf',size=10GB,filegrowth=1000MB)
log on (name=tpcc_log,filename='C:\DBFiles\tpcc_log.ldf',size=2000MB,filegrowth=500MB);

alter database tpcc set recovery simple;
GO

USE tpcc;
GO

IF exists (select 1 from sys.objects where name = 'IDXMAINT')
BEGIN
	DROP PROCEDURE dbo.IDXMAINT
END;
GO

CREATE PROCEDURE IDXMAINT
AS
BEGIN

	/*****************************
	Simple stored procedure to fix maintenance and statistics after test runs.
	This is extremely simple and should only be used in conjunction with the 
	with the HammerDB database.  It is not recommended this be used in production 
	databases.
	*****************************/
	SET NOCOUNT ON;
	
	declare @v_sql nvarchar(2000) = N'';

	SELECT @V_sql+=N'ALTER INDEX '+ quotename(i.name,'[')+' ON '+quotename(schema_name(o.schema_id),'[')+'.'+quotename(o.name,'[')+' REBUILD;'+char(10)
	from sys.objects o
		join sys.indexes i on (o.object_id = i.object_id)
		join sys.dm_db_index_physical_stats(DB_ID(),NULL,NULL,NULL,'LIMITED') ips on (i.object_id = ips.object_id and i.index_id = ips.index_id)
	WHERE
		ips.avg_fragmentation_in_percent >= 30 
		and page_count >=1000
		and i.index_id > 0;

	exec sp_executesql @v_sql;

	exec sp_updatestats

end;

go
