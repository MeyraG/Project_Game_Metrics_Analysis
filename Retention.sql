--ARPU
SELECT
  d.date,
  p.country_code_first,
  ROUND(SUM(d.ad_Revenue + d.user_spent) / COUNT(DISTINCT p.user_id), 2) AS arpu
FROM
  game-analysis-01.project_game.players p
INNER JOIN
  game-analysis-01.project_game.user_daily_activities d ON p.user_id = d.user_id
WHERE
  p.country_code_first IN ('US','PH')
GROUP BY 1, 2
ORDER BY 1, 2;