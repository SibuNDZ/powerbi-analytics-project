-- Create Power BI Dimensional Model Database
USE NinetyOne;
GO

-- Drop existing tables if they exist (in dependency order)
IF OBJECT_ID('FactHoldings', 'U') IS NOT NULL DROP TABLE FactHoldings;
IF OBJECT_ID('FactPerformance', 'U') IS NOT NULL DROP TABLE FactPerformance;
IF OBJECT_ID('DimBenchmark', 'U') IS NOT NULL DROP TABLE DimBenchmark;
IF OBJECT_ID('DimPortfolio', 'U') IS NOT NULL DROP TABLE DimPortfolio;
IF OBJECT_ID('DimDate', 'U') IS NOT NULL DROP TABLE DimDate;
GO

-- Create DimDate table
CREATE TABLE DimDate (
    DateKey INT PRIMARY KEY,
    Date DATE NOT NULL,
    Year INT NOT NULL,
    Quarter INT NOT NULL,
    Month INT NOT NULL,
    MonthName NVARCHAR(20) NOT NULL,
    WeekOfYear INT NOT NULL,
    DayOfMonth INT NOT NULL,
    DayOfWeek INT NOT NULL,
    DayName NVARCHAR(20) NOT NULL,
    IsWeekend BIT NOT NULL,
    IsMonthEnd BIT NOT NULL,
    IsQuarterEnd BIT NOT NULL,
    IsYearEnd BIT NOT NULL,
    FiscalYear INT NOT NULL,
    FiscalQuarter INT NOT NULL
);
GO

-- Create DimPortfolio table
CREATE TABLE DimPortfolio (
    PortfolioKey INT PRIMARY KEY IDENTITY(1,1),
    PortfolioID NVARCHAR(20) NOT NULL UNIQUE,
    PortfolioName NVARCHAR(100) NOT NULL,
    ManagerName NVARCHAR(100) NOT NULL,
    Department NVARCHAR(50) NOT NULL,
    Strategy NVARCHAR(50) NOT NULL,
    InceptionDate DATE NOT NULL,
    BaseCurrency NCHAR(3) NOT NULL,
    IsActive BIT NOT NULL DEFAULT 1,
    MinimumInvestment DECIMAL(18,2),
    ManagementFee DECIMAL(5,4),
    PerformanceFee DECIMAL(5,4),
    CreatedDate DATETIME2 DEFAULT GETDATE(),
    ModifiedDate DATETIME2 DEFAULT GETDATE()
);
GO

-- Create DimBenchmark table
CREATE TABLE DimBenchmark (
    BenchmarkKey INT PRIMARY KEY IDENTITY(1,1),
    BenchmarkID NVARCHAR(20) NOT NULL UNIQUE,
    BenchmarkName NVARCHAR(100) NOT NULL,
    BenchmarkFamily NVARCHAR(50) NOT NULL,
    AssetClass NVARCHAR(30) NOT NULL,
    Region NVARCHAR(30) NOT NULL,
    Currency NCHAR(3) NOT NULL,
    Provider NVARCHAR(50) NOT NULL,
    IsActive BIT NOT NULL DEFAULT 1,
    CreatedDate DATETIME2 DEFAULT GETDATE(),
    ModifiedDate DATETIME2 DEFAULT GETDATE()
);
GO

-- Create FactPerformance table
CREATE TABLE FactPerformance (
    PerformanceKey BIGINT PRIMARY KEY IDENTITY(1,1),
    DateKey INT NOT NULL,
    PortfolioKey INT NOT NULL,
    BenchmarkKey INT NOT NULL,
    NAV DECIMAL(18,6) NOT NULL,
    TotalReturn DECIMAL(8,6),
    BenchmarkReturn DECIMAL(8,6),
    ExcessReturn DECIMAL(8,6),
    AUM DECIMAL(18,2) NOT NULL,
    NumberOfHoldings INT,
    CashPercentage DECIMAL(5,4),
    TurnoverRate DECIMAL(5,4),
    ExpenseRatio DECIMAL(5,4),
    CreatedDate DATETIME2 DEFAULT GETDATE(),
    CONSTRAINT FK_FactPerformance_DimDate 
        FOREIGN KEY (DateKey) REFERENCES DimDate(DateKey),
    CONSTRAINT FK_FactPerformance_DimPortfolio 
        FOREIGN KEY (PortfolioKey) REFERENCES DimPortfolio(PortfolioKey),
    CONSTRAINT FK_FactPerformance_DimBenchmark 
        FOREIGN KEY (BenchmarkKey) REFERENCES DimBenchmark(BenchmarkKey)
);
GO

