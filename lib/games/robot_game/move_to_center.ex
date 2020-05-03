defmodule BattleBoxClient.Games.RobotGame.MoveToCenter do
  import BattleBoxClient.Games.{RobotGame, RobotGame.Terrain}

  def make_commands(%{"my_robots" => my_robots}, %{"settings" => %{"terrain" => terrain}}) do
    %{rows: rows, cols: cols} = dimensions(terrain)
    row_midpoint = Integer.floor_div(rows, 2)
    col_midpoint = Integer.floor_div(cols, 2)

    for %{"location" => [row, col]} = robot <- my_robots do
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

      move(robot, target)
    end
  end
end
