#pragma once

#include "audiocollector.hpp"
#include "audioprovider.hpp"
#include <aubio/aubio.h>
#include <qqmlintegration.h>

namespace caelestia {

class BeatProcessor : public AudioProcessor {
    Q_OBJECT

public:
    explicit BeatProcessor(AudioCollector* collector, QObject* parent = nullptr);
    ~BeatProcessor();

signals:
    void beat(smpl_t bpm);

protected:
    void setCollector(AudioCollector* collector) override;

private:
    aubio_tempo_t* m_tempo;
    fvec_t* m_in;
    fvec_t* m_out;

    void process() override;
};

class BeatTracker : public AudioProvider {
    Q_OBJECT
    QML_ELEMENT

    Q_PROPERTY(smpl_t bpm READ bpm NOTIFY bpmChanged)

public:
    explicit BeatTracker(QObject* parent = nullptr);

    [[nodiscard]] smpl_t bpm() const;

signals:
    void bpmChanged();
    void beat(smpl_t bpm);

private:
    smpl_t m_bpm;

    void updateBpm(smpl_t bpm);
};

} // namespace caelestia
