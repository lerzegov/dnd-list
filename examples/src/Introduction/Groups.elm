module Introduction.Groups exposing (Model, Msg, init, initialModel, main, subscriptions, update, view)

import Browser
import DnDList.Groups
import Html
import Html.Attributes



-- MAIN


main : Program () Model Msg
main =
    Browser.element
        { init = init
        , view = view
        , update = update
        , subscriptions = subscriptions
        }



-- DATA


type Group
    = Top
    | Bottom


type alias Item =
    { group : Group
    , value : String
    , color : String
    }


preparedData : List Item
preparedData =
    [ Item Top "C" blue
    , Item Top "2" red
    , Item Top "A" blue
    , Item Top "" transparent
    , Item Bottom "3" red
    , Item Bottom "B" blue
    , Item Bottom "1" red
    , Item Bottom "" transparent
    ]



-- SYSTEM


config : DnDList.Groups.Config Item
config =
    { trigger = DnDList.Groups.OnDrag
    , operation = DnDList.Groups.RotateOut
    , beforeUpdate = \_ _ list -> list
    , groups =
        { comparator = compareByGroup
        , trigger = DnDList.Groups.OnDrag
        , operation = DnDList.Groups.InsertBefore
        , beforeUpdate = updateOnGroupChange
        }
    }


compareByGroup : Item -> Item -> Bool
compareByGroup dragItem dropItem =
    dragItem.group == dropItem.group


updateOnGroupChange : Int -> Int -> List Item -> List Item
updateOnGroupChange dragIndex dropIndex list =
    let
        drop : List Item
        drop =
            list |> List.drop dropIndex |> List.take 1
    in
    list
        |> List.indexedMap
            (\index item ->
                if index == dragIndex then
                    List.map2
                        (\dragItem dropItem -> { dragItem | group = dropItem.group })
                        [ item ]
                        drop

                else
                    [ item ]
            )
        |> List.concat


system : DnDList.Groups.System Item Msg
system =
    DnDList.Groups.create config MyMsg



-- MODEL


type alias Model =
    { dnd : DnDList.Groups.Model
    , items : List Item
    }


initialModel : Model
initialModel =
    { dnd = system.model
    , items = preparedData
    }


init : () -> ( Model, Cmd Msg )
init _ =
    ( initialModel, Cmd.none )



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions model =
    system.subscriptions model.dnd



-- UPDATE


type Msg
    = MyMsg DnDList.Groups.Msg


update : Msg -> Model -> ( Model, Cmd Msg )
update message model =
    case message of
        MyMsg msg ->
            let
                ( dnd, items ) =
                    system.update msg model.dnd model.items
            in
            ( { model | dnd = dnd, items = items }
            , system.commands model.dnd
            )



-- VIEW


view : Model -> Html.Html Msg
view model =
    Html.section sectionStyles
        [ groupView model Top lightRed
        , groupView model Bottom lightBlue
        , ghostView model.dnd model.items
        ]


groupView : Model -> Group -> String -> Html.Html Msg
groupView model group bgColor =
    let
        items : List Item
        items =
            model.items
                |> List.filter (\item -> item.group == group)
    in
    items
        |> List.indexedMap (itemView model (calculateOffset 0 group model.items))
        |> Html.div (groupStyles bgColor)


itemView : Model -> Int -> Int -> Item -> Html.Html Msg
itemView model offset localIndex { group, value, color } =
    let
        globalIndex : Int
        globalIndex =
            offset + localIndex

        itemId : String
        itemId =
            "id-" ++ String.fromInt globalIndex
    in
    case ( system.info model.dnd, maybeDragItem model.dnd model.items ) of
        ( Just { dragIndex }, Just dragItem ) ->
            if value == "" && dragItem.group /= group then
                Html.div
                    (Html.Attributes.id itemId
                        :: auxiliaryStyles
                        ++ system.dropEvents globalIndex itemId
                    )
                    []

            else if value == "" && dragItem.group == group then
                Html.div
                    (Html.Attributes.id itemId
                        :: auxiliaryStyles
                    )
                    []

            else if dragIndex /= globalIndex then
                Html.div
                    (Html.Attributes.id itemId
                        :: itemStyles color
                        ++ system.dropEvents globalIndex itemId
                    )
                    [ Html.text value ]

            else
                Html.div
                    (Html.Attributes.id itemId
                        :: itemStyles gray
                    )
                    []

        _ ->
            if value == "" then
                Html.div
                    (Html.Attributes.id itemId
                        :: auxiliaryStyles
                    )
                    []

            else
                Html.div
                    (Html.Attributes.id itemId
                        :: itemStyles color
                        ++ system.dragEvents globalIndex itemId
                    )
                    [ Html.text value ]


ghostView : DnDList.Groups.Model -> List Item -> Html.Html Msg
ghostView dnd items =
    case maybeDragItem dnd items of
        Just { value, color } ->
            Html.div
                (itemStyles color ++ system.ghostStyles dnd)
                [ Html.text value ]

        Nothing ->
            Html.text ""



-- HELPERS


calculateOffset : Int -> Group -> List Item -> Int
calculateOffset index group list =
    case list of
        [] ->
            0

        x :: xs ->
            if x.group == group then
                index

            else
                calculateOffset (index + 1) group xs


maybeDragItem : DnDList.Groups.Model -> List Item -> Maybe Item
maybeDragItem dnd items =
    system.info dnd
        |> Maybe.andThen (\{ dragIndex } -> items |> List.drop dragIndex |> List.head)



-- COLORS


red : String
red =
    "#c30005"


blue : String
blue =
    "#0067c3"


lightRed : String
lightRed =
    "#ea9088"


lightBlue : String
lightBlue =
    "#88b0ea"


gray : String
gray =
    "dimgray"


transparent : String
transparent =
    "transparent"



-- STYLES


sectionStyles : List (Html.Attribute msg)
sectionStyles =
    [ Html.Attributes.style "display" "flex"
    , Html.Attributes.style "align-items" "top"
    , Html.Attributes.style "justify-content" "center"
    ]


groupStyles : String -> List (Html.Attribute msg)
groupStyles color =
    [ Html.Attributes.style "display" "table"
    , Html.Attributes.style "background-color" color
    , Html.Attributes.style "padding-top" "3em"
    ]


itemStyles : String -> List (Html.Attribute msg)
itemStyles color =
    [ Html.Attributes.style "width" "5rem"
    , Html.Attributes.style "height" "5rem"
    , Html.Attributes.style "background-color" color
    , Html.Attributes.style "border-radius" "8px"
    , Html.Attributes.style "color" "#ffffff"
    , Html.Attributes.style "cursor" "pointer"
    , Html.Attributes.style "margin" "0 auto 2em auto"
    , Html.Attributes.style "display" "flex"
    , Html.Attributes.style "align-items" "center"
    , Html.Attributes.style "justify-content" "center"
    ]


auxiliaryStyles : List (Html.Attribute msg)
auxiliaryStyles =
    [ Html.Attributes.style "height" "auto"
    , Html.Attributes.style "height" "1rem"
    , Html.Attributes.style "width" "10rem"
    ]
