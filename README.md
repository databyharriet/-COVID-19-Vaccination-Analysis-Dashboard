
# 💉 COVID-19 Vaccination Analytics Project

## 📚 Table of Contents
- [Project Overview](#project-overview)
- [Datasets Used](#datasets-used)
- [Tools Used](#tools-used)
- [Data Cleaning & Transformation](#data-cleaning--transformation)
- [Power BI Dashboard](#power-bi-dashboard)
- [Insights Gained](#insights-gained)
- [Getting Started](#getting-started)
- [Acknowledgements](#acknowledgements)


---

## 🌍 Project Overview

This project showcases the end-to-end data analysis process for global COVID-19 vaccination and death trends, starting from raw SQL datasets to creating a professional Power BI dashboard.

---

## 🗂️ Datasets Used

- **CovidDeaths**: Contains daily COVID-19 death counts, total cases, new cases, and population.
- **CovidVaccine**: Contains daily vaccination records plus healthcare and economic indicators (like GDP, life expectancy).

---

## 🛠️ Tools Used

- **SQL Server (SSMS)** 🧠: Data cleaning, transformation, and preprocessing.
- **Power BI** 📊: Data visualization and dashboard creation.

---

## 🧼 Data Cleaning & Transformation

### In SQL Server:
- Removed rows with `NULL` in the `Continent` field.
- Converted string values to numeric using `TRY_CAST` and `CAST`.
- Calculated key metrics:
  - **Infection rate**: `Total_Cases / Population * 100`
  - **Death rate**: `Total_Deaths / Total_Cases * 100`
  - **Recovery rate**: `(Total_Cases - Total_Deaths) / Total_Cases`
  - **Vaccination percentage**: `(Rolling_Vaccinated / Population) * 100`

### Sample SQL CTE:
```sql
-- CTE to calculate cumulative vaccinations and vaccination percentage
WITH PopVsVaccinations AS
(
    SELECT dea.Continent, dea.Location, dea.Date, dea.Population, vac.New_Vaccinations,
           SUM(CAST(vac.New_Vaccinations AS INT)) OVER (PARTITION BY dea.Location ORDER BY dea.Location, dea.Date) AS Rolling_Vaccinated
    FROM PortfolioProject..CovidDeaths dea
    JOIN PortfolioProject..CovidVaccinations vac
        ON dea.Location = vac.Location
        AND dea.Date = vac.Date
    WHERE dea.Continent IS NOT NULL
)
SELECT *, (Rolling_Vaccinated / Population) * 100 AS Percent_Vaccinated
FROM PopVsVaccinations;

```

---

## 📊 Power BI Dashboard

The Power BI dashboard provides interactive visualizations to track global vaccination progress.

### Key Visualizations:
- **Count of New Vaccinations by Continent**: Shows the distribution of vaccine doses per region.
- **Sum of Rolling Vaccinated vs Population by Month & Continent**: Tracks vaccination progress over time.
- **DAX Measures**: For example, calculated max daily vaccinations and vaccination percentage.



### Power BI Dashboard Preview:
<img width="738" alt="Screenshot 2025-04-07 114845" src="https://github.com/user-attachments/assets/f7dc4186-5290-42e4-aa48-e79e95c52e83" />

---
#### Example DAX Measures:
```dax
Max Daily Vaccinations = MAX(VaccinationStatistics[New_Vaccinations])

Percent Vaccinated = 
    DIVIDE(SUM(VaccinationStatistics[Rolling_Vaccinated]), SUM(VaccinationStatistics[Population])) * 100
```

## 🧠 Insights Gained

- **SQL Processing**: 
  - Ensured clean, accurate data for Power BI visualization.
  - Used window functions like `OVER (PARTITION BY ...)` for cumulative calculations (rolling vaccinations).
- **Power BI**:
  - Leveraged interactive visualizations, tooltips, and filters for dynamic insights.
  - Created intuitive visuals like bar, area, and map charts to track global vaccination trends.

---

## 🚀 Getting Started

To run this project on your own:

1. **Clone this repository**.
2. **Set up SQL Server** and import the raw datasets (`CovidDeaths` and `CovidVaccine`).
3. Execute the provided SQL queries to clean and prepare the data.
4. **Open the Power BI file** (`covid19.pbix`) and refresh the data to generate the visualizations.
   
Ensure that you have **SQL Server** and **Power BI Desktop** installed before starting.

---

## 🙌 Acknowledgements

- **Data Source**: [Our World In Data](https://ourworldindata.org/covid-vaccinations)
- Special thanks to the open data community and frontline workers worldwide for their invaluable efforts during the pandemic.

⭐ **Star this repo** if you found it useful!
```
