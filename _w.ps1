$path = "C:\Test_Program\VS_Code\ghostty-blackhole-main\Blakhole_UI\core\blackholecore.cpp"
$enc = [System.Text.UTF8Encoding]::new($false)
$sb = [System.Text.StringBuilder]::new()

function al($line) { [void]$sb.AppendLine($line) }

al '// blackholecore.cpp'
al '#include "blackholecore.h"'
al ''
al '#include <QCoreApplication>'
al '#include <QDir>'
al '#include <QFile>'
al '#include <QFileInfo>'
al '#include <QTextStream>'
al '#include <QStandardPaths>'
al '#include <QSettings>'
al '#include <QDebug>'
al ''
al '#ifdef Q_OS_WIN'
al '#include <windows.h>'
al '#endif'
Write-Output "Phase 1: headers written"
[System.IO.File]::WriteAllText($path, $sb.ToString(), $enc)