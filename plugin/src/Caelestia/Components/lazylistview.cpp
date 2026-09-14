#include "lazylistview.hpp"

#include <qqmlcontext.h>
#include <qtimer.h>

#include <algorithm>

namespace {

constexpr int k_asyncBatchCreate = 2;
constexpr int k_asyncBatchDestroy = 4;
constexpr qreal k_fallbackSize = 40;

// Start of a rect along the main axis
qreal rectStart(const QRectF& rect, bool horizontal) {
    return horizontal ? rect.x() : rect.y();
}

// End of a rect along the main axis
qreal rectEnd(const QRectF& rect, bool horizontal) {
    return horizontal ? rect.x() + rect.width() : rect.y() + rect.height();
}

// Clip a rect along the main axis to [start, end], empty if there is no overlap
QRectF clipAxis(const QRectF& rect, bool horizontal, qreal start, qreal end) {
    const qreal newStart = std::max(rectStart(rect, horizontal), start);
    const qreal newEnd = std::min(rectEnd(rect, horizontal), end);
    if (newStart >= newEnd)
        return {};
    return horizontal ? QRectF(newStart, rect.y(), newEnd - newStart, rect.height())
                      : QRectF(rect.x(), newStart, rect.width(), newEnd - newStart);
}

} // namespace

