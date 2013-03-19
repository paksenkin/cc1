//
//  GrammarController.h
//  СС1
//
//  Created by Pavel Aksenkin on 24.02.13.
//  Copyright (c) 2013 Pavel Aksenkin. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface GrammarController : NSObject <NSTableViewDataSource, NSTableViewDelegate, NSTextFieldDelegate>
{
    NSMutableArray *_rules;
    
    IBOutlet NSTextField *_newRuleField;
    IBOutlet NSTableView *_table;
}

-(NSArray*)strings;
-(IBAction)addRule:(id)sender;
-(IBAction)removeRule:(id)sender;
-(IBAction)clear:(id)sender;

@end
