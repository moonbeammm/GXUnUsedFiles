//
//  GXUnusedFilesTool.m
//  UnusedFiles
//
//  Created by sgx on 2019/4/29.
//  Copyright © 2019 sgx. All rights reserved.
//

#import "GXUnusedFilesTool.h"
#import "GXDefine.h"
#import <Cocoa/Cocoa.h>

@interface GXUnusedFilesTool ()
{
    NSString *_xcode_PbxprojPath;
    NSString *_xcode_projectPath;
    NSDictionary *_xcode_Pbx_objects;
    NSMutableDictionary *_xcode_AllClass;
    NSMutableArray *_usedClassArray;
}
@property(nonatomic,strong)NSMutableArray *object_C_FilesM;
@property(nonatomic,strong)NSMutableArray *swift_FilesM;
@property(nonatomic,strong)NSMutableArray *error_FilesM;

@end

@implementation GXUnusedFilesTool

- (instancetype)init{
    self = [super init];
    if (self) {
        self->_xcode_AllClass = [NSMutableDictionary dictionaryWithCapacity:0];
        self->_usedClassArray= [NSMutableArray arrayWithCapacity:0];
        _object_C_FilesM = [NSMutableArray arrayWithCapacity:0];
        _swift_FilesM= [NSMutableArray arrayWithCapacity:0];
        _error_FilesM = [NSMutableArray arrayWithCapacity:0];
    }
    return self;
}

-(void)setSpecialFilesStr:(NSString *)specialFilesStr{
    _specialFilesStr = specialFilesStr;
    [_error_FilesM removeAllObjects];
    NSArray *specialStrArray = [specialFilesStr componentsSeparatedByString:@","];
    
    if (specialStrArray.count > 0) {
        for (NSString *key in specialStrArray) {
            NSString *classKey = key.lastPathComponent.stringByDeletingPathExtension;
            classKey = [classKey stringByReplacingOccurrencesOfString:@" " withString:@""];
            if (classKey.length > 0 && ![_error_FilesM containsObject:classKey]) {
                [_error_FilesM addObject:classKey];
            }
        }
    }
}

/**
 *  start search Action
 *
 *  @param path .xcodeproj path
 */
-(BOOL)searchWithFilePath:(NSString *)path {
    
    if(!path || ![path hasSuffix:@".xcodeproj"]){
        NSAlert* errorAlert = [[NSAlert alloc] init];
        errorAlert.messageText = @" “Xcodeproj” path input error";
        [errorAlert beginSheetModalForWindow:[NSApplication sharedApplication].keyWindow completionHandler:nil];
        return NO;
    }
    
    [self->_xcode_AllClass removeAllObjects];
    [self->_usedClassArray removeAllObjects];
    [self.swift_FilesM removeAllObjects];
    [self.object_C_FilesM removeAllObjects];
    
    [self dealWithXcodeproj:path];
    return YES;
}

/**
 start dealwith .xcodeproj
 
 @param path xcodeproj path
 */
-(void)dealWithXcodeproj:(NSString *)path{
    
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        self->_xcode_projectPath = [path stringByDeletingLastPathComponent];
        self->_xcode_PbxprojPath = [path stringByAppendingPathComponent:@"project.pbxproj"];
        NSDictionary *pbxprojDic = [NSDictionary dictionaryWithContentsOfFile:self->_xcode_PbxprojPath];
        
        self->_xcode_Pbx_objects = [pbxprojDic objectForKey:@"objects"];
        NSString *uuid_mainGroup = [[self->_xcode_Pbx_objects objectForKey:[pbxprojDic objectForKey:@"rootObject"]] objectForKey:@"mainGroup"];
        NSDictionary *PBXGroupDic = [self->_xcode_Pbx_objects objectForKey:uuid_mainGroup];
        [self classPath:self->_xcode_projectPath pbxGroupDic:PBXGroupDic uuid:uuid_mainGroup operateType:OperateType_GetAllClass];
        [self classPath:self->_xcode_projectPath pbxGroupDic:PBXGroupDic uuid:uuid_mainGroup operateType:OperateType_GetOneFile];
        [self classPath:self->_xcode_projectPath pbxGroupDic:PBXGroupDic uuid:uuid_mainGroup operateType:OperateType_DeletStorybord];
        
        NSMutableString *usedString= [NSMutableString string];
        for (NSString *key in self->_usedClassArray) {
            [usedString appendFormat:@"\n%@",key];
        }
        
        if (self.usedClassBlock) {
            self.usedClassBlock(usedString);
            
        }
        
        NSMutableString *unString= [NSMutableString string];
        [self->_xcode_AllClass removeObjectForKey:@"main"];
        
        if (self.error_FilesM.count > 0) {
            for (NSString *errorFile in self.error_FilesM) {
                [self->_xcode_AllClass removeObjectForKey:errorFile];
            }
        }
        
        for (NSString *key in self->_xcode_AllClass.allKeys) {
            [unString appendFormat:@"\n%@",key];
        }
        
        if (self.unUsedClassBlock) {
            self.unUsedClassBlock(unString,self->_xcode_AllClass.count);
            
        }
    });
}

