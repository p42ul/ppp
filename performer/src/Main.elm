module Main exposing (..)

import Html exposing (..)
import WebSocket


backendServerAddress : String
backendServerAddress =
    "ws://localhost/listen"


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
    ( Model []
    , Cmd.none
    )



-- MODEL


type alias Model =
    { receivedMessages : List String
    }



-- UPDATE


type Msg
    = ReceiveMessage String


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        ReceiveMessage message ->
            let
                newModel =
                    { model | receivedMessages = message :: model.receivedMessages }
            in
                ( newModel, Cmd.none )



-- VIEW


view : Model -> Html Msg
view model =
    div []
        [ text (toString model) ]



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions model =
    WebSocket.listen backendServerAddress ReceiveMessage
