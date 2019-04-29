//
//  GXUnusedFilesTool.h
//  UnusedFiles
//
//  Created by sgx on 2019/4/29.
//  Copyright © 2019 sgx. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface GXUnusedFilesTool : NSObject

@property(nonatomic,copy)void(^usedClassBlock) (NSString *usedClassString);
@property(nonatomic,copy)void(^unUsedClassBlock) (NSString *unUsedClassString,NSInteger count);

/**
 button select
 */
@property(nonatomic,assign)BOOL isSelect;
/**
 Filter special files
 */
@property(nonatomic,copy)NSString *specialFilesStr;

/**
 *  start search Action
 *
 *  @param path .xcodeproj path
 */
-(BOOL)searchWithFilePath:(NSString *)path;
/**
 get All unusedFiles
 
 @return All unusedFiles
 */
-(NSString *)allClass_Files;
/**
 get object_C Files
 
 @return object_C Files
 */
-(NSString *)object_C_Files;
/**
 get swift_Files
 
 @return swift_Files
 */
-(NSString *)swift_Files;

@end

NS_ASSUME_NONNULL_END
