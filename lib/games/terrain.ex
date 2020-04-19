defmodule BattleBoxClient.Games.RobotGame.Terrain do
  @doc ~S"""
  Returns the dimensions of the terrain

  iex> BattleBoxClient.Games.RobotGame.Terrain.dimensions(<<0, 0>>)
  %{rows: 0, cols: 0}

  iex> BattleBoxClient.Games.RobotGame.Terrain.dimensions(<<1, 1, 1>>)
  %{rows: 1, cols: 1}

  iex> BattleBoxClient.Games.RobotGame.Terrain.dimensions(<<100, 100, "whatever">>)
  %{rows: 100, cols: 100}
  """
  def dimensions(<<rows::8, cols::8, _terrain_data::binary>>) do
    %{rows: rows, cols: cols}
  end

  @doc ~S"""
  Returns the value for a location on a terrain, is :inaccesible if that position
  does not exist on the board

  iex> BattleBoxClient.Games.RobotGame.Terrain.at_location(<<0, 0>>, [42, 42])
  :inaccessible

  iex> BattleBoxClient.Games.RobotGame.Terrain.at_location(<<1, 1, 0>>, [0, 0])
  :inaccessible

  iex> BattleBoxClient.Games.RobotGame.Terrain.at_location(<<1, 1, 1>>, [0, 0])
  :normal

  iex> BattleBoxClient.Games.RobotGame.Terrain.at_location(<<1, 2, 0, 1>>, [0, 1])
  :normal

  iex> BattleBoxClient.Games.RobotGame.Terrain.at_location(<<2, 1, 0, 1>>, [1, 0])
  :normal
  """
  def at_location(<<rows::8, cols::8, terrain_data::binary>>, [row, col]) do
    on_board? = row >= 0 && col >= 0 && row <= rows - 1 && col <= cols - 1

    if on_board? do
      offset = row * cols + col

      case :binary.at(terrain_data, offset) do
        0 -> :inaccessible
        1 -> :normal
        2 -> :spawn
        3 -> :obstacle
      end
    else
      :inaccessible
    end
  end
end
