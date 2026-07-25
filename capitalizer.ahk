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

        menu.AddButton("w100", "4 - sqwrap")
            .OnEvent("Click", (*) => TransformText("1q", selected, menu))

        menu.AddButton("w100", "5 - dqwrap")
            .OnEvent("Click", (*) => TransformText("2q", selected, menu))

        menu.AddButton("w100", "0 - cancel")
            .OnEvent("Click", (*) => menu.Destroy())

        menu.OnEvent("Escape", (*) => menu.Destroy())

        ; hotkeys only work inside menu gui
        HotIfWinActive("ahk_id " menu.Hwnd)

        ; hotkeys
        Hotkey("1", (*) => TransformText("upper", selected, menu), "On")
        Hotkey("2", (*) => TransformText("lower", selected, menu), "On")
        Hotkey("3", (*) => TransformText("title", selected, menu), "On")
        Hotkey("4", (*) => TransformText("1q", selected, menu), "On")
        Hotkey("5", (*) => TransformText("2q", selected, menu), "On")

        Hotkey("0", (*) => menu.Destroy(), "On")

        ; reset
        HotIfWinActive() 

        menu.Show()
    }
}

TransformText(choice, selected, menu)
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
        case "1q":
            result := "'" selected "'"
        case "2q":            
            result := '"' selected '"'
        
    }

    menu.Destroy()

    ; puts the changes onto the clipboard
    A_Clipboard := result

    ; clipboard updates not instant sometimes
    Sleep 40
    
    SendInput "^v"
}

