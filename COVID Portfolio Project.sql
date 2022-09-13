SELECT *
FROM PortfolioProject..CovidDeaths
WHERE continent is not NULL
ORDER BY 3,4

--SELECT *
--FROM PortfolioProject..CovidVaccinations
--ORDER BY 3,4

-- Select Data that we are going to be using

SELECT Location, date, total_cases, new_cases, total_deaths, population
FROM PortfolioProject..CovidDeaths
WHERE continent is not NULL
ORDER BY 1, 2

-- Examine Total Cases vs Total Deaths
-- Shows the likelihood of dying if you contract Covid in your country
SELECT Location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 AS DeathPercentage
FROM PortfolioProject..CovidDeaths
WHERE location LIKE '%states%'
AND continent is not NULL
ORDER BY 1, 2

-- Examine Total Cases vs Population
-- Shows percentage of population that got Covid
SELECT Location, date, Population, total_cases, (total_cases/population)*100 AS CovidPercentage
FROM PortfolioProject..CovidDeaths
WHERE location LIKE '%states%'
AND continent is not NULL
ORDER BY 1, 2

-- Examine Countries with Highest Infection Rate compared to Population
SELECT Location, Population, MAX(total_cases) HighestInfectionCount, MAX((total_cases/population))*100 AS PercentInfected
FROM PortfolioProject..CovidDeaths
-- WHERE location LIKE '%states%'
WHERE continent is not NULL
GROUP BY Location, Population
ORDER BY PercentInfected DESC


-- Let's show the Countries with the Highest Death Count per Population
SELECT Location, MAX(cast(Total_deaths AS INT)) AS TotalDeathCount
FROM PortfolioProject..CovidDeaths
-- WHERE location LIKE '%states%'
WHERE continent is not NULL
GROUP BY Location
ORDER BY TotalDeathCount DESC

-- Lets break things down by continent

-- Showing continents with the highest death count per population

SELECT continent, MAX(cast(Total_deaths AS INT)) AS TotalDeathCount
FROM PortfolioProject..CovidDeaths
-- WHERE location LIKE '%states%'
WHERE continent is not NULL
GROUP BY continent
ORDER BY TotalDeathCount DESC

-- GLOBAL NUMBERS

-- Death Percentages per day
SELECT date, SUM(new_cases) AS total_cases, SUM(cast(new_deaths AS INT)) AS total_deaths, (SUM(cast(new_deaths AS INT))/SUM(new_cases))*100 AS DeathPercentage
FROM PortfolioProject..CovidDeaths
-- location LIKE '%states%'
WHERE continent is not NULL
GROUP BY date
ORDER BY 1, 2

-- Death Percentage of the world combined
SELECT  SUM(new_cases) AS total_cases, SUM(cast(new_deaths AS INT)) AS total_deaths, (SUM(cast(new_deaths AS INT))/SUM(new_cases))*100 AS DeathPercentage
FROM PortfolioProject..CovidDeaths
-- location LIKE '%states%'
WHERE continent is not NULL
--GROUP BY date
ORDER BY 1, 2

-- Looking at Total Population vs Vaccinations
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, 
SUM(cast(vac.new_vaccinations AS bigint)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS rolling_count_vaccinations,
FROM PortfolioProject..CovidDeaths dea
JOIN PortfolioProject..CovidVaccinations vac
	ON dea.location = vac.location 
	AND dea.date = vac.date 
WHERE dea.continent is not null
ORDER BY 2, 3

-- Use CTE
WITH pop_vs_vac (continent, location, date, population, new_vaccinations, rolling_count_vaccinations)
AS 
(
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, 
SUM(cast(vac.new_vaccinations AS bigint)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS rolling_count_vaccinations
FROM PortfolioProject..CovidDeaths dea
JOIN PortfolioProject..CovidVaccinations vac
	ON dea.location = vac.location 
	AND dea.date = vac.date 
WHERE dea.continent is not null
--ORDER BY 2, 3
)
SELECT *, (rolling_count_vaccinations/population)*100
FROM pop_vs_vac


-- TEMP TABLE
DROP TABLE if exists #PercentPopulationVaccinated
CREATE TABLE #PercentPopulationVaccinated
(
Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population numeric,
New_vaccinations numeric,
rolling_count_vaccinations numeric
)

INSERT INTO #PercentPopulationVaccinated
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, 
SUM(cast(vac.new_vaccinations AS bigint)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS rolling_count_vaccinations
FROM PortfolioProject..CovidDeaths dea
JOIN PortfolioProject..CovidVaccinations vac
	ON dea.location = vac.location 
	AND dea.date = vac.date 
--WHERE dea.continent is not null
--ORDER BY 2, 3

SELECT *, (rolling_count_vaccinations/population)*100
FROM #PercentPopulationVaccinated

-- Creating View to store data for later visualizations

CREATE VIEW PercentPopulationVaccinated AS 
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, 
SUM(cast(vac.new_vaccinations AS bigint)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS rolling_count_vaccinations
FROM PortfolioProject..CovidDeaths dea
JOIN PortfolioProject..CovidVaccinations vac
	ON dea.location = vac.location 
	AND dea.date = vac.date 
WHERE dea.continent is not null
--ORDER BY 2, 3

SELECT *
FROM PercentPopulationVaccinated
