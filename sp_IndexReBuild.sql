 -- ================================================
-- Template generated from Template Explorer using:
-- Create Procedure (New Menu).SQL
--
-- Use the Specify Values for Template Parameters 
-- command (Ctrl-Shift-M) to fill in the parameter 
-- values below.
--
-- This block of comments will not be included in
-- the definition of the procedure.
-- ================================================
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Muammer AKILLI
-- Create date: 28.09.2021
-- Description:	Indexleri Listeleyen ve build eden procedure
-- =============================================
ALTER Procedure [dbo].[sp_IndexReBuild] @fragmentationValue INT,@view TINYINT,@buildType TINYINT
As
BEGIN
/*
	  @view		 1  SELECT INDEX LIST
				 0  REBUILD Or REORGANIZE
 
	  @buildType 0 REORGANIZE
				 1 REBUILD

				 30%<=Rebuild
				 5%<=Reorganize
				 5%>do nothing

*/


	IF @view=1
	BEGIN
		SELECT S.name as 'Schema',
		T.name as 'Table',
		I.name as 'Index',
		DDIPS.avg_fragmentation_in_percent,
		DDIPS.page_count
		FROM sys.dm_db_index_physical_stats (DB_ID(), NULL, NULL, NULL, NULL) AS DDIPS
			INNER JOIN sys.tables T on T.object_id = DDIPS.object_id
			INNER JOIN sys.schemas S on T.schema_id = S.schema_id
			INNER JOIN sys.indexes I ON I.object_id = DDIPS.object_id AND DDIPS.index_id = I.index_id
		WHERE DDIPS.database_id = DB_ID() and I.name is not null AND DDIPS.avg_fragmentation_in_percent > @fragmentationValue
		ORDER BY DDIPS.avg_fragmentation_in_percent desc

		RETURN
	END
	ELSE
	BEGIN

		PRINT 'BULID TYPE: ' +CASE @buildType WHEN 0 THEN 'REORGANIZE' ELSE 'REBUILD' END

		DECLARE @tableName VARCHAR(500)
		DECLARE @IndexName VARCHAR(500)
		DECLARE @Str VARCHAR(4000)

		DECLARE RbCursor INSENSITIVE CURSOR FOR
		SELECT T.name,I.name
		FROM sys.dm_db_index_physical_stats (DB_ID(), NULL, NULL, NULL, NULL) AS DDIPS
			INNER JOIN sys.tables T on T.object_id = DDIPS.object_id
			INNER JOIN sys.schemas S on T.schema_id = S.schema_id
			INNER JOIN sys.indexes I ON I.object_id = DDIPS.object_id AND DDIPS.index_id = I.index_id
		WHERE DDIPS.database_id = DB_ID() and I.name is not null AND DDIPS.avg_fragmentation_in_percent > @fragmentationValue
		ORDER BY DDIPS.avg_fragmentation_in_percent desc

		OPEN RbCursor
		FETCH NEXT FROM RbCursor INTO @tableName,@IndexName
		While @@Fetch_Status = 0
		BEGIN
				PRINT 'TABLE NAME :'+@tableName +'  INDEX NAME:'+@IndexName
				IF @buildType=0				
					SELECT @Str='ALTER INDEX '+@IndexName+' ON '+@tableName+' REORGANIZE '
				ELSE
				    SELECT @Str='ALTER INDEX '+@IndexName+' ON '+@tableName+' REBUILD '

				EXEC(@Str)
		
		FETCH NEXT FROM RbCursor INTO  @tableName,@IndexName
		END
		CLOSE RbCursor
		DEALLOCATE RbCursor

	END

	 

END

