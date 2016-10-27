#import "RCTCameraRollRNPhotosFrameworkManager.h"
#import "RCTUtils.h"
#import "PHCachingImageManagerInstance.h"
#import "RCTConvert.h"
#import "RCTImageLoader.h"
#import "RCTLog.h"
#import "RCTUtils.h"
#import "RCTConvert+RNPhotosFramework.h"
#import "PHChangeObserver.h"
#import "PHFetchOptionsService.h"
#import "PHAssetsService.h"
#import "PHCollectionService.h"
#import "RCTCachedFetchResult.h"
#import "RCTProfile.h"
@import Photos;

@implementation RCTCameraRollRNPhotosFrameworkManager
RCT_EXPORT_MODULE()

@synthesize bridge = _bridge;
NSString *const RNPHotoFrameworkErrorUnableToLoad = @"RNPHOTOSFRAMEWORK_UNABLE_TO_LOAD";
NSString *const RNPHotoFrameworkErrorUnableToSave = @"RNPHOTOSFRAMEWORK_UNABLE_TO_SAVE";

static id ObjectOrNull(id object)
{
    return object ?: [NSNull null];
}

- (dispatch_queue_t)methodQueue
{
    return dispatch_queue_create("com.facebook.React.ReactNaticePhotosFramework", DISPATCH_QUEUE_SERIAL);
}

RCT_EXPORT_METHOD(getAssets:(NSDictionary *)params
                  resolve:(RCTPromiseResolveBlock)resolve
                  reject:(RCTPromiseRejectBlock)reject)
{
    RCT_PROFILE_BEGIN_EVENT(0, @"-[RCTCameraRollRNPhotosFrameworkManager getAssets", nil);
    NSString *fetchId = params[@"fetchId"];
    PHFetchResult<PHAsset *> *assetsFetchResult;
    if(fetchId != nil) {
        RCTCachedFetchResult *cachedFetchResult = [[PHChangeObserver sharedChangeObserver] getFetchResultFromCacheWithuuid:fetchId];
        if(cachedFetchResult != nil) {
            assetsFetchResult = cachedFetchResult.fetchResult;
        }
    }
    if(assetsFetchResult == nil) {
        assetsFetchResult = [PHAssetsService getAssetsForParams:params];
        if(fetchId != nil) {
            [[PHChangeObserver sharedChangeObserver] cacheFetchResultWithUUID:assetsFetchResult andObjectType:[PHAsset class] andUUID:fetchId];
        }
    }
    
    NSString *startIndexParam = params[@"startIndex"];
    NSString *endIndexParam = params[@"endIndex"];
    BOOL includeMetaData = [RCTConvert BOOL:params[@"includeMetaData"]];
    
    NSUInteger startIndex = [RCTConvert NSInteger:startIndexParam];
    NSUInteger endIndex = endIndexParam != nil ? [RCTConvert NSInteger:endIndexParam] : (assetsFetchResult.count -1);
    
    
    NSArray<PHAsset *> *assets = [PHAssetsService getAssetsForFetchResult:assetsFetchResult startIndex:startIndex endIndex:endIndex];
    [self prepareAssetsForDisplayWithParams:params andAssets:assets];
    BOOL includesLastAsset = endIndex >= (assetsFetchResult.count -1);
    resolve(@{
              @"assets" : [PHAssetsService assetsArrayToUriArray:assets andIncludeMetaData:includeMetaData],
              @"includesLastAsset" : @(includesLastAsset)
              });
    RCT_PROFILE_END_EVENT(RCTProfileTagAlways, @"");
}

RCT_EXPORT_METHOD(cleanCache:(RCTPromiseResolveBlock)resolve
                  reject:(RCTPromiseRejectBlock)reject)
{
    RCTBridge *b = _bridge;
    [[PHChangeObserver sharedChangeObserver] cleanCache];
    resolve(@{});
}


RCT_EXPORT_METHOD(updateAlbumTitle:(NSDictionary *)params
                  resolve:(RCTPromiseResolveBlock)resolve
                  reject:(RCTPromiseRejectBlock)reject)
{
    PHAssetCollection *collection = [PHCollectionService getAssetCollectionForParams:params];
    NSString *newTitle = [RCTConvert NSString:params[@"newTitle"]];
    if(newTitle == nil) {
        reject(@"You have to provide newTitle-prop to rename album", @{ @"success" : @(NO) }, nil);
    }
    if (![collection canPerformEditOperation:PHCollectionEditOperationRename]) {
        reject(@"Can't PerformEditOperation", @{ @"success" : @(NO) }, nil);
        return;
    }
    
    [[PHPhotoLibrary sharedPhotoLibrary] performChanges:^{
        PHAssetCollectionChangeRequest *changeTitlerequest =[PHAssetCollectionChangeRequest changeRequestForAssetCollection:collection];
        changeTitlerequest.title = newTitle;
        
    } completionHandler:^(BOOL success, NSError *error) {
        if(success) {
            resolve(@{ @"success" : @(success) });
        }else {
            reject(@"Error", @{ @"success" : @(success) }, nil);
        }
    }];
}


RCT_EXPORT_METHOD(addAssetsToAlbum:(NSDictionary *)params
                  resolve:(RCTPromiseResolveBlock)resolve
                  reject:(RCTPromiseRejectBlock)reject)
{
    PHAssetCollection *assetCollection = [PHCollectionService getAssetCollectionForParams:params];
    PHFetchResult<PHAsset *> *fetchedAssets = [PHAssetsService getAssetsFromArrayOfLocalIdentifiers:[RCTConvert NSArray:params[@"assets"]]];
    [PHCollectionService addAssets:fetchedAssets toAssetCollection:assetCollection andCompleteBLock:^(BOOL success, NSError * _Nullable error) {
        if(success) {
            resolve(@{ @"success" : @(success) });
        }else {
            reject(@"Error", @{ @"success" : @(success) }, nil);
        }
        
    }];
}

