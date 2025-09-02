#include "filesystemmodel.hpp"

#include <QAbstractListModel>
#include <QDir>
#include <QDirIterator>
#include <QFileInfo>
#include <QFutureWatcher>
#include <QImageReader>
#include <QObject>
#include <QtConcurrent>
#include <qqmlintegration.h>

int FileSystemModel::rowCount(const QModelIndex& parent) const {
    if (parent != QModelIndex()) {
        return 0;
    }
    return static_cast<int>(m_entries.size());
}

QVariant FileSystemModel::data(const QModelIndex& index, int role) const {
    if (role != Qt::UserRole || !index.isValid() || index.row() >= m_entries.size()) {
        return QVariant();
    }
    return QVariant::fromValue(m_entries.at(index.row()));
}

QHash<int, QByteArray> FileSystemModel::roleNames() const {
    return { { Qt::UserRole, "modelData" } };
}

QString FileSystemModel::path() const {
    return m_path;
}

void FileSystemModel::setPath(const QString& path) {
    if (m_path == path) {
        return;
    }

    m_path = path;
    emit pathChanged();

    m_dir.setPath(m_path);
    update();
}

bool FileSystemModel::recursive() const {
    return m_recursive;
}

void FileSystemModel::setRecursive(bool recursive) {
    if (m_recursive == recursive) {
        return;
    }

    m_recursive = recursive;
    emit recursiveChanged();

    update();
}

bool FileSystemModel::watchChanges() const {
    return m_watchChanges;
}

void FileSystemModel::setWatchChanges(bool watchChanges) {
    if (m_watchChanges == watchChanges) {
        return;
    }

    m_watchChanges = watchChanges;
    emit watchChangesChanged();

    update();
}

bool FileSystemModel::showHidden() const {
    return m_showHidden;
}

void FileSystemModel::setShowHidden(bool showHidden) {
    if (m_showHidden == showHidden) {
        return;
    }

    m_showHidden = showHidden;
    emit showHiddenChanged();

    update();
}

FileSystemModel::Filter FileSystemModel::filter() const {
    return m_filter;
}

void FileSystemModel::setFilter(Filter filter) {
    if (m_filter == filter) {
        return;
    }

    m_filter = filter;
    emit filterChanged();

    update();
}

QList<FileSystemEntry*> FileSystemModel::entries() const {
    return m_entries;
}

void FileSystemModel::watchDirIfRecursive(const QString& path) {
    if (m_recursive && m_watchChanges) {
        const auto currentDir = m_dir;
        const bool showHidden = m_showHidden;
        const auto future = QtConcurrent::run([showHidden, path]() {
            QDir::Filters filters = QDir::Dirs | QDir::NoDotAndDotDot;
            if (showHidden) {
                filters |= QDir::Hidden;
            }

            QDirIterator iter(path, filters, QDirIterator::Subdirectories);
            QStringList dirs;
            while (iter.hasNext()) {
                dirs << iter.next();
            }
            return dirs;
        });
        const auto watcher = new QFutureWatcher<QStringList>(this);
        connect(watcher, &QFutureWatcher<QStringList>::finished, this, [currentDir, showHidden, watcher, this]() {
            const auto paths = watcher->result();
            if (currentDir == m_dir && showHidden == m_showHidden && !paths.isEmpty()) {
                // Ignore if dir or showHidden has changed
                m_watcher.addPaths(paths);
            }
            watcher->deleteLater();
        });
        watcher->setFuture(future);
    }
}

void FileSystemModel::update() {
    updateWatcher();
    updateEntries();
}

void FileSystemModel::updateWatcher() {
    if (!m_watcher.directories().isEmpty()) {
        m_watcher.removePaths(m_watcher.directories());
    }

    if (!m_watchChanges || m_path.isEmpty()) {
        return;
    }

    m_watcher.addPath(m_path);
    watchDirIfRecursive(m_path);
}

