Set WshShell = CreateObject("WScript.Shell")
WshShell.CurrentDirectory = "c:\Users\Elize\Desktop\Roblox\starve\tools\discord-bot"
WshShell.Run "cmd /c run-forever.bat >> bot-service.log 2>&1", 0, False
