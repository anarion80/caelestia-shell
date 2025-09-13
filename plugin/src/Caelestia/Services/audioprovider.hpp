#pragma once

#include "audiocollector.hpp"
#include "service.hpp"
#include <qqmlintegration.h>
#include <qtimer.h>

namespace caelestia {

class AudioProcessor : public QObject {
    Q_OBJECT

public:
    explicit AudioProcessor(AudioCollector* collector, QObject* parent = nullptr);
    ~AudioProcessor();

    void init();

protected:
    AudioCollector* m_collector;

    Q_INVOKABLE virtual void setCollector(AudioCollector* collector);

private:
    QTimer* m_timer;

    Q_INVOKABLE void start();
    Q_INVOKABLE void stop();

    virtual void process() = 0;
};

class AudioProvider : public Service {
    Q_OBJECT

    Q_PROPERTY(AudioCollector* collector READ collector WRITE setCollector NOTIFY collectorChanged)

public:
    explicit AudioProvider(QObject* parent = nullptr);
    ~AudioProvider();

    AudioCollector* collector() const;
    void setCollector(AudioCollector* collector);

signals:
    void collectorChanged();

protected:
    AudioCollector* m_collector;
    AudioProcessor* m_processor;

    void init();

private:
    QThread* m_thread;

    void start() override;
    void stop() override;
};

} // namespace caelestia
