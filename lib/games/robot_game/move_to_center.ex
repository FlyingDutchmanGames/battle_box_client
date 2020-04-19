defmodule BattleBoxClient.Games.RobotGame.MoveToCenter do
  alias BattleBoxClient.Games.RobotGame.Terrain

  def make_commands(%{"robots" => robots}, %{"player" => player} = game_info) do
    %{rows: rows, cols: cols} = Terrain.dimensions(game_info["settings"]["terrain"])
    row_midpoint = Integer.floor_div(rows, 2)
    col_midpoint = Integer.floor_div(cols, 2)

    robots
    |> Enum.filter(fn robot -> robot["player_id"] == player end)
    |> Enum.map(fn robot ->
      [row, col] = robot["location"]

      target =
        cond do
          col > col_midpoint ->
            [row, col - 1]

          col < col_midpoint ->
            [row, col + 1]

          row < row_midpoint ->
            [row + 1, col]

          row > row_midpoint ->
            [row - 1, col]

          true ->
            [row - 1, col]
        end

      %{
        "target" => target,
        "robot_id" => robot["id"],
        "type" => "move"
      }
    end)
  end
end
