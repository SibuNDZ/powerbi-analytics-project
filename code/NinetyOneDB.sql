--create database 
BEGIN TRY
   CREATE DATABASE NinetyOneDB;
   PRINT 'Database created successfully!';
END TRY

BEGIN CATCH
   PRINT 'Error creating database';
   PRINT 'ERROR_MESSAGE';
END CATCH
GO

--Use the database
USE NinetyOneDB;
GO

IF OBJECT_ID('dbo.managers', 'U') IS NOT NULL
DROP TABLE dbo.managers;
GO

--create manage table
CREATE TABLE managers (
    manager_id INT PRIMARY KEY IDENTITY(1,1),
	manager_name NVARCHAR(100) NOT NULL,
	department NVARCHAR(100) NOT NULL
);
GO

--Create portfolio table
CREATE TABLE portfolios (
    portfolio_id INT PRIMARY KEY IDENTITY(1,1),
	portfolio_name NVARCHAR(100) NOT NULL,
	manager_id INT NOT NULL,
	inception_date DATE NOT NULL,
	CONSTRAINT fk_portfolios_managers
	    FOREIGN KEY (manager_id)
		REFERENCES managers(manager_id)
);
GO

--Create securities table
CREATE TABLE securities (
    security_id INT PRIMARY KEY IDENTITY(1,1),
	ticker NVARCHAR(20) NOT NULL,
	security_name NVARCHAR(100) NOT NULL,
	sector NVARCHAR(100),
	country NVARCHAR(100)


);

-- Create holdings table
CREATE TABLE holdings (
   holding_id INT PRIMARY KEY IDENTITY(1,1),
   portfolio_id INT NOT NULL,
   security_id INT NOT NULL,
   quantity DECIMAL(18,4) NOT NULL,
   market_value DECIMAL(18,2) NOT NULL,
   as_of_date DATE NOT NULL,
   CONSTRAINT FK_holdings_portfolios
        FOREIGN KEY (portfolio_id)
		REFERENCES portfolios(portfolio_id),
  CONSTRAINT FK_holdings_securities
        FOREIGN KEY  (security_id)
		REFERENCES securities(security_id)
   );
GO


-- Create indexes for better query performance
CREATE INDEX IX_holdings_portfolio_id  ON holdings(portfolio_id);
CREATE INDEX IX_holdings_security_id   ON holdings(security_id);
CREATE INDEX IX_holdings_as_of_date    ON holdings(as_of_date);
CREATE INDEX IX_portfolios_manager_id  ON portfolios(manager_id);
CREATE INDEX IX_securities_ticker      ON securities(ticker);
GO


--insert sample managers
INSERT INTO managers (manager_name, department) VALUES
('Sarah Thompson', 'Global Equity'),
('Michael Chen', 'Fixed Income'),
('Emma Rodriguez', 'Emerging Markets'),
('James Wilson', 'Global Equity'),
('Priya Patel', 'Alternative Investments'),
('David Kim', 'Fixed Income'),
('Alexandra Volkov', 'Emerging Markets'),
('Robert Johnson', 'Multi-Asset'),
('Lisa Zhang', 'ESG Investing'),
('Marcus van der Berg', 'Africa Specialist');
GO

-- Insert sample portfolios
INSERT INTO portfolios (portfolio_name, manager_id, inception_date) VALUES
('Global Equity Growth Fund', 1, '2018-03-15'),
('Emerging Markets Equity Fund', 3, '2019-06-01'),
('Global Government Bond Fund', 2, '2017-09-20'),
('Technology Innovation Fund', 4, '2020-01-10'),
('Sustainable Development Fund', 9, '2021-04-12'),
('High Yield Credit Fund', 6, '2018-11-30'),
('Africa Frontier Markets Fund', 10, '2019-08-15'),
('Multi-Asset Income Fund', 8, '2017-12-05'),
('Infrastructure Debt Fund', 5, '2020-07-22'),
('Asian Equity Opportunities', 7, '2021-02-28');
GO