-- Create FactHoldings table
CREATE TABLE FactHoldings (
    HoldingKey BIGINT PRIMARY KEY IDENTITY(1,1),
    DateKey INT NOT NULL,
    PortfolioKey INT NOT NULL,
    SecurityID NVARCHAR(20) NOT NULL,
    SecurityName NVARCHAR(200) NOT NULL,
    Ticker NVARCHAR(20),
    ISIN NVARCHAR(12),
    Sector NVARCHAR(50),
    Country NVARCHAR(50),
    Currency NCHAR(3),
    AssetClass NVARCHAR(30),
    Quantity DECIMAL(18,4) NOT NULL,
    Price DECIMAL(18,6) NOT NULL,
    MarketValue DECIMAL(18,2) NOT NULL,
    Weight DECIMAL(7,6) NOT NULL,
    CostBasis DECIMAL(18,2),
    UnrealizedPL DECIMAL(18,2),
    Duration DECIMAL(8,4), -- For bonds
    YieldToMaturity DECIMAL(6,4), -- For bonds
    CreatedDate DATETIME2 DEFAULT GETDATE(),
    CONSTRAINT FK_FactHoldings_DimDate 
        FOREIGN KEY (DateKey) REFERENCES DimDate(DateKey),
    CONSTRAINT FK_FactHoldings_DimPortfolio 
        FOREIGN KEY (PortfolioKey) REFERENCES DimPortfolio(PortfolioKey)
);
GO

-- Create indexes for better performance
CREATE INDEX IX_FactPerformance_DateKey ON FactPerformance(DateKey);
CREATE INDEX IX_FactPerformance_PortfolioKey ON FactPerformance(PortfolioKey);
CREATE INDEX IX_FactPerformance_BenchmarkKey ON FactPerformance(BenchmarkKey);
CREATE INDEX IX_FactHoldings_DateKey ON FactHoldings(DateKey);
CREATE INDEX IX_FactHoldings_PortfolioKey ON FactHoldings(PortfolioKey);
CREATE INDEX IX_FactHoldings_SecurityID ON FactHoldings(SecurityID);
GO

-- Populate DimDate table (2023-2025)
WITH DateCTE AS (
    SELECT CAST('2023-01-01' AS DATE) AS Date
    UNION ALL
    SELECT DATEADD(DAY, 1, Date)
    FROM DateCTE
    WHERE Date < '2025-12-31'
)
INSERT INTO DimDate (
    DateKey, Date, Year, Quarter, Month, MonthName, WeekOfYear, 
    DayOfMonth, DayOfWeek, DayName, IsWeekend, IsMonthEnd, 
    IsQuarterEnd, IsYearEnd, FiscalYear, FiscalQuarter
)
SELECT 
    CAST(FORMAT(Date, 'yyyyMMdd') AS INT) as DateKey,
    Date,
    YEAR(Date) as Year,
    DATEPART(QUARTER, Date) as Quarter,
    MONTH(Date) as Month,
    DATENAME(MONTH, Date) as MonthName,
    DATEPART(WEEK, Date) as WeekOfYear,
    DAY(Date) as DayOfMonth,
    DATEPART(WEEKDAY, Date) as DayOfWeek,
    DATENAME(WEEKDAY, Date) as DayName,
    CASE WHEN DATEPART(WEEKDAY, Date) IN (1,7) THEN 1 ELSE 0 END as IsWeekend,
    CASE WHEN Date = EOMONTH(Date) THEN 1 ELSE 0 END as IsMonthEnd,
    CASE WHEN Date = EOMONTH(Date, 0) AND MONTH(Date) IN (3,6,9,12) THEN 1 ELSE 0 END as IsQuarterEnd,
    CASE WHEN Date = EOMONTH(Date, 0) AND MONTH(Date) = 12 THEN 1 ELSE 0 END as IsYearEnd,
    CASE WHEN MONTH(Date) >= 4 THEN YEAR(Date) + 1 ELSE YEAR(Date) END as FiscalYear,
    CASE 
        WHEN MONTH(Date) BETWEEN 4 AND 6 THEN 1
        WHEN MONTH(Date) BETWEEN 7 AND 9 THEN 2
        WHEN MONTH(Date) BETWEEN 10 AND 12 THEN 3
        ELSE 4
    END as FiscalQuarter
