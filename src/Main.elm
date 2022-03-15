module Main exposing (main)

import Browser
import Html exposing (..)
import Html.Attributes as Attr
import Html.Events exposing (onClick)
import Json.Decode as D
import Json.Decode.Pipeline as P
import Json.Encode as E
import MachineConnector


main : Program () Model Msg
main =
    Browser.element
        { init = init
        , view = view
        , update = update
        , subscriptions = subscriptions
        }


type alias Item =
    { contractAddress : String
    , tokenId : Int
    , name : String
    , description : String
    , image : String
    }


type alias Model =
    { state : State
    , itemsSize : String
    , totalItems : Int
    , items : List Item
    , selectedItem : Maybe Item
    }


type State
    = Loading
    | Display
    | Failed


modelDecoder : D.Decoder Model
modelDecoder =
    D.map5 Model
        stateDecoder
        itemsSizeDecoder
        totalItemsDecoder
        itemsDecoder
        selectedItemDecoder


stateDecoder : D.Decoder State
stateDecoder =
    D.field "value" D.string
        |> D.andThen
            (\value ->
                case value of
                    "loading" ->
                        D.succeed Loading

                    "display" ->
                        D.succeed Display

                    "failed" ->
                        D.succeed Failed

                    v ->
                        D.fail ("Unknown state: " ++ v)
            )


itemsSizeDecoder : D.Decoder String
itemsSizeDecoder =
    D.at [ "context", "itemsSize" ] D.string


totalItemsDecoder : D.Decoder Int
totalItemsDecoder =
    D.at [ "context", "totalItems" ] D.int


itemsDecoder : D.Decoder (List Item)
itemsDecoder =
    D.at [ "context", "items" ] (D.list itemDecoder)


itemDecoder : D.Decoder Item
itemDecoder =
    D.succeed Item
        |> P.required "contractAddress" D.string
        |> P.required "tokenId" D.int
        |> P.required "name" D.string
        |> P.required "description" D.string
        |> P.required "image" D.string


selectedItemDecoder : D.Decoder (Maybe Item)
selectedItemDecoder =
    D.nullable (D.at [ "context", "selectedItem" ] itemDecoder)


type Msg
    = StateChanged Model
    | DecodeStateError D.Error
    | ItemsSizeChanged String
    | ItemsReloadClicked
    | ItemClicked Int


init : () -> ( Model, Cmd Msg )
init _ =
    ( { state = Loading
      , itemsSize = "small"
      , totalItems = 0
      , items = []
      , selectedItem = Nothing
      }
    , Cmd.none
    )


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        StateChanged m ->
            ( m, Cmd.none )

        DecodeStateError _ ->
            ( model, Cmd.none )

        ItemsSizeChanged itemsSize ->
            ( model
            , MachineConnector.event
                (E.object
                    [ ( "type", E.string "ITEMS.SIZE_CHANGED" )
                    , ( "itemsSize", E.string itemsSize )
                    ]
                )
            )

        ItemsReloadClicked ->
            ( model
            , MachineConnector.event
                (E.object
                    [ ( "type", E.string "ITEMS.RELOAD" )
                    ]
                )
            )

        ItemClicked index ->
            ( model
            , MachineConnector.event
                (E.object
                    [ ( "type", E.string "ITEM.CLICKED" )
                    , ( "selectedItem", E.int index )
                    ]
                )
            )


view : Model -> Html Msg
view model =
    div [ Attr.id "main__view" ]
        [ div []
            [ text <| "Inventory (" ++ String.fromInt model.totalItems ++ ")"
            ]
        , div []
            [ text "Items Size: "
            , button [ onClick <| ItemsSizeChanged "small" ] [ text "small" ]
            , button [ onClick <| ItemsSizeChanged "large" ] [ text "large" ]
            ]
        , div [] <|
            case model.state of
                Display ->
                    p [] [ text "Selected Item:" ]
                        :: (List.indexedMap
                                (\index item ->
                                    div
                                        [ Attr.style "font-size" model.itemsSize
                                        , onClick <| ItemClicked index
                                        ]
                                        [ span [ Attr.style "margin-right" "20px" ] [ text <| String.fromInt item.tokenId ]
                                        , span
                                            [ Attr.style "margin-right" "20px"
                                            ]
                                            [ img
                                                [ Attr.src item.image
                                                , Attr.style "width" "20px"
                                                ]
                                                []
                                            ]
                                        , span [ Attr.style "margin-right" "20px" ] [ text item.name ]
                                        , span [ Attr.style "margin-right" "20px" ] [ text item.description ]
                                        ]
                                )
                            <|
                                model.items
                           )
                        ++ [ div [ Attr.style "margin-top" "20px" ] <|
                                case model.selectedItem of
                                    Just item ->
                                        [ p [] [ text "Selected Item:" ]
                                        , span [ Attr.style "margin-right" "20px" ] [ text <| String.fromInt item.tokenId ]
                                        , span [ Attr.style "margin-right" "20px" ]
                                            [ img
                                                [ Attr.src item.image
                                                , Attr.style "width" "64px"
                                                ]
                                                []
                                            ]
                                        , span [ Attr.style "margin-right" "20px" ] [ text item.name ]
                                        , span [ Attr.style "margin-right" "20px" ] [ text item.description ]
                                        ]

                                    Nothing ->
                                        []
                           ]

                Loading ->
                    [ span [] [ text "Loading..." ] ]

                Failed ->
                    [ span [] [ text "Failed!" ]
                    , button [ onClick ItemsReloadClicked ] [ text "RETRY" ]
                    ]
        ]


subscriptions : Model -> Sub Msg
subscriptions _ =
    MachineConnector.stateChanged
        (\value ->
            case D.decodeValue modelDecoder value of
                Ok m ->
                    StateChanged m

                Err e ->
                    DecodeStateError e
        )
