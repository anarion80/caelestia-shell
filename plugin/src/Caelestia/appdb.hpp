#pragma once

#include <qhash.h>
#include <qobject.h>
#include <qqmlintegration.h>

namespace caelestia {

class AppEntry : public QObject {
    Q_OBJECT
    QML_ELEMENT
    QML_UNCREATABLE("AppEntry instances can only be retrieved from an AppDb")

    // The actual DesktopEntry, but we don't have access to the type so it's a QObject
    Q_PROPERTY(QObject* entry READ entry CONSTANT)

    Q_PROPERTY(quint32 frequency READ frequency NOTIFY frequencyChanged)
    Q_PROPERTY(QString id READ id CONSTANT)
    Q_PROPERTY(QString name READ name CONSTANT)
    Q_PROPERTY(QString desc READ desc CONSTANT)
    Q_PROPERTY(QString execString READ execString CONSTANT)
    Q_PROPERTY(QString wmClass READ wmClass CONSTANT)
    Q_PROPERTY(QString genericName READ genericName CONSTANT)
    Q_PROPERTY(QString categories READ categories CONSTANT)
    Q_PROPERTY(QString keywords READ keywords CONSTANT)

public:
    explicit AppEntry(QObject* entry, quint32 frequency, QObject* parent = nullptr);

    [[nodiscard]] QObject* entry() const;

    [[nodiscard]] quint32 frequency() const;
    void setFrequency(quint32 frequency);
    void incrementFrequency();

    [[nodiscard]] QString id() const;
    [[nodiscard]] QString name() const;
    [[nodiscard]] QString desc() const;
    [[nodiscard]] QString execString() const;
    [[nodiscard]] QString wmClass() const;
    [[nodiscard]] QString genericName() const;
    [[nodiscard]] QString categories() const;
    [[nodiscard]] QString keywords() const;

signals:
    void frequencyChanged();

private:
    QObject* m_entry;
    quint32 m_frequency;
};

class AppDb : public QObject {
    Q_OBJECT
    QML_ELEMENT

    Q_PROPERTY(QString uuid READ uuid CONSTANT)
    Q_PROPERTY(QString path READ path WRITE setPath NOTIFY pathChanged REQUIRED)
    Q_PROPERTY(QList<QObject*> entries READ entries WRITE setEntries NOTIFY entriesChanged REQUIRED)
    Q_PROPERTY(QList<AppEntry*> apps READ apps NOTIFY appsChanged)

public:
    explicit AppDb(QObject* parent = nullptr);

    [[nodiscard]] QString uuid() const;

    [[nodiscard]] QString path() const;
    void setPath(const QString& path);

    [[nodiscard]] QList<QObject*> entries() const;
    void setEntries(const QList<QObject*>& entries);

    [[nodiscard]] QList<AppEntry*> apps() const;

    Q_INVOKABLE void incrementFrequency(const QString& id);

signals:
    void pathChanged();
    void entriesChanged();
    void appsChanged();

private:
    const QString m_uuid;
    QString m_path;
    QList<QObject*> m_entries;
    QHash<QString, AppEntry*> m_apps;

    quint32 getFrequency(const QString& id) const;
    void updateAppFrequencies();
    void updateApps();
};

} // namespace caelestia
