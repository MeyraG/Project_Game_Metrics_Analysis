--Daily New User
 SELECT install_date,
        COUNT(user_id) as dnu
  FROM `game-analysis-01.project_game.players`
  GROUP BY 1
  ORDER BY 1;