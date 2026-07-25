#Requires AutoHotkey v2.0
#SingleInstance Force

global IsRecording := false
global Recorder := ""
global RecordedKeys := []
global MacroGui := ""

^+Tab::ToggleRecording()

ToggleRecording()
{
    global IsRecording, Recorder, RecordedKeys

    if !IsRecording
    {
        RecordedKeys := []
        IsRecording := true

        Recorder := InputHook("V")
        Recorder.KeyOpt("{All}", "+N")
        Recorder.OnKeyDown := RecordKey
        Recorder.Start()

        ToolTip("Recording keyboard input...")
        SetTimer(() => ToolTip(), -1200)
    }
    else
    {
        IsRecording := false

        if IsObject(Recorder)
            Recorder.Stop()

        ShowRecordedMacro()
    }
}

RecordKey(InputHookObject, VK, SC)
{
    global IsRecording, RecordedKeys

    if !IsRecording
        return

    keyName := GetKeyName(
        Format("vk{:02X}sc{:03X}", VK, SC)
    )

    ; Do not record modifier keys by themselves.
    if IsModifierKey(keyName)
        return

    ; Do not record Ctrl+Shift+Tab, since it stops recording.
    if keyName = "Tab"
        && GetKeyState("Ctrl", "P")
        && GetKeyState("Shift", "P")
    {
        return
    }

    modifiers := ""
    displayModifiers := ""

    if GetKeyState("Ctrl", "P")
    {
        modifiers .= "^"
        displayModifiers .= "Ctrl + "
    }

    if GetKeyState("Alt", "P")
    {
        modifiers .= "!"
        displayModifiers .= "Alt + "
    }

    if GetKeyState("Shift", "P")
    {
        modifiers .= "+"
        displayModifiers .= "Shift + "
    }

    if GetKeyState("LWin", "P") || GetKeyState("RWin", "P")
    {
        modifiers .= "#"
        displayModifiers .= "Win + "
    }

    sendKey := FormatSendKey(keyName)

    RecordedKeys.Push({
        SendValue: modifiers . sendKey,
        DisplayValue: displayModifiers . FriendlyKeyName(keyName)
    })
}

FormatSendKey(keyName)
{
    ; Named keys need braces for Send().
    namedKeys := Map(
        "Space", true,
        "Up", true,
        "Down", true,
        "Left", true,
        "Right", true,
        "Enter", true,
        "Tab", true,
        "Escape", true,
        "Backspace", true,
        "Delete", true,
        "Insert", true,
        "Home", true,
        "End", true,
        "PgUp", true,
        "PgDn", true,
        "CapsLock", true
    )

    if namedKeys.Has(keyName)
        return "{" . keyName . "}"

    if RegExMatch(keyName, "^F\d+$")
        return "{" . keyName . "}"

    ; Braces have special meaning inside Send().
    if keyName = "{"
        return "{{}"

    if keyName = "}"
        return "{}}"

    return keyName
}

FriendlyKeyName(keyName)
{
    friendlyNames := Map(
        "Space", "Space",
        "Up", "Up Arrow",
        "Down", "Down Arrow",
        "Left", "Left Arrow",
        "Right", "Right Arrow",
        "Escape", "Escape",
        "Backspace", "Backspace",
        "Delete", "Delete",
        "PgUp", "Page Up",
        "PgDn", "Page Down"
    )

    if friendlyNames.Has(keyName)
        return friendlyNames[keyName]

    return StrUpper(keyName)
}

IsModifierKey(keyName)
{
    return keyName = "LControl"
        || keyName = "RControl"
        || keyName = "LShift"
        || keyName = "RShift"
        || keyName = "LAlt"
        || keyName = "RAlt"
        || keyName = "LWin"
        || keyName = "RWin"
}

ShowRecordedMacro()
{
    global RecordedKeys, MacroGui

    try MacroGui.Destroy()

    MacroGui := Gui("-MaximizeBox -MinimizeBox", "Recorded Macro")
    MacroGui.SetFont("s10", "Segoe UI")

    if RecordedKeys.Length = 0
    {
        sequenceText := "No keys were recorded."
    }
    else
    {
        sequenceParts := []

        for recordedKey in RecordedKeys
            sequenceParts.Push(recordedKey.DisplayValue)

        sequenceText := JoinArray(sequenceParts, "`n")
    }

    MacroGui.AddText(
        "w320",
        "Recorded sequence:`n`n" . sequenceText
    )

    replayButton := MacroGui.AddButton(
        "w150 Default",
        "Replay"
    )

    closeButton := MacroGui.AddButton(
        "x+10 w150",
        "Close"
    )

    replayButton.OnEvent("Click", (*) => ReplayMacro())
    closeButton.OnEvent("Click", (*) => MacroGui.Destroy())

    MacroGui.Show()
}

ReplayMacro()
{
    global RecordedKeys

    if RecordedKeys.Length = 0
        return

    ; Small delay gives you time to focus the target window.
    ToolTip("Replaying...")
    Sleep(500)
    ToolTip()

    for recordedKey in RecordedKeys
    {
        Send(recordedKey.SendValue)
        Sleep(50)
    }
}

JoinArray(items, separator)
{
    output := ""

    for index, item in items
    {
        if index > 1
            output .= separator

        output .= item
    }

    return output
}

; Optional shortcut to replay without opening the window.
F8::ReplayMacro()