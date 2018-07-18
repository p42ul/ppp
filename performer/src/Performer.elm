module Performer exposing (..)

import Html exposing (..)
import Html.Events exposing (..)
import WebMidi exposing (MidiPort)
import Array.Hamt as Array exposing (Array)


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
    ( Model [ "none so far" ]
    , Cmd.none
    )



-- MODEL


type alias Model =
    { receivedMessages : List String
    }



-- UPDATE


type Msg
    = ReceiveMessage String
    | GenError


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        ReceiveMessage message ->
            ( { model | receivedMessages = message :: model.receivedMessages }, Cmd.none )

        GenError ->
            ( model, WebMidi.sendMidi (Array.repeat 3 10) )



-- SUBSCRIPTIONS


onMidiAccess : ( List MidiPort, List MidiPort ) -> Msg
onMidiAccess data =
    ReceiveMessage ("midi access changed!" ++ toString data)


onRecvMidi : List Int -> Msg
onRecvMidi midi =
    ReceiveMessage ("midi values seen: " ++ toString midi)


onMidiError : ( String, String ) -> Msg
onMidiError ( name, message ) =
    ReceiveMessage ("midi error: name: " ++ name ++ " message: " ++ message)


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.batch
        [ WebMidi.midiAccess onMidiAccess
        , WebMidi.recvMidi onRecvMidi
        , WebMidi.midiError onMidiError
        ]



-- VIEW


view : Model -> Html Msg
view model =
    div []
        [ div [ onClick GenError ]
            [ text "This app attempts to print midi messages as they are received."
            , text "Click this message to generate a midi message."
            ]
        , div []
            [ text (toString model.receivedMessages)
            ]
        ]
