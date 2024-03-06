--Cheaterların belirlenmesi

--BigQuery üzerinden vw_meyra_main viewı oluşturdum:

WITH currency_table AS (
  SELECT DISTINCT
    cc.user_id,
    MAX(current_gem) AS max_gem,
    MAX(current_gold) AS max_gold,
    SUM(CASE WHEN change_type = 'Gain' AND currency_type = 'Gold' THEN SAFE_CAST(cc.currency_change_amount AS FLOAT64) ELSE 0 END) AS gold_gain,
    SUM(CASE WHEN change_type = 'Spend' AND currency_type = 'Gold' THEN SAFE_CAST(cc.currency_change_amount AS FLOAT64) ELSE 0 END) AS gold_spend,
    SUM(CASE WHEN change_type = 'Gain' AND currency_type = 'Gem' THEN SAFE_CAST(cc.currency_change_amount AS FLOAT64) ELSE 0 END) AS gem_gain,
    SUM(CASE WHEN change_type = 'Spend' AND currency_type = 'Gem' THEN SAFE_CAST(cc.currency_change_amount AS FLOAT64) ELSE 0 END) AS gem_spend
  FROM game-analysis-01.project_game.user_states us
  LEFT JOIN game-analysis-01.project_game.currency_changes cc ON us.user_id = CAST(cc.user_id AS INT64)
  GROUP BY cc.user_id
),
stage_metrics AS (
  SELECT DISTINCT  user_id,
  event_date,
    stage_index,
    (SAFE_CAST(stage_attempt AS INT64)) AS stage_attempt,
    (SAFE_CAST(stage_health AS FLOAT64)) AS stage_health,
    (SAFE_CAST(stage_taken_damage AS FLOAT64)) AS stage_taken_damage
  FROM game-analysis-01.project_game.stage_events
),

--Kullanıcının satınalma ve reklam gelirlerinin incelemesi
purchase_and_revenue AS (
  SELECT
  DISTINCT p.user_id,
    sm.event_date,
    a.date as dates,
    sm.stage_index,
    sm.stage_attempt,
    ct.max_gem,
    ct.max_gold,
    ct.gold_gain,
    ct.gold_spend,
    ct.gem_gain,
    ct.gem_spend,
    sm.stage_health,
    sm.stage_taken_damage,
    us.is_cheater_from_client,
    a.purchases,
    a.ad_revenue,
    DATE_DIFF(us.event_date, p.install_date, DAY) AS days_since_install
  FROM game-analysis-01.project_game.players p
  INNER JOIN game-analysis-01.project_game.user_daily_activities a ON a.user_id = p.user_id
  INNER JOIN currency_table ct ON a.user_id = ct.user_id
  INNER JOIN stage_metrics sm ON CAST(a.user_id AS INT64) = sm.user_id
  INNER JOIN game-analysis-01.project_game.user_states us ON us.user_id = CAST(a.user_id AS INT64) and us.event_date = sm.event_date
),
cheater_detect AS (
SELECT
  DISTINCT pr.user_id,
  pr.dates,
  pr.stage_index,
  pr.stage_attempt,
  pr.max_gem,
  pr.max_gold,
  pr.gold_gain,
  pr.gold_spend,
  pr.gem_gain,
  pr.gem_spend,
  pr.stage_health,
  pr.stage_taken_damage,
  pr.days_since_install,
  is_cheater_from_client,

  -- Hileci olup olmadığına dair şüpheli durumların belirlenmesi
 CASE
  WHEN
    (
      -- Altın veya gem kazanımı anormal yüksekse ve hiç satın alma veya reklam geliri yoksa
(pr.gold_gain > 99999999 OR pr.gem_gain > 9999999)
      AND pr.purchases = 0
      AND pr.ad_revenue < 19)
    OR
    (
      -- Harcanan altın veya gem, kazanılandan belirgin şekilde yüksekse
      (pr.gold_spend > pr.gold_gain + 99 OR pr.gem_spend > pr.gem_gain + 9)
    )
    OR
    (
      -- İlk günlerdeki maksimum gem veya altın miktarı anormal yüksekse
(SAFE_CAST(pr.max_gem AS FLOAT64) > 99999999 OR SAFE_CAST(pr.max_gold AS FLOAT64) > 99999999999)
   AND (days_since_install IN (0,1,2))
    )
  THEN 1
  ELSE 0
END AS suspicious_currency_gain,

CASE
  WHEN
    (
      -- Zor stagelerde, az denemede ve düşük hasar alarak ilerlediyse
      CAST(pr.stage_index AS INT64) IN (2,14,15,16,17,18,19,21)
      AND pr.stage_attempt < 3
      AND pr.stage_taken_damage < 999999999
    )
  THEN 1
  ELSE 0
END AS suspicious_stage_performance

FROM purchase_and_revenue pr
),

--Bir user'ın cheater olma olasılığının hesaplanması
 final_cheater AS (
  SELECT
  DISTINCT user_id,
  cheater_detect.dates,
  stage_index,
  stage_attempt,
  days_since_install,
  is_cheater_from_client,
CASE WHEN (suspicious_currency_gain = 1 AND
          suspicious_stage_performance = 1)
THEN 'highly_probable_cheaters'
          WHEN  (suspicious_currency_gain = 0 AND
          suspicious_stage_performance = 0)
THEN 'low_pro_cheaters'
ELSE 'medium_probable_cheaters'
END AS cheater_posibility
FROM cheater_detect)

SELECT * FROM final_cheater




--1.a DAU içindeki cheater oranı:

--Dau hesaplaması
WITH dau_table AS (
  SELECT
    a.date,
    COUNT(DISTINCT p.user_id) AS daily_active_users
  FROM `project_game.players` p LEFT JOIN game-analysis-01.project_game.user_daily_activities a
  ON p.useR_id = a.user_id
  WHERE time_spent_seconds > 0
  GROUP BY a.date
),
--Meyra_main view'ındaki kurguya göre belirlediğimiz cheaterların toplam sayısı
cheater_counts AS (
  SELECT
    dates,
    COUNT(DISTINCT user_id) AS cheater_count
  FROM  `game-analysis-01.project_game.vw_meyra_main`
  WHERE cheater_posibility
IN ('highly_probable_cheaters', 'medium_probable_cheaters')
  GROUP BY dates
),
--Dau içindeki cheater oranı
cheater_ratio AS (
  SELECT
    d.date,
    cheater_count,
    d.daily_active_users,
    ROUND(cheater_count / CAST(d.daily_active_users AS INT64),2) AS cheater_ratio
  FROM dau_table d
  INNER JOIN cheater_counts c ON d.date = c.dates
)
SELECT * FROM cheater_ratio





--1.b Oyun içi hile tespit sistemi ile karşılaştırması için:

    SELECT DISTINCT user_id,
    cheater_posibility, is_cheater_from_client
    FROM  `game-analysis-01.project_game.vw_meyra_main`;