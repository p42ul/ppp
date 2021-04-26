module Config exposing (config)


config =
    { sendServerAddress = "ws://minty:8080/send"
    , listenServerAddress = "ws://minty:8080/listen"
    , motionScaleFactor = 1 / 20
    }
