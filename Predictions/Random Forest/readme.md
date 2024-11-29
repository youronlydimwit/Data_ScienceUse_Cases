# Folder Information
## Diabetes Prediction - `DONE`
- No EDA
- Using `RandomForestClassifier`, `SMOTE`, `sklearn`, `pandas` libraries
- **Result:**
    - Attained Accuracy of 75.97%
    - Diabetes as Class `1` and No Diabetes as Class `0`
    - Precision (Class 0) = **0.84**, Precision (Class 1) = **0.64**
    - Recall (Class 0) = **0.77**, Recall (Class 1) = **0.75**
    - F1-score (Class 0) = **0.80**, F1-score (Class 1) = **0.69**

## Digital Marketing Expense Prediction - `DONE`
- Performed Exploratory Data Analysis (EDA)
- Using `RandomForestRegressor`, `sklearn`, `seaborn`, `pandas`, `matplotlib` libraries
- Dataset contains features:
  - `Impressions`, `Reach`, `Video_plays`, `Link_clicks`, `Engagement`, and `Live_time`
- Target variable: `Amount_spent` (in IDR)
- **Result:**
   - Attained R² of **0.86**
   - `live_time` contributes 80% to the prediction of `Amount_spent`
   - Other features provide smaller but meaningful contributions
   - The model demonstrates robust handling of non-linear relationships and multicollinearity.
