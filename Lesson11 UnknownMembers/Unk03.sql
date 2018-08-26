USE [TestDB]
GO

-- �adowanie danych
-------------------------------------------------

	--	klucze DimEmployeeKey oraz FactPaymentKey nadawane s� podczas towrzenia wierszy
	--	�aduj�c tabel� dest.FactPayment potrzebujemy DimEmployeeKey, kt�re utworzone zostanie podczas �adownia dest.DimEmployee
	--
	--	z tego powodu oknieczne jest �adowanie danych w kolejno�ci 1/ Wymiar, 2/ Fakt

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
	INNER JOIN	[dest].[DimEmployee]	AS e ON [e].[EmpId] = [p].[EmpId]
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

	-- jest �le...

-- gdzie jest problem?
-------------------------------------------------

	SELECT *
	FROM 
				[src].[Payments] AS p
	LEFT JOIN	[src].[Emps] AS e ON [e].[EmpId] = [p].[EmpId]
	WHERE e.[EmpId] IS NULL

	--	w systemie �r�d�owym s� braki
	--	na tabelach nie ma za�o�onych fizycznych kluczy obcych
	--	i nie jest pilnowana poprawno�� danych
	--	kto� skasowa� u�ytkownika a jego p�atno�ci zosta�y

	--	b��d generuje "INNER JOIN" u�yty do doci�gni�cia klucza obcego przy �adowaniu fakt�w

--	co z tym zrobi�?
--	...