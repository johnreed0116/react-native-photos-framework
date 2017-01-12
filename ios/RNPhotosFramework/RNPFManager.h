#import <AssetsLibrary/AssetsLibrary.h>
#import <React/RCTBridgeModule.h>
#import <React/RCTConvert.h>
#import <React/RCTBridge.h>
#import <React/RCTEventDispatcher.h> 
#import <React/RCTEventEmitter.h>
#import "PHOperationResult.h"

@import UIKit;
@import Photos;

typedef void (^assetOperationBlock)(BOOL success, NSError *__nullable error, NSString  * __nullable localIdentifier);
typedef void (^fileDownloadExtendedPrograessBlock)(NSString * _Nonnull uri, int index,int64_t progress, int64_t total);
typedef void(^createAssetsCompleteBlock)( NSMutableArray<PHOperationResult *> * _Nonnull  result);

@interface RNPFManager : RCTEventEmitter <RCTBridgeModule>

@end
