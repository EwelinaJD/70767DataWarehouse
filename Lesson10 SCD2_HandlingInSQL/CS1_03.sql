USE TestDB
GO

IF OBJECT_ID('dbo.usp_Reload_DWH_DimEmployeeSCD2', 'P') IS NOT NULL DROP PROC [dbo].[usp_Reload_DWH_DimEmployeeSCD2]
GO

CREATE PROC [dbo].[usp_Reload_DWH_DimEmployeeSCD2]
AS
BEGIN
	
	--	Procedura ma aktualizowa� [dbo].[DWH_DimEmployeeSCD2]
	--	mamy nast�puj�ce scenariusze:
	--	1/ pojawia si� nowy pracownik, trzeba go doda�
	--	2/ znika pracownik, trzeba go skasowa� albo wy��czy�
	--	3/ zmieniaj� si� dane:
		--	3a/ chcemy mie� wgl�d do historii = kolumny [Salary],[BonusRate],[JobPosition],[TeamName]
		--	3b/ nie chcemy mie� wgl�du do historii, nadpisujemy dane
				
	----------------------------------------------------------------------------------------------------

		IF OBJECT_ID('tempdb..#Temporary')	IS NOT NULL DROP TABLE	#Temporary
		IF OBJECT_ID('tempdb..#Actions')	IS NOT NULL DROP TABLE	#Actions

	--	Do tabeli tymczasowej zrzucamy aktualny stan system�w �r�d�owych
	--	jest SCD2 wi�c nie mo�emy go tak po prostu za�adowa�/podmieni�
	----------------------------------------------------------------------------------------------------

		SELECT
			hr.[PESEL]
		,	hr.[EmpFirstName]
		,	hr.[EmpLastName]
		,	hr.[DateOfBirth]
		,	fi.[Salary]
		,	fi.[BonusRate]
		,	og.[JobPosition]
		,	og.[TeamName]
		INTO #Temporary
		FROM
					[dbo].[HR_Employees]	AS hr
		INNER JOIN  [dbo].[FIN_Payroll]		AS fi	ON hr.[PESEL]	= fi.[PESEL]
		INNER JOIN  [dbo].[ORG_Structure]	AS og	ON hr.[PESEL]	= og.[PESEL]


	--	Por�wnujemy ze sob� dwie tabele: aktualny stan system�w �r�d�owych oraz dane w tabeli wymiaru
	--
	--	je�eli co� jest w a nie ma w �rodle, to znaczy, �e zwolniony i trzeba wiersz skasowa� - flaga DELETE
	--	je�eli co� jest w �rodle a nie ma w wymiarze, to znaczy, �e nowy i trzeba wiersz doda� - flaga INSERT
	--	je�eli co� jest tu i tu i zmieni�y si� kolumny, kt�rych nie chcemy trzyma� w SCD 2 to robimy zwyk�y UPDATE - flaga UPDATE_NoHistory
	--	je�eli co� jest tu i tu i zmieni�a si� jakakolwiek z kolumn, kt�rych warto�� chcemy trzyma� w SCD2 to wiersz tzeba wy��czy� (nie kasowa�!!) i doda� nowy - flaga UPDATE_SCD2
	----------------------------------------------------------------------------------------------------

		SELECT
			[PESEL]			=	COALESCE(src.PESEL,tgt.PESEL)
		,	[ActionTime]	=	CAST ( GETDATE() AS DATETIME2(0))
		,	[Action]		=	CASE 
									WHEN	src.PESEL	IS NULL 
									THEN	'DELETE'
									WHEN	tgt.PESEL	IS NULL 
									THEN	'INSERT'
									WHEN	src.PESEL = tgt.PESEL
											AND	(		tgt.[Salary]		=	src.[Salary]
													OR	tgt.[BonusRate]		=	src.[BonusRate]
													OR	tgt.[JobPosition]	=	src.[JobPosition]
													OR	tgt.[TeamName]		=	src.[TeamName]
											)
											AND(		tgt.[EmpFirstName]	<>	src.[EmpFirstName]	
													OR	tgt.[EmpLastName]	<>	src.[EmpLastName]	
													OR	tgt.[DateOfBirth]	<>	src.[DateOfBirth]	
											)
									THEN	'UPDATE_NoHistory'
									WHEN	src.PESEL = tgt.PESEL
											AND	(		tgt.[Salary]		<> src.[Salary]
													OR	tgt.[BonusRate]		<> src.[BonusRate]
													OR	tgt.[JobPosition]	<> src.[JobPosition]
													OR	tgt.[TeamName]		<> src.[TeamName]
											)
									THEN	'UPDATE_SCD2'
									ELSE	'NO ACTION'
									END
		INTO #Actions
		FROM	
						#Temporary					AS src
		FULL OUTER JOIN	[dbo].[DWH_DimEmployeeSCD2]	AS tgt	ON src.PESEL		=	tgt.PESEL
															AND	tgt.IsActive	=	1
		WHERE	1=1
	
		SELECT *
		FROM #Actions

	----------------------------------------------------------------------------------------------------

		--	INSERT NEW ROWS
		--------------------------------------------

			INSERT INTO [dbo].[DWH_DimEmployeeSCD2]
			(
					[PESEL]				
				,	[EmpFirstName]		
				,	[EmpLastName]		
				,	[DateOfBirth]		
				,	[Salary]			
				,	[BonusRate]			
				,	[JobPosition]		
				,	[TeamName]			

				,	[IsActive]			
				,	[BegDateTime]		
				,	[EndDateTime]		
			)
			SELECT
				[PESEL]			=	tmp.[PESEL]
			,	[EmpFirstName]	=	tmp.[EmpFirstName]
			,	[EmpLastName]	=	tmp.[EmpLastName]
			,	[DateOfBirth]	=	tmp.[DateOfBirth]
			,	[Salary]		=	tmp.[Salary]
			,	[BonusRate]		=	tmp.[BonusRate]
			,	[JobPosition]	=	tmp.[JobPosition]
			,	[TeamName]		=	tmp.[TeamName]

			,	[IsActive]			=	1
			,	[BegDateTime]		=	act.ActionTime
			,	[EndDateTime]		=	NULL	
			FROM	
						#Temporary	AS tmp
			INNER JOIN	#Actions	AS act ON tmp.PESEL = act.PESEL
			WHERE
				act.[Action] = 'INSERT'

		--	DELETE OLD ROWS (nie kasujemy a wy��czamy)
		--------------------------------------------

			UPDATE trg
			SET
				[IsActive]			=	0
			,	[EndDateTime]		=	DATEADD(s, -1, act.ActionTime)	
			FROM	
						[dbo].[DWH_DimEmployeeSCD2]	AS trg
			INNER JOIN	#Actions					AS act ON trg.PESEL = act.PESEL
			WHERE 1=1
			AND trg.IsActive = 1
			AND act.[Action] = 'DELETE'

		--	UPDATE CHANGES No History
		--------------------------------------------

			UPDATE trg
			SET
				[EmpFirstName]	=	tmp.[EmpFirstName]	
			,	[EmpLastName]	=	tmp.[EmpLastName]	
			,	[DateOfBirth]	=	tmp.[DateOfBirth]	
			FROM	
						[dbo].[DWH_DimEmployeeSCD2]	AS trg
			INNER JOIN	#Actions					AS act ON trg.PESEL = act.PESEL
			INNER JOIN	#Temporary					AS tmp ON tmp.PESEL = act.PESEL
			WHERE 1=1
			AND trg.IsActive = 1
			AND act.[Action] = 'UPDATE_NoHistory'
			;

		--	UPDATE CHANGES SC2
		--------------------------------------------

			UPDATE trg
			SET
				[IsActive]			=	0
			,	[EndDateTime]		=	DATEADD(s, -1, act.ActionTime)	
			FROM	
						[dbo].[DWH_DimEmployeeSCD2]	AS trg
			INNER JOIN	#Actions					AS act ON trg.PESEL = act.PESEL
			WHERE 1=1
			AND trg.IsActive = 1
			AND act.[Action] = 'UPDATE_SCD2'
			;

			INSERT INTO [dbo].[DWH_DimEmployeeSCD2]
			(
					[PESEL]				
				,	[EmpFirstName]		
				,	[EmpLastName]		
				,	[DateOfBirth]		
				,	[Salary]			
				,	[BonusRate]			
				,	[JobPosition]		
				,	[TeamName]			

				,	[IsActive]			
				,	[BegDateTime]		
				,	[EndDateTime]		
			)
			SELECT
				[PESEL]			=	tmp.[PESEL]
			,	[EmpFirstName]	=	tmp.[EmpFirstName]
			,	[EmpLastName]	=	tmp.[EmpLastName]
			,	[DateOfBirth]	=	tmp.[DateOfBirth]
			,	[Salary]		=	tmp.[Salary]
			,	[BonusRate]		=	tmp.[BonusRate]
			,	[JobPosition]	=	tmp.[JobPosition]
			,	[TeamName]		=	tmp.[TeamName]

			,	[IsActive]			=	1
			,	[BegDateTime]		=	act.ActionTime
			,	[EndDateTime]		=	NULL	
			FROM	
						#Temporary	AS tmp
			INNER JOIN	#Actions	AS act ON tmp.PESEL = act.PESEL
			WHERE
				act.[Action] = 'UPDATE_SCD2'

END