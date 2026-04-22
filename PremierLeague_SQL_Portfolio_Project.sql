/*
================================================================================
  PREMIER LEAGUE DATA EXPLORATION (1993–2024)
  SQL Portfolio Project
  
  Dataset: Premier League final standings for every season from 1992/93
           to 2023/24 (season_end_year 1993–2024).
  
  Tables used:
    pl_tables  — one row per team per season
      season_end_year  INT      -- year the season ended (e.g. 2024)
      team             TEXT     -- club name
      position         INT      -- final league position (1 = champion)
      played           INT      -- matches played
      won              INT      -- matches won
      drawn            INT      -- matches drawn
      lost             INT      -- matches lost
      gf               INT      -- goals for
      ga               INT      -- goals against
      gd               INT      -- goal difference
      points           INT      -- total points
      notes            TEXT     -- European/relegation qualification notes
      
  Skills demonstrated:
    Aggregations & GROUP BY · Window Functions (RANK, ROW_NUMBER, LAG, LEAD,
    running totals) · CTEs · Subqueries · CASE expressions · String filtering
    (LIKE / ILIKE) · Date arithmetic · Self-joins · Set operations
================================================================================
*/


-- ============================================================
-- 0. QUICK LOOK AT THE DATA
-- ============================================================

-- All columns, first 20 rows
SELECT *
FROM pl_tables
ORDER BY season_end_year, position
LIMIT 20;

-- How many seasons and teams are in the dataset?
SELECT
    COUNT(DISTINCT season_end_year) AS total_seasons,
    COUNT(DISTINCT team)            AS unique_teams,
    MIN(season_end_year)            AS first_season,
    MAX(season_end_year)            AS last_season
FROM pl_tables;


-- ============================================================
-- 1. TITLE WINNERS — every Premier League champion
-- ============================================================

SELECT
    season_end_year AS season,
    team            AS champion,
    points,
    won,
    gf,
    ga,
    gd
FROM pl_tables
WHERE position = 1
ORDER BY season_end_year;


-- ============================================================
-- 2. HOW MANY TITLES HAS EACH CLUB WON?
-- ============================================================

SELECT
    team,
    COUNT(*)  AS titles,
    MIN(season_end_year) AS first_title,
    MAX(season_end_year) AS last_title
FROM pl_tables
WHERE position = 1
GROUP BY team
ORDER BY titles DESC;


-- ============================================================
-- 3. TOP-4 FINISHES — European qualification appearances
--    (Champions League spots are positions 1–4 in the modern era)
-- ============================================================

SELECT
    team,
    COUNT(*) AS top4_finishes
FROM pl_tables
WHERE position <= 4
GROUP BY team
ORDER BY top4_finishes DESC
LIMIT 10;


-- ============================================================
-- 4. MOST POINTS IN A SINGLE SEASON (all-time)
-- ============================================================

SELECT
    season_end_year AS season,
    team,
    points,
    won,
    drawn,
    lost,
    gd
FROM pl_tables
ORDER BY points DESC
LIMIT 10;


-- ============================================================
-- 5. WORST SEASONS — fewest points recorded
-- ============================================================

SELECT
    season_end_year AS season,
    team,
    position,
    points,
    won,
    lost,
    gd
FROM pl_tables
ORDER BY points ASC
LIMIT 10;


-- ============================================================
-- 6. GOAL-SCORING RECORDS
--    Most goals scored / conceded in a single season
-- ============================================================

-- Most goals scored
SELECT
    season_end_year AS season,
    team,
    gf AS goals_scored
FROM pl_tables
ORDER BY gf DESC
LIMIT 10;

-- Most goals conceded
SELECT
    season_end_year AS season,
    team,
    ga AS goals_conceded
FROM pl_tables
ORDER BY ga DESC
LIMIT 10;

-- Best goal difference ever recorded
SELECT
    season_end_year AS season,
    team,
    gf,
    ga,
    gd
FROM pl_tables
ORDER BY gd DESC
LIMIT 10;


-- ============================================================
-- 7. TEAM CAREER STATISTICS
--    Aggregated totals across all Premier League seasons played
-- ============================================================

SELECT
    team,
    COUNT(DISTINCT season_end_year)                        AS seasons_in_pl,
    SUM(won)                                               AS total_wins,
    SUM(drawn)                                             AS total_draws,
    SUM(lost)                                              AS total_losses,
    SUM(gf)                                                AS total_goals_for,
    SUM(ga)                                                AS total_goals_against,
    SUM(gd)                                                AS total_gd,
    SUM(points)                                            AS total_points,
    ROUND(AVG(points), 2)                                  AS avg_points_per_season,
    ROUND(AVG(position), 2)                                AS avg_finish_position,
    ROUND(SUM(won)::NUMERIC / NULLIF(SUM(played), 0) * 100, 1) AS win_pct
FROM pl_tables
GROUP BY team
ORDER BY total_points DESC;


-- ============================================================
-- 8. SEASON-BY-SEASON RANK FOR THE "BIG SIX"
--    Using a CASE expression to flag the traditional top clubs
-- ============================================================

