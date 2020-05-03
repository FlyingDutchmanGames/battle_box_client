defmodule BattleBoxClient.Games.RobotGame.SearchAndDestory do
  import BattleBoxClient.Games.RobotGame

  def make_commands(%{"my_robots" => my_robots, "enemies" => enemies}, _game_info) do
    for robot <- my_robots do
      adjacent_enemies =
        for enemy <- enemies, enemy["location"] in adjacent_locations(robot), do: enemy

      closest_enemy = Enum.min_by(enemies, fn enemy -> distance(robot, enemy) end, fn -> nil end)

      case %{adjacent_enemies: adjacent_enemies, closest_enemy: closest_enemy} do
        %{adjacent_enemies: [enemy | _]} ->
          attack(robot, enemy)

        %{closest_enemy: closest_enemy} when not is_nil(closest_enemy) ->
          move(robot, towards(robot, closest_enemy))

        _ ->
          guard(robot)
      end
    end
  end
end
