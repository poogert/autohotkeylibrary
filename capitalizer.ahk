#Requires AutoHotkey v2.0

^+a::
{ 
    ; replaces whatever is in the clipboard
    A_Clipboard := ""
    SendInput "^c"

    ; wait for input
    if !ClipWait(1)
    {
        ; nothing msg if nothing selected
        MsgBox "nothing selected" 
        return

    } 
    else 
    {
        ; saves clipboard
        selected := A_Clipboard

        ; gui stuff
        menu := Gui("-MinimizeBox -MaximizeBox", "text changer")

        ; menu options
        menu.BackColor := "202020"
        menu.SetFont("s11 cFFFFFF", "Calibri")
        menu.AddText("w100 Center", "Choose a transformation")
        
        menu.AddButton("w100", "1 - upper")
            .OnEvent("Click", (*) => TransformText("upper", selected, menu))

        menu.AddButton("w100", "2 - lower")
            .OnEvent("Click", (*) => TransformText("lower", selected, menu))

        menu.AddButton("w100", "3 - title")
            .OnEvent("Click", (*) => TransformText("title", selected, menu))

        menu.AddButton("w100", "4 - wrap")
            .OnEvent("Click", (*) => AskForWrapper(selected, menu))

        menu.AddButton("w100", "0 - cancel")
            .OnEvent("Click", (*) => menu.Destroy())

        menu.OnEvent("Escape", (*) => menu.Destroy())

        ; hotkeys only work inside menu gui
        HotIfWinActive("ahk_id " menu.Hwnd)

        ; hotkeys
        Hotkey("1", (*) => TransformText("upper", selected, menu), "On")
        Hotkey("2", (*) => TransformText("lower", selected, menu), "On")
        Hotkey("3", (*) => TransformText("title", selected, menu), "On")
        Hotkey("4", (*) => AskForWrapper(selected, menu), "On")

        Hotkey("0", (*) => menu.Destroy(), "On")

        ; reset
        HotIfWinActive() 

        menu.Show()
    }
}

TransformText(choice, selected, menu, wrapper := "")
{
    ; events depending on option
    switch choice
    {
        case "upper":
            result := StrUpper(selected)

        case "lower":
            result := StrLower(selected)

        case "title":
            result := StrTitle(selected)

        case "wrap":
            pair := GetWrapperPair(Trim(wrapper))

            if !pair
                return

            result := pair[1] selected pair[2]        
    }

    menu.Destroy()

    ; puts the changes onto the clipboard
    A_Clipboard := result

    ; clipboard updates not instant sometimes
    Sleep 40
    
    SendInput "^v"
}

AskForWrapper(selected, menu)
{
    input := InputBox(
        "Enter wrapper: `"`", (), {}, [], etc.",
        "Wrap text",
        "w300 h130"
    )

    if (input.Result = "Cancel")
        return

    wrapper := input.Value

    ; You can replace this with your own wrapper logic.
    TransformText("wrap", selected, menu, wrapper)
}

GetWrapperPair(wrapper)
{
    dq := Chr(34)
    sq := Chr(39)

    wrappers := Map(
        "(",       ["(", ")"],
        ")",       ["(", ")"],
        "()",       ["(", ")"],

        "{",       ["{", "}"],
        "}",       ["{", "}"],
        "{}",      ["{", "}"],

        "[",       ["[", "]"],
        "]",       ["[", "]"],
        "[]",      ["[", "]"],

        "<",       ["<", ">"],
        ">",       ["<", ">"],
        "</",      ["</", ">"],
        "<>",      ["<", ">"],
        "</>",     ["</", ">"],

        "|",       ["|", "|"],
        "\",       ["\", "\"],
        "*",       ["*", "*"],
        "**",      ["**", "**"],

        ; single quote wrapping
        sq,     [sq, sq],
        sq sq,     [sq, sq],

        ; double quote wrapping
        dq,     [dq, dq],
        dq dq,     [dq, dq],
        dq dq dq, [dq dq dq, dq dq dq],

        "<!--",    ["<!--", "-->"],
        "-->",     ["<!--", "-->"],

        "/*",      ["/*", "*/"],
        "*/",      ["/*", "*/"]
    )

    if !wrappers.Has(wrapper)
    {
        MsgBox "Invalid wrapper: " wrapper
        return false
    }

    return wrappers[wrapper]
}

