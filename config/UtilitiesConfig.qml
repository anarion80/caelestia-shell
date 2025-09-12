import Quickshell.Io

JsonObject {
    property bool enabled: true

    property Sizes sizes: Sizes {}

    component Sizes: JsonObject {
        property int width: 400
    }
}