-- Insert sample securities
INSERT INTO securities (ticker, security_name, sector, country) VALUES
-- US Stocks
('AAPL', 'Apple Inc', 'Technology', 'United States'),
('MSFT', 'Microsoft Corporation', 'Technology', 'United States'),
('GOOGL', 'Alphabet Inc Class A', 'Technology', 'United States'),
('AMZN', 'Amazon.com Inc', 'Consumer Discretionary', 'United States'),
('TSLA', 'Tesla Inc', 'Consumer Discretionary', 'United States'),
('NVDA', 'NVIDIA Corporation', 'Technology', 'United States'),
('META', 'Meta Platforms Inc', 'Technology', 'United States'),
('JPM', 'JPMorgan Chase & Co', 'Financials', 'United States'),
('JNJ', 'Johnson & Johnson', 'Healthcare', 'United States'),
('V', 'Visa Inc', 'Financials', 'United States'),

-- European Stocks
('ASML', 'ASML Holding NV', 'Technology', 'Netherlands'),
('NESN.SW', 'Nestle SA', 'Consumer Staples', 'Switzerland'),
('LVMH.PA', 'LVMH Moet Hennessy Louis Vuitton', 'Consumer Discretionary', 'France'),
('SAP.DE', 'SAP SE', 'Technology', 'Germany'),
('NOVO-B.CO', 'Novo Nordisk A/S', 'Healthcare', 'Denmark'),

-- Asian Stocks
('TSM', 'Taiwan Semiconductor Manufacturing Co', 'Technology', 'Taiwan'),
('BABA', 'Alibaba Group Holding Ltd', 'Technology', 'China'),
('TM', 'Toyota Motor Corporation', 'Consumer Discretionary', 'Japan'),
('005930.KS', 'Samsung Electronics Co Ltd', 'Technology', 'South Korea'),
('RELIANCE.NS', 'Reliance Industries Ltd', 'Energy', 'India'),

-- African Stocks
('NPN.JO', 'Naspers Ltd', 'Technology', 'South Africa'),
('SBK.JO', 'Standard Bank Group Ltd', 'Financials', 'South Africa'),
('MTN.JO', 'MTN Group Ltd', 'Telecommunications', 'South Africa'),
('DANGCEM.LG', 'Dangote Cement Plc', 'Materials', 'Nigeria'),
('EQBNK.LG', 'Ecobank Transnational Inc', 'Financials', 'Nigeria'),

-- Bonds
('US10Y', 'US Treasury 10-Year Note', 'Government Bonds', 'United States'),
('DE10Y', 'German 10-Year Bund', 'Government Bonds', 'Germany'),
('GB10Y', 'UK 10-Year Gilt', 'Government Bonds', 'United Kingdom'),
('ZAR10Y', 'South African 10-Year Bond', 'Government Bonds', 'South Africa'),
('CORP-HY', 'High Yield Corporate Bond Index', 'Corporate Bonds', 'Global'),

-- REITs and Infrastructure
('AMT', 'American Tower Corporation', 'REITs', 'United States'),
('CCI', 'Crown Castle International Corp', 'Infrastructure', 'United States');

-- Insert sample holdings data (multiple dates to show historical data)
-- Global Equity Growth Fund holdings
INSERT INTO holdings (portfolio_id, security_id, quantity, market_value, as_of_date) VALUES
-- December 2024 holdings
(1, 1, 15000.0000, 2850000.00, '2024-12-31'),  -- AAPL
(1, 2, 12000.0000, 4800000.00, '2024-12-31'),  -- MSFT
(1, 3, 8000.0000, 1360000.00, '2024-12-31'),   -- GOOGL
(1, 4, 5000.0000, 750000.00, '2024-12-31'),    -- AMZN
(1, 6, 3000.0000, 4200000.00, '2024-12-31'),   -- NVDA
(1, 11, 2000.0000, 1800000.00, '2024-12-31'),  -- ASML
(1, 16, 25000.0000, 2750000.00, '2024-12-31'), -- TSM

