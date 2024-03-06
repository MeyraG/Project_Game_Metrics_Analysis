
--2.4 - Conversion Rate
SELECT install_date, 
    COUNT(DISTINCT  p.user_id) AS cohort_size,
    DATE_DIFF(event_date, install_date, DAY) AS days_since_install,
    COUNT(DISTINCT 
CASE WHEN user_spent > 0 
THEN p.user_id END) AS paying_users,
    COUNT(DISTINCT 
CASE WHEN user_spent > 0 AND 
DATE_DIFF(event_date, install_date, DAY) = 0 THEN p.user_id END) * 1.0 /  COUNT(DISTINCT  p.user_id) AS D0_cvr,
      COUNT(DISTINCT 
CASE WHEN user_spent > 0 AND DATE_DIFF(event_date, install_date, DAY) = 1 
THEN p.user_id END) * 1.0 / COUNT(DISTINCT  p.user_id) AS D1_cvr
FROM `project_game.players` p 
INNER JOIN   game-analysis-01.project_game.user_daily_activities a 
USING(user_id) 
INNER JOIN `game-analysis-01.project_game.stage_events` gse
ON gse.user_id = CAST(p.user_id AS INT64)
WHERE  
DATE_DIFF(event_date, install_date, DAY) IN (0, 1) 
GROUP BY install_date, days_since_install
ORDER BY install_date, days_since_install;
