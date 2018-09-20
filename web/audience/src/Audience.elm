module Audience exposing (..)

import Config exposing (config)
import Color
import Color.Colormaps
import Device.Motion exposing (Acceleration, Motion, changes)
import Html exposing (..)
import Html.Attributes exposing (style)
import WebSocket


-- CONFIGURATION
-- Configuration is injected at build time via Docker.


{-| A <ws://> or <wss://> address that our audience app sends data to.
-}
backendServerAddress : String
backendServerAddress =
    config.backendServerAddress


{-| An amount to scale the device motion by.
Greater values will require less motion to "max out" the colormap.
Smaller value will require more motion to register.
-}
motionScaleFactor : Float
motionScaleFactor =
    config.motionScaleFactor


main : Program Never Model Msg
main =
    Html.program
        { init = init
        , view = view
        , update = update
        , subscriptions = subscriptions
        }


init : ( Model, Cmd Msg )
init =
    ( Model Color.lightBlue, Cmd.none )



-- MODEL


type alias Model =
    { backgroundColor : Color.Color
    }



-- UPDATE


type Msg
    = MovePhone Motion


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        MovePhone motion ->
            let
                magnitude =
                    accelerationToMagnitude motion.acceleration

                midi =
                    magnitudeToMidi magnitude
            in
                ( { model | backgroundColor = Color.Colormaps.plasma magnitude }, WebSocket.send backendServerAddress (toString midi) )


accelerationToMagnitude : Acceleration -> Float
accelerationToMagnitude { x, y, z } =
    (abs x + abs y + abs z / 3) * motionScaleFactor


magnitudeToMidi : Float -> Int
magnitudeToMidi f =
    clamp 0 127 (floor (127 * f))



-- VIEW


colorToRgbString : Color.Color -> String
colorToRgbString c =
    let
        { red, green, blue, alpha } =
            Color.toRgb c
    in
        "rgb(" ++ toString red ++ ", " ++ toString green ++ ", " ++ toString blue ++ ")"


view : Model -> Html Msg
view model =
    div
        [ style
            [ ( "backgroundColor", colorToRgbString model.backgroundColor )
            , ( "height", "100vh" )
            , ( "width", "100vw" )
            ]
        ]
        [ text <| toString model
        ]



-- SUBSCRIPTIONS


handleMotion : Motion -> Msg
handleMotion motion =
    MovePhone motion


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.batch
        [ WebSocket.keepAlive backendServerAddress
        , changes handleMotion
        ]
