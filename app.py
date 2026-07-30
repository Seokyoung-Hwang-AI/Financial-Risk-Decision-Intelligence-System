import os
import joblib
import numpy as np
import pandas as pd
import streamlit as st
import shap
import matplotlib.pyplot as plt

# =========================
# CONFIG
# =========================
BASE_DIR = os.getcwd()
MODEL_PATH = os.path.join(BASE_DIR, 'models')

st.set_page_config(
    page_title="FDS Risk Decision System",
    layout="wide"
)

# =========================
# LOAD MODELS
# =========================
@st.cache_resource
def load_assets():
    model = joblib.load(os.path.join(MODEL_PATH, 'fds_model.pkl'))
    explainer = joblib.load(os.path.join(MODEL_PATH, 'shap_explainer.pkl'))
    return model, explainer

model, explainer = load_assets()

# =========================
# LAYER 1: INPUT LAYER
# =========================
def get_input():
    st.sidebar.header("📝 Transaction Input")

    st.sidebar.info("""
    ### Risk Test Scenario
    - Change amount / month / vendor count
    - Observe Rule + ML + Risk changes
    """)

    amount = st.sidebar.number_input(
        "Transaction Amount ($)", 100.0, 100000.0, 21500.0
    )

    month = st.sidebar.slider("Month", 1, 12, 11)

    vendor_month_count = st.sidebar.number_input(
        "Vendor Monthly Count", 0, 30, 2
    )

    # derived features
    is_q4 = 1 if month >= 10 else 0
    amount_log = np.log1p(amount)

    df = pd.DataFrame({
        "amount": [amount],
        "month": [month],
        "is_q4": [is_q4],
        "amount_log": [amount_log],
        "vendor_month_count": [vendor_month_count]
    })

    return df

input_df = get_input()

# =========================
# LAYER 2: RULE ENGINE
# =========================
def rule_engine(row):
    rules = []

    if row["vendor_month_count"] <= 3 and row["amount"] >= 20000:
        rules.append("⚠ Split Payment Pattern")

    if row["amount"] >= 40000:
        rules.append("⚠ High Value Transaction")

    if row["is_q4"] == 1 and row["amount"] > 30000:
        rules.append("⚠ Q4 Budget Spike")

    return rules

# =========================
# LAYER 3: ML LAYER
# =========================
def ml_layer(df):
    pred = model.predict(df)[0]
    proba = model.predict_proba(df)[0][1]

    shap_values = explainer(df)

    return pred, proba, shap_values

# =========================
# LAYER 4: RISK ENGINE
# =========================
def risk_score(amount, proba):
    return amount * proba

def risk_quadrant(amount, proba):
    if amount > 50000 and proba > 0.7:
        return "CRITICAL"
    elif proba > 0.7:
        return "HIGH RISK"
    elif amount > 50000:
        return "HIGH VALUE"
    else:
        return "NORMAL"

# =========================
# RUN PIPELINE
# =========================
prediction, proba, shap_values = ml_layer(input_df)

rules = rule_engine(input_df.iloc[0])

score = risk_score(input_df["amount"][0], proba)
quadrant = risk_quadrant(input_df["amount"][0], proba)

# =========================
# UI
# =========================
st.title("🛡️ Government Expenditure FDS")
st.markdown("### 4-Layer Risk Decision System")

# =========================
# LAYER 1 OUTPUT
# =========================
st.divider()
st.subheader("Layer 1: Rule Engine")

if rules:
    for r in rules:
        st.warning(r)
else:
    st.success("No Rule Triggered")

# =========================
# LAYER 2 OUTPUT
# =========================
st.divider()
st.subheader("Layer 2: ML Prediction")

col1, col2 = st.columns(2)

with col1:
    if prediction == 1:
        st.error("FRAUD DETECTED")
    else:
        st.success("NORMAL")

with col2:
    st.metric("Fraud Probability", f"{proba*100:.2f}%")

# =========================
# SHAP
# =========================
st.subheader("🔍 Feature Explanation (SHAP)")

fig, ax = plt.subplots()
shap.plots.bar(shap_values[0], show=False)
st.pyplot(fig)

# =========================
# LAYER 3 OUTPUT
# =========================
st.divider()
st.subheader("Layer 3: Risk Engine")

col3, col4 = st.columns(2)

with col3:
    st.metric("Risk Score", f"{score:,.2f}")

with col4:
    st.metric("Risk Quadrant", quadrant)

# =========================
# LAYER 4 OUTPUT
# =========================
st.divider()
st.subheader("Layer 4: Audit Decision")

if quadrant == "CRITICAL":
    st.error("IMMEDIATE AUDIT REQUIRED")
elif quadrant == "HIGH RISK":
    st.warning("PRIORITY AUDIT")
elif quadrant == "HIGH VALUE":
    st.info("REVIEW REQUIRED")
else:
    st.success("NORMAL MONITORING")