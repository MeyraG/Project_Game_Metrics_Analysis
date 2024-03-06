--Daily ad spends
SELECT date, 
       ROUND(SUM(spend),2) AS ad_spend
FROM `game-analysis-01.project_game.ua_spends` 
GROUP BY 1 
ORDER BY 1
