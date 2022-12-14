USE [ncu_database]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER FUNCTION [dbo].[find_date](@Date date,@NumberOfDay int, @forward int, @include int)
RETURNS @record TABLE 
(
	Dates date
)
AS
BEGIN 
DECLARE @remaining_day int;
DECLARE @current_day int;
DECLARE @current_year INT
DECLARE @current_total_day INT

SELECT @current_day = day_of_stock FROM [dbo].[calendar] WHERE date = @Date AND day_of_stock != -1;
if(@current_day is NULL) RETURN
IF(@forward = 1)
	BEGIN
		SET @remaining_day = @current_day - @NumberOfDay;
		
		IF(@remaining_day > 0)
			if(@include=1)
				insert into @record SELECT date FROM [dbo].[calendar] WHERE day_of_stock BETWEEN @remaining_day+1 AND @current_day AND year(date) = year(@Date);
			else
				insert into @record SELECT date FROM [dbo].[calendar] WHERE day_of_stock BETWEEN @remaining_day AND @current_day-1 AND year(date) = year(@Date);
		ELSE 
			BEGIN
				if(@include=1)
					SET @remaining_day= @remaining_day+1
				else
					SET @current_day=@current_day-1
				insert into  @record SELECT date FROM [dbo].[calendar] WHERE day_of_stock BETWEEN 0 AND @current_day AND year(date) = year(@Date);

				DECLARE cur CURSOR LOCAL for
				SELECT year, total_day FROM [dbo].[year_calendar] order by year ASC  
				open cur

				FETCH next from cur into @current_year, @current_total_day
				WHILE @@FETCH_STATUS = 0 BEGIN
					SET @remaining_day = @remaining_day + @current_total_day;

					IF @remaining_day > 0 
						BEGIN
							insert into  @record SELECT date FROM [dbo].[calendar] WHERE day_of_stock BETWEEN @remaining_day AND @current_total_day AND year(date) = @current_year;
							BREAK
						END
					ELSE
						insert into @record SELECT date FROM [dbo].[calendar] WHERE day_of_stock BETWEEN 0 AND @current_total_day AND year(date) = @current_year;
					FETCH next from cur into @current_year, @current_total_day
				END
			END
	END
IF(@forward = 0)
	BEGIN	
		SET @remaining_day = @current_day + @NumberOfDay;
		
		if(@remaining_day<245)
			BEGIN
			IF(@remaining_day > 0)
				BEGIN
				if(@include=1)
					insert into  @record SELECT date FROM [dbo].[calendar] WHERE day_of_stock BETWEEN @current_day AND @remaining_day-1  AND year(date) = year(@Date);
				else
					insert into  @record SELECT date FROM [dbo].[calendar] WHERE day_of_stock BETWEEN @current_day+1 AND @remaining_day  AND year(date) = year(@Date);
				END
			END
		ELSE 
			BEGIN
				if(@include=1)
					SET @remaining_day= @remaining_day-1
				else
					SET @current_day=@current_day+1
				insert into @record SELECT date FROM [dbo].[calendar] WHERE day_of_stock BETWEEN @current_day AND @remaining_day AND year(date) = year(@Date);

				DECLARE cur CURSOR LOCAL for
				SELECT year, total_day FROM [dbo].[year_calendar] order by year ASC
				open cur

				FETCH next from cur into @current_year, @current_total_day
				WHILE @@FETCH_STATUS = 0 BEGIN
					SET @remaining_day = @remaining_day - @current_total_day;

					IF @remaining_day > 0 
						BEGIN
							insert into  @record SELECT date FROM [dbo].[calendar] WHERE day_of_stock BETWEEN 0 AND @remaining_day AND year(date) = @current_year+1;
							BREAK
						END
					ELSE
						/*insert into @record SELECT date FROM [dbo].[calendar] WHERE day_of_stock BETWEEN 0 AND @current_total_day AND year(date) = @current_year;*/
						break;
					FETCH next from cur into @current_year, @current_total_day
				END
			END
	END
	RETURN
END
