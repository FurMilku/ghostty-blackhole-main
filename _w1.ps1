$path = "C:\Test_Program\VS_Code\ghostty-blackhole-main\Blakhole_UI\core\blackholecore.cpp"
$enc = [System.Text.UTF8Encoding]::new($false)
$all = @"
// blackholecore.cpp
#include "blackholecore.h"

#include <QCoreApplication>
#include <QDir>
#include <QFile>
#include <QFileInfo>
#include <QTextStream>
#include <QStandardPaths>
#include <QSettings>
#include <QDebug>

#ifdef Q_OS_WIN
#include <windows.h>
#endif

// ========== PresetModel ==========

PresetModel::PresetModel(QObject *parent)
    : QAbstractListModel(parent)
{
}

int PresetModel::rowCount(const QModelIndex &parent) const
{
    if (parent.isValid()) return 0;
    return m_presets.size();
}

QVariant PresetModel::data(const QModelIndex &index, int role) const
{
    if (!index.isValid() || index.row() >= m_presets.size())
        return QVariant();

    const PresetData &p = m_presets.at(index.row());

    switch (role) {
    case NameRole:       return p.name;
    case DiskTempRole:   return p.diskTemp;
    case DiskInclRole:   return p.diskIncl;
    case DiskRollRole:   return p.diskRoll;
    case DiskInnerRole:  return p.diskInner;
    case DiskOuterRole:  return p.diskOuter;
    case DiskOpacRole:   return p.diskOpac;
    case DiskDoppRole:   return p.diskDopp;
    case DiskBeamRole:   return p.diskBeam;
    case DiskGainRole:   return p.diskGain;
    case DiskContrRole:  return p.diskContr;
    case DiskWindRole:   return p.diskWind;
    case DiskSpeedRole:  return p.diskSpeed;
    case DiskExpoRole:   return p.diskExpo;
    case DiskStarRole:   return p.diskStar;
    default: return QVariant();
    }
}

bool PresetModel::setData(const QModelIndex &index, const QVariant &value, int role)
{
    if (!index.isValid() || index.row() >= m_presets.size())
        return false;

    PresetData &p = m_presets[index.row()];

    switch (role) {
    case NameRole:       p.name = value.toString(); break;
    case DiskTempRole:   p.diskTemp  = value.toFloat(); break;
    case DiskInclRole:   p.diskIncl  = value.toFloat(); break;
    case DiskRollRole:   p.diskRoll  = value.toFloat(); break;
    case DiskInnerRole:  p.diskInner = value.toFloat(); break;
    case DiskOuterRole:  p.diskOuter = value.toFloat(); break;
    case DiskOpacRole:   p.diskOpac  = value.toFloat(); break;
    case DiskDoppRole:   p.diskDopp  = value.toFloat(); break;
    case DiskBeamRole:   p.diskBeam  = value.toFloat(); break;
    case DiskGainRole:   p.diskGain  = value.toFloat(); break;
    case DiskContrRole:  p.diskContr = value.toFloat(); break;
    case DiskWindRole:   p.diskWind  = value.toFloat(); break;
    case DiskSpeedRole:  p.diskSpeed = value.toFloat(); break;
    case DiskExpoRole:   p.diskExpo  = value.toFloat(); break;
    case DiskStarRole:   p.diskStar  = value.toFloat(); break;
    default: return false;
    }

    emit dataChanged(index, index, {role});
    return true;
}

QHash<int, QByteArray> PresetModel::roleNames() const
{
    return {
        {NameRole,       "presetName"},
        {DiskTempRole,   "diskTemp"},
        {DiskInclRole,   "diskIncl"},
        {DiskRollRole,   "diskRoll"},
        {DiskInnerRole,  "diskInner"},
        {DiskOuterRole,  "diskOuter"},
        {DiskOpacRole,   "diskOpac"},
        {DiskDoppRole,   "diskDopp"},
        {DiskBeamRole,   "diskBeam"},
        {DiskGainRole,   "diskGain"},
        {DiskContrRole,  "diskContr"},
        {DiskWindRole,   "diskWind"},
        {DiskSpeedRole,  "diskSpeed"},
        {DiskExpoRole,   "diskExpo"},
        {DiskStarRole,   "diskStar"}
    };
}

void PresetModel::setPresets(const QVector<PresetData> &presets)
{
    beginResetModel();
    m_presets = presets;
    endResetModel();
}

QVector<PresetData> PresetModel::presets() const
{
    return m_presets;
}

void PresetModel::updateParam(int index, const QString &param, float value)
{
    if (index < 0 || index >= m_presets.size()) return;

    PresetData &p = m_presets[index];

    if (param == "diskTemp")       p.diskTemp  = value;
    else if (param == "diskIncl")  p.diskIncl  = value;
    else if (param == "diskRoll")  p.diskRoll  = value;
    else if (param == "diskInner") p.diskInner = value;
    else if (param == "diskOuter") p.diskOuter = value;
    else if (param == "diskOpac")  p.diskOpac  = value;
    else if (param == "diskDopp")  p.diskDopp  = value;
    else if (param == "diskBeam")  p.diskBeam  = value;
    else if (param == "diskGain")  p.diskGain  = value;
    else if (param == "diskContr") p.diskContr = value;
    else if (param == "diskWind")  p.diskWind  = value;
    else if (param == "diskSpeed") p.diskSpeed = value;
    else if (param == "diskExpo")  p.diskExpo  = value;
    else if (param == "diskStar")  p.diskStar  = value;
    else return;

    QModelIndex idx = this->index(index, 0);
    emit dataChanged(idx, idx);
}

void PresetModel::movePreset(int from, int to)
{
    if (from < 0 || from >= m_presets.size() || to < 0 || to >= m_presets.size() || from == to)
        return;
    int destRow = (to > from) ? to + 1 : to;
    if (destRow > m_presets.size()) destRow = m_presets.size();
    m_presets.move(from, destRow - 1);
    emit dataChanged(index(0), index(m_presets.size() - 1));
}
"@
[System.IO.File]::WriteAllText($path, $all, $enc)
Write-Output "Part 1 done: PresetModel"
