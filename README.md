## Customer Churn Analysis & Risk Scoring (SQL Only)

![SQL Server](https://img.shields.io/badge/SQL%20Server-CC29227?style=for-the-badge&logo=microsoft-sql-server&logoColor=white)
![T-SQL](https://img.shields.io/badge/T--SQL-CC29227?style=for-the-badge&logo=microsoft-sql-server&logoColor=white)

## Overview

This project demonstrates an end-to-end customer churn analysis using SQL only.
It transforms raw telecom customer data into analytical, feature rich views and applies a transparent, rule based churn risk scoring model suitable for BI tools.


## Objectives

- Normalize raw churn data into a relational schema

- Enforce data integrity and consistency

- Engineer business relevant features using SQL

- Translate churn drivers into an interpretable risk score

- Produce production ready views for reporting and dashboards

## Data Architecture

        Staging → Normalized → Analytics → Features → Final Risk View

- stg_customer_churn – raw data ingestion

- customers, subscriptions, services – normalized core tables

- vw_customer_churn – denormalized analytics layer

- vw_customer_churn_features – engineered features

- vw_churn_risk_final – final churn risk scoring view

## Feature Engineering (SQL)

Key engineered features include:

- LifecycleStage (New / Established / Loyal)

- EffectiveMonthlyValue (tenure adjusted spend)

- Service_Depth (count of protection & support services)

- ChurnRiskScore (rule based scoring)

- ChurnRiskBand (Low / Medium / High)


 ## Business Insight

Analysis confirms that:

Month-to-month contracts have the highest churn risk

Low service adoption significantly increases churn likelihood

Support and security services strongly reduce churn

Early tenure customers are most vulnerable

## Tools Used

SQL Server (T-SQL)




## Outcome

A clean, scalable churn analytics model that supports:

Risk segmentation

Retention targeting

Executive dashboards
