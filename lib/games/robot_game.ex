defmodule BattleBoxClient.Games.RobotGame do
  def center_point(board) do
  end

  def toward(current_location, destination) do
  end

  @doc ~S"""
  Calculates the distance between two points as the crow flies.

  iex> BattleBoxClient.Games.RobotGame.distance([0, 0], [0, 0])
  0.0

  iex> BattleBoxClient.Games.RobotGame.distance([0, 0], [0, 1])
  1.0

  iex> BattleBoxClient.Games.RobotGame.distance([0, 0], [0, -1])
  1.0

  iex> BattleBoxClient.Games.RobotGame.distance([0, 0], [3, 4])
  5.0
  """
  def distance([x1, y1], [x2, y2]) do
    a_squared = :math.pow(x2 - x1, 2)
    b_squared = :math.pow(y2 - y1, 2)
    :math.pow(a_squared + b_squared, 0.5)
  end

  @doc ~S"""
  Calculates the walking distance between two points.

  iex> BattleBoxClient.Games.RobotGame.walking_distance([0, 0], [0, 0])
  0

  iex> BattleBoxClient.Games.RobotGame.walking_distance([0, 0], [0, 1])
  1

  iex> BattleBoxClient.Games.RobotGame.walking_distance([0, 0], [0, -1])
  1

  iex> BattleBoxClient.Games.RobotGame.walking_distance([0, 0], [1, 1])
  2
  """
  def walking_distance([x1, y1], [x2, y2]) do
    abs(x2 - x1) + abs(y2 - y1)
  end
end
