module Performer exposing (..)

import Html exposing (..)
import Html.Events exposing (..)
import Html.Attributes
import WebMidi exposing (MidiPort)
import WebSocket
import Array.Hamt as Array exposing (Array)


-- CONFIGURATION


backendServerAddress =
    "ws://localhost:8080/listen"


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
    ( { receivedMessages = []
      , midiInputs = []
      , midiOutputs = []
      , midiIn = Nothing
      , midiOut = Nothing
      }
    , Cmd.none
    )



-- MODEL


type alias Model =
    { receivedMessages : List String
    , midiInputs : List MidiPort
    , midiOutputs : List MidiPort
    , midiIn : Maybe MidiPort
    , midiOut : Maybe MidiPort
    }



-- UPDATE


type Msg
    = ReceiveMessage String
    | ChangeMidiAccess ( List MidiPort, List MidiPort )
    | ChangeMidiOut String
    | ChangeMidiIn String
    | WebSocketMessage String


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        ReceiveMessage message ->
            ( { model | receivedMessages = message :: model.receivedMessages }, Cmd.none )

        ChangeMidiAccess ( inputs, outputs ) ->
            ( { model | midiInputs = inputs, midiOutputs = outputs }, Cmd.none )

        ChangeMidiOut id ->
            ( { model | midiOut = selectMidiPort model.midiOutputs id }, WebMidi.selectMidiOut (Just id) )

        ChangeMidiIn id ->
            ( { model | midiIn = selectMidiPort model.midiInputs id }, WebMidi.selectMidiIn (Just id) )

        WebSocketMessage wsmsg ->
            ( { model | receivedMessages = wsmsg :: model.receivedMessages }, WebMidi.sendMidi (Array.fromList [ 144, Result.withDefault 64 (String.toFloat wsmsg) |> truncate, 100 ]) )


selectMidiPort : List MidiPort -> String -> Maybe MidiPort
selectMidiPort midiPorts id =
    case midiPorts of
        [] ->
            Nothing

        x :: xs ->
            if x.id == id then
                Just x
            else
                selectMidiPort xs id



-- SUBSCRIPTIONS


onMidiAccess : ( List MidiPort, List MidiPort ) -> Msg
onMidiAccess data =
    ChangeMidiAccess data


onRecvMidi : List Int -> Msg
onRecvMidi midi =
    ReceiveMessage ("midi value seen: " ++ toString midi)


onMidiError : ( String, String ) -> Msg
onMidiError ( name, message ) =
    ReceiveMessage ("midi error: name: " ++ name ++ " message: " ++ message)


subscriptions : Model -> Sub Msg
subscriptions _ =
    Sub.batch
        [ WebMidi.midiAccess onMidiAccess
        , WebMidi.recvMidi onRecvMidi
        , WebMidi.midiError onMidiError
        , WebSocket.listen backendServerAddress WebSocketMessage
        ]



-- VIEW


makeSelectionOption : MidiPort -> Html msg
makeSelectionOption midiPort =
    option [ Html.Attributes.value midiPort.id ]
        [ text midiPort.name
        ]


midiPortName : Maybe MidiPort -> String
midiPortName maybeMidi =
    case maybeMidi of
        Nothing ->
            "None"

        Just midiPort ->
            midiPort.name


nullMidiOption : Html msg
nullMidiOption =
    option [ Html.Attributes.value "0" ]
        [ text "None" ]


view : Model -> Html Msg
view model =
    div []
        [ div []
            [ text " Midi inputs: "
            , select [ onInput ChangeMidiIn ] (nullMidiOption :: (List.map makeSelectionOption model.midiInputs))
            ]
        , div []
            [ text " Midi outputs: "
            , select [ onInput ChangeMidiOut ] (nullMidiOption :: (List.map makeSelectionOption model.midiOutputs))
            ]
        , div []
            [ text ("Current Midi Input: " ++ (midiPortName model.midiIn)) ]
        , div []
            [ text ("Current Midi Output: " ++ (midiPortName model.midiOut)) ]
        , div []
            (List.map
                (\msg -> div [] [ text msg ])
                model.receivedMessages
            )
        ]
