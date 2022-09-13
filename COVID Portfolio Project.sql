/*
Queries I used to examine data and trends
*/

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

-- Lets break things down by continent:
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



-- Let's determine which queries to use for creating visualizations in Tableau.

/*
Queries used for Tableau Project
*/



-- 1. 

SELECT SUM(new_cases) as total_cases, SUM(cast(new_deaths as int)) as total_deaths, SUM(cast(new_deaths as int))/SUM(New_Cases)*100 as death_percentage
FROM PortfolioProject..CovidDeaths
--WHERE location LIKE '%states%'
WHERE continent is not null 
--GROUP BY date
ORDER BY 1,2

-- Just a double check based off the data provided
-- numbers are extremely close so we will keep them - The Second includes "International"  Location


--SELECT SUM(new_cases) as total_cases, SUM(cast(new_deaths as int)) as total_deaths, SUM(cast(new_deaths as int))/SUM(New_Cases)*100 as death_percentage
--FROM PortfolioProject..CovidDeaths
----WHERE location LIKE '%states%'
--WHERE location = 'World'
----GROUP BY date
--ORDER BY 1,2


-- 2. 

-- We take these out as they are not inluded in the above queries and want to stay consistent
-- European Union is part of Europe

SELECT location, SUM(cast(new_deaths AS int)) AS total_death_count
FROM PortfolioProject..CovidDeaths
--WHERE location LIKE '%states%'
WHERE continent IS NULL 
AND location NOT IN ('World', 'European Union', 'International', 'High Income', 'Upper middle income', 'Lower middle income', 'Low income')
GROUP BY location
ORDER BY total_death_count DESC


SELECT location, SUM(CAST(new_deaths AS INT)) AS TotalDeathCount
FROM PortfolioProject..CovidDeaths
WHERE continent IS NULL 
AND location IN ('Europe', 'North America', 'South America', 'Asia', 'Africa', 'Oceania')
GROUP BY location
ORDER BY 2 DESC

-- 3.

SELECT Location, Population, MAX(total_cases) AS highest_infection_count,  Max((total_cases/population))*100 AS percent_population_infected
FROM PortfolioProject..CovidDeaths
--WHERE location LIKE '%states%'
GROUP BY Location, Population
ORDER BY percent_population_infected DESC


-- 4.


SELECT Location, Population, date, MAX(total_cases) AS highest_infection_count,  Max((total_cases/population))*100 AS percent_population_infected
FROM PortfolioProject..CovidDeaths
--WHERE location LIKE '%states%'
GROUP BY Location, Population, date
ORDER BY percent_population_infected DESC









-- Additional queries to dive deeper into the data and create more visualizations


-- 1.

SELECT dea.continent, dea.location, dea.date, dea.population
, MAX(vac.total_vaccinations) AS rolling_people_vaccinated
--, (rolling_people_vaccinated/population)*100
FROM PortfolioProject..CovidDeaths dea
JOIN PortfolioProject..CovidVaccinations vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent is not null 
GROUP BY dea.continent, dea.location, dea.date, dea.population
ORDER BY 1,2,3




-- 2.
SELECT SUM(new_cases) AS total_cases, SUM(cast(new_deaths AS int)) AS total_deaths, SUM(cast(new_deaths AS int))/SUM(New_Cases)*100 as death_percentage
From PortfolioProject..CovidDeaths
--WHERE location LIKE '%states%'
WHERE continent is not null 
--GROUP BY date
ORDER BY 1,2


-- Just a double check based off the data provided
-- numbers are extremely close so we will keep them - The Second includes "International"  Location


--SELECT SUM(new_cases) AS total_cases, SUM(cast(new_deaths as int)) AS total_deaths, SUM(cast(new_deaths as int))/SUM(New_Cases)*100 as death_percentage
--FROM PortfolioProject..CovidDeaths
----WHERE location LIKE '%states%'
--WHERE location = 'World'
----GROUP BY date
--ORDER BY 1,2


-- 3.

-- We take these out as they are not inluded in the above queries and want to stay consistent
-- European Union is part of Europe

SELECT location, SUM(cast(new_deaths AS int)) AS total_death_count
FROM PortfolioProject..CovidDeaths
--WHERE location LIKE '%states%'
WHERE continent is null 
AND location NOT IN ('World', 'European Union', 'International', 'High Income', 'Upper middle income', 'Lower middle income', 'Low income')
GROUP BY location
ORDER BY total_death_count DESC



-- 4.

SELECT Location, Population, MAX(total_cases) AS highest_infection_count,  Max((total_cases/population))*100 AS percent_population_infected
FROM PortfolioProject..CovidDeaths
--WHERE location LIKE '%states%'
GROUP BY Location, Population
ORDER BY percent_population_infected DESC



-- 5.

--SELECT Location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 as death_percentage
--FROM PortfolioProject..CovidDeaths
----WHERE location LIKE '%states%'
--WHERE continent is not null 
--ORDER BY 1,2

-- took the above query and added population
SELECT Location, date, population, total_cases, total_deaths
FROM PortfolioProject..CovidDeaths
--WHERE location LIKE '%states%'
WHERE continent is not null 
ORDER BY 1,2


-- 6. 

WITH pop_vs_vac (Continent, Location, Date, Population, people_vaccinated, people_fully_vaccinated, total_boosters, New_Vaccinations, rolling_people_vaccinated)
AS
(
SELECT dea.continent, dea.location, dea.date, dea.population, vac.people_vaccinated, vac.people_fully_vaccinated, vac.total_boosters, vac.new_vaccinations
, SUM(CONVERT(bigint,vac.new_vaccinations)) OVER (PARTITION BY dea.Location ORDER BY dea.location, dea.Date) AS rolling_people_vaccinated
--, (rolling_people_vaccinated/population)*100
FROM PortfolioProject..CovidDeaths dea
JOIN PortfolioProject..CovidVaccinations vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent is not null 
--ORDER BY 2,3
)
SELECT *, (people_vaccinated/Population)*100 AS percent_people_partially_vaccinated, (people_fully_vaccinated/Population)*100 AS percent_people_fully_vaccinated
FROM pop_vs_vac


-- 7. 

SELECT Location, Population, date, MAX(total_cases) AS highest_infection_count, Max((total_cases/population))*100 AS percent_population_infected
FROM PortfolioProject..CovidDeaths
--WHERE location LIKE '%states%'
GROUP BY Location, Population, date
ORDER BY percent_population_infected DESC
