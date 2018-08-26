USE [TestDB]
GO

-- Propozycja #2 -> Dopchajmy wymiar pozycjami, kt�re si� nie pojawi�yw Emp, a pojawi�y w Paym
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

	--	VVV tutaj zmiana VVV --

    INSERT  INTO [dest].[DimEmployee]
    (		[EmpId]
		,	[EmpFirstName]
		,	[EmpLastName]
	)
    SELECT DISTINCT
        [EmpId]
    ,   '!Nieznany'
    ,   '!Nieznany'
    FROM
        [src].[Payments] AS p
	WHERE
		p.[EmpId] NOT IN (SELECT [EmpId] FROM [dest].[DimEmployee])


-- �adowanie fakt�w
-------------------------------------------------

	--	problem #1: sk�d zabra� DimEmployeeKey
	--	rozwi�zanie: JOIN do wymiaru

	INSERT INTO [dest].[FactPayment]
	(		[PaymentId]
		,	[DimEmployeeKey]
		,	[DateId]
		,	[Amount]
	)
	SELECT 
		[p].[PaymentId]
    ,	[e].[DimEmployeeKey]
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

	--	dodatkowo gdzie� na boku tworzymy raport
	--	kt�ry listuje wszystkie pozycje "dopchane" i wysy�amy do uzupe�nienia i poprawienia w systemach

	SELECT *
	FROM [dest].[DimEmployee]
	WHERE [EmpFirstName] = '!Nieznany'

	--	rozwi�zanie jest OK!