FROM DateCTE
OPTION (MAXRECURSION 0);
GO

-- Insert DimPortfolio data
INSERT INTO DimPortfolio (
    PortfolioID, PortfolioName, ManagerName, Department, Strategy, 
    InceptionDate, BaseCurrency, MinimumInvestment, ManagementFee, PerformanceFee
) VALUES
('PF001', 'Global Equity Growth Fund', 'Sarah Thompson', 'Equity', 'Growth', '2018-03-15', 'USD', 10000000.00, 0.0075, 0.15),
('PF002', 'Emerging Markets Equity Fund', 'Emma Rodriguez', 'Equity', 'Emerging Markets', '2019-06-01', 'USD', 5000000.00, 0.0125, 0.20),
('PF003', 'Global Government Bond Fund', 'Michael Chen', 'Fixed Income', 'Government Bonds', '2017-09-20', 'USD', 25000000.00, 0.0045, 0.00),
('PF004', 'Technology Innovation Fund', 'James Wilson', 'Equity', 'Sector Focus', '2020-01-10', 'USD', 1000000.00, 0.0095, 0.20),
('PF005', 'Sustainable Development Fund', 'Lisa Zhang', 'ESG', 'ESG Growth', '2021-04-12', 'USD', 5000000.00, 0.0085, 0.15),
('PF006', 'High Yield Credit Fund', 'David Kim', 'Fixed Income', 'High Yield', '2018-11-30', 'USD', 10000000.00, 0.0065, 0.10),
('PF007', 'Africa Frontier Fund', 'Marcus van der Berg', 'Equity', 'Emerging Markets', '2019-08-15', 'USD', 2000000.00, 0.0150, 0.25),
('PF008', 'Multi-Asset Income Fund', 'Robert Johnson', 'Multi-Asset', 'Income', '2017-12-05', 'USD', 15000000.00, 0.0055, 0.00),
('PF009', 'Infrastructure Debt Fund', 'Priya Patel', 'Alternatives', 'Infrastructure', '2020-07-22', 'USD', 50000000.00, 0.0075, 0.00),
('PF010', 'Asian Equity Fund', 'Alexandra Volkov', 'Equity', 'Regional Focus', '2021-02-28', 'USD', 3000000.00, 0.0095, 0.18);
GO

-- Insert DimBenchmark data
INSERT INTO DimBenchmark (
    BenchmarkID, BenchmarkName, BenchmarkFamily, AssetClass, Region, Currency, Provider
) VALUES
('BM001', 'MSCI World Index', 'MSCI', 'Equity', 'Global', 'USD', 'MSCI Inc'),
('BM002', 'MSCI Emerging Markets Index', 'MSCI', 'Equity', 'Emerging Markets', 'USD', 'MSCI Inc'),
('BM003', 'Bloomberg Global Aggregate Bond', 'Bloomberg', 'Fixed Income', 'Global', 'USD', 'Bloomberg'),
('BM004', 'NASDAQ 100 Index', 'NASDAQ', 'Equity', 'US', 'USD', 'NASDAQ'),
('BM005', 'MSCI World ESG Leaders Index', 'MSCI', 'Equity', 'Global', 'USD', 'MSCI Inc'),
('BM006', 'Bloomberg Global High Yield Index', 'Bloomberg', 'Fixed Income', 'Global', 'USD', 'Bloomberg'),
('BM007', 'MSCI Frontier Markets Africa Index', 'MSCI', 'Equity', 'Africa', 'USD', 'MSCI Inc'),
('BM008', 'Bloomberg Multi-Asset Income Index', 'Bloomberg', 'Multi-Asset', 'Global', 'USD', 'Bloomberg'),
('BM009', 'S&P Global Infrastructure Index', 'S&P', 'Infrastructure', 'Global', 'USD', 'S&P Global'),
('BM010', 'MSCI Asia Pacific Index', 'MSCI', 'Equity', 'Asia Pacific', 'USD', 'MSCI Inc');
GO

