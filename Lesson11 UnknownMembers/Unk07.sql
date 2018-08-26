USE [TestDB]
GO

-- Propozycja #3b		-> To samo co w #3 ale bardziej elegancko
-------------------------------------------------

-- Czyszczenie
-------------------------------------------------

	TRUNCATE TABLE [dest].[DimEmployee]
	TRUNCATE TABLE [dest].[FactPayment]
	;

-- �adowanie wymiaru
-------------------------------------------------

    INSERT  INTO [dest].[DimEmployee]
    (		[EmpId]
		,	[EmpFirstName]
		,	[EmpLastName]
	)
    SELECT
        [EmpId]
    ,   [EmpFirstName]
    ,   [EmpLastName]
    FROM
        [src].[Emps]
	;

	--	VVV tutaj zmiana VVV
	--	chcemy, �eby nasz '!UN' mia� zawsze ten sam numer
	--	skoro IDENTITY nadaje numery od 1 w g�r�, to nadajmy mu numer (-1)


		--	ten kod wywo�a b��d
		--	Cannot insert explicit value for identity column in table 'DimEmployee' when IDENTITY_INSERT is set to OFF.

			INSERT  INTO [dest].[DimEmployee]
			(		[DimEmployeeKey]
				,	[EmpId]
				,	[EmpFirstName]
				,	[EmpLastName]
			)
			SELECT
				-1
			,	'!UN'
			,   '!B��dneWpisy'
			,   '!B��dneWpisy'

		--	domy�lnie nie da si� po prostu wpisa� dowolnej liczby w kolumn� z IDENTITY
		--	ale da si� to wy��czy� poleceniem IDENTITY_INSERT

		--	pr�bujemy jeszcze raz:

		SET IDENTITY_INSERT [dest].[DimEmployee] ON

			INSERT  INTO [dest].[DimEmployee]
			(		[DimEmployeeKey]
				,	[EmpId]
				,	[EmpFirstName]
				,	[EmpLastName]
			)
			SELECT
				-1
			,	'!UN'
			,   '!B��dneWpisy'
			,   '!B��dneWpisy'

		SET IDENTITY_INSERT [dest].[DimEmployee] OFF
		;

		--	powinno by� ok:

		SELECT *
		FROM [dest].[DimEmployee]

-- �adowanie fakt�w
-------------------------------------------------

	--	mogliby�my zrobi� to tak samo jak w #3 a potem wszystkie NULL'e podmieni� na (-1)
	--	ale mo�emy to zrobi� jesze szybciej -> tzn, podmienia� je od razu a nie poprzez UPDATE:

		INSERT INTO [dest].[FactPayment]
		(		[PaymentId]
			,	[DimEmployeeKey]
			,	[DateId]
			,	[Amount]
		)
		SELECT 
			[p].[PaymentId]
		,	ISNULL([e].[DimEmployeeKey], -1)		--	<<== je�eli jest NULL, to zamie� na -1
		,	[p].[DateId]
		,	[p].[Amount]
		FROM 
					[src].[Payments]		AS p
		LEFT JOIN	[dest].[DimEmployee]	AS e ON [e].[EmpId] = [p].[EmpId]
		;

-- sprawdzamy
-------------------------------------------------
	
	SELECT * FROM [dest].[DimEmployee]
	SELECT * FROM [dest].[FactPayment]
	;

	-- wygl�da OK!

--	sprawdzamy dok�adniej
--	czy suma systemu �r�d�owego = suma DWH
-------------------------------------------------

	SELECT SUM([Amount])
	FROM [src].[Payments]

	SELECT SUM([Amount])
	FROM [dest].[FactPayment]

	-- wygl�da OK!

--	sprawdzamy jeszcze dok�adniej
-------------------------------------------------

	SELECT [p].[EmpId], SUM([Amount])
	FROM [src].[Payments] AS p
	GROUP BY [p].[EmpId]

	SELECT [e].[EmpId], SUM([Amount])
	FROM [dest].[FactPayment] AS p
	INNER JOIN [dest].[DimEmployee] AS e ON [e].[DimEmployeeKey] = [p].[DimEmployeeKey]
	GROUP BY [e].[EmpId]

	--	wygl�da OK!