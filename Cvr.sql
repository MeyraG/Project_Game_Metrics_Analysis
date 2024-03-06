-- D1, D3, D7 ve D14 ROAS
WITH cohort AS (
  SELECT
    p.install_date,
    COUNT(DISTINCT p.user_id) AS cohort_size,
    DATE_DIFF(se.event_date, p.install_date, DAY) AS days_since_install,
    SUM(a.user_spent * 0.7 * 0.8) AS net_revenue
  FROM  game-analysis-01.project_game.user_daily_activities a
    LEFT JOIN project_game.players p ON a.user_id = p.user_id
    INNER JOIN game-analysis-01.project_game.stage_events se ON se.user_id = CAST(p.user_id AS INT64)
  GROUP BY 1, 3
),
--Paid userlar ( paid ve xPromo dahil)
install_calc AS (
  SELECT install_date,
         SUM(CASE WHEN user_ua_type != 'Organic' THEN 1 ELSE 0 END) AS paid_users
    FROM  project_game.players
    GROUP BY install_date
),
cpi_table AS (
  SELECT
    ic.install_date,
    ic.paid_users,
    SUM(s.spend) / COALESCE(nullif(ic.paid_users,0), 1) AS cpi
   FROM  install_calc ic
   LEFT JOIN game-analysis-01.project_game.ua_spends s
   ON ic.install_date = s.date
   GROUP BY ic.install_date, ic.paid_users
),
 ltv_cpi_roas AS (
  SELECT
    c.install_date,
    SUM(CASE WHEN c.days_since_install <= 1 THEN c.net_revenue ELSE 0 END) / MAX(c.cohort_size) AS day1_ltv,
    SUM(CASE WHEN c.days_since_install <= 3 THEN c.net_revenue ELSE 0 END) / MAX(c.cohort_size) AS day3_ltv,
    SUM(CASE WHEN c.days_since_install <= 7 THEN c.net_revenue ELSE 0 END) / MAX(c.cohort_size) AS day7_ltv,
    SUM(CASE WHEN c.days_since_install <= 14 THEN c.net_revenue ELSE 0 END) / MAX(c.cohort_size) AS day14_ltv,
    cp.cpi
  FROM cohort c
  JOIN cpi_table cp ON c.install_date = cp.install_date
  GROUP BY c.install_date, cp.cpi
)
-- ROAS
SELECT
  install_date,
  day1_ltv / COALESCE(nullif(cpi,0), 1) AS day1_roas,
  day3_ltv / COALESCE(nullif(cpi,0), 1) AS day3_roas,
  day7_ltv / COALESCE(nullif(cpi,0), 1) AS day7_roas,
  day14_ltv / COALESCE(nullif(cpi,0), 1) AS day14_roas
FROM ltv_cpi_roas
ORDER BY install_date;