SELECT
    season_end_year AS season,
    team,
    position,
    points,
    CASE
        WHEN team IN ('Manchester Utd', 'Arsenal', 'Chelsea',
                      'Liverpool', 'Manchester City', 'Tottenham')
        THEN 'Big Six'
        ELSE 'Other'
    END AS club_tier
FROM pl_tables
ORDER BY season_end_year, position;


-- ============================================================
-- 9. WINDOW FUNCTION — RANK TEAMS WITHIN EACH SEASON
--    (Confirms position column; also useful for custom metrics)
-- ============================================================

SELECT
    season_end_year                                             AS season,
    team,
    points,
    gd,
    RANK()       OVER (PARTITION BY season_end_year ORDER BY points DESC, gd DESC) AS points_rank,
    DENSE_RANK() OVER (PARTITION BY season_end_year ORDER BY gf DESC)              AS goals_scored_rank
FROM pl_tables
ORDER BY season_end_year, points_rank;


-- ============================================================
-- 10. YEAR-OVER-YEAR POINTS CHANGE PER TEAM
--     Using LAG() to compare a team's points to the previous season
-- ============================================================

SELECT
    season_end_year                                             AS season,
    team,
    points,
    LAG(points) OVER (PARTITION BY team ORDER BY season_end_year) AS prev_season_points,
    points - LAG(points) OVER (PARTITION BY team ORDER BY season_end_year) AS yoy_change,
    position,
    LAG(position) OVER (PARTITION BY team ORDER BY season_end_year) AS prev_position
FROM pl_tables
ORDER BY team, season_end_year;


-- ============================================================
-- 11. BIGGEST SINGLE-SEASON IMPROVEMENTS & DECLINES
--     (via CTE wrapping the LAG query above)
-- ============================================================

WITH yoy AS (
    SELECT
        season_end_year AS season,
        team,
        points,
        points - LAG(points) OVER (PARTITION BY team ORDER BY season_end_year) AS pts_change,
        position - LAG(position) OVER (PARTITION BY team ORDER BY season_end_year) AS pos_change
    FROM pl_tables
)
-- Biggest points improvements
SELECT
    season,
    team,
    pts_change AS points_improvement,
    pos_change AS positions_gained   -- negative = moved up the table
FROM yoy
WHERE pts_change IS NOT NULL
ORDER BY pts_change DESC
LIMIT 10;


-- Biggest points declines (same CTE)
WITH yoy AS (
    SELECT
        season_end_year AS season,
        team,
        points,
        points - LAG(points) OVER (PARTITION BY team ORDER BY season_end_year) AS pts_change
    FROM pl_tables
)
SELECT
    season,
    team,
    pts_change AS points_decline
FROM yoy
WHERE pts_change IS NOT NULL
ORDER BY pts_change ASC
LIMIT 10;


-- ============================================================
-- 12. RUNNING TOTAL OF WINS — career cumulative wins per club
-- ============================================================

