defmodule BattleBoxClient.BotServer do
  require Logger
  alias BattleBoxClient.Logic
  use GenStateMachine, callback_mode: [:handle_event_function], restart: :temporary

  # TODO warn when recieve buffer is exceeded
  @recieve_buffer_bytes 65536

  def start_link(%{token: _, lobby: _, domain: _, port: _} = data) do
    data = Map.put_new(data, :transport, :gen_tcp)
    GenStateMachine.start_link(__MODULE__, data)
  end

  def init(%{domain: domain, port: port} = data) do
    {:ok, socket} =
      data.transport.connect(domain, port, [
        :binary,
        active: true,
        packet: 2,
        recbuf: @recieve_buffer_bytes
      ])

    :ok = data.transport.send(socket, encode(%{"token" => data.token, "lobby" => data.lobby}))

    data = Map.put(data, :socket, socket)
    {:ok, :authing, data}
  end

  def handle_event(:info, {:tcp_closed, _socket}, state, _data) do
    Logger.info("TCP CONNECTION CLOSED state:#{state}")
    {:stop, :normal}
  end

  def handle_event(:info, {:tcp_error, _socket, _reason}, state, _data) do
    Logger.info("TCP CONNECTION ERROR state:#{state}")
    {:stop, :normal}
  end

  def handle_event(:info, {transport, socket, bytes}, _state, %{socket: socket})
      when transport in [:ssl, :tcp] do
    case Jason.decode(bytes) do
      {:ok, msg} ->
        {:keep_state_and_data, {:next_event, :internal, msg}}

      {:error, %Jason.DecodeError{}} ->
        Logger.warn("Invalid Message Sent by Server, #{bytes}")
        :keep_state_and_data
    end
  end

  def handle_event(
        :internal,
        %{"status" => status, "connection_id" => connection_id},
        _,
        data
      )
      when status in ["idle", "match_making"] do
    Logger.info(
      "bot in lobby:#{data.lobby}, status:#{status} and connection_id:#{
        connection_id
      }"
    )

    data = Map.put(data, :connection_id, connection_id)

    case status do
      "idle" ->
        Process.sleep(30000)
        :ok = data.transport.send(data.socket, encode(%{"action" => "start_match_making"}))
        {:next_state, :match_making, data}

      "match_making" ->
        {:keep_state, data}
    end
  end

  def handle_event(:internal, %{"error" => "invalid_msg_sent"}, _state, data) do
    Logger.warn("INVALID MSG SENT")
    :keep_state_and_data
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

    :ok =
      data.transport.send(data.socket, encode(%{"action" => "accept_game", "game_id" => game_id}))

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
            "game_state" => %{"robots" => robots}
          }
        },
        :playing,
        %{game_info: %{game_id: game_id}} = data
      ) do
    Logger.info("Moves request for game_id:#{game_id}, request_id:#{request_id}")

    moves = Logic.make_moves(robots, data.game_info.player)

    :ok =
      data.transport.send(
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
    :ok = data.transport.send(data.socket, encode(%{"action" => "start_match_making"}))
    data = Map.drop(data, [:game_info])
    {:next_state, :match_making, data}
  end

  def handle_event(
        :internal,
        %{"game_id" => game_id, "info" => "game_cancelled"},
        _,
        %{game_info: %{game_id: game_id}} = data
      ) do
    Logger.info("Game Cancelled game_id:#{game_id}")
    :ok = data.transport.send(data.socket, encode(%{"action" => "start_match_making"}))
    data = Map.drop(data, [:game_info])
    {:next_state, :match_making, data}
  end

  def handle_event(:internal, %{"error" => "bot_instance_failure"}, state, data) do
    Logger.error("Bot instance failure in state:#{state} connection_id:#{data.connection_id}")
    {:stop, :normal}
  end

  defp encode(msg) do
    Jason.encode!(msg)
  end
end

# {:ok, _pid} = BattleBoxClient.BotServer.start_link(%{token:  "791c66d2cfdca9b45ca230a41098ce1ef342fcc3d57282275be121bac8111c51", lobby: "foo", domain: 'localhost', port: 4001})
