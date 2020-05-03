defmodule BattleBoxClient.Games.RobotGame do
  def initialize_game_info(game_info) do
    decoded_terrain = Base.decode64!(game_info["settings"]["terrain_base64"])
    put_in(game_info["settings"]["terrain"], decoded_terrain)
  end

  def initialize_game_state(%{"robots" => robots} = game_state, %{"player" => player}) do
    my_robots = for robot <- robots, robot["player_id"] == player, do: robot
    enemies = for robot <- robots, robot["player_id"] != player, do: robot

    Map.merge(game_state, %{
      "my_robots" => my_robots,
      "enemies" => enemies
    })
  end

  def guard(%{"id" => robot_id}), do: %{"type" => "guard", "robot_id" => robot_id}
  def suicide(%{"id" => robot_id}), do: %{"type" => "suicide", "robot_id" => robot_id}

  def move(%{"id" => robot_id}, target),
    do: %{"type" => "move", "target" => target, "robot_id" => robot_id}

  def attack(%{"id" => robot_id}, target), do: attack(robot_id, target)
  def attack(robot_id, %{"location" => target}), do: attack(robot_id, target)

  def attack(robot_id, target),
    do: %{"type" => "attack", "target" => target, "robot_id" => robot_id}

  @doc ~S"""
  Calculates the Adjacent locations to a position/robot

  iex> BattleBoxClient.Games.RobotGame.adjacent_locations([1, 1])
  [[1, 2], [1, 0], [2, 1], [0, 1]]
  """
  def adjacent_locations(%{"location" => location}), do: adjacent_locations(location)

  def adjacent_locations([x, y]) do
    [[x, y + 1], [x, y - 1], [x + 1, y], [x - 1, y]]
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
  def distance(%{"location" => location}, other), do: distance(location, other)
  def distance(other, %{"location" => location}), do: distance(other, location)

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

  @doc ~S"""
  Calculates the next step towards a location/robot

  iex> BattleBoxClient.Games.RobotGame.towards([0, 0], [0, 1])
  [0, 1]

  iex> BattleBoxClient.Games.RobotGame.towards([0, 0], [0, 2])
  [0, 1]

  iex> BattleBoxClient.Games.RobotGame.towards([0, 0], [1, 0])
  [1, 0]

  iex> BattleBoxClient.Games.RobotGame.towards([0, 0], [2, 0])
  [1, 0]
  """
  def towards(%{"location" => location}, other), do: towards(location, other)
  def towards(other, %{"location" => location}), do: towards(other, location)

  def towards([x1, y1] = _robot_loc, [x2, y2] = _target) do
    cond do
      x1 > x2 ->
        [x1 - 1, y1]

      x1 < x2 ->
        [x1 + 1, y1]

      y1 > y2 ->
        [x1, y1 - 1]

      y1 < y2 ->
        [x1, y1 + 1]
    end
  end
end
