-- Disable safe update to be able to modify the tables
SET SQL_SAFE_UPDATES = 0;

-- Deleting rows with no earnings or tournaments
DELETE FROM new_schema.generalesportdata
WHERE TotalEarnings = 0 or TotalTournaments = 0

-- Converting earning columns from double to integer
ALTER TABLE new_schema.generalesportdata
MODIFY COLUMN OnlineEarnings INT
MODIFY COLUMN TotalEarnings INT

-- Data Grouped by genre
SELECT 	Genre,
		SUM(TotalEarnings) as TotalEarnings ,
		SUM(OnlineEarnings) as OnlineEarnings,
        SUM(TotalPlayers) as TotalPlayers,
        SUM(TotalTournaments) as TotalTournaments 
FROM  new_schema.generalesportdata
GROUP BY Genre
ORDER BY TotalEarnings DESC

-- Joined data esports + twitch (Using CTE)
WITH twig AS 
(SELECT Game,
		avg(Avg_viewers) as AverageViewers,
		MAX(Peak_viewers) as PeakViewers
FROM new_schema.twitch_game_data
GROUP BY Game
ORDER BY AverageViewers DESC)

SELECT 	esp.game,
        esp.Genre,
		esp.TotalEarnings,
        esp.OnlineEarnings,
        twig.AverageViewers,
        twig.PeakViewers
FROM  	new_schema.generalesportdata esp 	
		JOIN  twig
		ON esp.Game = twig.Game

-- Joined data grouped by genre (Using CTE)
WITH twig AS 
(SELECT Game,
		avg(Avg_viewers) as AverageViewers,
		MAX(Peak_viewers) as PeakViewers
FROM new_schema.twitch_game_data
GROUP BY Game
ORDER BY AverageViewers DESC)
                
SELECT 	esp.Genre,
		SUM(esp.TotalEarnings) as Earnings,
        SUM(esp.OnlineEarnings) as Online_Earnings,
        SUM(twig.AverageViewers) as Added_Average_Viewers,
        SUM(twig.PeakViewers) as Added_Peak_Viewers
FROM  	new_schema.generalesportdata esp 	
		JOIN twig
		ON esp.Game = twig.Game
        GROUP BY esp.Genre


-- Data grouped by game realease year
SELECT 	ReleaseDate,
		SUM(TotalEarnings) as TotalEarnings ,
		SUM(OnlineEarnings) as OnlineEarnings,
        SUM(TotalPlayers) as TotalPlayers,
        SUM(TotalTournaments) as TotalTournaments 
FROM  new_schema.generalesportdata
GROUP BY ReleaseDate
ORDER BY ReleaseDate ASC

-- Player count to tournament count ratio and Total Earning per tournament and per player
SELECT 		Game, 
			ROUND((TotalPlayers / TotalTournaments),2) as NumPlayerToNumTournaments, 
            ROUND((TotalEarnings / TotalTournaments),0) as AverageEarningsPerTournament,
            ROUND((TotalEarnings / TotalPlayers),0) as EarningPerPlayerRatio
FROM  new_schema.generalesportdata
ORDER BY AverageEarningsPerTournament DESCnew_tablenew_table

-- Player count to tournament count ratio and Total Earning per tournament and per player GROUPED BY GENRE
SELECT 		Genre,
			SUM(TotalPlayers)as Players,
            SUM(TotalTournaments) as Tournaments,
			ROUND(SUM(TotalPlayers) / SUM(TotalTournaments),2) as NumPlayerToNumTournaments, 
            ROUND(SUM(TotalEarnings) / SUM(TotalTournaments),0) as AverageEarningsPerTournament,
            ROUND(SUM(TotalEarnings) / SUM(TotalPlayers),0) as EarningPerPlayerRatio
FROM  new_schema.generalesportdata
GROUP BY Genre
ORDER BY AverageEarningsPerTournament DESC

-- Essential Data grouped by year (esport and twitch.tv)
SELECT 	EXTRACT(year FROM esp.Date) AS Year, 
		SUM(esp.Earnings) AS Earnings, 
        avg(esp.Players) AS AveragePlayers, 
        sum(esp.Tournaments) AS Tournaments,
        SUM(esp.Earnings) / sum(esp.Tournaments) AS AverageTournamentEarnings,
		AVG(twi.Avg_viewers) AS AverageViewers,
        MAX(twi.Peak_viewers) AS PeakViwers
FROM new_schema.historicalesportdata esp LEFT JOIN new_schema.twitch_global_data twi ON EXTRACT(year FROM esp.Date) = twi.year
WHERE Year < 2023
GROUP BY EXTRACT(year FROM esp.Date)
ORDER BY EXTRACT(year FROM esp.Date) asc

-- Tournament Cash Prize grouped by genre and range
SELECT 
  esp.genre,
  SUM(CASE WHEN hesp.earnings BETWEEN 0 AND 1000 THEN 1 ELSE 0 END) as '0-1000',
  SUM(CASE WHEN hesp.earnings BETWEEN 1000 AND 5000 THEN 1 ELSE 0 END) as '1000-5000',
  SUM(CASE WHEN hesp.earnings BETWEEN 5000 AND 10000 THEN 1 ELSE 0 END) as '5000-10000',
  SUM(CASE WHEN hesp.earnings BETWEEN 10000 AND 50000 THEN 1 ELSE 0 END) as '10000-50000',
  SUM(CASE WHEN hesp.earnings > 50000 THEN 1 ELSE 0 END) as '50000+'
FROM 	new_schema.historicalesportdata hesp 
		JOIN new_schema.generalesportdata esp
		ON hesp.game = esp.game
GROUP BY esp.genre
ORDER BY esp.genre

-- Earning grouped by coutry
SELECT 	Country,
		SUM(TotalEarning) AS Earnings
FROM new_schema.esport_country
GROUP BY Country
ORDER BY Earnings DESC