SELECT
    season_end_year AS season,
    team,
    won,
    SUM(won) OVER (PARTITION BY team ORDER BY season_end_year
                   ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS cumulative_wins
FROM pl_tables
ORDER BY team, season_end_year;


-- ============================================================
-- 13. RELEGATION ANALYSIS
--     Identify relegated teams (position 18, 19, or 20 from 1995 onwards;
--     positions 21 & 22 in the 22-team 1993 and 1994 seasons)
-- ============================================================

SELECT
    season_end_year AS season,
    team,
    position,
    points,
    gd
FROM pl_tables
WHERE
    (season_end_year IN (1993, 1994) AND position >= 21)
    OR
    (season_end_year >= 1995 AND position >= 18)
ORDER BY season_end_year, position;

-- Teams relegated most often
SELECT
    team,
    COUNT(*) AS times_relegated
FROM pl_tables
WHERE
    (season_end_year IN (1993, 1994) AND position >= 21)
    OR
    (season_end_year >= 1995 AND position >= 18)
GROUP BY team
ORDER BY times_relegated DESC;


-- ============================================================
-- 14. CONSECUTIVE SEASONS IN THE TOP FLIGHT
--     How long has each club stayed up without relegation?
--     Uses a gaps-and-islands approach.
-- ============================================================

WITH appearances AS (
    SELECT
        team,
        season_end_year,
        season_end_year
            - ROW_NUMBER() OVER (PARTITION BY team ORDER BY season_end_year) AS grp
    FROM pl_tables
),
streaks AS (
    SELECT
        team,
        MIN(season_end_year) AS streak_start,
        MAX(season_end_year) AS streak_end,
        COUNT(*)             AS consecutive_seasons
    FROM appearances
    GROUP BY team, grp
)
SELECT
    team,
    streak_start,
    streak_end,
    consecutive_seasons
FROM streaks
ORDER BY consecutive_seasons DESC, streak_end DESC
LIMIT 20;


-- ============================================================
-- 15. AVERAGE POINTS OF CHAMPIONS VS. RUNNERS-UP
--     Using a subquery to join positions 1 and 2
-- ============================================================

SELECT
    champ.season_end_year              AS season,
    champ.team                         AS champion,
    champ.points                       AS champion_points,
    runner.team                        AS runner_up,
    runner.points                      AS runner_up_points,
    champ.points - runner.points       AS points_gap
FROM
    (SELECT * FROM pl_tables WHERE position = 1) AS champ
JOIN
    (SELECT * FROM pl_tables WHERE position = 2) AS runner
    ON champ.season_end_year = runner.season_end_year
ORDER BY points_gap DESC;


-- Average winning margin
SELECT
    ROUND(AVG(champ.points - runner.points), 2) AS avg_title_winning_margin
FROM
    (SELECT * FROM pl_tables WHERE position = 1) AS champ
JOIN
    (SELECT * FROM pl_tables WHERE position = 2) AS runner
    ON champ.season_end_year = runner.season_end_year;


-- ============================================================
-- 16. HAS THE PREMIER LEAGUE BECOME MORE COMPETITIVE?
--     Compare average points gap (1st vs 10th) across decades
-- ============================================================

WITH gaps AS (
    SELECT
        t1.season_end_year,
        t1.points - t10.points AS gap_1st_vs_10th,
        CASE
            WHEN t1.season_end_year BETWEEN 1993 AND 2002 THEN '1990s/early2000s'
            WHEN t1.season_end_year BETWEEN 2003 AND 2012 THEN '2000s/early2010s'
            ELSE '2013-2024'
        END AS era
    FROM
        (SELECT * FROM pl_tables WHERE position = 1)  AS t1
    JOIN
        (SELECT * FROM pl_tables WHERE position = 10) AS t10
        ON t1.season_end_year = t10.season_end_year
)
SELECT
    era,
    ROUND(AVG(gap_1st_vs_10th), 1) AS avg_points_gap,
    COUNT(*)                        AS seasons
FROM gaps
GROUP BY era
ORDER BY era;


-- ============================================================
-- 17. EUROPEAN QUALIFICATION — filter by notes column
-- ============================================================

-- All Champions League qualifications (via league finish)
SELECT
    season_end_year AS season,
    team,
    position,
    points,
    notes
FROM pl_tables
WHERE notes ILIKE '%Champions League%'
ORDER BY season_end_year, position;

-- All relegated teams (notes contain 'Relegated')
SELECT
    season_end_year AS season,
    team,
    position,
    points
FROM pl_tables
WHERE notes ILIKE '%relegated%'
ORDER BY season_end_year;


-- ============================================================
-- 18. UNBEATEN SEASONS — teams with 0 losses
--     Arsenal's 'Invincibles' 2003/04 should appear here
-- ============================================================

SELECT
    season_end_year AS season,
    team,
    played,
    won,
    drawn,
    lost,
    points,
    position
FROM pl_tables
WHERE lost = 0
ORDER BY season_end_year;


-- ============================================================
-- 19. HEAD-TO-HEAD ERA DOMINANCE
--     Points-per-season average by club, per era
-- ============================================================

SELECT
    team,
    CASE
        WHEN season_end_year BETWEEN 1993 AND 2002 THEN 'Era 1 (1993–2002)'
        WHEN season_end_year BETWEEN 2003 AND 2012 THEN 'Era 2 (2003–2012)'
        ELSE                                             'Era 3 (2013–2024)'
    END                            AS era,
    COUNT(*)                       AS seasons_in_era,
    ROUND(AVG(points), 1)          AS avg_points,
    ROUND(AVG(position), 1)        AS avg_position,
    MIN(position)                  AS best_finish,
    MAX(position)                  AS worst_finish
FROM pl_tables
GROUP BY team, era
HAVING COUNT(*) >= 3          -- only teams with meaningful sample
ORDER BY team, era;


-- ============================================================
-- 20. FINAL SUMMARY VIEW
--     One row per team: all-time PL stats at a glance
-- ============================================================

SELECT
    team,
    COUNT(DISTINCT season_end_year)                                    AS pl_seasons,
    SUM(CASE WHEN position = 1  THEN 1 ELSE 0 END)                    AS titles,
    SUM(CASE WHEN position <= 4 THEN 1 ELSE 0 END)                    AS top4s,
    SUM(CASE WHEN position <= 10 THEN 1 ELSE 0 END)                   AS top10s,
    SUM(CASE WHEN (season_end_year IN (1993,1994) AND position >= 21)
              OR  (season_end_year >= 1995        AND position >= 18)
             THEN 1 ELSE 0 END)                                        AS relegations,
    SUM(won)                                                           AS total_wins,
    SUM(drawn)                                                         AS total_draws,
    SUM(lost)                                                          AS total_losses,
    SUM(gf)                                                            AS total_gf,
    SUM(ga)                                                            AS total_ga,
    SUM(gd)                                                            AS total_gd,
    SUM(points)                                                        AS total_points,
    ROUND(AVG(points),   1)                                            AS avg_pts_season,
    ROUND(AVG(position), 1)                                            AS avg_finish
FROM pl_tables
GROUP BY team
ORDER BY total_points DESC;
