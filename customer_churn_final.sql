

/**********************************************************************
 Title: Customer Churn Analysis & Risk Scoring (SQL Only Project)

 Author: Igho

 Purpose:
 This project demonstrates an end to end customer churn analysis using
 SQL only. It covers data modeling, normalization, feature engineering,
 and rule based churn risk scoring without reliance on Python or ML
 libraries.

 Objective:
 - Design a normalized relational schema for customer churn data
 - Perform data cleansing and transformation via SQL
 - Engineer business relevant features (tenure, service depth, value)
 - Build a transparent churn risk scoring model using SQL logic
 - Deliver production ready analytical views for BI and reporting tools
**********************************************************************/

--------------------------------------------------------
-- 1. Create Base Tables
--------------------------------------------------------

-- Customers Table
CREATE TABLE dbo.customers (
    CustomerID VARCHAR(20) NOT NULL,
    Gender VARCHAR(10),
    SeniorCitizen BIT,
    Partner BIT,
    Dependents BIT,
    Tenure INT,

    CONSTRAINT pk_customers PRIMARY KEY (CustomerID)
);

     
-- Subscriptions Table
CREATE TABLE dbo.subscriptions (
    CustomerID VARCHAR(20) NOT NULL,
    Contract VARCHAR(30),
    PaymentMethod VARCHAR(50),
    PaperlessBilling BIT,
    MonthlyCharges DECIMAL(10,2),
    TotalCharges DECIMAL(10,2),
    Churn BIT,

    CONSTRAINT pk_subscriptions PRIMARY KEY (CustomerID),
    CONSTRAINT fk_subscriptions_customers
        FOREIGN KEY (CustomerID)
        REFERENCES dbo.customers (CustomerID)
);

 
-- Services Table
CREATE TABLE dbo.services (
    CustomerID VARCHAR(20) NOT NULL,
    PhoneService BIT,
    MultipleLines VARCHAR(20),
    InternetService VARCHAR(20),
    OnlineSecurity BIT,
    OnlineBackup BIT,
    DeviceProtection BIT,
    TechSupport BIT,
    StreamingTV BIT,
    StreamingMovies BIT,

    CONSTRAINT pk_services PRIMARY KEY (CustomerID),
    CONSTRAINT fk_services_customers
        FOREIGN KEY (CustomerID)
        REFERENCES dbo.customers (CustomerID)
);


--------------------------------------------------------
-- 2. Staging Table (Raw Data Load)
--------------------------------------------------------
 CREATE TABLE dbo.stg_customer_churn (
    CustomerID NVARCHAR(100),
    Gender NVARCHAR(20),
    SeniorCitizen INT,
    Partner NVARCHAR(20),
    Dependents NVARCHAR(20),
    Tenure SMALLINT,
    PhoneService NVARCHAR(100),
    MultipleLines NVARCHAR(60),
    InternetService NVARCHAR(60),
    OnlineSecurity NVARCHAR(60),
    OnlineBackup NVARCHAR(60),
    DeviceProtection NVARCHAR(60),
    TechSupport NVARCHAR(60),
    StreamingTV NVARCHAR(60),
    StreamingMovies NVARCHAR(60),
    Contract NVARCHAR(100),
    PaperlessBilling NVARCHAR(20),
    PaymentMethod NVARCHAR(100),
    MonthlyCharges DECIMAL(10,2),
    TotalCharges DECIMAL(10,2),
    Churn NVARCHAR(20)
);



SELECT * FROM dbo.stg_customer_churn;

-- Quick Row Count and NULL Check
SELECT
    COUNT(*) AS TotalRows,
    SUM(CASE WHEN CustomerID IS NULL THEN 1 ELSE 0 END) AS NULLCustomerIDs
FROM dbo.stg_customer_churn;


--------------------------------------------------------
-- 3. Data Loading into Normalized Tables
--------------------------------------------------------

-- Load customers
INSERT INTO dbo.customers (
    CustomerID,
    Gender,
    SeniorCitizen,
    Partner,
    Dependents,
    Tenure
)
SELECT
    CustomerID,
    Gender,
    CAST(SeniorCitizen AS bit),          
    CASE WHEN Partner = 'Yes' THEN 1 ELSE 0 END,
    CASE WHEN Dependents = 'Yes' THEN 1 ELSE 0 END,
    Tenure
FROM dbo.stg_customer_churn;

-- Load subscriptions
INSERT INTO dbo.subscriptions (
    CustomerID,
    Contract,
    PaymentMethod,
    PaperlessBilling,
    MonthlyCharges,
    TotalCharges,
    Churn

    )
SELECT
    CustomerID,
    Contract,
    PaymentMethod,
    CASE WHEN PaperlessBilling = 'Yes' THEN 1 ELSE 0 END,
    MonthlyCharges,
    TotalCharges,
    CASE WHEN Churn = 'Yes' THEN 1 ELSE 0 END
FROM dbo.stg_customer_churn;


