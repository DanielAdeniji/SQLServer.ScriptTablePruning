set nocount on
go

use [master]
go


if object_id('[dbo].[sp_ScriptTablePrune]') is null
begin

	exec('create procedure [dbo].[sp_ScriptTablePrune] as ')

end
go

alter procedure [dbo].[sp_ScriptTablePrune] 
as
begin

	set nocount on;
	set XACT_ABORT on;

	/*
		Declare Local Variable Values
	*/
	declare @CHAR_PERIOD    char(1)
	declare @CHAR_SEMICOLON char(1)
	declare @CHAR_NEWLINE  char(2);
	declare @CHAR_GO       char(2);

	declare @CHAR_OBJECTID_IS_NOTNULL varchar(30)
	declare @CHAR_SINGLE_QUOTES     char(1)
	declare @CHAR_PARENTHESIS_OPEN  char(1)
	declare @CHAR_PARENTHESIS_CLOSE char(1)

	/*
		Set Local Variable Values
	*/
	set @CHAR_PERIOD = '.'
	set @CHAR_SEMICOLON = ';';
	set @CHAR_NEWLINE = char(13) + char(10)
	set @CHAR_GO = 'go'

	set @CHAR_OBJECTID_IS_NOTNULL = ' is not null '
	set @CHAR_SINGLE_QUOTES = ''''
	set @CHAR_PARENTHESIS_OPEN = '('
	set @CHAR_PARENTHESIS_CLOSE = ')'


	/*
		1) Foreign Key
				a) NoCheck
				b) Check, Check

		2) Truncate Table or Delete
				a) If Foreign Key exists, issue delete
				b) If Foreign Key does not exist, issue truncate
	*/
	select 
			[sqFKNoCheck] 
				=
						'if object_id'
					+ @CHAR_PARENTHESIS_OPEN
					+ @CHAR_SINGLE_QUOTES
				    + quotename(object_schema_name(tblSFK.parent_object_id))
				    + @CHAR_PERIOD
				    + quotename(object_name(tblSFK.parent_object_id))
					+ @CHAR_SINGLE_QUOTES
					+ @CHAR_PARENTHESIS_CLOSE
					+ @CHAR_OBJECTID_IS_NOTNULL

				    + ' alter table '
				    + quotename(object_schema_name(tblSFK.parent_object_id))
				    + @CHAR_PERIOD
				    + quotename(object_name(tblSFK.parent_object_id))
				    + ' nocheck constraint '
				    + quotename(tblSFK.[name])
				    + @CHAR_SEMICOLON
				    + @CHAR_NEWLINE
				    + @CHAR_GO

		, [sqFKCheck] 
				=

						'if object_id'
				   + @CHAR_PARENTHESIS_OPEN
				   + @CHAR_SINGLE_QUOTES
				   + quotename(object_schema_name(tblSFK.parent_object_id))
				   + @CHAR_PERIOD
				   + quotename(object_name(tblSFK.parent_object_id))
				   + @CHAR_SINGLE_QUOTES
				   + @CHAR_PARENTHESIS_CLOSE
				   + @CHAR_OBJECTID_IS_NOTNULL

				   + ' alter table '
				   + quotename(object_schema_name(tblSFK.parent_object_id))
				   + @CHAR_PERIOD
				   + quotename(object_name(tblSFK.parent_object_id))
				   + ' with check check constraint '
				   + quotename(tblSFK.[name])
				   + @CHAR_NEWLINE
				   + @CHAR_GO

	from   sys.foreign_keys tblSFK

	order by 
			  1



	select 
			 [sqlPrune] 
				  =  case
					   when exists 
							  (
								select *
								from   sys.foreign_keys tblSFK
								where  tblSO.object_id = tblSFK.referenced_object_id
							  ) then 
							      'if object_id'
								+ @CHAR_PARENTHESIS_OPEN
								+ @CHAR_SINGLE_QUOTES
								+ quotename( tblSS.[name] )
								+ @CHAR_PERIOD
								+ quotename( tblSO.[name] )
								+ @CHAR_SINGLE_QUOTES
								+ @CHAR_PARENTHESIS_CLOSE
								+ @CHAR_OBJECTID_IS_NOTNULL
								+ ' delete from ' 
								+ quotename( tblSS.[name] )
								+ @CHAR_PERIOD
								+ quotename( tblSO.[name] )
								+ @CHAR_SEMICOLON
								+ @CHAR_NEWLINE
								+ @CHAR_GO

						else 
							      'if object_id'
								+ @CHAR_PARENTHESIS_OPEN
								+ @CHAR_SINGLE_QUOTES
								+ quotename( tblSS.[name] )
								+ @CHAR_PERIOD
								+ quotename( tblSO.[name] )
								+ @CHAR_SINGLE_QUOTES
								+ @CHAR_PARENTHESIS_CLOSE
								+ @CHAR_OBJECTID_IS_NOTNULL

								+ 'truncate table '

								+ quotename( tblSS.[name] )
								+ @CHAR_PERIOD
								+ quotename( tblSO.[name] )

								+ @CHAR_SEMICOLON
								+ @CHAR_NEWLINE
								+ @CHAR_GO

					  end

	from   sys.objects tblSO

	inner join sys.schemas tblSS

			on tblSO.schema_id = tblSS.schema_id

	where  tblSO.[type] = 'U'

	and    tblSO.is_ms_shipped = 0

	order by 
			  tblSS.[name]
			, tblSO.[name]


end
go

exec sp_MS_MarkSystemObject '[dbo].[sp_ScriptTablePrune]'
go

/*

	use [assist]
	go

	exec [dbo].[sp_ScriptTablePrune] 


*/