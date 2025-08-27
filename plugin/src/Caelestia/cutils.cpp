#include "cutils.hpp"

#include <qobject.h>
#include <QtQuick/QQuickItem>
#include <QtQuick/QQuickItemGrabResult>
#include <QThreadPool>
#include <QQmlEngine>
#include <QDir>

void CUtils::saveItem(QQuickItem* target, const QUrl& path) const {
    this->saveItem(target, path, QRect(), QJSValue(), QJSValue());
}

void CUtils::saveItem(QQuickItem* target, const QUrl& path, const QRect& rect) const {
    this->saveItem(target, path, rect, QJSValue(), QJSValue());
}

void CUtils::saveItem(QQuickItem* target, const QUrl& path, QJSValue onSaved) const {
    this->saveItem(target, path, QRect(), onSaved, QJSValue());
}

void CUtils::saveItem(QQuickItem* target, const QUrl& path, QJSValue onSaved, QJSValue onFailed) const {
    this->saveItem(target, path, QRect(), onSaved, onFailed);
}

void CUtils::saveItem(QQuickItem* target, const QUrl& path, const QRect& rect, QJSValue onSaved) const {
    this->saveItem(target, path, rect, onSaved, QJSValue());
}

void CUtils::saveItem(QQuickItem* target, const QUrl& path, const QRect& rect, QJSValue onSaved, QJSValue onFailed) const {
    if (!target) {
        qWarning() << "CUtils::saveItem: a target is required";
        return;
    }

    if (!path.isLocalFile()) {
        qWarning() << "CUtils::saveItem:" << path << "is not a local file";
        return;
    }

    QSharedPointer<QQuickItemGrabResult> grabResult = target->grabToImage();

    QObject::connect(
        grabResult.data(),
        &QQuickItemGrabResult::ready,
        this,
        [grabResult, rect, path, onSaved, onFailed, this]() {
            QThreadPool::globalInstance()->start([grabResult, rect, path, onSaved, onFailed, this] {
                QImage image = grabResult->image();

                if (!rect.isEmpty()) {
                    image = image.copy(rect);
                }

                const QString file = path.toLocalFile();
                const QString parent = QFileInfo(file).absolutePath();
                if (QDir().mkpath(parent) && image.save(file)) {
                    if (onSaved.isCallable()) {
                        onSaved.call({ QJSValue(file), qmlEngine(this)->toScriptValue(QVariant::fromValue(path)) });
                    }
                } else {
                    qWarning() << "CUtils::saveItem: failed to save" << path;
                    if (onFailed.isCallable()) {
                        onFailed.call({ qmlEngine(this)->toScriptValue(QVariant::fromValue(path)) });
                    }
                }
            });
        }
    );
}

bool CUtils::copyFile(const QUrl& source, const QUrl& target) const {
    return this->copyFile(source, target, true);
}

bool CUtils::copyFile(const QUrl& source, const QUrl& target, bool overwrite) const {
    if (!source.isLocalFile()) {
        qWarning() << "CUtils::copyFile: source" << source << "is not a local file";
        return false;
    }
    if (!target.isLocalFile()) {
        qWarning() << "CUtils::copyFile: target" << target << "is not a local file";
        return false;
    }

    if (overwrite) {
        QFile::remove(target.toLocalFile());
    }

    return QFile::copy(source.toLocalFile(), target.toLocalFile());
}
