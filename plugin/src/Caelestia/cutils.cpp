#include "cutils.hpp"

#include <qobject.h>
#include <QtQuick/QQuickItem>
#include <QtQuick/QQuickItemGrabResult>
#include <QThreadPool>
#include <QQmlEngine>

void CUtils::saveItem(QQuickItem* target, const QUrl& path) {
    this->saveItem(target, path, QRect(), QJSValue(), QJSValue());
}

void CUtils::saveItem(QQuickItem* target, const QUrl& path, const QRect& rect) {
	this->saveItem(target, path, rect, QJSValue(), QJSValue());
}

void CUtils::saveItem(QQuickItem* target, const QUrl& path, QJSValue onSaved) {
	this->saveItem(target, path, QRect(), onSaved, QJSValue());
}

void CUtils::saveItem(QQuickItem* target, const QUrl& path, QJSValue onSaved, QJSValue onFailed) {
	this->saveItem(target, path, QRect(), onSaved, onFailed);
}

void CUtils::saveItem(QQuickItem* target, const QUrl& path, const QRect& rect, QJSValue onSaved) {
	this->saveItem(target, path, rect, onSaved, QJSValue());
}

void CUtils::saveItem(QQuickItem* target, const QUrl& path, const QRect& rect, QJSValue onSaved, QJSValue onFailed) {
	if (!target) {
		qWarning() << "CUtils::saveItem: a target is required";
		return;
	}

	if (!path.isLocalFile()) {
		qWarning() << "CUtils::saveItem:" << path << "is not a local file";
		return;
	}

	QSharedPointer<QQuickItemGrabResult> grabResult = target->grabToImage();

	QObject::connect(
	    grabResult.data(),
	    &QQuickItemGrabResult::ready,
	    this,
	    [grabResult, rect, path, onSaved, onFailed, this]() {
		    QThreadPool::globalInstance()->start([grabResult, rect, path, onSaved, onFailed, this] {
			    QImage image = grabResult->image();

			    if (!rect.isEmpty()) {
				    image = image.copy(rect);
			    }

				const QString file = path.toLocalFile();
			    if (image.save(file)) {
					if (onSaved.isCallable()) {
						onSaved.call({ QJSValue(file), qmlEngine(this)->toScriptValue(QVariant::fromValue(path)) });
					}
				} else if (onFailed.isCallable()) {
					onFailed.call({ qmlEngine(this)->toScriptValue(QVariant::fromValue(path)) });
				}
		    });
	    }
	);
}
