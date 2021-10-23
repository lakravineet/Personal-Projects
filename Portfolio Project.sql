Use PortfolioProject;
GO

SELECT * 
FROM PortfolioProject..CovidDeaths
ORDER BY 3,4;

--SELECT * 
--FROM PortfolioProject..CovidVaccinations
--ORDER BY 3,4;

--Data Selection

GO

SELECT location, date, total_cases, new_cases, total_deaths, population
FROM PortfolioProject..CovidDeaths
ORDER BY 1,2;

GO
--Looking at the Total Covid Cases vs Total Deaths
--This Data Shows the Chances of Death if found Covid Positive in the Countires
SELECT location, CAST(date as date) as date, total_cases, total_deaths, ROUND((total_deaths / total_cases) * 100 , 2) as [Death %]
FROM PortfolioProject..CovidDeaths
WHERE location = 'India'
ORDER BY 1,2;

GO

-- Looking at the Total Covid Cases vs Total Deaths
-- This Data Shows the percentage of the Population Positive with Covid
SELECT location, CAST(date as date) as [date], population, total_cases, ROUND((total_cases / population) * 100 , 2) as [Positivity %]
FROM PortfolioProject..CovidDeaths
WHERE location = 'India'
ORDER BY 1,2;

--Looking at the Countries with the Highest Infection Rate
SELECT location, population, MAX(total_cases)as [Infection Count], MAX(ROUND((total_cases / population) * 100 , 2)) as [% of Pouplation Infected]
FROM PortfolioProject..CovidDeaths
where continent is NOT NULL
GROUP BY location, population
ORDER BY [% of Pouplation Infected] DESC;

--Looking for countries with the Highest Death count per population
SELECT location, MAX(population)[Total Population] ,MAX(CAST(total_deaths as INT)) as [TotalDeathCount]
FROM PortfolioProject..CovidDeaths
where continent is NOT NULL --The Continent data is also included so we remove it
GROUP BY location
ORDER BY TotalDeathCount DESC;

--BY CONTINENT
--Looking at the Continents with the Highest Infection Rate
SELECT location, MAX(population)[Total Population] ,MAX(CAST(total_cases as INT)) as [TotalCases], ROUND(MAX((total_cases/ population) * 100),2) as[% of Total Infected]
FROM PortfolioProject..CovidDeaths
where continent is NULL 
GROUP BY location
ORDER BY [TotalCases] DESC;

--Looking for Continents with Highest Death count per population
SELECT location, MAX(population)[Total Population] ,MAX(CAST(total_deaths as INT)) as [TotalDeathCount]
FROM PortfolioProject..CovidDeaths
where continent is NULL 
GROUP BY location
ORDER BY TotalDeathCount DESC;


--GLOBAL NUMBERS--

--Global Death Percentage from Covid 
SELECT SUM(new_cases) as [total_cases], SUM(CAST(new_deaths as int)) as [total_deaths], 
		SUM(CAST(new_deaths as int)) / SUM(new_cases) * 100 as [death_percentage]
FROM PortfolioProject..CovidDeaths
where continent is NOT NULL 
--GROUP BY date
ORDER BY 1,2

--Looking at Total Population vs Vaccinations
SELECT DEA.continent, DEA.location, DEA.date, DEA.population, CAST(VAC.new_vaccinations AS int) as [new_vaccinations], 
	SUM(CAST(VAC.new_vaccinations AS bigint)) OVER (Partition by DEA.location order by DEA.location, DEA.date) as [rollingVaccinationCount]
FROM PortfolioProject..CovidDeaths[DEA]
JOIN PortfolioProject..CovidVaccinations[VAC]
	ON DEA.location = VAC.location
	AND DEA.date = VAC.date
where DEA.continent is NOT NULL
ORDER BY 2,3


--Looking at Total Population vs Vaccinations Percentage

--USING CTE
WITH PopvsVac (continent, location, date, population, new_vaccinations, rollingVaccinationCount)
as 
(
SELECT DEA.continent, DEA.location, DEA.date, DEA.population, CAST(VAC.new_vaccinations AS int) as [new_vaccinations], 
	SUM(CAST(VAC.new_vaccinations AS bigint)) OVER (Partition by DEA.location order by DEA.location, DEA.date) as [rollingVaccinationCount]
FROM PortfolioProject..CovidDeaths[DEA]
JOIN PortfolioProject..CovidVaccinations[VAC]
	ON DEA.location = VAC.location
	AND DEA.date = VAC.date
where DEA.continent is NOT NULL
--ORDER BY 2,3
)
SELECT *, (rollingVaccinationCount/ population * 100) as [vacinationPercentage] FROM PopvsVac
WHERE location = 'India'


--Using TEMP Tables
DROP TABLE IF EXISTS #PercentPoplulationVaccinated
CREATE TABLE #PercentPoplulationVaccinated(
continent VARCHAR(255),
location NVARCHAR(255),
date DATETIME,
population NUMERIC,
new_vaccinations NUMERIC,
rollingVaccinationCount NUMERIC
)

INSERT INTO #PercentPoplulationVaccinated
SELECT DEA.continent, DEA.location, DEA.date, DEA.population, CAST(VAC.new_vaccinations AS int) as [new_vaccinations], 
	SUM(CAST(VAC.new_vaccinations AS bigint)) OVER (Partition by DEA.location order by DEA.location, DEA.date) as [rollingVaccinationCount]
FROM PortfolioProject..CovidDeaths[DEA]
JOIN PortfolioProject..CovidVaccinations[VAC]
	ON DEA.location = VAC.location
	AND DEA.date = VAC.date
where DEA.continent is NOT NULL

SELECT *, (rollingVaccinationCount/ population * 100) as [vacinationPercentage] FROM #PercentPoplulationVaccinated


--VIEW

DROP VIEW IF EXISTS PercentPoplulationVaccinated;
CREATE VIEW PercentPoplulationVaccinated as
SELECT DEA.continent, DEA.location, DEA.date, DEA.population, CAST(VAC.new_vaccinations AS int) as [new_vaccinations], 
	SUM(CAST(VAC.new_vaccinations AS bigint)) OVER (Partition by DEA.location order by DEA.location, DEA.date) as [rollingVaccinationCount]
FROM PortfolioProject..CovidDeaths[DEA]
JOIN PortfolioProject..CovidVaccinations[VAC]
	ON DEA.location = VAC.location
	AND DEA.date = VAC.date
where DEA.continent is NOT NULL

SELECT *, (rollingVaccinationCount/ population * 100) as [vacinationPercentage] FROM PercentPoplulationVaccinated
