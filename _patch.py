import re

filepath = r"C:\Test_Program\VS_Code\ghostty-blackhole-main\Blakhole_UI\core\blackholepreviewfbo.cpp"
with open(filepath, "r", encoding="utf-8") as f:
    content = f.read()

old_start = "bool BlackholePreviewRenderer::initShaders()"
old_end = "    m_program = new QOpenGLShaderProgram();"

new_code = """bool BlackholePreviewRenderer::initShaders()
{
    QString vertPath, fragHeaderPath, fragBodyPath;
    resolveShaderPath(vertPath, fragHeaderPath, fragBodyPath);

    QString vertSrc = readShaderFile(vertPath);
    QString fragHeader = readShaderFile(fragHeaderPath);
    QString fragBody = readShaderFile(fragBodyPath);

    if (vertSrc.isEmpty() || fragHeader.isEmpty() || fragBody.isEmpty()) {
        qWarning() << "BlackholePreviewFBO: failed to read shader files";
        return false;
    }

    // === Shader preprocessing: replace constants with uniform refs ===
    // 1. MODE_TOKENS -> MODE_POMODORO
    fragBody.replace("#define SIZE_MODE MODE_TOKENS", "#define SIZE_MODE MODE_POMODORO");

    // 2. Replace hardcoded consts with uniform references
    auto ovr = [&](const char* name, const char* uni) {
        int pos = 0;
        while ((pos = fragBody.indexOf(QLatin1String(name), pos)) != -1) {
            int ve = fragBody.indexOf(QLatin1Char(';'), pos);
            if (ve == -1) break;
            int eq = fragBody.lastIndexOf(QLatin1Char('='), pos);
            if (eq <= pos) { pos = ve + 1; continue; }
            QString val = fragBody.mid(pos + (int)strlen(name), ve - pos - (int)strlen(name)).trimmed();
            fragBody.replace(pos, ve - pos,
                QLatin1String(name) + QStringLiteral(" = ") + QLatin1String(uni) + QStringLiteral(" ") + val);
            pos = ve + 1;
        }
        fragBody.replace(QStringLiteral("const float ") + QLatin1String(name),
                         QStringLiteral("float ") + QLatin1String(name));
    };
    ovr("HOLE_RADIUS",   "uHoleRadius > 0.0 ? uHoleRadius :");
    ovr("DISK_GAIN",     "uDiskGain > 0.0 ? uDiskGain :");
    ovr("DISK_TEMP",     "uDiskTemp > 0.0 ? uDiskTemp :");
    ovr("EXPOSURE",      "uExposure > 0.0 ? uExposure :");
    ovr("DRIFT_SPEED",   "uSpeed > 0.0 ? uSpeed :");
    ovr("DISK_INCL",     "uDiskIncl > 0.0 ? uDiskIncl :");
    ovr("STAR_GAIN",     "uStarGain > 0.0 ? uStarGain :");
    ovr("DISK_INNER",    "uDiskInner > 0.0 ? uDiskInner :");
    ovr("DISK_OUTER",    "uDiskOuter > 0.0 ? uDiskOuter :");
    ovr("DISK_OPACITY",  "uDiskOpac > 0.0 ? uDiskOpac :");
    ovr("DOPPLER_MIX",   "uDiskDopp > 0.0 ? uDiskDopp :");
    ovr("DISK_BEAM",     "uDiskBeam > 0.0 ? uDiskBeam :");
    ovr("DISK_CONTRAST", "uDiskContr > 0.0 ? uDiskContr :");
    ovr("DISK_SPEED",    "uDiskSpeed > 0.0 ? uDiskSpeed :");
    ovr("DISK_WIND",     "uDiskWind > 0.0 ? uDiskWind :");

    // 3. Concat + main() wrapper
    QString fragSrc = fragHeader + "\\n" + fragBody;
    fragSrc += "\\nvoid main() { vec4 c; vec2 fc = vec2(gl_FragCoord.x, iResolution.y - gl_FragCoord.y); mainImage(c, fc); fragColor = c; }\\n";

    m_program = new QOpenGLShaderProgram();"""

old_idx = content.find(old_start)
old_end_idx = content.find(old_end, old_idx)
if old_idx >= 0 and old_end_idx >= 0:
    old_end_idx += len(old_end)
    content = content[:old_idx] + new_code + content[old_end_idx:]
    with open(filepath, "w", encoding="utf-8") as f:
        f.write(content)
    print("OK: initShaders replaced")
else:
    print(f"FAIL: old_start={old_idx}, old_end={old_end_idx}")
