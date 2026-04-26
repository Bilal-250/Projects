==========================================================
  PREMIER LEAGUE DATA EXPLORATION (1993 - 2024)
  SQL Portfolio Project
  Bilal Mohammed
  
  Dataset: Premier League final standings for every season
           from 1992/93 to 2023/24.

  Columns:
    season_end_year  -- year the season ended (e.g. 2024)
    team             -- club name
    position         -- final league position (1 = champions)
    played           -- matches played
    won              -- matches won
    drawn            -- matches drawn
    lost             -- matches lost
    gf               -- goals scored
    ga               -- goals conceded
    gd               -- goal difference
    points           -- total points
    notes            -- European/relegation qualification notes
==========================================================


-- ============================================================
-- FIRST LOOK AT THE DATA
-- ============================================================

SELECT *
FROM pl_tables
LIMIT 20;


-- ============================================================
-- 1. HOW MANY SEASONS AND TEAMS ARE IN THE DATASET?
-- ============================================================

SELECT
    COUNT(DISTINCT season_end_year) AS total_seasons,
    COUNT(DISTINCT team)            AS total_teams
FROM pl_tables;


-- ============================================================
-- 2. EVERY PREMIER LEAGUE CHAMPION
-- ============================================================

SELECT
    season_end_year AS season,
    team            AS champion,
    points,
    won,
    lost,
    gf,
    ga
FROM pl_tables
WHERE position = 1
ORDER BY season_end_year;


-- ============================================================
-- 3. HOW MANY TITLES HAS EACH CLUB WON?
-- ============================================================

SELECT
    team,
    COUNT(*) AS titles
FROM pl_tables
WHERE position = 1
GROUP BY team
ORDER BY titles DESC;


-- ============================================================
-- 4. MOST POINTS IN A SINGLE SEASON
-- ============================================================

SELECT
    season_end_year AS season,
    team,
    points,
    won,
    drawn,
    lost
FROM pl_tables
ORDER BY points DESC
LIMIT 10;


-- ============================================================
-- 5. WORST EVER SEASONS (fewest points)
-- ============================================================

SELECT
    season_end_year AS season,
    team,
    position,
    points,
    won,
    lost
FROM pl_tables
ORDER BY points ASC
LIMIT 10;


-- ============================================================
-- 6. TOP GOAL SCORING SEASONS
-- ============================================================

SELECT
    season_end_year AS season,
    team,
    gf AS goals_scored
FROM pl_tables
ORDER BY gf DESC
LIMIT 10;


-- ============================================================
-- 7. MOST GOALS CONCEDED IN A SINGLE SEASON
-- ============================================================

SELECT
    season_end_year AS season,
    team,
    ga AS goals_conceded,
    position
FROM pl_tables
ORDER BY ga DESC
LIMIT 10;


-- ============================================================
-- 8. ARSENAL'S INVINCIBLE SEASON
--    Who has ever gone a full season without losing?
-- ============================================================

SELECT
    season_end_year AS season,
    team,
    played,
    won,
    drawn,
    lost,
    points
FROM pl_tables
WHERE lost = 0;


-- ============================================================
-- 9. ALL OF MANCHESTER UNITED'S SEASONS
-- ============================================================

SELECT
    season_end_year AS season,
    position,
    points,
    won,
    lost,
    gf,
    ga
FROM pl_tables
WHERE team = 'Manchester Utd'
ORDER BY season_end_year;


-- ============================================================
-- 10. HOW MANY TIMES HAS EACH TEAM FINISHED IN THE TOP 4?
-- ============================================================

SELECT
    team,
    COUNT(*) AS top_4_finishes
FROM pl_tables
WHERE position <= 4
GROUP BY team
ORDER BY top_4_finishes DESC;


-- ============================================================
-- 11. TEAMS WITH THE MOST RELEGATED SEASONS
--     (bottom 3 = positions 18, 19, 20 from 1995 onwards)
--     (bottom 3 = positions 20, 21, 22 in the 22-team 1993/94 seasons)
-- ============================================================

SELECT
    team,
    COUNT(*) AS times_relegated
FROM pl_tables
WHERE
    (season_end_year IN (1993, 1994) AND position >= 20)
    OR
    (season_end_year >= 1995 AND position >= 18)
GROUP BY team
ORDER BY times_relegated DESC;