-- November 2024 holdings (showing some changes)
(1, 1, 14500.0000, 2755000.00, '2024-11-30'),  -- AAPL
(1, 2, 12500.0000, 4875000.00, '2024-11-30'),  -- MSFT
(1, 3, 8200.0000, 1394000.00, '2024-11-30'),   -- GOOGL
(1, 4, 5200.0000, 780000.00, '2024-11-30'),    -- AMZN
(1, 6, 2800.0000, 3920000.00, '2024-11-30'),   -- NVDA

-- Emerging Markets Equity Fund holdings
(2, 17, 50000.0000, 4500000.00, '2024-12-31'), -- BABA
(2, 19, 30000.0000, 3600000.00, '2024-12-31'), -- Samsung
(2, 20, 25000.0000, 3750000.00, '2024-12-31'), -- Reliance
(2, 21, 20000.0000, 6000000.00, '2024-12-31'), -- Naspers
(2, 22, 40000.0000, 2800000.00, '2024-12-31'), -- Standard Bank
(2, 24, 35000.0000, 1750000.00, '2024-12-31'), -- Dangote Cement

-- Global Government Bond Fund holdings
(3, 26, 1000000.0000, 95000000.00, '2024-12-31'), -- US10Y
(3, 27, 500000.0000, 45000000.00, '2024-12-31'),  -- DE10Y
(3, 28, 300000.0000, 27000000.00, '2024-12-31'),  -- GB10Y
(3, 29, 200000.0000, 18000000.00, '2024-12-31'),  -- ZAR10Y

-- Technology Innovation Fund holdings
(4, 1, 10000.0000, 1900000.00, '2024-12-31'),  -- AAPL
(4, 2, 8000.0000, 3200000.00, '2024-12-31'),   -- MSFT
(4, 3, 6000.0000, 1020000.00, '2024-12-31'),   -- GOOGL
(4, 6, 2000.0000, 2800000.00, '2024-12-31'),   -- NVDA
(4, 7, 4000.0000, 2400000.00, '2024-12-31'),   -- META
(4, 11, 1500.0000, 1350000.00, '2024-12-31'),  -- ASML
(4, 14, 3000.0000, 600000.00, '2024-12-31'),   -- SAP
(4, 16, 15000.0000, 1650000.00, '2024-12-31'), -- TSM

-- Sustainable Development Fund holdings
(5, 2, 5000.0000, 2000000.00, '2024-12-31'),   -- MSFT
(5, 15, 2000.0000, 260000.00, '2024-12-31'),   -- Novo Nordisk
(5, 12, 1000.0000, 120000.00, '2024-12-31'),   -- Nestle
(5, 31, 800.0000, 160000.00, '2024-12-31'),    -- American Tower
(5, 21, 8000.0000, 2400000.00, '2024-12-31'),  -- Naspers (ESG focused)

-- High Yield Credit Fund holdings
(6, 30, 2000000.0000, 180000000.00, '2024-12-31'), -- High Yield Corporate Bonds

-- Africa Frontier Markets Fund holdings
(7, 21, 100000.0000, 30000000.00, '2024-12-31'), -- Naspers
(7, 22, 150000.0000, 10500000.00, '2024-12-31'), -- Standard Bank
(7, 23, 80000.0000, 6400000.00, '2024-12-31'),   -- MTN
(7, 24, 60000.0000, 3000000.00, '2024-12-31'),   -- Dangote Cement
(7, 25, 40000.0000, 2000000.00, '2024-12-31'),   -- Ecobank

-- Multi-Asset Income Fund holdings
(8, 8, 20000.0000, 3200000.00, '2024-12-31'),   -- JPM
(8, 10, 15000.0000, 3750000.00, '2024-12-31'),  -- Visa
(8, 26, 500000.0000, 47500000.00, '2024-12-31'), -- US10Y
(8, 31, 2000.0000, 400000.00, '2024-12-31'),    -- American Tower
(8, 22, 25000.0000, 1750000.00, '2024-12-31'),  -- Standard Bank