-- Insert FactPerformance data (monthly data for 2024)
DECLARE @StartDate DATE = '2024-01-01';
DECLARE @EndDate DATE = '2024-12-31';
DECLARE @CurrentDate DATE = @StartDate;

WHILE @CurrentDate <= @EndDate
BEGIN
    -- Only insert for month-end dates
    IF @CurrentDate = EOMONTH(@CurrentDate)
    BEGIN
        DECLARE @DateKey INT = CAST(FORMAT(@CurrentDate, 'yyyyMMdd') AS INT);
        
        -- Portfolio 1: Global Equity Growth Fund
        INSERT INTO FactPerformance (DateKey, PortfolioKey, BenchmarkKey, NAV, TotalReturn, BenchmarkReturn, ExcessReturn, AUM, NumberOfHoldings, CashPercentage, TurnoverRate, ExpenseRatio)
        VALUES (@DateKey, 1, 1, 
                100 + (DATEDIFF(MONTH, '2024-01-01', @CurrentDate) * 1.2) + (RAND() * 5 - 2.5),
                0.012 + (RAND() * 0.02 - 0.01),
                0.010 + (RAND() * 0.015 - 0.0075),
                0.002 + (RAND() * 0.01 - 0.005),
                750000000 + (DATEDIFF(MONTH, '2024-01-01', @CurrentDate) * 5000000),
                45 + (RAND() * 10 - 5),
                0.025 + (RAND() * 0.02),
                0.15 + (RAND() * 0.1),
                0.0075);

        -- Portfolio 2: Emerging Markets Equity Fund
        INSERT INTO FactPerformance (DateKey, PortfolioKey, BenchmarkKey, NAV, TotalReturn, BenchmarkReturn, ExcessReturn, AUM, NumberOfHoldings, CashPercentage, TurnoverRate, ExpenseRatio)
        VALUES (@DateKey, 2, 2,
                100 + (DATEDIFF(MONTH, '2024-01-01', @CurrentDate) * 0.8) + (RAND() * 8 - 4),
                0.008 + (RAND() * 0.03 - 0.015),
                0.006 + (RAND() * 0.025 - 0.0125),
                0.002 + (RAND() * 0.015 - 0.0075),
                320000000 + (DATEDIFF(MONTH, '2024-01-01', @CurrentDate) * 2000000),
                55 + (RAND() * 15 - 7),
                0.035 + (RAND() * 0.025),
                0.25 + (RAND() * 0.15),
                0.0125);

        -- Portfolio 3: Global Government Bond Fund
        INSERT INTO FactPerformance (DateKey, PortfolioKey, BenchmarkKey, NAV, TotalReturn, BenchmarkReturn, ExcessReturn, AUM, NumberOfHoldings, CashPercentage, TurnoverRate, ExpenseRatio)
        VALUES (@DateKey, 3, 3,
                100 + (DATEDIFF(MONTH, '2024-01-01', @CurrentDate) * 0.3) + (RAND() * 2 - 1),
                0.003 + (RAND() * 0.008 - 0.004),
                0.0025 + (RAND() * 0.006 - 0.003),
                0.0005 + (RAND() * 0.003 - 0.0015),
                1850000000 + (DATEDIFF(MONTH, '2024-01-01', @CurrentDate) * 8000000),
                25 + (RAND() * 10 - 5),
                0.015 + (RAND() * 0.01),
                0.05 + (RAND() * 0.03),
                0.0045);

        -- Portfolio 4: Technology Innovation Fund
        INSERT INTO FactPerformance (DateKey, PortfolioKey, BenchmarkKey, NAV, TotalReturn, BenchmarkReturn, ExcessReturn, AUM, NumberOfHoldings, CashPercentage, TurnoverRate, ExpenseRatio)
        VALUES (@DateKey, 4, 4,
                100 + (DATEDIFF(MONTH, '2024-01-01', @CurrentDate) * 2.1) + (RAND() * 12 - 6),
                0.021 + (RAND() * 0.04 - 0.02),
                0.018 + (RAND() * 0.035 - 0.0175),
                0.003 + (RAND() * 0.02 - 0.01),
                85000000 + (DATEDIFF(MONTH, '2024-01-01', @CurrentDate) * 1500000),
                28 + (RAND() * 8 - 4),
                0.02 + (RAND() * 0.015),
                0.35 + (RAND() * 0.2),
                0.0095);

        -- Continue for other portfolios...
        INSERT INTO FactPerformance (DateKey, PortfolioKey, BenchmarkKey, NAV, TotalReturn, BenchmarkReturn, ExcessReturn, AUM, NumberOfHoldings, CashPercentage, TurnoverRate, ExpenseRatio)
        VALUES (@DateKey, 5, 5,
                100 + (DATEDIFF(MONTH, '2024-01-01', @CurrentDate) * 1.1) + (RAND() * 6 - 3),
                0.011 + (RAND() * 0.025 - 0.0125),
                0.009 + (RAND() * 0.02 - 0.01),
                0.002 + (RAND() * 0.012 - 0.006),
                125000000 + (DATEDIFF(MONTH, '2024-01-01', @CurrentDate) * 3000000),
                35 + (RAND() * 10 - 5),
                0.03 + (RAND() * 0.02),
                0.18 + (RAND() * 0.12),
                0.0085);
    END
    
    SET @CurrentDate = DATEADD(DAY, 1, @CurrentDate);