-- ============================================================
-- 12. AVERAGE POINTS PER SEASON FOR EACH CLUB
--     (only clubs with 5 or more seasons in the PL)
-- ============================================================

SELECT
    team,
    COUNT(*)               AS seasons_played,
    ROUND(AVG(points), 1)  AS avg_points_per_season,
    ROUND(AVG(position),1) AS avg_finish
FROM pl_tables
GROUP BY team
HAVING COUNT(*) >= 5
ORDER BY avg_points_per_season DESC;


-- ============================================================
-- 13. WHICH SEASON HAD THE MOST COMBINED GOALS?
-- ============================================================

SELECT
    season_end_year AS season,
    SUM(gf)         AS total_goals_scored
FROM pl_tables
GROUP BY season_end_year
ORDER BY total_goals_scored DESC;


-- ============================================================
-- 14. POINTS NEEDED TO WIN THE TITLE EACH SEASON
-- ============================================================

SELECT
    season_end_year AS season,
    team            AS champion,
    points
FROM pl_tables
WHERE position = 1
ORDER BY points DESC;


-- ============================================================
-- 15. HOW FAR AHEAD WAS THE CHAMPION FROM 2ND PLACE?
-- ============================================================

SELECT
    champ.season_end_year          AS season,
    champ.team                     AS champion,
    champ.points                   AS champion_points,
    runner.team                    AS runner_up,
    runner.points                  AS runner_up_points,
    champ.points - runner.points   AS points_gap
FROM pl_tables AS champ
JOIN pl_tables AS runner
    ON champ.season_end_year = runner.season_end_year
WHERE champ.position = 1
  AND runner.position = 2
ORDER BY points_gap DESC;


-- ============================================================
-- 16. MANCHESTER CITY vs MANCHESTER UNITED
--     Average points and average finish compared side by side
-- ============================================================

SELECT
    team,
    COUNT(*)               AS seasons,
    SUM(won)               AS total_wins,
    SUM(lost)              AS total_losses,
    SUM(points)            AS total_points,
    ROUND(AVG(points), 1)  AS avg_points,
    ROUND(AVG(position),1) AS avg_finish,
    MIN(position)          AS best_finish
FROM pl_tables
WHERE team IN ('Manchester City', 'Manchester Utd')
GROUP BY team;


-- ============================================================
-- 17. LIVERPOOL'S RECORD SEASON BY SEASON
-- ============================================================

SELECT
    season_end_year AS season,
    position,
    points,
    won,
    drawn,
    lost,
    gf,
    ga,
    gd
FROM pl_tables
WHERE team = 'Liverpool'
ORDER BY season_end_year;


-- ============================================================
-- 18. BIGGEST SHOCKS -- TEAMS RELEGATED AFTER A TOP 10 FINISH
-- ============================================================

SELECT
    current_season.team,
    current_season.season_end_year  AS relegated_season,
    current_season.position         AS relegated_position,
    prev_season.season_end_year     AS previous_season,
    prev_season.position            AS previous_position
FROM pl_tables AS current_season
JOIN pl_tables AS prev_season
    ON  current_season.team = prev_season.team
    AND current_season.season_end_year = prev_season.season_end_year + 1
WHERE current_season.position >= 18
  AND prev_season.position    <= 10
ORDER BY current_season.season_end_year;


-- ============================================================
-- 19. TOTAL WINS, DRAWS AND LOSSES FOR EACH TEAM ALL TIME
-- ============================================================

SELECT
    team,
    SUM(won)   AS total_wins,
    SUM(drawn) AS total_draws,
    SUM(lost)  AS total_losses,
    SUM(gf)    AS total_goals_for,
    SUM(ga)    AS total_goals_against
FROM pl_tables
GROUP BY team
ORDER BY total_wins DESC;


-- ============================================================
-- 20. FINAL SUMMARY -- TOP 10 CLUBS OF ALL TIME IN THE PL
--     Ranked by total points accumulated
-- ============================================================

SELECT
    team,
    COUNT(DISTINCT season_end_year)                AS seasons_in_pl,
    SUM(CASE WHEN position = 1 THEN 1 ELSE 0 END) AS titles,
    SUM(won)                                       AS total_wins,
    SUM(lost)                                      AS total_losses,
    SUM(gf)                                        AS goals_scored,
    SUM(ga)                                        AS goals_conceded,
    SUM(points)                                    AS total_points
FROM pl_tables
GROUP BY team
ORDER BY total_points DESC
LIMIT 10;
