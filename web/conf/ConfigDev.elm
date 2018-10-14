module Config exposing (config)


config =
    { sendServerAddress = "ws://192.168.86.116:8080/send"
    , listenServerAddress = "ws://192.168.86.116:8080/listen"
    , motionScaleFactor = 1 / 20
    }
