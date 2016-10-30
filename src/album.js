import NativeApi from './index';
import Asset from './asset';
export default class Album {

  constructor(obj, fetchOptions, eventEmitter) {
    this._fetchOptions = fetchOptions;
    Object.assign(this, obj);
    if (this.previewAssets) {
      this.previewAssets = this
        .previewAssets
        .map((assetNativeObj) => new Asset(assetNativeObj));
      if (this.previewAssets.length) {
        this.previewAsset = this.previewAssets[0];
      }
    }
    eventEmitter.addListener('onObjectChange', (changeDetails) => {
      if (changeDetails._cacheKey === this._cacheKey) {
        this._emitChange(changeDetails);
      }
    });
  }

  getAssets(params) {
    return NativeApi.getAssets({
      ...params,
      _cacheKey: this._cacheKey,
      albumLocalIdentifier: this.localIdentifier
    });
  }

  addAssetToAlbum(asset) {
    return this.addAssetsToAlbum([asset]);
  }

  addAssetsToAlbum(assets) {
    return NativeApi.addAssetsToAlbum({
      assets: assets.map(asset => asset.localIdentifier),
      _cacheKey: this._cacheKey,
      albumLocalIdentifier: this.localIdentifier
    });
  }

  removeAssetFromAlbum(asset) {
    return this.removeAssetsFromAlbum([asset]);
  }

  removeAssetsFromAlbum(assets) {
    return NativeApi.removeAssetsFromAlbum({
      assets: assets.map(asset => asset.localIdentifier),
      _cacheKey: this._cacheKey,
      albumLocalIdentifier: this.localIdentifier
    });
  }

  updateTitle(newTitle) {
    return NativeApi.updateAlbumTitle({newTitle: newTitle, _cacheKey: this._cacheKey, albumLocalIdentifier: this.localIdentifier});
  }

  delete() {
    return NativeApi.deleteAlbums([this]);
  }

  onChange(changeHandler) {
    this._changeHandler = changeHandler;
    return () => this._changeHandler = undefined;
  }

  _emitChange(changeDetails) {
    this._changeHandler && this._changeHandler(changeDetails);
  }
}
