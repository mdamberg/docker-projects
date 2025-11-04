# Data-Cleaning-With-SQL
This project focuses on cleaning and standardizing a dataset about housing trends in Nashville, Tennessee. It involves resolving null values, standardizing inconsistent data formats, splitting and restructuring address fields, removing duplicates, and dropping unnecessary columns to prepare the data for analysis.
The Nashville Housing Data Cleaning Project is designed to prepare a raw dataset for analysis by addressing various data quality issues. This dataset contains housing data from Nashville, Tennessee, and includes information such as property addresses, owner addresses, sale dates, and other key details.

The project involves several key steps:

Date Standardization: The SaleDate column, originally in a DateTime format, is converted to a simpler Date format for easier analysis.
Handling Missing Values: Null values in critical fields like PropertyAddress are resolved by leveraging existing data. For instance, addresses are populated by matching parcel IDs in the dataset.
Address Splitting: Compound address fields (e.g., PropertyAddress and OwnerAddress) are split into separate components, such as street address, city, and state, to improve readability and usability.
Data Standardization: Fields with inconsistent entries, like SoldAsVacant, are standardized using uniform values (e.g., converting "Y" and "N" to "Yes" and "No").
Duplicate Removal: Duplicate records are identified and deleted using SQL's ROW_NUMBER() function, ensuring data integrity.
Dropping Unnecessary Columns: Redundant or unused columns, such as the original compound address fields, are removed to streamline the dataset.
By the end of this project, the dataset is cleaned, standardized, and optimized for analysis. This ensures the data is ready for deeper exploration of housing trends, such as market insights, property value patterns, and demographic analyses. This project highlights key data cleaning techniques and demonstrates the practical application of SQL for data preprocessing in real-world scenarios.



