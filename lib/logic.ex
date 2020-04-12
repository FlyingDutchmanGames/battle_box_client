defmodule BattleBoxClient.Logic do
  def make_commands(robots, player) do
    robots
    |> Enum.filter(fn robot -> robot["player_id"] == player end)
    |> Enum.map(fn robot ->
      [x, y] = robot["location"]

      target =
        cond do
          y > 9 ->
            [x, y - 1]

          y < 9 ->
            [x, y + 1]

          x < 9 ->
            [x + 1, y]

          x > 9 ->
            [x - 1, y]

          true ->
            [x - 1, y]
        end

      %{
        "target" => target,
        "robot_id" => robot["id"],
        "type" => "move"
      }
    end)
  end
end
