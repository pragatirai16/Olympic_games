--Mention the total number of nations which participated in each olympic games
 with all_countries as
        (select games, nr.region
        from olympics_history oh
        join olympics_history_noc_regions nr ON nr.noc = oh.noc
        group by games, nr.region)
    select games, count(1) as total_countries
    from all_countries
    group by games
    order by games;
	

--Which year saw the highest and lowest no of countries participating in olympics
with all_countries as
              (select games, nr.region
              from olympics_history oh
              join olympics_history_noc_regions nr ON nr.noc=oh.noc
              group by games, nr.region),
          tot_countries as
              (select games, count(1) as total_countries
              from all_countries
              group by games)
      select distinct
      concat(first_value(games) over(order by total_countries)
      , ' - '
      , first_value(total_countries) over(order by total_countries)) as Lowest_Countries,
      concat(first_value(games) over(order by total_countries desc)
      , ' - '
      , first_value(total_countries) over(order by total_countries desc)) as Highest_Countries
      from tot_countries
      order by 1;
	  
	  
--Identify the sport which was played in all summer olympics	
with t1 as 
    (select count(distinct games) as total_summer_games
     from olympics_history
     where season = 'Summer'),
t2 as
   (select distinct sport, games
    from olympics_history
    where season = 'Summer'order by games),
t3 as
   (select sport, count(games) as no_of_games
   from t2
   group by sport)
   
select *
from t3
join t1
on t1.total_summer_games = t3.no_of_games;


--Which Sports were just played only once in the olympics
with t1 as
		(select distinct games, sport
		from olympics_history),
	  t2 as
		(select sport, count(1) as no_of_games
		from t1
		group by sport)
select t2.*, t1.games
from t2
join t1 on t1.sport = t2.sport
where t2.no_of_games = 1
order by t1.sport; 

	  
-- Fetch the top 5 athletes who have won the most gold medals
with t1 as
	(select name,count(1) as total_medals
	from olympics_history
	where medal = 'Gold'
	group by name
	order by count(1) desc),
t2 as 
     (select *, dense_rank() over(order by total_medals desc) as rnk
	 from t1)
select * 
from t2
where rnk<=5;


--Fetch the top 5 most successful countries in olympics. Success is defined by no of medals won.
with t1 as
		(select nr.region, count(1) as total_medals
		from olympics_history oh
		join olympics_history_noc_regions nr on nr.noc = oh.noc
		where medal <> 'NA'
		group by nr.region
		order by total_medals desc),
	t2 as
		(select *, dense_rank() over(order by total_medals desc) as rnk
		from t1)
select *
from t2
where rnk <= 5;


--List down total gold, silver and bronze medals won by each country
select country,
coalesce(gold,0) as gold,
coalesce(silver,0) as silver,
coalesce(bronze,0) as bronze
from crosstab
	('select r.region as country, medal, count(*) as total_medals
	from olympics_history h
	join olympics_history_noc_regions r on r.noc = h.noc
	where medal <> ''NA''
	group by r.region, medal
	order by r.region, medal',
	 'values(''Bronze''),(''Gold''),(''Silver'')')
	as result(country varchar, bronze bigint, gold bigint, silver bigint)
order by gold desc, bronze desc, silver desc;


--Identify which country won the most gold, most silver and most bronze medals in each olympic games.
with temp as
	(select substring(games_country,1, position(' - ' in games_country) -1) as games,
	substring(games_country,position(' - ' in games_country) +3) as country,
	coalesce(gold,0) as gold,
	coalesce(silver,0) as silver,
	coalesce(bronze,0) as bronze
	from crosstab
		('select concat(games,'' - '',r.region) as games_country, medal, count(*) as total_medals
		from olympics_history h
		join olympics_history_noc_regions r on r.noc = h.noc
		where medal <> ''NA''
		group by games,r.region, medal
		order by games,r.region, medal',
		 'values(''Bronze''),(''Gold''),(''Silver'')')
		as result(games_country varchar, bronze bigint, gold bigint, silver bigint)
	order by games_country)
select distinct games,
concat(first_value(country) over(partition by games order by gold desc) ,' - ',
	first_value(gold) over(partition by games order by gold desc)) as max_gold,
concat(first_value(country) over(partition by games order by silver desc) ,' - ',
	first_value(silver) over(partition by games order by silver desc)) as max_silver,
concat(first_value(country) over(partition by games order by bronze desc) ,' - ',
	first_value(bronze) over(partition by games order by bronze desc)) as max_bronze
from temp
order by games


--Which countries have never won gold medal but have won silver/bronze medals?
select * from (
SELECT country, coalesce(gold,0) as gold, coalesce(silver,0) as silver, coalesce(bronze,0) as bronze
	FROM CROSSTAB('SELECT nr.region as country
				, medal, count(1) as total_medals
				FROM OLYMPICS_HISTORY oh
				JOIN OLYMPICS_HISTORY_NOC_REGIONS nr ON nr.noc=oh.noc
				where medal <> ''NA''
				GROUP BY nr.region,medal order BY nr.region,medal',
			'values (''Bronze''), (''Gold''), (''Silver'')')
	AS FINAL_RESULT(country varchar,
	bronze bigint, gold bigint, silver bigint))x 
where gold = 0 and (silver > 0 or bronze > 0)
order by gold desc nulls last, silver desc nulls last, bronze desc nulls last;


--In which Sport/event, India has won highest medals.
with t1 as
		(select sport, count(1) as total_medals
		from olympics_history
		where medal <> 'NA'
		and team = 'India'
		group by sport
		order by total_medals desc),
	t2 as
		(select *, rank() over(order by total_medals desc) as rnk
		from t1)
select sport, total_medals
from t2
where rnk = 1;


