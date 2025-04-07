-- Select the data excluding rows with NULL in the continent column
SELECT Location, Date, Total_Cases, New_Cases, Total_Deaths, Population
FROM CovidDeaths 
WHERE Continent IS NOT NULL
ORDER BY Location, Date;

-- Calculate the percentage of death based on total cases
SELECT Location, Date, Total_Cases, Total_Deaths,
       (CAST(Total_Deaths AS DECIMAL) / Total_Cases) * 100 AS Death_Percentage
FROM CovidDeaths
WHERE Location LIKE '%states%' 
  AND Continent IS NOT NULL
ORDER BY Location, Date;

-- Calculate the percentage of the population infected with COVID-19
SELECT Location, Date, Population, Total_Cases,
       (CAST(Total_Cases AS DECIMAL) / Population) * 100 AS Percent_Population_Infected
FROM CovidDeaths
ORDER BY Location, Date;

-- Find the countries with the highest infection rate compared to their population
SELECT Location, Population, MAX(Total_Cases) AS Highest_Infection_Count,
       MAX(CAST(Total_Cases AS DECIMAL) / Population) * 100 AS Infection_Percentage
FROM CovidDeaths
GROUP BY Location, Population
ORDER BY Infection_Percentage DESC;

-- Get countries with the highest death count per population
SELECT Location, MAX(CAST(Total_Deaths AS INT)) AS Total_Death_Count
FROM CovidDeaths
WHERE Continent IS NOT NULL
GROUP BY Location
ORDER BY Total_Death_Count DESC;

-- Find continents with the highest death count per population
SELECT Continent, MAX(CAST(Total_Deaths AS INT)) AS Total_Death_Count
FROM CovidDeaths
WHERE Continent IS NOT NULL
GROUP BY Continent
ORDER BY Total_Death_Count DESC;

-- Aggregate global COVID-19 data (total cases, total deaths, and death rate)
SELECT SUM(New_Cases) AS Total_New_Cases,
       SUM(CAST(New_Deaths AS INT)) AS Total_New_Deaths,
       (SUM(CAST(New_Deaths AS INT)) / SUM(New_Cases)) * 100 AS Death_Percentage
FROM CovidDeaths
WHERE Continent IS NOT NULL;

-- Compare the percentage of people vaccinated against the total population
SELECT dea.Continent, dea.Location, dea.Date, dea.Population, vac.New_Vaccinations,
       SUM(CAST(vac.New_Vaccinations AS DECIMAL(10, 2))) OVER (PARTITION BY dea.Location ORDER BY dea.Location, dea.Date) AS Rolling_Vaccinations
FROM CovidDeaths dea
JOIN CovidVaccine vac
  ON dea.Location = vac.Location
  AND dea.Date = vac.Date
WHERE dea.Continent IS NOT NULL
ORDER BY dea.Location, dea.Date;

-- Relationship between GDP and COVID cases in each country
SELECT dea.Location, dea.gdp_per_capita, SUM(dea.Total_Cases) AS Total_Cases,
       (SUM(dea.Total_Cases) / dea.gdp_per_capita) * 1000 AS CovidCasesPerBillionGDP
FROM CovidDeaths dea
WHERE dea.Continent IS NOT NULL
GROUP BY dea.Location, dea.gdp_per_capita
ORDER BY CovidCasesPerBillionGDP DESC;

-- GDP vs Total Deaths in each country
SELECT dea.Location, dea.gdp_per_capita, SUM(dea.Total_Deaths) AS Total_Deaths,
       (SUM(dea.Total_Deaths) / dea.gdp_per_capita) * 1000 AS DeathsPerBillionGDP
FROM CovidDeaths dea
WHERE dea.Continent IS NOT NULL
GROUP BY dea.Location, dea.gdp_per_capita
ORDER BY DeathsPerBillionGDP DESC;

-- Life expectancy vs total COVID cases in each country
SELECT Location, Total_Cases
FROM CovidDeaths
WHERE ISNUMERIC(Total_Cases) = 0;

-- Check for non-numeric values in Life_Expectancy
SELECT Location, Life_Expectancy
FROM CovidVaccine
WHERE ISNUMERIC(Life_Expectancy) = 0;

-- Healthcare infrastructure (hospital_beds_per_thousand) vs Total Deaths
SELECT dea.Location, 
       TRY_CAST(vac.hospital_beds_per_thousand AS FLOAT) AS Beds_Per_Capita, 
       SUM(TRY_CAST(dea.Total_Deaths AS BIGINT)) AS Total_Deaths,
       (SUM(TRY_CAST(dea.Total_Deaths AS BIGINT)) / TRY_CAST(vac.hospital_beds_per_thousand AS FLOAT)) AS DeathsPerBed
FROM CovidDeaths dea
JOIN CovidVaccine vac
  ON dea.Location = vac.Location
  AND dea.Date = vac.Date
WHERE dea.Continent IS NOT NULL
GROUP BY dea.Location, vac.hospital_beds_per_thousand
ORDER BY DeathsPerBed DESC;

