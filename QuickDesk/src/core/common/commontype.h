#pragma once
#include <QString>
#include <QStringList>
#include <QVariant>

namespace core {
struct IpRange {
    int ipRangeId;
    QString startIp;
    QString stopIp;
    QString startPort;
    QString stopPort;
};

struct RemoteDevice {
    int id;
    QString deviceId;           // 设备ID（9位）
    QString deviceName;         // 设备别名
    QString accessPassword;     // 加密后的密码
    bool isFavorite;           // 是否星标
    int connectionCount;       // 连接次数
    qint64 lastConnectedTime;  // 最后连接时间
    qint64 createdTime;        // 创建时间
};
}