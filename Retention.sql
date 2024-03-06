--Chapter-2.2_Retention
--Retention
WITH cohort AS (
    SELECT install_date,
           TIMESTAMP_DIFF(event_date, install_date, DAY) AS cohort_age,
           COUNT(DISTINCT CAST(gse.user_id AS INT64)) AS cohort_size,
FROM `project_game.players` p
INNER JOIN `game-analysis-01.project_game.stage_events`  gse
ON gse.user_id = CAST(p.user_id AS INT64)
GROUP BY 1,2
)
SELECT install_date,
SUM(CASE WHEN cohort_age = 0 THEN cohort_size ELSE 0 END) as DO,
SUM(CASE WHEN cohort_age = 1 THEN cohort_size ELSE 0 END) as D1,
SUM(CASE WHEN cohort_age =3 THEN cohort_size ELSE 0 END) as D3,
SUM(CASE WHEN cohort_age = 7 THEN cohort_size ELSE 0 END) as D7,
SUM(CASE WHEN cohort_age = 14 THEN cohort_size ELSE 0 END) as D14,

ROUND (SUM (CASE WHEN cohort_age = 1 THEN cohort_size ELSE 0 END) / SUM (CASE WHEN cohort_Age = 0 THEN cohort_size ELSE 0 END), 2 ) as D1R,
ROUND (SUM (CASE WHEN cohort_age = 3 THEN cohort_size ELSE 0 END) / SUM (CASE WHEN cohort_Age = 0 THEN cohort_size ELSE 0 END), 2 ) as D3R,
ROUND (SUM (CASE WHEN cohort_age = 7 THEN cohort_size ELSE 0 END) / SUM (CASE WHEN cohort_Age = 0 THEN cohort_size ELSE 0 END), 2 ) as D7R,
ROUND (SUM (CASE WHEN cohort_age = 14 THEN cohort_size ELSE 0 END) / SUM (CASE WHEN cohort_Age = 0 THEN cohort_size ELSE 0 END), 2 ) as D14R
FROM cohort
GROUP BY 1
ORDER BY 1;
