/*SELECT *
FROM covid_deaths
WHERE continent is not null
ORDER BY 3,4
LIMIT 100;

SELECT *
FROM covid_vaccination
WHERE continent is not null
ORDER BY 3,4
LIMIT 100;*/

--Let's select the data that is going to be used

SELECT location, 
	   date, 
	   total_cases, 
	   new_cases, 
	   total_deaths, 
	   population
FROM covid_deaths
WHERE continent is not null
ORDER BY location, date;

-- Total Cases vs Total Deaths
-- Shows likelihood someone could pass away if Covid is acquired, change the WHERE case to check other locations

SELECT location, 
	   date, 
	   total_cases, 
	   total_deaths, 
	   (total_deaths/total_cases)*100 AS Deaths_percentage
FROM covid_deaths
WHERE continent is not null
--WHERE location = 'Colombia'
ORDER BY location, 
		 date;

-- Total Cases vs Population
-- Likelihood someone from a country has acquired Covid

SELECT location, 
	   date, 
	   total_cases, 
	   population, 
	   (total_cases/population)*100 AS Contagious_percentage
FROM covid_deaths
WHERE continent is not null
--WHERE location = 'Colombia'
ORDER BY location, 
		 date;

-- Which countries have the highest infection rate, regarding population

SELECT location, 
	   MAX(total_cases) AS max_total_cases, 
	   population, 
	   MAX((total_cases/population))*100 AS contraction_percentage
FROM covid_deaths
--WHERE location = 'Colombia'
WHERE continent IS NOT null AND total_cases IS NOT NULL
GROUP BY location, 
		 population
ORDER BY contraction_percentage DESC;

-- Countries with the highest death count
SELECT location, 
	   MAX(total_deaths) AS total_death_counts
FROM covid_deaths
WHERE total_deaths IS NOT NULL 
AND
	  continent IS NOT NULL
GROUP BY location
ORDER BY total_death_counts DESC;

-- Now let's take a look by continents
SELECT location, 
	   MAX(total_deaths) AS total_death_counts
FROM covid_deaths
WHERE (continent IS NULL
	  AND iso_code NOT LIKE('OWID_HIC')
	  AND iso_code NOT LIKE('OWID_LIC')
	  AND iso_code NOT LIKE('OWID_LMC')
	  AND iso_code NOT LIKE('OWID_UMC')
	  AND location != 'World')
GROUP BY location
ORDER BY total_death_counts DESC;

-- Now let's see a more global view
--Total Cases VS Total Deaths

SELECT date, 
	   SUM(new_cases) AS total_cases_global,
	   SUM(new_deaths) AS total_deaths_global,
	   (SUM(new_deaths)/SUM(new_cases))*100 AS Death_percentage
FROM covid_deaths
WHERE (new_cases !=0
	  AND continent IS NOT NULL)
GROUP BY date
ORDER BY date, total_cases_global;

--Let's see what is the record for the last data recorded in the dataset
--Using new_cases and new_deaths
SELECT  
	   SUM(new_cases) AS world_total_cases,
	   SUM(new_deaths) AS world_total_deaths,
	   (SUM(new_deaths)/SUM(new_cases))*100 AS Death_percentage
FROM covid_deaths
WHERE (new_cases !=0
	  AND continent IS NOT NULL);
	  
