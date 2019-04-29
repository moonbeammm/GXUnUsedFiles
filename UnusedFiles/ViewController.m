//
//  ViewController.m
//  UnusedFiles
//
//  Created by sgx on 2019/4/29.
//  Copyright © 2019 sgx. All rights reserved.
//

#import "ViewController.h"
#import "GXUnusedFilesTool.h"

@interface ViewController ()
{
    NSString *projectPath;
}

@property (weak) IBOutlet NSTextFieldCell *xcodePathTextField;

@property (weak) IBOutlet NSTextView *usedFilesTextView;
@property (weak) IBOutlet NSTextView *unUsedFilesTextView;
@property (weak) IBOutlet NSTextField *specialFilesFidld;
@property (weak) IBOutlet NSPopUpButtonCell *selectItem;
@property (weak) IBOutlet NSButton *filterSwiftExtensionBtn;

@property(nonatomic,strong) GXUnusedFilesTool *arrangementTool;
@property(nonatomic,strong) NSOpenPanel *openPanel;

@end

@implementation ViewController

- (void)awakeFromNib{
    self.usedFilesTextView.string = @"The classes that are used are shown here";
    self.unUsedFilesTextView.string = @"The classes that are unUsed are shown here";
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do view setup here.
    
    __weak typeof(self) weakSelf = self;
    [self.arrangementTool setUsedClassBlock:^(NSString * usedClassSting) {
        dispatch_async(dispatch_get_main_queue(), ^{
            weakSelf.usedFilesTextView.string = usedClassSting;
            [weakSelf.usedFilesTextView scrollRectToVisible:NSMakeRect(0, 0, 0, 0)];
        });
    }];
    [self.arrangementTool setUnUsedClassBlock:^(NSString *unString,NSInteger count) {
        dispatch_async(dispatch_get_main_queue(), ^{
            weakSelf.unUsedFilesTextView.string = unString;
            [weakSelf.unUsedFilesTextView scrollRectToVisible:NSMakeRect(0, 0, 0, 0)];
        });
    }];
    self.arrangementTool.isSelect = self.filterSwiftExtensionBtn.state;
}

- (GXUnusedFilesTool *)arrangementTool{
    if (!_arrangementTool) {
        _arrangementTool = [[GXUnusedFilesTool alloc]init];
    }
    return _arrangementTool;
}

#pragma mark -- Action

- (IBAction)browseAction:(id)sender {
    self.xcodePathTextField.stringValue = @"";
    if (self.openPanel) {
        [self.openPanel close];
        self.openPanel = nil;
    }
    self.openPanel = [NSOpenPanel openPanel];
    [self.openPanel setCanChooseDirectories:YES];
    [self.openPanel setCanChooseFiles:YES];
    self.openPanel.allowsMultipleSelection = NO;
    
    [self.openPanel beginSheetModalForWindow:[NSApplication sharedApplication].keyWindow completionHandler:^(NSInteger result) {
        if (result == NSModalResponseOK) {
            NSString *path = [[self.openPanel URL] path];
            self.xcodePathTextField.stringValue = path;
        }
    }];
}

- (IBAction)searchAction:(id)sender {
    self.usedFilesTextView.string = @"search Class ...";
    self.unUsedFilesTextView.string = @"search Class ...";
    self.arrangementTool.specialFilesStr = self.specialFilesFidld.stringValue;
    [self.selectItem selectItemAtIndex:0];
    BOOL isOK = [self.arrangementTool searchWithFilePath:[self.xcodePathTextField stringValue]];

    if (isOK) {
        projectPath = [self.xcodePathTextField stringValue];
    }
}

- (IBAction)filterSwiftExtensionAction:(NSButton *)sender {
    self.arrangementTool.isSelect = self.filterSwiftExtensionBtn.state;
}

- (IBAction)selectFilesAction:(NSPopUpButton *)sender {
    if ([sender.title isEqualToString:@"AllClass"]) {
        self.unUsedFilesTextView.string = [self.arrangementTool allClass_Files];
        [self.unUsedFilesTextView scrollRectToVisible:NSMakeRect(0, 0, 0, 0)];
    }else if ([sender.title isEqualToString:@"Objec-C"]) {
        self.unUsedFilesTextView.string = [self.arrangementTool object_C_Files];
        [self.unUsedFilesTextView scrollRectToVisible:NSMakeRect(0, 0, 0, 0)];
    }else if ([sender.title isEqualToString:@"Swift"]) {
        self.unUsedFilesTextView.string = [self.arrangementTool swift_Files];
        [self.unUsedFilesTextView scrollRectToVisible:NSMakeRect(0, 0, 0, 0)];
    }
}

@end