-(NSString *)allClass_Files{
    NSMutableString *unString= [NSMutableString string];
    [self->_xcode_AllClass removeObjectForKey:@"main"];
    for (NSString *key in self->_xcode_AllClass.allKeys) {
        [unString appendFormat:@"\n%@",key];
    }
    return unString;
}

-(NSString *)object_C_Files{
    NSMutableString *ocString= [NSMutableString string];
    for (NSString *key in self.object_C_FilesM) {
        [ocString appendFormat:@"\n%@",key];
    }
    
    if (self.error_FilesM.count > 0) {
        for (NSString *errorFile in self.error_FilesM) {
            [self.object_C_FilesM removeObject:errorFile];
        }
    }
    
    return ocString;
}

-(NSString *)swift_Files{
    NSMutableString *swiftString= [NSMutableString string];
    for (NSString *key in self.swift_FilesM) {
        [swiftString appendFormat:@"\n%@",key];
    }
    
    if (self.error_FilesM.count > 0) {
        for (NSString *errorFile in self.error_FilesM) {
            [self.swift_FilesM removeObject:errorFile];
        }
    }
    
    return swiftString;
}
/**
 get All Classes
 
 @param classPath classPath
 @param pbxGroupDic pbxGroupDic
 @param uuid uuid
 */
-(void)classPath:(NSString*)classPath pbxGroupDic:(NSDictionary*)pbxGroupDic uuid:(NSString*)uuid operateType:(OperateType)operateType{
    NSArray* children = pbxGroupDic[@"children"];
    NSString* path = pbxGroupDic[@"path"];
    NSString* sourceTree = pbxGroupDic[@"sourceTree"];
    
    if(path.length > 0){
        
        if([sourceTree isEqualToString:@"<group>"]){
            classPath = [classPath stringByAppendingPathComponent:path];
        }else if([sourceTree isEqualToString:@"SOURCE_ROOT"]){
            classPath = [self->_xcode_projectPath stringByAppendingPathComponent:path];
        }
    }
    
    if(children.count == 0){
        NSString*pathExtension = classPath.pathExtension;
        if([pathExtension isEqualToString:@"h"] || [pathExtension isEqualToString:@"m"]||[pathExtension isEqualToString:@"pch"] ||  [pathExtension isEqualToString:@"storyboard"]|| [pathExtension isEqualToString:@"mm"] || [pathExtension isEqualToString:@"xib"] || [pathExtension isEqualToString:@"swift"]){
            
            
            if (operateType == OperateType_GetAllClass) {
                NSString* fileName = classPath.lastPathComponent.stringByDeletingPathExtension;
                NSMutableDictionary* fileInfo = self->_xcode_AllClass[fileName];
                
                if(!fileInfo){
                    fileInfo = [NSMutableDictionary dictionary];
                    self->_xcode_AllClass[fileName] = fileInfo;
                    fileInfo[@"paths"] = [NSMutableArray array];
                    fileInfo[@"keys"] = [NSMutableArray array];
                }
                
                [fileInfo[@"paths"] addObject:classPath];
                [fileInfo[@"keys"] addObject:uuid];
            } else if (operateType == OperateType_GetOneFile){
                [self examineClassFilePath:classPath];
            } else if (operateType == OperateType_DeletStorybord){
                NSString* fileName = classPath.lastPathComponent.stringByDeletingPathExtension;
                if([pathExtension isEqualToString:@"storyboard"]){
                    
                    [self->_xcode_AllClass removeObjectForKey:fileName];
                    
                } else if ([pathExtension isEqualToString:@"swift"] && [self->_xcode_AllClass objectForKey:fileName]){
                    [_swift_FilesM addObject:fileName];
                } else if ([pathExtension isEqualToString:@"m"]|| [pathExtension isEqualToString:@"mm"]){
                    if ([self->_xcode_AllClass objectForKey:fileName]) {
                        [_object_C_FilesM addObject:fileName];
                    }
                    
                }
            }
            
        }
    } else {
        for (NSString* childrenUUid in children) {
            NSDictionary* childrenDic = self->_xcode_Pbx_objects[childrenUUid];
            [self classPath:classPath pbxGroupDic:childrenDic uuid:childrenUUid operateType:operateType];
        }
    }
}

