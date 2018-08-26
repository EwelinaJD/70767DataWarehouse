USE [TestDB]
GO

--	problem:
--	rozwi�zanie #2 zak�ada, �e te sytuacje mog� istnie� i powinny by� poprawiane
--	mo�e si� jednak okaza�, �e tak nie jest, tzn:

	--	nie powinni�my tworzy� tych pracownik�w, bo s� zwolnieni
	--	dane finansowe nadal powinny by� przenoszone w 100%
	--	chcemy wszystkie b��dne dane mie� w jednym miejscu - czyli jak si� pojawi kilka niepoprawnych u�ytkownik� AB1, AB2, AB3, to chcemy
		-- mie� ich wpisy na jednej pozycji wymiaru Employee

-- Propozycja #3		-> Dopychamy wymiar techniczny jednym u�ytkownikiem "UNKNOWN"
					--	-> �adujemy na niego wszystkie wpisy z niepoprawnym EmpId
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
    SELECT
        '!UN'
    ,   '!B��dneWpisy'
    ,   '!B��dneWpisy'


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

-- UPDATE
-------------------------------------------------

	--	b��dne wpisy maj� [DimEmployeeKey] = NULL
	--	trzeba je zmieni� na [DimEmployeeKey] wiersza UNKNOWN
	--	ale tego numeru nie znamy bo si� nadaje automatycznie
	--	tzn... teraz znamy bo jest 3'ci, ale w rzeczywisto�ci mo�e by� dowolny

	-- pierwsze podej�cie ("brzydkie"), cz�� a) oraz b) nale�y odpali� RAZEM
		
		--	a) szukamy klucza

			DECLARE @UnknownKey INT 
			SET @UnknownKey = ( SELECT DimEmployeeKey
								FROM	[dest].[DimEmployee]
								WHERE [EmpId] = '!UN'
								)

			PRINT @UnknownKey

		--	b) nadpisujemy klucz

			UPDATE [dest].[FactPayment]
			SET [DimEmployeeKey] = @UnknownKey
			WHERE [DimEmployeeKey] IS NULL

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