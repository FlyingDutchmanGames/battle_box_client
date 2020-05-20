defmodule BattleBoxClient do
  alias BattleBoxClient.{BotSupervisor, BotServer}

  def start_bot(token, bot, lobby, logic, battle_box_server \\ "battleboxs://app.botskrieg.com:4242") do
    %URI{host: host, port: port, scheme: scheme} = URI.parse(battle_box_server)

    transport =
      case scheme do
        "battleboxs" -> :ssl
        "battlebox" -> :gen_tcp
      end

    DynamicSupervisor.start_child(
      BotSupervisor,
      {BotServer,
       %{
         token: token,
         bot: bot,
         lobby: lobby,
         host: host,
         port: port,
         logic: logic,
         transport: transport
       }}
    )
  end
end
