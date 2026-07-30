# Financial Risk Decision Intelligence System

> **Project Goal:** Build an end-to-end Financial Risk Decision Intelligence platform that integrates SQL-based audit analytics, machine learning, explainable AI, and executive business intelligence to support data-driven financial risk monitoring and investigation prioritization.

---

## 📖 Project Overview

This project demonstrates how financial risk analytics can be transformed into a **Decision Intelligence platform** by integrating rule-based auditing, machine learning, explainable AI, and executive business intelligence.

Inspired by real-world public sector budget management, the platform simulates an end-to-end financial risk monitoring workflow—from transaction analysis and fraud detection to executive risk reporting—supporting both operational investigators and financial decision-makers.

---

## 🛠️ Tech Stack

- **Language:** Python, SQL
- **Libraries:** Pandas, NumPy, Scikit-learn, Matplotlib
- **Database:** PostgreSQL
- **Machine Learning:** Isolation Forest, XGBoost
- **Explainable AI:** SHAP
- **Business Intelligence:** Power BI
- **Web Application:** Streamlit

---

## 🧱 System Architecture

```text
Financial Transactions
        ↓
SQL Audit Analytics (Rule-based Detection)
        ↓
Isolation Forest (Unsupervised Anomaly Detection)
        ↓
XGBoost (Supervised Fraud Prediction)
        ↓
SHAP Explainability (Model Interpretation)
        ↓
Power BI Executive Risk Dashboard
```

---

## 📊 Data Strategy

Rather than relying on publicly available datasets, this project uses a **synthetic financial transaction dataset** designed to simulate realistic public expenditure scenarios and fraud patterns.

The dataset enables controlled validation of audit rules and machine learning models by incorporating predefined behavioral risks such as:

- Tactical payment splitting
- Vendor concentration
- Fiscal year-end spending anomalies
- High-risk transaction patterns

This approach provides reliable ground-truth labels for supervised learning while creating realistic business scenarios for executive risk analysis.
