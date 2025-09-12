#include "beattracker.hpp"

#include "audiocollector.hpp"
#include "audioprovider.hpp"
#include <aubio/aubio.h>

namespace caelestia {

BeatProcessor::BeatProcessor(AudioCollector* collector, QObject* parent)
    : AudioProcessor(collector, parent)
    , m_tempo(nullptr)
    , m_in(nullptr)
    , m_out(new_fvec(2)) {
    if (collector) {
        m_tempo = new_aubio_tempo("default", 1024, collector->chunkSize(), collector->sampleRate());
        m_in = new_fvec(collector->chunkSize());
    }
};

BeatProcessor::~BeatProcessor() {
    if (m_tempo) {
        del_aubio_tempo(m_tempo);
    }
    if (m_in) {
        del_fvec(m_in);
    }
    del_fvec(m_out);
}

void BeatProcessor::setCollector(AudioCollector* collector) {
    AudioProcessor::setCollector(collector);

    if (m_tempo) {
        del_aubio_tempo(m_tempo);
    }
    if (m_in) {
        del_fvec(m_in);
    }

    if (collector) {
        m_tempo = new_aubio_tempo("default", 1024, collector->chunkSize(), collector->sampleRate());
        m_in = new_fvec(collector->chunkSize());
    } else {
        m_tempo = nullptr;
        m_in = nullptr;
    }
}

void BeatProcessor::process() {
    if (!m_collector || !m_tempo || !m_in) {
        return;
    }

    m_collector->readChunk(m_in->data);

    aubio_tempo_do(m_tempo, m_in, m_out);
    if (!qFuzzyIsNull(m_out->data[0])) {
        emit beat(aubio_tempo_get_bpm(m_tempo));
    }
}

BeatTracker::BeatTracker(QObject* parent)
    : AudioProvider(parent)
    , m_bpm(120) {
    m_processor = new BeatProcessor(m_collector);
    init();

    connect(static_cast<BeatProcessor*>(m_processor), &BeatProcessor::beat, this, &BeatTracker::updateBpm);
}

smpl_t BeatTracker::bpm() const {
    return m_bpm;
}

void BeatTracker::updateBpm(smpl_t bpm) {
    if (!qFuzzyCompare(bpm + 1.0f, m_bpm + 1.0f)) {
        m_bpm = bpm;
        emit bpmChanged();
    }
}

} // namespace caelestia