END
GO

-- Insert FactHoldings data (sample for latest month)
DECLARE @LatestDateKey INT = (SELECT MAX(DateKey) FROM FactPerformance);

-- Holdings for Global Equity Growth Fund (Portfolio 1)
INSERT INTO FactHoldings (DateKey, PortfolioKey, SecurityID, SecurityName, Ticker, Sector, Country, Currency, AssetClass, Quantity, Price, MarketValue, Weight, CostBasis, UnrealizedPL)
VALUES 
(@LatestDateKey, 1, 'US0378331005', 'Apple Inc', 'AAPL', 'Technology', 'United States', 'USD', 'Equity', 15000, 190.50, 2857500.00, 0.0845, 2650000.00, 207500.00),
(@LatestDateKey, 1, 'US5949181045', 'Microsoft Corporation', 'MSFT', 'Technology', 'United States', 'USD', 'Equity', 12000, 400.25, 4803000.00, 0.1421, 4500000.00, 303000.00),
(@LatestDateKey, 1, 'US02079K3059', 'Alphabet Inc Class A', 'GOOGL', 'Technology', 'United States', 'USD', 'Equity', 8000, 170.15, 1361200.00, 0.0403, 1280000.00, 81200.00),
(@LatestDateKey, 1, 'US0231351067', 'Amazon.com Inc', 'AMZN', 'Consumer Discretionary', 'United States', 'USD', 'Equity', 5000, 151.25, 756250.00, 0.0224, 720000.00, 36250.00),
(@LatestDateKey, 1, 'US67066G1040', 'NVIDIA Corporation', 'NVDA', 'Technology', 'United States', 'USD', 'Equity', 3000, 1400.50, 4201500.00, 0.1243, 3800000.00, 401500.00),
(@LatestDateKey, 1, 'NL0010273215', 'ASML Holding NV', 'ASML', 'Technology', 'Netherlands', 'EUR', 'Equity', 2000, 900.75, 1801500.00, 0.0533, 1650000.00, 151500.00),
(@LatestDateKey, 1, 'US88160R1014', 'Tesla Inc', 'TSLA', 'Consumer Discretionary', 'United States', 'USD', 'Equity', 4000, 248.50, 994000.00, 0.0294, 920000.00, 74000.00);

-- Holdings for Emerging Markets Fund (Portfolio 2)
INSERT INTO FactHoldings (DateKey, PortfolioKey, SecurityID, SecurityName, Ticker, Sector, Country, Currency, AssetClass, Quantity, Price, MarketValue, Weight, CostBasis, UnrealizedPL)
VALUES 
(@LatestDateKey, 2, 'US01609W1027', 'Alibaba Group Holding Ltd', 'BABA', 'Technology', 'China', 'USD', 'Equity', 50000, 90.25, 4512500.00, 0.1845, 4200000.00, 312500.00),
(@LatestDateKey, 2, 'US8740391003', 'Taiwan Semiconductor Manufacturing Co', 'TSM', 'Technology', 'Taiwan', 'USD', 'Equity', 25000, 110.75, 2768750.00, 0.1132, 2500000.00, 268750.00),
(@LatestDateKey, 2, 'KR7005930003', 'Samsung Electronics Co Ltd', '005930.KS', 'Technology', 'South Korea', 'KRW', 'Equity', 30000, 120.50, 3615000.00, 0.1478, 3400000.00, 215000.00),
(@LatestDateKey, 2, 'INE002A01018', 'Reliance Industries Ltd', 'RELIANCE.NS', 'Energy', 'India', 'INR', 'Equity', 25000, 150.80, 3770000.00, 0.1542, 3600000.00, 170000.00),
(@LatestDateKey, 2, 'ZAE000015889', 'Naspers Ltd', 'NPN.JO', 'Technology', 'South Africa', 'ZAR', 'Equity', 20000, 300.25, 6005000.00, 0.2457, 5500000.00, 505000.00);

