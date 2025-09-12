#pragma once

#include "service.hpp"
#include <atomic>
#include <pipewire/pipewire.h>
#include <qmutex.h>
#include <qqmlintegration.h>
#include <spa/param/audio/format-utils.h>
#include <stop_token>
#include <thread>
#include <vector>

namespace caelestia {

class AudioCollector;

class PipeWireWorker {
public:
    explicit PipeWireWorker(std::stop_token token, AudioCollector* collector);

    void run();

private:
    pw_main_loop* m_loop;
    pw_stream* m_stream;
    spa_source* m_timer;
    bool m_idle;

    std::stop_token m_token;
    AudioCollector* m_collector;

    void cleanup();

    static void handleTimeout(void* data, uint64_t expirations);
    void streamStateChanged(pw_stream_state state);
    void processStream();
    void processSamples(const qint16* samples, quint32 count);

    [[nodiscard]] unsigned int nextPowerOf2(unsigned int n);
};

class AudioCollector : public Service {
    Q_OBJECT
    QML_ELEMENT

    Q_PROPERTY(quint32 nodeId READ nodeId WRITE setNodeId NOTIFY nodeIdChanged)

public:
    explicit AudioCollector(QObject* parent = nullptr);
    ~AudioCollector();

    [[nodiscard]] quint32 sampleRate() const;
    [[nodiscard]] quint32 chunkSize() const;

    [[nodiscard]] quint32 nodeId();
    void setNodeId(quint32 nodeId);

    void clearBuffer();
    void loadChunk(const qint16* samples, quint32 count);
    quint32 readChunk(float* out, quint32 count = 0);
    quint32 readChunk(double* out, quint32 count = 0);

signals:
    void sampleRateChanged();
    void chunkSizeChanged();
    void nodeIdChanged();

private:
    const quint32 m_sampleRate;
    const quint32 m_chunkSize;
    quint32 m_nodeId;
    QMutex m_nodeIdMutex;

    std::jthread m_thread;
    std::vector<float> m_buffer1;
    std::vector<float> m_buffer2;
    std::atomic<std::vector<float>*> m_readBuffer;
    std::atomic<std::vector<float>*> m_writeBuffer;
    quint32 m_sampleCount;

    void reload();
    void start() override;
    void stop() override;
};

} // namespace caelestia
