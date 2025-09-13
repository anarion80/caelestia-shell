#include "audioprovider.hpp"

#include "audiocollector.hpp"
#include "service.hpp"
#include <qdebug.h>
#include <qthread.h>

namespace caelestia {

AudioProcessor::AudioProcessor(AudioCollector* collector, QObject* parent)
    : QObject(parent)
    , m_collector(collector) {}

AudioProcessor::~AudioProcessor() {
    stop();
}

void AudioProcessor::init() {
    m_timer = new QTimer(this);
    if (m_collector) {
        m_timer->setInterval(static_cast<int>(m_collector->chunkSize() * 1000.0 / m_collector->sampleRate()));
    }
    connect(m_timer, &QTimer::timeout, this, &AudioProcessor::process);
}

void AudioProcessor::setCollector(AudioCollector* collector) {
    if (m_collector == collector) {
        return;
    }

    if (m_timer) {
        if (m_timer->isActive()) {
            if (m_collector) {
                m_collector->unref();
            }
            if (collector) {
                collector->ref();
            }
        }
        if (collector) {
            m_timer->setInterval(static_cast<int>(collector->chunkSize() * 1000.0 / collector->sampleRate()));
        } else {
            m_timer->stop();
        }
    }

    m_collector = collector;
}

void AudioProcessor::start() {
    if (m_timer && m_collector) {
        m_collector->ref();
        m_timer->start();
    }
}

void AudioProcessor::stop() {
    if (m_timer && m_collector) {
        m_timer->stop();
        m_collector->unref();
    }
}

AudioProvider::AudioProvider(QObject* parent)
    : Service(parent)
    , m_collector(nullptr)
    , m_processor(nullptr)
    , m_thread(nullptr) {}

AudioProvider::~AudioProvider() {
    if (m_thread) {
        m_thread->quit();
        m_thread->wait();
    }
}

AudioCollector* AudioProvider::collector() const {
    return m_collector;
}

void AudioProvider::setCollector(AudioCollector* collector) {
    if (m_collector == collector) {
        return;
    }

    m_collector = collector;
    emit collectorChanged();

    if (m_processor) {
        QMetaObject::invokeMethod(m_processor, "setCollector", Qt::QueuedConnection, Q_ARG(AudioCollector*, collector));
    }
}

void AudioProvider::init() {
    if (!m_processor) {
        qWarning() << "AudioProvider::init: attempted to init with no processor set";
        return;
    }

    m_thread = new QThread(this);
    m_processor->moveToThread(m_thread);

    connect(m_thread, &QThread::started, m_processor, &AudioProcessor::init);
    connect(m_thread, &QThread::finished, m_processor, &AudioProcessor::deleteLater);
    connect(m_thread, &QThread::finished, m_thread, &QThread::deleteLater);

    m_thread->start();
}

void AudioProvider::start() {
    if (m_processor) {
        QMetaObject::invokeMethod(m_processor, "start", Qt::QueuedConnection);
    }
}

void AudioProvider::stop() {
    if (m_processor) {
        QMetaObject::invokeMethod(m_processor, "stop", Qt::QueuedConnection);
    }
}

} // namespace caelestia