--Using total_cases and total_deaths (there's a little mismatch), using CTE

WITH death_counts AS (SELECT location, 
	   				         MAX(total_deaths) AS total_death_count,
					    	 MAX(total_cases) AS total_cases_count
					  		 
	   
FROM covid_deaths
WHERE total_deaths IS NOT NULL 
AND
	  total_cases IS NOT NULL
AND
	  continent IS NOT NULL
GROUP BY location
ORDER BY total_death_count DESC, total_cases_count DESC)

SELECT SUM(total_death_count) AS world_total_deaths,
	   SUM(total_cases_count) AS world_total_cases,
	   (SUM(total_death_count)/SUM(total_cases_count))*100 AS Death_percentage
FROM death_counts;

-- Looking at Population vs Vaccination

SELECT dea.continent, 
	   dea.location, 
	   dea.date, 
	   dea.population,
	   vac.new_vaccinations,
--Adding the order adds up in a rolling sequence
	   SUM(vac.new_vaccinations) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS rolling_people_vaccinated
FROM covid_deaths AS dea
INNER JOIN covid_vaccination AS vac
ON dea.iso_code = vac.iso_code AND
   dea.date = vac.date
WHERE dea.continent IS NOT NULL
ORDER BY dea.location, dea.date;

--Let's calculate the adding percentage through time per each country
--CTE lets me do it pretty simple as I know from which table I would like to grab the info
WITH population_vs_vaccination AS (
	SELECT dea.continent AS continent, 
	   dea.location AS location, 
	   dea.date AS date, 
	   dea.population AS population,
	   vac.new_vaccinations AS new_vaccination,
	   SUM(vac.new_vaccinations) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS rolling_people_vaccinated
FROM covid_deaths AS dea
INNER JOIN covid_vaccination AS vac
ON dea.iso_code = vac.iso_code AND
   dea.date = vac.date
WHERE dea.continent IS NOT NULL
ORDER BY dea.location, dea.date)

SELECT *, 
	   (rolling_people_vaccinated/population) *100 AS percentage_vaccinated
FROM population_vs_vaccination;


--Now, lets create some VIEWS to visualize later in Tableau or Power BI or Looker Studio (consumer preference)
-- Death Percentage
CREATE VIEW public.death_percentage
 AS
SELECT location, 
	   date, 
	   total_cases, 
	   total_deaths, 
	   (total_deaths/total_cases)*100 AS Deaths_percentage
FROM covid_deaths
WHERE continent is not null
ORDER BY location, 
		 date;

-- Contagious Percentage by date
CREATE VIEW public.contagious_percentage
 AS
SELECT location, 
	   date, 
	   total_cases, 
	   population, 
	   (total_cases/population)*100 AS Contagious_percentage
FROM covid_deaths
WHERE continent is not null
ORDER BY location, 
		 date;
		 
-- Contagious percentage only by country
CREATE VIEW public.contagious_percentage_max
 AS
SELECT location, 
	   MAX(total_cases) AS max_total_cases, 
	   population, 
	   MAX((total_cases/population))*100 AS contraction_percentage
FROM covid_deaths

WHERE continent IS NOT null AND total_cases IS NOT NULL
GROUP BY location, 
		 population
ORDER BY contraction_percentage DESC;

-- Death count by country
CREATE VIEW public.death_count_by_country
 AS
SELECT location, 
	   MAX(total_deaths) AS total_death_counts
FROM covid_deaths
WHERE total_deaths IS NOT NULL 
AND
	  continent IS NOT NULL
GROUP BY location
ORDER BY total_death_counts DESC;

-- Death count by continent
CREATE VIEW public.death_count_by_continent
 AS
SELECT location, 
	   MAX(total_deaths) AS total_death_counts
FROM covid_deaths
WHERE (continent IS NULL
	  AND iso_code NOT LIKE('OWID_HIC')
	  AND iso_code NOT LIKE('OWID_LIC')
	  AND iso_code NOT LIKE('OWID_LMC')
	  AND iso_code NOT LIKE('OWID_UMC')
	  AND location != 'World')
GROUP BY location
ORDER BY total_death_counts DESC;

-- World deaths vs population
CREATE VIEW public.death_percentage_world
 AS
SELECT date, 
	   SUM(new_cases) AS total_cases_global,
	   SUM(new_deaths) AS total_deaths_global,
	   (SUM(new_deaths)/SUM(new_cases))*100 AS Death_percentage
FROM covid_deaths
WHERE (new_cases !=0
	  AND continent IS NOT NULL)
GROUP BY date
ORDER BY date, total_cases_global;

-- World deaths vs population
CREATE VIEW public.death_percentage_world
 AS
SELECT date, 
	   SUM(new_cases) AS total_cases_global,
	   SUM(new_deaths) AS total_deaths_global,
	   (SUM(new_deaths)/SUM(new_cases))*100 AS Death_percentage
FROM covid_deaths
WHERE (new_cases !=0
	  AND continent IS NOT NULL)
GROUP BY date
ORDER BY date, total_cases_global;


-- Population vs vaccination
CREATE VIEW public.population_vs_vaccination
AS
SELECT dea.continent, 
	   dea.location, 
	   dea.date, 
	   dea.population,
	   vac.new_vaccinations,
--Adding the order adds up in a rolling sequence
	   SUM(vac.new_vaccinations) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS rolling_people_vaccinated
FROM covid_deaths AS dea
INNER JOIN covid_vaccination AS vac
ON dea.iso_code = vac.iso_code AND
   dea.date = vac.date
WHERE dea.continent IS NOT NULL
ORDER BY dea.location, dea.date;

--Rolling people vaccinated percentag
CREATE VIEW public.rolling_people_vaccinated_percentage
AS
WITH population_vs_vaccination AS (
	SELECT dea.continent AS continent, 
	   dea.location AS location, 
	   dea.date AS date, 
	   dea.population AS population,
	   vac.new_vaccinations AS new_vaccination,
	   SUM(vac.new_vaccinations) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS rolling_people_vaccinated
FROM covid_deaths AS dea
INNER JOIN covid_vaccination AS vac
ON dea.iso_code = vac.iso_code AND
   dea.date = vac.date
WHERE dea.continent IS NOT NULL
ORDER BY dea.location, dea.date)

SELECT *, 
	   (rolling_people_vaccinated/population) *100 AS percentage_vaccinated
FROM population_vs_vaccination;