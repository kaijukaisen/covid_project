-- Selecting the columns we are going to use and ordering by location and date
SELECT location, date, total_cases, new_cases, total_deaths, population
FROM covid_deaths
ORDER BY 1, 2;

SELECT location, date, total_cases, new_cases, total_deaths, population
FROM covid_deaths
WHERE population is not null
ORDER BY 1,2;

-- Death percentage for each country

SELECT location, date, total_deaths, total_cases, round(((total_deaths / total_cases) * 100),2) AS death_percentage
FROM covid_deaths
WHERE population is not null
ORDER BY 1,2;

-- United States death_percentage calculation

SELECT location, date, total_deaths, total_cases, round(((total_deaths / total_cases) * 100),2) AS death_percentage
FROM covid_deaths
WHERE location like '%states%'
ORDER BY 1,2;

-- Showing the timeframe of the data I have (01/01/2020 - 04/30/2021)

SELECT MIN(date) AS FirstDate, MAX(date) AS LastDate FROM covid_deaths;

-- Total Cases vs Population (United States)

SELECT location, date, total_cases, population, round(((total_cases / population) * 100),2) AS PercentPopulationInfected
FROM covid_deaths
WHERE location like '%states%'
ORDER BY 1,2;

-- Total Cases vs Population (All Countries)

SELECT location, date, total_cases, population, round(((total_cases / population) * 100),2) AS PercentPopulationInfected
FROM covid_deaths
WHERE population is not null
ORDER BY 1,2;

-- Which Countries Have The Highest Infection Rate Compared To The Population (Used in the dashboard)

SELECT location, population, date, MAX(total_cases) AS HighestInfectionCount, MAX(total_cases / population) * 100 AS PercentPopulationInfected
FROM covid_deaths
GROUP BY location, population, date
ORDER BY 5 DESC;


-- Countries With The Highest Death Count Per Population

SELECT location, population, MAX(total_deaths) AS HighestDeathCount
-- round(((MAX(total_deaths / population)) * 100),2) AS PercentPopulationPassed
FROM covid_deaths
WHERE continent is not null
GROUP BY location, population
ORDER BY 3 DESC;

-- Continents With The Highest Death Count Per Population

SELECT location, MAX(total_deaths) AS TotalDeathCount
FROM covid_deaths
WHERE continent is NULL
GROUP BY location
ORDER BY TotalDeathCount DESC;


-- Shows which locations are being calculated into the North America data returned above

SELECT location, continent, MAX(total_deaths) AS HighestDeathCount
FROM covid_deaths
WHERE continent = 'North America'
GROUP BY continent, location
ORDER BY HighestDeathCount DESC;

-- Global Numbers Overall (Used in the dashboard)

SELECT SUM(new_cases) AS TotalCases, SUM(new_deaths) AS TotalDeaths, ROUND((SUM(new_deaths)/SUM(new_cases) * 100),3) AS DeathPercentage
FROM covid_deaths
WHERE continent is not NULL 
ORDER BY 1, 2;

-- Global Numbers By Date

SELECT date, SUM(new_cases) AS TotalCases, SUM(new_deaths) AS TotalDeaths, ROUND((SUM(new_deaths)/SUM(new_cases) * 100),3) AS DeathPercentage
FROM covid_deaths
WHERE continent is not NULL 
GROUP BY date
ORDER BY 1, 2;

-- Total Death Count Excluding Redundant Values (Used in the dashboard)

SELECT location, SUM(new_deaths) as TotalDeathCount
FROM covid_deaths
WHERE continent IS null 
AND location not in ('World', 'European Union', 'International')
GROUP BY location
ORDER BY TotalDeathCount DESC

-- Examining the other table covid_vaccs

SELECT *
FROM covid_vaccs;

-- Looking at total vaccinations vs total population after joining the covid_deaths and covid_vaccs tables

SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
SUM(vac.new_vaccinations) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS RollingPeopleVaccinated
FROM covid_deaths dea
JOIN covid_vaccs vac
        ON dea.location = vac.location
        AND dea.date = vac.date
WHERE dea.continent is not null
ORDER BY 2,3;

-- USE CTE

WITH PopvsVac (Continent, Location, Date, Population, New_Vaccinations, RollingPeopleVaccinated)
AS
(
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
SUM(vac.new_vaccinations) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS RollingPeopleVaccinated
FROM covid_deaths dea
JOIN covid_vaccs vac
        ON dea.location = vac.location
        AND dea.date = vac.date
WHERE dea.continent is not null
--ORDER BY 2,3
)
SELECT *, (RollingPeopleVaccinated/Population)*100 
FROM PopvsVac

-- USE TEMP TABLE

DROP TABLE IF EXISTS #PercentPopulationVaccinated

CREATE TABLE #PercentPopulationVaccinated
(
Continent nvarchar(255),
Location nvarchar(255),
Date date,
Population numeric,
New_Vaccinations numeric,
RollingPeopleVaccinated numeric
)

INSERT INTO #PercentPopulationVaccinated
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
SUM(vac.new_vaccinations) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS RollingPeopleVaccinated
FROM covid_deaths dea
JOIN covid_vaccs vac
        ON dea.location = vac.location
        AND dea.date = vac.date
-- WHERE dea.continent is not null
--ORDER BY 2,3


SELECT *, (RollingPeopleVaccinated/Population)*100 AS PercentPopVaccinated
FROM #PercentPopulationVaccinated

-- Creating view to store data for later visualizations

CREATE VIEW PercentPopulationVaccinated AS

SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
SUM(vac.new_vaccinations) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS RollingPeopleVaccinated
FROM covid_deaths dea
JOIN covid_vaccs vac
        ON dea.location = vac.location
        AND dea.date = vac.date
WHERE dea.continent is not null
-- ORDER BY 2,3