-- GDP Growth Rate vs COVID Recovery Rate (Total Cases - Total Deaths)
SELECT dea.Location, 
       TRY_CAST(dea.gdp_per_capita AS FLOAT) AS gdp_per_capita, 
       SUM(TRY_CAST(dea.Total_Cases AS BIGINT)) - SUM(TRY_CAST(dea.Total_Deaths AS BIGINT)) AS Total_Recovered,
       (SUM(TRY_CAST(dea.Total_Cases AS BIGINT)) - SUM(TRY_CAST(dea.Total_Deaths AS BIGINT))) * 100.0 / SUM(TRY_CAST(dea.Total_Cases AS BIGINT)) AS RecoveryRatePercentage
FROM CovidDeaths dea
WHERE dea.Continent IS NOT NULL
  AND dea.Total_Cases IS NOT NULL
  AND dea.Total_Deaths IS NOT NULL
  AND dea.gdp_per_capita IS NOT NULL
GROUP BY dea.Location, dea.gdp_per_capita
ORDER BY RecoveryRatePercentage DESC;

-- CTE to calculate cumulative vaccinations and vaccination percentage
WITH PopVsVaccinations AS
(
    SELECT dea.Continent, dea.Location, dea.Date, dea.Population, 
           TRY_CAST(vac.New_Vaccinations AS FLOAT) AS New_Vaccinations,
           SUM(TRY_CAST(vac.New_Vaccinations AS FLOAT)) OVER 
               (PARTITION BY dea.Location ORDER BY dea.Location, dea.Date) AS Rolling_Vaccinated
    FROM CovidDeaths dea
    JOIN CovidVaccine vac
        ON dea.Location = vac.Location
        AND dea.Date = vac.Date
    WHERE dea.Continent IS NOT NULL
)
SELECT *, (Rolling_Vaccinated / Population) * 100 AS Percent_Vaccinated
FROM PopVsVaccinations;

-- Create and use a temporary table to store the vaccination data
DROP TABLE IF EXISTS #VaccinationStats;
CREATE TABLE #VaccinationStats
(
    Continent NVARCHAR(255),
    Location NVARCHAR(255),
    Date DATETIME,
    Population NUMERIC,
    New_Vaccinations NUMERIC,
    Rolling_Vaccinated NUMERIC
);

-- Insert the data into the temporary table
INSERT INTO #VaccinationStats
SELECT dea.Continent, dea.Location, dea.Date, dea.Population, 
       TRY_CAST(vac.New_Vaccinations AS FLOAT) AS New_Vaccinations,
       SUM(TRY_CAST(vac.New_Vaccinations AS FLOAT)) OVER 
           (PARTITION BY dea.Location ORDER BY dea.Location, dea.Date) AS Rolling_Vaccinated
FROM CovidDeaths dea
JOIN CovidVaccine vac
  ON dea.Location = vac.Location
  AND dea.Date = vac.Date
WHERE dea.Continent IS NOT NULL;

-- Query the data from the temporary table
SELECT *, (Rolling_Vaccinated / Population) * 100 AS Percent_Vaccinated
FROM #VaccinationStats;

EXEC sp_help 'CovidVaccine';  -- Check columns for the 'CovidVaccine' table
EXEC sp_help 'CovidDeaths';  -- Check columns for the 'CovidDeaths' table

-- Create a view to store vaccination data for later use in visualizations

CREATE VIEW VaccinationStatisticss AS
SELECT dea.Continent, dea.Location, dea.Date, dea.Population, vac.New_Vaccinations,
       SUM(TRY_CAST(vac.New_Vaccinations AS INT)) OVER (PARTITION BY dea.Location ORDER BY dea.Location, dea.Date) AS Rolling_Vaccinated
FROM CovidDeaths dea
JOIN CovidVaccine vac
    ON dea.Location = vac.Location
    AND dea.Date = vac.Date
WHERE dea.Continent IS NOT NULL;

-- End the current batch with GO
GO

-- Now, you can run other statements like SELECT after this batch
SELECT dea.Location, 
       TRY_CAST(vac.Life_Expectancy AS FLOAT) AS Life_Expectancy,  -- Safely cast to FLOAT, returns NULL if invalid
       SUM(TRY_CAST(dea.Total_Cases AS BIGINT)) AS Total_Cases,  -- Use BIGINT to avoid overflow
       (SUM(TRY_CAST(dea.Total_Cases AS BIGINT)) / NULLIF(TRY_CAST(vac.Life_Expectancy AS FLOAT), 0)) AS CovidCasesPerLifeExpectancy
FROM CovidDeaths dea
JOIN CovidVaccine vac
    ON dea.Location = vac.Location
    AND dea.Date = vac.Date
WHERE dea.Continent IS NOT NULL
GROUP BY dea.Location, vac.Life_Expectancy
ORDER BY CovidCasesPerLifeExpectancy DESC;

