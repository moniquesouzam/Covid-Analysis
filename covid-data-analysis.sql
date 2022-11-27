
-- SELECT * 
-- FROM covid.covidDeaths
-- ORDER BY 4,5;

-- Converting the column date in covidDeaths from text type to date type

-- UPDATE covidDeaths
-- set date = str_to_date(`date`, '%m/%d/%Y')
-- WHERE `index` > -1;

-- ALTER TABLE covid.covidDeaths
-- MODIFY COLUMN date date;

-- check if changes to date coloumn was made
SELECT * 
FROM covid.covidDeaths
ORDER BY 4,5;

-- Converting the column date in covidVaccines from text type to date type
-- UPDATE covidVaccinations
-- set date = str_to_date(`date`, '%m/%d/%Y')
-- WHERE `index` > -1;

-- ALTER TABLE covid.covidVaccinations
-- MODIFY COLUMN date date;

SELECT * 
FROM covid.covidVaccinations
ORDER BY 4,5;

-- data I want to work with only 
SELECT location, date, total_cases, new_cases, total_deaths, population
FROM covid.covidDeaths
ORDER BY 1,2;

-- total cases vs total deaths in the united states
-- likelihood of dying from covid if you contract it
SELECT location, date, total_cases, new_cases, total_deaths, (total_deaths/total_cases)*100 AS death_Percentage
FROM covid.covidDeaths
WHERE location LIKE '%states%'
ORDER BY 2;

-- pecentage of getting infected compared to population in united states for each day
SELECT location, date, total_cases,population, (total_cases/population)*100 AS Infected_Percentage
FROM covid.covidDeaths
WHERE location LIKE '%states%'
ORDER BY 2;

-- what countries have the highest infection rate compared to population
-- Ordered by the highest infected percentage in Desc order, showing the top countries first
SELECT location, population, MAX(total_cases) AS Highest_Infection_Count, MAX(total_cases/population)*100 AS Infected_Percentage
FROM covid.covidDeaths
WHERE continent IS not NULL
GROUP BY location, population
ORDER BY Infected_Percentage DESC;

-- grouping by continent for highest infection rate compared to population
-- SELECT location, MAX(total_cases) AS Highest_Infection_Count, MAX(total_cases/population)*100 AS Infected_Percentage
-- FROM covid.covidDeaths
-- WHERE continent IS NULL
-- GROUP BY location
-- ORDER BY Infected_Percentage DESC;


-- HIGHEST DEATH COUNT VS POPULATION IN COUNTRIES
-- How many people died in each country compared to population
SELECT location, MAX(CAST(total_deaths AS unsigned)) AS total_Death_Count, MAX(total_deaths/population)*100 AS Percentage_of_popluation_died
FROM covid.covidDeaths
WHERE continent IS NOT NULL
GROUP BY location
ORDER BY total_Death_Count DESC;

-- grouping by continents for HIGHEST DEATH COUNT VS POPULATION 
-- SELECT location, MAX(CAST(total_deaths AS unsigned)) AS total_Death_Count, MAX(total_deaths/population)*100 AS Percentage_of_popluation_died
-- FROM covid.covidDeaths
-- WHERE continent IS NULL
-- GROUP BY location
-- ORDER BY total_Death_Count DESC;

-- Highest death count in each Continent
SELECT continent, MAX(CAST(total_deaths AS unsigned)) AS total_Death_Count
FROM covid.covidDeaths
WHERE continent IS NOT NULL
GROUP BY continent
ORDER BY total_Death_Count DESC;

-- THE CORRECT WAY OF DOING THE ABOVE QUERY FOR MORE ACCURATE COUNT FOR CONTINENT
-- But the above is following along with youtube
-- SELECT location, MAX(CAST(total_deaths AS unsigned)) AS total_Death_Count
-- FROM covid.covidDeaths
-- WHERE continent IS NULL
-- GROUP BY location
-- ORDER BY total_Death_Count DESC;


-- GLOBAL NUMBERS 
SELECT SUM(new_cases) AS TOTAL_CASES, SUM(new_deaths) AS TOTAL_DEATHS, SUM(new_deaths)/SUM(new_cases)*100 AS death_Percentage
FROM covid.covidDeaths
WHERE continent IS NOT NULL
-- GROUP BY date
ORDER BY 1,2;



-- JOINING BOTH TABLES
-- SELECT * 
-- FROM covid.covidDeaths dea
-- join covid.covidVaccinations vac
-- 	on dea.location = vac.location
--     and dea.date = vac.date;

-- Looking at the total population vs population 
-- USING JOIN TO JOIN 2 TABLE AND PARTITION BY TO DO ROLLING COUNT OF VAXED ORDERED BY LOCATOIN AND DATE
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, 
SUM(vac.new_vaccinations) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date ) as rollingCount_VaccinatedPeople
FROM covid.covidDeaths dea
join covid.covidVaccinations vac
	on dea.location = vac.location
    and dea.date = vac.date
WHERE dea.continent IS NOT NULL    
ORDER BY 2,3;

-- USING A CTE TO DO THE SAME AS ABOVE BUT SHOWING A PERCENTAGE OF THOSE VAXED COMPARED TO POPULATION
WITH pop_vs_vac (continent, location, date, population, new_vaccinations, rollingCount_VaccinatedPeople)
as
(
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, 
SUM(vac.new_vaccinations) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date ) as rollingCount_VaccinatedPeople
FROM covid.covidDeaths dea
join covid.covidVaccinations vac
	on dea.location = vac.location
    and dea.date = vac.date
WHERE dea.continent IS NOT NULL    
-- ORDER BY 2,3; CANT DO ORDER BY IN CTE
)
select *, (rollingCount_VaccinatedPeople/population)*100 as percentVaxxed
from pop_vs_vac;


-- USING TEMP TABLE

-- Here I am using a drop table statement just in case I make any changes it will be easier to 
-- to manage to do
DROP TABLE IF EXISTS percentPopulationVaccinated;

CREATE TEMPORARY TABLE percentPopulationVaccinated (
continent text,
location text,
date date,
population double,
new_vaccinations double,
rollingCount_VaccinatedPeople double);

INSERT INTO percentPopulationVaccinated
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, 
SUM(vac.new_vaccinations) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date ) as rollingCount_VaccinatedPeople
FROM covid.covidDeaths dea
join covid.covidVaccinations vac
	on dea.location = vac.location
    and dea.date = vac.date
WHERE dea.continent IS NOT NULL;

select *, (rollingCount_VaccinatedPeople/population)*100 as percentVaxxed
from percentPopulationVaccinated;


-- CREATING A VIEW TO STORE DATA FOR VISUALIZATION

CREATE VIEW percentofPopulationVaccinatedView AS 
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, 
SUM(vac.new_vaccinations) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date ) as rollingCount_VaccinatedPeople
FROM covid.covidDeaths dea
join covid.covidVaccinations vac
	on dea.location = vac.location
    and dea.date = vac.date
WHERE dea.continent IS NOT NULL;