/**
 Filter used classes
 
 @param classFilePath file path
 */
-(void)examineClassFilePath:(NSString*)classFilePath{
    
    NSString *fileName  = classFilePath.lastPathComponent;
    NSString *fileClassName = fileName.stringByDeletingPathExtension;
    
    NSString* content = [NSString stringWithContentsOfFile:classFilePath encoding:NSUTF8StringEncoding error:nil];
    
    NSString *contentFile= [self stringByReplacingContent:content];
    if(content.length == 0) return;
    
    NSArray *contentFileArray = [contentFile componentsSeparatedByString:@" "];
    NSMutableDictionary *fileAllKey = [NSMutableDictionary dictionaryWithCapacity:0];
    for (NSString *subString in contentFileArray) {
        if (subString.length > 0) {
            [fileAllKey setObject:@"0" forKey:subString];
        }
    }
    
    NSString*pathExtension = classFilePath.pathExtension;
    if ([pathExtension isEqualToString:@"pch"]) {
        for (NSString *key in self->_xcode_AllClass.allKeys) {
            if (fileAllKey[key]) {
                fileAllKey[key] = @"1";
            }
        }
    }else if([pathExtension isEqualToString:@"swift"] && [fileClassName containsString:@"+"] && _isSelect){
        //过滤swift的分类
        [self->_xcode_AllClass removeObjectForKey:fileClassName];
        
    }else{
        for (NSString *key in self->_xcode_AllClass.allKeys) {
            
            if ([key isEqualToString:fileClassName]) {
                continue;
            }
            
            if (fileAllKey[key]) {
                fileAllKey[key] = @"1";
            }
        }
    }
    
    for (NSString *key in fileAllKey.allKeys) {
        NSString *value = fileAllKey[key];
        if ([value isEqualToString:@"1"]) {
            NSString *userStr = [NSString stringWithFormat:@"File:%@ ------>>%@",fileName.lastPathComponent,key];
            [self->_usedClassArray addObject:userStr];
            
            [self->_xcode_AllClass removeObjectForKey:key];
        }
    }
    
    [fileAllKey removeAllObjects];
    fileAllKey = nil ;
    contentFile = nil;
}

/**
 Filter out special characters and comments
 
 @param content content
 @return Filtered string
 */
-(NSString *)stringByReplacingContent:(NSString *)content{
    if (!content) return @"";
    NSMutableString* useReplaceString = [NSMutableString stringWithString:content];
    NSString *pattern = [NSString stringWithFormat:@"/\\*[\\s\\S]*?\\*/|\\#|\\/\\/.*|\n|\\:|\\;|\\[|\\]|\\.|\\@|\\(|\\)|\\<|\\>|\\/|\\,|\\{|\\}|\\.|\\!|\\?|\\=|\"|\\*"];
    NSError *error;
    NSRegularExpression* regex = [NSRegularExpression regularExpressionWithPattern:pattern options:0 error:&error];
    if (regex != nil) {
        NSString* resultString = [regex stringByReplacingMatchesInString:useReplaceString options:NSMatchingReportProgress range:NSMakeRange(0, [useReplaceString length]) withTemplate:@" "];
        return resultString;
    }
    return content;
}

@end
