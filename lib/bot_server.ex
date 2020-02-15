defmodule BattleBoxClient.BotServer do
  require Logger
  use GenStateMachine, callback_mode: [:handle_event_function], restart: :temporary

  def start_link(%{token: _, lobby: _, domain: _, port: _} = data) do
    GenStateMachine.start_link(__MODULE__, data)
  end

  def init(%{domain: domain, port: port} = data) do
    {:ok, socket} =
      :gen_tcp.connect(domain, port, [:binary, active: :once, packet: :line, recbuf: 65536])

    data = Map.put(data, :socket, socket)
    {:ok, :connecting, data}
  end

  def handle_event(:info, {:tcp_closed, _socket}, state, _data) do
    Logger.info("TCP CONNECTION CLOSED state:#{state}")
    {:stop, :normal}
  end

  def handle_event(:info, {:tcp_error, _socket, _reason}, state, _data) do
    Logger.info("TCP CONNECTION ERROR state:#{state}")
    {:stop, :normal}
  end

  def handle_event(:info, {:tcp, socket, bytes}, _state, %{socket: socket}) do
    :ok = :inet.setopts(socket, active: :once)

    case Jason.decode(bytes) do
      {:ok, msg} ->
        {:keep_state_and_data, {:next_event, :internal, msg}}

      {:error, %Jason.DecodeError{}} ->
        Logger.warn("Invalid Message Sent by Server, #{bytes}")
        :keep_state_and_data
    end
  end

  def handle_event(:internal, %{"connection_id" => connection_id}, :connecting, data) do
    Logger.info("client connected with connection_id:#{connection_id}")

    :ok = :gen_tcp.send(data.socket, encode(%{"token" => data.token, "lobby" => data.lobby}))
    data = Map.put(data, :connection_id, connection_id)

    {:next_state, :authing, data}
  end

  def handle_event(:internal, %{"bot_id" => bot_id, "status" => status}, _, data)
      when status in ["idle", "match_making"] do
    Logger.info("bot in lobby:#{data.lobby}, bot_id:#{bot_id}, status:#{status}")

    case status do
      "idle" ->
        :ok = :gen_tcp.send(data.socket, encode(%{"action" => "start_match_making"}))
        {:next_state, :match_making, data}

      "match_making" ->
        :keep_state_and_data
    end
  end

  def handle_event(
        :internal,
        %{
          "request_type" => "game_request",
          "game_info" => %{"game_id" => game_id, "player" => player}
        },
        :match_making,
        data
      ) do
    Logger.info("got game request for game_id:#{game_id}")
    :ok = :gen_tcp.send(data.socket, encode(%{"action" => "accept_game", "game_id" => game_id}))
    data = Map.merge(data, %{game_info: %{player: player, game_id: game_id}})
    {:next_state, :playing, data}
  end

  def handle_event(
        :internal,
        %{
          "request_type" => "moves_request",
          "moves_request" => %{
            "request_id" => request_id,
            "game_id" => game_id,
            "game_state" => %{"robots" => _robots}
          }
        },
        :playing,
        %{game_info: %{game_id: game_id}} = data
      ) do
    Logger.info("Moves request for game_id:#{game_id}, request_id:#{request_id}")
    moves = []

    :ok =
      :gen_tcp.send(
        data.socket,
        encode(%{
          "action" => "send_moves",
          "request_id" => request_id,
          "moves" => moves
        })
      )

    :keep_state_and_data
  end

  def handle_event(
        :internal,
        %{"info" => "game_over", "result" => %{"game_id" => game_id, "winner" => winner}},
        :playing,
        %{game_info: %{game_id: game_id}} = data
      ) do
    Logger.info("Game over game_id:#{game_id} winner:#{winner}")
    :ok = :gen_tcp.send(data.socket, encode(%{"action" => "start_match_making"}))
    data = Map.drop(data, [:game_info])
    {:next_state, :match_making, data}
  end

  def handle_event(:internal, %{"error" => "bot_instance_failure"}, state, data) do
    Logger.error("Bot instance failure in state:#{state} connection_id:#{data.connection_id}")
    {:stop, :normal}
  end

  defp encode(msg) do
    Jason.encode!(msg) <> "\n"
  end
end

# {:ok, pid1} = BattleBoxClient.BotServer.start_link(%{token:  "791c66d2cfdca9b45ca230a41098ce1ef342fcc3d57282275be121bac8111c51", lobby: "foo", domain: 'localhost', port: 4001})
# {:ok, pid2} = BattleBoxClient.BotServer.start_link(%{token:  "791c66d2cfdca9b45ca230a41098ce1ef342fcc3d57282275be121bac8111c51", lobby: "foo", domain: 'localhost', port: 4001})