-- Infrastructure Debt Fund holdings
(9, 31, 5000.0000, 1000000.00, '2024-12-31'),   -- American Tower
(9, 32, 3000.0000, 600000.00, '2024-12-31'),    -- Crown Castle
(9, 26, 200000.0000, 19000000.00, '2024-12-31'), -- US Treasury (safe component)

-- Asian Equity Opportunities holdings
(10, 16, 40000.0000, 4400000.00, '2024-12-31'), -- TSM
(10, 17, 30000.0000, 2700000.00, '2024-12-31'), -- BABA
(10, 18, 15000.0000, 2250000.00, '2024-12-31'), -- Toyota
(10, 19, 20000.0000, 2400000.00, '2024-12-31'), -- Samsung
(10, 20, 18000.0000, 2700000.00, '2024-12-31'); -- Reliance

-- Add some additional historical data points for trend analysis
-- Global Equity Growth Fund - October 2024
INSERT INTO holdings (portfolio_id, security_id, quantity, market_value, as_of_date) VALUES
(1, 1, 14000.0000, 2660000.00, '2024-10-31'),  -- AAPL
(1, 2, 12800.0000, 4992000.00, '2024-10-31'),  -- MSFT
(1, 3, 8500.0000, 1445000.00, '2024-10-31'),   -- GOOGL
(1, 6, 2600.0000, 3640000.00, '2024-10-31'),   -- NVDA

-- Emerging Markets Fund - October 2024
(2, 17, 52000.0000, 4680000.00, '2024-10-31'), -- BABA
(2, 19, 32000.0000, 3840000.00, '2024-10-31'), -- Samsung
(2, 21, 18000.0000, 5400000.00, '2024-10-31'); -- Naspers

-- Verify data integrity
--PRINT 'Sample data inserted successfully!';
--PRINT 'Managers: ' + CAST((SELECT COUNT(*) FROM managers) AS VARCHAR(10));
--PRINT 'Portfolios: ' + CAST((SELECT COUNT(*) FROM portfolios) AS VARCHAR(10));
--PRINT 'Securities: ' + CAST((SELECT COUNT(*) FROM securities) AS VARCHAR(10));
--PRINT 'Holdings: ' + CAST((SELECT COUNT(*) FROM holdings) AS VARCHAR(10));

-- Step 4: Verify data integrity (corrected section)
-- Fetch counts into variables first, then print.
DECLARE @managerCount INT;
DECLARE @portfolioCount INT;
DECLARE @securityCount INT;
DECLARE @holdingCount INT;

-- Assuming 'portfolios', 'securities', and 'holdings' tables exist for demonstration.
-- If these tables are not yet created, these SELECT statements will cause errors.
-- Please ensure these tables are created before running this verification section.
SELECT @managerCount = COUNT(*) FROM managers;
-- SELECT @portfolioCount = COUNT(*) FROM portfolios; -- Uncomment and ensure table exists
-- SELECT @securityCount = COUNT(*) FROM securities;   -- Uncomment and ensure table exists
-- SELECT @holdingCount = COUNT(*) FROM holdings;     -- Uncomment and ensure table exists

PRINT 'Sample data insertion verification:';
PRINT 'Managers: ' + CAST(@managerCount AS VARCHAR(10));
-- PRINT 'Portfolios: ' + CAST(@portfolioCount AS VARCHAR(10)); -- Uncomment
-- PRINT 'Securities: ' + CAST(@securityCount AS VARCHAR(10));   -- Uncomment
-- PRINT 'Holdings: ' + CAST(@holdingCount AS VARCHAR(10));     -- Uncomment

-- You can add additional verification queries here, e.g., SELECT * FROM managers;