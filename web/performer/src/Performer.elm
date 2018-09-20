module Performer exposing (..)

import Array.Hamt as Array exposing (Array)
import Config exposing (config)
import Html exposing (..)
import Html.Events exposing (..)
import Html.Attributes
import WebMidi exposing (MidiPort)
import WebSocket


-- CONFIGURATION
-- Configuration is injected at build time via Docker.


{-| A <ws://> or <wss://> address from which our performer receives updates.
-}
backendServerAddress : String
backendServerAddress =
    config.backendServerAddress


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
      , midiChannel = 1
      , midiCc = 0
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
    , midiChannel : Int
    , midiCc : Int
    }



-- UPDATE


type Msg
    = ReceiveMessage String
    | MidiAccess ( List MidiPort, List MidiPort )
    | ChangeMidiOut String
    | ChangeMidiIn String
    | WebSocketMessage String
    | MidiMessage (List Int)
    | ChangeMidiChannel String
    | ChangeMidiCC String


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        ReceiveMessage message ->
            ( { model | receivedMessages = message :: model.receivedMessages }, Cmd.none )

        MidiAccess ( inputs, outputs ) ->
            ( { model | midiInputs = inputs, midiOutputs = outputs }, Cmd.none )

        ChangeMidiOut id ->
            ( { model | midiOut = selectMidiPort model.midiOutputs id }, WebMidi.selectMidiOut (Just id) )

        ChangeMidiIn id ->
            ( { model | midiIn = selectMidiPort model.midiInputs id }, WebMidi.selectMidiIn (Just id) )

        ChangeMidiCC cc ->
            ( { model | midiCc = clamp 0 127 (Result.withDefault 0 (String.toInt cc)) }, Cmd.none )

        ChangeMidiChannel channel ->
            ( { model | midiChannel = clamp 1 16 (Result.withDefault 1 (String.toInt channel)) }, Cmd.none )

        WebSocketMessage wsmsg ->
            let
                maybeValue =
                    String.toInt wsmsg
            in
                case maybeValue of
                    Err _ ->
                        ( { model | receivedMessages = ("unsent websocket message: " ++ wsmsg) :: model.receivedMessages }, Cmd.none )

                    Ok int ->
                        ( model, (sendCC model.midiChannel model.midiCc int) )

        MidiMessage midi ->
            ( { model | receivedMessages = (midiToString midi) :: model.receivedMessages }, Cmd.none )


midiToString : List Int -> String
midiToString midi =
    midi |> List.foldr (\e acc -> toString e ++ ", " ++ acc) ""


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


sendMidi : List Int -> Cmd msg
sendMidi midi =
    WebMidi.sendMidi (Array.fromList midi)


sendCC : Int -> Int -> Int -> Cmd msg
sendCC channel cc value =
    let
        -- 176 = Hexadecimal "B" shifted left 4
        -- e.g. the 4 higher-order bits of a MIDI CC message "status byte"
        -- we subtract 1 from the channel to convert from one-index to zero-index
        midiChannel =
            176 + (clamp 0 15 (channel - 1))

        midiCc =
            clamp 0 127 cc

        midiValue =
            clamp 0 127 value
    in
        sendMidi [ midiChannel, midiCc, midiValue ]



-- SUBSCRIPTIONS


onMidiAccess : ( List MidiPort, List MidiPort ) -> Msg
onMidiAccess data =
    MidiAccess data


onRecvMidi : List Int -> Msg
onRecvMidi midi =
    MidiMessage midi


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


midiPortName : Maybe MidiPort -> String
midiPortName maybeMidi =
    case maybeMidi of
        Nothing ->
            "None"

        Just midiPort ->
            midiPort.name


makeSelectionOption : MidiPort -> Html msg
makeSelectionOption midiPort =
    option [ Html.Attributes.value midiPort.id ]
        [ text midiPort.name
        ]


nullMidiOption : Html msg
nullMidiOption =
    option [ Html.Attributes.value "0" ]
        [ text "None" ]


midiSenderControl : Model -> Html Msg
midiSenderControl model =
    div []
        [ div [] [ text "Midi Channel: ", input [ onInput ChangeMidiChannel ] [], text (toString model.midiChannel) ]
        , div [] [ text "Midi CC: ", input [ onInput ChangeMidiCC ] [], text (toString model.midiCc) ]
        ]


midiInOutControl : Model -> Html Msg
midiInOutControl model =
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
        ]


view : Model -> Html Msg
view model =
    div []
        [ midiInOutControl model
        , midiSenderControl model
        , div []
            (List.map
                (\msg -> div [] [ text msg ])
                model.receivedMessages
            )
        ]
