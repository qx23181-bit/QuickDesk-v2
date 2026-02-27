// Copyright 2026 QuickDesk Authors
// TURN Server configuration manager

#ifndef QUICKDESK_MANAGER_TURNSERVERMANAGER_H
#define QUICKDESK_MANAGER_TURNSERVERMANAGER_H

#include <QObject>
#include <QJsonArray>
#include <QJsonObject>
#include <QString>

namespace quickdesk {

/**
 * @brief Manages STUN/TURN server configuration from two sources:
 * 
 *   1. Built-in STUN servers (always included)
 *   2. User-configured servers (configured in UI, persisted locally; always included)
 * 
 * TURN credential fetching is handled on the Chromium side by
 * QuickDeskIceConfigFetcher, which contacts the signaling server directly.
 * This class only provides the initial STUN/user config to pass via
 * native messaging.
 */
class TurnServerManager : public QObject {
    Q_OBJECT
    Q_PROPERTY(QJsonArray servers READ servers NOTIFY serversChanged)

public:
    explicit TurnServerManager(QObject* parent = nullptr);
    ~TurnServerManager() override = default;

    QJsonArray servers() const;
    void setServers(const QJsonArray& servers);
    
    /**
     * @brief Get the ICE config object for native messaging
     * 
     * Returns QJsonObject with "iceServers" containing built-in STUN + user servers.
     * Does NOT include server-fetched TURN — that is handled by Chromium.
     */
    Q_INVOKABLE QJsonObject getEffectiveIceConfig() const;
    
    Q_INVOKABLE bool addTurnServer(const QString& url,
                                     const QString& username,
                                     const QString& credential,
                                     int maxRateKbps = 8000);
    Q_INVOKABLE bool addStunServer(const QString& url);
    Q_INVOKABLE void removeServer(int index);
    Q_INVOKABLE void clearServers();
    Q_INVOKABLE static bool validateServerUrl(const QString& url);
    
    Q_INVOKABLE bool hasTurnServer() const;
    Q_INVOKABLE bool hasTurnServer(const QJsonArray& servers) const;

    void loadSettings();
    void saveSettings();

signals:
    void serversChanged();

private:
    // Built-in STUN servers (always sent to Chromium)
    QJsonArray m_builtinStunServers;

    // User-configured servers (always sent to Chromium)
    QJsonArray m_userServers;
};

} // namespace quickdesk

#endif // QUICKDESK_MANAGER_TURNSERVERMANAGER_H
