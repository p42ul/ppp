module Main exposing (..)

import Html exposing (..)
import Html.Attributes as HtmlAttrs exposing (..)
import Html.Events exposing (onInput)
import WebSocket


backendServerAddress : String
backendServerAddress =
    "ws://localhost/send"


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
    ( Model 0 "", Cmd.none )



-- MODEL


type alias Model =
    { sliderValue : Int
    , lastMessage : String
    }



-- UPDATE


type Msg
    = ChangeSlider String
    | ReceiveMessage String


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        ChangeSlider newValue ->
            let
                newModel =
                    { model | sliderValue = Result.withDefault 0 (String.toInt newValue) }
            in
                ( newModel, WebSocket.send backendServerAddress newValue )

        ReceiveMessage message ->
            let
                newModel =
                    { model | lastMessage = message }
            in
                ( newModel, Cmd.none )



-- VIEW


view : Model -> Html Msg
view model =
    div []
        [ input
            [ type_ "range"
            , HtmlAttrs.min "0"
            , HtmlAttrs.max "127"
            , value <| toString model.sliderValue
            , onInput ChangeSlider
            ]
            []
        , text <| toString model
        ]



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions model =
    WebSocket.keepAlive backendServerAddress
