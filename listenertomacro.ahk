#Requires AutoHotkey v2.0
#SingleInstance Force

global IsRecording := false
global Recorder := ""
global RecordedKeys := []
global MacroGui := ""
global RecordedWindow := 0
global RecordedControl := ""

^+Tab::ToggleRecording()
F8::ReplayMacro()

ToggleRecording()
{
    global IsRecording
    global Recorder
    global RecordedKeys
    global RecordedWindow
    global RecordedControl

    if !IsRecording
    {
        RecordedKeys := []
        IsRecording := true

        Recorder := InputHook("V")
        Recorder.KeyOpt("{All}", "+N")
        Recorder.OnKeyDown := RecordKey
        Recorder.Start()

        ToolTip("recording keyboard input...")
        SetTimer(() => ToolTip(), -1200)
    }
    else
    {
        IsRecording := false

        if IsObject(Recorder)
            Recorder.Stop()

        ; save the active editor and text control
        RecordedWindow := WinGetID("A")

        try
            RecordedControl := ControlGetFocus(
                "ahk_id " RecordedWindow
            )
        catch
            RecordedControl := ""

        ShowRecordedMacro()
    }
}

RecordKey(InputHookObject, VK, SC)
{
    global IsRecording
    global RecordedKeys

    if !IsRecording
        return

    keyName := GetKeyName(
        Format("vk{:02X}sc{:03X}", VK, SC)
    )

    ; ignore standalone modifiers
    if IsModifierKey(keyName)
        return

    ; ignore the recording shortcut
    if (
        keyName = "Tab"
        && GetKeyState("Ctrl", "P")
        && GetKeyState("Shift", "P")
    )
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

    if (
        GetKeyState("LWin", "P")
        || GetKeyState("RWin", "P")
    )
    {
        modifiers .= "#"
        displayModifiers .= "Win + "
    }

    sendKey := FormatSendKey(keyName)

    RecordedKeys.Push({
        SendValue: modifiers . sendKey,
        DisplayValue:
            displayModifiers . FriendlyKeyName(keyName)
    })
}

FormatSendKey(keyName)
{
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

    ; escape braces for send
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
    return (
        keyName = "LControl"
        || keyName = "RControl"
        || keyName = "LShift"
        || keyName = "RShift"
        || keyName = "LAlt"
        || keyName = "RAlt"
        || keyName = "LWin"
        || keyName = "RWin"
    )
}

ShowRecordedMacro()
{
    global RecordedKeys
    global MacroGui

    try MacroGui.Destroy()

    MacroGui := Gui(
        "-MaximizeBox -MinimizeBox",
        "Recorded Macro"
    )

    MacroGui.SetFont("s10", "Segoe UI")

    if RecordedKeys.Length = 0
    {
        sequenceText := "No keys were recorded."
    }
    else
    {
        sequenceParts := []

        for recordedKey in RecordedKeys
            sequenceParts.Push(
                recordedKey.DisplayValue
            )

        sequenceText := JoinArray(
            sequenceParts,
            "`n"
        )
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

    replayButton.OnEvent(
        "Click",
        (*) => ReplayMacro()
    )

    closeButton.OnEvent(
        "Click",
        (*) => MacroGui.Destroy()
    )

    MacroGui.OnEvent(
        "Escape",
        (*) => MacroGui.Destroy()
    )

    MacroGui.Show()
}

ReplayMacro()
{
    global RecordedKeys
    global RecordedWindow
    global RecordedControl
    global MacroGui

    if RecordedKeys.Length = 0
        return

    ; hide the menu before restoring focus
    try MacroGui.Hide()

    if (
        RecordedWindow
        && WinExist("ahk_id " RecordedWindow)
    )
    {
        WinActivate(
            "ahk_id " RecordedWindow
        )

        if !WinWaitActive(
            "ahk_id " RecordedWindow,
            ,
            1
        )
        {
            MsgBox "could not restore the target window."
            return
        }

        ; restore the original text control
        if RecordedControl != ""
        {
            try ControlFocus(
                RecordedControl,
                "ahk_id " RecordedWindow
            )
        }
    }

    Sleep 150

    for recordedKey in RecordedKeys
    {
        Send(recordedKey.SendValue)
        Sleep 50
    }

    try MacroGui.Destroy()
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