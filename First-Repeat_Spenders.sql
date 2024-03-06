--First-Repeat Spender
WITH user_activities AS (
    SELECT
        uda.date,
        p.user_id,
        purchases,
        ROW_NUMBER() OVER(PARTITION BY p.user_id ORDER BY uda.date) AS row_n
    FROM project_game.players p
    JOIN project_game.user_daily_activities uda ON uda.user_id = p.user_id
    WHERE uda.time_spent_seconds > 0
),
spending_status AS (
    SELECT
        date,
        user_id,
        CASE WHEN purchases > 0 AND row_n = 1 THEN 1 ELSE 0 END AS first_spender,
        CASE WHEN purchases > 0 AND row_n > 1 THEN 1 ELSE 0 END AS repeat_spender,
        CASE WHEN purchases = 0 THEN 1 ELSE 0 END AS non_spender
    FROM user_activities
),
aggregated_counts AS (
    SELECT
        date,
        COUNT(DISTINCT user_id) AS dau,
        SUM(first_spender) AS first_time_spenders,
        SUM(repeat_spender) AS repeat_spenders,
        SUM(non_spender) AS non_spenders
    FROM spending_status
    GROUP BY date
)
SELECT
    date,
    dau,
    first_time_spenders,
    repeat_spenders,
    non_spenders
FROM aggregated_counts
ORDER BY date;