namespace caelestia::components {

using Qt::StringLiterals::operator""_s;

// --- LazyListViewAttached ---

LazyListViewAttached::LazyListViewAttached(QObject* parent)
    : QObject(parent) {}

qreal LazyListViewAttached::preferredHeight() const {
    return m_preferredHeight;
}

void LazyListViewAttached::setPreferredHeight(qreal height) {
    if (qFuzzyCompare(m_preferredHeight + 1.0, height + 1.0))
        return;
    m_preferredHeight = height;
    emit preferredHeightChanged();
}

qreal LazyListViewAttached::visibleHeight() const {
    return m_visibleHeight;
}

void LazyListViewAttached::setVisibleHeight(qreal height) {
    if (qFuzzyCompare(m_visibleHeight + 1.0, height + 1.0))
        return;
    m_visibleHeight = height;
    emit visibleHeightChanged();
}

qreal LazyListViewAttached::preferredWidth() const {
    return m_preferredWidth;
}

void LazyListViewAttached::setPreferredWidth(qreal width) {
    if (qFuzzyCompare(m_preferredWidth + 1.0, width + 1.0))
        return;
    m_preferredWidth = width;
    emit preferredWidthChanged();
}

qreal LazyListViewAttached::visibleWidth() const {
    return m_visibleWidth;
}

void LazyListViewAttached::setVisibleWidth(qreal width) {
    if (qFuzzyCompare(m_visibleWidth + 1.0, width + 1.0))
        return;
    m_visibleWidth = width;
    emit visibleWidthChanged();
}

qreal LazyListViewAttached::layoutY() const {
    return m_layoutY;
}

void LazyListViewAttached::setLayoutY(qreal y) {
    if (qFuzzyCompare(m_layoutY + 1.0, y + 1.0))
        return;
    m_layoutY = y;
    emit layoutYChanged();
}

qreal LazyListViewAttached::layoutX() const {
    return m_layoutX;
}

void LazyListViewAttached::setLayoutX(qreal x) {
    if (qFuzzyCompare(m_layoutX + 1.0, x + 1.0))
        return;
    m_layoutX = x;
    emit layoutXChanged();
}

bool LazyListViewAttached::ready() const {
    return m_ready;
}

void LazyListViewAttached::setReady(bool ready) {
    if (m_ready == ready)
        return;
    m_ready = ready;
    emit readyChanged();
}

bool LazyListViewAttached::adding() const {
    return m_adding;
}

void LazyListViewAttached::setAdding(bool adding) {
    if (m_adding == adding)
        return;
    m_adding = adding;
    emit addingChanged();
}

bool LazyListViewAttached::removing() const {
    return m_removing;
}

void LazyListViewAttached::setRemoving(bool removing) {
    if (m_removing == removing)
        return;
    m_removing = removing;
    emit removingChanged();
}

bool LazyListViewAttached::trackViewport() const {
    return m_trackViewport;
}

void LazyListViewAttached::setTrackViewport(bool track) {
    if (m_trackViewport == track)
        return;
    m_trackViewport = track;
    emit trackViewportChanged();
}

// --- LazyListView ---

LazyListView::LazyListView(QQuickItem* parent)
    : QQuickItem(parent) {
    setFlag(ItemHasContents, false);
}

LazyListViewAttached* LazyListView::qmlAttachedProperties(QObject* object) {
    return new LazyListViewAttached(object);
}

LazyListView::~LazyListView() {
    for (auto& entry : m_delegates)
        destroyDelegate(entry);
    for (auto& entry : m_dyingDelegates)
        destroyDelegate(entry);
}

// --- Model & Delegate ---

QAbstractItemModel* LazyListView::model() const {
    return m_model;
}

void LazyListView::setModel(QAbstractItemModel* model) {
    if (m_model == model)
        return;

    if (m_model)
        disconnectModel();

    m_model = model;

    if (m_model)
        connectModel();

    resetContent();
    emit modelChanged();
}

QQmlComponent* LazyListView::delegate() const {
    return m_delegate;
}

void LazyListView::setDelegate(QQmlComponent* delegate) {
    if (m_delegate == delegate)
        return;

    m_delegate = delegate;
    resetContent();
    emit delegateChanged();
}

// --- Layout ---

Qt::Orientation LazyListView::orientation() const {
    return m_orientation;
}

// Switching axis invalidates every measurement, so the content is rebuilt from
// scratch rather than reusing sizes taken along the other axis.
void LazyListView::setOrientation(Qt::Orientation orientation) {
    if (m_orientation == orientation)
        return;

    m_orientation = orientation;
    emit orientationChanged();
    notifyExtentChanged();
    resetContent();
}

bool LazyListView::horizontal() const {
    return m_orientation == Qt::Horizontal;
}

qreal LazyListView::spacing() const {
    return m_spacing;
}

void LazyListView::setSpacing(qreal spacing) {
    if (qFuzzyCompare(m_spacing, spacing))
        return;
    m_spacing = spacing;
    emit spacingChanged();
    polish();
}

// Extent of the content along the main axis. Both accessors report it so that a
// consumer binds whichever matches its orientation. Reporting width()/height()
// for the other axis instead would make `implicitWidth: contentWidth` on a
// vertical view resolve to the item's own width, i.e. a binding loop.
qreal LazyListView::contentHeight() const {
    return m_contentSize;
}

qreal LazyListView::contentWidth() const {
    return m_contentSize;
}

qreal LazyListView::layoutHeight() const {
    return m_layoutSize;
}

qreal LazyListView::layoutWidth() const {
    return m_layoutSize;
}

qreal LazyListView::contentY() const {
    return horizontal() ? 0 : m_contentPos;
}

void LazyListView::setContentY(qreal contentY) {
    setContentPos(contentY);
}

qreal LazyListView::contentX() const {
    return horizontal() ? m_contentPos : 0;
}

void LazyListView::setContentX(qreal contentX) {
    setContentPos(contentX);
}

// Both scroll accessors write the same main-axis offset, so the list follows
// whichever one its consumer drives.
void LazyListView::setContentPos(qreal contentPos) {
    if (qFuzzyCompare(m_contentPos, contentPos))
        return;
    m_contentPos = contentPos;
    emit contentYChanged();
    emit contentXChanged();
    polish();
}

// The value a consumer binds for the cross axis changes with the view size, so
// both content and layout notifications always fire together.
void LazyListView::notifyExtentChanged() {
    emit contentHeightChanged();
    emit contentWidthChanged();
    emit layoutHeightChanged();
    emit layoutWidthChanged();
}

// --- Viewport ---

QRectF LazyListView::viewport() const {
    return m_viewport;
}

void LazyListView::setViewport(const QRectF& viewport) {
    if (m_viewport == viewport)
        return;
    m_viewport = viewport;
    emit viewportChanged();
    if (m_useCustomViewport)
        polish();
}

bool LazyListView::useCustomViewport() const {
    return m_useCustomViewport;
}

void LazyListView::setUseCustomViewport(bool use) {
    if (m_useCustomViewport == use)
        return;
    m_useCustomViewport = use;
    emit useCustomViewportChanged();
    polish();
}

qreal LazyListView::cacheBuffer() const {
    return m_cacheBuffer;
}

void LazyListView::setCacheBuffer(qreal buffer) {
    if (qFuzzyCompare(m_cacheBuffer, buffer))
        return;
    m_cacheBuffer = buffer;
    emit cacheBufferChanged();
    polish();
}

bool LazyListView::cullDelegates() const {
    return m_cullDelegates;
}

void LazyListView::setCullDelegates(bool cull) {
    if (m_cullDelegates == cull)
        return;
    m_cullDelegates = cull;
    emit cullDelegatesChanged();
    polish();
}

// --- Sizing ---

qreal LazyListView::estimatedHeight() const {
    return m_estimatedHeight;
}

void LazyListView::setEstimatedHeight(qreal height) {
    if (qFuzzyCompare(m_estimatedHeight, height))
        return;
    m_estimatedHeight = height;
    emit estimatedHeightChanged();
    polish();
}

qreal LazyListView::estimatedWidth() const {
    return m_estimatedWidth;
}

void LazyListView::setEstimatedWidth(qreal width) {
    if (qFuzzyCompare(m_estimatedWidth, width))
        return;
    m_estimatedWidth = width;
    emit estimatedWidthChanged();
    polish();
}

bool LazyListView::asynchronous() const {
    return m_asynchronous;
}

void LazyListView::setAsynchronous(bool async) {
    if (m_asynchronous == async)
        return;
    m_asynchronous = async;
    emit asynchronousChanged();
}

LazyListViewAttached* LazyListView::attachedFor(QQuickItem* item) {
    return qobject_cast<LazyListViewAttached*>(qmlAttachedPropertiesObject<LazyListView>(item, false));
}

LazyListViewAttached* LazyListView::attachedForCreate(QQuickItem* item) {
    return qobject_cast<LazyListViewAttached*>(qmlAttachedPropertiesObject<LazyListView>(item, true));
}

// Estimated main-axis size of an item that has not been measured yet
qreal LazyListView::effectiveEstimatedSize() const {
    const qreal estimated = horizontal() ? m_estimatedWidth : m_estimatedHeight;
    if (estimated >= 0)
        return estimated;
    if (m_knownSizeCount > 0)
        return m_knownSizeSum / m_knownSizeCount;
    return k_fallbackSize;
}

// Size used for layout positioning, falling back to the estimate while unmeasured
qreal LazyListView::layoutSizeAt(int index) const {
    const auto& record = m_layout[index];
    return record.sizeKnown ? record.size : effectiveEstimatedSize();
}

// Size as currently rendered, so scrolling follows in-flight animations
qreal LazyListView::visibleSizeAt(int index) const {
    const auto it = m_delegates.find(index);
    if (it != m_delegates.end() && it->item)
        return delegateVisibleSize(it->item);
    return layoutSizeAt(index);
}

// Position of an item in visible-size space, including the spacing before it.
// Only non-zero size items participate, so collapsed items add no spacing.
qreal LazyListView::visualPosAt(int index) const {
    qreal pos = 0;
    bool hasItem = false;
    for (int i = 0; i < index; ++i) {
        const qreal size = visibleSizeAt(i);
        if (size <= 0)
            continue;
        if (hasItem)
            pos += m_spacing;
        hasItem = true;
        pos += size;
    }
    if (hasItem && visibleSizeAt(index) > 0)
        pos += m_spacing;
    return pos;
}

qreal LazyListView::viewportStart() const {
    if (m_useCustomViewport)
        return horizontal() ? m_viewport.x() : m_viewport.y();
    return m_contentPos;
}

void LazyListView::trackSize(qreal size) {
    m_knownSizeSum += size;
    ++m_knownSizeCount;
}

void LazyListView::untrackSize(qreal size) {
    m_knownSizeSum -= size;
    --m_knownSizeCount;
}

// Records a measured main-axis size for an item, keeping the running average in sync
LazyListView::SizeUpdate LazyListView::setKnownSize(int index, qreal size) {
    auto& record = m_layout[index];
    const SizeUpdate previous{ .previousSize = layoutSizeAt(index), .wasKnown = record.sizeKnown };

    if (record.sizeKnown)
        untrackSize(record.size);
    record.size = size;
    record.sizeKnown = true;
    trackSize(size);

    return previous;
}

// A resize before the viewport shifts everything after it, so opted-in delegates
// report the delta and let the consumer compensate its scroll position.
void LazyListView::adjustViewportIfBefore(int index, QQuickItem* item, qreal delta) {
    auto* attached = attachedFor(item);
    if (attached && attached->trackViewport() && m_layout[index].target < viewportStart())
        emit viewportAdjustNeeded(delta);
}

// Rendered position of a delegate along the main axis
qreal LazyListView::delegateMainPos(QQuickItem* item) const {
    return horizontal() ? item->x() : item->y();
}

qreal LazyListView::delegateSize(QQuickItem* item) const {
    if (!item)
        return 0;

    auto* attached = attachedFor(item);
    if (attached) {
        const qreal preferred = horizontal() ? attached->preferredWidth() : attached->preferredHeight();
        if (preferred >= 0)
            return preferred;
    }

    return horizontal() ? item->implicitWidth() : item->implicitHeight();
}

qreal LazyListView::delegateVisibleSize(QQuickItem* item) const {
    if (!item)
        return 0;

    auto* attached = attachedFor(item);
    if (attached) {
        const qreal visible = horizontal() ? attached->visibleWidth() : attached->visibleHeight();
        if (visible >= 0)
            return visible;
    }

    return delegateSize(item);
}

bool LazyListView::isDelegateReady(QQuickItem* item) {
    if (!item)
        return false;
    auto* attached = attachedFor(item);
    return !attached || attached->ready();
}

// --- Animation Durations ---

int LazyListView::removeDuration() const {
    return m_removeDuration;
}

void LazyListView::setRemoveDuration(int duration) {
    if (m_removeDuration == duration)
        return;
    m_removeDuration = duration;
    emit removeDurationChanged();
}

int LazyListView::readyDelay() const {
    return m_readyDelay;
}

void LazyListView::setReadyDelay(int delay) {
    if (m_readyDelay == delay)
        return;
    m_readyDelay = delay;
    emit readyDelayChanged();
}

// --- State ---

int LazyListView::count() const {
    return m_model ? m_model->rowCount() : 0;
}

// Always false; bind through it to re-run itemAtIndex/itemAt on mapping changes
bool LazyListView::itemsDirty() {
    return false;
}

// Instantiated delegate for a model index, nullptr if outside the cache
QQuickItem* LazyListView::itemAtIndex(int index) const {
    return m_delegates.value(index).item;
}

// Hit test against instantiated delegates at their current visual positions
QQuickItem* LazyListView::itemAt(qreal x, qreal y) const {
    const bool horiz = horizontal();

    // The cross axis must be inside the view for a hit to count
    if (horiz ? (y < 0 || y >= height()) : (x < 0 || x >= width()))
        return nullptr;

    const qreal pos = horiz ? x : y;
    if (pos < 0)
        return nullptr;

    const auto children = childItems();
    for (auto* const item : children | std::views::reverse) {
        if (!m_itemToIndex.contains(item) || !item->isVisible())
            continue;

        const qreal start = delegateMainPos(item) + m_contentPos;
        const qreal end = start + delegateVisibleSize(item);

        if (pos >= start && pos < end)
            return item;
    }

    return nullptr;
}

// --- QQuickItem Overrides ---

void LazyListView::componentComplete() {
    QQuickItem::componentComplete();
    m_componentComplete = true;
    resetContent();
}

void LazyListView::geometryChange(const QRectF& newGeometry, const QRectF& oldGeometry) {
    QQuickItem::geometryChange(newGeometry, oldGeometry);

    if (!m_componentComplete)
        return;

    // Delegates span the cross axis, so a change there resizes all of them.
    // The extent accessors deliberately do not depend on width()/height(), so no
    // extent notification belongs here: broadening a geometry change into a
    // contentWidthChanged/contentHeightChanged emit makes the signal fire
    // synchronously while a consumer's `implicitWidth: contentWidth` binding is
    // still running, which Qt reports as a binding loop.
    const bool changed = !qFuzzyCompare(newGeometry.width(), oldGeometry.width()) ||
                         !qFuzzyCompare(newGeometry.height(), oldGeometry.height());

    if (changed) {
        for (auto& entry : m_delegates) {
            if (!entry.item)
                continue;
            if (horizontal())
                entry.item->setHeight(newGeometry.height());
            else
                entry.item->setWidth(newGeometry.width());
        }
    }

    polish();
}

void LazyListView::updatePolish() {
    if (!m_componentComplete || !m_model || !m_delegate)
        return;

    flushPendingInserts();
    relayout();
    syncDelegates();

    // Clear isNew flags - the add animation only plays for items created
    // during the same polish cycle as their model insertion, not for
    // delegates created later when scrolling items into the viewport.
    for (auto& record : m_layout)
        record.isNew = false;

    positionDelegates();
}

// Makes newly created delegates visible and clears the adding flag so enter
// animations begin. When readyDelay > 0 the reveal is deferred so delegates
// have time to lay out before appearing.
void LazyListView::flushPendingInserts() {
    for (auto& entry : m_delegates) {
        if (!entry.pendingInsert || !entry.item)
            continue;

        if (m_readyDelay <= 0) {
            entry.pendingInsert = false;
            revealDelegate(entry.item);
            continue;
        }

        if (!entry.readyDelayStarted) {
            entry.readyDelayStarted = true;
            QTimer::singleShot(m_readyDelay, this, [this, item = entry.item] {
                finishDelayedInsert(item);
            });
        }
    }
}

void LazyListView::revealDelegate(QQuickItem* item) {
    item->setVisible(true);

    auto* attached = attachedFor(item);
    if (attached) {
        attached->setAdding(false);
        attached->setReady(true);
    }
}

// Reveals a delegate whose readyDelay has elapsed, seeding its main-axis
// position from the current visual one so the move to the layout position
// animates.
void LazyListView::finishDelayedInsert(QQuickItem* item) {
    const int idx = indexOfDelegate(item);
    if (idx < 0)
        return;

    auto& entry = m_delegates[idx];
    if (!entry.pendingInsert)
        return;

    entry.pendingInsert = false;
    entry.readyDelayStarted = false;

    if (idx < static_cast<int>(m_layout.size()))
        setDelegateMainPos(item, visualPosAt(idx));

    revealDelegate(item);

    // Re-check the bounds: revealing runs QML bindings and onReady handlers,
    // which may have mutated the model out from under us.
    if (idx < static_cast<int>(m_layout.size())) {
        setDelegateMainPos(item, m_layout[idx].target); // animate to layout position
        updateLayoutPos(item, idx);
    }

    polish();
}

void LazyListView::positionDelegates() {
    for (auto& entry : m_delegates) {
        if (!entry.item || entry.pendingRemoval || entry.pendingInsert)
            continue;

        const int idx = entry.modelIndex;
        if (idx < 0 || idx >= static_cast<int>(m_layout.size()))
            continue;

        if (m_layout[idx].sizeKnown && qFuzzyIsNull(m_layout[idx].size))
            continue;

        setDelegateMainPos(entry.item, m_layout[idx].target);
        updateLayoutPos(entry.item, idx);
    }
}

// Places a delegate along the main axis through the QML property system so
// Behaviors apply and the move animates (direct setters would bypass them).
void LazyListView::setDelegateMainPos(QQuickItem* item, qreal pos) const {
    item->setProperty(horizontal() ? "x" : "y", pos - m_contentPos);
}

// Publishes the non-animated main-axis position so delegates can read it while
// their position animates
void LazyListView::updateLayoutPos(QQuickItem* item, int index) {
    auto* attached = attachedFor(item);
    if (!attached)
        return;

    const qreal value = m_layout[index].target - m_contentPos;
    if (horizontal())
        attached->setLayoutX(value);
    else
        attached->setLayoutY(value);
}

// --- Layout Engine ---

void LazyListView::relayout() {
    updateLayoutPositions();
    updateContentExtent();
}

// Layout positioning uses the preferred main-axis size (final/non-animated).
// Only adds spacing between items with non-zero size.
void LazyListView::updateLayoutPositions() {
    qreal pos = 0;
    bool hasItem = false;
    for (int i = 0; i < static_cast<int>(m_layout.size()); ++i) {
        auto& record = m_layout[i];
        record.target = pos;

        const qreal size = layoutSizeAt(i);
        if (size <= 0)
            continue;

        if (hasItem) {
            pos += m_spacing;
            record.target = pos;
        }
        hasItem = true;
        pos += size;
    }

    if (!qFuzzyCompare(m_layoutSize + 1.0, pos + 1.0)) {
        m_layoutSize = pos;
        notifyExtentChanged();
    }
}

// Content extent tracks actual visible sizes so scrolling follows animations
void LazyListView::updateContentExtent() {
    const int last = static_cast<int>(m_layout.size()) - 1;
    qreal visEnd = last < 0 ? 0 : visualPosAt(last) + visibleSizeAt(last);

    // Account for dying delegates still visually present
    for (const auto& dying : std::as_const(m_dyingDelegates)) {
        if (!dying.item)
            continue;
        const qreal dyingSize = delegateVisibleSize(dying.item);
        if (dyingSize > 0)
            visEnd = std::max(visEnd, delegateMainPos(dying.item) + dyingSize);
    }

    if (!qFuzzyCompare(m_contentSize + 1.0, visEnd + 1.0)) {
        m_contentSize = visEnd;
        notifyExtentChanged();
    }
}

// Coalesces size-driven relayouts into a single deferred pass
void LazyListView::scheduleRelayout() {
    if (m_relayoutPending)
        return;

    m_relayoutPending = true;
    QTimer::singleShot(0, this, [this] {
        m_relayoutPending = false;
        relayout();
        polish();
    });
}

QRectF LazyListView::effectiveViewport() const {
    const bool horiz = horizontal();

    QRectF vp;
    if (m_useCustomViewport)
        vp = m_viewport;
    else if (horiz)
        vp = QRectF(m_contentPos, 0, width(), height());
    else
        vp = QRectF(0, m_contentPos, width(), height());

    // During Flickable overshoot the viewport can extend entirely beyond content bounds,
    // causing all delegates to be culled. Clamp so it always overlaps [0, layoutSize].
    // Only needed for the built-in viewport — custom viewports represent the actual
    // visible area and may legitimately lie entirely outside the content.
    if (!m_useCustomViewport && m_layoutSize > 0) {
        const qreal start = std::min(rectStart(vp, horiz), m_layoutSize);
        const qreal end = std::max(rectEnd(vp, horiz), 0.0);
        if (end > start)
            vp = horiz ? QRectF(start, vp.y(), end - start, vp.height())
                       : QRectF(vp.x(), start, vp.width(), end - start);
    }

    vp = horiz ? vp.adjusted(-m_cacheBuffer, 0, m_cacheBuffer, 0) : vp.adjusted(0, -m_cacheBuffer, 0, m_cacheBuffer);

    // Trim the cache-buffered viewport to [0, layoutSize]. No items exist outside
    // those bounds, so extending past them wastes budget and can cause edge thrashing
    // when a large cache buffer reaches the opposite end of the content.
    if (m_layoutSize > 0)
        return clipAxis(vp, horiz, 0, m_layoutSize);

    return vp;
}

std::pair<int, int> LazyListView::computeVisibleRange() const {
    if (m_layout.isEmpty())
        return { -1, -1 };

    // Culling disabled: keep every delegate alive
    if (!m_cullDelegates)
        return { 0, static_cast<int>(m_layout.size()) - 1 };

    const bool horiz = horizontal();
    const auto vp = effectiveViewport();
    if (vp.isEmpty())
        return { -1, -1 };

    const qreal vpStart = rectStart(vp, horiz);
    const qreal vpEnd = rectEnd(vp, horiz);

    // Binary search for first visible item
    int lo = 0;
    int hi = static_cast<int>(m_layout.size()) - 1;
    int first = static_cast<int>(m_layout.size());

    while (lo <= hi) {
        const int mid = lo + (hi - lo) / 2;
        const auto& record = m_layout[mid];
        const qreal itemEnd = record.target + (record.sizeKnown ? record.size : effectiveEstimatedSize());

        if (itemEnd >= vpStart) {
            first = mid;
            hi = mid - 1;
        } else {
            lo = mid + 1;
        }
    }

    if (first >= static_cast<int>(m_layout.size()))
        return { -1, -1 };

    // Linear scan for last visible item
    int last = first;
    for (int i = first; i < static_cast<int>(m_layout.size()); ++i) {
        if (m_layout[i].target > vpEnd)
            break;
        last = i;
    }

    return { first, last };
}

// --- Delegate Lifecycle ---

void LazyListView::syncDelegates() {
    const auto [first, last] = computeVisibleRange();

    // Collect indices that should be alive
    QSet<int> visibleIndices;
    if (first >= 0) {
        for (int i = first; i <= last; ++i)
            visibleIndices.insert(i);
    }

    const auto toRemove = delegatesOutsideViewport(visibleIndices, effectiveViewport());
    const int destroyed =
        destroyDelegates(toRemove, m_asynchronous ? k_asyncBatchDestroy : static_cast<int>(toRemove.size()));

    const auto toCreate = missingDelegates(first, last);
    const int created =
        createDelegates(toCreate, m_asynchronous ? k_asyncBatchCreate : static_cast<int>(toCreate.size()));

    // Pending inserts need to become visible on the next frame, and
    // async mode may have remaining create/destroy work.
    const bool workRemains = m_asynchronous && (destroyed < static_cast<int>(toRemove.size()) ||
                                                   created < static_cast<int>(toCreate.size()));
    if (created > 0 || workRemains)
        polish();

    if (created > 0 || destroyed > 0)
        emit itemsDirtyChanged();
}

// Delegates safe to destroy - outside the range to keep and no longer visually
// overlapping the viewport, so nothing mid-animation disappears.
QList<int> LazyListView::delegatesOutsideViewport(const QSet<int>& keep, const QRectF& viewport) const {
    QList<int> outside;

    const bool horiz = horizontal();
    const qreal vpStart = rectStart(viewport, horiz);
    const qreal vpEnd = rectEnd(viewport, horiz);

    for (auto it = m_delegates.constBegin(); it != m_delegates.constEnd(); ++it) {
        if (keep.contains(it.key()))
            continue;

        if (!it->item || viewport.isEmpty()) {
            outside.append(it.key());
            continue;
        }

        const qreal itemStart = delegateMainPos(it->item);
        const qreal itemEnd = itemStart + delegateVisibleSize(it->item);
        if (itemEnd < vpStart || itemStart > vpEnd)
            outside.append(it.key());
    }

    return outside;
}

QList<int> LazyListView::missingDelegates(int first, int last) const {
    if (first < 0)
        return {};

    QList<int> missing;
    for (int i = first; i <= last; ++i) {
        if (!m_delegates.contains(i))
            missing.append(i);
    }

    return missing;
}

int LazyListView::destroyDelegates(const QList<int>& indices, int budget) {
    // Take entries out of the maps first so destruction cannot observe
    // a delegate that is already unreachable from the view.
    QVector<DelegateEntry> removed;
    removed.reserve(std::min(budget, static_cast<int>(indices.size())));

    for (const int idx : indices) {
        if (static_cast<int>(removed.size()) >= budget)
            break;

        auto entry = m_delegates.take(idx);
        if (entry.item)
            m_itemToIndex.remove(entry.item);
        removed.append(std::move(entry));
    }

    for (auto& entry : removed)
        destroyDelegate(entry);

    return static_cast<int>(removed.size());
}

int LazyListView::createDelegates(const QList<int>& indices, int budget) {
    int created = 0;

    for (const int idx : indices) {
        if (created >= budget)
            break;

        auto entry = createDelegate(idx);
        if (!entry.item)
            continue;

        // Size tracking and viewport compensation are deferred
        // until the delegate signals ready via readyChanged.
        entry.pendingInsert = true;
        setDelegateMainPos(entry.item, m_layout[idx].target);
        updateLayoutPos(entry.item, idx);
        m_itemToIndex.insert(entry.item, idx);
        m_delegates.insert(idx, entry);
        ++created;
    }

    return created;
}

LazyListView::DelegateEntry LazyListView::createDelegate(int modelIndex) {
    DelegateEntry entry;
    entry.modelIndex = modelIndex;

    if (!m_delegate || !m_model)
        return entry;

    // Use the delegate component's creation context for beginCreate
    // so bound components (pragma ComponentBehavior: Bound) are accepted.
    auto* compContext = m_delegate->creationContext();
    if (!compContext)
        compContext = qmlContext(this);
    if (!compContext)
        return entry;

    auto* obj = m_delegate->beginCreate(compContext);
    entry.item = qobject_cast<QQuickItem*>(obj);

    if (!entry.item) {
        if (obj)
            m_delegate->completeCreate();
        delete obj;
        return entry;
    }

    const auto props = delegateProperties(modelIndex);
    QVariantMap initialProps;
    for (const auto& [name, value] : props)
        initialProps.insert(name, value);
    m_delegate->setInitialProperties(entry.item, initialProps);

    // Stretch across the cross axis; the main axis is driven by the delegate's
    // own preferred/measured size.
    entry.item->setParentItem(this);
    if (horizontal())
        entry.item->setHeight(height());
    else
        entry.item->setWidth(width());

    // Only set adding = true for genuinely new model items (not viewport entries).
    // Cleared on the next frame in updatePolish when the item becomes visible.
    if (modelIndex < static_cast<int>(m_layout.size()) && m_layout[modelIndex].isNew) {
        auto* attached = attachedForCreate(entry.item);
        if (attached)
            attached->setAdding(true);
    }

    m_delegate->completeCreate();

    // Keep adding=true and hide - flushed on the next frame in updatePolish
    entry.item->setVisible(false);

    connectDelegate(entry);

    return entry;
}

void LazyListView::connectDelegate(const DelegateEntry& entry) {
    auto* item = entry.item;

    // Watch the implicit sizes as fallback
    connect(item, &QQuickItem::implicitHeightChanged, this, [this, item] {
        onDelegateSizeChanged(item);
    });
    connect(item, &QQuickItem::implicitWidthChanged, this, [this, item] {
        onDelegateSizeChanged(item);
    });

    // Watch attached properties if the delegate uses them
    auto* attached = attachedFor(item);
    if (!attached)
        return;

    connect(attached, &LazyListViewAttached::preferredHeightChanged, this, [this, item] {
        onDelegateSizeChanged(item);
    });
    connect(attached, &LazyListViewAttached::preferredWidthChanged, this, [this, item] {
        onDelegateSizeChanged(item);
    });
    connect(attached, &LazyListViewAttached::visibleHeightChanged, this, [this] {
        polish();
    });
    connect(attached, &LazyListViewAttached::visibleWidthChanged, this, [this] {
        polish();
    });
    connect(attached, &LazyListViewAttached::readyChanged, this, [this, item] {
        onDelegateReady(item);
    });
}

// Resolves a delegate item to its model index, or -1 if it is no longer the
// live delegate for that index (stale signal from a destroyed or replaced item).
int LazyListView::indexOfDelegate(QQuickItem* item) const {
    const auto indexIt = m_itemToIndex.constFind(item);
    if (indexIt == m_itemToIndex.constEnd())
        return -1;

    const int idx = indexIt.value();
    const auto delegateIt = m_delegates.constFind(idx);
    if (delegateIt == m_delegates.constEnd() || delegateIt->item != item)
        return -1;

    return idx;
}

// Re-measures a delegate whose main-axis size changed after it became ready.
// Cross-axis changes leave the measured size untouched, so this is a no-op for them.
void LazyListView::onDelegateSizeChanged(QQuickItem* item) {
    if (!isDelegateReady(item))
        return;

    const int idx = indexOfDelegate(item);
    if (idx < 0 || idx >= static_cast<int>(m_layout.size()))
        return;

    const qreal size = delegateSize(item);
    if (qFuzzyCompare(m_layout[idx].size + 1.0, size + 1.0))
        return;

    const auto previous = setKnownSize(idx, size);
    if (previous.wasKnown)
        adjustViewportIfBefore(idx, item, size - previous.previousSize);

    scheduleRelayout();
}

// Takes the first real measurement once a delegate reports itself ready
void LazyListView::onDelegateReady(QQuickItem* item) {
    if (!isDelegateReady(item))
        return;

    const int idx = indexOfDelegate(item);
    if (idx < 0 || idx >= static_cast<int>(m_layout.size()))
        return;

    const qreal size = delegateSize(item);
    const auto previous = setKnownSize(idx, size);
    if (!qFuzzyCompare(size + 1.0, previous.previousSize + 1.0))
        adjustViewportIfBefore(idx, item, size - previous.previousSize);

    polish();
}

void LazyListView::destroyDelegate(DelegateEntry& entry) {
    if (entry.item) {
        entry.item->setParentItem(nullptr);
        entry.item->setVisible(false);
        entry.item->deleteLater();
        entry.item = nullptr;
    }
}

// Delegate properties for a row, in the order they must be applied: every model
// role, then index, then a modelData fallback for models with no such role.
// The order is observable - an onIndexChanged handler may read modelData.
LazyListView::PropertyList LazyListView::delegateProperties(int modelIndex) const {
    PropertyList props;
    if (!m_model)
        return props;

    const auto roleNames = m_model->roleNames();
    const auto index = m_model->index(modelIndex, 0);
    bool hasModelData = false;

    props.reserve(roleNames.size() + 2);

    for (auto it = roleNames.constBegin(); it != roleNames.constEnd(); ++it) {
        const auto name = QString::fromUtf8(it.value());
        props.emplaceBack(name, m_model->data(index, it.key()));
        if (name == u"modelData"_s)
            hasModelData = true;
    }

    props.emplaceBack(u"index"_s, modelIndex);

    if (!hasModelData) {
        const auto role = roleNames.isEmpty() ? Qt::DisplayRole : roleNames.constBegin().key();
        props.emplaceBack(u"modelData"_s, m_model->data(index, role));
    }

    return props;
}

void LazyListView::updateDelegateData(DelegateEntry& entry) {
    if (!m_model || !entry.item)
        return;

    const auto props = delegateProperties(entry.modelIndex);
    for (const auto& [name, value] : props)
        entry.item->setProperty(name.toUtf8().constData(), value);
}

// Re-keys every delegate through mapIndex, keeping modelIndex, the reverse
// lookup and the delegate's own index property in sync.
void LazyListView::remapDelegates(const std::function<int(int)>& mapIndex) {
    QHash<int, DelegateEntry> remapped;
    remapped.reserve(m_delegates.size());

    for (auto it = m_delegates.begin(); it != m_delegates.end(); ++it) {
        const int newIdx = mapIndex(it.key());
        auto entry = it.value();
        entry.modelIndex = newIdx;
        if (entry.item) {
            entry.item->setProperty("index", newIdx);
            m_itemToIndex[entry.item] = newIdx;
        }
        remapped.insert(newIdx, entry);
    }

    m_delegates = std::move(remapped);
    emit itemsDirtyChanged();
}

// --- Model Connection ---

void LazyListView::connectModel() {
    if (!m_model)
        return;

    m_modelConnections = {
        connect(m_model, &QAbstractItemModel::rowsInserted, this, &LazyListView::onRowsInserted),
        connect(m_model, &QAbstractItemModel::rowsAboutToBeRemoved, this, &LazyListView::onRowsAboutToBeRemoved),
        connect(m_model, &QAbstractItemModel::rowsRemoved, this, &LazyListView::onRowsRemoved),
        connect(m_model, &QAbstractItemModel::rowsMoved, this, &LazyListView::onRowsMoved),
        connect(m_model, &QAbstractItemModel::dataChanged, this, &LazyListView::onDataChanged),
        connect(m_model, &QAbstractItemModel::modelReset, this, &LazyListView::onModelReset),
        connect(m_model, &QAbstractItemModel::layoutChanged, this,
            [this] {
                for (auto& entry : m_delegates)
                    updateDelegateData(entry);
                polish();
            }),
        connect(m_model, &QObject::destroyed, this,
            [this] {
                m_model = nullptr;
                resetContent();
                emit modelChanged();
            }),
    };
}

void LazyListView::disconnectModel() {
    for (auto& conn : m_modelConnections)
        disconnect(conn);
    m_modelConnections.clear();
}

void LazyListView::resetContent() {
    // Stop all animations and destroy all delegates
    for (auto& entry : m_delegates)
        destroyDelegate(entry);
    m_delegates.clear();
    m_itemToIndex.clear();

    for (auto& entry : m_dyingDelegates)
        destroyDelegate(entry);
    m_dyingDelegates.clear();

    // Reset pending state
    m_knownSizeSum = 0;
    m_knownSizeCount = 0;

    // Rebuild layout from model
    m_layout.clear();
    if (m_model && m_componentComplete) {
        m_layout.resize(m_model->rowCount());
        emit countChanged();
    }

    emit itemsDirtyChanged();
    polish();
}

void LazyListView::onRowsInserted(const QModelIndex& parent, int first, int last) {
    if (parent.isValid())
        return;

    const int insertCount = last - first + 1;
    // Insert new layout records
    m_layout.insert(first, insertCount, ItemRecord{ .target = 0, .size = 0, .sizeKnown = false, .isNew = true });

    // Shift existing delegate indices
    remapDelegates([first, insertCount](int idx) {
        return idx >= first ? idx + insertCount : idx;
    });

    emit countChanged();
    polish();
}

void LazyListView::onRowsAboutToBeRemoved(const QModelIndex& parent, int first, int last) {
    if (parent.isValid())
        return;

    for (int i = first; i <= last; ++i) {
        if (!m_delegates.contains(i))
            continue;

        auto entry = m_delegates.take(i);
        if (entry.item)
            m_itemToIndex.remove(entry.item);
        entry.pendingRemoval = true;

        // Never made visible — skip remove animation
        if (entry.pendingInsert) {
            destroyDelegate(entry);
            continue;
        }

        if (m_removeDuration > 0 && entry.item) {
            auto* attached = attachedFor(entry.item);
            if (attached)
                attached->setRemoving(true);

            // Schedule destruction after the remove animation duration
            auto* item = entry.item;
            QTimer::singleShot(m_removeDuration, this, [this, item] {
                for (auto it = m_dyingDelegates.begin(); it != m_dyingDelegates.end(); ++it) {
                    if (it->item == item) {
                        destroyDelegate(*it);
                        m_dyingDelegates.erase(it);
                        return;
                    }
                }
            });
            m_dyingDelegates.append(std::move(entry));
        } else {
            destroyDelegate(entry);
        }
    }
}

void LazyListView::onRowsRemoved(const QModelIndex& parent, int first, int last) {
    if (parent.isValid())
        return;

    const int removeCount = last - first + 1;

    // Untrack known sizes being removed
    for (int i = first; i <= last; ++i) {
        if (m_layout[i].sizeKnown)
            untrackSize(m_layout[i].size);
    }

    // Remove layout records
    m_layout.remove(first, removeCount);

    // Shift remaining delegate indices down
    remapDelegates([last, removeCount](int idx) {
        return idx > last ? idx - removeCount : idx;
    });

    emit countChanged();
    polish();
}

void LazyListView::onRowsMoved(const QModelIndex& parent, int start, int end, const QModelIndex& destination, int row) {
    if (parent.isValid() || destination.isValid())
        return;

    const int count = end - start + 1;
    const int dest = row > start ? row - count : row;

    // Reorder layout records
    QVector<ItemRecord> moved;
    moved.reserve(count);
    for (int i = start; i <= end; ++i)
        moved.append(m_layout[i]);
    m_layout.remove(start, count);
    for (int i = 0; i < count; ++i)
        m_layout.insert(dest + i, moved[i]);

    // Remap delegate indices to match new model order
    remapDelegates([start, end, dest, count](int idx) {
        if (idx >= start && idx <= end)
            return dest + (idx - start);

        int newIdx = idx > end ? idx - count : idx;
        if (newIdx >= dest)
            newIdx += count;
        return newIdx;
    });

    polish();
}

void LazyListView::onDataChanged(const QModelIndex& topLeft, const QModelIndex& bottomRight, const QList<int>& roles) {
    Q_UNUSED(roles)

    if (topLeft.parent().isValid())
        return;

    for (int i = topLeft.row(); i <= bottomRight.row(); ++i) {
        if (m_delegates.contains(i))
            updateDelegateData(m_delegates[i]);
    }
}

void LazyListView::onModelReset() {
    if (!m_model) {
        resetContent();
        return;
    }

    const int newRows = m_model->rowCount();
    const int oldRows = static_cast<int>(m_layout.size());

    // Check if the model data actually changed
    if (newRows == oldRows) {
        const auto roleNames = m_model->roleNames();
        const auto role = roleNames.isEmpty() ? Qt::DisplayRole : roleNames.constBegin().key();
        bool changed = false;

        for (auto it = m_delegates.constBegin(); it != m_delegates.constEnd(); ++it) {
            if (!it->item || it.key() >= newRows) {
                changed = true;
                break;
            }
            const auto newData = m_model->data(m_model->index(it.key(), 0), role);
            const auto oldData = it->item->property("modelData");
            if (newData != oldData) {
                changed = true;
                break;
            }
        }

        if (!changed) {
            // Model content unchanged, just refresh delegate data
            for (auto& entry : m_delegates)
                updateDelegateData(entry);
            return;
        }
    }

    resetContent();
}

} // namespace caelestia::components
