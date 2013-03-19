//
//  Solver.h
//  СС1
//
//  Created by Pavel Aksenkin on 24.02.13.
//  Copyright (c) 2013 Pavel Aksenkin. All rights reserved.
//

#import "GrammarController.h"
#import "FA.h"
#import "RSystem.h"

@interface Solver : NSObject
{
    IBOutlet NSTextField *_expField;
    IBOutlet NSTextView *_log;
    
    IBOutlet GrammarController *_grController;
    FA *_fa;
}

-(IBAction)solve:(id)sender;
-(IBAction)isAllowed:(id)sender;

@end
