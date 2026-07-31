#Requires AutoHotkey v2.0

^+l::
{

    Send "{Home}" ; send to beginning of code
    Send "{Home}" ; send to beginning of line
    Send "+{End}" ; send to end of line

}

Home::Send "{Home}"