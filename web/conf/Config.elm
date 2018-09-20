module Config exposing (config)


config =
    { sendServerAddress = "wss://plexusplay.app:8080/send"
    , listenServerAddress = "wss://plexusplay.app:8080/listen"
    , motionScaleFactor = 1 / 20
    }
