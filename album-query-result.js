import Album from './album';
export default class AlbumQueryResult {
    constructor(obj, fetchOptions, eventEmitter) {
        this._fetchOptions = fetchOptions;
        Object.assign(this, obj);
        this._albumNativeObjs = this.albums;
        this.albums = this._albumNativeObjs.map(albumObj => new Album(albumObj,
            fetchOptions, eventEmitter));
        eventEmitter.addListener('onObjectChange', (changeDetails) => {
            if (changeDetails._cacheKey === this._cacheKey && this._changeHandler) {
                this._changeHandler(changeDetails);
                if(changeDetails.albumLocalIdentifier) {
                  const albumThatChanged = this.albums.find(album => album.localIdentifier === changeDetails.albumLocalIdentifier);
                  albumThatChanged._emitChange(changeDetails);
                }
            }
        });
    }

    onChange(changeHandler) {
      this._changeHandler = changeHandler;
    }
}
