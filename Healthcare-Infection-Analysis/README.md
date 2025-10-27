# Healthcare-Infection-Analysis 
This project is healthcare-focused, exploring trends in healthcare-associated infections across U.S. hospitals. (Link to full dashboard below)

![Dashboard Preview](./Hospital%20Acquired%20Infections.png)

Healthcare-Associated Infections Analysis

Overview

This project focuses on analyzing healthcare-associated infections (HAIs) in U.S. hospitals to identify infection trends, assess performance against national benchmarks, and classify facilities into risk categories. The dataset contains over 21,000 rows and 18 variables, including infection scores, infection types (e.g., C. difficile, MRSA), observed and predicted cases, and geographic data.

By leveraging data science techniques like Exploratory Data Analysis (EDA), Principal Component Analysis (PCA), K-means clustering, and predictive modeling, this analysis provides actionable insights to improve infection prevention strategies and patient outcomes.


Key Objectives

- Identify facilities and regions with the highest infection rates.
- Compare infection types and scores to national benchmarks.
- Classify facilities into high-risk and low-risk categories for proactive management.
- Uncover patterns and trends using clustering and dimensionality reduction techniques.


Tools and Technologies

- Python: Used for data cleaning, EDA, clustering, PCA, and predictive modeling.
- Power BI: Developed interactive dashboards to visualize findings and communicate results effectively.
- Libraries:
   - Pandas, Numpy: Data manipulation and preprocessing.
   - Matplotlib, Seaborn: Data visualization.
   - Scikit-learn: Machine learning and clustering techniques.

    
Steps and Methods

  1). Dataset Preparation:
    - Loaded the dataset and cleaned data for missing values and inconsistent formatting.
    - Filtered relevant rows for specific analyses (e.g., "Observed Cases" in Measure Name).
  2). Exploratory Data Analysis (EDA):
    - Visualized infection score distributions by state and infection type.
    - Identified outliers and regions with the highest scores (e.g., C. difficile rates in DC, MA, NY).


  3). Benchmarking Against National Averages:
  - Analyzed infection scores and compared deviations from national benchmarks.
  - Highlighted states and facilities performing below average.


  4). Principal Component Analysis (PCA):
  - Reduced dimensionality to focus on key drivers of infection trends.
  - Identified high-variance states and facilities for targeted analysis.


  5). K-means Clustering
  - Grouped facilities into clusters based on infection scores.
  - Analyzed cluster centers to uncover patterns in infection performance.


  6). Predictive Modeling:
  - Used Random Forest Classifier to classify facilities as high-risk or low-risk based on infection scores and other features.
  - Achieved perfect precision and recall, validating the model’s reliability.


  7). State-Level Analysis:
  -Focused on high-risk states (DC, MA, NY) and compared infection rates for specific infection types (e.g., C. difficile).

  
Key Findings

  - High-Risk Regions: Washington, D.C., Massachusetts, and New York showed disproportionately high infection rates, particularly for C. difficile.
  - National Benchmarks: Certain infection types consistently exceeded national averages, highlighting areas for improvement.
  - Cluster Insights: K-means clustering revealed distinct groups of facilities with similar infection performances, allowing for tailored interventions.
  - Predictive Risk Classification: The Random Forest model accurately classified facilities into risk categories, enabling proactive infection prevention strategies.


How to Use This Repository
 
  1). Jupyter Notebook:
    - Explore the full Python analysis, including data preprocessing, EDA, PCA, clustering, and predictive modeling.
    - Code is well-documented for clarity and reproducibility.


  2). Power BI Dashboard:
    - Interactive dashboard showcasing key visualizations and findings.
    - Provides an overview of infection trends, high-risk regions, and benchmarking insights.

    ## View Dashboard

   [View the Dashboard](./Hospital%20Acquired%20Infections.png)

    ## View DAX Measures
   [View the DAX Measures Image](./DAX%20Measures.png)


  3). Dataset:
    - Contains raw data for independent analysis and experimentation (adhering to data usage policies).

    
Repository Structure

  - notebooks/: Contains the Jupyter Notebook for Python analysis.
  - dashboards/: Includes the Power BI file for interactive visualization.
  - data/: Original dataset 
  - README.md: Project overview and instructions.
  - requirements.txt: Python libraries required to run the notebook.


Getting Started

  1). Clone this repository:
      - git clone https://github.com/mdamberg/healthcare-associated-infections.git
      
  2). Install the required Python libraries:
      - pip install -r requirements.txt
      
  3). Open the Jupyter Notebook for detailed analysis:
      - jupyter notebook notebooks/HAI_Analysis.ipynb

      
Acknowledgments
Special thanks to the healthcare data community for providing the dataset and for contributing analysis and insights. This project serves as an example of how data-driven methods can improve healthcare outcomes.
