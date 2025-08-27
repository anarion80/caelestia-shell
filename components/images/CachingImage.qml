import qs.utils
import Caelestia
import QtQuick

Image {
    id: root

    property alias path: manager.path

    property int sourceWidth
    property int sourceHeight

    asynchronous: true
    fillMode: Image.PreserveAspectCrop
    sourceSize.width: sourceWidth
    sourceSize.height: sourceHeight

    onStatusChanged: {
        if (!manager.usingCache && status === Image.Ready)
            CUtils.saveItem(this, manager.cachePath);
    }

    CachingImageManager {
        id: manager

        item: root
        cacheDir: Paths.imagecache
    }
}