-- Load Services
INSERT INTO dbo.services (
    CustomerID,
    PhoneService,
    MultipleLines,
    InternetService,
    OnlineSecurity,
    OnlineBackup,
    DeviceProtection,
    TechSupport,
    StreamingTV,
    StreamingMovies

    )
SELECT
    CustomerID,
    CASE WHEN PhoneService  = 'Yes' THEN 1 ELSE 0 END,
    CASE WHEN MultipleLines  = 'Yes' THEN 1 ELSE 0 END,
    InternetService,
    CASE WHEN OnlineSecurity  = 'Yes' THEN 1 ELSE 0 END,
    CASE WHEN OnlineBackup  = 'Yes' THEN 1 ELSE 0 END,
    CASE WHEN DeviceProtection  = 'Yes' THEN 1 ELSE 0 END,
    CASE WHEN TechSupport  = 'Yes' THEN 1 ELSE 0 END,
    CASE WHEN StreamingTV  = 'Yes' THEN 1 ELSE 0 END,
    CASE WHEN StreamingMovies  = 'Yes' THEN 1 ELSE 0 END
FROM dbo.stg_customer_churn;

--------------------------------------------------------
-- 4. Data Integrity Constraints
--------------------------------------------------------
-- Gender validity
ALTER TABLE dbo.customers
ADD CONSTRAINT chk_gender
CHECK (Gender IN ('Male', 'Female'));

-- Churn validity
ALTER TABLE dbo.subscriptions
ADD CONSTRAINT chk_churn
CHECK (Churn IN (0,1));

--------------------------------------------------------
-- 5. Denormalized Analytics View
--------------------------------------------------------
CREATE VIEW vw_customer_churn AS
SELECT
    c.CustomerID,
    c.Gender,
    c.SeniorCitizen,
    c.Partner,
    c.Dependents,
    c.Tenure,

    s.Contract,
    s.PaymentMethod,
    s.PaperlessBilling,
    s.MonthlyCharges,
    s.TotalCharges,
    s.Churn,

    sv.PhoneService,
    sv.MultipleLines,
    sv.InternetService,
    sv.OnlineSecurity,
    sv.OnlineBackup,
    sv.DeviceProtection,
    sv.TechSupport,
    sv.StreamingTV,
    sv.StreamingMovies
FROM dbo.customers c
JOIN dbo.subscriptions s 
    ON c.CustomerID = s.CustomerID
JOIN dbo.services sv 
    ON c.CustomerID = sv.CustomerID;

--------------------------------------------------------
-- 6. Feature Engineering View
--------------------------------------------------------
CREATE VIEW vw_customer_churn_features AS
SELECT
    *,
    CASE
        WHEN Tenure < 6 THEN 'New'
        WHEN Tenure BETWEEN 6 AND 24 THEN 'Established'
        ELSE 'Loyal'
    END AS LifecycleStage,

    CASE 
        WHEN Tenure = 0 THEN MonthlyCharges
        ELSE TotalCharges / Tenure
    END AS EffectiveMonthlyValue,

    (
        CAST(OnlineSecurity AS INT) +
        CAST(TechSupport AS INT) +
        CAST(OnlineBackup AS INT) +
        CAST(DeviceProtection AS INT)
    ) AS Service_Depth
FROM vw_customer_churn;


--------------------------------------------------------
-- 7. Final Production View
--------------------------------------------------------
CREATE VIEW vw_churn_risk_final AS
SELECT
    *,
    (
        CASE WHEN Contract = 'Month-to-month' THEN 4 ELSE 0 END +
        CASE WHEN Tenure < 12 THEN 3 ELSE 0 END +
        CASE WHEN MonthlyCharges > 70 THEN 2 ELSE 0 END +
        CASE WHEN Service_Depth <= 1 THEN 2 ELSE 0 END
    ) AS ChurnRiskScore,

    CASE
        WHEN
            (
                CASE WHEN Contract = 'Month-to-month' THEN 4 ELSE 0 END +
                CASE WHEN Tenure < 12 THEN 3 ELSE 0 END +
                CASE WHEN MonthlyCharges > 70 THEN 2 ELSE 0 END +
                CASE WHEN Service_Depth <= 1 THEN 2 ELSE 0 END
            ) >= 9 THEN 'High Risk'
        WHEN
            (
                CASE WHEN Contract = 'Month-to-month' THEN 4 ELSE 0 END +
                CASE WHEN Tenure < 12 THEN 3 ELSE 0 END +
                CASE WHEN MonthlyCharges > 70 THEN 2 ELSE 0 END +
                CASE WHEN Service_Depth <= 1 THEN 2 ELSE 0 END
            ) BETWEEN 5 AND 8 THEN 'Medium Risk'
        ELSE 'Low Risk'
    END AS ChurnRiskBand
FROM vw_customer_churn_features;

select * from vw_churn_risk_final;

select * from vw_customer_churn_features;












