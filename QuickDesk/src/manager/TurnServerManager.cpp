// Copyright 2026 QuickDesk Authors

#include "TurnServerManager.h"
#include "infra/log/log.h"
#include "../core/localconfigcenter.h"
#include <QJsonDocument>

namespace quickdesk {

namespace {
const char* kBuiltinStunUrls[] = {
    "stun:stun.hot-chilli.net",
    "stun:stun.internetcalls.com",
    "stun:stun.miwifi.com"
};
}

TurnServerManager::TurnServerManager(QObject* parent)
    : QObject(parent)
{
    for (const char* url : kBuiltinStunUrls) {
        QJsonObject server;
        server["urls"] = QJsonArray{QString::fromLatin1(url)};
        m_builtinStunServers.append(server);
    }

    loadSettings();
}

QJsonArray TurnServerManager::servers() const
{
    return m_userServers;
}

void TurnServerManager::setServers(const QJsonArray& servers)
{
    if (m_userServers != servers) {
        m_userServers = servers;
        saveSettings();
        emit serversChanged();
        LOG_INFO("User ICE servers updated, count: {}", m_userServers.size());
    }
}

QJsonObject TurnServerManager::getEffectiveIceConfig() const
{
    QJsonArray merged;

    for (const auto& s : m_builtinStunServers) {
        merged.append(s);
    }
    for (const auto& s : m_userServers) {
        merged.append(s);
    }

    QString source = hasTurnServer(m_userServers) ? "user-turn+stun" : "builtin-stun";

    QJsonObject config;
    config["iceServers"] = merged;

    LOG_INFO("ICE config [source={}]: {} server(s)", source.toStdString(), merged.size());
    return config;
}

bool TurnServerManager::addTurnServer(const QString& url,
                                       const QString& username,
                                       const QString& credential,
                                       int maxRateKbps)
{
    if (!validateServerUrl(url)) {
        LOG_WARN("Invalid TURN server URL: {}", url.toStdString());
        return false;
    }
    
    QJsonObject server;
    server["urls"] = QJsonArray{url};
    server["username"] = username;
    server["credential"] = credential;
    if (maxRateKbps > 0) {
        server["maxRateKbps"] = maxRateKbps;
    }
    
    QJsonArray newServers = m_userServers;
    newServers.append(server);
    setServers(newServers);
    
    LOG_INFO("Added TURN server: {}", url.toStdString());
    return true;
}

bool TurnServerManager::addStunServer(const QString& url)
{
    if (!validateServerUrl(url)) {
        LOG_WARN("Invalid STUN server URL: {}", url.toStdString());
        return false;
    }
    
    QJsonObject server;
    server["urls"] = QJsonArray{url};
    
    QJsonArray newServers = m_userServers;
    newServers.append(server);
    setServers(newServers);
    
    LOG_INFO("Added STUN server: {}", url.toStdString());
    return true;
}

void TurnServerManager::removeServer(int index)
{
    if (index >= 0 && index < m_userServers.size()) {
        QJsonArray newServers = m_userServers;
        
        auto serverObj = newServers[index].toObject();
        QString url = serverObj.value("urls").toArray().first().toString();
        
        newServers.removeAt(index);
        setServers(newServers);
        
        LOG_INFO("Removed server at index {}: {}", index, url.toStdString());
    }
}

void TurnServerManager::clearServers()
{
    if (!m_userServers.isEmpty()) {
        setServers(QJsonArray());
        LOG_INFO("Cleared all user-configured servers");
    }
}

bool TurnServerManager::validateServerUrl(const QString& url)
{
    if (url.isEmpty()) {
        return false;
    }
    
    if (!url.startsWith("stun:", Qt::CaseInsensitive) &&
        !url.startsWith("turn:", Qt::CaseInsensitive) &&
        !url.startsWith("turns:", Qt::CaseInsensitive)) {
        return false;
    }
    
    QUrl qurl(url);
    return qurl.isValid();
}

bool TurnServerManager::hasTurnServer() const
{
    return hasTurnServer(m_userServers);
}

bool TurnServerManager::hasTurnServer(const QJsonArray& servers) const
{
    for (const auto& serverValue : servers) {
        auto serverObj = serverValue.toObject();
        auto urls = serverObj.value("urls").toArray();
        for (const auto& urlValue : urls) {
            QString url = urlValue.toString();
            if (url.startsWith("turn:", Qt::CaseInsensitive) ||
                url.startsWith("turns:", Qt::CaseInsensitive)) {
                return true;
            }
        }
    }
    return false;
}

void TurnServerManager::loadSettings()
{
    QString jsonStr = core::LocalConfigCenter::instance().turnServersJson("");
    
    if (jsonStr.isEmpty()) {
        m_userServers = QJsonArray();
        LOG_INFO("No user-configured ICE servers");
        return;
    }
    
    QJsonDocument doc = QJsonDocument::fromJson(jsonStr.toUtf8());
    if (doc.isArray()) {
        m_userServers = doc.array();
        LOG_INFO("Loaded {} user-configured ICE server(s)", m_userServers.size());
    } else {
        m_userServers = QJsonArray();
        LOG_WARN("Failed to parse user ICE servers JSON, using empty array");
    }
}

void TurnServerManager::saveSettings()
{
    QJsonDocument doc(m_userServers);
    QString jsonStr = QString::fromUtf8(doc.toJson(QJsonDocument::Compact));
    core::LocalConfigCenter::instance().setTurnServersJson(jsonStr);
}

} // namespace quickdesk
