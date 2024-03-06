--Day5'te hala oynayan bir oyuncunun hangi stagede olması en olası:

 WITH stage_table AS (
    SELECT p.user_id,
    se.event_Date,
    se.stage_index,
    se.stage_level,
    se.stage_attempt,
    DATE_DIFF(event_date, install_date, DAY) AS days_since_install
      FROM game-analysis-01.project_game.stage_events se INNER JOIN `project_game.players` p
      ON se.user_id = CAST(p.user_id AS INT64)
      WHERE   DATE_DIFF(event_date, install_date, DAY) = 5 )

     SELECT stage_index,
            COUNT(DISTINCT stage_table.user_id) as dau_count
FROM stage_table
            WHERE stage_index IS NOT NULL
            GROUP BY 1
ORDER BY dau_count DESC;



-- 15. Attempt'te kullanıcının hangi stagede olması muhtemel:
WITH cum_attempts_table AS (
  SELECT
    user_id,
    stage_index,
    SUM(CAST(stage_attempt AS INT64)) OVER(PARTITION BY user_id ORDER BY stage_index) AS cumulative_attempts
  FROM project_game.stage_events
),
 at15th_Attempt AS (
  SELECT
    user_id,
    stage_index,
    ROW_NUMBER() OVER(PARTITION BY user_id ORDER BY stage_index) AS attempt_no
  FROM cum_attempts_table
  WHERE cumulative_attempts >= 15
)

SELECT
  stage_index,
  COUNT(*) AS user_count
FROM  at15th_Attempt
WHERE attempt_no = 15
GROUP BY stage_index
ORDER BY user_count DESC;