port module WebMidi
    exposing
        ( MidiPort
        , midiAccess
        , selectMidiIn
        , selectMidiOut
        , sendMidi
        , recvMidi
        , midiError
        , genMidiError
        , closeMidi
        )

import Array.Hamt as Array exposing (Array)
import Json.Encode as E


arrayToPort : Array Int -> E.Value
arrayToPort =
    E.list << Array.foldr (\e acc -> E.int e :: acc) []



-- This code benchmarks 2.9x the speed of the normal port marshalling.
-- Normal port marshalling ends up being:
--   E.list << List.map E.int << Array.toList
-- because there is no native marshalling for Array.Hamt.
-- You can 1.7x the speed with:
--   E.list << Array.toList << Array.map E.int
-- Do not be tempted to replace the folding function, much slower:
--   Array.foldr (E.int e >> (::)) []
-- Web MIDI


type alias MidiPort =
    { id : String
    , manufacturer : String
    , name : String
    , state : String
    , connection : String
    }


port midiAccess : (( List MidiPort, List MidiPort ) -> msg) -> Sub msg


port selectMidiIn : Maybe String -> Cmd msg


port selectMidiOut : Maybe String -> Cmd msg


sendMidi : Array Int -> Cmd msg
sendMidi =
    sendMidi_ << arrayToPort


port sendMidi_ : E.Value -> Cmd msg


port recvMidi : (List Int -> msg) -> Sub msg


port midiError : (( String, String ) -> msg) -> Sub msg


port genMidiError : ( String, String ) -> Cmd msg


port closeMidi : () -> Cmd msg
