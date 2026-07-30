#Requires AutoHotkey v2.0

#Requires AutoHotkey v2.0

Home & End::
{
    ; Go to the true beginning of the current line
    Send "{Home}{Home}"

    ; Select through the end of the line
    Send "+{End}"

    ; Include the line break, but no characters below
    Send "+{Right}"
}

; Preserve normal Home-key behavior
Home::Send "{Home}"