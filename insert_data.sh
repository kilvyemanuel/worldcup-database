#! /bin/bash

if [[ $1 == "test" ]]
then
  PSQL="psql --username=postgres --dbname=worldcuptest -t --no-align -c"
else
  PSQL="psql --username=freecodecamp --dbname=worldcup -t --no-align -c"
fi

# Do not change code above this line. Use the PSQL variable above to query your database.

game_values=""
while IFS=, read -r year round winner opponent winner_goals opponent_goals
do
  [[ -n "$year" && "$year" != "year" ]] || continue
  game_values+="($year, '$round', '$winner', '$opponent', $winner_goals, $opponent_goals),"
done < games.csv
game_values=${game_values%,}

$PSQL "
BEGIN;
INSERT INTO teams (name)
SELECT team_name
FROM (
  SELECT winner AS team_name
  FROM (VALUES $game_values) AS game_data(year, round, winner, opponent, winner_goals, opponent_goals)
  UNION
  SELECT opponent AS team_name
  FROM (VALUES $game_values) AS game_data(year, round, winner, opponent, winner_goals, opponent_goals)
) AS unique_teams
WHERE true
ON CONFLICT (name) DO NOTHING;

INSERT INTO games (year, round, winner_id, opponent_id, winner_goals, opponent_goals)
SELECT game_data.year, game_data.round, winner.team_id, opponent.team_id,
       game_data.winner_goals, game_data.opponent_goals
FROM (VALUES $game_values) AS game_data(year, round, winner, opponent, winner_goals, opponent_goals)
JOIN teams AS winner ON winner.name = game_data.winner
JOIN teams AS opponent ON opponent.name = game_data.opponent;
COMMIT;
" > /dev/null
