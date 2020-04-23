defmodule BattleBoxClient.Games.RobotGame.ShelterInPlace do
  import BattleBoxClient.Games.RobotGame

  def make_commands(%{"my_robots" => my_robots}, _game_info) do
    for robot <- my_robots do
      guard(robot)
    end
  end
end
