--Veriden kendim çıkardığım soru ve cevabı
--Her bir ülke için yapılan toplam reklam harcamaları, ortalama oyuncu başına elde edilen  IAP ve (ad revenue) miktarları nedir?
--Bu değerlere dayanarak, ülke bazında ortalama kullanıcı başına karlılık oranı hesaplaması:

WITH user_revenue AS (
  SELECT
    p.user_id,
    p.country_name_first AS country,
    uda.date,
    SUM(uda.user_spent) AS user_iap_revenue,
    SUM(uda.ad_Revenue) AS user_ad_revenue
  FROM
    `game-analysis-01.project_game.user_daily_activities` uda
  JOIN
    `game-analysis-01.project_game.players` p ON uda.user_id = p.user_id
  GROUP BY
    p.user_id, country, uda.date
),
country_ad_spend AS (
  SELECT
    country_name,
    SUM(spend) AS total_ad_spend
  FROM
    `game-analysis-01.project_game.ua_spends`
  GROUP BY
    country_name
),
country_revenue AS (
  SELECT
    country,
    date,
    AVG(user_iap_revenue + user_ad_revenue) AS avg_revenue_per_user,
    SUM(user_iap_revenue + user_ad_revenue) AS total_revenue,
    COUNT(user_id) AS user_count
  FROM
    user_revenue
  GROUP BY
    country, date
)

SELECT
  cr.date,
  cr.country,
  cr.user_count,
  cr.total_revenue,
  cr.avg_revenue_per_user,
  cas.total_ad_spend,
  cas.total_ad_spend / cr.user_count AS avg_ad_spend_per_user,
  cr.avg_revenue_per_user - (cas.total_ad_spend / cr.user_count) AS avg_profit_per_user
FROM
  country_revenue cr
LEFT JOIN
  country_ad_spend cas ON cr.country = cas.country_name
   WHERE (total_ad_spend > 0 AND cr.total_revenue > 0)
ORDER BY
  cr.date, avg_profit_per_user DESC;