RCT_EXPORT_METHOD(removeAssetsFromAlbum:(NSDictionary *)params
                  resolve:(RCTPromiseResolveBlock)resolve
                  reject:(RCTPromiseRejectBlock)reject)
{
    PHAssetCollection *assetCollection = [PHCollectionService getAssetCollectionForParams:params];
    PHFetchResult<PHAsset *> *fetchedAssets = [PHAssetsService getAssetsFromArrayOfLocalIdentifiers:[RCTConvert NSArray:params[@"assets"]]];
    [PHCollectionService removeAssets:fetchedAssets fromAssetCollection:assetCollection andCompleteBLock:^(BOOL success, NSError * _Nullable error) {
        if(success) {
            resolve(@{ @"success" : @(success) });
        }else {
            reject(@"Error", @{ @"success" : @(success) }, nil);
        }
        
    }];
}

RCT_EXPORT_METHOD(getAlbums:(NSDictionary *)params
                  resolve:(RCTPromiseResolveBlock)resolve
                  reject:(RCTPromiseRejectBlock)reject)
{
    resolve([PHCollectionService getAlbums:params]);
}

RCT_EXPORT_METHOD(getAlbumsMany:(NSArray *)params
                  resolve:(RCTPromiseResolveBlock)resolve
                  reject:(RCTPromiseRejectBlock)reject)
{
    NSMutableArray *responseArray = [NSMutableArray new];
    for(int i = 0; i < params.count;i++) {
        NSDictionary *albumsQuery = [params objectAtIndex:i];
        [responseArray addObject:[PHCollectionService getAlbums:albumsQuery]];
    }
    resolve(responseArray);
}

RCT_EXPORT_METHOD(getAlbumsByTitles:(NSDictionary *)params
                  resolve:(RCTPromiseResolveBlock)resolve
                  reject:(RCTPromiseRejectBlock)reject)
{
    NSArray * albumTitles = [RCTConvert NSArray:params[@"albumTitles"]];
    if(albumTitles == nil) {
        reject(@"albumTitles cannot be null", nil, nil);
    }
    PHFetchResult<PHAssetCollection *> * collections = [PHCollectionService getUserAlbumsByTitles:albumTitles withParams:params];
    resolve([PHCollectionService generateCollectionResponseWithCollections:collections andParams:params]);
}

RCT_EXPORT_METHOD(createAlbums:(NSArray *)albumTitles
                  resolve:(RCTPromiseResolveBlock)resolve
                  reject:(RCTPromiseRejectBlock)reject)
{
    if(albumTitles == nil) {
        reject(@"input array with album-names array<string> cannot be null", nil, nil);
    }
    
    if(albumTitles.count == 0) {
        resolve(@[]);
    }
    
    [PHCollectionService createAlbumsWithTitles:albumTitles andCompleteBLock:^(BOOL success, NSError * _Nullable error, NSArray<NSString *> *localIdentifier) {
        if(success) {
            resolve(localIdentifier);
        }else{
            reject([NSString stringWithFormat:@"Error creating albumTitles %@", albumTitles], nil, error);
        }
    }];
    
    /*[PHCollectionService createAlbumWithTitle:albumName andCompleteBLock:^(BOOL success, NSError * _Nullable error, NSString * _Nullable localIdentifier) {
        if(success) {
            resolve(@{
                      @"localIdentifier" : localIdentifier
                    });
        }else{
            reject([NSString stringWithFormat:@"Error creating album named %@", albumName], nil, error);
        }
    }];*/
}


RCT_EXPORT_METHOD(getAssetsMetaData:(NSArray<NSString *> *)arrayWithLocalIdentifiers
                  resolve:(RCTPromiseResolveBlock)resolve
                  reject:(RCTPromiseRejectBlock)reject)
{
    PHFetchResult<PHAsset *> * arrayWithAssets = [PHAssetsService getAssetsFromArrayOfLocalIdentifiers:arrayWithLocalIdentifiers];
    NSMutableArray<NSDictionary *>  *arrayWithMetaDataObjs = [NSMutableArray arrayWithCapacity:arrayWithAssets.count];
    [arrayWithAssets enumerateObjectsUsingBlock:^(PHAsset * _Nonnull asset, NSUInteger idx, BOOL * _Nonnull stop) {
        [arrayWithMetaDataObjs addObject:[PHAssetsService extendAssetDicWithAssetMetaData:[NSMutableDictionary dictionaryWithObject:asset.localIdentifier forKey:@"localIdentifier"] andPHAsset:asset]];
    }];
    resolve(arrayWithMetaDataObjs);
}



-(void) prepareAssetsForDisplayWithParams:(NSDictionary *)params andAssets:(NSArray<PHAsset *> *)assets {
    NSString *prepareProp = params[@"prepareForSizeDisplay"];
    if(prepareProp != nil) {
        CGSize prepareForSizeDisplay = [RCTConvert CGSize:params[@"prepareForSizeDisplay"]];
        CGFloat prepareScale = [RCTConvert CGFloat:params[@"prepareScale"]];
        PHCachingImageManager *cacheManager = [PHCachingImageManagerInstance sharedCachingManager];
        
        if(prepareForSizeDisplay.width != 0 && prepareForSizeDisplay.height != 0) {
            if(prepareScale < 0.1) {
                prepareScale = 2;
            }
            [cacheManager startCachingImagesForAssets:assets targetSize:CGSizeApplyAffineTransform(prepareForSizeDisplay, CGAffineTransformMakeScale(prepareScale, prepareScale)) contentMode:PHImageContentModeAspectFill options:nil];
        }
    }

}






@end