-- Holdings for Bond Fund (Portfolio 3) 
INSERT INTO FactHoldings (DateKey, PortfolioKey, SecurityID, SecurityName, Ticker, Sector, Country, Currency, AssetClass, Quantity, Price, MarketValue, Weight, Duration, YieldToMaturity)
VALUES 
(@LatestDateKey, 3, 'US912828XG94', 'US Treasury 10-Year Note', 'US10Y', 'Government', 'United States', 'USD', 'Bond', 1000000, 95.50, 95500000.00, 0.4521, 8.75, 0.0425),
(@LatestDateKey, 3, 'DE0001102309', 'German 10-Year Bund', 'DE10Y', 'Government', 'Germany', 'EUR', 'Bond', 500000, 90.25, 45125000.00, 0.2136, 9.12, 0.0238),
(@LatestDateKey, 3, 'GB0008983148', 'UK 10-Year Gilt', 'GB10Y', 'Government', 'United Kingdom', 'GBP', 'Bond', 300000, 89.75, 26925000.00, 0.1275, 8.93, 0.0385),
(@LatestDateKey, 3, 'ZA000000R198', 'South African 10-Year Bond', 'ZAR10Y', 'Government', 'South Africa', 'ZAR', 'Bond', 200000, 85.50, 17100000.00, 0.0809, 7.85, 0.0950);

PRINT 'Dimensional model tables created and populated successfully!';
PRINT '';
PRINT '--- Table Row Counts ---';
SELECT 'DimDate' as TableName, COUNT(*) as RowCount FROM DimDate
UNION ALL
SELECT 'DimPortfolio', COUNT(*) FROM DimPortfolio
UNION ALL
SELECT 'DimBenchmark', COUNT(*) FROM DimBenchmark  
UNION ALL
SELECT 'FactPerformance', COUNT(*) FROM FactPerformance
UNION ALL
SELECT 'FactHoldings', COUNT(*) FROM FactHoldings;

PRINT '';
PRINT '--- Sample Performance Data ---';
SELECT TOP 5
    d.Date,
    p.PortfolioName,
    b.BenchmarkName,
    fp.NAV,
    FORMAT(fp.TotalReturn, 'P2') as TotalReturn,
    FORMAT(fp.BenchmarkReturn, 'P2') as BenchmarkReturn,
    FORMAT(fp.ExcessReturn, 'P2') as ExcessReturn,
    FORMAT(fp.AUM, 'C0') as AUM
FROM FactPerformance fp
    INNER JOIN DimDate d ON fp.DateKey = d.DateKey
    INNER JOIN DimPortfolio p ON fp.PortfolioKey = p.PortfolioKey
    INNER JOIN DimBenchmark b ON fp.BenchmarkKey = b.BenchmarkKey
ORDER BY d.Date DESC, p.PortfolioName;

PRINT '';
PRINT '--- Sample Holdings Data ---';
SELECT TOP 5
    d.Date,
    p.PortfolioName,
    fh.SecurityName,
    fh.Ticker,
    fh.Quantity,
    FORMAT(fh.Price, 'C2') as Price,
    FORMAT(fh.MarketValue, 'C0') as MarketValue,
    FORMAT(fh.Weight, 'P2') as Weight
FROM FactHoldings fh
    INNER JOIN DimDate d ON fh.DateKey = d.DateKey
    INNER JOIN DimPortfolio p ON fh.PortfolioKey = p.PortfolioKey
ORDER BY fh.MarketValue DESC;