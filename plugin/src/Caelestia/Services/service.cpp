#include "service.hpp"

#include <qdebug.h>
#include <qpointer.h>

namespace caelestia {

Service::Service(QObject* parent)
    : QObject(parent)
    , m_refCount(0) {}

int Service::refCount() const {
    return m_refCount;
}

void Service::ref() {
    if (m_refCount == 0) {
        start();
    }

    m_refCount++;
    emit refCountChanged();
}

void Service::unref() {
    if (m_refCount == 0) {
        return;
    }

    m_refCount--;
    emit refCountChanged();

    if (m_refCount == 0) {
        stop();
    }
}

} // namespace caelestia
