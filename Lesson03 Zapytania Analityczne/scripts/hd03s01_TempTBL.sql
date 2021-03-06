USE [AdventureworksDW2016CTP3]
GO

--	https://technet.microsoft.com/pl-pl/library/tabele-tymczasowe-i-zmienne-tablicowe-fakty-i-mity.aspx
-----------------------------------------------------------------------------------------------------------------

--	SQL Server pozwala na utworzenie dwóch rodzajów tabel tymczasowych:
--		globalnych, których nazwa jest poprzedzona prefiksem ##
--		lokalnych, których nazwa jest poprzedzona prefiksem #


--	Lokalne tabele tymczasowe są widoczne w ramach jednego połączenia, czyli sesji.	
----------------------------------------------------------------------

	CREATE TABLE #A1
	(
		AccountType			NVARCHAR(50),
		OrganizationName	NVARCHAR(50),
		Amount				FLOAT
	)

	INSERT INTO #A1
	(
		AccountType			,
		OrganizationName	,
		Amount				
	)
	SELECT 
		a.AccountType		, 
		o.OrganizationName	,
		f.Amount
	FROM 
				[dbo].[FactFinance]		AS	f
	INNER JOIN	[dbo].[DimAccount]		AS	a	ON a.AccountKey			= f.AccountKey
	INNER JOIN	[dbo].[DimOrganization]	AS	o	ON o.OrganizationKey	= f.OrganizationKey

	SELECT TOP 100 * 
	FROM #A1

	SELECT *
	FROM tempdb.sys.tables AS t
	WHERE t.name LIKE '%#A%'

	--	Lokalne tabele tymczasowe zostaną usunięte w następujących sytuacjach:
		--	zostanie wywołane polecenie DROP TABLE,
		--	jeśli tabela tymczasowa została utworzona wewnątrz procedury składowanej, to zostanie usunięta po zakończeniu działania procedury,
		--	wszystkie inne tabele tymczasowe zostaną usunięte po zakończeniu sesji, w której zostały utworzone.

	GO

--	Globalne tabele tymczasowe (utworzone z przedrostkiem ##) mają większą widoczność, ponieważ są dostępne dla wszystkich sesji. 
--	Należy jednak zawsze sprawdzać, czy globalna tabela tymczasowa istnieje zanim zostanie utworzona ponownie, 
--	ponieważ w takim wypadku SQL Server zgłosi komunikat o błędzie. 

--	Globalna tabela tymczasowa jest usuwana w momencie, kiedy sesja, w której została utworzona tabela tymczasowa, 
--	została zakończona i tabela nie posiada referencji (odwołań) w innych aktywnych sesjach.

	SELECT 
		a.AccountType		, 
		o.OrganizationName	,
		f.Amount
	INTO #A2
	FROM 
				[dbo].[FactFinance]		AS	f
	INNER JOIN	[dbo].[DimAccount]		AS	a	ON a.AccountKey			= f.AccountKey
	INNER JOIN	[dbo].[DimOrganization]	AS	o	ON o.OrganizationKey	= f.OrganizationKey

	SELECT TOP 100 * 
	FROM #A2

--	
----------------------------------------------------------------------

	SELECT 
		a.AccountType		, 
		o.OrganizationName	,
		f.Amount
	INTO ##A3
	FROM 
				[dbo].[FactFinance]		AS	f
	INNER JOIN	[dbo].[DimAccount]		AS	a	ON a.AccountKey			= f.AccountKey
	INNER JOIN	[dbo].[DimOrganization]	AS	o	ON o.OrganizationKey	= f.OrganizationKey

	SELECT TOP 100 * 
	FROM ##A3

--	
----------------------------------------------------------------------


	SELECT *
	FROM tempdb.sys.tables AS t
	WHERE t.name LIKE '%#A%'

--	Warto wspomnieć jeszcze o kilku istotnych sprawach:
	
	--	Zmienne tabelaryczne powodują znacznie mniej rekompilacji procedur składowanych – zgodnie z artykułem w bazie wiedzy firmy Microsoft.
	--	Transakcje wykonywane na zmiennych tablicowych ograniczają się do operacji UPDATE, co powoduje znaczne zmniejszenie blokad czy zakleszczeń oraz zdecydowanie mniej logowania w dzienniku transakcji.
	--	Zmienne tablicowe nie stanowią o spójności bazy danych, w której  się znajdują, a więc nie działają na nie operacje ROLLBACK TRANSACTION.
	--	Zmiennej tablicowej nie można przypisywać do innej zmiennej tablicowej.
	--	Zmienna tablicowa nie może w swojej strukturze odwoływać się do typów danych użytkownika (UDDT).
	--	SQL Server nie buduje statystyk dla zmiennych tablicowych, wobec czego optymalizator uznaje, że zmienna tablicowa zawsze ma 1 wiersz (niezależnie od faktycznej ilości przechowywanych danych).
	--	Nie można wykonywać operacji TRUNCATE TABLE na zmiennej tablicowej.
	--	Nie można tworzyć nazwanych ograniczeń dla zmiennej tablicowej.
	--	Nazwa zmiennej tabelarycznej zostanie wewnętrznie nadana przez SQL Server.
	--	Jeśli zmienna tablicowa posiada kolumnę typu IDENTITY, to nie można do niej wpisywać wartości wprost, ponieważ nie jest wspierana instrukcją SET IDENTITY_INSERT ON