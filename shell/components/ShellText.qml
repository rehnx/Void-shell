import QtQuick

Text {
    property string role: "body"
    font.family: Theme.fontFamily
    font.pixelSize: role === "display" ? Theme.fontDisplay : role === "title" ? Theme.fontTitle
        : role === "label" ? Theme.fontLabel : role === "caption" ? Theme.fontCaption : Theme.fontBody
    font.weight: role === "display" || role === "title" ? Theme.weightTitle
        : role === "label" ? Theme.weightLabel : Theme.weightRegular
    color: role === "caption" ? Theme.textSecondary : Theme.textPrimary
    textFormat: Text.PlainText
    lineHeight: Theme.lineHeight
}
