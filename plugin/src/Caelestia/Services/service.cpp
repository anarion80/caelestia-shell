#include "service.hpp"

#include <qdebug.h>
#include <qpointer.h>

namespace caelestia {

Service::Service(QObject* parent)
    : QObject(parent)
    , m_refCount(0) {}

int Service::refCount() const {
    QMutexLocker locker(&m_mutex);
    return m_refCount;
}

void Service::ref() {
    bool needsStart = false;

    {
        QMutexLocker locker(&m_mutex);
        if (m_refCount == 0) {
            needsStart = true;
        }
        m_refCount++;
    }
    emit refCountChanged();

    if (needsStart) {
        const QPointer<Service> self(this);
        QMetaObject::invokeMethod(
            this,
            [self]() {
                if (self) {
                    self->start();
                }
            },
            Qt::QueuedConnection);
    }
}

void Service::unref() {
    bool needsStop = false;

    {
        QMutexLocker locker(&m_mutex);
        if (m_refCount == 0) {
            return;
        }
        m_refCount--;
        if (m_refCount == 0) {
            needsStop = true;
        }
    }
    emit refCountChanged();

    if (needsStop) {
        const QPointer<Service> self(this);
        QMetaObject::invokeMethod(
            this,
            [self]() {
                if (self) {
                    self->stop();
                }
            },
            Qt::QueuedConnection);
    }
}

} // namespace caelestia
