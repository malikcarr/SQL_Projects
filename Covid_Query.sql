SELECT * 
FROM `portfolio-project-395319.Covid_Data.Covid_Deaths`
WHERE continent IS NOT NULL
ORDER BY 3,4;

SELECT *
FROM `portfolio-project-395319.Covid_Data.Covid_Vaccinations`
ORDER BY 3, 4;

SELECT location, date, total_cases, new_cases, total_deaths, population
FROM `portfolio-project-395319.Covid_Data.Covid_Deaths`
ORDER BY 1,2;

--Total cases against total deaths
--Likelihood of dying if you catch covid in USA
SELECT location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 AS death_percentage
FROM `portfolio-project-395319.Covid_Data.Covid_Deaths`
WHERE location LIKE '%States%'
ORDER BY 1,2;

--Total cases against population
--Percentage of population with covid
SELECT location, date, total_cases, population, (total_cases/population)*100 AS population_percentage
FROM `portfolio-project-395319.Covid_Data.Covid_Deaths`
WHERE location LIKE '%States%'
ORDER BY 1,2;

--Countries with highest infection rates compared to population

SELECT location, MAX(total_cases) AS highest_infection_count, population, MAX((total_cases/population))*100 AS percent_population_infected
FROM `portfolio-project-395319.Covid_Data.Covid_Deaths`
--WHERE location LIKE '%States%'
GROUP BY location, population
ORDER BY percent_population_infected DESC;

--Countries with highest death count per population

SELECT location, MAX(cast(total_deaths as int)) AS total_death_count
FROM `portfolio-project-395319.Covid_Data.Covid_Deaths`
WHERE continent IS NOT NULL
GROUP BY location
ORDER BY total_death_count DESC;

--Continents with highest death count per population
SELECT continent, MAX(cast(total_deaths as int)) AS total_death_count
FROM `portfolio-project-395319.Covid_Data.Covid_Deaths`
WHERE continent IS NOT NULL
GROUP BY continent
ORDER BY total_death_count DESC;

--Global

SELECT date, SUM(new_cases) as total_cases, SUM(new_deaths) as total_deaths, SUM(total_deaths)/SUM(total_cases)*100 as death_percentage
FROM `portfolio-project-395319.Covid_Data.Covid_Deaths`
--WHERE location LIKE '%States%'
WHERE continent IS NOT NULL
GROUP BY date
ORDER BY 1,2;

--Total Population vs Vaccinations
SELECT `Covid_Data.Covid_Deaths`.continent, `Covid_Data.Covid_Deaths`.location, `Covid_Data.Covid_Deaths`.date, `Covid_Data.Covid_Deaths`.population, `Covid_Data.Covid_Vaccinations`.new_vaccinations, SUM(CAST(`Covid_Data.Covid_Vaccinations`.new_vaccinations as int)) OVER (PARTITION BY `Covid_Data.Covid_Deaths`.location ORDER BY `Covid_Data.Covid_Deaths`.location, `Covid_Data.Covid_Deaths`.date) as rolling_people_vaccinated --, (rolling_people_vaccinated/population)*100
FROM `Covid_Data.Covid_Deaths` 
JOIN `Covid_Data.Covid_Vaccinations` 
  ON `Covid_Data.Covid_Deaths`.location = `Covid_Data.Covid_Vaccinations`.location
  and `Covid_Data.Covid_Deaths`.date = `Covid_Data.Covid_Vaccinations`.date
WHERE `Covid_Data.Covid_Deaths`.continent IS NOT NULL
--and `Covid_Data.Covid_Deaths`.location = 'Albania'
ORDER BY 2,3;


--Use CTE

WITH PopvsVac AS (
    SELECT 
        cd.continent,
        cd.location,
        cd.date,
        cd.population,
        cv.new_vaccinations,
        SUM(CAST(cv.new_vaccinations AS INT64)) OVER (PARTITION BY cd.location ORDER BY cd.date) AS rolling_people_vaccinated --,(rolling_people_vaccinated)
      FROM 
        `Covid_Data.Covid_Deaths` AS cd
    JOIN 
        `Covid_Data.Covid_Vaccinations` AS cv
    ON 
        cd.location = cv.location
        AND cd.date = cv.date
    WHERE 
        cd.continent IS NOT NULL
)
SELECT *, (rolling_people_vaccinated/population)*100
FROM PopvsVac;

--Temp Table for calculation on partition

CREATE TEMP TABLE PercentPopulationVaccinated AS
SELECT
    cd.continent,
    cd.location,
    cd.date,
    cd.population,
    cv.new_vaccinations,
    SUM(CAST(cv.new_vaccinations AS NUMERIC)) OVER (PARTITION BY cd.location ORDER BY cd.date) AS RollingPeopleVaccinated
FROM
    `Covid_Data.Covid_Deaths` AS cd
JOIN
    `Covid_Data.Covid_Vaccinations` AS cv
ON
    cd.location = cv.location
    AND cd.date = cv.date;

Select *, (RollingPeopleVaccinated/Population)*100
From PercentPopulationVaccinated;
