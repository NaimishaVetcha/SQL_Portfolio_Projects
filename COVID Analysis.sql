-- 
-- Covid Death Percent | Across World | On Daily Level
Select 
	location, 
	CAST(date AS date), 
	total_cases, 
	total_deaths, 
	round((100 * total_deaths/total_cases), 2) as death_percent 
from CovidDeaths 
where continent is not null
order by 1,2;


-- Covid Death Percent | Across World | On Daily Level
Select 
	location, max(population),
	max(total_cases), 
	max(total_deaths), 
	round((100 * max(total_deaths)/max(total_cases)), 2) as death_perc_by_cases,
	round((100 * max(total_deaths)/max(population)), 2) as death_perc_by_pop
from CovidDeaths
group by location
--order by 5 desc;

Select 
	location, max(population) from CovidDeaths
	where continent is not null
group by location
order by location desc


-- Overall Cases & Deaths | In each Location | In 2020
Select 
	location, 
	max(total_cases) as #Cases, 
	max(total_deaths) as #Deaths
from CovidDeaths
where YEAR(date) = '2020' and 
group by location
order by 1;

-- Overall Cases & Deaths compared to the Population | By location 
Select 
	location, 
	max(population) as total_population,
	max(total_cases) as #Cases, 
	max(total_deaths) as #Deaths
from CovidDeaths
group by location
order by 1;

-- Population Percentage infected by COVID in each location
Select 
	location, 
	round( (100 * max(total_cases)/max(population)), 2) as tot_cases
from CovidDeaths
group by location
order by location;

 -- same query with cte
 with cte as
(Select 
	location, 
	max(population) as pop, 
	max(total_cases) as tot_cases
from CovidDeaths
group by location
)
select location, round(100*tot_cases/pop, 2) as Pop_infected from cte order by 1;


-- Month with highest infected population % in each location in 2021
with cte as 
(Select 
	location,
	MONTH(date) as month,
	round( (100 * max(total_cases)/max(population)), 2) as Infected_Perc
from CovidDeaths
where YEAR(date) = '2021' and continent is not null
group by location, MONTH(date)
),
cte1 as (select *, dense_rank() over(partition by location order by Infected_Perc desc) as rnk from cte where Infected_Perc is not null)
select location, month, Infected_Perc from cte1 where rnk = 1 order by location;

-- Month with highest infected population % in each location in 2021
with cte as 
(Select 
	location,
	MONTH(date) as month,
	round( (100 * max(total_cases)/max(population)), 2) as Infected_Perc
from CovidDeaths
where YEAR(date) = '2021'
group by location, MONTH(date)
),
cte1 as (select *, dense_rank() over(partition by location order by Infected_Perc desc) as rnk from cte where Infected_Perc is not null)
select location, month, Infected_Perc from cte1 where rnk = 1 order by location;

-- Asian country with highest infected population % in 2021 and respective month number
with cte as 
(Select 
	location,
	MONTH(date) as month,
	round( (100 * max(total_cases)/max(population)), 2) as Infected_Perc
from CovidDeaths
where YEAR(date) = '2021' and continent = 'Asia'
group by location, MONTH(date)
)
select location, month, Infected_Perc from cte where Infected_Perc = (select max(Infected_Perc) from cte);

-- Asian country with least infected population % in 2020 and respective month number
with cte as 
(Select 
	location,
	MONTH(date) as month,
	round( (100 * max(total_cases)/max(population)), 2) as Infected_Perc
from CovidDeaths
where YEAR(date) = '2020' and continent = 'Asia'
group by location, MONTH(date)
)
select location, month, Infected_Perc from cte where Infected_Perc = (select min(Infected_Perc) from cte);


-- Month with highest infected population % in each continent in 2020
with cte as 
(Select 
	continent,
	MONTH(date) as month,
	round( (100 * max(total_cases)/max(population)), 2) as Infected_Perc
from CovidDeaths
where YEAR(date) = '2020'
group by continent, MONTH(date)
),
cte1 as (select *, dense_rank() over(partition by continent order by Infected_Perc desc) as rnk from cte)
select continent, month, Infected_Perc from cte1 where rnk = 1 and continent is not null order by continent;

-- Month with highest infected population % in each continent in 2021
with cte as 
(Select 
	continent,
	MONTH(date) as month,
	round( (100 * max(total_cases)/max(population)), 2) as Infected_Perc
from CovidDeaths
where YEAR(date) = '2021'
group by continent, MONTH(date)
),
cte1 as (select *, dense_rank() over(partition by continent order by Infected_Perc desc) as rnk from cte)
select continent, month, Infected_Perc from cte1 where rnk = 1 and continent is not null order by continent;

-- From this we can conclude that, in 2021, the whole world has faced a heavy COVID impact in April, where as in 2020 it is december.
--------------------------------------------------------------------

SELECT round(sum(population)/1000000 , 2) as population_in_mil  FROM CovidDeaths d join CovidVaccinations v on d.location = v.location and d.date = v.date;
------------------------------------------------------------------
SELECT d.continent, d.location, cast(d.date as date) as Date, d.population, v.new_vaccinations 
FROM CovidDeaths d 
join CovidVaccinations v 
on d.location = v.location and d.date = v.date
where d.continent is not null
order by 1,2,3;

-- Rolling sum of new people who are vaccinated each day | By Location 
with cte as
(SELECT d.continent as cont, d.location as loc, cast(d.date as date) as Date, cast(d.population as int) as pop, cast(v.new_vaccinations as int) as new_vac
FROM CovidDeaths d 
join CovidVaccinations v 
on d.location = v.location and d.date = v.date
where d.continent is not null)

select *, sum(new_vac) over(partition by cont, loc order by date) as rolling_people_vac  from cte;

-- Calculating Vaccinated Population Percentage | By Location
with cte as
(SELECT 
	d.continent as cont, 
	d.location as loc, cast(d.date as date) as Dt, 
	cast(d.population as float) as pop, cast(v.new_vaccinations as float) as new_vac,
	sum(convert(float,v.new_vaccinations)) over(partition by d.location order by cast(d.date as date)) as rolling_people_vac
FROM CovidDeaths d 
join CovidVaccinations v 
on d.location = v.location and d.date = v.date
where d.continent is not null and v.new_vaccinations is not null)

select 
	loc, 
	max(pop) as Total_Population, 
	max(rolling_people_vac) as total_vaccinated,
	round( (100 * max(rolling_people_vac)/max(pop)), 2) as Vaccinated_Pop_Perc
from cte group by loc order by 4 desc;