void FileSystemModel::updateEntries() {
    if (m_path.isEmpty()) {
        if (!m_entries.isEmpty()) {
            beginResetModel();
            qDeleteAll(m_entries);
            m_entries.clear();
            emit entriesChanged();
            endResetModel();
        }

        return;
    }

    for (auto& future : m_futures) {
        future.cancel();
    }
    m_futures.clear();

    updateEntriesForDir(m_path);
}

void FileSystemModel::updateEntriesForDir(const QString& dir) {
    const bool recursive = m_recursive;
    const bool showHidden = m_showHidden;
    const auto filter = m_filter;
    const auto oldEntries = m_entries;
    const auto baseDir = m_dir;

    const auto future = QtConcurrent::run([dir, recursive, showHidden, filter, oldEntries, baseDir](
                                              QPromise<QPair<QSet<QString>, QSet<QString>>>& promise) {
        const auto flags = recursive ? QDirIterator::Subdirectories : QDirIterator::NoIteratorFlags;

        std::optional<QDirIterator> iter;

        if (filter == Images) {
            QStringList nameFilters;
            for (const auto& format : QImageReader::supportedImageFormats()) {
                nameFilters << "*." + format;
            }

            QDir::Filters filters = QDir::Files;
            if (showHidden) {
                filters |= QDir::Hidden;
            }

            iter.emplace(dir, nameFilters, filters, flags);
        } else {
            QDir::Filters filters;

            if (filter == Files) {
                filters = QDir::Files;
            } else if (filter == Dirs) {
                filters = QDir::Dirs | QDir::NoDotAndDotDot;
            } else {
                filters = QDir::Dirs | QDir::Files | QDir::NoDotAndDotDot;
            }

            if (showHidden) {
                filters |= QDir::Hidden;
            }

            iter.emplace(dir, filters, flags);
        }

        QSet<QString> newPaths;
        while (iter->hasNext()) {
            if (promise.isCanceled()) {
                return;
            }

            QString path = iter->next();

            if (filter == Images) {
                QImageReader reader(path);
                if (!reader.canRead()) {
                    continue;
                }
            }

            newPaths.insert(path);
        }

        QSet<QString> oldPaths;
        for (const auto& entry : oldEntries) {
            oldPaths.insert(entry->path());
        }

        if (promise.isCanceled() || newPaths == oldPaths) {
            return;
        }

        promise.addResult(qMakePair(oldPaths - newPaths, newPaths - oldPaths));
    });

    if (m_futures.contains(dir)) {
        m_futures[dir].cancel();
    }
    m_futures.insert(dir, future);

    const auto watcher = new QFutureWatcher<QPair<QSet<QString>, QSet<QString>>>(this);

    connect(watcher, &QFutureWatcher<QPair<QSet<QString>, QSet<QString>>>::finished, this, [dir, watcher, this]() {
        m_futures.remove(dir);

        if (!watcher->future().isResultReadyAt(0)) {
            watcher->deleteLater();
            return;
        }

        const auto result = watcher->result();
        const auto removedPaths = result.first;
        const auto addedPaths = result.second;

        beginResetModel();

        const int numEntries = static_cast<int>(m_entries.size());
        for (int i = numEntries - 1; i >= 0; --i) {
            if (removedPaths.contains(m_entries[i]->path())) {
                emit removed(m_entries[i]->path());
                delete m_entries.takeAt(i);
            }
        }

        for (const auto& path : addedPaths) {
            const auto entry = new FileSystemEntry(path, m_dir.relativeFilePath(path), this);
            emit added(entry);
            m_entries << entry;
        }

        std::sort(m_entries.begin(), m_entries.end(), [](const FileSystemEntry* a, const FileSystemEntry* b) {
            if (a->isDir() != b->isDir()) {
                return a->isDir();
            }
            return a->relativePath().localeAwareCompare(b->relativePath()) < 0;
        });

        emit entriesChanged();

        endResetModel();

        watcher->deleteLater();
    });

    watcher->setFuture(future);
}
