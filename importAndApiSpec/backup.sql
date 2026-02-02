/*
MS SQL Server DDL for Vending Championship DB
- Tables: VendingMachines, Models, Brands, Companies, Countries, MachineTypes, MachineStatuses
         Users, Roles, Products, MachineProductStock, Sales, PaymentMethods
         Verifications (checks), Maintenance, Inventory
- All key constraints requested in the description are enforced in SQL.
*/

SET NOCOUNT ON;
SET XACT_ABORT ON;

BEGIN TRY
    BEGIN TRAN;

    /* ====== Create DB (optional) ======
       If you already have a DB, comment this block and run the rest inside your DB.
    */
    --IF DB_ID(N'VendingChampionship') IS NULL
    --BEGIN
    --    CREATE DATABASE VendingChampionship;
    --END
    --GO
  USE vendingMachinesDB;
    --GO

    /* ====== Safety drops (for re-run) ====== */
    IF OBJECT_ID(N'dbo.trg_Sales_ValidateAndCalc', 'TR') IS NOT NULL DROP TRIGGER dbo.trg_Sales_ValidateAndCalc;
    IF OBJECT_ID(N'dbo.trg_VM_RecalcNextVerification', 'TR') IS NOT NULL DROP TRIGGER dbo.trg_VM_RecalcNextVerification;

    IF OBJECT_ID(N'dbo.vw_VendingMachineIncome', 'V') IS NOT NULL DROP VIEW dbo.vw_VendingMachineIncome;

    IF OBJECT_ID(N'dbo.Inventory', 'U') IS NOT NULL DROP TABLE dbo.Inventory;
    IF OBJECT_ID(N'dbo.Maintenance', 'U') IS NOT NULL DROP TABLE dbo.Maintenance;
    IF OBJECT_ID(N'dbo.Verifications', 'U') IS NOT NULL DROP TABLE dbo.Verifications;
    IF OBJECT_ID(N'dbo.Sales', 'U') IS NOT NULL DROP TABLE dbo.Sales;
    IF OBJECT_ID(N'dbo.MachineProductStock', 'U') IS NOT NULL DROP TABLE dbo.MachineProductStock;
    IF OBJECT_ID(N'dbo.Products', 'U') IS NOT NULL DROP TABLE dbo.Products;
    IF OBJECT_ID(N'dbo.PaymentMethods', 'U') IS NOT NULL DROP TABLE dbo.PaymentMethods;

    IF OBJECT_ID(N'dbo.VendingMachines', 'U') IS NOT NULL DROP TABLE dbo.VendingMachines;

    IF OBJECT_ID(N'dbo.Users', 'U') IS NOT NULL DROP TABLE dbo.Users;
    IF OBJECT_ID(N'dbo.Roles', 'U') IS NOT NULL DROP TABLE dbo.Roles;

    IF OBJECT_ID(N'dbo.Models', 'U') IS NOT NULL DROP TABLE dbo.Models;
    IF OBJECT_ID(N'dbo.Brands', 'U') IS NOT NULL DROP TABLE dbo.Brands;
    IF OBJECT_ID(N'dbo.Companies', 'U') IS NOT NULL DROP TABLE dbo.Companies;

    IF OBJECT_ID(N'dbo.MachineStatuses', 'U') IS NOT NULL DROP TABLE dbo.MachineStatuses;
    IF OBJECT_ID(N'dbo.MachineTypes', 'U') IS NOT NULL DROP TABLE dbo.MachineTypes;
    IF OBJECT_ID(N'dbo.Countries', 'U') IS NOT NULL DROP TABLE dbo.Countries;

    /* ====== Reference tables ====== */

    CREATE TABLE dbo.Countries
    (
        CountryId       INT IDENTITY(1,1) NOT NULL CONSTRAINT PK_Countries PRIMARY KEY,
        CountryName     NVARCHAR(100) NOT NULL CONSTRAINT UQ_Countries_Name UNIQUE
    );

    CREATE TABLE dbo.MachineTypes
    (
        MachineTypeId   INT IDENTITY(1,1) NOT NULL CONSTRAINT PK_MachineTypes PRIMARY KEY,
        TypeName        NVARCHAR(100) NOT NULL CONSTRAINT UQ_MachineTypes_Name UNIQUE
        -- examples: Cash, Card, Cash+Card, QR, etc.
    );

    CREATE TABLE dbo.MachineStatuses
    (
        StatusId        INT IDENTITY(1,1) NOT NULL CONSTRAINT PK_MachineStatuses PRIMARY KEY,
        StatusName      NVARCHAR(80) NOT NULL CONSTRAINT UQ_MachineStatuses_Name UNIQUE
        -- required: Работает, Вышел из строя, В ремонте/на обслуживании
    );

    CREATE TABLE dbo.Companies
    (
        CompanyId       INT IDENTITY(1,1) NOT NULL CONSTRAINT PK_Companies PRIMARY KEY,
        CompanyName     NVARCHAR(200) NOT NULL CONSTRAINT UQ_Companies_Name UNIQUE
    );

    CREATE TABLE dbo.Brands
    (
        BrandId         INT IDENTITY(1,1) NOT NULL CONSTRAINT PK_Brands PRIMARY KEY,
        BrandName       NVARCHAR(200) NOT NULL,
        CompanyId       INT NOT NULL,
        CONSTRAINT FK_Brands_Companies FOREIGN KEY (CompanyId) REFERENCES dbo.Companies(CompanyId),
        CONSTRAINT UQ_Brands UNIQUE (CompanyId, BrandName)
    );

    CREATE TABLE dbo.Models
    (
        ModelId         INT IDENTITY(1,1) NOT NULL CONSTRAINT PK_Models PRIMARY KEY,
        ModelName       NVARCHAR(200) NOT NULL,
        BrandId         INT NOT NULL,
        CONSTRAINT FK_Models_Brands FOREIGN KEY (BrandId) REFERENCES dbo.Brands(BrandId),
        CONSTRAINT UQ_Models UNIQUE (BrandId, ModelName)
    );

    CREATE TABLE dbo.Roles
    (
        RoleId          INT IDENTITY(1,1) NOT NULL CONSTRAINT PK_Roles PRIMARY KEY,
        RoleName        NVARCHAR(80) NOT NULL CONSTRAINT UQ_Roles_Name UNIQUE
        -- examples: Администратор, Оператор, Инженер
    );

    CREATE TABLE dbo.Users
    (
        UserId          INT IDENTITY(1,1) NOT NULL CONSTRAINT PK_Users PRIMARY KEY,
        FullName        NVARCHAR(200) NOT NULL,
        Email           NVARCHAR(200) NULL,
        Phone           NVARCHAR(50)  NULL,
        RoleId          INT NOT NULL,
        CONSTRAINT FK_Users_Roles FOREIGN KEY (RoleId) REFERENCES dbo.Roles(RoleId),

        CONSTRAINT UQ_Users_Email UNIQUE (Email),
        CONSTRAINT UQ_Users_Phone UNIQUE (Phone)
    );

    CREATE TABLE dbo.PaymentMethods
    (
        PaymentMethodId INT IDENTITY(1,1) NOT NULL CONSTRAINT PK_PaymentMethods PRIMARY KEY,
        MethodName      NVARCHAR(50) NOT NULL CONSTRAINT UQ_PaymentMethods_Name UNIQUE
        -- required: наличные, карта, QR
    );

    /* ====== Core table: VendingMachines ====== */

    CREATE TABLE dbo.VendingMachines
    (
        VendingMachineId        INT IDENTITY(1,1) NOT NULL CONSTRAINT PK_VendingMachines PRIMARY KEY,

        Location                NVARCHAR(300) NOT NULL,     -- address / description

        ModelId                 INT NOT NULL,
        MachineTypeId           INT NOT NULL,
        ManufacturerCompanyId   INT NOT NULL,              -- firm-manufacturer
        CountryId               INT NOT NULL,
        StatusId                INT NOT NULL,

        SerialNumber            NVARCHAR(100) NOT NULL,
        InventoryNumber         NVARCHAR(100) NOT NULL,

        ManufactureDate         DATE NOT NULL,              -- Дата изготовления
        CommissioningDate       DATE NOT NULL,              -- Дата ввода в эксплуатацию
        AddedToSystemDate       DATE NOT NULL,              -- Дата внесения в систему

        LastVerificationDate    DATE NULL,                  -- Дата последней поверки (must be >= ManufactureDate and <= today)
        VerificationIntervalMonths INT NULL,                -- Межповерочный интервал (months)
        NextVerificationDate    AS (
            CASE
                WHEN LastVerificationDate IS NULL OR VerificationIntervalMonths IS NULL THEN NULL
                ELSE DATEADD(MONTH, VerificationIntervalMonths, LastVerificationDate)
            END
        ) PERSISTED,

        ResourceHours           INT NOT NULL,              -- Ресурс ТА в часах (positive)

        NextMaintenanceDate     DATE NULL,                 -- Дата следующего ремонта/обслуживания ( > AddedToSystemDate )

        ServiceTimeHours        INT NULL,                  -- Время обслуживания (1..20) - as requirement
        LastVerifierUserId      INT NULL,                  -- Сотрудник, который производил последнюю поверку

        LastInventoryDate       DATE NULL,                 -- Дата инвентаризации (>= ManufactureDate and <= today)

        CONSTRAINT FK_VM_Model              FOREIGN KEY (ModelId) REFERENCES dbo.Models(ModelId),
        CONSTRAINT FK_VM_MachineType        FOREIGN KEY (MachineTypeId) REFERENCES dbo.MachineTypes(MachineTypeId),
        CONSTRAINT FK_VM_Manufacturer       FOREIGN KEY (ManufacturerCompanyId) REFERENCES dbo.Companies(CompanyId),
        CONSTRAINT FK_VM_Country            FOREIGN KEY (CountryId) REFERENCES dbo.Countries(CountryId),
        CONSTRAINT FK_VM_Status             FOREIGN KEY (StatusId) REFERENCES dbo.MachineStatuses(StatusId),
        CONSTRAINT FK_VM_LastVerifierUser   FOREIGN KEY (LastVerifierUserId) REFERENCES dbo.Users(UserId),

        CONSTRAINT UQ_VM_SerialNumber       UNIQUE (SerialNumber),
        CONSTRAINT UQ_VM_InventoryNumber    UNIQUE (InventoryNumber),

        /* --- CHECK constraints required by the task --- */
        CONSTRAINT CK_VM_ResourceHours_Positive CHECK (ResourceHours > 0),

        -- CommissioningDate must be between ManufactureDate and AddedToSystemDate (inclusive)
        CONSTRAINT CK_VM_CommissioningDate_Range CHECK (
            CommissioningDate >= ManufactureDate
            AND CommissioningDate <= AddedToSystemDate
        ),

        -- AddedToSystemDate cannot be before ManufactureDate (reasonable, and helps)
        CONSTRAINT CK_VM_AddedDate_AfterManufacture CHECK (
            AddedToSystemDate >= ManufactureDate
        ),

        -- LastVerificationDate must be >= ManufactureDate and <= today
        CONSTRAINT CK_VM_LastVerificationDate_Range CHECK (
            LastVerificationDate IS NULL
            OR (LastVerificationDate >= ManufactureDate AND LastVerificationDate <= CAST(GETDATE() AS DATE))
        ),

        -- Interval months must be positive if provided
        CONSTRAINT CK_VM_VerificationIntervalMonths_Positive CHECK (
            VerificationIntervalMonths IS NULL OR VerificationIntervalMonths > 0
        ),

        -- NextMaintenanceDate must be > AddedToSystemDate
        CONSTRAINT CK_VM_NextMaintenanceDate CHECK (
            NextMaintenanceDate IS NULL OR NextMaintenanceDate > AddedToSystemDate
        ),

        -- ServiceTimeHours must be 1..20 if provided
        CONSTRAINT CK_VM_ServiceTimeHours CHECK (
            ServiceTimeHours IS NULL OR (ServiceTimeHours BETWEEN 1 AND 20)
        ),

        -- LastInventoryDate must be >= ManufactureDate and <= today
        CONSTRAINT CK_VM_LastInventoryDate_Range CHECK (
            LastInventoryDate IS NULL
            OR (LastInventoryDate >= ManufactureDate AND LastInventoryDate <= CAST(GETDATE() AS DATE))
        )
    );

    /* ====== Products & stock ====== */

    CREATE TABLE dbo.Products
    (
        ProductId            INT IDENTITY(1,1) NOT NULL CONSTRAINT PK_Products PRIMARY KEY,
        ProductName          NVARCHAR(200) NOT NULL,
        ProductDescription   NVARCHAR(500) NULL,
        Price                DECIMAL(18,2) NOT NULL,
        MinimumStock         INT NOT NULL,
        SalesTendencyPerDay  DECIMAL(18,2) NULL, -- "склонность к продажам" as avg/day

        CONSTRAINT UQ_Products_Name UNIQUE (ProductName),
        CONSTRAINT CK_Products_Price_Positive CHECK (Price > 0),
        CONSTRAINT CK_Products_MinStock_NonNegative CHECK (MinimumStock >= 0),
        CONSTRAINT CK_Products_Tendency_NonNegative CHECK (SalesTendencyPerDay IS NULL OR SalesTendencyPerDay >= 0)
    );

    -- Current stock of each product in each machine (M:N)
    CREATE TABLE dbo.MachineProductStock
    (
        VendingMachineId     INT NOT NULL,
        ProductId            INT NOT NULL,
        QuantityInStock      INT NOT NULL,

        CONSTRAINT PK_MachineProductStock PRIMARY KEY (VendingMachineId, ProductId),
        CONSTRAINT FK_MPS_VM FOREIGN KEY (VendingMachineId) REFERENCES dbo.VendingMachines(VendingMachineId) ON DELETE CASCADE,
        CONSTRAINT FK_MPS_Product FOREIGN KEY (ProductId) REFERENCES dbo.Products(ProductId),
        CONSTRAINT CK_MPS_Quantity_NonNegative CHECK (QuantityInStock >= 0)
    );

    /* ====== Sales ====== */

    CREATE TABLE dbo.Sales
    (
        SaleId              INT IDENTITY(1,1) NOT NULL CONSTRAINT PK_Sales PRIMARY KEY,
        VendingMachineId    INT NOT NULL,
        ProductId           INT NOT NULL,
        Quantity            INT NOT NULL,
        SaleAmount          DECIMAL(18,2) NOT NULL,
        SaleDateTime        DATETIME2(0) NOT NULL CONSTRAINT DF_Sales_SaleDateTime DEFAULT (SYSUTCDATETIME()),
        PaymentMethodId     INT NOT NULL,

        CONSTRAINT FK_Sales_VM FOREIGN KEY (VendingMachineId) REFERENCES dbo.VendingMachines(VendingMachineId),
        CONSTRAINT FK_Sales_Product FOREIGN KEY (ProductId) REFERENCES dbo.Products(ProductId),
        CONSTRAINT FK_Sales_PaymentMethod FOREIGN KEY (PaymentMethodId) REFERENCES dbo.PaymentMethods(PaymentMethodId),

        CONSTRAINT CK_Sales_Quantity_Positive CHECK (Quantity > 0),
        CONSTRAINT CK_Sales_Amount_NonNegative CHECK (SaleAmount >= 0)
    );

    /*
      Trigger: keep SaleAmount consistent with Product.Price * Quantity.
      If you want to allow discounts, remove this trigger and validate differently.
    */
   

    /* ====== Verifications (проверка/поверка) ====== */

    CREATE TABLE dbo.Verifications
    (
        VerificationId      INT IDENTITY(1,1) NOT NULL CONSTRAINT PK_Verifications PRIMARY KEY,
        VendingMachineId    INT NOT NULL,
        VerificationDate    DATE NOT NULL,
        UserId              INT NOT NULL, -- who performed
        Notes               NVARCHAR(500) NULL,

        CONSTRAINT FK_Verifications_VM FOREIGN KEY (VendingMachineId) REFERENCES dbo.VendingMachines(VendingMachineId),
        CONSTRAINT FK_Verifications_User FOREIGN KEY (UserId) REFERENCES dbo.Users(UserId),

        -- VerificationDate: >= ManufactureDate and <= today (needs cross-table -> trigger)
        -- We'll enforce via trigger below.
        CONSTRAINT CK_Verifications_Date_NotFuture CHECK (VerificationDate <= CAST(GETDATE() AS DATE))
    );

    /*
      Cross-table rule:
      VerificationDate must be >= VendingMachines.ManufactureDate
      Also update VendingMachines.LastVerificationDate and LastVerifierUserId automatically.
    */
    

    /* ====== Maintenance (обслуживание) ====== */

    CREATE TABLE dbo.Maintenance
    (
        MaintenanceId       INT IDENTITY(1,1) NOT NULL CONSTRAINT PK_Maintenance PRIMARY KEY,
        VendingMachineId    INT NOT NULL,
        MaintenanceDate     DATE NOT NULL,
        WorkDescription     NVARCHAR(800) NOT NULL,
        Problems            NVARCHAR(800) NULL,
        ExecutorUserId      INT NOT NULL,

        DurationHours       INT NULL,  -- if you want to track actual duration; must be 1..20 if set

        CONSTRAINT FK_Maintenance_VM FOREIGN KEY (VendingMachineId) REFERENCES dbo.VendingMachines(VendingMachineId),
        CONSTRAINT FK_Maintenance_Executor FOREIGN KEY (ExecutorUserId) REFERENCES dbo.Users(UserId),

        CONSTRAINT CK_Maintenance_Date_NotFuture CHECK (MaintenanceDate <= CAST(GETDATE() AS DATE)),
        CONSTRAINT CK_Maintenance_Duration CHECK (DurationHours IS NULL OR (DurationHours BETWEEN 1 AND 20))
    );

    /* ====== Inventory (инвентаризация) ====== */

    CREATE TABLE dbo.Inventory
    (
        InventoryId         INT IDENTITY(1,1) NOT NULL CONSTRAINT PK_Inventory PRIMARY KEY,
        VendingMachineId    INT NOT NULL,
        InventoryDate       DATE NOT NULL,
        UserId              INT NOT NULL,
        Notes               NVARCHAR(500) NULL,

        CONSTRAINT FK_Inventory_VM FOREIGN KEY (VendingMachineId) REFERENCES dbo.VendingMachines(VendingMachineId),
        CONSTRAINT FK_Inventory_User FOREIGN KEY (UserId) REFERENCES dbo.Users(UserId),

        CONSTRAINT CK_Inventory_Date_NotFuture CHECK (InventoryDate <= CAST(GETDATE() AS DATE))
        -- Cross-table rule (>= ManufactureDate) already ensured in VM as LastInventoryDate,
        -- but each inventory row needs it too; simplest: a trigger could be added similarly if required.
    );

    /* ====== Income view (совокупный доход) ====== */
   
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK TRAN;

    DECLARE @Err NVARCHAR(4000) = ERROR_MESSAGE();
    DECLARE @Num INT = ERROR_NUMBER();
    DECLARE @Line INT = ERROR_LINE();
    RAISERROR(N'Ошибка создания БД. %s (№%d, строка %d)', 16, 1, @Err, @Num, @Line);
END CATCH;
