#pragma once

#include "service.hpp"
#include <atomic>
#include <cstdint>
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
    void processSamples(const int16_t* samples, uint32_t count);

    [[nodiscard]] unsigned int nextPowerOf2(unsigned int n);
};

class AudioCollector : public Service {
    Q_OBJECT
    QML_ELEMENT

    Q_PROPERTY(uint32_t nodeId READ nodeId WRITE setNodeId NOTIFY nodeIdChanged)

public:
    explicit AudioCollector(QObject* parent = nullptr);
    ~AudioCollector();

    [[nodiscard]] uint32_t sampleRate() const;
    [[nodiscard]] uint32_t chunkSize() const;

    [[nodiscard]] uint32_t nodeId();
    void setNodeId(uint32_t nodeId);

    void clearBuffer();
    void loadChunk(const int16_t* samples, uint32_t count);
    uint32_t readChunk(float* out, uint32_t count = 0);
    uint32_t readChunk(double* out, uint32_t count = 0);

signals:
    void sampleRateChanged();
    void chunkSizeChanged();
    void nodeIdChanged();

private:
    const uint32_t m_sampleRate;
    const uint32_t m_chunkSize;
    uint32_t m_nodeId;
    QMutex m_nodeIdMutex;

    std::jthread m_thread;
    std::vector<float> m_buffer1;
    std::vector<float> m_buffer2;
    std::atomic<std::vector<float>*> m_readBuffer;
    std::atomic<std::vector<float>*> m_writeBuffer;
    uint32_t m_sampleCount;

    void reload();
    void start() override;
    void stop() override;
};

} // namespace caelestia
